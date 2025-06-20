# Local Testing Guide

This guide will help you test the presentation practice application locally before deploying to AWS.

## Quick Start

### Option 1: Run Both Servers Together (Recommended)

```bash
npm run dev
```

This will start both the React frontend (port 3000) and the mock backend server (port 3001) simultaneously.

### Option 2: Run Servers Separately

**Terminal 1 - Start Mock Backend:**
```bash
npm run mock-server
```

**Terminal 2 - Start React Frontend:**
```bash
npm start
```

## What You'll See

### Mock Backend Server (Port 3001)
```
🚀 Mock server running at http://localhost:3001
📝 Process recording endpoint: http://localhost:3001/process-recording
🏥 Health check: http://localhost:3001/health

💡 To test the application:
   1. Keep this server running
   2. Open http://localhost:3000 in your browser
   3. Click "Start Recording" and speak for a few seconds
   4. Click "Stop Recording" to see the mock feedback
```

### React Frontend (Port 3000)
- Opens automatically in your browser
- Beautiful UI with the large green recording button
- Real-time recording indicator
- Processing status display

## Testing the Application

1. **Open the Application**
   - Navigate to `http://localhost:3000`
   - You should see the presentation practice interface

2. **Test Recording**
   - Click the green "Start Recording" button
   - Allow microphone access when prompted
   - Speak for 10-30 seconds (any content will work)
   - Click "Stop Recording"

3. **View Feedback**
   - Wait 2-5 seconds for processing simulation
   - You'll see:
     - Confidence score (70-90 range)
     - Pronunciation suggestions
     - Overall feedback
     - Audio feedback button (placeholder)

## Mock Features

### Simulated Processing
- **Transcription**: Random professional presentation transcripts
- **Analysis**: Confidence scoring based on content length
- **Feedback**: Personalized suggestions and improvements
- **Audio**: Placeholder audio feedback

### Processing Time
- Simulates 2-5 second processing delay
- Shows realistic loading states
- Console logs show processing steps

## Console Output

When you record, you'll see detailed logs in the mock server console:

```
📝 Processing recording request...
⏳ Simulating processing for 3247ms...
🎤 Simulating transcription...
🤖 Simulating Nova Sonic analysis...
🔊 Generating audio feedback...
✅ Processing completed successfully!
```

## Troubleshooting

### Microphone Access Issues
- Ensure you're using HTTPS or localhost
- Check browser permissions
- Try refreshing the page

### Server Connection Issues
- Verify both servers are running
- Check ports 3000 and 3001 are available
- Restart servers if needed

### Audio Recording Issues
- Test with different browsers (Chrome, Firefox, Edge)
- Check microphone hardware
- Ensure no other apps are using the microphone

## Switching to Production

When ready to deploy to AWS:

1. **Update Configuration**
   ```typescript
   // In src/config.ts, change:
   baseUrl: 'https://your-api-gateway-url.execute-api.us-east-1.amazonaws.com/prod'
   ```

2. **Deploy Backend**
   ```bash
   cd backend
   ./deploy.sh
   ```

3. **Deploy Frontend**
   ```bash
   npm run build
   # Deploy to AWS Amplify or S3
   ```

## Development Tips

### Testing Different Scenarios
- **Short recordings**: Test with 5-10 seconds
- **Long recordings**: Test with 1-2 minutes
- **Silent recordings**: Test error handling
- **Multiple recordings**: Test consecutive sessions

### Browser Testing
- **Chrome**: Best compatibility
- **Firefox**: Good compatibility
- **Edge**: Modern versions work well
- **Safari**: May have limitations

### Debug Mode
- Open browser developer tools
- Check Network tab for API calls
- Monitor Console for errors
- Use React Developer Tools

## Mock Data Examples

The mock server provides realistic feedback:

### High Confidence (80-90%)
- "Excellent delivery! You demonstrated strong confidence and clear articulation."

### Medium Confidence (60-79%)
- "Good effort! Your presentation was clear and engaging."

### Low Confidence (40-59%)
- "You have potential! With more practice, you'll improve significantly."

### Common Suggestions
- "Reduce filler words (um, uh)"
- "Consider expanding your content"
- "Practice speaking at a more natural pace"

---

**🎉 Happy Testing!** Your local environment is now ready for development and testing. 