# Image Agent - Gemini 2.5 Flash Image (nano-banana)

## Overview

This image agent uses Google's Gemini 2.5 Flash Image (internally known as "nano-banana") on Vertex AI for native image generation. This replaces the previous Unsplash image search implementation with AI-generated custom images.

## Features

- **Native Image Generation**: Creates custom educational images tailored to course topics
- **High Quality**: State-of-the-art (SOTA) image generation and editing capabilities
- **Fast Generation**: Low latency image creation using Flash model
- **SynthID Watermarking**: Built-in watermarking for responsible AI use
- **Character & Style Consistency**: Maintains consistent visual style across generations
- **Conversational Editing**: Support for natural language image editing instructions

## Model Information

- **Model**: `gemini-2.5-flash-image-preview`
- **Provider**: Google Vertex AI
- **Capabilities**: Image generation, multi-image fusion, style consistency
- **Status**: Preview (as of August 2025)

## Implementation Details

### Key Methods

#### `generate_image(prompt: str, output_path: Optional[str] = None) -> str`
Generates an image based on a text prompt.

**Parameters:**
- `prompt`: Text description of the image to generate
- `output_path`: Optional path to save the generated image file

**Returns:**
- File path to saved image or base64 encoded image data

**Example:**
```python
image_path = await image_agent.generate_image(
    "A modern illustration of machine learning concepts",
    output_path="/tmp/ml_course_cover.png"
)
```

#### `run(user_id: str, state: Dict[str, Any], content: str) -> Dict[str, Any]`
Main entry point compatible with existing agent infrastructure.

**Parameters:**
- `user_id`: User identifier
- `state`: Current state dictionary
- `content`: Course topic or description

**Returns:**
```python
{
    "status": "success",
    "url": "path/to/image.png",
    "explanation": "path/to/image.png",  # For backward compatibility
    "image_path": "path/to/image.png",
    "user_id": "user123",
    "prompt": "original content"
}
```

## Configuration

### Environment Variables
Required environment variables (set in `.env`):
```bash
GOOGLE_GENAI_USE_VERTEXAI=true
GOOGLE_CLOUD_PROJECT=your-project-id
GOOGLE_CLOUD_LOCATION=us-central1
```

### Model Settings
- **Temperature**: 1.0 (creative generation)
- **Candidate Count**: 1 (single image output)

## Usage Examples

### Basic Usage
```python
from agents.image_agent.agent import ImageAgent
from google.adk.sessions import InMemorySessionService

# Initialize agent
image_agent = ImageAgent(
    app_name="LearnWeave",
    session_service=InMemorySessionService()
)

# Generate image
response = await image_agent.run(
    user_id="user123",
    state={},
    content="Python programming for beginners"
)

print(f"Generated image: {response['url']}")
```

### Standalone Script
```bash
cd backend/src/agents/image_agent
python agent.py
```

## Migration from Unsplash

### Previous Implementation
- Used MCP (Model Context Protocol) with Unsplash API
- Searched existing images from Unsplash photo library
- Required external API keys and MCP server setup

### New Implementation
- Native Vertex AI image generation
- Creates custom images tailored to specific topics
- No external API dependencies beyond Google Cloud
- Better customization and control over image content

### Breaking Changes
- Removed `unsplash_mcp_server.py` dependency
- Removed MCP toolset requirements
- Changed from image search to image generation
- Output is now local file paths instead of URLs

## Error Handling

The agent includes comprehensive error handling:
1. If image generation fails, returns a fallback URL
2. Logs all errors for debugging
3. Gracefully degrades to default placeholder image

## Fallback Behavior

Default fallback image URL:
```
https://confetticampus.de/wp-content/uploads/2022/02/Oxford-Top-File-A4-Eckspannermappe-mit-Einschlagklappen-rot-1350x1350.jpg
```

## Image Storage

Generated images are saved to:
```
{temp_dir}/course_image_{user_id}_{hash(content)}.png
```

For production, consider:
- Moving to persistent storage (Google Cloud Storage, S3, etc.)
- Implementing image cleanup policies
- Adding image caching mechanisms

## Best Practices

1. **Prompt Engineering**: Create detailed, specific prompts for better results
2. **File Management**: Implement proper cleanup for temporary files
3. **Error Monitoring**: Monitor generation failures and adjust prompts
4. **Rate Limiting**: Be aware of Vertex AI quotas and rate limits
5. **Cost Management**: Monitor API usage and implement caching where appropriate

## Future Enhancements

Potential improvements:
- Multi-image fusion for chapter-specific images
- Image editing capabilities for refinement
- Character consistency across course images
- Integration with Cloud Storage for persistence
- Batch generation for multiple chapters
- A/B testing different image styles

## References

- [Gemini 2.5 Flash Image Blog Post](https://cloud.google.com/blog/products/ai-machine-learning/gemini-2-5-flash-image-on-vertex-ai)
- [Vertex AI Documentation](https://cloud.google.com/vertex-ai/generative-ai/docs/models/gemini/2-5-flash#image)
- [Google GenAI SDK](https://pypi.org/project/google-genai/)

## Support

For issues or questions:
1. Check Vertex AI quota limits
2. Verify environment variables are set correctly
3. Review logs for detailed error messages
4. Consult Vertex AI documentation for API changes
