import urllib.parse

def lambda_handler(event, context):
    # Get the bucket name and file name from the S3 event
    bucket = event['Records'][0]['s3']['bucket']['name']
    key = urllib.parse.unquote_plus(event['Records'][0]['s3']['object']['key'], encoding='utf-8')
    
    # Requirement 4.5 logic: Print specific message to CloudWatch
    print(f"Image received: {key}")
    
    return {
        'statusCode': 200,
        'body': f"Processed {key} from {bucket}"
    }
