// Configuration file for the Presentation Practice Application

export const config = {
  // API Configuration
  api: {
    // For local testing, use the mock server
    // For production, update this to your AWS API Gateway URL
    baseUrl: 'https://vbtbb826n2.execute-api.us-east-1.amazonaws.com/prod',
    endpoints: {
      processRecording: '/process-recording'
    }
  },
  
  // Audio Configuration
  audio: {
    sampleRate: 8000, // 8kHz for cost optimization
    channelCount: 1, // Mono
    echoCancellation: true,
    noiseSuppression: true,
    autoGainControl: true,
    maxDuration: 20 * 60, // 20 minutes in seconds
    mimeType: 'audio/webm;codecs=opus'
  },
  
  // UI Configuration
  ui: {
    recordingButtonSize: {
      desktop: 200,
      tablet: 150,
      mobile: 120
    },
    maxWidth: 800,
    colors: {
      primary: '#00b894',
      secondary: '#667eea',
      accent: '#ff4757',
      background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)'
    }
  },
  
  // Feature Flags
  features: {
    realTimeTranscription: false, // Future feature
    audioVisualization: false, // Future feature
    multipleLanguages: false, // Future feature
    userManagement: false // No user management for cost optimization
  }
};

// Helper function to get the full API URL
export const getApiUrl = (endpoint: string): string => {
  return `${config.api.baseUrl}${endpoint}`;
};

// Helper function to get recording button size based on screen size
export const getRecordingButtonSize = (): number => {
  const width = window.innerWidth;
  if (width <= 480) return config.ui.recordingButtonSize.mobile;
  if (width <= 768) return config.ui.recordingButtonSize.tablet;
  return config.ui.recordingButtonSize.desktop;
}; 