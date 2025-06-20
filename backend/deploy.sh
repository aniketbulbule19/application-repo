#!/bin/bash

# Presentation Practice App Deployment Script
# This script deploys the Lambda function and infrastructure to AWS

set -e

# Configuration
PROJECT_NAME="presentation-practice"
REGION="us-east-1"
STACK_NAME="${PROJECT_NAME}-stack"

echo "🚀 Starting deployment of Presentation Practice Application..."

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo "❌ AWS CLI is not installed. Please install it first."
    exit 1
fi

# Check if AWS credentials are configured
if ! aws sts get-caller-identity &> /dev/null; then
    echo "❌ AWS credentials are not configured. Please run 'aws configure' first."
    exit 1
fi

echo "✅ AWS CLI and credentials verified"

# Check if Nova Sonic API key is provided
if [ -z "$NOVA_SONIC_API_KEY" ]; then
    echo "❌ Error: NOVA_SONIC_API_KEY environment variable is required"
    echo "Please set your Nova Sonic API key:"
    echo "export NOVA_SONIC_API_KEY='your-api-key-here'"
    exit 1
fi

echo "🔑 Nova Sonic API key found"

# Create deployment package for Lambda
echo "📦 Creating Lambda deployment package..."

# Create a temporary directory for packaging
TEMP_DIR=$(mktemp -d)
cp lambda_function.py "$TEMP_DIR/"
cp requirements.txt "$TEMP_DIR/"

# Install dependencies
cd "$TEMP_DIR"
pip install -r requirements.txt -t . --no-deps

# Create ZIP file
zip -r lambda-deployment.zip . -x "*.pyc" "__pycache__/*" "*.DS_Store"

# Move ZIP file to project directory
cd - > /dev/null
mv "$TEMP_DIR/lambda-deployment.zip" ./lambda-deployment.zip

# Clean up temporary directory
rm -rf "$TEMP_DIR"

echo "✅ Lambda deployment package created"

# Deploy CloudFormation stack
echo "🚀 Deploying CloudFormation stack..."
aws cloudformation deploy \
    --template-file template.yaml \
    --stack-name presentation-practice-stack \
    --parameter-overrides \
        ProjectName=presentation-practice \
        NovaSonicApiKey=$NOVA_SONIC_API_KEY \
    --capabilities CAPABILITY_NAMED_IAM \
    --region us-east-1

echo "✅ CloudFormation stack deployed"

# Update Lambda function with actual code
echo "📝 Updating Lambda function with actual code..."

# Get the Lambda function name from CloudFormation
LAMBDA_FUNCTION_NAME=$(aws cloudformation describe-stacks \
    --stack-name "$STACK_NAME" \
    --region "$REGION" \
    --query 'Stacks[0].Outputs[?OutputKey==`LambdaFunctionArn`].OutputValue' \
    --output text | cut -d'/' -f2)

# Update the Lambda function code
aws lambda update-function-code \
    --function-name "$LAMBDA_FUNCTION_NAME" \
    --zip-file fileb://lambda-deployment.zip \
    --region "$REGION"

echo "✅ Lambda function updated"

# Get the API Gateway URL
API_URL=$(aws cloudformation describe-stacks \
    --stack-name "$STACK_NAME" \
    --region "$REGION" \
    --query 'Stacks[0].Outputs[?OutputKey==`ApiGatewayUrl`].OutputValue' \
    --output text)

echo "🎉 Deployment completed successfully!"
echo ""
echo "📋 Deployment Summary:"
echo "   Stack Name: $STACK_NAME"
echo "   Region: $REGION"
echo "   API Gateway URL: $API_URL"
echo ""
echo "🔧 Next Steps:"
echo "   1. Update the frontend API URL in src/App.tsx to: $API_URL"
echo "   2. Build and deploy the frontend to AWS Amplify or S3"
echo "   3. Test the application"
echo ""
echo "🧹 Cleanup:"
echo "   To remove all resources, run: aws cloudformation delete-stack --stack-name $STACK_NAME --region $REGION" 