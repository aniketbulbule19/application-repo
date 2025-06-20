# Deployment Guide - Presentation Practice Application

This guide will walk you through deploying the complete presentation practice application to AWS.

## Prerequisites

1. **AWS Account** with appropriate permissions
2. **AWS CLI** installed and configured
3. **Node.js 16+** and npm
4. **Python 3.9+** (for Lambda deployment)

## Step 1: AWS Setup

### Configure AWS CLI
```bash
aws configure
```
Enter your AWS Access Key ID, Secret Access Key, default region (us-east-1), and output format (json).

### Verify AWS Access
```bash
aws sts get-caller-identity
```

## Step 2: Deploy Backend Infrastructure

### Navigate to Backend Directory
```bash
cd backend
```

### Make Deployment Script Executable
```bash
chmod +x deploy.sh
```

### Run Deployment
```bash
./deploy.sh
```

This script will:
- ✅ Create S3 bucket for audio storage
- ✅ Deploy Lambda function with necessary permissions
- ✅ Set up API Gateway with CORS enabled
- ✅ Configure CloudWatch logging
- ✅ Output the API Gateway URL

### Expected Output
```
🚀 Starting deployment of Presentation Practice Application...
✅ AWS CLI and credentials verified
📦 Creating Lambda deployment package...
✅ Lambda deployment package created
🏗️  Deploying CloudFormation stack...
✅ CloudFormation stack deployed
📝 Updating Lambda function with actual code...
✅ Lambda function updated
🎉 Deployment completed successfully!

📋 Deployment Summary:
   Stack Name: presentation-practice-stack
   Region: us-east-1
   API Gateway URL: https://abc123.execute-api.us-east-1.amazonaws.com/prod/process-recording
```

## Step 3: Configure Frontend

### Update API URL
Copy the API Gateway URL from the deployment output and update `src/config.ts`:

```typescript
export const config = {
  api: {
    baseUrl: 'https://your-api-gateway-url.execute-api.us-east-1.amazonaws.com/prod',
    endpoints: {
      processRecording: '/process-recording'
    }
  },
  // ... rest of config
};
```

### Alternative: Environment Variable
Create a `.env` file in the root directory:

```bash
REACT_APP_API_URL=https://your-api-gateway-url.execute-api.us-east-1.amazonaws.com/prod
```

## Step 4: Deploy Frontend

### Option A: AWS Amplify (Recommended)

1. **Connect Repository**
   - Go to AWS Amplify Console
   - Click "New app" → "Host web app"
   - Connect your Git repository

2. **Configure Build Settings**
   ```yaml
   version: 1
   frontend:
     phases:
       preBuild:
         commands:
           - npm install
       build:
         commands:
           - npm run build
     artifacts:
       baseDirectory: build
       files:
         - '**/*'
   ```

3. **Deploy**
   - Amplify will automatically build and deploy your app
   - You'll get a URL like: `https://main.d1234567890.amplifyapp.com`

### Option B: S3 + CloudFront

1. **Create S3 Bucket**
   ```bash
   aws s3 mb s3://presentation-practice-frontend
   ```

2. **Enable Static Website Hosting**
   ```bash
   aws s3 website s3://presentation-practice-frontend --index-document index.html --error-document index.html
   ```

3. **Build and Deploy**
   ```bash
   npm run build
   aws s3 sync build/ s3://presentation-practice-frontend --delete
   ```

4. **Configure CloudFront** (optional for HTTPS)
   - Create CloudFront distribution
   - Set S3 bucket as origin
   - Configure custom domain (optional)

## Step 5: Test the Application

1. **Open the Application**
   - Navigate to your deployed frontend URL
   - Ensure you're using HTTPS (required for microphone access)

2. **Test Recording**
   - Click the green "Start Recording" button
   - Allow microphone access when prompted
   - Speak for 30-60 seconds
   - Click "Stop Recording"

3. **Verify Feedback**
   - Wait for processing (should take 10-30 seconds)
   - Check that feedback appears with:
     - Confidence score
     - Pronunciation suggestions
     - Overall feedback
     - Audio feedback (if enabled)

## Step 6: Monitor and Optimize

### Check CloudWatch Logs
```bash
aws logs describe-log-groups --log-group-name-prefix "/aws/lambda/presentation-practice"
```

### Monitor Costs
- Check AWS Cost Explorer
- Set up billing alerts
- Monitor Lambda execution times

### Performance Optimization
- Adjust Lambda timeout if needed
- Monitor S3 storage usage
- Check API Gateway throttling

## Troubleshooting

### Common Issues

1. **CORS Errors**
   ```
   Access to fetch at '...' from origin '...' has been blocked by CORS policy
   ```
   **Solution**: Verify API Gateway CORS configuration in CloudFormation template

2. **Lambda Timeout**
   ```
   Task timed out after 300.00 seconds
   ```
   **Solution**: Increase Lambda timeout in `template.yaml`

3. **Microphone Access Denied**
   ```
   NotAllowedError: Permission denied
   ```
   **Solution**: Ensure HTTPS and user grants microphone permission

4. **Audio Processing Failures**
   ```
   Failed to process recording
   ```
   **Solution**: Check CloudWatch logs for detailed error messages

### Debug Commands

```bash
# Check Lambda function status
aws lambda get-function --function-name presentation-practice-audio-processor

# View recent logs
aws logs tail /aws/lambda/presentation-practice-audio-processor --follow

# Test API endpoint
curl -X POST https://your-api-url/process-recording \
  -H "Content-Type: application/json" \
  -d '{"audioData":"test","audioFormat":"webm","sampleRate":8000}'
```

## Cost Optimization

### Current Monthly Estimate: $56-84
- Lambda: $5-10
- Transcribe: $24
- Nova Sonic: $20-40
- S3: $1-2
- API Gateway: $5-10
- CloudFront: $1-2

### Optimization Tips
1. **Reduce Usage**: Limit to 50 sessions/month
2. **Shorter Recordings**: Encourage 5-10 minute presentations
3. **Cleanup**: Ensure S3 lifecycle policies are working
4. **Monitor**: Set up CloudWatch alarms for cost thresholds

## Security Considerations

- ✅ All data encrypted in transit and at rest
- ✅ No persistent storage of audio data
- ✅ S3 bucket with public access blocked
- ✅ API Gateway rate limiting enabled
- ✅ Lambda function with minimal permissions

## Cleanup

To remove all resources:
```bash
aws cloudformation delete-stack --stack-name presentation-practice-stack --region us-east-1
```

## Support

For additional help:
1. Check AWS service documentation
2. Review CloudWatch logs
3. Open an issue in the repository
4. Contact AWS support if needed

---

**🎉 Congratulations!** Your presentation practice application is now deployed and ready to use! 