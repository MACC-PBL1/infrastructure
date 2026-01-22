import json
import boto3
import joblib
import pandas as pd
import numpy as np
from io import StringIO, BytesIO
from datetime import datetime

s3 = boto3.client('s3')
sns = boto3.client('sns')
MODEL_BUCKET = 'zeek-flowmeter-logs'


model = None
scaler = None
metadata = None

def get_latest_keys(prefix="modelo/"):
    print(f"Buscando modelos en s3://{MODEL_BUCKET}/{prefix}...")
    response = s3.list_objects_v2(Bucket=MODEL_BUCKET, Prefix=prefix)

    if 'Contents' not in response:
        raise Exception(f"No hay archivos en s3://{MODEL_BUCKET}/{prefix}")

    timestamps = []

    for obj in response['Contents']:
        key = obj['Key']
        if key.startswith(f"{prefix}hdbscan_exfiltration_") and key.endswith(".pkl"):
            ts = key.replace(f"{prefix}hdbscan_exfiltration_", "").replace(".pkl", "")
            timestamps.append(ts)

    if not timestamps:
        raise Exception(f"No se encontraron modelos válidos con patrón hdbscan_exfiltration_ en {prefix}")
    latest_ts = sorted(timestamps)[-1]
    print(f"Versión más reciente encontrada: {latest_ts}")

    model_key    = f"{prefix}hdbscan_exfiltration_{latest_ts}.pkl"
    scaler_key   = f"{prefix}robust_scaler_{latest_ts}.pkl"
    metadata_key = f"{prefix}model_metadata_{latest_ts}.json"

    return model_key, scaler_key, metadata_key

def load_modelo():
    global model, scaler, metadata

    if model is None:
        print("Iniciando carga de modelos...")
        model_key, scaler_key, metadata_key = get_latest_keys()

        print(f"Descargando modelo: {model_key}")
        obj = s3.get_object(Bucket=MODEL_BUCKET, Key=model_key)
        
        model = joblib.load(BytesIO(obj['Body'].read()))

        print(f"Descargando scaler: {scaler_key}")
        obj = s3.get_object(Bucket=MODEL_BUCKET, Key=scaler_key)
        scaler = joblib.load(BytesIO(obj['Body'].read()))

        print(f"Descargando metadata: {metadata_key}")
        obj = s3.get_object(Bucket=MODEL_BUCKET, Key=metadata_key)
        metadata = json.loads(obj['Body'].read())

        print("Carga completa.")

def preprocess_csv(df):
    expected_features = [
        'flow_duration', 'fwd_pkts_tot', 'bwd_data_pkts_tot', 'fwd_pkts_per_sec',
        'down_up_ratio', 'fwd_header_size_min', 'bwd_header_size_min',
        'flow_SYN_flag_count', 'flow_RST_flag_count', 'fwd_pkts_payload.max',
        'bwd_pkts_payload.min', 'bwd_pkts_payload.max', 'fwd_iat.min',
        'fwd_iat.max', 'bwd_iat.std', 'flow_iat.min', 'payload_bytes_per_second',
        'bwd_bulk_rate', 'active.std', 'idle.min', 'idle.tot',
        'bwd_last_window_size'
    ]

    missing = [c for c in expected_features if c not in df.columns]
    if missing:
        print(f"ADVERTENCIA: Faltan columnas: {missing}. El proceso fallará si no se encuentran.")
        
    df_clean = df[expected_features].copy()
    for col in df_clean.columns:
        df_clean[col] = pd.to_numeric(df_clean[col], errors='coerce')

    df_clean = df_clean.dropna()
    df_clean = df_clean[np.isfinite(df_clean).all(axis=1)]
    
    return df_clean

def lambda_handler(event, context):
    try:
        load_modelo()

        bucket = event['Records'][0]['s3']['bucket']['name']
        key = event['Records'][0]['s3']['object']['key']
        
        print(f"Procesando archivo: s3://{bucket}/{key}")
        
        obj = s3.get_object(Bucket=bucket, Key=key)
        csv_content = obj['Body'].read().decode('utf-8')
        
        df = pd.read_csv(StringIO(csv_content), sep=',')
        
        if len(df.columns) == 1:
            print("Advertencia: Se detectó solo 1 columna con coma. Reintentando con punto y coma (;)...")
            df = pd.read_csv(StringIO(csv_content), sep=';')

        df.columns = df.columns.str.strip()
        
        print(f"Columnas encontradas en el CSV: {df.columns.tolist()}")
        print(f"Total registros leídos: {len(df)}")

        try:
            df_clean = preprocess_csv(df)
        except KeyError as e:
            print("ERROR CRÍTICO DE COLUMNAS.")
            print("El modelo espera:", [
                'flow_duration', 'fwd_pkts_tot', 'bwd_data_pkts_tot', 'fwd_pkts_per_sec',
                'down_up_ratio', 'fwd_header_size_min', 'bwd_header_size_min',
                'flow_SYN_flag_count', 'flow_RST_flag_count', 'fwd_pkts_payload.max',
                'bwd_pkts_payload.min', 'bwd_pkts_payload.max', 'fwd_iat.min',
                'fwd_iat.max', 'bwd_iat.std', 'flow_iat.min', 'payload_bytes_per_second',
                'bwd_bulk_rate', 'active.std', 'idle.min', 'idle.tot',
                'bwd_last_window_size'
            ])
            print("El CSV tiene:", df.columns.tolist())
            raise e

        print(f"Registros válidos para análisis: {len(df_clean)}")

        if len(df_clean) == 0:
            return {'statusCode': 200, 'body': json.dumps("No hay datos válidos para procesar")}

        X_scaled = scaler.transform(df_clean.values)

        print("Calculando scores de anomalía...")
        
        try:
            import hdbscan

            labels, strengths = hdbscan.approximate_predict(model, X_scaled)

            outlier_scores = 1.0 - strengths
            
        except AttributeError:

            print("⚠️ El modelo no soporta predicción directa. Usando fallback local...")

            params = metadata.get('hyperparameters', {})
            min_cluster = params.get('min_cluster_size', 100)
            if len(df_clean) < min_cluster:
                print(f"Ajustando min_cluster_size de {min_cluster} a {max(2, int(len(df_clean)/4))} por tamaño de archivo.")
                min_cluster = max(2, int(len(df_clean)/4))
            
            temp_model = hdbscan.HDBSCAN(
                min_cluster_size=min_cluster,
                min_samples=params.get('min_samples', 1),
                metric=params.get('metric', 'manhattan')
            )
            temp_model.fit(X_scaled)
            outlier_scores = temp_model.outlier_scores_

        if len(outlier_scores) != len(df_clean):
            print(f"ERROR: Mismatch de longitudes. Datos: {len(df_clean)}, Scores: {len(outlier_scores)}")
            outlier_scores = outlier_scores[:len(df_clean)]

        threshold_mod = metadata.get('anomaly_thresholds', {}).get('moderate', 0.85)
        threshold_sev = metadata.get('anomaly_thresholds', {}).get('severe', 0.95)

        is_severe = outlier_scores >= threshold_sev
        is_moderate = (outlier_scores >= threshold_mod) & (outlier_scores < threshold_sev)

        n_severe = int(is_severe.sum())
        n_moderate = int(is_moderate.sum())

        print(f"Resultados -> Severas: {n_severe}, Moderadas: {n_moderate}")

        results = {
            'timestamp': datetime.utcnow().isoformat(),
            'source_file': key,
            'processed_rows': len(df_clean),
            'anomalies': {
                'severe_count': n_severe,
                'moderate_count': n_moderate,
                'severe_indices': [int(i) for i in np.where(is_severe)[0][:100]] 
            }
        }
        if n_severe > 0:
            print(f"⚠️ ¡ALERTA! Se detectaron {n_severe} flujos maliciosos.")
            
            sns.publish(
               TopicArn='arn:aws:sns:us-east-1:512411987939:security-alerts', 
               Subject='[ALERTA] Exfiltración Detectada en S3',
               Message=f"Archivo analizado: {key}\n\n"
                       f"Resultados:\n"
                       f"- Total flujos: {len(df_clean)}\n"
                       f"- Anomalías Severas: {n_severe}\n"
                       f"- Anomalías Moderadas: {n_moderate}\n\n"
                       f"Verifique el archivo en la carpeta /results para más detalles."
            )
        output_key = f"results/{datetime.utcnow().strftime('%Y%m%d_%H%M%S')}_analysis.json"
        s3.put_object(
            Bucket=bucket,
            Key=output_key,
            Body=json.dumps(results, indent=2)
        )
        print(f"Resultados guardados en: {output_key}")

        return {
            'statusCode': 200,
            'body': json.dumps(results)
        }

    except Exception as e:
        print(f"ERROR FATAL: {str(e)}")
        raise e