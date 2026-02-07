"""
Image generation agent using Gemini 2.5 Flash Image (nano-banana) on Vertex AI.
This agent generates custom images for courses using native image generation capabilities.
"""
import json
import os
import asyncio
import base64
import tempfile
from typing import Dict, Any, Optional
from pathlib import Path

from google import genai
from google.genai import types
from google.adk.sessions import InMemorySessionService

from ..utils import create_text_query, load_instruction_from_file
from ..agent import StandardAgent


class ImageAgent(StandardAgent):
    def __init__(self, app_name: str, session_service):
        """
        Initialize the ImageAgent with Gemini 2.5 Flash Image for native image generation.
        
        Args:
            app_name: Application name for session management
            session_service: Session service for managing agent sessions
        """
        self.app_name = app_name
        self.session_service = session_service
        self.client = genai.Client()
        self.model_name = "gemini-2.5-flash-image-preview"
        
        # Load image generation instructions
        instruction_path = os.path.join(os.path.dirname(__file__), "instructions.txt")
        with open(instruction_path, 'r') as f:
            self.instruction = f.read()
    
    async def generate_image(self, prompt: str, output_path: Optional[str] = None) -> str:
        """
        Generate an image using Gemini 2.5 Flash Image.
        
        Args:
            prompt: The text prompt describing the image to generate
            output_path: Optional path to save the generated image
            
        Returns:
            Path to the saved image file or base64 encoded image data
        """
        try:
            # Generate image using Gemini 2.5 Flash Image
            response = self.client.models.generate_content(
                model=self.model_name,
                contents=prompt,
                config=types.GenerateContentConfig(
                    temperature=1.0,
                    candidate_count=1,
                )
            )
            
            # Extract image from response
            if response.candidates and len(response.candidates) > 0:
                candidate = response.candidates[0]
                
                # Check for inline image data in parts
                for part in candidate.content.parts:
                    if hasattr(part, 'inline_data') and part.inline_data:
                        image_data = part.inline_data.data
                        
                        # Save to file if output_path is provided
                        if output_path:
                            with open(output_path, 'wb') as f:
                                f.write(image_data)
                            return output_path
                        else:
                            # Return base64 encoded image
                            return base64.b64encode(image_data).decode('utf-8')
            
            raise ValueError("No image data found in response")
            
        except Exception as e:
            print(f"Error generating image: {e}")
            # Fallback to default image URL on error
            return "https://confetticampus.de/wp-content/uploads/2022/02/Oxford-Top-File-A4-Eckspannermappe-mit-Einschlagklappen-rot-1350x1350.jpg"
    
    async def run(self, user_id: str, state: Dict[str, Any], content: str) -> Dict[str, Any]:
        """
        Run the image generation agent with a text prompt.
        
        Args:
            user_id: User identifier
            state: Current state dictionary
            content: Text description of the course/topic to generate an image for
            
        Returns:
            Dictionary containing the generated image path or URL
        """
        # Create a more detailed prompt for image generation
        enhanced_prompt = f"""Generate a professional, educational cover image for a course about: {content}
        
Style: Clean, modern, educational
Quality: High resolution, suitable for course cover
Content: Abstract or symbolic representation of the topic, visually appealing
Colors: Professional and engaging color palette"""
        
        try:
            # Generate with temporary file
            temp_dir = tempfile.gettempdir()
            output_path = os.path.join(temp_dir, f"course_image_{user_id}_{hash(content)}.png")
            
            result = await self.generate_image(enhanced_prompt, output_path)
            
            # Return format compatible with existing code
            return {
                "status": "success",
                "url": result,  # For course creation
                "explanation": result,  # For chapter creation
                "image_path": result,
                "user_id": user_id,
                "prompt": content
            }
        except Exception as e:
            print(f"Error in image agent run: {e}")
            fallback_url = "https://confetticampus.de/wp-content/uploads/2022/02/Oxford-Top-File-A4-Eckspannermappe-mit-Einschlagklappen-rot-1350x1350.jpg"
            return {
                "status": "error",
                "error": str(e),
                "url": fallback_url,
                "explanation": fallback_url,
                "fallback_url": fallback_url
            }


async def main():
    print("Starting ImageAgent with Gemini 2.5 Flash Image (nano-banana)")
    image_agent_instance = ImageAgent(app_name="LearnWeave", session_service=InMemorySessionService())
    response = await image_agent_instance.run(
        user_id="test", 
        state={}, 
        content="branch and bound algorithm for optimization problems"
    )
    print(response)
    print("done")

if __name__ == "__main__":
    asyncio.run(main())