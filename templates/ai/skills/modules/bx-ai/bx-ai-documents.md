---
name: BoxLang AI - Document Processing
description: Complete guide to loading, processing, chunking documents for RAG workflows with 12+ document loaders
category: bx-ai
priority: high
triggers:
  - document loading
  - document processing
  - document chunking
  - rag documents
---

# BoxLang AI - Document Processing

## Overview

BoxLang AI provides 12+ document loaders for processing text, PDFs, HTML, CSV, JSON, XML, and more for RAG workflows.

## Document Loaders

### Text Files

```boxlang
var docs = aiDocuments( {
    source: "text",
    content: fileRead( "document.txt" )
} )
```

### PDF Documents

```boxlang
var docs = aiDocuments( {
    source: "pdf",
    file: "manual.pdf"
} )

// With options
var docs = aiDocuments( {
    source: "pdf",
    file: "manual.pdf",
    options: {
        extractImages: true,
        ocrEnabled: true
    }
} )
```

### Markdown

```boxlang
var docs = aiDocuments( {
    source: "markdown",
    file: "README.md",
    parseLinks: true,
    parseImages: true
} )
```

### HTML/Web Pages

```boxlang
var docs = aiDocuments( {
    source: "http",
    url: "https://example.com/docs"
} )

// With CSS selector
var docs = aiDocuments( {
    source: "http",
    url: "https://example.com/docs",
    selector: ".documentation"
} )
```

### CSV

```boxlang
var docs = aiDocuments( {
    source: "csv",
    file: "data.csv",
    headers: true
} )
```

### JSON

```boxlang
var docs = aiDocuments( {
    source: "json",
    file: "config.json"
} )
```

### XML

```boxlang
var docs = aiDocuments( {
    source: "xml",
    file: "data.xml"
} )
```

### Directories

```boxlang
var docs = aiDocuments( {
    source: "directory",
    path: "docs/",
    recursive: true,
    extensions: [ "md", "txt", "pdf" ]
} )
```

### SQL Queries

```boxlang
var docs = aiDocuments( {
    source: "sql",
    datasource: "myDB",
    sql: "SELECT id, content, title FROM articles",
    contentColumn: "content",
    metadataColumns: [ "id", "title" ]
} )
```

### RSS/Atom Feeds

```boxlang
var docs = aiDocuments( {
    source: "rss",
    url: "https://example.com/feed.xml"
} )
```

### Web Crawler

```boxlang
var docs = aiDocuments( {
    source: "crawler",
    startUrl: "https://example.com/docs",
    maxPages: 50,
    selector: ".content",
    followLinks: true
} )
```

### Log Files

```boxlang
var docs = aiDocuments( {
    source: "logs",
    file: "application.log",
    pattern: "^\[([^\]]+)\] (.+)$"
} )
```

## Document Chunking

### Basic Chunking

```boxlang
var docs = aiDocuments( { source: "text", content: largeText } )

// Chunk by size
var chunks = aiChunk( docs, {
    size: 1000,
    overlap: 200
} )
```

### Chunking Strategies

```boxlang
// By characters
var chunks = aiChunk( docs, {
    strategy: "character",
    size: 1000,
    overlap: 100
} )

// By tokens
var chunks = aiChunk( docs, {
    strategy: "token",
    size: 500,
    overlap: 50,
    model: "gpt-4o"
} )

// By sentences
var chunks = aiChunk( docs, {
    strategy: "sentence",
    maxSentences: 5
} )

// By paragraphs
var chunks = aiChunk( docs, {
    strategy: "paragraph",
    minLength: 100
} )
```

### Smart Chunking

```boxlang
// Preserve markdown structure
var chunks = aiChunk( docs, {
    strategy: "markdown",
    size: 1000,
    preserveHeaders: true
} )

// Preserve code blocks
var chunks = aiChunk( docs, {
    strategy: "code-aware",
    size: 800,
    preserveBlocks: true
} )
```

## RAG Workflow

### Complete Pipeline

```boxlang
function buildRAGSystem( docsPath ) {
    // 1. Load documents
    var docs = aiDocuments( {
        source: "directory",
        path: docsPath,
        recursive: true
    } )

    // 2. Chunk documents
    var chunks = aiChunk( docs, {
        size: 1000,
        overlap: 200
    } )

    // 3. Create vector memory
    var vectorMemory = aiMemory( {
        type: "boxvector",
        dimensions: 1536
    } )

    // 4. Index chunks
    chunks.each( function( chunk, index ) {
        vectorMemory.add( {
            id: "chunk_#index#",
            content: chunk.content,
            metadata: chunk.metadata
        } )
    } )

    return vectorMemory
}

// Usage
var vectorMemory = buildRAGSystem( "docs/" )
```

### Query RAG System

```boxlang
function queryRAG( question, vectorMemory ) {
    // Search relevant documents
    var results = vectorMemory.search( question, limit: 5 )

    // Build context
    var context = results
        .map( ( r ) => r.content )
        .toList( "\n\n" )

    // Generate answer
    var prompt = """
        Answer based on this context:
        #context#

        Question: #question#
    """

    return ai.chat( prompt ).content
}
```

## Document Metadata

### Extracting Metadata

```boxlang
var docs = aiDocuments( {
    source: "pdf",
    file: "manual.pdf",
    extractMetadata: true
} )

docs.each( function( doc ) {
    echo( "Title: #doc.metadata.title#\n" )
    echo( "Author: #doc.metadata.author#\n" )
    echo( "Created: #doc.metadata.createdDate#\n" )
} )
```

### Custom Metadata

```boxlang
var chunks = aiChunk( docs, { size: 1000 } )

chunks.each( function( chunk ) {
    chunk.metadata.indexed = now()
    chunk.metadata.source = "documentation"
    chunk.metadata.version = "1.0"
} )
```

## Async Loading

```boxlang
function loadDocumentsAsync( paths ) {
    var futures = paths.map( function( path ) {
        return runAsync( function() {
            return aiDocuments( {
                source: "directory",
                path: path
            } )
        } )
    } )

    return futures.map( ( f ) => f.get() )
}
```

## Best Practices

### Chunk Size Selection

```boxlang
// ✅ Good: Based on use case
function getChunkSize( useCase ) {
    switch ( useCase ) {
        case "qa":
            return { size: 500, overlap: 100 }  // Short, focused
        case "summarization":
            return { size: 2000, overlap: 200 }  // Longer context
        case "code":
            return { size: 800, overlap: 0 }  // Complete blocks
    }
}
```

### Metadata for Filtering

```boxlang
// ✅ Good: Rich metadata
vectorMemory.add( {
    content: chunk.content,
    metadata: {
        source: "manual.pdf",
        section: "authentication",
        version: "2.0",
        lastUpdated: now(),
        tags: [ "security", "auth" ]
    }
} )
```

## Related Skills

- [AI Vector Memory](bx-ai-vector-memory.md) - Vector databases
- [AI Chat](bx-ai-chat.md) - Chat with context
- [AI Agents](bx-ai-agents.md) - RAG agents

## References

- [Document Loaders](https://ai.ortusbooks.com/documents)
- [Chunking Strategies](https://ai.ortusbooks.com/documents/chunking)
- [RAG Workflows](https://ai.ortusbooks.com/rag)
