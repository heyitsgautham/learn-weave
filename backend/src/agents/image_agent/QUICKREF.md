# Quick Reference: Gemini 2.5 Flash Image Agent

## Basic Usage

```python
from agents.image_agent.agent import ImageAgent
from google.adk.sessions import InMemorySessionService

# Initialize
agent = ImageAgent(
    app_name="LearnWeave",
    session_service=InMemorySessionService()
)

# Generate image
response = await agent.run(
    user_id="user123",
    state={},
    content="Python programming basics"
)

# Get image path
image_path = response['url']
```

## Response Format

```python
{
    "status": "success",           # or "error"
    "url": "path/to/image.png",   # Main image path
    "explanation": "...",          # Same as url (for compatibility)
    "image_path": "...",           # Alternative access
    "user_id": "user123",
    "prompt": "original content"
}
```

## Environment Setup

```bash
# Required environment variables
export GOOGLE_GENAI_USE_VERTEXAI=true
export GOOGLE_CLOUD_PROJECT=your-project-id
export GOOGLE_CLOUD_LOCATION=us-central1
```

## Model Details

- **Model:** `gemini-2.5-flash-image-preview`
- **Temperature:** 1.0
- **Output:** PNG images saved to temp directory
- **Fallback:** Default URL if generation fails

## Common Operations

### Test Image Generation
```bash
cd backend/src/agents/image_agent
python agent.py
```

### Run Test Suite
```bash
cd backend/test
python test_image_agent.py
```

### Check if Image Exists
```python
import os
if response.get("status") == "success":
    image_exists = os.path.exists(response["url"])
```

## Error Handling

```python
try:
    response = await agent.run(user_id, {}, content)
    if response.get("status") == "error":
        # Use fallback
        fallback_url = response.get("fallback_url")
except Exception as e:
    # Handle exception
    print(f"Error: {e}")
```

## Prompt Engineering Tips

### Good Prompts
✅ "Python programming for beginners"
✅ "Machine learning and neural networks"
✅ "Web development with React"

### Enhanced Prompts (automatic)
The agent automatically enhances prompts:
```
"Generate a professional, educational cover image for a course about: {topic}

Style: Clean, modern, educational
Quality: High resolution, suitable for course cover
Content: Abstract or symbolic representation
Colors: Professional and engaging palette"
```

## File Locations

- **Agent Code:** `backend/src/agents/image_agent/agent.py`
- **Instructions:** `backend/src/agents/image_agent/instructions.txt`
- **Tests:** `backend/test/test_image_agent.py`
- **Documentation:** `backend/src/agents/image_agent/README.md`
- **Migration Guide:** `backend/src/agents/image_agent/MIGRATION.md`

## Integration Points

### Course Creation
```python
# In agent_service.py
image_response = await self.image_agent.run(
    user_id=user_id,
    state={},
    content=create_text_query(
        f"Title: {title}, Description: {description}"
    )
)
image_url = image_response.get('url')
```

### Chapter Creation
```python
# In agent_service.py
image_response = await self.image_agent.run(
    user_id=user_id,
    state={},
    content=self.query_service.get_explainer_image_query(
        user_id, course_id, chapter_idx
    )
)
chapter_image_url = image_response.get('explanation')
```

## Troubleshooting

### Issue: "No image data found in response"
- Check Vertex AI quotas
- Verify environment variables
- Check model availability in your region

### Issue: File not found
- Images saved to temp directory
- May be cleaned up by system
- Consider cloud storage for persistence

### Issue: Generation too slow
- Normal: 2-5 seconds per image
- Use caching for repeated topics
- Consider async processing with queues

### Issue: API errors
- Check Google Cloud project permissions
- Verify Vertex AI API is enabled
- Check quota limits in console

## Best Practices

1. ✅ Always handle errors with fallback
2. ✅ Use descriptive prompts for better results
3. ✅ Cache generated images when possible
4. ✅ Monitor API usage and costs
5. ✅ Clean up temporary files regularly
6. ✅ Log generation metrics for optimization

## Resources

- [Blog Post](https://cloud.google.com/blog/products/ai-machine-learning/gemini-2-5-flash-image-on-vertex-ai)
- [Documentation](https://cloud.google.com/vertex-ai/generative-ai/docs/models/gemini/2-5-flash#image)
- [Vertex AI Console](https://console.cloud.google.com/vertex-ai/)

---
**Model:** Gemini 2.5 Flash Image (nano-banana)  
**Status:** Preview  
**Last Updated:** February 2026
