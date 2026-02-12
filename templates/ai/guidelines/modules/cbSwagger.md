---
title: CBSwagger Module Guidelines
description: OpenAPI/Swagger documentation generator for RESTful APIs with automatic spec generation
---

# CBSwagger Module Guidelines

## Overview

CBSwagger automatically generates OpenAPI v3 (formerly Swagger) documentation from your ColdBox application routes. It introspects your handlers and generates interactive API documentation.

## Installation

```bash
box install cbswagger
```

## Configuration

In `config/ColdBox.cfc`:

```boxlang
moduleSettings = {
    cbswagger = {
        // Route prefixes to document (default: ["api"])
        routes = [ "api", "v1", "v2" ],
        
        // Default output format: json or yml
        defaultFormat = "json",
        
        // API metadata
        info = {
            title = "My API",
            version = "1.0.0",
            description = "API for my awesome application",
            contact = {
                name = "API Support",
                email = "[email protected]",
                url = "https://example.com/support"
            },
            license = {
                name = "Apache 2.0",
                url = "https://www.apache.org/licenses/LICENSE-2.0"
            }
        },
        
        // Servers
        servers = [
            {
                url = "https://api.example.com",
                description = "Production"
            },
            {
                url = "https://staging-api.example.com",
                description = "Staging"
            }
        ],
        
        // Security schemes
        securityDefinitions = {
            bearerAuth = {
                type = "http",
                scheme = "bearer",
                bearerFormat = "JWT"
            },
            apiKey = {
                type = "apiKey",
                name = "X-API-Key",
                in = "header"
            }
        }
    }
}
```

## Accessing Documentation

```
# JSON format (default)
http://localhost:8080/cbswagger

# YAML format
http://localhost:8080/cbswagger?format=yml

# Swagger UI
http://localhost:8080/cbswagger/ui
```

## Documenting Handlers

### Handler-Level Documentation

```boxlang
/**
 * User management API endpoints
 * 
 * @route /api/v1/users
 * @tags users
 */
class Users extends coldbox.system.EventHandler {
    property name="userService" inject;
}
```

### Action Documentation

```boxlang
/**
 * List all users
 * 
 * @route (GET) /api/v1/users
 * @tags users
 * @summary Get all users
 * @description Returns a paginated list of users
 * 
 * @x-parameters-page (query) Page number (default: 1)
 * @x-parameters-perPage (query) Results per page (default: 25)
 * @x-parameters-status (query) Filter by status
 * 
 * @response-200 ~users/index.json
 * @response-401 Unauthorized
 */
function index( event, rc, prc ) {
    prc.users = userService.getAll(
        page = rc.page ?: 1,
        perPage = rc.perPage ?: 25
    )
    
    event.renderData( data = prc.users )
}

/**
 * Get user by ID
 * 
 * @route (GET) /api/v1/users/:id
 * @tags users
 * @summary Get a single user
 * 
 * @x-parameters-id (path) User ID (required)
 * 
 * @response-200 ~users/show.json
 * @response-404 User not found
 */
function show( event, rc, prc ) {
    prc.user = userService.getById( rc.id )
    event.renderData( data = prc.user )
}

/**
 * Create new user
 * 
 * @route (POST) /api/v1/users
 * @tags users
 * @summary Create a user
 * 
 * @x-requestBody ~users/create.json
 * 
 * @response-201 User created successfully
 * @response-422 Validation errors
 */
function create( event, rc, prc ) {
    prc.user = userService.create( rc )
    event.renderData( data = prc.user, statusCode = 201 )
}

/**
 * Update user
 * 
 * @route (PUT) /api/v1/users/:id
 * @tags users
 * @summary Update a user
 * 
 * @x-parameters-id (path) User ID (required)
 * @x-requestBody ~users/update.json
 * 
 * @response-200 User updated successfully
 * @response-404 User not found
 * @response-422 Validation errors
 */
function update( event, rc, prc ) {
    prc.user = userService.update( rc.id, rc )
    event.renderData( data = prc.user )
}

/**
 * Delete user
 * 
 * @route (DELETE) /api/v1/users/:id
 * @tags users
 * @summary Delete a user
 * 
 * @x-parameters-id (path) User ID (required)
 * 
 * @response-204 User deleted successfully
 * @response-404 User not found
 */
function delete( event, rc, prc ) {
    userService.delete( rc.id )
    event.renderData( data = { message: "Deleted" }, statusCode = 204 )
}
```

## Response Schema Files

Create JSON schema files for responses:

```json
// resources/apidocs/users/index.json
{
    "type": "object",
    "properties": {
        "data": {
            "type": "array",
            "items": {
                "$ref": "#/components/schemas/User"
            }
        },
        "pagination": {
            "$ref": "#/components/schemas/Pagination"
        }
    }
}
```

## Security

### Documenting Security

```boxlang
/**
 * Get protected resource
 * 
 * @route (GET) /api/v1/protected
 * @security bearerAuth
 * 
 * @response-200 Success
 * @response-401 Unauthorized
 */
function protectedResource( event, rc, prc ) {
    event.renderData( data = { message: "Secure data" } )
}
```

### Global Security

```boxlang
cbswagger = {
    // Apply security to all endpoints
    security = [
        { bearerAuth: [] }
    ]
}
```

## Tags & Grouping

```boxlang
/**
 * @route (GET) /api/v1/users
 * @tags users,management
 * @summary List users
 */
function index( event, rc, prc ) {}

/**
 * @route (GET) /api/v1/posts
 * @tags posts,content
 * @summary List posts
 */
function listPosts( event, rc, prc ) {}
```

## Common Patterns

### RESTful CRUD Handler

```boxlang
/**
 * User API
 * 
 * @route /api/v1/users
 * @tags users
 */
class Users extends coldbox.system.EventHandler {
    property name="userService" inject;
    
    /**
     * @route (GET) /api/v1/users
     * @summary List all users
     * @x-parameters-page (query) Page number
     * @x-parameters-perPage (query) Results per page
     * @response-200 ~users/list.json
     */
    function index( event, rc, prc ) {}
    
    /**
     * @route (GET) /api/v1/users/:id
     * @summary Get user by ID
     * @x-parameters-id (path) User ID (required)
     * @response-200 ~users/show.json
     * @response-404 Not found
     */
    function show( event, rc, prc ) {}
    
    /**
     * @route (POST) /api/v1/users
     * @summary Create user
     * @x-requestBody ~users/create.json
     * @response-201 Created
     * @response-422 Validation error
     */
    function create( event, rc, prc ) {}
    
    /**
     * @route (PUT) /api/v1/users/:id
     * @summary Update user
     * @x-parameters-id (path) User ID (required)
     * @x-requestBody ~users/update.json
     * @response-200 Updated
     * @response-404 Not found
     */
    function update( event, rc, prc ) {}
    
    /**
     * @route (DELETE) /api/v1/users/:id
     * @summary Delete user
     * @x-parameters-id (path) User ID (required)
     * @response-204 Deleted
     * @response-404 Not found
     */
    function delete( event, rc, prc ) {}
}
```

## Best Practices

- **Document all API endpoints** - Complete documentation improves API adoption
- **Use tags for organization** - Group related endpoints
- **Provide examples** - Include request/response examples
- **Document error responses** - Show all possible status codes
- **Use schema files** - Reference external JSON schema files
- **Secure Swagger UI** - Restrict access in production
- **Version your API** - Use route prefixes for versioning
- **Keep docs current** - Update documentation when changing APIs
- **Test via Swagger UI** - Use UI to test endpoints
- **Export for external tools** - Share OpenAPI spec with consumers

## Documentation

For complete CBSwagger documentation and OpenAPI specification details, visit:
https://github.com/coldbox-modules/cbSwagger
