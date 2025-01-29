import json

# Predefined toxic keywords based on the dataset analysis
TOXIC_KEYWORDS = [
    "hate", "stupid", "idiot", "kill", "dumb", "trash", "moron", "racist", "bigot",
    "loser", "dumbass", "jerk", "fool", "scum", "garbage", "nonsense", "terrorist",
    "creep", "psychopath", "freak", "nazi", "dirtbag", "insane", "lunatic", "pathetic",
    "selfish", "brainless", "ignorant", "foolish", "hopeless", "coward", "snake",
    "toxic", "degenerate", "liar", "worthless", "miserable", "horrible"
]


def classify_comment(comment):
    """
    Simple toxicity detection based on keyword matching.
    """
    comment_lower = comment.lower()
    for keyword in TOXIC_KEYWORDS:
        if keyword in comment_lower:
            return "BLOCK"
    return "OK"

def handler(event, context):
    """
    AWS Lambda handler function.
    Processes input from API Gateway and returns moderation results.
    """
    try:
        # Parse the incoming request
        body = json.loads(event["body"])
        comment = body.get("text", None)
        
        if not comment:
            return {
                "statusCode": 400,
                "body": json.dumps({"error": "Missing 'text' field in request body"})
            }

        # Classify the comment
        prediction = classify_comment(comment)

        # Prepare the response
        response = {
            "comment": comment,
            "decision": prediction
        }

        return {
            "statusCode": 200,
            "body": json.dumps(response)
        }

    except Exception as e:
        print(f"Error: {str(e)}")
        return {
            "statusCode": 500,
            "body": json.dumps({"error": str(e)})
        }
