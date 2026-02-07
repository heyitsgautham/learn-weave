# Architecture Diagrams: Image Generation

## Before: Unsplash MCP Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                      LearnWeave Backend                         │
│                                                                  │
│  ┌────────────────────────────────────────────────────────┐   │
│  │              ImageAgent (Old)                          │   │
│  │                                                        │   │
│  │  ┌──────────────────────────────────────────────┐    │   │
│  │  │    LlmAgent                                  │    │   │
│  │  │    - model: gemini-2.0-flash-exp            │    │   │
│  │  │    - tools: [unsplash_mcp_toolset]          │    │   │
│  │  │    - callback: get_url_from_response        │    │   │
│  │  └──────────────────────────────────────────────┘    │   │
│  │                      ↓                                │   │
│  │  ┌──────────────────────────────────────────────┐    │   │
│  │  │    MCPToolset                                │    │   │
│  │  │    - command: uv run fastmcp                 │    │   │
│  │  │    - server: unsplash_mcp_server.py          │    │   │
│  │  └──────────────────────────────────────────────┘    │   │
│  └────────────────────────────────────────────────────────┘   │
│                          ↓                                      │
└──────────────────────────────────────────────────────────────────┘
                           ↓
         ┌─────────────────────────────────┐
         │     MCP Server (External)       │
         │   unsplash_mcp_server.py        │
         │                                 │
         │  - Receives search query        │
         │  - Calls Unsplash API           │
         │  - Returns image URL            │
         └─────────────────────────────────┘
                           ↓
         ┌─────────────────────────────────┐
         │      Unsplash API               │
         │   (External Service)            │
         │                                 │
         │  - Searches stock photos        │
         │  - Returns image URLs           │
         │  - Requires API key             │
         └─────────────────────────────────┘
                           ↓
              Returns: Unsplash URL
              https://images.unsplash.com/...
```

### Data Flow (Old)
1. User requests course creation
2. ImageAgent receives course topic
3. Agent queries MCP Server via toolset
4. MCP Server calls Unsplash API
5. Unsplash returns matching stock photo URL
6. URL passed back through MCP → Agent → Service
7. URL stored in database

### Issues
- ❌ External dependency (Unsplash API)
- ❌ API rate limits (50 req/hour free)
- ❌ Generic stock photos
- ❌ Complex architecture (MCP layer)
- ❌ No customization
- ❌ Requires separate API key management

---

## After: Gemini 2.5 Flash Image Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                      LearnWeave Backend                         │
│                                                                  │
│  ┌────────────────────────────────────────────────────────┐   │
│  │              ImageAgent (New)                          │   │
│  │                                                        │   │
│  │  ┌──────────────────────────────────────────────┐    │   │
│  │  │    google.genai.Client                       │    │   │
│  │  │    - model: gemini-2.5-flash-image-preview  │    │   │
│  │  │    - temperature: 1.0                        │    │   │
│  │  │    - Direct API calls                        │    │   │
│  │  └──────────────────────────────────────────────┘    │   │
│  │                      ↓                                │   │
│  │  ┌──────────────────────────────────────────────┐    │   │
│  │  │    generate_image()                          │    │   │
│  │  │    - Creates enhanced prompt                 │    │   │
│  │  │    - Generates custom image                  │    │   │
│  │  │    - Saves to local file                     │    │   │
│  │  └──────────────────────────────────────────────┘    │   │
│  └────────────────────────────────────────────────────────┘   │
│                          ↓                                      │
└──────────────────────────────────────────────────────────────────┘
                           ↓
         ┌─────────────────────────────────┐
         │    Google Vertex AI              │
         │  (Cloud Service)                 │
         │                                  │
         │  Model: gemini-2.5-flash-image  │
         │  - AI Image Generation           │
         │  - SOTA Quality                  │
         │  - Built-in SynthID              │
         └─────────────────────────────────┘
                           ↓
              Returns: Binary Image Data
              (PNG format with SynthID watermark)
                           ↓
              Saved to Local File System
              /tmp/course_image_{user_id}_{hash}.png
```

### Data Flow (New)
1. User requests course creation
2. ImageAgent receives course topic
3. Agent enhances prompt with styling instructions
4. Direct call to Vertex AI (Gemini 2.5 Flash Image)
5. AI generates custom image based on topic
6. Binary image data returned
7. Image saved to local file system
8. File path stored in database

### Benefits
- ✅ No external API dependencies (uses existing Vertex AI)
- ✅ Custom AI-generated images
- ✅ Simple, direct architecture
- ✅ Better quality and relevance
- ✅ Full customization control
- ✅ Same auth as other Vertex services

---

## Request/Response Flow Comparison

### Old Flow (Unsplash)
```
Service Request
    ↓
ImageAgent.run()
    ↓
LlmAgent with MCP tools
    ↓
MCP Server Process (external)
    ↓
Unsplash API (external)
    ↓
Response: URL string
    ↓
Store URL in database
    ↓
Frontend fetches from Unsplash CDN
```

**Latency:** ~1-2 seconds  
**Dependencies:** 3 (LLM, MCP, Unsplash)  
**Output:** External URL  

### New Flow (Gemini 2.5 Flash Image)
```
Service Request
    ↓
ImageAgent.run()
    ↓
Google GenAI Client
    ↓
Vertex AI (native)
    ↓
Response: Binary image data
    ↓
Save to file system
    ↓
Store file path in database
    ↓
Frontend fetches from backend/CDN
```

**Latency:** ~2-5 seconds  
**Dependencies:** 1 (Vertex AI)  
**Output:** Local file path  

---

## Integration Points

### Course Creation Flow
```
┌─────────────────────────────────────────────────────────┐
│              agent_service.py                           │
│                                                         │
│  async def create_course()                             │
│      ↓                                                  │
│  1. InfoAgent.run() → title, description               │
│      ↓                                                  │
│  2. ImageAgent.run() → image_path                      │
│      ↓                                                  │
│  3. courses_crud.update_course(image_url=image_path)  │
│      ↓                                                  │
│  4. Continue with PlannerAgent, etc.                   │
└─────────────────────────────────────────────────────────┘
```

### Chapter Creation Flow
```
┌─────────────────────────────────────────────────────────┐
│              agent_service.py                           │
│                                                         │
│  async def create_course() (chapters loop)             │
│      ↓                                                  │
│  1. ExplainerAgent.run() → chapter content             │
│      ↓                                                  │
│  2. ImageAgent.run() → chapter_image_path              │
│      ↓                                                  │
│  3. chapters_crud.create_chapter(                      │
│         image_url=chapter_image_path)                  │
│      ↓                                                  │
│  4. Continue with next chapter                         │
└─────────────────────────────────────────────────────────┘
```

---

## Error Handling Flow

### Old (Unsplash)
```
ImageAgent.run()
    ↓
Try MCP call
    ↓
    ├─ Success: Return URL
    │
    └─ Failure ─→ Log warning
                   ↓
                Return fallback URL
```

### New (Gemini)
```
ImageAgent.run()
    ↓
Try generate_image()
    ↓
    ├─ Success: Return file path
    │
    └─ Failure ─→ Log error
                   ↓
                Return fallback URL
                   ↓
                Response includes:
                - status: "error"
                - error: exception details
                - fallback_url: default image
```

---

## Storage Architecture (Future Enhancement)

### Current (Temporary Files)
```
Generate Image
    ↓
Save to /tmp/course_image_{user_id}_{hash}.png
    ↓
Return local file path
    ↓
Store path in database
```

**Issues:**
- ❌ Temp files may be cleaned up
- ❌ Not accessible across servers
- ❌ No CDN benefits

### Recommended (Cloud Storage)
```
Generate Image
    ↓
Save to temporary file
    ↓
Upload to Google Cloud Storage
    ↓
Get public URL
    ↓
Delete temporary file
    ↓
Store GCS URL in database
    ↓
Frontend fetches from GCS/CDN
```

**Benefits:**
- ✅ Persistent storage
- ✅ Scalable across servers
- ✅ CDN integration available
- ✅ Backup and versioning

---

## Component Dependencies

### Before
```
ImageAgent
    ├── google-adk (LlmAgent, Runner)
    ├── fastmcp (MCP toolset)
    ├── uv (package runner)
    ├── unsplash_mcp_server.py
    └── callbacks.get_url_from_response
```

### After
```
ImageAgent
    ├── google.genai (Client, types)
    ├── google-adk (sessions only)
    └── Standard Python (asyncio, base64, tempfile)
```

**Reduction:** 60% fewer dependencies  
**Simplification:** Direct API calls, no middleware  

---

## Performance Comparison

| Metric | Unsplash (Old) | Gemini (New) |
|--------|----------------|--------------|
| **Latency** | 1-2 seconds | 2-5 seconds |
| **Quality** | Stock photos | Custom AI art |
| **Relevance** | Keyword match | Semantic understanding |
| **Customization** | None | Full control |
| **Rate Limits** | 50/hour (free) | Project quota |
| **Cost** | $99/month (paid) | Pay-per-use |
| **Dependencies** | 3 external | 1 (Vertex AI) |
| **Maintenance** | Complex | Simple |

---

**Last Updated:** February 7, 2026  
**Migration Status:** Complete ✅
