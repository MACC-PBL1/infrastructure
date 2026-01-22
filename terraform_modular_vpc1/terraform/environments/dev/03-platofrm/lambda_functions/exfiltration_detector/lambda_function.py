import json
import boto3
import joblib
import pandas as pd
import numpy as np
import os
from io import StringIO, BytesIO
from datetime import datetime

# Clientes AWS
s3 = boto3.client('s3')
sns = boto3.client('sns') # [cite: 133]

# Configuración desde Variables de Entorno
MODEL_BUCKET = os.environ.get('MODEL_BUCKET') # [cite: 40]
SNS_TOPIC_ARN = os.environ.get('SNS_TOPIC_ARN')

# Variables globales para cache (Warm Start) [cite: 41]
model = None
scaler = None
metadata = None

def get_latest_keys(prefix="modelo/"):
    # Lógica del PDF para buscar los archivos más recientes [cite: 45-66]
    response = s3.list_objects_v2(Bucket=MODEL_BUCKET, Prefix=prefix)
    if 'Contents' not in response:
        raise Exception(f"No hay archivos en s3://{MODEL_BUCKET}/{prefix}")

    timestamps = []
    for obj in response['Contents']:
        key = obj['Key']
        if key.startswith("modelo/hdbscan_exfiltration_detector_") and key.endswith(".pkl"):
            ts = key.replace("modelo/hdbscan_exfiltration_detector_", "").replace(".pkl", "")
            timestamps.append(ts)
            
    if not timestamps:
        raise Exception("No se encontraron modelos HDBSCAN válidos")
        
    latest_ts = sorted(timestamps)[-1]
    
    return (
        f"modelo/hdbscan_exfiltration_detector_{latest_ts}.pkl",
        f"modelo/robust_scaler_{latest_ts}.pkl",
        f"modelo/model_metadata_{latest_ts}.json"
    )

def load_modelo():
    global model, scaler, metadata
    if model is None:
        print("Cargando modelos...")
        model_key, scaler_key, metadata_key = get_latest_keys()
        
        # Carga desde S3 [cite: 76-83]
        obj_m = s3.get_object(Bucket=MODEL_BUCKET, Key=model_key)
        model = joblib.load(BytesIO(obj_m['Body'].read()))
        
        obj_s = s3.get_object(Bucket=MODEL_BUCKET, Key=scaler_key)
        scaler = joblib.load(BytesIO(obj_s['Body'].read()))
        
        obj_meta = s3.get_object(Bucket=MODEL_BUCKET, Key=metadata_key)
        metadata = json.loads(obj_meta['Body'].read())

def preprocess_csv(df):
    # Lógica de limpieza [cite: 85-89]
    expected = metadata['feature_names']
    df = df[expected].copy()
    df = df.dropna()
    df = df[np.isfinite(df).all(axis=1)]
    return df

def lambda_handler(event, context):
    try:
        load_modelo()
        
        # Leer evento S3 [cite: 91-95]
        bucket = event['Records'][0]['s3']['bucket']['name']
        key = event['Records'][0]['s3']['object']['key']
        print(f"Procesando: s3://{bucket}/{key}")
        
        obj = s3.get_object(Bucket=bucket, Key=key)
        df = pd.read_csv(StringIO(obj['Body'].read().decode('utf-8')), sep=';')
        
        df_clean = preprocess_csv(df)
        if len(df_clean) == 0:
            return {'statusCode': 200, 'body': 'No hay datos válidos'}

        # Predicción [cite: 101-114]
        X_scaled = scaler.transform(df_clean.values)
        model.fit_predict(X_scaled) # En inferencia usualmente es predict, pero el PDF usa fit_predict
        outlier_scores = model.outlier_scores_
        
        t95 = metadata['anomaly_thresholds']['moderate']
        t99 = metadata['anomaly_thresholds']['severe']
        
        severe = outlier_scores >= t99
        moderate = (outlier_scores >= t95) & (outlier_scores < t99)
        n_severe = severe.sum()
        n_moderate = moderate.sum()

        results = {
            'timestamp': datetime.utcnow().isoformat(),
            'source_file': key,
            'severe_anomalies': int(n_severe),
            'moderate_anomalies': int(n_moderate)
        }

        # Guardar resultados [cite: 125-131]
        output_key = f"results/{datetime.utcnow().strftime('%Y%m%d_%H%M%S')}_results.json"
        s3.put_object(Bucket=bucket, Key=output_key, Body=json.dumps(results, indent=2))

        # Notificación SNS [cite: 132-138]
        if n_severe > 0 and SNS_TOPIC_ARN:
            sns.publish(
                TopicArn=SNS_TOPIC_ARN,
                Subject='Exfiltración detectada',
                Message=f"Se detectaron {n_severe} anomalías severas en {key}"
            )

        return {'statusCode': 200, 'body': json.dumps(results)}
        
    except Exception as e:
        print(e)
        raise e