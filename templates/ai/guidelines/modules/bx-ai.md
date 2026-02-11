# BoxLang AI Module

> **Module**: bx-ai
> **Category**: modules
> **Purpose**: Enterprise-grade AI integration library for BoxLang with multi-provider support, agents, memory systems, and RAG workflows

## Overview

BoxLang AI (`bx-ai`) is a comprehensive AI integration library that provides a unified interface for working with multiple AI providers (OpenAI, Claude, Gemini, Ollama, etc.). It supports chatbots, autonomous agents, document processing, vector memory, and complex multi-agent systems.

## Installation

```bash
box install bx-ai
```

## Configuration

Configure in `Application.bx`:

```boxlang
this.aiSettings = {
    // Provider configuration
    provider: "openai",  // or "claude", "gemini", "ollama", etc.
    apiKey: getSystemSetting( "OPENAI_API_KEY" ),

    // Model defaults
    defaultModel: "gpt-4o",
    temperature: 0.7,
    maxTokens: 2000,

    // Memory configuration
    memory: {
        type: "session",
        maxMessages: 50
    },

    // Vector memory
    vectorMemory: {
        provider: "boxvector",
        dimensions: 1536
    },

    // Async settings
    async: {
        enabled: true,
        timeout: 30000
    }
}
```

## Core Concepts

### Multi-Provider Support

BoxLang AI provides a unified API across 10+ AI providers:

- **OpenAI**: GPT-4o, GPT-4, GPT-3.5
- **Anthropic Claude**: Claude 3.5 Sonnet, Claude 3 Opus
- **Google Gemini**: Gemini 1.5 Pro, Gemini 1.5 Flash
- **xAI Grok**: Grok-2, Grok Beta
- **Groq**: Fast inference with Llama, Mixtral
- **DeepSeek**: DeepSeek V3
- **Ollama**: Local models (Llama, Mistral, etc.)
- **OpenRouter**: Access to multiple models
- **OpenAI Compatible**: Any OpenAI-compatible API

### AI Services

The central component for AI interactions:

```boxlang
// Create AI service
var ai = aiService( provider: "openai", apiKey: apiKey )

// Simple chat
var response = ai.chat( "What is BoxLang?" )

// Chat with options
var response = ai.chat(
    "Explain dependency injection",
    {
        model: "gpt-4o",
        temperature: 0.5,
        maxTokens: 500
    }
)
```

### AI Models

Explicit model configuration:

```boxlang
// Create model
var model = aiModel( {
    provider: "openai",
    model: "gpt-4o",
    apiKey: apiKey,
    temperature: 0.7
} )

// Use model
var response = model.chat( "Hello!" )
```

## Memory Systems

BoxLang AI supports 20+ memory types for different use cases.

### Standard Memory Types

```boxlang
// Windowed memory (last N messages)
var memory = aiMemory( {
    type: "windowed",
    maxMessages: 10
} )

// Summary memory (summarizes old messages)
var memory = aiMemory( {
    type: "summary",
    maxMessages: 20,
    summaryInterval: 10
} )

// Session memory (HTTP session)
var memory = aiMemory( { type: "session" } )

// File-based memory
var memory = aiMemory( {
    type: "file",
    filePath: "conversations/user-123.json"
} )

// Cache memory
var memory = aiMemory( {
    type: "cache",
    cacheName: "default",
    ttl: 3600
} )

// JDBC memory (database)
var memory = aiMemory( {
    type: "jdbc",
    datasource: "myDB",
    table: "ai_conversations"
} )
```

### Vector Memory

Semantic search with 12 vector database options:

```boxlang
// BoxVector (built-in)
var vectorMemory = aiMemory( {
    type: "boxvector",
    dimensions: 1536,
    similarity: "cosine"
} )

// Chroma
var vectorMemory = aiMemory( {
    type: "chroma",
    host: "localhost",
    port: 8000,
    collection: "conversations"
} )

// PostgreSQL with pgvector
var vectorMemory = aiMemory( {
    type: "postgres",
    datasource: "pgDB",
    table: "embeddings"
} )

// Pinecone
var vectorMemory = aiMemory( {
    type: "pinecone",
    apiKey: apiKey,
    environment: "us-west1-gcp",
    index: "conversations"
} )
```

### Multi-Tenant Memory

Enterprise isolation with userId and conversationId:

```boxlang
var memory = aiMemory( {
    type: "jdbc",
    datasource: "myDB",
    userId: session.user.id,
    conversationId: conversationId
} )

// Store messages
memory.add( aiMessage( "user", "Hello!" ) )
memory.add( aiMessage( "assistant", "Hi there!" ) )

// Retrieve conversation
var history = memory.getMessages()

// Clear user's conversation
memory.clear()
```

## AI Agents

Autonomous agents with memory, tools, and reasoning:

```boxlang
// Create agent
var agent = aiAgent( {
    name: "SupportAgent",
    model: "gpt-4o",
    systemPrompt: "You are a helpful customer support agent",
    memory: aiMemory( { type: "session" } ),
    tools: [
        {
            name: "searchKnowledgeBase",
            description: "Search the knowledge base",
            parameters: {
                query: { type: "string", description: "Search query" }
            },
            function: function( args ) {
                return searchKB( args.query )
            }
        },
        {
            name: "createTicket",
            description: "Create a support ticket",
            parameters: {
                subject: { type: "string" },
                description: { type: "string" }
            },
            function: function( args ) {
                return createTicket( args.subject, args.description )
            }
        }
    ]
} )

// Execute agent
var response = agent.chat( "I need help with my account" )

// Agent will:
// 1. Understand the request
// 2. Decide which tools to use
// 3. Call tools with proper arguments
// 4. Synthesize a response
```

## Document Processing

Load and process documents for RAG workflows:

```boxlang
// Load documents
var docs = aiDocuments( {
    source: "text",
    content: fileRead( "docs/manual.txt" )
} )

// PDF
var docs = aiDocuments( {
    source: "pdf",
    file: "documents/guide.pdf"
} )

// Web page
var docs = aiDocuments( {
    source: "http",
    url: "https://example.com/docs"
} )

// Directory
var docs = aiDocuments( {
    source: "directory",
    path: "docs/",
    recursive: true,
    extensions: [ "md", "txt" ]
} )

// Chunk documents
var chunks = aiChunk( docs, {
    size: 1000,
    overlap: 200
} )

// Store in vector memory
chunks.each( function( chunk ) {
    vectorMemory.add( chunk )
} )
```

## RAG (Retrieval-Augmented Generation)

Combine vector search with AI generation:

```boxlang
// Search relevant documents
var relevantDocs = vectorMemory.search( userQuery, limit: 5 )

// Build context
var context = relevantDocs.map( ( doc ) => doc.content ).toList( "\n\n" )

// Generate response with context
var response = ai.chat(
    "Answer based on this context: #context#\n\nQuestion: #userQuery#"
)
```

## Streaming

Real-time responses as they're generated:

```boxlang
// Stream response
var stream = ai.chatStream( "Write a long story" )

// Process chunks
stream.onChunk( function( chunk ) {
    print( chunk.content )
} )

stream.onComplete( function( fullResponse ) {
    // Handle completion
} )

stream.onError( function( error ) {
    // Handle errors
} )
```

## Async Operations

Non-blocking AI calls:

```boxlang
// Async chat
var future = ai.chatAsync( "Analyze this data..." )

// Do other work
processOtherTasks()

// Get result when ready
var response = future.get( timeout: 30000 )
```

## AI Pipelines

Chain operations for multi-step workflows:

```boxlang
var pipeline = ai.pipeline()
    .transform( "Extract key points from: #userInput#" )
    .transform( "Translate to Spanish: {result}" )
    .transform( "Summarize in 2 sentences: {result}" )
    .execute()

var finalResult = pipeline.getResult()
```

## Prompt Templates

Reusable patterns with dynamic variables:

```boxlang
var template = aiTemplate( """
You are a {role} assistant.
User: {name}
Task: {task}

Context:
{context}

Please provide a detailed response.
""" )

var prompt = template.populate( {
    role: "technical support",
    name: "John Doe",
    task: "troubleshoot connection issue",
    context: contextData
} )

var response = ai.chat( prompt )
```

## Function Calling / Tools

Enable AI to call your functions:

```boxlang
// Define tools
var tools = [
    aiTool( {
        name: "getWeather",
        description: "Get current weather for a location",
        parameters: {
            location: {
                type: "string",
                description: "City name"
            },
            units: {
                type: "string",
                enum: [ "celsius", "fahrenheit" ],
                default: "celsius"
            }
        },
        function: function( args ) {
            return weatherService.getCurrent(
                args.location,
                args.units
            )
        }
    } ),

    aiTool( {
        name: "sendEmail",
        description: "Send an email",
        parameters: {
            to: { type: "string" },
            subject: { type: "string" },
            body: { type: "string" }
        },
        function: function( args ) {
            mailService.send(
                args.to,
                args.subject,
                args.body
            )
            return "Email sent successfully"
        }
    } )
]

// Chat with tools
var response = ai.chat(
    "What's the weather in New York?",
    { tools: tools }
)
```

## MCP Integration

Model Context Protocol for extended capabilities:

```boxlang
// Create MCP server
var mcpServer = MCPServer( {
    name: "MyServer",
    version: "1.0.0",
    capabilities: {
        tools: true,
        resources: true,
        prompts: true
    }
} )

// Register tools
mcpServer.registerTool( "calculator", calculatorTool )

// Create MCP client
var mcpClient = MCP( {
    server: "stdio",
    command: "node",
    args: [ "mcp-server.js" ]
} )

// Use MCP tools
var result = mcpClient.callTool( "calculator", {
    operation: "add",
    a: 5,
    b: 3
} )
```

## Embeddings

Generate embeddings for semantic search:

```boxlang
// Single embedding
var embedding = ai.embed( "Hello world" )

// Multiple embeddings
var embeddings = ai.embedBatch( [
    "First text",
    "Second text",
    "Third text"
] )

// Store in vector memory
embeddings.each( function( emb, index ) {
    vectorMemory.add( {
        content: texts[ index ],
        embedding: emb
    } )
} )
```

## Token Counting

Estimate and manage token usage:

```boxlang
// Count tokens
var count = aiTokens( "This is my text", model: "gpt-4o" )

// Check if within limit
if ( aiTokens( prompt ) > 4000 ) {
    prompt = truncatePrompt( prompt, 4000 )
}
```

## Multimodal Processing

### Images

```boxlang
var response = ai.chat(
    "What's in this image?",
    {
        images: [ imageBase64 ],
        model: "gpt-4o"
    }
)
```

### Audio

```boxlang
var transcription = ai.transcribe( {
    audio: audioFile,
    model: "whisper-1"
} )
```

### Video

```boxlang
var response = ai.chat(
    "Describe this video",
    {
        video: videoFile,
        model: "gemini-1.5-pro"
    }
)
```

## Best Practices

### Provider Selection

- **OpenAI GPT-4o**: Best for complex reasoning, code generation
- **Claude 3.5 Sonnet**: Best for long context, analysis, writing
- **Gemini 1.5 Pro**: Best for multimodal, large context windows
- **Ollama**: Best for privacy, local deployment, cost savings
- **Groq**: Best for fast inference, real-time applications

### Memory Management

- Use **windowed** for simple chatbots
- Use **summary** for long conversations
- Use **vector** for RAG and semantic search
- Use **JDBC** for enterprise multi-tenancy
- Use **hybrid** for combining approaches

### Performance

- Use **streaming** for better UX on long responses
- Use **async** for non-blocking operations
- Use **caching** to avoid redundant API calls
- Implement **token limits** to control costs
- Use **local models** (Ollama) for development

### Security

- Never log API keys
- Use environment variables for credentials
- Implement rate limiting
- Validate user inputs
- Sanitize AI outputs
- Use separate conversations per user (multi-tenancy)

## Common Patterns

### Chatbot with Memory

```boxlang
var chatbot = aiAgent( {
    model: "gpt-4o",
    systemPrompt: "You are a helpful assistant",
    memory: aiMemory( {
        type: "jdbc",
        datasource: "myDB",
        userId: session.user.id
    } )
} )

var response = chatbot.chat( userMessage )
```

### RAG System

```boxlang
// Load and index documents
var docs = aiDocuments( { source: "directory", path: "docs/" } )
var chunks = aiChunk( docs, { size: 1000 } )

var vectorMemory = aiMemory( { type: "boxvector" } )
chunks.each( ( chunk ) => vectorMemory.add( chunk ) )

// Query with context
var relevantDocs = vectorMemory.search( userQuery, limit: 3 )
var context = relevantDocs.map( ( d ) => d.content ).toList( "\n" )

var response = ai.chat(
    "Answer based on: #context#\n\nQuestion: #userQuery#"
)
```

### Multi-Agent System

```boxlang
var researcher = aiAgent( {
    name: "Researcher",
    model: "gpt-4o",
    systemPrompt: "Research and gather information"
} )

var writer = aiAgent( {
    name: "Writer",
    model: "claude-3-5-sonnet",
    systemPrompt: "Write engaging content"
} )

var editor = aiAgent( {
    name: "Editor",
    model: "gpt-4o",
    systemPrompt: "Edit and refine content"
} )

// Workflow
var research = researcher.chat( "Research BoxLang features" )
var draft = writer.chat( "Write article: #research#" )
var final = editor.chat( "Edit and refine: #draft#" )
```

## Related Skills

- [AI Chat & Streaming](../skills/bx-ai-chat.md) - Chat basics and streaming
- [AI Agents](../skills/bx-ai-agents.md) - Autonomous agent development
- [AI Memory Systems](../skills/bx-ai-memory.md) - Memory configuration
- [AI Vector Memory](../skills/bx-ai-vector-memory.md) - Vector databases and RAG
- [AI Document Processing](../skills/bx-ai-documents.md) - Document loaders and RAG
- [AI Tools & Function Calling](../skills/bx-ai-tools.md) - Tool integration
- [AI Pipelines](../skills/bx-ai-pipelines.md) - Multi-step workflows

## Additional Resources

- Documentation: https://ai.ortusbooks.com
- Repository: https://github.com/ortus-boxlang/bx-ai
- ForgeBox: https://forgebox.io/view/bx-ai
- Examples: https://github.com/ortus-boxlang/bx-ai-examples
