"""
Test script for ImageAgent using Gemini 2.5 Flash Image (nano-banana)
Run this to verify the image generation is working correctly.
"""
import asyncio
import os
import sys
from pathlib import Path

# Add the backend/src directory to the path
backend_src = Path(__file__).parent.parent / "src"
sys.path.insert(0, str(backend_src))

from agents.image_agent.agent import ImageAgent
from google.adk.sessions import InMemorySessionService


async def test_basic_generation():
    """Test basic image generation"""
    print("\n=== Testing Basic Image Generation ===")
    
    agent = ImageAgent(
        app_name="LearnWeave-Test",
        session_service=InMemorySessionService()
    )
    
    test_cases = [
        "Python programming for beginners",
        "Machine learning and artificial intelligence",
        "Web development with React and Node.js",
        "Data structures and algorithms"
    ]
    
    for i, test_prompt in enumerate(test_cases, 1):
        print(f"\n[Test {i}/{len(test_cases)}] Generating image for: {test_prompt}")
        
        try:
            response = await agent.run(
                user_id=f"test_user_{i}",
                state={},
                content=test_prompt
            )
            
            if response.get("status") == "success":
                print(f"✓ Success! Image path: {response.get('url')}")
                print(f"  File exists: {os.path.exists(response.get('url', ''))}")
            else:
                print(f"✗ Failed: {response.get('error', 'Unknown error')}")
                print(f"  Using fallback: {response.get('fallback_url')}")
                
        except Exception as e:
            print(f"✗ Exception occurred: {str(e)}")


async def test_direct_generation():
    """Test direct generate_image method"""
    print("\n=== Testing Direct Image Generation ===")
    
    agent = ImageAgent(
        app_name="LearnWeave-Test",
        session_service=InMemorySessionService()
    )
    
    try:
        prompt = "A modern, abstract illustration representing computer science education"
        print(f"Generating with prompt: {prompt}")
        
        output_path = "/tmp/test_direct_generation.png"
        result = await agent.generate_image(prompt, output_path)
        
        print(f"✓ Direct generation successful!")
        print(f"  Output path: {result}")
        print(f"  File exists: {os.path.exists(result)}")
        
        if os.path.exists(result):
            file_size = os.path.getsize(result)
            print(f"  File size: {file_size / 1024:.2f} KB")
            
    except Exception as e:
        print(f"✗ Direct generation failed: {str(e)}")


async def test_error_handling():
    """Test error handling with invalid inputs"""
    print("\n=== Testing Error Handling ===")
    
    agent = ImageAgent(
        app_name="LearnWeave-Test",
        session_service=InMemorySessionService()
    )
    
    # Test with empty prompt
    print("\nTesting with empty prompt...")
    try:
        response = await agent.run(
            user_id="test_user_error",
            state={},
            content=""
        )
        print(f"Response status: {response.get('status')}")
        print(f"Has fallback: {'fallback_url' in response or 'url' in response}")
    except Exception as e:
        print(f"Caught exception (expected): {str(e)}")


async def main():
    """Run all tests"""
    print("=" * 60)
    print("ImageAgent Test Suite - Gemini 2.5 Flash Image (nano-banana)")
    print("=" * 60)
    
    # Check environment variables
    print("\n=== Checking Environment Variables ===")
    env_vars = {
        "GOOGLE_GENAI_USE_VERTEXAI": os.getenv("GOOGLE_GENAI_USE_VERTEXAI"),
        "GOOGLE_CLOUD_PROJECT": os.getenv("GOOGLE_CLOUD_PROJECT"),
        "GOOGLE_CLOUD_LOCATION": os.getenv("GOOGLE_CLOUD_LOCATION")
    }
    
    for var, value in env_vars.items():
        status = "✓" if value else "✗"
        print(f"{status} {var}: {value if value else 'NOT SET'}")
    
    if not all(env_vars.values()):
        print("\n⚠ Warning: Some environment variables are not set!")
        print("Make sure to set them in your .env file or environment.")
        return
    
    # Run tests
    try:
        await test_basic_generation()
        await test_direct_generation()
        await test_error_handling()
        
        print("\n" + "=" * 60)
        print("All tests completed!")
        print("=" * 60)
        
    except Exception as e:
        print(f"\n✗ Test suite failed with error: {str(e)}")
        import traceback
        traceback.print_exc()


if __name__ == "__main__":
    asyncio.run(main())
