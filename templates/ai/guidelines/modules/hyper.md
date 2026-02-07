# Hyper HTTP Client Module Guidelines

## Overview

Hyper is a fluent HTTP client for CFML that provides a chainable interface for building HTTP requests and handling responses. It abstracts the complexity of cfhttp and provides a clean, modern API for making HTTP calls.

## Installation

```bash
box install hyper
```

## Basic Usage

### Injection

```boxlang
// In your component
property name="hyper" inject="HyperBuilder@hyper";
```

### Simple Requests

```boxlang
// GET request
var response = hyper.get( "https://api.github.com/users/lmajano" )

// GET with query params
var response = hyper.get(
    "https://api.example.com/users",
    { status: "active", page: 1 }
)

// POST request
var response = hyper.post(
    "https://api.example.com/users",
    { name: "John Doe", email: "[email protected]" }
)

// PUT request
var response = hyper.put(
    "https://api.example.com/users/1",
    { name: "Jane Doe" }
)

// PATCH request
var response = hyper.patch(
    "https://api.example.com/users/1",
    { email: "[email protected]" }
)

// DELETE request
var response = hyper.delete( "https://api.example.com/users/1" )
```

## Building Requests

### Fluent Interface

```boxlang
var response = hyper.new()
    .setMethod( "POST" )
    .setUrl( "https://api.example.com/users" )
    .withHeaders( {
        "Authorization": "Bearer #token#",
        "Accept": "application/json"
    } )
    .setBody( {
        name: "John Doe",
        email: "[email protected]"
    } )
    .send()
```

### Setting URL

```boxlang
// Full URL
hyper.setUrl( "https://api.example.com/users" )

// Base URL + URI
hyper.setBaseUrl( "https://api.example.com" )
    .setUrl( "/users" )

// With query string
hyper.setUrl( "https://api.example.com/users?status=active" )

// With query params
hyper.setUrl( "https://api.example.com/users" )
    .withQueryParams( { status: "active", page: 1 } )
```

### Headers

```boxlang
// Set single header
hyper.setHeader( "Authorization", "Bearer #token#" )

// Set multiple headers
hyper.withHeaders( {
    "Authorization": "Bearer #token#",
    "Accept": "application/json",
    "X-Custom-Header": "value"
} )

// Accept header shortcut
hyper.accept( "application/json" )

// Content-Type shortcut
hyper.contentType( "application/json" )
```

### Request Body

```boxlang
// JSON body (default)
hyper.asJson()
    .setBody( {
        name: "John",
        email: "[email protected]"
    } )

// Form fields
hyper.asFormFields()
    .setBody( {
        name: "John",
        email: "[email protected]"
    } )

// Multipart form data
hyper.asMultipart()
    .setBody( {
        name: "John",
        avatar: fileReadBinary( avatarPath )
    } )

// XML body
hyper.asXML()
    .setBody( xmlDocument )

// Raw body
hyper.setBody( "raw string content" )
```

## Authentication

### Basic Auth

```boxlang
hyper.withBasicAuth( "username", "password" )
    .get( "https://api.example.com/protected" )
```

### Bearer Token

```boxlang
hyper.withHeaders( {
    "Authorization": "Bearer #accessToken#"
} ).get( "https://api.example.com/data" )
```

### NTLM Auth

```boxlang
hyper.withNTLMAuth(
    username = "user",
    password = "pass",
    domain = "DOMAIN",
    workstation = "WORKSTATION"
).get( "https://api.example.com/data" )
```

### Certificate Auth

```boxlang
hyper.withCertificateAuth(
    certificatePath = expandPath( "/certs/client.p12" ),
    password = "certPassword"
).get( "https://api.example.com/secure" )
```

## Handling Responses

### Response Object

```boxlang
var response = hyper.get( "https://api.example.com/users" )

// Get response data
var data = response.getData()

// Get JSON response
var json = response.json()

// Get status code
var statusCode = response.getStatusCode()

// Check success
if ( response.isSuccess() ) {
    // 2xx status code
}

if ( response.isOk() ) {
    // 200 status code
}

if ( response.isCreated() ) {
    // 201 status code
}

if ( response.isError() ) {
    // 4xx or 5xx status code
}

// Get headers
var headers = response.getHeaders()
var contentType = response.getHeader( "Content-Type" )

// Get status text
var statusText = response.getStatusText()

// Get request that generated this response
var originalRequest = response.getRequest()
```

## Creating HTTP Clients

Pre-configure defaults for reusable clients:

### In WireBox Configuration

```boxlang
// config/WireBox.cfc
component {
    function configure() {
        map( "GitHubClient" )
            .to( "hyper.models.HyperBuilder" )
            .asSingleton()
            .initWith(
                baseUrl = "https://api.github.com",
                headers = {
                    "Authorization": "token #getSystemSetting( 'GITHUB_TOKEN' )#",
                    "Accept": "application/vnd.github.v3+json"
                }
            )
        
        map( "StripeClient" )
            .to( "hyper.models.HyperBuilder" )
            .asSingleton()
            .initWith(
                baseUrl = "https://api.stripe.com/v1",
                username = getSystemSetting( "STRIPE_SECRET_KEY" ),
                password = "" // Basic auth with empty password
            )
    }
}
```

### Using Pre-Configured Clients

```boxlang
component {
    property name="github" inject="GitHubClient";
    property name="stripe" inject="StripeClient";
    
    function getGitHubUser( required string username ) {
        return github.get( "/users/#arguments.username#" ).json()
    }
    
    function createStripeCustomer( required struct data ) {
        return stripe.post( "/customers", arguments.data ).json()
    }
}
```

### Programmatic Client Creation

```boxlang
// Create client with defaults
var apiClient = hyper.new()
    .setBaseUrl( "https://api.example.com" )
    .withHeaders( {
        "Authorization": "Bearer #token#",
        "Accept": "application/json"
    } )
    .asJson()

// Use client for multiple requests
var users = apiClient.get( "/users" ).json()
var user = apiClient.get( "/users/1" ).json()
var newUser = apiClient.post( "/users", { name: "John" } ).json()
```

## Advanced Features

### Retry Logic

```boxlang
var response = hyper.get( "https://api.example.com/data" )
    .retry( 3 ) // Retry up to 3 times on failure
    .send()
```

### Timeout

```boxlang
hyper.setTimeout( 30 ) // 30 seconds
    .get( "https://slow-api.example.com/data" )
```

### Throw On Error

```boxlang
try {
    var response = hyper.throwOnError()
        .get( "https://api.example.com/users" )
} catch ( any e ) {
    // Handle HTTP errors
    log.error( "API call failed: #e.message#" )
}
```

### Redirects

```boxlang
// Follow redirects (default: unlimited)
hyper.setMaximumRedirects( 5 )
    .get( "https://bit.ly/shorturl" )

// Don't follow redirects
hyper.setMaximumRedirects( 0 )
    .get( "https://example.com" )
```

### Cookies

```boxlang
// Send cookies
hyper.withCookies( {
    session_id: "abc123",
    user_prefs: "dark_mode"
} ).get( "https://api.example.com/data" )
```

## Common Patterns

### API Service Wrapper

```boxlang
component singleton {
    property name="hyper" inject="HyperBuilder@hyper";
    property name="apiUrl" inject="coldbox:setting:apiUrl";
    property name="apiKey" inject="coldbox:setting:apiKey";
    
    function init() {
        variables.client = hyper.new()
            .setBaseUrl( variables.apiUrl )
            .withHeaders( {
                "Authorization": "Bearer #variables.apiKey#",
                "Accept": "application/json"
            } )
            .asJson()
            .throwOnError()
        
        return this
    }
    
    function getUsers() {
        return client.get( "/users" ).json()
    }
    
    function getUser( required numeric id ) {
        return client.get( "/users/#arguments.id#" ).json()
    }
    
    function createUser( required struct data ) {
        return client.post( "/users", arguments.data ).json()
    }
    
    function updateUser( required numeric id, required struct data ) {
        return client.put( "/users/#arguments.id#", arguments.data ).json()
    }
    
    function deleteUser( required numeric id ) {
        return client.delete( "/users/#arguments.id#" ).json()
    }
}
```

### OAuth2 Integration

```boxlang
component singleton {
    property name="hyper" inject="HyperBuilder@hyper";
    property name="clientId" inject="coldbox:setting:oauth.clientId";
    property name="clientSecret" inject="coldbox:setting:oauth.clientSecret";
    
    function getAccessToken( required string code ) {
        var response = hyper.post(
            "https://oauth.example.com/token",
            {
                grant_type: "authorization_code",
                code: arguments.code,
                client_id: variables.clientId,
                client_secret: variables.clientSecret,
                redirect_uri: "https://myapp.com/callback"
            }
        )
        
        return response.json().access_token
    }
    
    function makeAuthenticatedRequest( required string token, required string endpoint ) {
        return hyper.new()
            .withHeaders( { "Authorization": "Bearer #arguments.token#" } )
            .get( endpoint )
            .json()
    }
}
```

### File Upload

```boxlang
function uploadFile( required string filePath ) {
    var response = hyper.new()
        .setUrl( "https://api.example.com/upload" )
        .asMultipart()
        .attach( "file", fileReadBinary( arguments.filePath ), "document.pdf" )
        .withHeaders( { "Authorization": "Bearer #token#" } )
        .send()
    
    return response.json()
}
```

### Download File

```boxlang
function downloadFile( required string url, required string savePath ) {
    var response = hyper.get( arguments.url )
    
    if ( response.isSuccess() ) {
        fileWrite( arguments.savePath, response.getData() )
        return true
    }
    
    return false
}
```

### Error Handling

```boxlang
function callExternalAPI( required string endpoint ) {
    try {
        var response = hyper.new()
            .setBaseUrl( "https://api.example.com" )
            .withHeaders( { "Authorization": "Bearer #token#" } )
            .setTimeout( 30 )
            .get( arguments.endpoint )
        
        if ( response.isError() ) {
            log.error( "API returned error: #response.getStatusCode()# - #response.getStatusText()#" )
            throw( 
                type = "APIException",
                message = "API call failed with status #response.getStatusCode()#",
                detail = response.getData()
            )
        }
        
        return response.json()
        
    } catch ( any e ) {
        log.error( "API call exception: #e.message#", e )
        rethrow
    }
}
```

### Pagination

```boxlang
function getAllPages( required string endpoint ) {
    var allData = []
    var page = 1
    var hasMore = true
    
    while ( hasMore ) {
        var response = hyper.get( 
            arguments.endpoint,
            { page: page, per_page: 100 }
        ).json()
        
        allData.append( response.data, true )
        
        hasMore = response.pagination.has_more ?: false
        page++
    }
    
    return allData
}
```

### Request/Response Callbacks

Pre-configured clients can use callbacks:

```boxlang
// In WireBox.cfc
map( "APIClient" )
    .to( "hyper.models.HyperBuilder" )
    .asSingleton()
    .initWith(
        baseUrl = "https://api.example.com",
        requestCallbacks = [
            // Add authentication token to every request
            ( req ) => {
                var auth = wirebox.getInstance( "AuthService" )
                if ( auth.isLoggedIn() ) {
                    req.withHeaders( {
                        "Authorization": "Bearer #auth.getToken()#"
                    } )
                }
            },
            // Log all requests
            ( req ) => {
                var log = wirebox.getInstance( "logbox:logger:api" )
                log.debug( "API Request: #req.getMethod()# #req.getFullUrl()#" )
            }
        ],
        responseCallbacks = [
            // Log all responses
            ( res ) => {
                var log = wirebox.getInstance( "logbox:logger:api" )
                log.debug( "API Response: #res.getStatusCode()# - #res.getRequest().getFullUrl()#" )
            }
        ]
    )
```

## Async Requests

Make asynchronous HTTP requests:

```boxlang
// Single async request
var future = hyper.getAsync( "https://api.example.com/users" )

// Wait for result
var response = future.get()
var data = response.json()

// Multiple parallel requests
var futures = [
    hyper.getAsync( "https://api.example.com/users" ),
    hyper.getAsync( "https://api.example.com/posts" ),
    hyper.getAsync( "https://api.example.com/comments" )
]

// Wait for all
var responses = futures.map( ( f ) => f.get() )
var userData = responses[ 1 ].json()
var postData = responses[ 2 ].json()
var commentData = responses[ 3 ].json()
```

## Testing with Hyper

### Faking Requests

```boxlang
// In your test
beforeEach( () => {
    variables.hyper = createMock( "hyper.models.HyperBuilder" )
    
    // Mock response
    var mockResponse = createStub()
        .$( "json" ).$results( { id: 1, name: "Test User" } )
        .$( "isSuccess" ).$results( true )
        .$( "getStatusCode" ).$results( 200 )
    
    hyper.$( "get" ).$results( mockResponse )
    hyper.$( "post" ).$results( mockResponse )
} )

it( "can fetch users from API", () => {
    var service = new models.UserAPIService( hyper )
    var users = service.getUsers()
    
    expect( hyper.$once( "get" ) ).toBeTrue()
    expect( users ).toBeStruct()
} )
```

## Service Layer Integration

### GitHub API Service

```boxlang
component singleton {
    property name="github" inject="HyperBuilder@hyper";
    property name="token" inject="coldbox:setting:github.token";
    
    function init() {
        variables.client = github.new()
            .setBaseUrl( "https://api.github.com" )
            .withHeaders( {
                "Authorization": "token #variables.token#",
                "Accept": "application/vnd.github.v3+json"
            } )
            .asJson()
        
        return this
    }
    
    function getUser( required string username ) {
        return client.get( "/users/#arguments.username#" ).json()
    }
    
    function getRepos( required string username ) {
        return client.get( "/users/#arguments.username#/repos" ).json()
    }
    
    function createRepo( required struct data ) {
        return client.post( "/user/repos", arguments.data ).json()
    }
}
```

### Stripe API Service

```boxlang
component singleton {
    property name="hyper" inject="HyperBuilder@hyper";
    property name="secretKey" inject="coldbox:setting:stripe.secretKey";
    
    function init() {
        variables.client = hyper.new()
            .setBaseUrl( "https://api.stripe.com/v1" )
            .withBasicAuth( variables.secretKey, "" )
            .asFormFields()
            .throwOnError()
        
        return this
    }
    
    function createCustomer( required struct data ) {
        return client.post( "/customers", arguments.data ).json()
    }
    
    function createCharge( required numeric amount, required string customerId ) {
        return client.post( "/charges", {
            amount: arguments.amount,
            currency: "usd",
            customer: arguments.customerId
        } ).json()
    }
    
    function getCustomer( required string id ) {
        return client.get( "/customers/#arguments.id#" ).json()
    }
}
```

## Best Practices

- **Use pre-configured clients** - Create clients for each external API
- **Set timeouts** - Always set appropriate timeout values
- **Handle errors gracefully** - Check response status before processing
- **Use async for parallel requests** - Improve performance with concurrent calls
- **Log API calls** - Track requests and responses for debugging
- **Secure credentials** - Never hardcode API keys, use environment variables
- **Implement retry logic** - Handle transient failures
- **Cache responses** - Cache expensive API calls when appropriate
- **Use request/response callbacks** - Centralize common logic
- **Test with mocks** - Don't call real APIs in tests

## Documentation

For complete Hyper documentation, advanced features, and HTTP client customization, visit:
https://hyper.ortusbooks.com
