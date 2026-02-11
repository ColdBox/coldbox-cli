---
name: BoxLang AI - Chat & Streaming
description: Complete guide to AI chat interactions, streaming responses, async operations, and prompt engineering with BoxLang AI
category: bx-ai
priority: high
triggers:
  - bx-ai chat
  - ai chat
  - ai streaming
  - ai async
  - boxlang ai
---

# BoxLang AI - Chat & Streaming

## Overview

BoxLang AI provides a unified interface for chat interactions across 10+ AI providers (OpenAI, Claude, Gemini, Ollama, etc.) with support for streaming, async operations, and advanced prompt engineering.

## Installation

```bash
box install bx-ai
```

## Basic Chat

### Simple Chat

```boxlang
// Create AI service
var ai = aiService( provider: "openai", apiKey: getSystemSetting( "OPENAI_API_KEY" ) )

// Simple question
var response = ai.chat( "What is BoxLang?" )
echo( response.content )

// Chat with options
var response = ai.chat(
    "Explain dependency injection in BoxLang",
    {
        model: "gpt-4o",
        temperature: 0.7,
        maxTokens: 1000
    }
)
```

### AI Model Configuration

```boxlang
// Create configured model
var model = aiModel( {
    provider: "openai",
    model: "gpt-4o",
    apiKey: apiKey,
    temperature: 0.5,
    maxTokens: 2000,
    topP: 0.9
} )

// Use model
var response = model.chat( "Hello!" )
```

### Multiple Providers

```boxlang
// OpenAI
var openai = aiService( provider: "openai", apiKey: openaiKey )

// Claude
var claude = aiService( provider: "claude", apiKey: claudeKey )

// Gemini
var gemini = aiService( provider: "gemini", apiKey: geminiKey )

// Ollama (local)
var ollama = aiService( provider: "ollama", endpoint: "http://localhost:11434" )

// All use the same interface
var response1 = openai.chat( "Hello" )
var response2 = claude.chat( "Hello" )
var response3 = gemini.chat( "Hello" )
var response4 = ollama.chat( "Hello", { model: "llama3" } )
```

## Chat Requests

### Building Chat Requests

```boxlang
// Create chat request
var request = aiChatRequest()
    .setModel( "gpt-4o" )
    .setTemperature( 0.7 )
    .setMaxTokens( 1500 )
    .addMessage( "system", "You are a helpful coding assistant" )
    .addMessage( "user", "How do I create a class in BoxLang?" )

// Execute
var response = ai.execute( request )
```

### Message History

```boxlang
var request = aiChatRequest()
    .setModel( "gpt-4o" )
    // Conversation history
    .addMessage( "user", "What's 2+2?" )
    .addMessage( "assistant", "2+2 equals 4" )
    .addMessage( "user", "What about 2+3?" )

var response = ai.execute( request )
```

### System Prompts

```boxlang
var request = aiChatRequest()
    .setModel( "gpt-4o" )
    .addMessage( "system", """
        You are an expert BoxLang developer.
        - Always use modern BoxLang syntax
        - Include error handling
        - Follow best practices
        - Explain your code
    """ )
    .addMessage( "user", "Create a user service" )

var response = ai.execute( request )
```

## Streaming Responses

### Basic Streaming

```boxlang
// Stream response
var stream = ai.chatStream( "Write a detailed story about BoxLang" )

// Process chunks as they arrive
stream.onChunk( function( chunk ) {
    echo( chunk.content )
    flush
} )

// Handle completion
stream.onComplete( function( fullResponse ) {
    log.info( "Stream completed" )
} )

// Handle errors
stream.onError( function( error ) {
    log.error( "Stream error: #error.message#" )
} )
```

### Streaming with Server-Sent Events (SSE)

```boxlang
// In handler
function streamChat( event, rc, prc ) {
    // Set headers for SSE
    event.setHTTPHeader( name: "Content-Type", value: "text/event-stream" )
    event.setHTTPHeader( name: "Cache-Control", value: "no-cache" )
    event.setHTTPHeader( name: "Connection", value: "keep-alive" )

    // Stream AI response
    var stream = ai.chatStream( rc.message )

    stream.onChunk( function( chunk ) {
        // Send SSE event
        echo( "data: #serializeJSON( { content: chunk.content } )#\n\n" )
        flush
    } )

    stream.onComplete( function( fullResponse ) {
        echo( "data: [DONE]\n\n" )
        flush
    } )

    return ""; // No view rendering
}
```

### Streaming with Progress

```boxlang
var totalTokens = 0
var startTime = getTickCount()

var stream = ai.chatStream( "Explain BoxLang in detail" )

stream.onChunk( function( chunk ) {
    totalTokens += len( chunk.content )
    echo( chunk.content )
    flush
} )

stream.onComplete( function( fullResponse ) {
    var duration = getTickCount() - startTime
    echo( "\n\nGenerated #totalTokens# tokens in #duration#ms" )
} )
```

## Async Operations

### Async Chat

```boxlang
// Start async chat
var future = ai.chatAsync( "Analyze this large dataset..." )

// Do other work
processOtherTasks()

// Get result when ready
var response = future.get( timeout: 30000 )
echo( response.content )
```

### Multiple Async Requests

```boxlang
// Start multiple requests
var future1 = ai.chatAsync( "Summarize article 1" )
var future2 = ai.chatAsync( "Summarize article 2" )
var future3 = ai.chatAsync( "Summarize article 3" )

// Wait for all
var results = [
    future1.get(),
    future2.get(),
    future3.get()
]

// Process results
results.each( function( result ) {
    echo( result.content & "\n\n" )
} )
```

### Async with Callbacks

```boxlang
ai.chatAsync(
    "Generate content",
    {
        onSuccess: function( response ) {
            log.info( "Content generated: #response.content#" )
            saveContent( response.content )
        },
        onError: function( error ) {
            log.error( "Generation failed: #error.message#" )
        }
    }
)
```

## Prompt Engineering

### Effective Prompts

```boxlang
// ✅ Good: Clear, specific instructions
var response = ai.chat( """
    Create a BoxLang class named UserService with these methods:
    - findById( id ) - Returns user by ID
    - list() - Returns all users
    - save( user ) - Saves or updates user
    - delete( id ) - Deletes user

    Include error handling and use BoxLang modern syntax.
""" )

// ❌ Bad: Vague request
var response = ai.chat( "Make a user thing" )
```

### Few-Shot Learning

```boxlang
var prompt = """
    Convert these function signatures to BoxLang:

    Example 1:
    Input: function getUser(id) { }
    Output: function getUser( required numeric id ) { }

    Example 2:
    Input: function createUser(name, email) { }
    Output: function createUser( required string name, required string email ) { }

    Now convert:
    Input: function updateUser(id, data) { }
    Output:
"""

var response = ai.chat( prompt )
```

### Chain of Thought

```boxlang
var prompt = """
    Let's think step by step:

    1. First, analyze the problem
    2. Then, design the solution
    3. Finally, implement the code

    Problem: Create a rate limiting service for API requests

    Please follow the steps above.
"""

var response = ai.chat( prompt )
```

### Role-Based Prompts

```boxlang
var systemPrompt = """
    You are an expert BoxLang architect with 10+ years experience.
    You specialize in:
    - Clean code and SOLID principles
    - Design patterns
    - Performance optimization
    - Testing best practices

    Always provide production-ready code with error handling.
"""

var request = aiChatRequest()
    .addMessage( "system", systemPrompt )
    .addMessage( "user", "Design a caching service" )

var response = ai.execute( request )
```

## Temperature Control

### Creative vs Deterministic

```boxlang
// High temperature (0.8-1.0) = Creative, varied
var creative = ai.chat(
    "Write a creative story",
    { temperature: 0.9 }
)

// Medium temperature (0.5-0.7) = Balanced
var balanced = ai.chat(
    "Explain BoxLang",
    { temperature: 0.7 }
)

// Low temperature (0.0-0.3) = Deterministic, focused
var deterministic = ai.chat(
    "Fix this bug",
    { temperature: 0.2 }
)
```

### Token Limits

```boxlang
// Limit response length
var response = ai.chat(
    "Explain BoxLang",
    {
        maxTokens: 100  // Short response
    }
)

// Longer response
var response = ai.chat(
    "Write comprehensive documentation",
    {
        maxTokens: 4000
    }
)

// Count tokens first
var tokenCount = aiTokens( prompt, model: "gpt-4o" )
if ( tokenCount > 8000 ) {
    prompt = truncate( prompt, 8000 )
}
```

## Response Handling

### Parsing Responses

```boxlang
var response = ai.chat( "List 3 BoxLang features as JSON array" )

// Parse JSON
var features = deserializeJSON( response.content )

features.each( function( feature ) {
    echo( "- #feature#\n" )
} )
```

### Extracting Code

```boxlang
var response = ai.chat( "Create a BoxLang class for User" )

// Extract code blocks
var codePattern = "```(?:boxlang)?\n(.*?)\n```"
var matches = reMatch( codePattern, response.content )

if ( matches.len() ) {
    var code = matches[ 1 ]
    // Use code
}
```

### Structured Outputs

```boxlang
var prompt = """
    Analyze this text and return JSON with these fields:
    {
        "sentiment": "positive|negative|neutral",
        "keywords": ["array", "of", "keywords"],
        "summary": "brief summary"
    }

    Text: #userText#
"""

var response = ai.chat( prompt )
var analysis = deserializeJSON( response.content )
```

## Error Handling

### Retry Logic

```boxlang
function chatWithRetry( message, maxRetries = 3 ) {
    var attempt = 0

    while ( attempt < maxRetries ) {
        try {
            return ai.chat( message )

        } catch ( any e ) {
            attempt++

            if ( attempt >= maxRetries ) {
                throw(
                    type: "AIError",
                    message: "Failed after #maxRetries# attempts: #e.message#"
                )
            }

            // Exponential backoff
            sleep( 1000 * attempt )
        }
    }
}
```

### Timeout Handling

```boxlang
try {
    var response = ai.chat( message, { timeout: 30000 } )

} catch ( timeout e ) {
    log.error( "AI request timed out" )
    return { content: "Request took too long. Please try again." }
}
```

### Rate Limiting

```boxlang
class singleton {

    property name="cache" inject="cachebox:default"
    property name="ai" inject="provider:AIService"

    function chat( userId, message ) {
        var key = "ai_rate_#userId#"
        var count = cache.get( key, 0 ) + 1

        if ( count > 10 ) {
            throw(
                type: "RateLimitExceeded",
                message: "Too many requests. Try again in 1 minute."
            )
        }

        cache.set( key, count, 60 )

        return ai.chat( message )
    }
}
```

## Best Practices

### Provider Selection

```boxlang
// Choose based on use case
function getAIProvider( useCase ) {
    switch ( useCase ) {
        case "code":
            return aiService( provider: "openai", model: "gpt-4o" )

        case "writing":
            return aiService( provider: "claude", model: "claude-3-5-sonnet" )

        case "multimodal":
            return aiService( provider: "gemini", model: "gemini-1.5-pro" )

        case "local":
            return aiService( provider: "ollama", model: "llama3" )

        default:
            return aiService( provider: "openai" )
    }
}
```

### Caching

```boxlang
class singleton {

    property name="cache" inject="cachebox:default"
    property name="ai" inject="AIService"

    function chat( message, options = {} ) {
        var cacheKey = hash( message & serializeJSON( options ) )

        // Check cache
        var cached = cache.get( cacheKey )
        if ( !isNull( cached ) ) {
            return cached
        }

        // Generate response
        var response = ai.chat( message, options )

        // Cache for 1 hour
        cache.set( cacheKey, response, 3600 )

        return response
    }
}
```

### Cost Management

```boxlang
// Estimate cost before calling
function estimateCost( prompt, model = "gpt-4o" ) {
    var tokenCount = aiTokens( prompt, model: model )

    var costs = {
        "gpt-4o": { input: 0.005, output: 0.015 },
        "gpt-3.5-turbo": { input: 0.0005, output: 0.0015 },
        "claude-3-5-sonnet": { input: 0.003, output: 0.015 }
    }

    var cost = costs[ model ]
    var estimatedInputCost = ( tokenCount / 1000 ) * cost.input
    var estimatedOutputCost = ( tokenCount / 1000 ) * cost.output

    return {
        inputCost: estimatedInputCost,
        outputCost: estimatedOutputCost,
        totalEstimate: estimatedInputCost + estimatedOutputCost
    }
}
```

## Related Skills

- [AI Agents](bx-ai-agents.md) - Autonomous agent development
- [AI Memory Systems](bx-ai-memory.md) - Conversation memory
- [AI Tools](bx-ai-tools.md) - Function calling
- [AI Pipelines](bx-ai-pipelines.md) - Multi-step workflows

## References

- [BoxLang AI Documentation](https://ai.ortusbooks.com)
- [Provider Configuration](https://ai.ortusbooks.com/providers)
- [Chat API Reference](https://ai.ortusbooks.com/chat)
