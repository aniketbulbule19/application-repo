# AWS Deployment Guide - Complete Walkthrough

This guide will walk you through deploying the entire presentation practice application to AWS, from initial setup to production deployment.

## 📋 Prerequisites

### 1. AWS Account Setup
- **AWS Account**: Create an account at https://aws.amazon.com
- **IAM User**: Create a user with appropriate permissions
- **Access Keys**: Generate Access Key ID and Secret Access Key

### 2. Local Environment Setup
- **AWS CLI**: Install AWS Command Line Interface
- **Node.js**: Version 16+ (already installed)
- **Python**: Version 3.9+ (for Lambda deployment)

## 🛠️ Step 1: Install and Configure AWS CLI

### For Windows:
1. **Download**: Go to https://aws.amazon.com/cli/
2. **Install**: Run the downloaded `.msi` file
3. **Verify**: Open PowerShell and run:
   ```powershell
   aws --version
   ```

### Configure AWS Credentials:
```powershell
aws configure
```

Enter the following when prompted:
- **AWS Access Key ID**: Your IAM user's access key
- **AWS Secret Access Key**: Your IAM user's secret key
- **Default region**: `us-east-1`
- **Default output format**: `json`

### Verify Configuration:
```powershell
aws sts get-caller-identity
```

You should see your AWS account information.

## 🏗️ Step 2: Deploy Backend Infrastructure

### Navigate to Backend Directory:
```powershell
cd backend
```

### Run Deployment Script:
```powershell
.\deploy.ps1
```

### What the Deployment Does:
1. ✅ **Creates S3 Bucket**: For audio storage with encryption
2. ✅ **Deploys Lambda Function**: With necessary permissions
3. ✅ **Sets up API Gateway**: With CORS enabled
4. ✅ **Configures CloudWatch**: For logging and monitoring
5. ✅ **Creates IAM Roles**: With minimal required permissions

### Expected Output:
```
🚀 Starting deployment of Presentation Practice Application...
✅ AWS CLI found: aws-cli/2.x.x
✅ AWS credentials verified
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

## 🔧 Step 3: Update Frontend Configuration

### Copy the API Gateway URL from the deployment output and update `src/config.ts`:

```typescript
export const config = {
  api: {
    // Replace with your actual API Gateway URL
    baseUrl: 'https://your-api-gateway-url.execute-api.us-east-1.amazonaws.com/prod',
    endpoints: {
      processRecording: '/process-recording'
    }
  },
  // ... rest of config
};
```

### Alternative: Use Environment Variable
Create a `.env` file in the root directory:
```bash
REACT_APP_API_URL=https://your-api-gateway-url.execute-api.us-east-1.amazonaws.com/prod
```

## 🌐 Step 4: Deploy Frontend

### Option A: AWS Amplify (Recommended)

1. **Go to AWS Amplify Console**
   - Navigate to AWS Console → Amplify
   - Click "New app" → "Host web app"

2. **Connect Repository**
   - Choose your Git provider (GitHub, GitLab, etc.)
   - Connect your repository
   - Select the main branch

3. **Configure Build Settings**
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

4. **Deploy**
   - Click "Save and deploy"
   - Wait for build to complete
   - Your app will be available at: `https://main.d1234567890.amplifyapp.com`

### Option B: S3 + CloudFront

1. **Create S3 Bucket for Frontend**
   ```powershell
   aws s3 mb s3://presentation-practice-frontend
   ```

2. **Enable Static Website Hosting**
   ```powershell
   aws s3 website s3://presentation-practice-frontend --index-document index.html --error-document index.html
   ```

3. **Build and Deploy**
   ```powershell
   cd ..
   npm run build
   aws s3 sync build/ s3://presentation-practice-frontend --delete
   ```

4. **Configure CloudFront** (for HTTPS)
   - Go to CloudFront console
   - Create distribution
   - Set S3 bucket as origin
   - Configure custom domain (optional)

## 🧪 Step 5: Test the Application

### 1. Open Your Application
- Navigate to your deployed frontend URL
- Ensure you're using HTTPS (required for microphone access)

### 2. Test Recording
- Click the green "Start Recording" button
- Allow microphone access when prompted
- Speak for 30-60 seconds
- Click "Stop Recording"

### 3. Verify Feedback
- Wait for processing (10-30 seconds)
- Check that feedback appears with:
  - Confidence score
  - Pronunciation suggestions
  - Overall feedback
  - Audio feedback button

## 📊 Step 6: Monitor and Optimize

### Check CloudWatch Logs
```powershell
aws logs describe-log-groups --log-group-name-prefix "/aws/lambda/presentation-practice"
```

### Monitor Costs
- Go to AWS Cost Explorer
- Set up billing alerts
- Monitor Lambda execution times

### Performance Optimization
- Adjust Lambda timeout if needed
- Monitor S3 storage usage
- Check API Gateway throttling

## 🔍 Troubleshooting

### Common Issues and Solutions

#### 1. CORS Errors
```
Access to fetch at '...' from origin '...' has been blocked by CORS policy
```
**Solution**: Verify API Gateway CORS configuration in CloudFormation template

#### 2. Lambda Timeout
```
Task timed out after 300.00 seconds
```
**Solution**: Increase Lambda timeout in `template.yaml`

#### 3. Microphone Access Denied
```
NotAllowedError: Permission denied
```
**Solution**: Ensure HTTPS and user grants microphone permission

#### 4. Audio Processing Failures
```
Failed to process recording
```
**Solution**: Check CloudWatch logs for detailed error messages

### Debug Commands

```powershell
# Check Lambda function status
aws lambda get-function --function-name presentation-practice-audio-processor

# View recent logs
aws logs tail /aws/lambda/presentation-practice-audio-processor --follow

# Test API endpoint
Invoke-RestMethod -Uri "https://your-api-url/process-recording" -Method POST -ContentType "application/json" -Body '{"audioData":"test","audioFormat":"webm","sampleRate":8000}'
```

## 💰 Cost Optimization

### Current Monthly Estimate: $56-84
- **Lambda**: $5-10
- **Transcribe**: $24
- **Nova Sonic**: $20-40
- **S3**: $1-2
- **API Gateway**: $5-10
- **CloudFront**: $1-2

### Optimization Tips
1. **Reduce Usage**: Limit to 50 sessions/month
2. **Shorter Recordings**: Encourage 5-10 minute presentations
3. **Cleanup**: Ensure S3 lifecycle policies are working
4. **Monitor**: Set up CloudWatch alarms for cost thresholds

## 🔒 Security Considerations

- ✅ All data encrypted in transit and at rest
- ✅ No persistent storage of audio data
- ✅ S3 bucket with public access blocked
- ✅ API Gateway rate limiting enabled
- ✅ Lambda function with minimal permissions

## 🧹 Cleanup

To remove all resources when you're done:
```powershell
aws cloudformation delete-stack --stack-name presentation-practice-stack --region us-east-1
```

## 📈 Next Steps

### Production Enhancements
1. **Custom Domain**: Set up a custom domain for your application
2. **SSL Certificate**: Configure SSL certificate in CloudFront
3. **Monitoring**: Set up CloudWatch alarms and dashboards
4. **Backup**: Implement backup strategies for critical data

### Feature Additions
1. **User Management**: Add Cognito for user authentication
2. **Analytics**: Implement detailed usage analytics
3. **Multi-language**: Add support for multiple languages
4. **Mobile App**: Create a React Native mobile version

## 🆘 Support

For additional help:
1. Check AWS service documentation
2. Review CloudWatch logs
3. Open an issue in the repository
4. Contact AWS support if needed

---

**🎉 Congratulations!** Your presentation practice application is now deployed and ready for production use! 