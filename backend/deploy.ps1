# Presentation Practice App Deployment Script for Windows
# This script deploys the Lambda function and infrastructure to AWS

# Configuration
$PROJECT_NAME = "presentation-practice"
$REGION = "us-east-1"
$STACK_NAME = "$PROJECT_NAME-stack"

Write-Host "🚀 Starting deployment of Presentation Practice Application..." -ForegroundColor Green

# Check if AWS CLI is installed
try {
    $awsVersion = aws --version 2>$null
    if ($LASTEXITCODE -ne 0) {
        throw "AWS CLI not found"
    }
    Write-Host "✅ AWS CLI found: $awsVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ AWS CLI is not installed. Please install it first." -ForegroundColor Red
    Write-Host "   Download from: https://aws.amazon.com/cli/" -ForegroundColor Yellow
    exit 1
}

# Check if AWS credentials are configured
try {
    $identity = aws sts get-caller-identity 2>$null
    if ($LASTEXITCODE -ne 0) {
        throw "AWS credentials not configured"
    }
    Write-Host "✅ AWS credentials verified" -ForegroundColor Green
    Write-Host "   Account: $($identity | ConvertFrom-Json | Select-Object -ExpandProperty Account)" -ForegroundColor Cyan
} catch {
    Write-Host "❌ AWS credentials are not configured. Please run 'aws configure' first." -ForegroundColor Red
    exit 1
}

# Check if Nova Sonic API key is provided
if (-not $env:NOVA_SONIC_API_KEY) {
    Write-Host "❌ Error: NOVA_SONIC_API_KEY environment variable is required" -ForegroundColor Red
    Write-Host "Please set your Nova Sonic API key:" -ForegroundColor Yellow
    Write-Host "`$env:NOVA_SONIC_API_KEY = 'your-api-key-here'" -ForegroundColor Cyan
    exit 1
}

Write-Host "🔑 Nova Sonic API key found" -ForegroundColor Green

# Create deployment package for Lambda
Write-Host "📦 Creating Lambda deployment package..." -ForegroundColor Yellow

# Create a temporary directory for packaging
$TEMP_DIR = New-TemporaryFile | ForEach-Object { Remove-Item $_; New-Item -ItemType Directory -Path $_ }
Copy-Item "lambda_function.py" "$TEMP_DIR\"
Copy-Item "requirements.txt" "$TEMP_DIR\"

# Install dependencies
Set-Location $TEMP_DIR
pip install -r requirements.txt -t . --no-deps

# Create ZIP file
Compress-Archive -Path * -DestinationPath "lambda-deployment.zip" -Force

# Move ZIP file to project directory
Set-Location ..
Move-Item "$TEMP_DIR\lambda-deployment.zip" ".\lambda-deployment.zip"

# Clean up temporary directory
Remove-Item $TEMP_DIR -Recurse -Force

Write-Host "✅ Lambda deployment package created" -ForegroundColor Green

# Deploy CloudFormation stack
Write-Host "🚀 Deploying CloudFormation stack..." -ForegroundColor Green
aws cloudformation deploy `
    --template-file template.yaml `
    --stack-name presentation-practice-stack `
    --parameter-overrides `
        ProjectName=presentation-practice `
        NovaSonicApiKey=$env:NOVA_SONIC_API_KEY `
    --capabilities CAPABILITY_NAMED_IAM `
    --region us-east-1

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ CloudFormation deployment failed" -ForegroundColor Red
    exit 1
}

Write-Host "✅ CloudFormation stack deployed" -ForegroundColor Green

# Update Lambda function with actual code
Write-Host "📝 Updating Lambda function with actual code..." -ForegroundColor Yellow

# Get the Lambda function name from CloudFormation
$LAMBDA_ARN = aws cloudformation describe-stacks `
    --stack-name $STACK_NAME `
    --region $REGION `
    --query 'Stacks[0].Outputs[?OutputKey==`LambdaFunctionArn`].OutputValue' `
    --output text

$LAMBDA_FUNCTION_NAME = $LAMBDA_ARN.Split('/')[-1]

# Update the Lambda function code
aws lambda update-function-code `
    --function-name $LAMBDA_FUNCTION_NAME `
    --zip-file fileb://lambda-deployment.zip `
    --region $REGION

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Lambda function update failed" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Lambda function updated" -ForegroundColor Green

# Get the API Gateway URL
$API_URL = aws cloudformation describe-stacks `
    --stack-name $STACK_NAME `
    --region $REGION `
    --query 'Stacks[0].Outputs[?OutputKey==`ApiGatewayUrl`].OutputValue' `
    --output text

Write-Host "🎉 Deployment completed successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Deployment Summary:" -ForegroundColor Cyan
Write-Host "   Stack Name: $STACK_NAME" -ForegroundColor White
Write-Host "   Region: $REGION" -ForegroundColor White
Write-Host "   API Gateway URL: $API_URL" -ForegroundColor White
Write-Host ""
Write-Host "🔧 Next Steps:" -ForegroundColor Yellow
Write-Host "   1. Update the frontend API URL in src/config.ts to: $API_URL" -ForegroundColor White
Write-Host "   2. Build and deploy the frontend to AWS Amplify or S3" -ForegroundColor White
Write-Host "   3. Test the application" -ForegroundColor White
Write-Host ""
Write-Host "🧹 Cleanup:" -ForegroundColor Yellow
Write-Host "   To remove all resources, run: aws cloudformation delete-stack --stack-name $STACK_NAME --region $REGION" -ForegroundColor White 