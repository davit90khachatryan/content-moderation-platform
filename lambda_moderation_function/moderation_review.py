import os
import json
import boto3
import traceback
from datetime import datetime

# Environment Variables
TABLE_NAME = os.getenv("TABLE_NAME")
if not TABLE_NAME:
    raise ValueError("Missing required environment variable: TABLE_NAME")

# AWS Clients
dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table(TABLE_NAME)

def handler(event, context):
    """Processes flagged comments from SQS and updates them in DynamoDB"""
    status_code = 200  # Assume success unless an error occurs
    errors = []

    print(f"Lambda request ID: {context.aws_request_id}")
    
    for record in event.get("Records", []):
        try:
            message_body = json.loads(record["body"])
            comment_id = message_body.get("comment_id")
            decision = message_body.get("decision")
            comment_text = message_body.get("comment_text")

            if not comment_id:
                raise ValueError("Missing 'comment_id' in message")

            print(f"Processing comment: {comment_id}, Decision: {decision}")

            # Update DynamoDB with review status
            table.update_item(
                Key={"comment_id": comment_id},
                UpdateExpression="SET review_status = :status, reviewed_at = :timestamp",
                ExpressionAttributeValues={
                    ":status": "REVIEWED",
                    ":timestamp": datetime.utcnow().isoformat()
                }
            )

            print(f"Successfully reviewed and updated comment: {comment_id}")

        except Exception as e:
            error_message = f"Error processing message: {record}. Exception: {traceback.format_exc()}"
            print(error_message)
            errors.append(error_message)
            status_code = 500  # Mark failure if any error occurs

    return {
        "statusCode": status_code,
        "body": json.dumps({
            "message": "Processing complete",
            "errors": errors if errors else None
        })
    }
