---
name: rest-api-development
description: Build RESTful APIs in ColdBox with proper HTTP methods, validation, error handling, and API best practices
category: coldbox
priority: high
triggers:
  - rest api
  - restful api
  - api development
  - build api
  - create api
---

# REST API Development Implementation Pattern

## When to Use This Skill

Use this skill when building RESTful APIs, creating API endpoints, implementing REST resources, or building backend services for SPAs and mobile apps.

## Core Concepts

REST APIs in ColdBox:
- Use RestHandler base class for API-specific functionality
- Return JSON/XML responses using event.renderData()
- Implement proper HTTP methods (GET, POST, PUT, PATCH, DELETE)
- Return appropriate HTTP status codes
- Handle validation and errors gracefully
- Support authentication and authorization
- Version your APIs for stability

## Resource-Based REST Handler (BoxLang)

```boxlang
/**
 * Users REST API Handler
 * Base Route: /api/v1/users
 */
class api_v1_Users extends coldbox.system.RestHandler {

    @inject
    property name="userService";

    @inject
    property name="validationManager";

    // Configure REST handler
    this.ALLOWED_METHODS = {
        index   : "GET",
        show    : "GET",
        create  : "POST",
        update  : "PUT,PATCH",
        delete  : "DELETE"
    }

    /**
     * GET /api/v1/users
     * List all users with pagination
     */
    function index( event, rc, prc ) {
        var users = userService.list(
            page    = rc.page ?: 1,
            limit   = rc.limit ?: 25,
            sortBy  = rc.sortBy ?: "createdDate",
            sortDir = rc.sortDir ?: "DESC",
            search  = rc.search ?: ""
        )

        event.renderData(
            type = "json",
            data = {
                "data": users.results,
                "pagination": {
                    "page": users.page,
                    "totalPages": users.totalPages,
                    "totalRecords": users.totalRecords,
                    "limit": users.limit
                }
            },
            statusCode = 200
        )
    }

    /**
     * GET /api/v1/users/:id
     * Get single user by ID
     */
    function show( event, rc, prc ) {
        var userId = rc.id ?: 0

        try {
            var user = userService.getById( userId )

            event.renderData(
                type = "json",
                data = { "data": user },
                statusCode = 200
            )
        } catch( EntityNotFoundException e ){
            event.renderData(
                type = "json",
                data = {
                    "error": true,
                    "message": "User not found",
                    "code": "USER_NOT_FOUND"
                },
                statusCode = 404
            )
        }
    }

    /**
     * POST /api/v1/users
     * Create new user
     */
    function create( event, rc, prc ) {
        // Validate input
        var constraints = {
            "firstName": { required: true, type: "string", min: 2, max: 50 },
            "lastName": { required: true, type: "string", min: 2, max: 50 },
            "email": { required: true, type: "email", unique: "User" },
            "password": { required: true, type: "string", min: 8 },
            "role": { required: false, type: "string", inList: "user,admin" }
        }

        var validationResult = validationManager.validate(
            target      = rc,
            constraints = constraints
        )

        if( validationResult.hasErrors() ){
            event.renderData(
                type = "json",
                data = {
                    "error": true,
                    "message": "Validation failed",
                    "errors": validationResult.getAllErrors()
                },
                statusCode = 422
            )
            return
        }

        try {
            var user = userService.create( rc )

            event.renderData(
                type = "json",
                data = {
                    "data": user,
                    "message": "User created successfully"
                },
                statusCode = 201
            )
        } catch( any e ){
            event.renderData(
                type = "json",
                data = {
                    "error": true,
                    "message": "Failed to create user",
                    "code": "CREATE_FAILED"
                },
                statusCode = 500
            )
        }
    }

    /**
     * PUT/PATCH /api/v1/users/:id
     * Update existing user
     */
    function update( event, rc, prc ) {
        var userId = rc.id ?: 0

        // Validate input
        var constraints = {
            "firstName": { required: false, type: "string", min: 2, max: 50 },
            "lastName": { required: false, type: "string", min: 2, max: 50 },
            "email": { required: false, type: "email" },
            "role": { required: false, type: "string", inList: "user,admin" }
        }

        var validationResult = validationManager.validate(
            target      = rc,
            constraints = constraints
        )

        if( validationResult.hasErrors() ){
            event.renderData(
                type = "json",
                data = {
                    "error": true,
                    "message": "Validation failed",
                    "errors": validationResult.getAllErrors()
                },
                statusCode = 422
            )
            return
        }

        try {
            var user = userService.update( userId, rc )

            event.renderData(
                type = "json",
                data = {
                    "data": user,
                    "message": "User updated successfully"
                },
                statusCode = 200
            )
        } catch( EntityNotFoundException e ){
            event.renderData(
                type = "json",
                data = {
                    "error": true,
                    "message": "User not found",
                    "code": "USER_NOT_FOUND"
                },
                statusCode = 404
            )
        }
    }

    /**
     * DELETE /api/v1/users/:id
     * Delete user
     */
    function delete( event, rc, prc ) {
        var userId = rc.id ?: 0

        try {
            userService.delete( userId )

            event.renderData(
                type = "json",
                data = {
                    "message": "User deleted successfully"
                },
                statusCode = 204
            )
        } catch( EntityNotFoundException e ){
            event.renderData(
                type = "json",
                data = {
                    "error": true,
                    "message": "User not found",
                    "code": "USER_NOT_FOUND"
                },
                statusCode = 404
            )
        }
    }
}
```

## REST Handler with Authentication (BoxLang)

```boxlang
class api_v1_Orders extends coldbox.system.RestHandler {

    @inject
    property name="orderService";

    @inject
    property name="jwtService";

    // Secure entire handler
    this.preHandler = "validateToken"

    /**
     * Validate JWT token before any action
     */
    private function validateToken( event, rc, prc, action ) {
        var token = event.getHTTPHeader( "Authorization", "" ).replaceNoCase( "Bearer ", "" )

        if( !len( token ) ){
            event.renderData(
                type = "json",
                data = {
                    "error": true,
                    "message": "Missing authentication token",
                    "code": "MISSING_TOKEN"
                },
                statusCode = 401
            )
            return false
        }

        try {
            prc.user = jwtService.decode( token )
        } catch( any e ){
            event.renderData(
                type = "json",
                data = {
                    "error": true,
                    "message": "Invalid authentication token",
                    "code": "INVALID_TOKEN"
                },
                statusCode = 401
            )
            return false
        }
    }

    function index( event, rc, prc ) {
        // Only return orders for authenticated user
        var orders = orderService.getByUserId( prc.user.id )

        event.renderData(
            type = "json",
            data = { "data": orders },
            statusCode = 200
        )
    }

    function create( event, rc, prc ) {
        // Create order for authenticated user
        rc.userId = prc.user.id
        var order = orderService.create( rc )

        event.renderData(
            type = "json",
            data = { "data": order },
            statusCode = 201
        )
    }
}
```

## REST Router Configuration

```boxlang
// config/Router.cfc
class Router extends coldbox.system.web.routing.Router {

    function configure() {
        setFullRewrites( true )

        route( "/" ).to( "Main.index" )

        // API v1 routes
        group( {
            prefix: "/api/v1",
            handler: "api.v1"
        }, function( options ){

            // Users resource
            resources( "users" )

            // Orders resource (authenticated)
            resources( "orders" )

            // Products with nested reviews
            resources( resource = "products", handler = "Products" )
                .resources( resource = "reviews", handler = "Products.Reviews" )

            // Custom routes
            route( "/auth/login" ).to( "Auth.login" )
            route( "/auth/logout" ).to( "Auth.logout" )
            route( "/auth/refresh" ).to( "Auth.refresh" )

            // Search endpoint
            route( "/search" ).to( "Search.index" )
        })

        // API v2 routes
        group( {
            prefix: "/api/v2",
            handler: "api.v2"
        }, function( options ){
            resources( "users", { only: ["index", "show"] } )
        })
    }
}
```

## Error Response Formatter

```boxlang
class api_Base extends coldbox.system.RestHandler {

    /**
     * Standard error response
     */
    function renderError(
        required string message,
        string code = "",
        numeric statusCode = 500,
        any errors = []
    ){
        event.renderData(
            type = "json",
            data = {
                "error": true,
                "message": arguments.message,
                "code": arguments.code,
                "errors": arguments.errors,
                "timestamp": now()
            },
            statusCode = arguments.statusCode
        )
    }

    /**
     * Standard success response
     */
    function renderSuccess(
        any data = {},
        string message = "",
        numeric statusCode = 200
    ){
        event.renderData(
            type = "json",
            data = {
                "data": arguments.data,
                "message": arguments.message,
                "timestamp": now()
            },
            statusCode = arguments.statusCode
        )
    }
}

// Usage in child handlers
class api_v1_Products extends api_Base {

    function show( event, rc, prc ) {
        try {
            var product = productService.getById( rc.id )
            renderSuccess( data = product )
        } catch( EntityNotFoundException e ){
            renderError(
                message = "Product not found",
                code = "PRODUCT_NOT_FOUND",
                statusCode = 404
            )
        }
    }
}
```

## API Versioning Strategy

### Option 1: URL Versioning (Recommended)

```
/api/v1/users
/api/v2/users
```

```boxlang
// Separate handlers per version
class api_v1_Users extends coldbox.system.RestHandler {
    // v1 implementation
}

class api_v2_Users extends coldbox.system.RestHandler {
    // v2 implementation
}
```

### Option 2: Header Versioning

```
Accept: application/vnd.myapp.v1+json
```

```boxlang
class api_Users extends coldbox.system.RestHandler {

    this.preHandler = "detectVersion"

    private function detectVersion( event, rc, prc ) {
        var accept = event.getHTTPHeader( "Accept", "" )
        prc.apiVersion = accept.find( "v1" ) ? "v1" : "v2"
    }

    function index( event, rc, prc ) {
        if( prc.apiVersion == "v1" ){
            indexV1( event, rc, prc )
        } else {
            indexV2( event, rc, prc )
        }
    }
}
```

## Rate Limiting

```boxlang
class api_v1_Base extends coldbox.system.RestHandler {

    @inject
    property name="rateLimiter";

    this.preHandler = "checkRateLimit"

    private function checkRateLimit( event, rc, prc ) {
        var clientIP = event.getHTTPHeader( "X-Forwarded-For", cgi.remote_addr )

        if( !rateLimiter.check( clientIP, limit = 100, window = 3600 ) ){
            event.renderData(
                type = "json",
                data = {
                    "error": true,
                    "message": "Rate limit exceeded",
                    "code": "RATE_LIMIT_EXCEEDED"
                },
                statusCode = 429
            )
            return false
        }
    }
}
```

## CORS Configuration

```boxlang
// config/ColdBox.cfc
configure() {
    coldbox = {
        // ... other settings
    }

    settings = {
        cors = {
            enabled = true,
            allowOrigins = "*",
            allowMethods = "GET,POST,PUT,PATCH,DELETE,OPTIONS",
            allowHeaders = "Content-Type,Authorization,X-Requested-With",
            allowCredentials = false,
            maxAge = 3600
        }
    }
}

// Interceptor to handle CORS
class CORSInterceptor {

    function preProcess( event, interceptData ) {
        var rc = event.getCollection()

        // Set CORS headers
        event.setHTTPHeader( name = "Access-Control-Allow-Origin", value = "*" )
        event.setHTTPHeader( name = "Access-Control-Allow-Methods", value = "GET,POST,PUT,PATCH,DELETE,OPTIONS" )
        event.setHTTPHeader( name = "Access-Control-Allow-Headers", value = "Content-Type,Authorization" )

        // Handle OPTIONS request
        if( event.getHTTPMethod() == "OPTIONS" ){
            event.renderData( type = "json", data = {}, statusCode = 200 )
        }
    }
}
```

## HTTP Status Codes Reference

```
200 OK              - Successful GET, PUT, PATCH
201 Created         - Successful POST (resource created)
204 No Content      - Successful DELETE
400 Bad Request     - Invalid request format
401 Unauthorized    - Missing or invalid authentication
403 Forbidden       - Authenticated but not authorized
404 Not Found       - Resource doesn't exist
422 Unprocessable   - Validation errors
429 Too Many        - Rate limit exceeded
500 Server Error    - Internal server error
503 Unavailable     - Service temporarily unavailable
```

## Best Practices

1. **Use REST Handler**: Extend `coldbox.system.RestHandler` for REST APIs
2. **Resource-Based URLs**: Use nouns, not verbs (`/users` not `/getUsers`)
3. **Proper HTTP Methods**: GET (read), POST (create), PUT/PATCH (update), DELETE (remove)
4. **Status Codes**: Return appropriate HTTP status codes
5. **Validation**: Always validate input data
6. **Error Handling**: Return consistent error formats
7. **API Versioning**: Version your APIs from day one
8. **Authentication**: Secure your endpoints
9. **Rate Limiting**: Protect against abuse
10. **CORS**: Configure CORS for browser access
11. **Documentation**: Use CBSwagger/OpenAPI for documentation
12. **Pagination**: Implement pagination for list endpoints
13. **Filtering**: Support filtering, sorting, and searching
14. **HATEOAS**: Include links to related resources when appropriate

## Common Pitfalls

1. **Wrong HTTP Methods**: Using POST for everything
2. **Wrong Status Codes**: Returning 200 for errors
3. **Inconsistent Responses**: Different formats per endpoint
4. **No Validation**: Accepting any input
5. **Security Issues**: No authentication or authorization
6. **No Versioning**: Breaking changes affect all clients
7. **No Error Handling**: Exposing stack traces
8. **Poor Documentation**: No API documentation
9. **No Rate Limiting**: Vulnerable to abuse
10. **Ignoring CORS**: Browser apps can't access API

## Testing REST APIs

```boxlang
class UsersAPITest extends coldbox.system.testing.BaseTestCase {

    function beforeAll() {
        super.beforeAll()
        setup()
    }

    function run() {
        describe( "Users REST API", function(){

            it( "should list users", function(){
                var event = GET( "/api/v1/users" )
                expect( event.getStatusCode() ).toBe( 200 )

                var response = deserializeJSON( event.getRenderedContent() )
                expect( response ).toHaveKey( "data" )
                expect( response.data ).toBeArray()
            })

            it( "should get single user", function(){
                var event = GET( "/api/v1/users/1" )
                expect( event.getStatusCode() ).toBe( 200 )

                var response = deserializeJSON( event.getRenderedContent() )
                expect( response.data ).toHaveKey( "id" )
            })

            it( "should create user", function(){
                var event = POST(
                    route = "/api/v1/users",
                    params = {
                        firstName = "John",
                        lastName = "Doe",
                        email = "john@example.com",
                        password = "password123"
                    }
                )
                expect( event.getStatusCode() ).toBe( 201 )

                var response = deserializeJSON( event.getRenderedContent() )
                expect( response.data ).toHaveKey( "id" )
            })

            it( "should validate user input", function(){
                var event = POST(
                    route = "/api/v1/users",
                    params = { firstName = "John" }
                )
                expect( event.getStatusCode() ).toBe( 422 )

                var response = deserializeJSON( event.getRenderedContent() )
                expect( response ).toHaveKey( "errors" )
            })

            it( "should return 404 for missing user", function(){
                var event = GET( "/api/v1/users/999999" )
                expect( event.getStatusCode() ).toBe( 404 )
            })
        })
    }
}
```

## Related Skills

- `handler-development` - Handler patterns
- `routing-development` - Route configuration
- `security-implementation` - API authentication
- `testing-handler` - Testing patterns
- `api-authentication` - JWT and OAuth
