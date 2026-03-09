---
name: BoxLang AI - Pipelines
description: Complete guide to AI pipelines for chaining operations, multi-step workflows, and complex AI task orchestration
category: bx-ai
priority: high
triggers:
  - ai pipelines
  - ai workflows
  - chaining operations
---

# BoxLang AI - Pipelines

## Overview

AI pipelines enable chaining multiple AI operations together, creating complex workflows where the output of one step feeds into the next.

## Basic Pipelines

### Simple Pipeline

```boxlang
var pipeline = ai.pipeline()
    .transform( "Summarize: #longText#" )
    .transform( "Translate to Spanish: {result}" )
    .transform( "Make it formal: {result}" )
    .execute()

var result = pipeline.getResult()
```

### Pipeline with Variables

```boxlang
var pipeline = ai.pipeline()
    .set( "userInput", userText )
    .transform( "Extract key points from: {userInput}" )
    .set( "keyPoints", "{result}" )
    .transform( "Create action items from: {keyPoints}" )
    .execute()

var actionItems = pipeline.get( "result" )
```

## Advanced Pipelines

### Conditional Pipeline

```boxlang
var pipeline = ai.pipeline()
    .transform( "Analyze sentiment of: #text#" )
    .branch( function( sentiment ) {
        if ( sentiment.contains( "positive" ) ) {
            return "Create thank you response"
        } else if ( sentiment.contains( "negative" ) ) {
            return "Create apologetic response with solutions"
        } else {
            return "Create neutral acknowledgment"
        }
    } )
    .execute()
```

### Parallel Pipeline

```boxlang
var pipeline = ai.pipeline()
    .parallel( [
        function() { return ai.chat( "Summarize: #text#" ) },
        function() { return ai.chat( "Extract keywords: #text#" ) },
        function() { return ai.chat( "Identify topics: #text#" ) }
    ] )
    .combine( function( results ) {
        return {
            summary: results[ 1 ],
            keywords: results[ 2 ],
            topics: results[ 3 ]
        }
    } )
    .execute()
```

### Loop Pipeline

```boxlang
var pipeline = ai.pipeline()
    .set( "draft", initialDraft )
    .loop( maxIterations: 3, function( iteration ) {
        return ai.chat( "Improve this draft: {draft}" )
    } )
    .execute()
```

## Real-World Examples

### Content Creation Pipeline

```boxlang
function createArticle( topic ) {
    return ai.pipeline()
        // Research
        .transform( "Research key facts about: #topic#" )
        .set( "research", "{result}" )

        // Outline
        .transform( "Create article outline from: {research}" )
        .set( "outline", "{result}" )

        // Write
        .transform( "Write article using outline: {outline} and research: {research}" )
        .set( "draft", "{result}" )

        // Edit
        .transform( "Edit for clarity and grammar: {draft}" )

        .execute()
        .getResult()
}
```

### Data Analysis Pipeline

```boxlang
function analyzeData( data ) {
    return ai.pipeline()
        // Clean
        .transform( "Identify and list data quality issues in: #serializeJSON( data )#" )
        .set( "issues", "{result}" )

        // Analyze
        .transform( "Perform statistical analysis on: #serializeJSON( data )#" )
        .set( "analysis", "{result}" )

        // Visualize
        .transform( "Suggest visualization types for: {analysis}" )
        .set( "visualizations", "{result}" )

        // Insights
        .transform( "Generate business insights from: {analysis}" )

        .execute()
        .getResult()
}
```

### Code Review Pipeline

```boxlang
function reviewCode( code ) {
    return ai.pipeline()
        .parallel( [
            // Security review
            function() {
                return ai.chat( "Identify security issues: #code#" )
            },
            // Performance review
            function() {
                return ai.chat( "Identify performance issues: #code#" )
            },
            // Best practices review
            function() {
                return ai.chat( "Check best practices: #code#" )
            }
        ] )
        .combine( function( reviews ) {
            return {
                security: reviews[ 1 ],
                performance: reviews[ 2 ],
                bestPractices: reviews[ 3 ]
            }
        } )
        .transform( "Summarize all issues: {result}" )
        .execute()
        .getResult()
}
```

## Pipeline Patterns

### Extract-Transform-Load (ETL)

```boxlang
var pipeline = ai.pipeline()
    // Extract
    .extract( function() {
        return loadRawData()
    } )

    // Transform
    .transform( "Clean and structure this data: {result}" )

    // Load
    .load( function( transformedData ) {
        return saveToDatabase( transformedData )
    } )

    .execute()
```

### Map-Reduce

```boxlang
var pipeline = ai.pipeline()
    // Map: Process each item
    .map( items, function( item ) {
        return ai.chat( "Process: #item#" )
    } )

    // Reduce: Combine results
    .reduce( function( results ) {
        return ai.chat( "Combine these results: #serializeJSON( results )#" )
    } )

    .execute()
```

## Error Handling

### Retry Pipeline

```boxlang
var pipeline = ai.pipeline()
    .retry( maxAttempts: 3, function() {
        return ai.chat( message )
    } )
    .onError( function( error ) {
        log.error( "Pipeline failed: #error.message#" )
        return fallbackResponse
    } )
    .execute()
```

### Fallback Pipeline

```boxlang
var pipeline = ai.pipeline()
    .try( function() {
        return ai.chat( message, { model: "gpt-4o" } )
    } )
    .catch( function( error ) {
        // Fallback to cheaper model
        return ai.chat( message, { model: "gpt-3.5-turbo" } )
    } )
    .execute()
```

## Pipeline Monitoring

### Logging Pipeline

```boxlang
var pipeline = ai.pipeline()
    .onStep( function( stepName, result ) {
        log.debug( "Step #stepName# completed" )
    } )
    .transform( "Step 1" )
    .transform( "Step 2" )
    .transform( "Step 3" )
    .onComplete( function( result ) {
        log.info( "Pipeline completed" )
    } )
    .execute()
```

## Best Practices

### Modular Pipelines

```boxlang
// ✅ Good: Reusable pipeline steps
function researchStep( topic ) {
    return function( pipeline ) {
        return pipeline.transform( "Research: #topic#" )
    }
}

function writeStep() {
    return function( pipeline ) {
        return pipeline.transform( "Write article from: {research}" )
    }
}

var pipeline = ai.pipeline()
    .apply( researchStep( "BoxLang" ) )
    .apply( writeStep() )
    .execute()
```

### Pipeline Composition

```boxlang
// ✅ Good: Compose pipelines
function createContentPipeline() {
    return ai.pipeline()
        .transform( "Research topic: {topic}" )
        .transform( "Create outline from: {result}" )
}

function editPipeline() {
    return ai.pipeline()
        .transform( "Edit for grammar: {content}" )
        .transform( "Check formatting: {result}" )
}

// Combine pipelines
var fullPipeline = createContentPipeline()
    .merge( editPipeline() )
    .execute()
```

## Related Skills

- [AI Chat](bx-ai-chat.md) - Chat operations
- [AI Agents](bx-ai-agents.md) - Agent orchestration
- [AI Tools](bx-ai-tools.md) - Tool integration

## References

- [Pipelines](https://ai.ortusbooks.com/pipelines)
- [Workflows](https://ai.ortusbooks.com/workflows)
