import requests
import json
import boto3
import time

# API Gateway URL
api_endpoint = "https://okwol6qpi8.execute-api.us-east-1.amazonaws.com/default/moderate"

# AWS Configuration
region = "us-east-1"
dynamodb_table_name = "FlaggedContent"
sqs_queue_url = "https://sqs.us-east-1.amazonaws.com/039612865454/FlaggedContentQueue"

# AWS Clients
dynamodb = boto3.resource("dynamodb", region_name=region)
table = dynamodb.Table(dynamodb_table_name)
sqs = boto3.client("sqs", region_name=region)

# 🔹 Test Cases
test_cases = {
    "OK": "This is a positive and neutral statement.",
    "FLAGGED": "This comment is not very nice.",
    "BLOCK": "I will hurt you badly!"
}

for decision, comment_text in test_cases.items():
    print(f"\n🔹 Testing {decision} comment...")
    
    # 🔹 Step 1: Send the comment for moderation via API Gateway
    payload = {"text": comment_text}
    response = requests.post(api_endpoint, json=payload)

    # Check API response
    assert response.status_code == 200, f"API request failed! Status: {response.status_code}"
    response_data = response.json()

    # Ensure decision matches expected
    assert response_data["decision"] == decision, f"Expected {decision}, got {response_data['decision']}"

    print(f"API Response: {response_data}")

    # If comment is OK, skip DB & SQS check
    if decision == "OK":
        print("No further action needed for OK comment.")
        continue

    # Extract comment_id for further validation
    print("comment_id:", response_data)
    assert "comment_id" in response_data, "API did not return comment_id for FLAGGED/BLOCKED comment!"
    comment_id = response_data["comment_id"]
    print(f"Comment stored with ID: {comment_id}")

    # 🔹 Step 2: Check DynamoDB for the comment
    print(f"🔹 Checking DynamoDB for comment_id: {comment_id}...")
    time.sleep(3)  # Allow AWS some time to process
    dynamodb_response = table.get_item(Key={"comment_id": comment_id})

    assert "Item" in dynamodb_response, f"Comment ID {comment_id} not found in DynamoDB!"
    reviewed_comment = dynamodb_response["Item"]

    # Validate stored fields
    assert reviewed_comment["decision"] == decision, f"DynamoDB decision mismatch! Expected {decision}, got {reviewed_comment['decision']}"
    print(f"DynamoDB update verified for {decision} comment.")

    # 🔹 Step 3: Check SQS for FLAGGED comments (optional)
    if decision == "FLAGGED":
        print("🔹 Checking SQS for flagged comment...")
        sqs_response = sqs.receive_message(
            QueueUrl=sqs_queue_url,
            MaxNumberOfMessages=5,
            WaitTimeSeconds=10
        )

        # Validate message exists
        assert "Messages" in sqs_response, "No message found in SQS for FLAGGED comment!"
        print(f"SQS message received: {sqs_response['Messages'][0]['Body']}")

print("\n🎉 All moderation scenarios PASSED successfully!")