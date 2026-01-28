---
name: handler-development
description: Implementation patterns for ColdBox handler development
category: coldbox
triggers:
  - create handler
  - build handler
  - implement handler
---

# Handler Development Implementation Pattern

## When to Use This Skill

Use this skill when creating ColdBox handlers (controllers) for handling HTTP requests.

## Implementation Steps

1. Define handler name and actions
2. Add dependency injection for services
3. Implement actions with event, rc, prc parameters
4. Return views or data responses
5. Add security annotations if needed
6. Write handler tests

## Code Template (BoxLang)

```boxlang
class |HandlerName| extends coldbox.system.EventHandler {
    property name="|serviceName|" inject;

    function index( event, rc, prc ) {
        prc.|items| = |serviceName|.getAll()
        event.setView( "|viewPath|" )
    }

    function show( event, rc, prc ) {
        prc.|item| = |serviceName|.getById( rc.id ?: 0 )
        event.setView( "|viewPath|" )
    }

    function create( event, rc, prc ) {
        var result = |serviceName|.create( rc )
        event.renderData(
            data = result,
            statusCode = 201
        )
    }

    function update( event, rc, prc ) {
        var result = |serviceName|.update( rc.id ?: 0, rc )
        event.renderData( data = result )
    }

    function delete( event, rc, prc ) {
        |serviceName|.delete( rc.id ?: 0 )
        event.renderData(
            data = { "success": true },
            statusCode = 204
        )
    }
}
```

## Best Practices

- Use dependency injection for all services
- Always validate input data
- Use prc for view data, rc for request data
- Return appropriate HTTP status codes
- Add security annotations (`secured`, `securelist`)
- Keep handlers thin - delegate to services

## Common Pitfalls

- Not validating input
- Business logic in handlers (should be in services)
- Missing error handling
- Incorrect HTTP status codes
- Not using event.renderData() for REST responses

## Related Skills

- rest-api-development
- testing-handler
- security-implementation
