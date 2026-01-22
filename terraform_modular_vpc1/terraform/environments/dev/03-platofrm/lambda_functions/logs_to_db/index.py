import json
import boto3
import csv
import io
import os
import time
import urllib.request
from urllib.parse import unquote_plus
from datetime import datetime
import gzip
import re

# =========================
# Configuración
# =========================
LOKI_URL = os.environ.get("LOKI_URL", "http://loki:3100")
BATCH_SIZE = int(os.environ.get("BATCH_SIZE", "500"))
MAX_RETRIES = int(os.environ.get("MAX_RETRIES", "3"))
RETRY_DELAY = float(os.environ.get("RETRY_DELAY", "1.0"))
s3_client = boto3.client("s3")


def parse_timestamp_from_row(row: dict) -> int:
    """
    Extrae timestamp de la fila. Si existe el campo 'ts', lo usa.
    Si no, usa el timestamp actual.
    """
    if "ts" in row and row["ts"]:
        # Intentar parsear el campo ts
        ts_str = row["ts"]
        
        # Formatos posibles
        timestamp_formats = [
            "%Y-%m-%dT%H:%M:%S.%f",
            "%Y-%m-%dT%H:%M:%S",
            "%Y-%m-%d %H:%M:%S.%f",
            "%Y-%m-%d %H:%M:%S",
        ]
        
        for fmt in timestamp_formats:
            try:
                # Manejar timestamps con zona horaria
                if ts_str.endswith('Z'):
                    ts_str = ts_str[:-1]
                dt = datetime.strptime(ts_str, fmt)
                return int(dt.timestamp() * 1e9)
            except ValueError:
                continue
        
        # Si todo falla, intentar como Unix timestamp
        try:
            return int(float(ts_str) * 1e9)
        except (ValueError, TypeError):
            pass
    
    # Fallback: timestamp actual
    return int(time.time() * 1e9)


def extract_flow_labels(row: dict, filename: str) -> dict:
    """
    Extrae labels relevantes de logs de flujo de red.
    """
    labels = {
        "job": "network_flows",
        "source": "s3",
    }
    
    # Protocolo
    if "proto" in row and row["proto"]:
        labels["protocol"] = str(row["proto"]).lower()
    
    # Servicio (si existe)
    if "service" in row and row["service"] and row["service"] != "":
        labels["service"] = str(row["service"])[:50]
    
    # Estado de conexión
    if "conn_state" in row and row["conn_state"]:
        labels["conn_state"] = str(row["conn_state"])
    
    # Dirección del tráfico
    if "local_orig" in row and "local_resp" in row:
        local_orig = str(row.get("local_orig", "")).lower() == "true"
        local_resp = str(row.get("local_resp", "")).lower() == "true"
        
        if local_orig and local_resp:
            labels["traffic_direction"] = "internal"
        elif local_orig:
            labels["traffic_direction"] = "outbound"
        elif local_resp:
            labels["traffic_direction"] = "inbound"
        else:
            labels["traffic_direction"] = "external"
    
    # Agregar subnet de origen (primeros 3 octetos)
    if "id.orig_h" in row and row["id.orig_h"]:
        orig_ip = str(row["id.orig_h"])
        # Extraer /24 subnet
        subnet_match = re.match(r'(\d+\.\d+\.\d+)\.\d+', orig_ip)
        if subnet_match:
            labels["src_subnet"] = subnet_match.group(1) + ".0/24"
    
    return labels


def push_batch_to_loki(batch: list, filename: str, retry_count: int = 0):
    """
    Envía un batch de logs a Loki.
    batch: lista de diccionarios
    """
    if not batch:
        return
    
    # Agrupar logs por labels
    streams_by_labels = {}
    
    for row in batch:
        # Extraer timestamp
        timestamp_ns = parse_timestamp_from_row(row)
        
        # Extraer labels
        labels = extract_flow_labels(row, filename)
        labels_key = json.dumps(labels, sort_keys=True)
        
        # Agregar metadata adicional
        log_entry = {
            **row,
            "source_file": filename,
            "_ingestion_time": datetime.now().isoformat()
        }
        
        # Agrupar por tipo de stream
        if labels_key not in streams_by_labels:
            streams_by_labels[labels_key] = {
                "stream": labels,
                "values": []
            }
        
        streams_by_labels[labels_key]["values"].append([
            str(timestamp_ns),
            json.dumps(log_entry, default=str)
        ])
    
    # Ordenar valores por timestamp dentro de cada stream
    for stream_data in streams_by_labels.values():
        stream_data["values"].sort(key=lambda x: int(x[0]))
    
    # Preparar payload
    payload = {
        "streams": list(streams_by_labels.values())
    }
    
    data = json.dumps(payload).encode("utf-8")
    
    # Comprimir si es grande
    if len(data) > 1024:
        data = gzip.compress(data)
        headers = {
            "Content-Type": "application/json",
            "Content-Encoding": "gzip"
        }
    else:
        headers = {"Content-Type": "application/json"}
    
    req = urllib.request.Request(
        url=f"{LOKI_URL}/loki/api/v1/push",
        data=data,
        headers=headers,
        method="POST"
    )
    
    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
            if resp.status not in (200, 204):
                body = resp.read().decode('utf-8', errors='replace')
                raise RuntimeError(f"Loki respondió con status {resp.status}: {body}")
            print(f"  ✓ Batch enviado exitosamente a Loki")
    except Exception as e:
        if retry_count < MAX_RETRIES:
            print(f" Error enviando a Loki (intento {retry_count + 1}/{MAX_RETRIES}): {e}")
            time.sleep(RETRY_DELAY * (retry_count + 1))
            push_batch_to_loki(batch, filename, retry_count + 1)
        else:
            print(f"✗ Error final enviando batch a Loki: {e}")
            raise


def process_csv_file(bucket: str, key: str) -> int:
    """
    Procesa un archivo CSV desde S3.
    """
    print(f" Procesando: s3://{bucket}/{key}")
    
    response = s3_client.get_object(Bucket=bucket, Key=key)
    content = response["Body"].read().decode("utf-8", errors="replace")
    
    # Usar CSV DictReader
    csv_reader = csv.DictReader(io.StringIO(content))
    
    batch = []
    total_sent = 0
    row_count = 0
    filename = f"s3://{bucket}/{key}"
    
    print(f" Columnas detectadas: {csv_reader.fieldnames[:10]}...")  # Primeras 10
    
    for row in csv_reader:
        row_count += 1
        
        # Limpiar valores vacíos
        cleaned_row = {
            k: (v.strip() if v and v.strip() not in ['', '-'] else None)
            for k, v in row.items()
        }
        
        batch.append(cleaned_row)
        
        if len(batch) >= BATCH_SIZE:
            push_batch_to_loki(batch, filename)
            total_sent += len(batch)
            print(f"   Enviados {total_sent} logs...")
            batch.clear()
    
    # Enviar último batch
    if batch:
        push_batch_to_loki(batch, filename)
        total_sent += len(batch)
    
    print(f"✔ Completado: {total_sent} logs procesados de {row_count} filas totales")
    
    return total_sent


def lambda_handler(event, context):
    """
    Handler principal de Lambda.
    """
    start_time = time.time()
    total_sent = 0
    files_processed = 0
    errors = []
    
    print(f" Iniciando procesamiento de {len(event['Records'])} archivo(s)")
    print(f" Loki URL: {LOKI_URL}")
    print(f" Batch size: {BATCH_SIZE}")
    
    for record in event["Records"]:
        bucket = None
        key = None
        try:
            bucket = record["s3"]["bucket"]["name"]
            key = unquote_plus(record["s3"]["object"]["key"])
            
            sent = process_csv_file(bucket, key)
            total_sent += sent
            files_processed += 1
            
        except Exception as e:
            error_msg = f"Error procesando s3://{bucket}/{key}: {str(e)}"
            print(f"✗ {error_msg}")
            errors.append(error_msg)
            import traceback
            traceback.print_exc()
    
    duration = time.time() - start_time
    
    print(f"\n{'='*60}")
    print(f"✔ Procesamiento completado en {duration:.2f}s")
    print(f"   Archivos procesados: {files_processed}/{len(event['Records'])}")
    print(f"   Total logs enviados: {total_sent}")
    print(f"   Velocidad: {total_sent/duration:.2f} logs/seg" if duration > 0 else "")
    if errors:
        print(f"   Errores: {len(errors)}")
        for err in errors:
            print(f"     - {err}")
    print(f"{'='*60}")
    
    return {
        "statusCode": 200 if not errors else 207,
        "body": json.dumps({
            "message": "Procesamiento completado",
            "files_processed": files_processed,
            "total_files": len(event["Records"]),
            "logs_sent": total_sent,
            "duration_seconds": round(duration, 2),
            "logs_per_second": round(total_sent/duration, 2) if duration > 0 else 0,
            "errors": errors
        }, indent=2)
    }