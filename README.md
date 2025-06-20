# Presentation Practice Application

A web application for practicing presentations with AI-powered feedback using AWS services. The application records audio presentations and provides detailed feedback on confidence, pronunciation, and overall delivery.

## Features

- 🎤 **Audio Recording**: Record presentations up to 20 minutes with 8kHz audio for cost optimization
- 🤖 **AI Analysis**: Uses AWS Nova Sonic for sentiment analysis, confidence scoring, and pronunciation analysis
- 🔊 **Audio Feedback**: Receives feedback in audio format using Nova Sonic speech-to-speech
- 📊 **Visual Feedback**: Displays confidence scores, pronunciation mistakes, and improvement suggestions
- 🌐 **Real-time Processing**: Streams audio directly to AWS services for immediate analysis
- 💰 **Cost Optimized**: Designed for minimal AWS costs with efficient resource usage

## Architecture

### Frontend
- **React/TypeScript**: Modern web application with responsive design
- **Audio API**: Browser-based audio recording with 8kHz sample rate
- **Real-time UI**: Live recording indicator and processing status

### Backend (AWS Services)
- **AWS Lambda**: Serverless function for audio processing
- **Amazon Transcribe**: Speech-to-text conversion
- **AWS Nova Sonic**: AI analysis for confidence, pronunciation, and feedback
- **Amazon S3**: Temporary audio storage with automatic cleanup
- **API Gateway**: RESTful API endpoints
- **CloudFront**: Global content delivery

### Cost Optimization
- 8kHz audio recording (reduces bandwidth and processing costs)
- Automatic cleanup of temporary files
- No persistent storage of audio data
- Efficient Lambda function design

## Prerequisites

- AWS Account with appropriate permissions
- AWS CLI installed and configured
- Node.js 16+ and npm
- Python 3.9+ (for Lambda deployment)

## Installation & Deployment

### 1. Clone and Setup

```bash
git clone <repository-url>
cd presentation-practice-app
npm install
```

### 2. Deploy AWS Infrastructure

```bash
cd backend
chmod +x deploy.sh
./deploy.sh
```

The deployment script will:
- Create S3 bucket for audio storage
- Deploy Lambda function with necessary permissions
- Set up API Gateway
- Configure CloudFront distribution
- Output the API Gateway URL

### 3. Update Frontend Configuration

After deployment, update the API URL in `src/App.tsx`:

```typescript
// Replace the placeholder URL with your actual API Gateway URL
const response = await fetch('YOUR_API_GATEWAY_URL', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
  },
  body: JSON.stringify({
    audioData: base64Audio,
    audioFormat: 'webm',
    sampleRate: 8000
  })
});
```

### 4. Deploy Frontend

#### Option A: AWS Amplify (Recommended)

1. Connect your repository to AWS Amplify
2. Configure build settings:
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

#### Option B: S3 + CloudFront

```bash
npm run build
aws s3 sync build/ s3://your-bucket-name --delete
```

### 5. Test the Application

1. Open the deployed application
2. Click the green "Start Recording" button
3. Speak for a few minutes
4. Click "Stop Recording"
5. Wait for processing and review feedback

## Configuration

### Environment Variables

The Lambda function uses these environment variables:

- `S3_BUCKET`: S3 bucket name for audio storage
- `AWS_REGION`: AWS region for services

### Audio Settings

- **Sample Rate**: 8kHz (cost optimized)
- **Channels**: Mono
- **Format**: WebM with Opus codec
- **Max Duration**: 20 minutes

### AWS Service Limits

- **Lambda Timeout**: 5 minutes
- **API Gateway Payload**: 10MB
- **S3 Object Lifecycle**: 1 day (automatic cleanup)

## Cost Estimation

Monthly costs for moderate usage (50 sessions/month):

| Service | Cost |
|---------|------|
| Lambda | $5-10 |
| Transcribe | $24 |
| Nova Sonic | $20-40 |
| S3 | $1-2 |
| API Gateway | $5-10 |
| CloudFront | $1-2 |
| **Total** | **$56-84** |

## Development

### Local Development

```bash
npm start
```

### Testing

```bash
npm test
```

### Building

```bash
npm run build
```

## API Reference

### Process Recording

**Endpoint**: `POST /process-recording`

**Request Body**:
```json
{
  "audioData": "base64_encoded_audio",
  "audioFormat": "webm",
  "sampleRate": 8000
}
```

**Response**:
```json
{
  "confidence": 75.5,
  "pronunciationMistakes": [
    "Reduce filler words (um, uh)",
    "Consider expanding your content"
  ],
  "overallFeedback": "Your presentation was 2.3 minutes long...",
  "audioFeedback": "base64_encoded_audio_feedback"
}
```

## Troubleshooting

### Common Issues

1. **Microphone Access Denied**
   - Ensure browser has microphone permissions
   - Check HTTPS requirement for audio recording

2. **Lambda Timeout**
   - Increase Lambda timeout in CloudFormation template
   - Check audio file size (should be under 10MB)

3. **CORS Errors**
   - Verify API Gateway CORS configuration
   - Check frontend API URL

4. **Transcription Failures**
   - Ensure audio quality is sufficient
   - Check S3 bucket permissions

### Logs

- **Lambda Logs**: CloudWatch Logs
- **API Gateway Logs**: CloudWatch Logs
- **Frontend Logs**: Browser Developer Tools

## Security

- All audio data is encrypted in transit and at rest
- Temporary files are automatically deleted
- No persistent storage of user data
- API Gateway rate limiting enabled
- S3 bucket with public access blocked

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This project is licensed under the MIT License.

## Support

For issues and questions:
1. Check the troubleshooting section
2. Review AWS service documentation
3. Open an issue in the repository

## Roadmap

- [ ] Real-time transcription display
- [ ] Multiple language support
- [ ] Presentation templates
- [ ] User session management
- [ ] Advanced analytics dashboard
- [ ] Mobile app version
