---
name: BoxLang AI - Agents
description: Complete guide to building autonomous AI agents with memory, tools, reasoning, and multi-agent systems using BoxLang AI
category: bx-ai
priority: high
triggers:
  - ai agents
  - autonomous agents
  - ai agent system
  - multi-agent
---

# BoxLang AI - Agents

## Overview

AI agents are autonomous systems that can understand tasks, decide which tools to use, execute actions, and synthesize responses. BoxLang AI provides a powerful agent framework with memory, tool integration, and multi-agent orchestration.

## Basic Agents

### Simple Agent

```boxlang
// Create agent
var agent = aiAgent( {
    name: "Assistant",
    model: "gpt-4o",
    systemPrompt: "You are a helpful AI assistant",
    memory: aiMemory( { type: "session" } )
} )

// Chat with agent
var response = agent.chat( "Hello! What can you help me with?" )
echo( response.content )

// Continue conversation (memory persists)
var response2 = agent.chat( "What did I just say?" )
```

### Agent Configuration

```boxlang
var agent = aiAgent( {
    name: "CodeAssistant",
    model: "gpt-4o",
    systemPrompt: """
        You are an expert BoxLang developer.
        - Write clean, modern BoxLang code
        - Include error handling
        - Follow SOLID principles
        - Add helpful comments
    """,
    temperature: 0.7,
    maxTokens: 2000,
    memory: aiMemory( {
        type: "windowed",
        maxMessages: 20
    } )
} )
```

## Agents with Tools

### Defining Tools

```boxlang
var tools = [
    {
        name: "getWeather",
        description: "Get current weather for a location",
        parameters: {
            location: {
                type: "string",
                description: "City name",
                required: true
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
    },
    {
        name: "searchDocs",
        description: "Search documentation",
        parameters: {
            query: {
                type: "string",
                description: "Search query",
                required: true
            }
        },
        function: function( args ) {
            return docsService.search( args.query )
        }
    }
]
```

### Agent with Tools

```boxlang
var agent = aiAgent( {
    name: "SupportAgent",
    model: "gpt-4o",
    systemPrompt: "You are a customer support agent. Use available tools to help customers.",
    tools: tools,
    memory: aiMemory( { type: "session" } )
} )

// Agent will automatically decide which tools to use
var response = agent.chat( "What's the weather in New York?" )
// Agent calls getWeather tool with location="New York"

var response2 = agent.chat( "How do I configure BoxLang?" )
// Agent calls searchDocs tool with query="configure boxlang"
```

### Tool Execution Flow

```boxlang
var agent = aiAgent( {
    name: "DataAgent",
    tools: [
        {
            name: "queryDatabase",
            description: "Query the database",
            parameters: {
                sql: { type: "string", required: true }
            },
            function: function( args ) {
                log.info( "Executing SQL: #args.sql#" )
                return queryExecute( args.sql )
            }
        },
        {
            name: "saveReport",
            description: "Save a report to file",
            parameters: {
                filename: { type: "string", required: true },
                content: { type: "string", required: true }
            },
            function: function( args ) {
                fileWrite( args.filename, args.content )
                return "Report saved: #args.filename#"
            }
        }
    ]
} )

// Agent can chain tools
var response = agent.chat( "Get all active users and save to report.txt" )
// 1. Calls queryDatabase with SQL
// 2. Formats results
// 3. Calls saveReport with content
```

## Advanced Agent Patterns

### Reasoning Agent

```boxlang
var reasoningAgent = aiAgent( {
    name: "Reasoner",
    model: "gpt-4o",
    systemPrompt: """
        You are a reasoning agent. For each task:
        1. Break down the problem
        2. Think through the solution step by step
        3. Execute the solution
        4. Verify the result

        Use chain-of-thought reasoning for complex tasks.
    """,
    tools: tools
} )

var response = reasoningAgent.chat( "Calculate compound interest for $1000 at 5% for 10 years" )
```

### Retrieval Agent (RAG)

```boxlang
var ragAgent = aiAgent( {
    name: "DocAgent",
    model: "gpt-4o",
    systemPrompt: "Answer questions using the provided documentation context",
    tools: [
        {
            name: "searchVectorDB",
            description: "Search documentation by semantic similarity",
            parameters: {
                query: { type: "string", required: true },
                limit: { type: "number", default: 5 }
            },
            function: function( args ) {
                return vectorMemory.search( args.query, limit: args.limit )
            }
        }
    ]
} )

var response = ragAgent.chat( "How do I implement caching in BoxLang?" )
// Agent searches vector DB and uses context to answer
```

### Validation Agent

```boxlang
var validatorAgent = aiAgent( {
    name: "Validator",
    model: "gpt-4o",
    systemPrompt: """
        You are a code validation agent.
        - Check for syntax errors
        - Verify best practices
        - Suggest improvements
        - Return JSON with validation results
    """,
    temperature: 0.3  // More deterministic
} )

var code = """
    class UserService {
        function getUser(id) {
            return query( "SELECT * FROM users WHERE id = #id#" )
        }
    }
"""

var response = validatorAgent.chat( "Validate this code: #code#" )
var validation = deserializeJSON( response.content )
```

## Multi-Agent Systems

### Agent Workflow

```boxlang
// Define specialized agents
var researcher = aiAgent( {
    name: "Researcher",
    model: "gpt-4o",
    systemPrompt: "Research topics and gather comprehensive information",
    tools: [
        {
            name: "webSearch",
            description: "Search the web",
            parameters: { query: { type: "string", required: true } },
            function: function( args ) {
                return webSearchService.search( args.query )
            }
        }
    ]
} )

var writer = aiAgent( {
    name: "Writer",
    model: "claude-3-5-sonnet",
    systemPrompt: "Write engaging, well-structured content from research"
} )

var editor = aiAgent( {
    name: "Editor",
    model: "gpt-4o",
    systemPrompt: "Edit content for clarity, grammar, and style"
} )

// Execute workflow
function createArticle( topic ) {
    // Step 1: Research
    var research = researcher.chat( "Research comprehensive information about: #topic#" )

    // Step 2: Write
    var draft = writer.chat( "Write an article using this research: #research.content#" )

    // Step 3: Edit
    var final = editor.chat( "Edit and refine this article: #draft.content#" )

    return final.content
}

var article = createArticle( "BoxLang AI Features" )
```

### Collaborative Agents

```boxlang
class AgentTeam {

    property name="agents" type="array"

    function init() {
        variables.agents = [
            aiAgent( {
                name: "Analyst",
                systemPrompt: "Analyze data and identify patterns"
            } ),
            aiAgent( {
                name: "Designer",
                systemPrompt: "Design solutions based on analysis"
            } ),
            aiAgent( {
                name: "Implementer",
                systemPrompt: "Implement designed solutions"
            } )
        ]
        return this
    }

    function executeTask( task ) {
        var results = []

        // Each agent contributes
        variables.agents.each( function( agent ) {
            var prompt = "Task: #task#\n\nPrevious work: #serializeJSON( results )#\n\nYour contribution:"
            var result = agent.chat( prompt )
            results.append( {
                agent: agent.name,
                output: result.content
            } )
        } )

        return results
    }
}

var team = new AgentTeam()
var results = team.executeTask( "Design and implement a caching system" )
```

### Agent Supervisor

```boxlang
var supervisor = aiAgent( {
    name: "Supervisor",
    model: "gpt-4o",
    systemPrompt: """
        You are a supervisor agent that coordinates other agents.
        - Analyze tasks
        - Delegate to appropriate agents
        - Synthesize results
        - Return final output
    """,
    tools: [
        {
            name: "delegateToResearcher",
            description: "Delegate research tasks",
            parameters: { task: { type: "string", required: true } },
            function: function( args ) {
                return researcher.chat( args.task )
            }
        },
        {
            name: "delegateToWriter",
            description: "Delegate writing tasks",
            parameters: { task: { type: "string", required: true } },
            function: function( args ) {
                return writer.chat( args.task )
            }
        }
    ]
} )

var response = supervisor.chat( "Create a comprehensive guide about BoxLang caching" )
// Supervisor delegates to researcher and writer, then synthesizes
```

## Agent Memory

### Persistent Memory

```boxlang
var agent = aiAgent( {
    name: "PersonalAssistant",
    memory: aiMemory( {
        type: "jdbc",
        datasource: "myDB",
        userId: session.user.id,
        conversationId: conversationId
    } )
} )

// Memory persists across sessions
var response = agent.chat( "Remember that I prefer TypeScript" )
// Later...
var response2 = agent.chat( "What programming language do I prefer?" )
// "You prefer TypeScript"
```

### Vector Memory for Context

```boxlang
var agent = aiAgent( {
    name: "KnowledgeAgent",
    memory: aiMemory( {
        type: "hybrid",
        standard: {
            type: "windowed",
            maxMessages: 10
        },
        vector: {
            type: "boxvector",
            dimensions: 1536
        }
    } )
} )

// Agent uses vector memory for semantic context
var response = agent.chat( "What did we discuss about caching yesterday?" )
// Searches vector memory for relevant context
```

## Agent Execution Strategies

### Sequential Execution

```boxlang
function executeSequential( agents, task ) {
    var result = task

    agents.each( function( agent ) {
        result = agent.chat( result ).content
    } )

    return result
}

var pipeline = [
    plannerAgent,
    implementerAgent,
    testerAgent
]

var finalResult = executeSequential( pipeline, "Create a user service" )
```

### Parallel Execution

```boxlang
function executeParallel( agents, task ) {
    var futures = agents.map( function( agent ) {
        return runAsync( function() {
            return agent.chat( task )
        } )
    } )

    return futures.map( function( f ) {
        return f.get()
    } )
}

var specialists = [
    securityAgent,
    performanceAgent,
    usabilityAgent
]

var reviews = executeParallel( specialists, "Review this code: #code#" )
```

### Voting/Consensus

```boxlang
function executeWithConsensus( agents, task, threshold = 0.7 ) {
    var responses = []

    agents.each( function( agent ) {
        var response = agent.chat( task )
        responses.append( response.content )
    } )

    // Analyze consensus
    var consensusAgent = aiAgent( {
        systemPrompt: "Analyze these responses and find consensus"
    } )

    var analysis = consensusAgent.chat(
        "Find consensus from these responses: #serializeJSON( responses )#"
    )

    return analysis.content
}

var validators = [
    validator1Agent,
    validator2Agent,
    validator3Agent
]

var consensus = executeWithConsensus( validators, "Is this code secure?" )
```

## Agent Monitoring

### Logging Agent Actions

```boxlang
var agent = aiAgent( {
    name: "MonitoredAgent",
    onBeforeChat: function( message ) {
        log.info( "Agent receiving: #message#" )
    },
    onAfterChat: function( message, response ) {
        log.info( "Agent responding: #response.content#" )
    },
    onToolCall: function( toolName, args ) {
        log.debug( "Tool called: #toolName# with #serializeJSON( args )#" )
    },
    onError: function( error ) {
        log.error( "Agent error: #error.message#" )
    }
} )
```

### Performance Tracking

```boxlang
class MonitoredAgent {

    property name="agent"
    property name="metrics" type="struct"

    function init( agentConfig ) {
        variables.agent = aiAgent( agentConfig )
        variables.metrics = {
            calls: 0,
            totalTokens: 0,
            totalTime: 0,
            errors: 0
        }
        return this
    }

    function chat( message ) {
        var start = getTickCount()

        try {
            variables.metrics.calls++

            var response = variables.agent.chat( message )

            variables.metrics.totalTokens += response.usage.totalTokens
            variables.metrics.totalTime += getTickCount() - start

            return response

        } catch ( any e ) {
            variables.metrics.errors++
            rethrow
        }
    }

    function getMetrics() {
        return variables.metrics
    }
}
```

## Best Practices

### Agent Design

```boxlang
// ✅ Good: Focused, single-purpose agent
var agent = aiAgent( {
    name: "WeatherAgent",
    systemPrompt: "Provide weather information using the weather tool",
    tools: [ weatherTool ]
} )

// ❌ Bad: Generic, unfocused agent
var agent = aiAgent( {
    systemPrompt: "Do whatever the user asks"
} )
```

### Tool Design

```boxlang
// ✅ Good: Clear, specific tool
{
    name: "getUserById",
    description: "Retrieve user by their unique ID",
    parameters: {
        userId: {
            type: "number",
            description: "The user's unique identifier",
            required: true
        }
    },
    function: function( args ) {
        return userService.get( args.userId )
    }
}

// ❌ Bad: Vague tool
{
    name: "doSomething",
    description: "Does something with data",
    function: function( args ) {
        // Unclear purpose
    }
}
```

### Error Handling

```boxlang
var agent = aiAgent( {
    tools: [
        {
            name: "riskyOperation",
            function: function( args ) {
                try {
                    return externalService.call( args )
                } catch ( any e ) {
                    log.error( "Tool error: #e.message#" )
                    return {
                        error: true,
                        message: "Operation failed: #e.message#"
                    }
                }
            }
        }
    ]
} )
```

## Related Skills

- [AI Chat](bx-ai-chat.md) - Basic chat interactions
- [AI Memory](bx-ai-memory.md) - Memory systems
- [AI Tools](bx-ai-tools.md) - Function calling
- [AI Pipelines](bx-ai-pipelines.md) - Workflows

## References

- [BoxLang AI Agents](https://ai.ortusbooks.com/agents)
- [Tool Integration](https://ai.ortusbooks.com/tools)
- [Multi-Agent Systems](https://ai.ortusbooks.com/multi-agent)
