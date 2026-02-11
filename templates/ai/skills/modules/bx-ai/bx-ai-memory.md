---
name: BoxLang AI - Memory Systems
description: Complete guide to AI memory systems including windowed, summary, session, file, cache, JDBC, and hybrid memory for conversation persistence
category: bx-ai
priority: high
triggers:
  - ai memory
  - conversation memory
  - chat history
  - memory systems
---

# BoxLang AI - Memory Systems

## Overview

BoxLang AI provides 20+ memory types for persisting conversation history, enabling contextual interactions, and managing long-term conversations across sessions.

## Memory Types

### Windowed Memory

Keeps the last N messages:

```boxlang
var memory = aiMemory( {
    type: "windowed",
    maxMessages: 10
} )

// Add messages
memory.add( aiMessage( "user", "Hello!" ) )
memory.add( aiMessage( "assistant", "Hi there!" ) )

// Get messages
var history = memory.getMessages()
// Returns last 10 messages
```

### Summary Memory

Summarizes old messages to save tokens:

```boxlang
var memory = aiMemory( {
    type: "summary",
    maxMessages: 20,
    summaryInterval: 10,  // Summarize every 10 messages
    model: "gpt-3.5-turbo"  // Model for summaries
} )

// As conversation grows, old messages are summarized
memory.add( aiMessage( "user", "Tell me about BoxLang" ) )
memory.add( aiMessage( "assistant", "BoxLang is..." ) )
// After 10 messages, creates summary
// After 20 more, summarizes again
```

### Session Memory

Stores in HTTP session:

```boxlang
var memory = aiMemory( {
    type: "session",
    sessionKey: "ai_conversation"
} )

// Persists for session duration
// Automatically clears when session ends
```

### File Memory

Persists to filesystem:

```boxlang
var memory = aiMemory( {
    type: "file",
    filePath: "conversations/#session.user.id#/#conversationId#.json",
    autoSave: true
} )

// Saves to file after each message
memory.add( aiMessage( "user", "Hello" ) )

// Load existing conversation
var memory2 = aiMemory( {
    type: "file",
    filePath: "conversations/123/conversation1.json"
} )
// Automatically loads existing messages
```

### Cache Memory

Stores in cache (temporary):

```boxlang
var memory = aiMemory( {
    type: "cache",
    cacheName: "default",
    cacheKey: "conversation_#conversationId#",
    ttl: 3600  // 1 hour
} )

// Good for temporary conversations
// Automatically expires
```

### JDBC Memory

Database-backed (production):

```boxlang
var memory = aiMemory( {
    type: "jdbc",
    datasource: "myDB",
    table: "ai_conversations",
    userId: session.user.id,
    conversationId: conversationId
} )

// Schema:
// CREATE TABLE ai_conversations (
//     id INT PRIMARY KEY AUTO_INCREMENT,
//     userId VARCHAR(100),
//     conversationId VARCHAR(100),
//     role VARCHAR(20),
//     content TEXT,
//     timestamp DATETIME,
//     metadata JSON
// )
```

## Multi-Tenant Memory

### User Isolation

```boxlang
var memory = aiMemory( {
    type: "jdbc",
    datasource: "myDB",
    userId: session.user.id,  // Isolate by user
    conversationId: rc.conversationId  // Isolate by conversation
} )

// Each user has separate conversations
// No data leakage between users
```

### Conversation Management

```boxlang
class ConversationService singleton {

    property name="dsn" inject="coldbox:setting:datasource"

    function createConversation( userId ) {
        var conversationId = createUUID()

        return aiMemory( {
            type: "jdbc",
            datasource: dsn,
            userId: userId,
            conversationId: conversationId
        } )
    }

    function getConversation( userId, conversationId ) {
        return aiMemory( {
            type: "jdbc",
            datasource: dsn,
            userId: userId,
            conversationId: conversationId
        } )
    }

    function listConversations( userId ) {
        return queryExecute(
            "SELECT DISTINCT conversationId, MIN(timestamp) as startedAt
             FROM ai_conversations
             WHERE userId = :userId
             GROUP BY conversationId
             ORDER BY startedAt DESC",
            { userId: userId },
            { datasource: dsn }
        )
    }

    function deleteConversation( userId, conversationId ) {
        var memory = getConversation( userId, conversationId )
        memory.clear()
    }
}
```

## Hybrid Memory

### Combining Memory Types

```boxlang
var memory = aiMemory( {
    type: "hybrid",
    // Short-term (recent messages)
    standard: {
        type: "windowed",
        maxMessages: 10
    },
    // Long-term (vector search)
    vector: {
        type: "boxvector",
        dimensions: 1536
    }
} )

// Stores recent messages in windowed
// Stores all messages in vector for semantic search

// When querying:
// 1. Gets recent messages from windowed
// 2. Searches relevant old messages from vector
// 3. Combines for context
```

### Session + JDBC Hybrid

```boxlang
var memory = aiMemory( {
    type: "hybrid",
    standard: {
        type: "session"  // Fast access
    },
    backup: {
        type: "jdbc",  // Persistent storage
        datasource: "myDB"
    }
} )

// Reads from session (fast)
// Writes to both session and JDBC (persistent)
```

## Memory Operations

### Adding Messages

```boxlang
// Add user message
memory.add( aiMessage( "user", "What is BoxLang?" ) )

// Add assistant message
memory.add( aiMessage( "assistant", "BoxLang is a dynamic language..." ) )

// Add system message
memory.add( aiMessage( "system", "You are a helpful assistant" ) )

// Add with metadata
memory.add( aiMessage( "user", "Hello", {
    timestamp: now(),
    ipAddress: cgi.remote_addr,
    userId: session.user.id
} ) )
```

### Retrieving Messages

```boxlang
// Get all messages
var messages = memory.getMessages()

// Get last N messages
var recent = memory.getMessages( limit: 5 )

// Get messages with filter
var userMessages = memory.getMessages( filter: function( msg ) {
    return msg.role == "user"
} )

// Search messages
var results = memory.search( "caching", limit: 10 )
```

### Clearing Memory

```boxlang
// Clear all messages
memory.clear()

// Clear old messages
memory.clearOlderThan( dateAdd( "d", -30, now() ) )

// Clear by role
memory.clearByRole( "system" )
```

## Memory with AI Services

### Simple Chat with Memory

```boxlang
var ai = aiService( provider: "openai" )
var memory = aiMemory( { type: "session" } )

function chat( message ) {
    // Add user message
    memory.add( aiMessage( "user", message ) )

    // Get conversation history
    var messages = memory.getMessages()

    // Send to AI
    var response = ai.chat( messages )

    // Store response
    memory.add( aiMessage( "assistant", response.content ) )

    return response.content
}

// Usage
chat( "Hello!" )
chat( "What did I just say?" )  // Has context
```

### Agent with Memory

```boxlang
var agent = aiAgent( {
    name: "Assistant",
    model: "gpt-4o",
    memory: aiMemory( {
        type: "jdbc",
        datasource: "myDB",
        userId: session.user.id
    } )
} )

// Memory automatically managed
var response = agent.chat( "Remember that I like TypeScript" )
var response2 = agent.chat( "What do I like?" )
// "You like TypeScript"
```

## Advanced Memory Patterns

### Conversation Branching

```boxlang
class ConversationTree {

    property name="memory"

    function init( baseMemory ) {
        variables.memory = baseMemory
        return this
    }

    function branch( branchId ) {
        // Create branch from current state
        var branchMemory = aiMemory( {
            type: "jdbc",
            datasource: memory.datasource,
            userId: memory.userId,
            conversationId: "#memory.conversationId#_branch_#branchId#"
        } )

        // Copy current messages
        memory.getMessages().each( function( msg ) {
            branchMemory.add( msg )
        } )

        return branchMemory
    }
}

// Usage
var mainConvo = ConversationTree( memory )
var alternateConvo = mainConvo.branch( "alternate1" )
```

### Memory Compression

```boxlang
function compressMemory( memory, targetSize = 10 ) {
    var messages = memory.getMessages()

    if ( messages.len() <= targetSize ) {
        return memory
    }

    // Keep system messages
    var systemMsgs = messages.filter( ( m ) => m.role == "system" )

    // Keep recent messages
    var recentMsgs = messages.slice( -targetSize )

    // Summarize middle
    var middleMsgs = messages.slice( systemMsgs.len() + 1, -targetSize )
    var summary = ai.chat(
        "Summarize this conversation:\n" &
        middleMsgs.map( ( m ) => "#m.role#: #m.content#" ).toList( "\n" )
    )

    // Create compressed memory
    var compressed = aiMemory( { type: "windowed", maxMessages: targetSize + 2 } )

    systemMsgs.each( ( m ) => compressed.add( m ) )
    compressed.add( aiMessage( "system", "Previous summary: #summary.content#" ) )
    recentMsgs.each( ( m ) => compressed.add( m ) )

    return compressed
}
```

### Contextual Memory

```boxlang
class ContextualMemory {

    property name="shortTerm"
    property name="longTerm"
    property name="ai"

    function init( config ) {
        variables.shortTerm = aiMemory( { type: "windowed", maxMessages: 5 } )
        variables.longTerm = aiMemory( { type: "jdbc", datasource: config.datasource } )
        variables.ai = aiService( provider: "openai" )
        return this
    }

    function add( message ) {
        variables.shortTerm.add( message )
        variables.longTerm.add( message )
    }

    function getRelevantContext( query ) {
        // Recent messages
        var recent = variables.shortTerm.getMessages()

        // Search long-term for relevant context
        var relevant = variables.longTerm.search( query, limit: 3 )

        // Combine
        return recent.append( relevant, true )
    }

    function chat( message ) {
        add( aiMessage( "user", message ) )

        var context = getRelevantContext( message )

        var response = variables.ai.chat( context )

        add( aiMessage( "assistant", response.content ) )

        return response.content
    }
}
```

## Memory Metadata

### Storing Metadata

```boxlang
memory.add( aiMessage( "user", "Hello", {
    timestamp: now(),
    userId: session.user.id,
    sessionId: session.sessionId,
    ipAddress: cgi.remote_addr,
    userAgent: cgi.http_user_agent,
    sentiment: "positive",
    language: "en",
    tags: [ "greeting", "initial_contact" ]
} ) )
```

### Filtering by Metadata

```boxlang
// Get messages by date range
var todayMessages = memory.getMessages( filter: function( msg ) {
    return dateDiff( "d", msg.metadata.timestamp, now() ) == 0
} )

// Get messages by tag
var greetings = memory.getMessages( filter: function( msg ) {
    return msg.metadata.tags.contains( "greeting" )
} )

// Get messages by sentiment
var positiveMessages = memory.getMessages( filter: function( msg ) {
    return msg.metadata.sentiment == "positive"
} )
```

## Performance Optimization

### Lazy Loading

```boxlang
class LazyMemory {

    property name="memory"
    property name="loaded" type="boolean" default="false"
    property name="messages" type="array"

    function init( memoryConfig ) {
        variables.memory = aiMemory( memoryConfig )
        return this
    }

    function getMessages() {
        if ( !variables.loaded ) {
            variables.messages = variables.memory.getMessages()
            variables.loaded = true
        }
        return variables.messages
    }

    function add( message ) {
        variables.memory.add( message )
        if ( variables.loaded ) {
            variables.messages.append( message )
        }
    }
}
```

### Caching

```boxlang
class CachedMemory {

    property name="memory"
    property name="cache" inject="cachebox:default"

    function init( memoryConfig ) {
        variables.memory = aiMemory( memoryConfig )
        return this
    }

    function getMessages() {
        var cacheKey = "memory_#memory.userId#_#memory.conversationId#"

        var cached = cache.get( cacheKey )
        if ( !isNull( cached ) ) {
            return cached
        }

        var messages = variables.memory.getMessages()
        cache.set( cacheKey, messages, 300 )  // 5 min cache

        return messages
    }

    function add( message ) {
        variables.memory.add( message )

        // Invalidate cache
        var cacheKey = "memory_#memory.userId#_#memory.conversationId#"
        cache.clear( cacheKey )
    }
}
```

## Best Practices

### Memory Type Selection

```boxlang
// ✅ Good: Choose based on use case
function getMemory( useCase, userId, conversationId ) {
    switch ( useCase ) {
        case "chatbot":
            // Short-term, fast
            return aiMemory( { type: "session" } )

        case "support":
            // Persistent, multi-tenant
            return aiMemory( {
                type: "jdbc",
                datasource: "myDB",
                userId: userId,
                conversationId: conversationId
            } )

        case "rag":
            // Semantic search
            return aiMemory( {
                type: "boxvector",
                dimensions: 1536
            } )

        case "temporary":
            // Auto-expire
            return aiMemory( {
                type: "cache",
                ttl: 3600
            } )
    }
}
```

### Memory Limits

```boxlang
// ✅ Good: Set appropriate limits
var memory = aiMemory( {
    type: "windowed",
    maxMessages: 20,  // Prevent memory bloat
    maxTokens: 4000   // Prevent API limits
} )

// ❌ Bad: Unlimited memory
var memory = aiMemory( {
    type: "jdbc"  // No limits, could grow indefinitely
} )
```

### Cleanup

```boxlang
// ✅ Good: Regular cleanup
function cleanupOldConversations() {
    queryExecute(
        "DELETE FROM ai_conversations
         WHERE timestamp < :cutoff",
        { cutoff: dateAdd( "m", -3, now() ) },
        { datasource: "myDB" }
    )
}

// Schedule cleanup
// In scheduler
function run() {
    cleanupOldConversations()
}
```

## Related Skills

- [AI Chat](bx-ai-chat.md) - Chat interactions
- [AI Agents](bx-ai-agents.md) - Agent development
- [AI Vector Memory](bx-ai-vector-memory.md) - Vector databases
- [AI Documents](bx-ai-documents.md) - Document processing

## References

- [Memory Systems](https://ai.ortusbooks.com/memory)
- [Memory Types](https://ai.ortusbooks.com/memory/types)
- [Multi-Tenancy](https://ai.ortusbooks.com/memory/multi-tenant)
