#!/usr/bin/env python3
"""
Example Script: Gemini 2.5 Flash Image Generation

This script demonstrates how to use the new ImageAgent with
Gemini 2.5 Flash Image (nano-banana) for course image generation.

Usage:
    python example_usage.py
"""

import asyncio
import os
import sys
from pathlib import Path

# Add backend/src to path
backend_src = Path(__file__).parent.parent.parent
sys.path.insert(0, str(backend_src))

from agents.image_agent.agent import ImageAgent
from google.adk.sessions import InMemorySessionService


async def example_1_basic_usage():
    """Example 1: Basic image generation"""
    print("\n" + "="*60)
    print("Example 1: Basic Image Generation")
    print("="*60)
    
    # Initialize the agent
    agent = ImageAgent(
        app_name="LearnWeave",
        session_service=InMemorySessionService()
    )
    
    # Generate an image for a Python course
    response = await agent.run(
        user_id="demo_user",
        state={},
        content="Python programming fundamentals"
    )
    
    print(f"\nStatus: {response.get('status')}")
    print(f"Image Path: {response.get('url')}")
    print(f"File exists: {os.path.exists(response.get('url', ''))}")


async def example_2_multiple_topics():
    """Example 2: Generate images for multiple course topics"""
    print("\n" + "="*60)
    print("Example 2: Multiple Course Topics")
    print("="*60)
    
    agent = ImageAgent(
        app_name="LearnWeave",
        session_service=InMemorySessionService()
    )
    
    topics = [
        "Machine Learning and Neural Networks",
        "Web Development with React",
        "Database Design and SQL",
        "Mobile App Development with Flutter"
    ]
    
    for i, topic in enumerate(topics, 1):
        print(f"\n[{i}/{len(topics)}] Generating image for: {topic}")
        
        response = await agent.run(
            user_id=f"user_{i}",
            state={},
            content=topic
        )
        
        if response.get('status') == 'success':
            print(f"  ✓ Generated: {response.get('url')}")
        else:
            print(f"  ✗ Failed: {response.get('error')}")


async def example_3_direct_api():
    """Example 3: Using the direct API"""
    print("\n" + "="*60)
    print("Example 3: Direct API Usage")
    print("="*60)
    
    agent = ImageAgent(
        app_name="LearnWeave",
        session_service=InMemorySessionService()
    )
    
    # Use the direct generate_image method
    prompt = """A professional, modern illustration representing 
    artificial intelligence and machine learning concepts.
    Style: Clean, abstract, educational.
    Colors: Blue and green tones."""
    
    print(f"\nPrompt: {prompt}")
    
    output_path = "/tmp/ai_course_example.png"
    result = await agent.generate_image(prompt, output_path)
    
    print(f"\nResult: {result}")
    print(f"File exists: {os.path.exists(result)}")
    
    if os.path.exists(result):
        file_size = os.path.getsize(result)
        print(f"File size: {file_size / 1024:.2f} KB")


async def example_4_error_handling():
    """Example 4: Error handling and fallback"""
    print("\n" + "="*60)
    print("Example 4: Error Handling")
    print("="*60)
    
    agent = ImageAgent(
        app_name="LearnWeave",
        session_service=InMemorySessionService()
    )
    
    # Try with an empty or problematic prompt
    print("\nTesting with empty prompt...")
    
    response = await agent.run(
        user_id="error_test",
        state={},
        content=""
    )
    
    print(f"Status: {response.get('status')}")
    
    if response.get('status') == 'error':
        print(f"Error: {response.get('error')}")
        print(f"Fallback URL provided: {response.get('fallback_url')}")
    else:
        print(f"Unexpectedly succeeded: {response.get('url')}")


async def example_5_integration_pattern():
    """Example 5: Integration pattern (like in agent_service.py)"""
    print("\n" + "="*60)
    print("Example 5: Integration Pattern")
    print("="*60)
    
    agent = ImageAgent(
        app_name="LearnWeave",
        session_service=InMemorySessionService()
    )
    
    # Simulate course creation
    course_info = {
        "title": "Advanced Python Programming",
        "description": "Learn advanced Python concepts including decorators, generators, and async programming"
    }
    
    print(f"\nCourse: {course_info['title']}")
    print(f"Description: {course_info['description']}")
    
    # Generate image (like in agent_service.py)
    image_url = "https://images.unsplash.com/photo-1516321318423-f06f85e504b3"  # Default
    
    try:
        image_response = await agent.run(
            user_id="integration_user",
            state={},
            content=f"Title: {course_info['title']}, Description: {course_info['description']}"
        )
        
        if image_response and image_response.get('url'):
            image_url = image_response.get('url')
            print(f"\n✓ Image generated successfully")
        
    except Exception as e:
        print(f"\n⚠ Failed to generate image, using fallback: {e}")
    
    print(f"Final image URL: {image_url}")
    
    # This URL would be stored in the database
    print(f"\nWould store in database: image_url='{image_url}'")


async def main():
    """Run all examples"""
    print("\n" + "="*70)
    print("  Gemini 2.5 Flash Image (nano-banana) - Usage Examples")
    print("="*70)
    
    # Check environment
    print("\n📋 Environment Check:")
    env_vars = {
        "GOOGLE_GENAI_USE_VERTEXAI": os.getenv("GOOGLE_GENAI_USE_VERTEXAI"),
        "GOOGLE_CLOUD_PROJECT": os.getenv("GOOGLE_CLOUD_PROJECT"),
        "GOOGLE_CLOUD_LOCATION": os.getenv("GOOGLE_CLOUD_LOCATION")
    }
    
    all_set = True
    for var, value in env_vars.items():
        status = "✓" if value else "✗"
        print(f"  {status} {var}: {value if value else 'NOT SET'}")
        if not value:
            all_set = False
    
    if not all_set:
        print("\n⚠ Warning: Missing environment variables!")
        print("Set them in your .env file or environment:")
        print("  export GOOGLE_GENAI_USE_VERTEXAI=true")
        print("  export GOOGLE_CLOUD_PROJECT=your-project-id")
        print("  export GOOGLE_CLOUD_LOCATION=us-central1")
        print("\nSome examples may fail without proper configuration.")
        
        response = input("\nContinue anyway? (y/N): ")
        if response.lower() != 'y':
            return
    
    # Run examples
    try:
        await example_1_basic_usage()
        
        # Comment out to run faster / save quota
        # await example_2_multiple_topics()
        
        await example_3_direct_api()
        await example_4_error_handling()
        await example_5_integration_pattern()
        
        print("\n" + "="*70)
        print("  All examples completed!")
        print("="*70 + "\n")
        
    except KeyboardInterrupt:
        print("\n\n⚠ Interrupted by user")
    except Exception as e:
        print(f"\n\n✗ Error running examples: {e}")
        import traceback
        traceback.print_exc()


if __name__ == "__main__":
    asyncio.run(main())
