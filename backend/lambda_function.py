import json
import base64
import boto3
import tempfile
import os
from typing import Dict, Any, List
import logging

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Initialize AWS clients
transcribe_client = boto3.client('transcribe')
s3_client = boto3.client('s3')
lambda_client = boto3.client('lambda')

# Configuration
S3_BUCKET = os.environ.get('S3_BUCKET', 'presentation-practice-audio')
MAX_AUDIO_DURATION = 20 * 60  # 20 minutes in seconds

def lambda_handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    Main Lambda function to process presentation recordings
    """
    try:
        # Parse the incoming request
        body = json.loads(event.get('body', '{}'))
        audio_data = body.get('audioData')
        audio_format = body.get('audioFormat', 'webm')
        sample_rate = body.get('sampleRate', 8000)
        
        if not audio_data:
            return {
                'statusCode': 400,
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*',
                    'Access-Control-Allow-Headers': 'Content-Type',
                    'Access-Control-Allow-Methods': 'POST, OPTIONS'
                },
                'body': json.dumps({'error': 'No audio data provided'})
            }
        
        # Decode base64 audio data
        audio_bytes = base64.b64decode(audio_data)
        
        # Upload audio to S3 for processing
        session_id = context.aws_request_id
        audio_key = f"recordings/{session_id}.{audio_format}"
        
        s3_client.put_object(
            Bucket=S3_BUCKET,
            Key=audio_key,
            Body=audio_bytes,
            ContentType=f'audio/{audio_format}'
        )
        
        # Start transcription
        transcription_result = start_transcription(session_id, audio_key, sample_rate)
        
        # Analyze with Nova Sonic
        analysis_result = analyze_with_nova_sonic(transcription_result, audio_key)
        
        # Generate feedback
        feedback = generate_feedback(analysis_result)
        
        # Generate audio feedback using Nova Sonic speech-to-speech
        audio_feedback = generate_audio_feedback(feedback)
        
        # Clean up temporary files
        cleanup_temp_files(session_id)
        
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Headers': 'Content-Type',
                'Access-Control-Allow-Methods': 'POST, OPTIONS'
            },
            'body': json.dumps({
                'confidence': feedback['confidence'],
                'pronunciationMistakes': feedback['pronunciationMistakes'],
                'overallFeedback': feedback['overallFeedback'],
                'audioFeedback': audio_feedback
            })
        }
        
    except Exception as e:
        logger.error(f"Error processing recording: {str(e)}")
        return {
            'statusCode': 500,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Headers': 'Content-Type',
                'Access-Control-Allow-Methods': 'POST, OPTIONS'
            },
            'body': json.dumps({'error': 'Internal server error'})
        }

def start_transcription(session_id: str, audio_key: str, sample_rate: int) -> Dict[str, Any]:
    """
    Start transcription using Amazon Transcribe
    """
    job_name = f"transcription-{session_id}"
    
    # Start transcription job
    transcribe_client.start_transcription_job(
        TranscriptionJobName=job_name,
        Media={'MediaFileUri': f"s3://{S3_BUCKET}/{audio_key}"},
        MediaFormat='webm',
        LanguageCode='en-US',
        Settings={
            'ShowSpeakerLabels': True,
            'MaxSpeakerLabels': 1,
            'ShowConfidence': True
        }
    )
    
    # Wait for completion
    while True:
        response = transcribe_client.get_transcription_job(TranscriptionJobName=job_name)
        status = response['TranscriptionJob']['TranscriptionJobStatus']
        
        if status == 'COMPLETED':
            # Get the transcript
            transcript_uri = response['TranscriptionJob']['Transcript']['TranscriptFileUri']
            transcript_response = boto3.client('s3').get_object(
                Bucket=S3_BUCKET,
                Key=transcript_uri.split('/')[-1]
            )
            transcript_data = json.loads(transcript_response['Body'].read().decode('utf-8'))
            return transcript_data
            
        elif status == 'FAILED':
            raise Exception(f"Transcription failed: {response['TranscriptionJob'].get('FailureReason', 'Unknown error')}")
        
        # Wait 5 seconds before checking again
        import time
        time.sleep(5)

def analyze_with_nova_sonic(transcript_data: Dict[str, Any], audio_key: str) -> Dict[str, Any]:
    """
    Analyze the presentation using AWS Nova Sonic
    """
    # Extract transcript text
    transcript_text = ""
    for item in transcript_data.get('results', {}).get('transcripts', []):
        transcript_text += item.get('transcript', '')
    
    # Prepare prompt for Nova Sonic analysis
    analysis_prompt = f"""
    Analyze this presentation transcript for public speaking quality:
    
    Transcript: {transcript_text}
    
    Please provide:
    1. Confidence score (0-100)
    2. Pronunciation mistakes and areas for improvement
    3. Overall feedback on presentation delivery
    4. Specific suggestions for improvement
    
    Focus on:
    - Speaking pace and rhythm
    - Clarity and articulation
    - Confidence indicators
    - Filler words and pauses
    - Overall presentation effectiveness
    """
    
    # Call Nova Sonic for analysis
    # Note: This is a placeholder - actual Nova Sonic integration would use the AWS SDK
    # For now, we'll simulate the analysis
    analysis_result = simulate_nova_sonic_analysis(transcript_text)
    
    return analysis_result

def simulate_nova_sonic_analysis(transcript_text: str) -> Dict[str, Any]:
    """
    Simulate Nova Sonic analysis (replace with actual Nova Sonic API calls)
    """
    # This is a placeholder implementation
    # In production, you would use the actual Nova Sonic API
    
    word_count = len(transcript_text.split())
    duration_estimate = word_count / 150  # Assuming 150 words per minute
    
    # Simple confidence scoring based on transcript characteristics
    confidence_score = min(85, max(40, 70 + (word_count / 100)))
    
    # Simulate pronunciation analysis
    pronunciation_mistakes = []
    if 'um' in transcript_text.lower() or 'uh' in transcript_text.lower():
        pronunciation_mistakes.append("Reduce filler words (um, uh)")
    
    if word_count < 50:
        pronunciation_mistakes.append("Consider expanding your content")
    
    # Generate overall feedback
    overall_feedback = f"""
    Your presentation was {duration_estimate:.1f} minutes long with {word_count} words.
    You demonstrated good engagement, but there's room for improvement in clarity and pacing.
    Consider practicing more to build confidence and reduce filler words.
    """
    
    return {
        'confidence': confidence_score,
        'pronunciationMistakes': pronunciation_mistakes,
        'overallFeedback': overall_feedback.strip(),
        'wordCount': word_count,
        'duration': duration_estimate
    }

def generate_feedback(analysis_result: Dict[str, Any]) -> Dict[str, Any]:
    """
    Generate structured feedback from analysis results
    """
    confidence = analysis_result['confidence']
    pronunciation_mistakes = analysis_result['pronunciationMistakes']
    overall_feedback = analysis_result['overallFeedback']
    
    # Enhance feedback based on confidence score
    if confidence < 50:
        overall_feedback += "\n\nFocus on building confidence through practice and preparation."
    elif confidence < 70:
        overall_feedback += "\n\nGood effort! Continue practicing to improve your delivery."
    else:
        overall_feedback += "\n\nExcellent presentation! Keep up the great work."
    
    return {
        'confidence': confidence,
        'pronunciationMistakes': pronunciation_mistakes,
        'overallFeedback': overall_feedback
    }

def generate_audio_feedback(feedback: Dict[str, Any]) -> str:
    """
    Generate audio feedback using Nova Sonic speech-to-speech
    """
    # Create audio feedback text
    audio_text = f"""
    Your presentation confidence score is {feedback['confidence']:.1f} percent.
    
    {feedback['overallFeedback']}
    
    Keep practicing to improve your presentation skills!
    """
    
    # This is a placeholder - in production, you would use Nova Sonic speech-to-speech
    # For now, we'll return a base64 encoded placeholder
    placeholder_audio = "data:audio/mp3;base64,UklGRnoGAABXQVZFZm10IBAAAAABAAEAQB8AAEAfAAABAAgAZGF0YQoGAACBhYqFbF1fdJivrJBhNjVgodDbq2EcBj+a2/LDciUFLIHO8tiJNwgZaLvt559NEAxQp+PwtmMcBjiR1/LMeSwFJHfH8N2QQAoUXrTp66hVFApGn+DyvmwhBSuBzvLZiTYIG2m98OScTgwOUarm7blmGgU7k9n1unEiBC13yO/eizEIHWq+8+OWT"
    
    return placeholder_audio

def cleanup_temp_files(session_id: str):
    """
    Clean up temporary files from S3
    """
    try:
        # Delete the original audio file
        s3_client.delete_object(
            Bucket=S3_BUCKET,
            Key=f"recordings/{session_id}.webm"
        )
        
        # Delete transcription results
        s3_client.delete_object(
            Bucket=S3_BUCKET,
            Key=f"transcriptions/{session_id}.json"
        )
    except Exception as e:
        logger.warning(f"Failed to cleanup temp files: {str(e)}") 