---
name: Request Context
description: Deep dive into ColdBox request context (event object), including rc/prc collections, request helpers, response methods, and data flow patterns
category: coldbox
priority: high
triggers:
  - request context
  - event object
  - rc prc
  - request collection
  - private collection
  - event methods
---

# Request Context

## Overview

The Request Context (event object) is the cornerstone of ColdBox applications. It encapsulates the entire HTTP request, provides access to request/private collections, and offers methods for controlling the response. Understanding the request context is essential for building ColdBox applications.

## Core Concepts

### Request Context Object

The event object (`coldbox.system.web.context.RequestContext`) is automatically created for every request and passed to handlers. It provides:

- **Request Collection (rc)**: URL/FORM variables
- **Private Request Collection (prc)**: Internal data not from URL/FORM
- **Methods**: View rendering, redirects, HTTP responses
- **Flash Scope**: Temporary data across redirects

### Data Flow

```
URL/FORM → rc (Request Collection)
Handler Logic → prc (Private Request Collection)
View → Renders data from rc/prc
```

## Request Collection (rc)

### Accessing Request Data

```boxlang
class extends="coldbox.system.EventHandler" {

    function index( event, rc, prc ) {
        // Access URL/FORM variables
        var userId = rc.id ?: 0
        var searchTerm = rc.q ?: ""

        // Check if exists
        if ( structKeyExists( rc, "filter" ) ) {
            var filter = rc.filter
        }

        // Using event methods
        var userId = event.getValue( "id", 0 )
        var searchTerm = event.getValue( "q", "" )

        // Get all values
        var allParams = event.getCollection()

        // Check existence
        if ( event.valueExists( "filter" ) ) {
            var filter = event.getValue( "filter" )
        }
    }
}
```

### Setting Request Values

```boxlang
function update( event, rc, prc ) {
    // Modify rc values
    rc.sanitized = true
    rc.processedDate = now()

    // Using event methods
    event.setValue( "sanitized", true )
    event.setValue( "processedDate", now() )

    // Set multiple values
    event.setValues( {
        sanitized: true,
        processedDate: now()
    } )

    // Remove value
    event.removeValue( "tempData" )
}
```

### Request Collection Scope

```boxlang
function process( event, rc, prc ) {
    // rc is available in:
    // - Handler
    // - Views
    // - Layouts
    // - Any code that receives the event object

    // Example: Passing to service
    var result = userService.search(
        term: rc.q ?: "",
        page: rc.page ?: 1
    )

    prc.results = result
}
```

## Private Request Collection (prc)

### Using Private Collection

```boxlang
function index( event, rc, prc ) {
    // Set private data (not from URL/FORM)
    prc.user = getInstance( "UserService" ).find( rc.id )
    prc.pageTitle = "User Profile"
    prc.breadcrumbs = [ "Home", "Users", "Profile" ]

    // Using event methods
    event.setPrivateValue( "user", user )
    event.setPrivateValue( "pageTitle", "User Profile" )

    // Get private value
    var user = event.getPrivateValue( "user" )

    // With default
    var pageTitle = event.getPrivateValue( "pageTitle", "Default Title" )

    // Get all private values
    var allPrivate = event.getPrivateCollection()
}
```

### Why Use prc?

```boxlang
// ✅ Good: Using prc for computed/fetched data
function show( event, rc, prc ) {
    // URL parameter
    var userId = rc.id

    // Computed/fetched data goes in prc
    prc.user = userService.find( userId )
    prc.posts = postService.getByUser( userId )
    prc.stats = statsService.getUserStats( userId )
}

// ❌ Bad: Putting URL params in prc
function show( event, rc, prc ) {
    prc.id = rc.id  // Unnecessary, already in rc
}

// ✅ Good: Separation of concerns
function process( event, rc, prc ) {
    // Input from user (rc)
    var email = rc.email
    var password = rc.password

    // Processed/computed data (prc)
    prc.user = authService.authenticate( email, password )
    prc.permissions = permissionService.getUserPermissions( prc.user )
}
```

## Event Object Methods

### View and Layout Control

```boxlang
function index( event, rc, prc ) {
    // Set view
    event.setView( "users/index" )

    // Set view with custom layout
    event.setView(
        view: "users/index",
        layout: "Admin"
    )

    // Set view with no layout
    event.setView(
        view: "users/index",
        noLayout: true
    )

    // Set just the layout
    event.setLayout( "Admin" )

    // Override default view (in layout)
    event.getCurrentView()  // Get current view
    event.getCurrentLayout()  // Get current layout
}
```

### View Rendering

```boxlang
function renderPartial( event, rc, prc ) {
    // Render a view and return HTML
    var html = event.renderView( "users/_userCard" )

    // Render with specific data
    var html = event.renderView(
        view: "users/_userCard",
        args: {
            user: prc.user
        }
    )

    // Render with no layout
    var html = event.renderView(
        view: "users/show",
        noLayout: true
    )

    return html
}
```

### Response Control

```boxlang
function api( event, rc, prc ) {
    // Return JSON
    event.renderData(
        type: "json",
        data: { success: true, data: prc.results }
    )

    // Return XML
    event.renderData(
        type: "xml",
        data: prc.results
    )

    // Return with status code
    event.renderData(
        type: "json",
        data: { error: "Not found" },
        statusCode: 404
    )

    // Return plain text
    event.renderData(
        type: "plain",
        data: "Success"
    )

    // Return PDF
    event.renderData(
        type: "pdf",
        data: pdfBinary
    )
}
```

### HTTP Status Codes

```boxlang
function setStatus( event, rc, prc ) {
    // Set status code
    event.setHTTPHeader( statusCode: 201, statusText: "Created" )
    event.setHTTPHeader( statusCode: 404, statusText: "Not Found" )
    event.setHTTPHeader( statusCode: 500, statusText: "Internal Server Error" )

    // Set custom headers
    event.setHTTPHeader( name: "X-Custom-Header", value: "CustomValue" )
    event.setHTTPHeader( name: "Cache-Control", value: "no-cache" )
}
```

### Relocations (Redirects)

```boxlang
function relocate( event, rc, prc ) {
    // Redirect to event
    relocate( "users.index" )

    // Redirect to URL
    relocate( URL: "/users" )

    // Redirect with status code
    relocate( event: "users.show", statusCode: 301 )

    // Redirect with query string
    relocate(
        event: "users.index",
        queryString: "page=2&sort=name"
    )

    // Redirect and persist data
    relocate(
        event: "users.index",
        persist: "userId,message"
    )

    // SSL redirect
    relocate(
        event: "users.index",
        ssl: true
    )
}
```

## Flash Scope

### Using Flash Scope

```boxlang
function save( event, rc, prc ) {
    var user = userService.create( rc )

    // Put data in flash
    flash.put( "notice", "User created successfully" )
    flash.put( "userId", user.id )

    // Redirect (flash data available in next request)
    relocate( "users.index" )
}

function index( event, rc, prc ) {
    // Get flash data
    prc.notice = flash.get( "notice", "" )
    prc.userId = flash.get( "userId", 0 )

    // Check if exists
    if ( flash.exists( "notice" ) ) {
        prc.notice = flash.get( "notice" )
    }

    // Get and remove
    prc.notice = flash.get( "notice" )
    flash.remove( "notice" )

    // Clear all flash
    flash.clearFlash()
}
```

### Flash Persistence with Relocate

```boxlang
function update( event, rc, prc ) {
    userService.update( rc.id, rc )

    // Persist specific rc keys
    relocate(
        event: "users.edit",
        persist: "id"
    )

    // Persist multiple keys
    relocate(
        event: "users.edit",
        persist: "id,message,returnURL"
    )

    // Persist with custom names
    flash.put( "successMessage", "User updated" )
    flash.put( "userId", rc.id )
    relocate( "users.index" )
}
```

## Request Context Helpers

### Route Params

```boxlang
function show( event, rc, prc ) {
    // From route: /users/:id
    var userId = event.getValue( "id", 0 )

    // Get route
    var currentRoute = event.getCurrentRoute()
    var routeName = event.getCurrentRoutedURL()

    // Get matched route
    var route = event.getCurrentRouteMeta()
}
```

### HTTP Information

```boxlang
function checkRequest( event, rc, prc ) {
    // HTTP method
    var method = event.getHTTPMethod()  // GET, POST, PUT, DELETE

    // Check method
    if ( event.isGet() ) { }
    if ( event.isPost() ) { }
    if ( event.isPut() ) { }
    if ( event.isDelete() ) { }

    // AJAX detection
    if ( event.isAjax() ) {
        return event.renderData(
            type: "json",
            data: results
        )
    }

    // SSL detection
    if ( event.isSSL() ) { }

    // HTTP headers
    var authHeader = event.getHTTPHeader( "Authorization", "" )
    var contentType = event.getHTTPHeader( "Content-Type", "" )

    // Remote IP
    var ip = event.getHTTPHeader( "X-Forwarded-For", CGI.REMOTE_ADDR )

    // Referer
    var referer = event.getHTTPReferer()
}
```

### Request Metadata

```boxlang
function metadata( event, rc, prc ) {
    // Current event
    var currentEvent = event.getCurrentEvent()  // "users.show"

    // Current handler
    var handler = event.getCurrentHandler()  // "users"

    // Current action
    var action = event.getCurrentAction()  // "show"

    // Request start time
    var startTime = event.getStartTime()

    // Execution time
    var elapsed = getTickCount() - event.getStartTime()
}
```

## Advanced Patterns

### Request Decoration

```boxlang
/**
 * Application.cfc or Interceptor
 */
function onRequestCapture( event, interceptData ) {
    // Add computed values to rc
    event.setValue( "isLoggedIn", authService.check() )
    event.setValue( "currentUser", authService.user() )

    // Add to prc
    event.setPrivateValue( "breadcrumbs", [] )
    event.setPrivateValue( "pageClass", "" )
}
```

### Input Sanitization

```boxlang
function sanitizeInput( event, rc, prc ) {
    // Sanitize all rc values
    for ( var key in rc ) {
        if ( isSimpleValue( rc[key] ) ) {
            rc[key] = htmlEditFormat( rc[key] )
        }
    }

    // Or use a helper
    rc.email = sanitizeEmail( rc.email ?: "" )
    rc.name = sanitizeName( rc.name ?: "" )
}
```

### Request Validation

```boxlang
function validateRequest( event, rc, prc ) {
    // Required fields
    if ( !event.valueExists( "email" ) || !event.valueExists( "password" ) ) {
        flash.put( "error", "Email and password are required" )
        relocate( "auth.login" )
    }

    // Custom validation
    if ( !isValid( "email", rc.email ) ) {
        flash.put( "error", "Invalid email format" )
        relocate( "auth.login" )
    }
}
```

### Building Response Objects

```boxlang
function apiResponse( event, rc, prc ) {
    // Success response
    var response = {
        success: true,
        data: prc.results,
        meta: {
            page: rc.page ?: 1,
            perPage: rc.perPage ?: 25,
            total: prc.totalCount
        }
    }

    event.renderData(
        type: "json",
        data: response,
        statusCode: 200
    )
}

function errorResponse( event, rc, prc ) {
    // Error response
    var response = {
        success: false,
        error: {
            message: "Resource not found",
            code: "RESOURCE_NOT_FOUND"
        }
    }

    event.renderData(
        type: "json",
        data: response,
        statusCode: 404
    )
}
```

## Best Practices

### Design Guidelines

1. **Use rc for Input**: URL/FORM parameters only
2. **Use prc for Output**: Computed/fetched data
3. **Validate Early**: Check required params at handler start
4. **Sanitize Input**: Clean user input immediately
5. **Flash for Redirects**: Use flash scope for temporary data
6. **Explicit Defaults**: Always provide default values
7. **Type Safety**: Validate data types
8. **Security**: Never trust rc values directly
9. **Separation**: Keep concerns separate (rc vs prc)
10. **Documentation**: Comment complex data flows

### Common Patterns

```boxlang
// ✅ Good: Clear separation
function show( event, rc, prc ) {
    // Input (rc)
    var userId = rc.id ?: 0

    // Processing/Output (prc)
    prc.user = userService.find( userId )
    prc.posts = postService.getByUser( userId )
}

// ✅ Good: Defaults and validation
function search( event, rc, prc ) {
    var query = rc.q ?: ""
    var page = rc.page ?: 1
    var perPage = rc.perPage ?: 25

    // Validate
    if ( page < 1 ) page = 1
    if ( perPage > 100 ) perPage = 100

    prc.results = searchService.search( query, page, perPage )
}

// ✅ Good: Flash for redirects
function save( event, rc, prc ) {
    var user = userService.create( rc )

    flash.put( "success", "User created successfully" )
    flash.put( "userId", user.id )

    relocate( "users.show" )
}
```

## Common Pitfalls

### Pitfalls to Avoid

1. **Mixing rc/prc**: Putting URL params in prc
2. **No Defaults**: Not providing default values
3. **No Validation**: Trusting rc values
4. **Direct Database**: Passing rc directly to DAO
5. **Memory Leaks**: Storing large objects in flash
6. **No Sanitization**: Using rc values without cleaning
7. **Wrong Scope**: Using wrong collection
8. **Flash Overuse**: Putting too much in flash
9. **No Type Checking**: Assuming types
10. **Tight Coupling**: Handler logic dependent on URL structure

### Anti-Patterns

```boxlang
// ❌ Bad: No defaults
var userId = rc.id  // Fails if not provided

// ✅ Good: With default
var userId = rc.id ?: 0

// ❌ Bad: Mixing concerns
prc.id = rc.id  // Unnecessary duplication

// ✅ Good: Separate concerns
var userId = rc.id ?: 0
prc.user = userService.find( userId )

// ❌ Bad: No validation
userService.create( rc )  // Dangerous!

// ✅ Good: Validate first
var data = {
    name: rc.name ?: "",
    email: rc.email ?: ""
}
validateOrFail( data )
userService.create( data )
```

## Related Skills

- [Handler Development](handler-development.md) - Handler patterns
- [REST API Development](rest-api-development.md) - API patterns
- [Event Model](event-model.md) - Event-driven architecture
- [View Rendering](view-rendering.md) - View patterns

## References

- [Request Context](https://coldbox.ortusbooks.com/the-basics/request-context)
- [Event Object](https://coldbox.ortusbooks.com/the-basics/request-context/request-context-methods)
- [Flash Scope](https://coldbox.ortusbooks.com/the-basics/flash-ram)
