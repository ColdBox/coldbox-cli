---
name: BoxLang AI - Vector Memory & RAG
description: Complete guide to vector memory, semantic search, RAG workflows, and vector database integration with BoxLang AI
category: bx-ai
priority: high
triggers:
  - vector memory
  - semantic search
  - RAG
  - retrieval augmented generation
  - embeddings
---

# BoxLang AI - Vector Memory & RAG

## Overview

Vector memory enables semantic search by storing text embeddings in vector databases. This powers RAG (Retrieval-Augmented Generation) workflows where AI retrieves relevant context before generating responses.

## Vector Databases

BoxLang AI supports 12 vector database providers.

### BoxVector (Built-In)

```boxlang
var vectorMemory = aiMemory( {
    type: "boxvector",
    dimensions: 1536,
    similarity: "cosine"  // or "euclidean", "dotproduct"
} )
```

### Chroma

```boxlang
var vectorMemory = aiMemory( {
    type: "chroma",
    host: "localhost",
    port: 8000,
    collection: "documents"
} )
```

### PostgreSQL (pgvector)

```boxlang
var vectorMemory = aiMemory( {
    type: "postgres",
    datasource: "pgDB",
    table: "embeddings",
    dimensions: 1536
} )
```

### Pinecone

```boxlang
var vectorMemory = aiMemory( {
    type: "pinecone",
    apiKey: getSystemSetting( "PINECONE_API_KEY" ),
    environment: "us-west1-gcp",
    index: "documents"
} )
```

### Other Providers

- **MySQL**: Native vector support
- **OpenSearch**: Distributed search
- **TypeSense**: Fast semantic search
- **Qdrant**: High-performance vectors
- **Weaviate**: AI-native database
- **Milvus**: Scalable vector search

## Basic Operations

### Storing Embeddings

```boxlang
// Add document
vectorMemory.add( {
    id: "doc1",
    content: "BoxLang is a dynamic language for the JVM",
    metadata: {
        title: "Introduction to BoxLang",
        category: "documentation"
    }
} )

// Batch add
vectorMemory.addBatch( [
    { id: "doc1", content: "First document" },
    { id: "doc2", content: "Second document" },
    { id: "doc3", content: "Third document" }
] )
```

### Semantic Search

```boxlang
// Search by query
var results = vectorMemory.search( "What is BoxLang?", limit: 5 )

results.each( function( result ) {
    echo( "Score: #result.score#\n" )
    echo( "Content: #result.content#\n\n" )
} )
```

### Filtering

```boxlang
// Search with metadata filter
var results = vectorMemory.search(
    "dependency injection",
    {
        limit: 5,
        filter: {
            category: "documentation",
            version: "1.0"
        }
    }
)
```

## RAG (Retrieval-Augmented Generation)

### Basic RAG

```boxlang
function askWithContext( question ) {
    // 1. Search relevant documents
    var relevantDocs = vectorMemory.search( question, limit: 3 )

    // 2. Build context
    var context = relevantDocs
        .map( ( doc ) => doc.content )
        .toList( "\n\n" )

    // 3. Generate response with context
    var prompt = """
        Answer the question using the provided context.

        Context:
        #context#

        Question: #question#
    """

    return ai.chat( prompt ).content
}

var answer = askWithContext( "How do I configure caching?" )
```

### RAG Agent

```boxlang
var ragAgent = aiAgent( {
    name: "DocAgent",
    model: "gpt-4o",
    systemPrompt: "Answer questions using retrieved context",
    tools: [
        {
            name: "searchDocs",
            description: "Search documentation",
            parameters: {
                query: { type: "string", required: true }
            },
            function: function( args ) {
                return vectorMemory.search( args.query, limit: 5 )
            }
        }
    ]
} )

var response = ragAgent.chat( "How do I implement authentication?" )
```

### Hybrid Search

```boxlang
// Combine vector + keyword search
function hybridSearch( query, limit = 5 ) {
    // Vector search (semantic)
    var vectorResults = vectorMemory.search( query, limit: limit )

    // Keyword search
    var keywordResults = queryExecute(
        "SELECT * FROM documents WHERE content LIKE :query LIMIT :limit",
        { query: "%#query#%", limit: limit }
    )

    // Merge and re-rank
    return mergeResults( vectorResults, keywordResults )
}
```

## Document Indexing

### Index Documents

```boxlang
// Load documents
var docs = aiDocuments( {
    source: "directory",
    path: "docs/",
    recursive: true
} )

// Chunk documents
var chunks = aiChunk( docs, {
    size: 1000,
    overlap: 200
} )

// Index in vector DB
chunks.each( function( chunk, index ) {
    vectorMemory.add( {
        id: "chunk_#index#",
        content: chunk.content,
        metadata: chunk.metadata
    } )
} )
```

### Incremental Indexing

```boxlang
function indexNewDocuments() {
    // Get last indexed timestamp
    var lastIndexed = cache.get( "last_indexed", dateAdd( "yyyy", -1, now() ) )

    // Find new documents
    var newDocs = queryExecute(
        "SELECT * FROM documents WHERE createdAt > :lastIndexed",
        { lastIndexed: lastIndexed }
    )

    // Index new documents
    newDocs.each( function( doc ) {
        vectorMemory.add( {
            id: doc.id,
            content: doc.content,
            metadata: {
                title: doc.title,
                createdAt: doc.createdAt
            }
        } )
    } )

    // Update timestamp
    cache.set( "last_indexed", now() )
}
```

## Advanced RAG Patterns

### Multi-Query RAG

```boxlang
function multiQueryRAG( question ) {
    // Generate multiple search queries
    var queries = ai.chat(
        "Generate 3 different search queries for: #question#"
    ).content.split( "\n" )

    // Search with each query
    var allResults = []
    queries.each( function( query ) {
        var results = vectorMemory.search( query, limit: 2 )
        allResults.append( results, true )
    } )

    // Deduplicate and rank
    var uniqueResults = deduplicateResults( allResults )

    // Generate answer
    var context = uniqueResults.map( ( r ) => r.content ).toList( "\n" )
    return ai.chat( "Answer using: #context#\nQuestion: #question#" )
}
```

### Reranking

```boxlang
function rerank( results, query ) {
    // Use AI to rerank results
    var prompt = """
        Rank these documents by relevance to: "#query#"
        Return indices in order (most relevant first).

        Documents:
        #results.map( ( r, i ) => "#i#: #r.content#" ).toList( "\n" )#
    """

    var ranking = ai.chat( prompt ).content

    // Reorder results based on ranking
    return reorderByRanking( results, ranking )
}
```

### Parent-Child Chunking

```boxlang
// Store small chunks for search, large chunks for context
function indexWithParentChild( document ) {
    // Split into large parent chunks
    var parents = aiChunk( document, { size: 2000 } )

    parents.each( function( parent, pIndex ) {
        var parentId = "parent_#pIndex#"

        // Split parent into small child chunks
        var children = aiChunk( parent, { size: 500 } )

        children.each( function( child, cIndex ) {
            // Index child with parent reference
            vectorMemory.add( {
                id: "child_#pIndex#_#cIndex#",
                content: child.content,
                metadata: {
                    parentId: parentId,
                    parentContent: parent.content
                }
            } )
        } )
    } )
}

// Search children, use parent for context
function searchWithParentContext( query ) {
    var childResults = vectorMemory.search( query, limit: 3 )

    return childResults.map( function( child ) {
        return {
            matched: child.content,
            fullContext: child.metadata.parentContent
        }
    } )
}
```

## Embeddings

### Generate Embeddings

```boxlang
// Single embedding
var embedding = ai.embed( "Hello world" )

// Batch embeddings
var texts = [ "First", "Second", "Third" ]
var embeddings = ai.embedBatch( texts )

// Store with embeddings
embeddings.each( function( emb, index ) {
    vectorMemory.add( {
        id: index,
        content: texts[ index ],
        embedding: emb
    } )
} )
```

### Custom Embeddings

```boxlang
// Use specific embedding model
var embedding = ai.embed( text, {
    provider: "openai",
    model: "text-embedding-3-large",
    dimensions: 1536
} )
```

## Performance Optimization

### Batch Operations

```boxlang
// ✅ Good: Batch add
var documents = loadDocuments()
vectorMemory.addBatch( documents )

// ❌ Bad: One at a time
documents.each( ( doc ) => vectorMemory.add( doc ) )
```

### Caching Search Results

```boxlang
class CachedVectorSearch {

    property name="vectorMemory"
    property name="cache" inject="cachebox:default"

    function search( query, options = {} ) {
        var cacheKey = "vsearch_#hash( query )#"

        var cached = cache.get( cacheKey )
        if ( !isNull( cached ) ) {
            return cached
        }

        var results = vectorMemory.search( query, options )
        cache.set( cacheKey, results, 3600 )

        return results
    }
}
```

## Related Skills

- [AI Documents](bx-ai-documents.md) - Document loading
- [AI Memory](bx-ai-memory.md) - Memory systems
- [AI Agents](bx-ai-agents.md) - RAG agents
- [AI Chat](bx-ai-chat.md) - Chat interactions

## References

- [Vector Memory](https://ai.ortusbooks.com/vector-memory)
- [RAG Workflows](https://ai.ortusbooks.com/rag)
- [Embeddings](https://ai.ortusbooks.com/embeddings)
