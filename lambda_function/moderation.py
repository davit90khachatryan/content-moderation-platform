import os
import json
import uuid
from datetime import datetime

import boto3
import nltk
from nltk.sentiment import SentimentIntensityAnalyzer

# Let NLTK find the VADER data in the Lambda layer
nltk.data.path.append("/opt/python/nltk_data")

TABLE_NAME = os.environ.get("TABLE_NAME")  # e.g. "FlaggedContent"
SQS_QUEUE_URL = os.environ.get("SQS_QUEUE_URL")

dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table(TABLE_NAME)

sqs = boto3.client("sqs")

def handler(event, context):
    try:
        body = json.loads(event["body"])
        comment = body.get("text", "")

        if not comment:
            return {
                "statusCode": 400,
                "body": json.dumps({"error": "Missing 'text' field"})
            }

        # VADER sentiment
        sia = SentimentIntensityAnalyzer()
        scores = sia.polarity_scores(comment)
        compound = scores["compound"]

        # Simple thresholds:
        #   - compound >=  0.0 => OK
        #   - -0.5 <= comp < 0 => FLAGGED
        #   - comp <  -0.5     => BLOCK
        if compound >= 0:
            decision = "OK"
        elif compound >= -0.5:
            decision = "FLAGGED"
        else:
            decision = "BLOCK"

        # If decision is FLAGGED or BLOCK, store in DynamoDB + push to SQS
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

            # Optional: push to SQS
            if SQS_QUEUE_URL:
                sqs.send_message(
                    QueueUrl=SQS_QUEUE_URL,
                    MessageBody=json.dumps({
                        "comment_id": comment_id,
                        "comment_text": comment,
                        "decision": decision,
                        "scores": scores,
                        "timestamp": timestamp
                    })
                )

        return {
            "statusCode": 200,
            "body": json.dumps({
                "comment": comment,
                "decision": decision,
                "scores": scores
            })
        }

    except Exception as e:
        print(f"Error: {str(e)}")
        return {
            "statusCode": 500,
            "body": json.dumps({"error": str(e)})
        }
