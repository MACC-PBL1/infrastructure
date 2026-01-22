import json
import boto3
import csv
from datetime import datetime, timedelta
from io import StringIO

s3 = boto3.client('s3')

# Get bucket name from environment variable
BUCKET = os.environ.get('BUCKET_NAME', 'zeek-flowmeter-logs')
CONN_PREFIX = 'conn/'
FLOW_PREFIX = 'flowmeter/'
PROCESSED_PREFIX = 'processed/'
OUTPUT_PREFIX = 'merged-logs/'
STATE_KEY = 'state/last_processed.json'

def lambda_handler(event, context):
    last_run = get_last_run_time()
    current_time = datetime.now()
    
    conn_files = list_new_files(CONN_PREFIX, last_run)
    flow_files = list_new_files(FLOW_PREFIX, last_run)
    
    if not conn_files or not flow_files:
        print("No hay archivos nuevos en ambas carpetas")
        return {'processed': 0}
    
    # Consolidar todos los logs
    all_conn_data = []
    for file in conn_files:
        all_conn_data.extend(read_log(file))
    
    all_flow_data = []
    for file in flow_files:
        all_flow_data.extend(read_log(file))
    
    # Merge por UID
    merged = {}
    for record in all_conn_data:
        uid = record.get('uid')
        if uid:
            merged[uid] = record
    
    for record in all_flow_data:
        uid = record.get('uid')
        if uid:
            if uid in merged:
                merged[uid].update(record)
            else:
                merged[uid] = record
    
    # Convertir a CSV
    merged_list = list(merged.values())
    if not merged_list:
        print("No hay registros para procesar")
        return {'processed': 0}
    
    # Obtener todas las columnas
    all_keys = set()
    for record in merged_list:
        all_keys.update(record.keys())
    fieldnames = sorted(all_keys)
    
    # Escribir CSV
    csv_buffer = StringIO()
    writer = csv.DictWriter(csv_buffer, fieldnames=fieldnames)
    writer.writeheader()
    writer.writerows(merged_list)
    
    # Guardar en S3
    timestamp = current_time.strftime('%Y%m%d-%H%M%S')
    output_key = f"{OUTPUT_PREFIX}{timestamp}.csv"
    s3.put_object(
        Bucket=BUCKET,
        Key=output_key,
        Body=csv_buffer.getvalue()
    )
    
    # Mover procesados
    for file in conn_files + flow_files:
        move_to_processed(file)
    
    save_last_run_time(current_time)
    
    print(f"Merged {len(merged)} records -> {output_key}")
    return {'processed': len(merged), 'output': output_key}

def list_new_files(prefix, since):
    response = s3.list_objects_v2(Bucket=BUCKET, Prefix=prefix)
    files = []
    if 'Contents' in response:
        for obj in response['Contents']:
            if obj['Key'].endswith(('.log', '.json')) and \
               obj['LastModified'].replace(tzinfo=None) > since:
                files.append(obj['Key'])
    return files

def read_log(key):
    obj = s3.get_object(Bucket=BUCKET, Key=key)
    content = obj['Body'].read().decode('utf-8')
    
    # NDJSON
    if '\n' in content and content.strip().startswith('{'):
        return [json.loads(line) for line in content.strip().split('\n') if line]
    # JSON array
    return json.loads(content)

def move_to_processed(key):
    filename = key.split('/')[-1]
    new_key = f"{PROCESSED_PREFIX}{filename}"
    s3.copy_object(
        Bucket=BUCKET,
        CopySource={'Bucket': BUCKET, 'Key': key},
        Key=new_key
    )
    s3.delete_object(Bucket=BUCKET, Key=key)

def get_last_run_time():
    try:
        obj = s3.get_object(Bucket=BUCKET, Key=STATE_KEY)
        data = json.loads(obj['Body'].read())
        return datetime.fromisoformat(data['last_run'])
    except:
        return datetime.now() - timedelta(minutes=10)

def save_last_run_time(time):
    s3.put_object(
        Bucket=BUCKET,
        Key=STATE_KEY,
        Body=json.dumps({'last_run': time.isoformat()})
    )