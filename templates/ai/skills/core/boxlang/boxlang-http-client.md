---
name: BoxLang HTTP Client
description: Comprehensive guide to making HTTP/S requests with BoxLang's fluent http() BIF, including REST APIs, request configuration, response handling, streaming, and async execution
category: boxlang
priority: high
triggers:
  - http
  - http request
  - REST API
  - API call
  - http()
  - GET POST PUT DELETE
  - REST client
  - API client
  - HTTP client
  - web service
  - API integration
---

# BoxLang HTTP Client

## Overview

BoxLang 1.8.0+ provides a modern, fluent `http()` BIF for making HTTP/S requests programmatically. The fluent API offers chainable methods, automatic response transformers, streaming support, async execution, and comprehensive configuration options for building REST API clients and web service integrations.

## Core Concepts

### Fluent API Benefits

- **Chainable Methods**: Readable, method-chaining syntax
- **Intellisense-Friendly**: IDE autocomplete support
- **Response Transformers**: Auto-parse JSON, XML, text
- **Streaming Support**: Server-Sent Events (SSE) and chunked responses
- **Async Execution**: BoxFuture integration for non-blocking requests
- **Conditional Building**: `when()`, `ifNull()`, `ifNotNull()` for dynamic requests

### HTTP vs bx:http Component

```boxlang
// Modern BIF approach - preferred for programmatic code
result = http( "https://api.example.com/users" )
    .header( "Accept", "application/json" )
    .timeout( 30 )
    .asJSON()
    .send()

// Component approach - best for templates
bx:http url="https://api.example.com/users" result="result" {
    bx:httpparam name="Accept" type="header" value="application/json"
}
```

**When to use which:**
- `http() BIF`: Services, APIs, programmatic code, fluent chaining
- `bx:http Component`: Templates, views, declarative configurations

## Basic HTTP Requests

### Simple GET Request

```boxlang
// Minimal GET request
result = http( "https://api.example.com/users" ).send()

// Access response
println( "Status: #result.statusCode#" )
println( "Body: #result.fileContent#" )
println( "Headers: #result.responseHeader#" )
```

### HTTP Methods

```boxlang
// GET request
result = http( url ).get().send()

// POST request
result = http( url ).post().send()

// PUT request
result = http( url ).put().send()

// DELETE request
result = http( url ).delete().send()

// PATCH request
result = http( url ).patch().send()

// HEAD request
result = http( url ).head().send()

// OPTIONS request
result = http( url ).options().send()

// TRACE request
result = http( url ).trace().send()
```

### URL Parameters

```boxlang
// Add query parameters
result = http( "https://api.example.com/search" )
    .urlParam( "q", "boxlang" )
    .urlParam( "limit", 10 )
    .urlParam( "offset", 0 )
    .send()
// Requests: https://api.example.com/search?q=boxlang&limit=10&offset=0

// Multiple parameters at once
result = http( "https://api.example.com/search" )
    .urlParams( {
        q: "boxlang",
        limit: 10,
        offset: 0,
        sort: "name"
    } )
    .send()
```

## Request Configuration

### Headers

```boxlang
// Single header
result = http( url )
    .header( "Authorization", "Bearer #token#" )
    .header( "Accept", "application/json" )
    .header( "Content-Type", "application/json" )
    .send()

// Multiple headers
result = http( url )
    .headers( {
        "Authorization": "Bearer #token#",
        "Accept": "application/json",
        "X-API-Version": "2.0",
        "X-Request-ID": createUUID()
    } )
    .send()

// Common header shortcuts
result = http( url )
    .userAgent( "MyApp/1.0" )
    .contentType( "application/json" )
    .accept( "application/json" )
    .send()
```

### Request Body

```boxlang
// JSON body (auto-serialized)
result = http( url )
    .post()
    .body( {
        name: "John Doe",
        email: "john@example.com",
        age: 30
    } )
    .send()

// String body
result = http( url )
    .post()
    .body( "Raw text body" )
    .send()

// JSON string body
result = http( url )
    .post()
    .jsonBody( '{"name":"John","email":"john@example.com"}' )
    .send()

// XML body
xmlContent = '<user><name>John</name><email>john@example.com</email></user>'
result = http( url )
    .post()
    .contentType( "application/xml" )
    .body( xmlContent )
    .send()
```

### Timeouts

```boxlang
// Connection timeout (seconds)
result = http( url )
    .connectionTimeout( 30 )
    .send()

// Combined timeout configuration
result = http( url )
    .timeout( 30 ) // Overall request timeout
    .connectionTimeout( 10 ) // Connection establishment timeout
    .send()
```

## Response Handling

### Response Structure

```boxlang
result = http( url ).send()

// Standard response properties
statusCode = result.statusCode // HTTP status code (200, 404, etc.)
body = result.fileContent // Response body as string
headers = result.responseHeader // Response headers as struct
cookies = result.cookies // Response cookies
mimeType = result.mimeType // Content-Type
charset = result.charset // Character encoding
```

### Automatic Response Transformation

```boxlang
// Auto-parse JSON response
users = http( "https://api.example.com/users" )
    .asJSON()
    .send()
// Returns deserialized JSON directly (not result struct)

// Access JSON data directly
println( "First user: #users[1].name#" )

// Auto-parse XML
xmlData = http( "https://api.example.com/data.xml" )
    .asXML()
    .send()

// Plain text
textContent = http( "https://example.com/document.txt" )
    .asText()
    .send()
```

### Custom Response Transformation

```boxlang
// Transform response with custom function
users = http( "https://api.example.com/users" )
    .transform( ( result ) => {
        // Custom transformation logic
        data = deserializeJSON( result.fileContent )
        
        // Filter and transform data
        return data.users.filter( ( user ) => user.active )
    } )
    .send()
// Returns transformed result directly
```

### Error Handling

```boxlang
// Automatic error throwing on HTTP errors
try {
    result = http( url )
        .throwOnError( true ) // Throws on 4xx/5xx status codes
        .send()
} catch ( any e ) {
    logger.error( "HTTP request failed: #e.message#" )
}

// Manual error checking
result = http( url ).send()

if ( result.statusCode >= 400 ) {
    logger.error( "Request failed with status: #result.statusCode#" )
    logger.error( "Response: #result.fileContent#" )
}

// Handle specific status codes
switch ( result.statusCode ) {
    case 401:
        // Unauthorized - refresh token
        break
    case 404:
        // Not found
        break
    case 429:
        // Rate limited - back off
        break
    case 500:
        // Server error - retry
        break
}
```

## REST API Patterns

### Complete REST Client Example

```boxlang
/**
 * GitHubAPIClient.bx
 * REST API client for GitHub API
 */
class {
    property name="baseURL" default="https://api.github.com"
    property name="token"
    property name="logger"
    
    function init( token ) {
        variables.token = token
        variables.logger = getLogger()
        return this
    }
    
    /**
     * Get repository information
     */
    function getRepository( owner, repo ) {
        url = "#variables.baseURL#/repos/#owner#/#repo#"
        
        return http( url )
            .header( "Authorization", "Bearer #variables.token#" )
            .header( "Accept", "application/vnd.github.v3+json" )
            .userAgent( "BoxLang-GitHubClient/1.0" )
            .timeout( 30 )
            .asJSON()
            .throwOnError( true )
            .send()
    }
    
    /**
     * List repository issues
     */
    function listIssues( owner, repo, state = "open" ) {
        url = "#variables.baseURL#/repos/#owner#/#repo#/issues"
        
        return http( url )
            .header( "Authorization", "Bearer #variables.token#" )
            .header( "Accept", "application/vnd.github.v3+json" )
            .urlParams( {
                state: state,
                per_page: 100
            } )
            .asJSON()
            .send()
    }
    
    /**
     * Create new issue
     */
    function createIssue( owner, repo, title, body = "" ) {
        url = "#variables.baseURL#/repos/#owner#/#repo#/issues"
        
        return http( url )
            .post()
            .header( "Authorization", "Bearer #variables.token#" )
            .header( "Accept", "application/vnd.github.v3+json" )
            .contentType( "application/json" )
            .body( {
                title: title,
                body: body
            } )
            .asJSON()
            .throwOnError( true )
            .send()
    }
    
    /**
     * Upload file to repository
     */
    function uploadFile( owner, repo, path, content, message ) {
        url = "#variables.baseURL#/repos/#owner#/#repo#/contents/#path#"
        
        // Encode content as base64
        encodedContent = toBase64( content )
        
        return http( url )
            .put()
            .header( "Authorization", "Bearer #variables.token#" )
            .header( "Accept", "application/vnd.github.v3+json" )
            .body( {
                message: message,
                content: encodedContent
            } )
            .asJSON()
            .send()
    }
}

// Usage
client = new GitHubAPIClient( "ghp_token123" )
repo = client.getRepository( "ortus-solutions", "boxlang" )
println( "Stars: #repo.stargazers_count#" )

issues = client.listIssues( "ortus-solutions", "boxlang", "open" )
println( "Open issues: #arrayLen( issues )#" )
```

### CRUD Operations

```boxlang
/**
 * UserAPIService.bx
 * CRUD operations for user API
 */
class {
    property name="baseURL"
    property name="apiKey"
    
    function init( baseURL, apiKey ) {
        variables.baseURL = baseURL
        variables.apiKey = apiKey
        return this
    }
    
    // CREATE - POST
    function create( data ) {
        return http( "#variables.baseURL#/users" )
            .post()
            .header( "X-API-Key", variables.apiKey )
            .contentType( "application/json" )
            .body( data )
            .asJSON()
            .throwOnError( true )
            .send()
    }
    
    // READ - GET
    function read( id ) {
        return http( "#variables.baseURL#/users/#id#" )
            .get()
            .header( "X-API-Key", variables.apiKey )
            .asJSON()
            .throwOnError( true )
            .send()
    }
    
    // UPDATE - PUT
    function update( id, data ) {
        return http( "#variables.baseURL#/users/#id#" )
            .put()
            .header( "X-API-Key", variables.apiKey )
            .contentType( "application/json" )
            .body( data )
            .asJSON()
            .throwOnError( true )
            .send()
    }
    
    // DELETE - DELETE
    function delete( id ) {
        return http( "#variables.baseURL#/users/#id#" )
            .delete()
            .header( "X-API-Key", variables.apiKey )
            .throwOnError( true )
            .send()
    }
    
    // LIST - GET with filters
    function list( filters = {} ) {
        return http( "#variables.baseURL#/users" )
            .get()
            .header( "X-API-Key", variables.apiKey )
            .urlParams( filters )
            .asJSON()
            .send()
    }
}
```

## Advanced Features

### File Upload (Multipart)

```boxlang
// Upload file with multipart form data
result = http( "https://api.example.com/upload" )
    .post()
    .multipart() // Enable multipart mode
    .file( "document", "/path/to/file.pdf" )
    .formField( "description", "Important document" )
    .formField( "category", "reports" )
    .send()

// Multiple file upload
result = http( url )
    .post()
    .multipart()
    .file( "file1", "/path/to/file1.pdf" )
    .file( "file2", "/path/to/file2.pdf" )
    .file( "image", "/path/to/image.jpg" )
    .formField( "title", "Multiple files" )
    .send()
```

### Streaming and Chunking

```boxlang
// Stream large response with chunking
http( "https://api.example.com/large-data" )
    .get()
    .onChunk( ( chunk ) => {
        // Process each chunk as it arrives
        println( "Received chunk: #chunk.data.len()# bytes" )
        processData( chunk.data )
    } )
    .send()

// Server-Sent Events (SSE)
http( "https://api.example.com/events" )
    .get()
    .header( "Accept", "text/event-stream" )
    .onChunk( ( event ) => {
        // Process SSE events in real-time
        println( "Event: #event.event#" )
        println( "Data: #event.data#" )
        println( "ID: #event.id#" )
    } )
    .send()
```

### Callbacks

```boxlang
// Comprehensive callback configuration
http( "https://api.example.com/data" )
    .onRequestStart( ( httpResult, httpClient ) => {
        // Pre-request logic
        logger.debug( "Starting request to #httpClient.getUrl()#" )
        startTime = getTickCount()
    } )
    .onChunk( ( chunk, lastEventId, httpResult ) => {
        // Process streaming data
        processStreamingChunk( chunk )
    } )
    .onComplete( ( httpResult ) => {
        // Success handling
        duration = getTickCount() - startTime
        logger.info( "Request completed in #duration#ms" )
        logger.info( "Status: #httpResult.statusCode#" )
    } )
    .onError( ( error, httpResult ) => {
        // Error handling
        logger.error( "Request failed: #error.message#" )
        notifyOps( error )
    } )
    .send()
```

### Async Execution

```boxlang
// Execute HTTP request async
boxFuture = http( "https://api.example.com/data" )
    .get()
    .sendAsync()

// Continue with other work...
doOtherWork()

// Wait for result when needed
result = boxFuture.get()

// Async with transformation pipeline
userData = http( "https://api.example.com/user/123" )
    .sendAsync()
    .then( result => deserializeJSON( result.fileContent ) )
    .then( data => {
        // Enrich data
        data.fullName = "#data.firstName# #data.lastName#"
        return data
    } )
    .get()
```

### Parallel Requests

```boxlang
// Execute multiple requests in parallel
results = asyncAll( [
    () => http( "https://api1.example.com/data" ).asJSON().send(),
    () => http( "https://api2.example.com/data" ).asJSON().send(),
    () => http( "https://api3.example.com/data" ).asJSON().send()
] ).get()

// Process aggregated results
aggregated = {
    api1: results[1],
    api2: results[2],
    api3: results[3]
}
```

## HTTP/2 and Connection Management

### HTTP Version Configuration

```boxlang
// Use HTTP/2
result = http( url )
    .httpVersion( "HTTP/2" )
    .send()

// HTTP/1.1
result = http( url )
    .httpVersion( "HTTP/1.1" )
    .send()

// Auto-negotiate (default)
result = http( url )
    .send() // Uses HTTP/2 by default with HTTP/1.1 fallback
```

### Connection Pooling

```boxlang
// Connection pooling is automatic and managed by BoxHttpClient
// Reuse clients for best performance

// Create reusable client
client = http( "https://api.example.com" )
    .header( "Authorization", "Bearer #token#" )
    .timeout( 30 )

// Make multiple requests with same client (connection reuse)
for ( i = 1; i <= 100; i++ ) {
    result = client
        .urlParam( "id", i )
        .send()
    processResult( result )
}
```

### Redirects

```boxlang
// Follow redirects (default behavior)
result = http( url )
    .redirect( true )
    .send()

// Disable redirects
result = http( url )
    .redirect( false )
    .send()

// Check if response was redirected
if ( result.statusCode == 302 || result.statusCode == 301 ) {
    location = result.responseHeader[ "Location" ]
    println( "Redirected to: #location#" )
}
```

## Authentication

### Basic Authentication

```boxlang
// HTTP Basic Auth
result = http( url )
    .basicAuth( username, password )
    .send()

// Alternative: Manual Authorization header
credentials = toBase64( "#username#:#password#" )
result = http( url )
    .header( "Authorization", "Basic #credentials#" )
    .send()
```

### Bearer Token

```boxlang
// Bearer token authentication
result = http( url )
    .bearerToken( token )
    .send()

// Alternative: Manual Authorization header
result = http( url )
    .header( "Authorization", "Bearer #token#" )
    .send()
```

### API Key Authentication

```boxlang
// API key in header
result = http( url )
    .header( "X-API-Key", apiKey )
    .send()

// API key in query parameter
result = http( url )
    .urlParam( "api_key", apiKey )
    .send()
```

### OAuth2 Example

```boxlang
/**
 * OAuth2 client with token refresh
 */
class OAuth2Client {
    property name="baseURL"
    property name="clientId"
    property name="clientSecret"
    property name="accessToken"
    property name="refreshToken"
    
    function init( baseURL, clientId, clientSecret ) {
        variables.baseURL = baseURL
        variables.clientId = clientId
        variables.clientSecret = clientSecret
        return this
    }
    
    function request( path, method = "GET", body = {} ) {
        // Ensure valid token
        ensureValidToken()
        
        // Make authenticated request
        try {
            return http( "#variables.baseURL##path#" )
                .method( method )
                .header( "Authorization", "Bearer #variables.accessToken#" )
                .body( body )
                .asJSON()
                .send()
        } catch ( any e ) {
            // If 401, try refreshing token
            if ( e.message contains "401" ) {
                refreshAccessToken()
                // Retry request
                return request( path, method, body )
            }
            throw e
        }
    }
    
    private function ensureValidToken() {
        if ( isTokenExpired() ) {
            refreshAccessToken()
        }
    }
    
    private function refreshAccessToken() {
        result = http( "#variables.baseURL#/oauth/token" )
            .post()
            .body( {
                grant_type: "refresh_token",
                refresh_token: variables.refreshToken,
                client_id: variables.clientId,
                client_secret: variables.clientSecret
            } )
            .asJSON()
            .send()
        
        variables.accessToken = result.access_token
        variables.refreshToken = result.refresh_token
    }
}
```

## Proxy Configuration

### HTTP/HTTPS Proxy

```boxlang
// Basic proxy
result = http( url )
    .proxyServer( "proxy.company.com", 8080 )
    .send()

// Proxy with authentication
result = http( url )
    .proxyServer( "proxy.company.com", 8080 )
    .proxyUser( "proxyuser" )
    .proxyPassword( "proxypass" )
    .send()
```

## SSL/TLS Configuration

### Client Certificates

```boxlang
// Client certificate authentication
result = http( url )
    .clientCert( "/path/to/cert.p12", "certPassword" )
    .send()

// PEM format certificates
result = http( url )
    .clientCert( "/path/to/cert.pem", "/path/to/key.pem", "keyPassword" )
    .send()
```

### SSL Verification

```boxlang
// Disable SSL verification (NOT recommended for production)
result = http( url )
    .verifySSL( false )
    .send()

// Custom trust store
result = http( url )
    .trustStore( "/path/to/truststore.jks", "password" )
    .send()
```

## Conditional Request Building

### Dynamic Request Construction

```boxlang
// Conditional header addition
result = http( url )
    .when( userIsAuthenticated, ( request ) => {
        request.header( "Authorization", "Bearer #token#" )
    } )
    .send()

// Multiple conditional additions
result = http( url )
    .when( includeAuth, ( req ) => req.bearerToken( token ) )
    .when( useCache, ( req ) => req.header( "Cache-Control", "max-age=3600" ) )
    .when( isDebug, ( req ) => req.header( "X-Debug", "true" ) )
    .send()

// Null-safe operations
result = http( url )
    .ifNotNull( apiKey, ( req, key ) => req.header( "X-API-Key", key ) )
    .ifNotNull( userId, ( req, id ) => req.urlParam( "user_id", id ) )
    .send()
```

## Testing HTTP Clients

### Mocking HTTP Responses

```boxlang
/**
 * APIServiceSpec.bx
 */
component extends="testbox.system.BaseSpec" {
    
    function beforeAll() {
        mockHTTPService = createMock( "HTTPService" )
        apiService = new APIService()
        apiService.httpService = mockHTTPService
    }
    
    function run() {
        describe( "API Service", () => {
            
            it( "should fetch user data", () => {
                // Mock HTTP response
                mockHTTPService
                    .$( "get" )
                    .$args( "https://api.example.com/users/123" )
                    .$results( {
                        statusCode: 200,
                        fileContent: '{"id":123,"name":"John"}'
                    } )
                
                user = apiService.getUser( 123 )
                
                expect( user.id ).toBe( 123 )
                expect( user.name ).toBe( "John" )
            } )
            
            it( "should handle HTTP errors", () => {
                mockHTTPService
                    .$( "get" )
                    .$throws( 
                        type = "HTTPException",
                        message = "404 Not Found"
                    )
                
                expect( () => apiService.getUser( 999 ) )
                    .toThrow( "HTTPException" )
            } )
        } )
    }
}
```

## Best Practices

### Design Guidelines

1. **Reuse Clients**: Create client instances with common configuration
2. **Set Timeouts**: Always configure appropriate timeouts
3. **Error Handling**: Use `throwOnError()` or manual checks
4. **Logging**: Log requests for debugging and monitoring
5. **Async for I/O**: Use `sendAsync()` for non-blocking requests
6. **Connection Pooling**: Reuse HTTP clients for connection pooling
7. **Secure Credentials**: Never hardcode API keys or tokens
8. **Rate Limiting**: Implement client-side rate limiting for APIs
9. **Retry Logic**: Implement retry with exponential backoff
10. **Response Validation**: Always validate response data

### Performance Optimization

```boxlang
// ✅ Create reusable client with common config
apiClient = http( "https://api.example.com" )
    .header( "Authorization", "Bearer #token#" )
    .timeout( 30 )
    .asJSON()

// Make multiple requests efficiently
users = apiClient.urlParam( "endpoint", "users" ).send()
orders = apiClient.urlParam( "endpoint", "orders" ).send()

// ✅ Use async for parallel requests
futures = [
    () => http( url1 ).sendAsync(),
    () => http( url2 ).sendAsync(),
    () => http( url3 ).sendAsync()
]
results = asyncAll( futures ).get()

// ✅ Use HTTP/2 for better performance
result = http( url ).httpVersion( "HTTP/2" ).send()
```

### Error Handling Patterns

```boxlang
/**
 * Robust API client with retry logic
 */
function robustAPICall( url, maxRetries = 3 ) {
    retryCount = 0
    lastError = null
    
    while ( retryCount < maxRetries ) {
        try {
            return http( url )
                .timeout( 30 )
                .throwOnError( true )
                .asJSON()
                .send()
        } catch ( any e ) {
            lastError = e
            retryCount++
            
            if ( retryCount < maxRetries ) {
                // Exponential backoff
                waitTime = ( 2 ^ retryCount ) * 1000
                logger.warn( "Request failed, retrying in #waitTime#ms (attempt #retryCount#)" )
                sleep( waitTime )
            }
        }
    }
    
    // All retries failed
    throw( 
        type = "APIException",
        message = "API call failed after #maxRetries# retries",
        detail = lastError.message
    )
}
```

## Common Pitfalls

### Pitfalls to Avoid

1. **No Timeout**: Always set timeouts to prevent hanging requests
2. **Blocking in Async**: Don't use `.get()` immediately after `sendAsync()`
3. **Hardcoded URLs**: Use configuration for base URLs
4. **Ignored Errors**: Always handle HTTP errors properly
5. **Memory Leaks**: Close connections, clean up resources
6. **SSL Verification Off**: Never disable SSL in production
7. **Excessive Retries**: Implement exponential backoff
8. **Missing Headers**: Always send required headers (Accept, Content-Type)
9. **Large Responses**: Use streaming for large data
10. **No Logging**: Log requests for debugging

### Troubleshooting

```boxlang
// Debug request details
result = http( url )
    .onRequestStart( ( httpResult, httpClient ) => {
        logger.debug( "URL: #httpClient.getUrl()#" )
        logger.debug( "Method: #httpClient.getMethod()#" )
        logger.debug( "Headers: #serializeJSON( httpClient.getHeaders() )#" )
    } )
    .send()

// Log response details
logger.debug( "Status: #result.statusCode#" )
logger.debug( "Response Headers: #serializeJSON( result.responseHeader )#" )
logger.debug( "Body: #result.fileContent#" )

// Check connection issues
try {
    result = http( url ).connectionTimeout( 5 ).send()
} catch ( any e ) {
    if ( e.type == "ConnectException" ) {
        logger.error( "Connection failed - check network/firewall" )
    } else if ( e.type == "TimeoutException" ) {
        logger.error( "Connection timeout - server not responding" )
    }
}
```

## Related Skills

- [BoxLang SOAP Client](boxlang-soap-client.md) - SOAP web services integration
- [BoxLang Futures](boxlang-futures.md) - Async programming with BoxFutures
- [ColdBox REST API Development](../coldbox/rest-api-development.md) - Building REST APIs

## References

- [BoxLang HTTP Calls](https://boxlang.ortusbooks.com/boxlang-framework/http-calls)
- [BoxLang http() BIF](https://boxlang.ortusbooks.com/boxlang-language/reference/built-in-functions/net/http)
- [BoxLang 1.8.0 Release](https://boxlang.ortusbooks.com/readme/release-history/1.8.0)
