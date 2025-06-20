import React, { useState, useRef, useEffect } from 'react';
import './App.css';
import { config, getApiUrl } from './config';

interface RecordingState {
  isRecording: boolean;
  duration: number;
  audioChunks: Blob[];
}

interface FeedbackData {
  confidence: number;
  pronunciationMistakes: string[];
  overallFeedback: string;
  audioFeedback?: string;
}

function App() {
  const [recordingState, setRecordingState] = useState<RecordingState>({
    isRecording: false,
    duration: 0,
    audioChunks: []
  });
  
  const [feedback, setFeedback] = useState<FeedbackData | null>(null);
  const [isProcessing, setIsProcessing] = useState(false);
  const [error, setError] = useState<string | null>(null);
  
  const mediaRecorderRef = useRef<MediaRecorder | null>(null);
  const streamRef = useRef<MediaStream | null>(null);
  const timerRef = useRef<NodeJS.Timeout | null>(null);
  const websocketRef = useRef<WebSocket | null>(null);

  const MAX_DURATION = config.audio.maxDuration;

  useEffect(() => {
    return () => {
      if (timerRef.current) {
        clearInterval(timerRef.current);
      }
      if (websocketRef.current) {
        websocketRef.current.close();
      }
      if (streamRef.current) {
        streamRef.current.getTracks().forEach(track => track.stop());
      }
    };
  }, []);

  const startRecording = async () => {
    try {
      setError(null);
      setFeedback(null);
      
      // Request microphone access with 8kHz audio for cost optimization
      const stream = await navigator.mediaDevices.getUserMedia({
        audio: {
          sampleRate: config.audio.sampleRate,
          channelCount: config.audio.channelCount,
          echoCancellation: config.audio.echoCancellation,
          noiseSuppression: config.audio.noiseSuppression,
          autoGainControl: config.audio.autoGainControl
        }
      });
      
      streamRef.current = stream;
      
      // Create MediaRecorder with 8kHz audio
      const mediaRecorder = new MediaRecorder(stream, {
        mimeType: config.audio.mimeType
      });
      
      mediaRecorderRef.current = mediaRecorder;
      
      const audioChunks: Blob[] = [];
      
      mediaRecorder.ondataavailable = (event) => {
        if (event.data.size > 0) {
          audioChunks.push(event.data);
        }
      };
      
      mediaRecorder.onstop = async () => {
        setIsProcessing(true);
        try {
          // Process the complete recording
          const audioBlob = new Blob(audioChunks, { type: 'audio/webm' });
          await processRecording(audioBlob);
        } catch (err) {
          setError('Failed to process recording');
          console.error('Processing error:', err);
        } finally {
          setIsProcessing(false);
        }
      };
      
      // Start recording
      mediaRecorder.start(1000); // Collect data every second
      
      setRecordingState({
        isRecording: true,
        duration: 0,
        audioChunks: []
      });
      
      // Start timer
      timerRef.current = setInterval(() => {
        setRecordingState(prev => {
          const newDuration = prev.duration + 1;
          if (newDuration >= MAX_DURATION) {
            stopRecording();
            return prev;
          }
          return { ...prev, duration: newDuration };
        });
      }, 1000);
      
    } catch (err) {
      setError('Failed to access microphone');
      console.error('Recording error:', err);
    }
  };

  const stopRecording = () => {
    if (mediaRecorderRef.current && recordingState.isRecording) {
      mediaRecorderRef.current.stop();
    }
    
    if (timerRef.current) {
      clearInterval(timerRef.current);
      timerRef.current = null;
    }
    
    if (streamRef.current) {
      streamRef.current.getTracks().forEach(track => track.stop());
      streamRef.current = null;
    }
    
    setRecordingState(prev => ({ ...prev, isRecording: false }));
  };

  const processRecording = async (audioBlob: Blob) => {
    try {
      // Convert audio to base64 for API transmission
      const arrayBuffer = await audioBlob.arrayBuffer();
      const uint8Array = new Uint8Array(arrayBuffer);
      const base64Audio = btoa(String.fromCharCode.apply(null, Array.from(uint8Array)));
      
      // Call AWS Lambda function for processing
      const response = await fetch(getApiUrl(config.api.endpoints.processRecording), {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          audioData: base64Audio,
          audioFormat: 'webm',
          sampleRate: config.audio.sampleRate
        })
      });
      
      if (!response.ok) {
        throw new Error('Failed to process recording');
      }
      
      const feedbackData: FeedbackData = await response.json();
      setFeedback(feedbackData);
      
    } catch (err) {
      console.error('Processing error:', err);
      setError('Failed to process recording');
    }
  };

  const formatTime = (seconds: number): string => {
    const mins = Math.floor(seconds / 60);
    const secs = seconds % 60;
    return `${mins.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
  };

  const playFeedback = () => {
    if (feedback?.audioFeedback) {
      const audio = new Audio(`data:audio/mp3;base64,${feedback.audioFeedback}`);
      audio.play();
    }
  };

  return (
    <div className="App">
      <header className="App-header">
        <h1>Presentation Practice</h1>
        <p>Record your presentation and get AI-powered feedback</p>
      </header>
      
      <main className="App-main">
        <div className="recording-section">
          <div className="timer">
            {recordingState.isRecording && (
              <div className="recording-indicator">
                <div className="pulse"></div>
                Recording: {formatTime(recordingState.duration)}
              </div>
            )}
          </div>
          
          <button
            className={`record-button ${recordingState.isRecording ? 'recording' : ''}`}
            onClick={recordingState.isRecording ? stopRecording : startRecording}
            disabled={isProcessing}
          >
            {recordingState.isRecording ? 'Stop Recording' : 'Start Recording'}
          </button>
          
          {isProcessing && (
            <div className="processing">
              <div className="spinner"></div>
              <p>Processing your presentation...</p>
            </div>
          )}
          
          {error && (
            <div className="error">
              <p>{error}</p>
            </div>
          )}
        </div>
        
        {feedback && (
          <div className="feedback-section">
            <h2>Your Feedback</h2>
            
            <div className="feedback-card">
              <div className="confidence-score">
                <h3>Confidence Score</h3>
                <div className="score-bar">
                  <div 
                    className="score-fill" 
                    style={{ width: `${feedback.confidence}%` }}
                  ></div>
                </div>
                <p>{feedback.confidence.toFixed(1)}%</p>
              </div>
              
              {feedback.pronunciationMistakes.length > 0 && (
                <div className="pronunciation-mistakes">
                  <h3>Pronunciation Areas to Improve</h3>
                  <ul>
                    {feedback.pronunciationMistakes.map((mistake, index) => (
                      <li key={index}>{mistake}</li>
                    ))}
                  </ul>
                </div>
              )}
              
              <div className="overall-feedback">
                <h3>Overall Feedback</h3>
                <p>{feedback.overallFeedback}</p>
              </div>
              
              {feedback.audioFeedback && (
                <div className="audio-feedback">
                  <h3>Audio Feedback</h3>
                  <button onClick={playFeedback} className="play-button">
                    🔊 Play Feedback
                  </button>
                </div>
              )}
            </div>
          </div>
        )}
      </main>
    </div>
  );
}

export default App;
