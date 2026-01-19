import json
import boto3
import pymysql
import os

s3 = boto3.client('s3')
ssm = boto3.client('ssm')

def get_db_password():
    param_name = os.environ['DB_PASSWORD_PARAM']
    response = ssm.get_parameter(Name=param_name, WithDecryption=True)
    return response['Parameter']['Value']

def handler(event, context):
    print(f"Event: {json.dumps(event)}")
    
    # Get DB credentials
    db_host = os.environ['DB_HOST']
    db_user = os.environ['DB_USER']
    db_name = os.environ['DB_NAME']
    db_password = get_db_password()
    
    try:
        # Connect to RDS
        conn = pymysql.connect(
            host=db_host,
            user=db_user,
            password=db_password,
            database=db_name
        )
        
        print("Connected to database")
        
        # Process S3 event
        for record in event['Records']:
            bucket = record['s3']['bucket']['name']
            key = record['s3']['object']['key']
            
            print(f"Processing: s3://{bucket}/{key}")
            
            # Get object from S3
            obj = s3.get_object(Bucket=bucket, Key=key)
            content = obj['Body'].read().decode('utf-8')
            
            # Parse JSON
            log_data = json.loads(content)
            
            # Insert into database (ejemplo simple)
            with conn.cursor() as cursor:
                sql = "INSERT INTO zeek_logs (data) VALUES (%s)"
                cursor.execute(sql, (json.dumps(log_data),))
            
            conn.commit()
            print(f"Inserted log from {key}")
        
        conn.close()
        return {'statusCode': 200, 'body': 'Success'}
        
    except Exception as e:
        print(f"Error: {str(e)}")
        raise e