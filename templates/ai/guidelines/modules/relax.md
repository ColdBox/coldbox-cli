# Relax Module Guideline

## Overview

ColdBox Relax (RESTful Tools for Lazy Experts) is a comprehensive module for modeling, documenting, testing, and monitoring RESTful web services. It provides a visual interface for API design, automatic documentation generation, endpoint testing, and export capabilities - making REST API development faster and more consistent.

**Benefits:**
- API modeling with RelaxDSL - declarative API definition
- Interactive documentation - automatically generated from models
- API testing interface - test endpoints directly in browser
- Multiple export formats - HTML, PDF, Swagger/OpenAPI
- History tracking - test result history
- Multi-API support - manage multiple API definitions

## Installation

```bash
box install relax
```

## Configuration

Configure in `config/ColdBox.cfc` under `moduleSettings.relax`:

```javascript
moduleSettings = {
    relax = {
        // Location of API definitions
        APILocation = "models.resources",
        // Default API to load
        defaultAPI = "myapi",
        // APIs to exclude from display (list or array, supports regex)
        exclude = "",
        // History stack size for Relaxer test tool
        maxHistory = 10
    }
}
```

## API Modeling with RelaxDSL

### Creating an API Definition

Create a CFC in your `APILocation` (default: `models/resources/`):

```javascript
// models/resources/MyAPI.cfc
component {
    
    function configure() {
        // API Metadata
        this.relax = {
            title = "My REST API",
            description = "API for managing users and products",
            version = "1.0.0",
            termsOfService = "https://example.com/terms",
            contact = {
                name = "API Support",
                email = "api@example.com",
                url = "https://example.com/support"
            }
        }
        
        // Define global response formats
        globalResponse( "200", "Success" )
        globalResponse( "400", "Bad Request" )
        globalResponse( "401", "Unauthorized" )
        globalResponse( "404", "Not Found" )
        globalResponse( "500", "Server Error" )
        
        // Define resources
        defineUsers()
        defineProducts()
    }
    
    function defineUsers() {
        // Resource group
        resource(
            resource = "/api/users",
            description = "User management endpoints"
        )
        
        // GET /api/users - List users
        route(
            pattern = "/api/users",
            handler = "api.users",
            action = "index",
            description = "Get list of all users",
            methods = "GET"
        )
        .param(
            name = "page",
            type = "numeric",
            required = false,
            default = 1,
            description = "Page number for pagination"
        )
        .param(
            name = "pageSize",
            type = "numeric",
            required = false,
            default = 20,
            description = "Number of results per page"
        )
        .response(
            status = "200",
            description = "Successfully retrieved users",
            schema = [
                {
                    "id" : "UUID",
                    "firstName" : "string",
                    "lastName" : "string",
                    "email" : "string",
                    "createdDate" : "date"
                }
            ]
        )
        
        // POST /api/users - Create user
        route(
            pattern = "/api/users",
            handler = "api.users",
            action = "create",
            description = "Create a new user",
            methods = "POST"
        )
        .param(
            name = "firstName",
            type = "string",
            required = true,
            description = "User's first name"
        )
        .param(
            name = "lastName",
            type = "string",
            required = true,
            description = "User's last name"
        )
        .param(
            name = "email",
            type = "string",
            required = true,
            description = "User's email address"
        )
        .response(
            status = "201",
            description = "User created successfully",
            schema = {
                "id" : "UUID",
                "message" : "User created successfully"
            }
        )
        
        // GET /api/users/:id - Get user
        route(
            pattern = "/api/users/:id",
            handler = "api.users",
            action = "show",
            description = "Get a specific user by ID",
            methods = "GET"
        )
        .pathParam(
            name = "id",
            type = "UUID",
            required = true,
            description = "User ID"
        )
        .response(
            status = "200",
            description = "User details",
            schema = {
                "id" : "UUID",
                "firstName" : "string",
                "lastName" : "string",
                "email" : "string",
                "role" : {
                    "id" : "UUID",
                    "name" : "string"
                },
                "createdDate" : "date",
                "modifiedDate" : "date"
            }
        )
        
        // PUT /api/users/:id - Update user
        route(
            pattern = "/api/users/:id",
            handler = "api.users",
            action = "update",
            description = "Update an existing user",
            methods = "PUT"
        )
        .pathParam(
            name = "id",
            type = "UUID",
            required = true
        )
        .param( name = "firstName", type = "string" )
        .param( name = "lastName", type = "string" )
        .param( name = "email", type = "string" )
        .response( status = "200", description = "User updated" )
        
        // DELETE /api/users/:id - Delete user
        route(
            pattern = "/api/users/:id",
            handler = "api.users",
            action = "delete",
            description = "Delete a user",
            methods = "DELETE"
        )
        .pathParam( name = "id", type = "UUID", required = true )
        .response( status = "204", description = "User deleted" )
    }
}
```

## RelaxDSL Methods

### API Metadata

```javascript
this.relax = {
    title = "API Title",
    description = "API description",
    version = "1.0.0",
    entryPoint = "https://api.example.com", // Optional base URL
    termsOfService = "URL",
    contact = {
        name = "Name",
        email = "email@example.com",
        url = "https://example.com"
    },
    license = {
        name = "Apache 2.0",
        url = "https://www.apache.org/licenses/LICENSE-2.0"
    }
}
```

### Resource Groups

```javascript
resource(
    resource = "/api/users",
    description = "User endpoints",
    tags = [ "users", "authentication" ]
)
```

### Route Definitions

```javascript
route(
    pattern = "/api/users/:id",
    handler = "api.users",
    action = "show",
    description = "Get user by ID",
    methods = "GET", // GET, POST, PUT, DELETE, PATCH
    defaultFormat = "json"
)
```

### Parameters

```javascript
// Query parameters
.param(
    name = "filter",
    type = "string", // string, numeric, boolean, date, UUID, etc.
    required = false,
    default = "",
    description = "Filter criteria"
)

// Path parameters
.pathParam(
    name = "id",
    type = "UUID",
    required = true,
    description = "Resource ID"
)

// Header parameters
.headerParam(
    name = "X-API-Key",
    type = "string",
    required = true,
    description = "API authentication key"
)
```

### Responses

```javascript
.response(
    status = "200",
    description = "Success response",
    schema = {
        "id" : "UUID",
        "name" : "string",
        "items" : [ "array of objects" ]
    }
)

// Global responses (defined once, applied to all)
globalResponse( "400", "Bad Request" )
globalResponse( "401", "Unauthorized" )
globalResponse( "500", "Internal Server Error" )
```

### Authentication

```javascript
// API Key authentication
.security(
    name = "api_key",
    type = "apiKey",
    in = "header", // header, query, cookie
    paramName = "X-API-Key"
)

// Bearer token
.security(
    name = "bearer",
    type = "http",
    scheme = "bearer",
    bearerFormat = "JWT"
)

// OAuth2
.security(
    name = "oauth2",
    type = "oauth2",
    flows = {
        "authorizationCode" : {
            "authorizationUrl" : "https://api.example.com/oauth/authorize",
            "tokenUrl" : "https://api.example.com/oauth/token",
            "scopes" : {
                "read" : "Read access",
                "write" : "Write access"
            }
        }
    }
)
```

## Using the Relax Interface

### Accessing Relax

Navigate to:
```
http://localhost:{port}/relax
```

### Interface Features

**Documentation View:**
- Browse all defined endpoints
- View parameter requirements
- See response schemas
- Copy example requests

**Testing Console (Relaxer):**
- Select endpoint to test
- Fill in parameters
- Set headers
- Execute request
- View response (formatted JSON/XML)
- See request/response headers
- Track history of test requests

**Export Options:**
- HTML documentation
- PDF documentation
- Swagger/OpenAPI JSON
- Postman collection (via OpenAPI import)

## Best Practices

### API Organization

```javascript
// Organize by resource in separate methods
function configure() {
    defineUsers()
    defineProducts()
    defineOrders()
    defineAuth()
}

function defineUsers() {
    resource( resource = "/api/users", description = "User management" )
    // All user routes
}

function defineProducts() {
    resource( resource = "/api/products", description = "Product catalog" )
    // All product routes
}
```

### Consistent Response Structures

```javascript
// Define global responses
globalResponse( "200", "Success" )
globalResponse( "400", "Bad Request - Invalid input" )
globalResponse( "401", "Unauthorized - Authentication required" )
globalResponse( "403", "Forbidden - Insufficient permissions" )
globalResponse( "404", "Not Found - Resource doesn't exist" )
globalResponse( "500", "Internal Server Error" )

// Use consistent schema patterns
var standardResponse = {
    "data" : {},
    "messages" : [],
    "success" : "boolean"
}

var paginatedResponse = {
    "data" : [],
    "pagination" : {
        "page" : "numeric",
        "pageSize" : "numeric",
        "totalRecords" : "numeric",
        "totalPages" : "numeric"
    }
}
```

### Versioned APIs

```javascript
// v1 API
resource( resource = "/api/v1/users" )
route( pattern = "/api/v1/users", handler = "api.v1.users" )

// v2 API
resource( resource = "/api/v2/users" )
route( pattern = "/api/v2/users", handler = "api.v2.users" )
```

### Parameter Documentation

```javascript
// Be specific and descriptive
.param(
    name = "startDate",
    type = "date",
    required = false,
    default = "today",
    description = "Filter records created on or after this date. Format: YYYY-MM-DD. Defaults to today's date."
)

// Document validation rules
.param(
    name = "email",
    type = "string",
    required = true,
    description = "User email address. Must be valid email format and unique in system."
)
```

### Testing Workflow

1. Define API in RelaxDSL
2. Reinit framework to load changes
3. Open Relax interface
4. Review generated documentation
5. Test each endpoint in Relaxer console
6. Verify responses match schema
7. Export documentation

## Common Patterns

### CRUD Resource

```javascript
function defineResource() {
    resource( resource = "/api/items" )
    
    // List
    route( "/api/items", "api.items", "index", "GET" )
        .param( "page", "numeric", false, 1 )
    
    // Create
    route( "/api/items", "api.items", "create", "POST" )
        .param( "name", "string", true )
    
    // Show
    route( "/api/items/:id", "api.items", "show", "GET" )
        .pathParam( "id", "UUID", true )
    
    // Update
    route( "/api/items/:id", "api.items", "update", "PUT" )
        .pathParam( "id", "UUID", true )
    
    // Delete
    route( "/api/items/:id", "api.items", "delete", "DELETE" )
        .pathParam( "id", "UUID", true )
}
```

### Search Endpoint

```javascript
route(
    pattern = "/api/search",
    handler = "api.search",
    action = "index",
    methods = "GET"
)
.param( "q", "string", true, "", "Search query" )
.param( "type", "string", false, "all", "Filter by type: users, products, orders" )
.param( "page", "numeric", false, 1 )
.param( "limit", "numeric", false, 20 )
```

### File Upload

```javascript
route(
    pattern = "/api/upload",
    handler = "api.files",
    action = "upload",
    methods = "POST"
)
.param( "file", "file", true, "", "File to upload (max 10MB)" )
.param( "description", "string", false )
.response( "201", "File uploaded", { "fileId" : "UUID", "url" : "string" } )
```

## Integration Tips

**With cbSwagger:**
- Relax can export OpenAPI/Swagger format
- Use for Swagger UI integration

**With API Development:**
- Document BEFORE building handlers
- Use Relax tests during development
- Export docs for team reference

**With Client Teams:**
- Export HTML or PDF documentation
- Share Relax URL for testing
- Use as API contract

**With Testing:**
- Use Relax tests to verify API works
- Save test cases in history
- Document expected responses

## Troubleshooting

**API Not Loading:**
- Check `APILocation` setting
- Verify API CFC extends proper class
- Check for syntax errors in RelaxDSL
- Reinit framework

**Routes Not Working:**
- Verify routes defined in ColdBox Router.cfc
- Check handler and action exist
- Test route in Route Visualizer

**Export Not Working:**
- Check module installation complete
- Verify write permissions
- Check ColdFusion PDF services (for PDF export)

## Module Information

- **Repository:** github.com/coldbox-modules/relax
- **Documentation:** relax.ortusbooks.com
- **Issues:** ortussolutions.atlassian.net/projects/RELAX/issues
- **ForgeBox:** forgebox.io/view/relax
- **Requirements:** Lucee 5+, ColdFusion 2016+
