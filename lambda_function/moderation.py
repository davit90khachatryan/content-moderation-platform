import os
import json
import uuid
from datetime import datetime
import boto3
import nltk
from nltk.sentiment import SentimentIntensityAnalyzer

nltk.data.path.append("/opt/python/nltk_data")

TABLE_NAME = os.environ.get("TABLE_NAME")
SQS_QUEUE_URL = os.environ.get("SQS_QUEUE_URL")

dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table(TABLE_NAME)
sqs = boto3.client("sqs")

def handler(event, context):
    try:
        body = json.loads(event["body"])
        comment = body.get("text", "")

        if not comment:
            return {"statusCode": 400, "body": json.dumps({"error": "Missing 'text' field"})}

        sia = SentimentIntensityAnalyzer()
        scores = sia.polarity_scores(comment)
        compound = scores["compound"]

        if compound >= 0:
            decision = "OK"
        elif compound >= -0.5:
            decision = "FLAGGED"
        else:
            decision = "BLOCK"

        response_data = {
            "comment": comment,
            "decision": decision,
            "scores": scores
        }

        if decision in ("FLAGGED", "BLOCK"):
            comment_id = str(uuid.uuid4())
            timestamp = datetime.utcnow().isoformat()

            table.put_item(
                Item={
                    "comment_id": comment_id,
                    "comment_text": comment,
                    "decision": decision,
                    "scores": json.dumps(scores),
                    "timestamp": timestamp
                }
            )

            # FIX: Log SQS Message Errors
            if SQS_QUEUE_URL:
                try:
                    response = sqs.send_message(
                        QueueUrl=SQS_QUEUE_URL,
                        MessageBody=json.dumps({
                            "comment_id": comment_id,
                            "comment_text": comment,
                            "decision": decision,
                            "scores": scores,
                            "timestamp": timestamp
                        })
                    )
                    print(f"SQS Message Sent! MessageId: {response['MessageId']}")
                except Exception as e:
                    print(f"Error sending message to SQS: {str(e)}")

            response_data["comment_id"] = comment_id

        return {"statusCode": 200, "body": json.dumps(response_data)}

    except Exception as e:
        print(f"Lambda Error: {str(e)}")
        return {"statusCode": 500, "body": json.dumps({"error": str(e)})}
