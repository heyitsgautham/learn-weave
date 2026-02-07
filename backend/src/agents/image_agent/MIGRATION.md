# Migration Guide: Unsplash to Gemini 2.5 Flash Image

## Overview

This document guides you through migrating from the Unsplash-based image search to Gemini 2.5 Flash Image (nano-banana) for course image generation.

## What Changed

### Before (Unsplash MCP)
```python
# Used MCP server to search Unsplash
unsplash_mcp_toolset = MCPToolset(
    connection_params=StdioServerParameters(
        command='uv',
        args=["run", "--with", "fastmcp", "fastmcp", "run", path_to_mcp_server],
        env={**os.environ}
    )
)

# Agent searched for existing images
image_agent = LlmAgent(
    name="image_agent",
    model="gemini-2.0-flash-exp",
    tools=[unsplash_mcp_toolset],
    after_model_callback=get_url_from_response
)
```

### After (Gemini 2.5 Flash Image)
```python
# Direct Vertex AI image generation
from google import genai
from google.genai import types

client = genai.Client()
response = client.models.generate_content(
    model="gemini-2.5-flash-image-preview",
    contents=prompt,
    config=types.GenerateContentConfig(
        temperature=1.0,
        candidate_count=1,
    )
)
```

## Benefits

### 1. **Custom Generated Images**
- Creates unique images tailored to your specific course content
- No more generic stock photos
- Better alignment with educational context

### 2. **No External Dependencies**
- No need for Unsplash API keys
- No MCP server setup required
- Fewer moving parts = more reliable

### 3. **Better Control**
- Customize image style, colors, and composition
- Maintain consistent visual identity across courses
- Support for image editing and refinement

### 4. **State-of-the-Art Quality**
- SOTA image generation capabilities
- High-resolution outputs suitable for professional use
- Built-in SynthID watermarking for transparency

## Migration Steps

### Step 1: Update Environment Variables

No changes needed! The same Vertex AI environment variables work:

```bash
GOOGLE_GENAI_USE_VERTEXAI=true
GOOGLE_CLOUD_PROJECT=your-project-id
GOOGLE_CLOUD_LOCATION=us-central1
```

### Step 2: Remove Unsplash Dependencies

The following are no longer needed:
- `unsplash_mcp_server.py`
- Unsplash API keys
- MCP server configuration

### Step 3: Test the New Implementation

Run the test script:
```bash
cd backend/test
python test_image_agent.py
```

### Step 4: Update Your Code (If Needed)

The ImageAgent interface remains the same:
```python
response = await image_agent.run(
    user_id=user_id,
    state={},
    content="course topic description"
)

# Access the image
image_url = response.get('url')
```

## Code Comparison

### Image Generation Flow

**Before:**
1. Agent receives course topic
2. Searches Unsplash for matching images
3. Returns URL to existing photo
4. Fallback to default if no match found

**After:**
1. Agent receives course topic
2. Generates custom image based on topic
3. Saves image locally and returns path
4. Fallback to default if generation fails

### Return Format

The return format is **backward compatible**:

```python
{
    "status": "success",
    "url": "path/to/generated/image.png",  # Main field
    "explanation": "path/to/generated/image.png",  # For chapters
    "image_path": "path/to/generated/image.png",  # Alternative
    "user_id": "user123",
    "prompt": "original content"
}
```

## Potential Issues & Solutions

### Issue 1: File Storage

**Problem:** Images are now generated locally, not URLs to external services.

**Solution:** Consider implementing:
- Cloud storage integration (Google Cloud Storage, AWS S3)
- CDN for serving generated images
- Cleanup policies for temporary files

**Example Cloud Storage Integration:**
```python
from google.cloud import storage

async def upload_to_gcs(local_path: str, bucket_name: str) -> str:
    """Upload generated image to Google Cloud Storage"""
    client = storage.Client()
    bucket = client.bucket(bucket_name)
    blob_name = f"course_images/{Path(local_path).name}"
    blob = bucket.blob(blob_name)
    blob.upload_from_filename(local_path)
    return blob.public_url
```

### Issue 2: Generation Time

**Problem:** Image generation takes longer than searching Unsplash.

**Solution:**
- Use async/await properly to avoid blocking
- Implement caching for repeated topics
- Consider pre-generating images for popular topics
- Show loading indicators in UI

### Issue 3: API Quotas

**Problem:** Vertex AI has usage quotas and costs.

**Solution:**
- Monitor usage through Google Cloud Console
- Implement rate limiting
- Cache generated images
- Use fallback images during high load

## Cost Considerations

### Unsplash (Before)
- Free tier: 50 requests/hour
- Paid: $99/month for commercial use
- Risk of API changes or shutdowns

### Gemini 2.5 Flash Image (After)
- Pay-per-use pricing
- No monthly subscription required
- Predictable costs based on generation count
- More control over usage and costs

**Cost Optimization Tips:**
1. Cache generated images for reuse
2. Implement image deduplication
3. Use fallback images during development/testing
4. Monitor and set budget alerts

## Testing Checklist

- [ ] Environment variables configured correctly
- [ ] Image generation works for various topics
- [ ] Error handling returns fallback images
- [ ] Generated images are saved correctly
- [ ] File cleanup works as expected
- [ ] Integration with course creation flow
- [ ] Integration with chapter creation flow
- [ ] Frontend displays generated images correctly
- [ ] Performance is acceptable
- [ ] Costs are within budget

## Rollback Plan

If issues arise, you can rollback by:

1. **Keep the old code** (in git history)
2. **Use git revert** to restore previous version:
   ```bash
   git log --oneline  # Find the commit before migration
   git revert <commit-hash>
   ```

3. **Quick fallback**: Set all images to use the default URL temporarily:
   ```python
   # In agent_service.py
   image_url = "https://images.unsplash.com/photo-1516321318423-f06f85e504b3"
   ```

## Production Deployment

### Pre-deployment Checklist
- [ ] All tests passing
- [ ] Environment variables set in production
- [ ] Vertex AI quotas reviewed and increased if needed
- [ ] Monitoring and logging in place
- [ ] Backup/fallback strategy tested
- [ ] Cost alerts configured
- [ ] Documentation updated

### Monitoring Points
- Image generation success rate
- Average generation time
- API error rates
- Storage usage
- Cost tracking

## Support & Resources

- **Blog Post:** https://cloud.google.com/blog/products/ai-machine-learning/gemini-2-5-flash-image-on-vertex-ai
- **Documentation:** https://cloud.google.com/vertex-ai/generative-ai/docs/models/gemini/2-5-flash#image
- **Google Cloud Console:** https://console.cloud.google.com/vertex-ai/
- **Support:** Google Cloud Support

## Feedback

Track issues and improvements:
1. Monitor user feedback on image quality
2. Track generation failures and patterns
3. Gather metrics on image relevance
4. Collect cost data
5. Document edge cases and solutions

---

**Last Updated:** February 2026
**Status:** ✅ Migration Complete
