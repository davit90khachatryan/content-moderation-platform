# NLTK + Regex + VADER Setup for Python 3.9 x86_64 on AWS Lambda

Step-by-step guide for building a Lambda layer with `nltk`, `regex`, and the VADER lexicon for **Python 3.9 x86_64** on AWS. It also shows how to package Lambda function code and test via API Gateway.


## 1. Build the NLTK Layer in Docker

1. **Open** a shell in a Docker container matching **Python 3.9 x86_64**:

   ```bash
   docker run --rm -it \
     --platform linux/amd64 \
     --entrypoint /bin/bash \
     -v "$(pwd)/nltk_layer:/tmp/layer" \
     public.ecr.aws/lambda/python:3.9


cd /tmp/layer
yum install -y zip  # if zip isn't installed
rm -rf python       # remove any old leftover
pip3 install --target=python nltk regex

# Expose the local folder to Python
export PYTHONPATH="$PWD/python"

# Download the VADER lexicon into python/nltk_data
python3 -m nltk.downloader -d ./python/nltk_data vader_lexicon


zip -r nltk_layer.zip python
exit

# Package the Lambda Function
zip lambda_function.zip lambda_function/moderation.py


# Test the Functionality via API Gateway
curl -X POST \
  -H "Content-Type: application/json" \
  -d '{"text": "This is a test comment"}' \
  https://wli4bq67eg.execute-api.us-east-1.amazonaws.com/default/moderate
