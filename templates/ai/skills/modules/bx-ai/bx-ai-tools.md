---
name: BoxLang AI - Tools & Function Calling
description: Complete guide to AI function calling, tool integration, and enabling AI to interact with your application
category: bx-ai
priority: high
triggers:
  - function calling
  - ai tools
  - tool integration
---

# BoxLang AI - Tools & Function Calling

## Overview

Tools enable AI to call your functions, access live data, and interact with your application. This transforms static AI into dynamic, action-taking agents.

## Defining Tools

### Basic Tool

```boxlang
var tools = [
    {
        name: "getCurrentTime",
        description: "Get current time",
        parameters: {},
        function: function( args ) {
            return now()
        }
    }
]
```

### Tool with Parameters

```boxlang
{
    name: "getUser",
    description: "Retrieve user by ID",
    parameters: {
        userId: {
            type: "number",
            description: "The user's ID",
            required: true
        }
    },
    function: function( args ) {
        return userService.get( args.userId )
    }
}
```

### Complex Parameters

```boxlang
{
    name: "createOrder",
    description: "Create a new order",
    parameters: {
        userId: {
            type: "number",
            required: true
        },
        items: {
            type: "array",
            description: "Order items",
            items: {
                type: "object",
                properties: {
                    productId: { type: "number" },
                    quantity: { type: "number" }
                }
            },
            required: true
        },
        shipping: {
            type: "object",
            properties: {
                address: { type: "string" },
                method: {
                    type: "string",
                    enum: [ "standard", "express" ]
                }
            }
        }
    },
    function: function( args ) {
        return orderService.create( args )
    }
}
```

## Tool Categories

### Data Retrieval

```boxlang
var dataTools = [
    {
        name: "searchProducts",
        description: "Search products catalog",
        parameters: {
            query: { type: "string", required: true },
            category: { type: "string" },
            maxResults: { type: "number", default: 10 }
        },
        function: function( args ) {
            return productService.search( args.query, args.category, args.maxResults )
        }
    },
    {
        name: "getOrderStatus",
        description: "Get order status",
        parameters: {
            orderId: { type: "number", required: true }
        },
        function: function( args ) {
            return orderService.getStatus( args.orderId )
        }
    }
]
```

### Actions

```boxlang
var actionTools = [
    {
        name: "sendEmail",
        description: "Send email to user",
        parameters: {
            to: { type: "string", required: true },
            subject: { type: "string", required: true },
            body: { type: "string", required: true }
        },
        function: function( args ) {
            mailService.send( args.to, args.subject, args.body )
            return "Email sent successfully"
        }
    },
    {
        name: "createTicket",
        description: "Create support ticket",
        parameters: {
            subject: { type: "string", required: true },
            description: { type: "string", required: true },
            priority: {
                type: "string",
                enum: [ "low", "medium", "high" ],
                default: "medium"
            }
        },
        function: function( args ) {
            return ticketService.create( args )
        }
    }
]
```

### Calculations

```boxlang
var calcTools = [
    {
        name: "calculateShipping",
        description: "Calculate shipping cost",
        parameters: {
            weight: { type: "number", required: true },
            destination: { type: "string", required: true }
        },
        function: function( args ) {
            return shippingService.calculate( args.weight, args.destination )
        }
    }
]
```

## Using Tools with AI

### Direct Tool Usage

```boxlang
var ai = aiService( provider: "openai" )

var response = ai.chat(
    "What's the weather in New York?",
    {
        tools: tools,
        model: "gpt-4o"
    }
)
```

### Agent with Tools

```boxlang
var agent = aiAgent( {
    name: "SupportAgent",
    model: "gpt-4o",
    tools: tools
} )

var response = agent.chat( "Create a ticket for login issues" )
// Agent automatically calls createTicket tool
```

## Advanced Tool Patterns

### Authenticated Tools

```boxlang
function createAuthenticatedTool( toolConfig, requiredRole ) {
    return {
        name: toolConfig.name,
        description: toolConfig.description,
        parameters: toolConfig.parameters,
        function: function( args ) {
            // Check authentication
            if ( !authService.isAuthenticated() ) {
                throw( "Authentication required" )
            }

            // Check authorization
            if ( !authService.hasRole( requiredRole ) ) {
                throw( "Insufficient permissions" )
            }

            return toolConfig.function( args )
        }
    }
}

var secureTool = createAuthenticatedTool(
    {
        name: "deleteUser",
        description: "Delete user account",
        parameters: { userId: { type: "number" } },
        function: function( args ) {
            return userService.delete( args.userId )
        }
    },
    "admin"
)
```

### Tool with Validation

```boxlang
{
    name: "updateSettings",
    parameters: {
        key: { type: "string", required: true },
        value: { type: "string", required: true }
    },
    function: function( args ) {
        // Validate
        if ( !isValidSettingKey( args.key ) ) {
            throw( "Invalid setting key: #args.key#" )
        }

        // Update
        return settingsService.update( args.key, args.value )
    }
}
```

### Async Tools

```boxlang
{
    name: "processLargeFile",
    description: "Process large file asynchronously",
    parameters: {
        fileId: { type: "number", required: true }
    },
    function: function( args ) {
        var future = runAsync( function() {
            return fileProcessor.process( args.fileId )
        } )

        return {
            status: "processing",
            jobId: createUUID(),
            message: "File processing started"
        }
    }
}
```

## Tool Helpers

### Tool Builder

```boxlang
class ToolBuilder {

    property name="tool" type="struct"

    function init( name ) {
        variables.tool = {
            name: name,
            parameters: {}
        }
        return this
    }

    function description( desc ) {
        variables.tool.description = desc
        return this
    }

    function addParameter( name, type, required = false, description = "" ) {
        variables.tool.parameters[ name ] = {
            type: type,
            required: required,
            description: description
        }
        return this
    }

    function handler( func ) {
        variables.tool.function = func
        return this
    }

    function build() {
        return variables.tool
    }
}

// Usage
var tool = new ToolBuilder( "searchUsers" )
    .description( "Search users by name" )
    .addParameter( "query", "string", true, "Search query" )
    .addParameter( "limit", "number", false, "Max results" )
    .handler( function( args ) {
        return userService.search( args.query, args.limit ?: 10 )
    } )
    .build()
```

## Best Practices

### Clear Descriptions

```boxlang
// ✅ Good: Detailed description
{
    name: "getWeather",
    description: "Get current weather conditions for a specific location. Returns temperature, conditions, humidity, and wind speed.",
    parameters: {
        location: {
            type: "string",
            description: "City name or ZIP code (e.g., 'New York' or '10001')",
            required: true
        }
    }
}

// ❌ Bad: Vague description
{
    name: "getWeather",
    description: "Gets weather",
    parameters: {
        location: { type: "string" }
    }
}
```

### Error Handling

```boxlang
// ✅ Good: Proper error handling
function: function( args ) {
    try {
        return externalAPI.call( args )
    } catch ( any e ) {
        log.error( "Tool error: #e.message#" )
        return {
            error: true,
            message: "Unable to complete request: #e.message#"
        }
    }
}
```

## Related Skills

- [AI Agents](bx-ai-agents.md) - Agent development
- [AI Chat](bx-ai-chat.md) - Chat interactions
- [AI Pipelines](bx-ai-pipelines.md) - Workflows

## References

- [Tool Integration](https://ai.ortusbooks.com/tools)
- [Function Calling](https://ai.ortusbooks.com/function-calling)
