# Nova Sonic Integration Guide

This guide explains how to set up and use AWS Nova Sonic for AI-powered presentation analysis and speech-to-speech feedback in your presentation practice application.

## What is Nova Sonic?

AWS Nova Sonic is Amazon's latest AI model that provides:
- **Advanced Text Analysis**: Deep understanding of presentation content and delivery
- **Speech-to-Speech**: Natural-sounding audio feedback generation
- **Confidence Scoring**: AI-powered assessment of presentation confidence
- **Pronunciation Analysis**: Detailed feedback on speaking clarity and articulation

## Prerequisites

1. **AWS Account**: Active AWS account with appropriate permissions
2. **Nova Sonic Access**: Access to Nova Sonic API (may require special access)
3. **API Key**: Valid Nova Sonic API key
4. **AWS CLI**: Configured with appropriate credentials

## Setup Instructions

### 1. Get Nova Sonic API Access

1. Contact AWS support or your AWS account manager to request Nova Sonic access
2. Follow the approval process (may take 1-2 business days)
3. Once approved, you'll receive:
   - API endpoint URL
   - API key for authentication
   - Usage limits and pricing information

### 2. Configure Environment Variables

**For PowerShell (Windows):**
```powershell
$env:NOVA_SONIC_API_KEY = "your-nova-sonic-api-key-here"
```

**For Bash (Linux/Mac):**
```bash
export NOVA_SONIC_API_KEY="your-nova-sonic-api-key-here"
```

### 3. Deploy with Nova Sonic Integration

**Using PowerShell:**
```powershell
cd backend
.\deploy.ps1
```

**Using Bash:**
```bash
cd backend
./deploy.sh
```

The deployment script will:
- Validate your Nova Sonic API key
- Deploy the CloudFormation stack with Nova Sonic permissions
- Configure Lambda environment variables
- Set up IAM roles for Nova Sonic API access

## How Nova Sonic is Used

### 1. Presentation Analysis

When a user records a presentation, Nova Sonic analyzes the transcript for:

- **Confidence Score (0-100)**: AI assessment of presentation confidence
- **Pronunciation Mistakes**: Specific areas for improvement
- **Overall Feedback**: Comprehensive delivery assessment
- **Suggestions**: Actionable improvement recommendations

### 2. Audio Feedback Generation

Nova Sonic generates natural-sounding audio feedback using:
- **Voice Options**: alloy, echo, fable, onyx, nova, shimmer
- **Customizable Speed**: Adjustable playback speed
- **Professional Tone**: Encouraging and constructive feedback

## API Integration Details

### Analysis Request Format

```python
analysis_request = {
    "model": "nova-sonic-1",
    "messages": [
        {
            "role": "system",
            "content": "You are an expert public speaking coach..."
        },
        {
            "role": "user", 
            "content": "Please analyze this presentation transcript: {transcript}"
        }
    ],
    "max_tokens": 1000,
    "temperature": 0.3
}
```

### Speech-to-Speech Request Format

```python
speech_request = {
    "model": "nova-sonic-1",
    "input": "Your feedback text here",
    "voice": "alloy",
    "response_format": "mp3",
    "speed": 1.0
}
```

## Fallback Behavior

If Nova Sonic is unavailable, the application gracefully falls back to:
- **Simulated Analysis**: Basic confidence scoring and feedback
- **Placeholder Audio**: Standard audio feedback message
- **Error Logging**: Detailed logs for troubleshooting

## Cost Optimization

### Nova Sonic Pricing (Estimated)
- **Text Analysis**: ~$0.01-0.05 per presentation
- **Speech-to-Speech**: ~$0.02-0.10 per minute of audio
- **Monthly Estimate**: $20-40 for 50 presentations

### Optimization Tips
1. **Limit Analysis Length**: Focus on key presentation segments
2. **Cache Results**: Store analysis results for repeated content
3. **Batch Processing**: Process multiple presentations together
4. **Monitor Usage**: Set up CloudWatch alarms for cost thresholds

## Troubleshooting

### Common Issues

1. **API Key Not Found**
   ```
   Error: NOVA_SONIC_API_KEY environment variable is required
   ```
   **Solution**: Set the environment variable before deployment

2. **API Call Failures**
   ```
   Nova Sonic API call failed with status 401: Unauthorized
   ```
   **Solution**: Verify API key is valid and has proper permissions

3. **Timeout Errors**
   ```
   Error calling Nova Sonic API: timeout
   ```
   **Solution**: Increase Lambda timeout or check network connectivity

4. **JSON Parse Errors**
   ```
   Failed to parse Nova Sonic response as JSON
   ```
   **Solution**: Check API response format and update parsing logic

### Debugging

1. **Check CloudWatch Logs**:
   ```bash
   aws logs describe-log-groups --log-group-name-prefix "/aws/lambda/presentation-practice"
   ```

2. **Test API Connectivity**:
   ```bash
   curl -H "Authorization: Bearer $NOVA_SONIC_API_KEY" \
        -H "Content-Type: application/json" \
        -d '{"model":"nova-sonic-1","messages":[{"role":"user","content":"test"}]}' \
        https://api.nova-sonic.amazonaws.com/v1/chat/completions
   ```

3. **Monitor Lambda Metrics**:
   - Duration
   - Error rate
   - Memory usage
   - Concurrent executions

## Security Considerations

- ✅ API keys are encrypted in transit and at rest
- ✅ IAM roles with minimal required permissions
- ✅ No persistent storage of API responses
- ✅ Automatic cleanup of temporary data
- ✅ Rate limiting to prevent abuse

## Next Steps

1. **Deploy the updated application** with Nova Sonic integration
2. **Test with sample presentations** to verify functionality
3. **Monitor costs and performance** using CloudWatch
4. **Adjust voice settings** and analysis parameters as needed
5. **Set up alerts** for usage thresholds and errors

## Support

For additional help:
1. Check AWS Nova Sonic documentation
2. Review CloudWatch logs for detailed error information
3. Contact AWS support for Nova Sonic-specific issues
4. Open an issue in the repository for application-specific problems

---

**🎉 Congratulations!** Your presentation practice application now has full Nova Sonic integration for advanced AI-powered feedback! 