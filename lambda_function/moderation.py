import json

def handler(event, context):
    print(f"Received event: {json.dumps(event)}")
    return {
        "statusCode": 200,
        "body": "Lambda is working!"
    }
