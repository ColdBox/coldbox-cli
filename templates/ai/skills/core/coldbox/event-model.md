---
name: event-model
description: Master the ColdBox request context object for handling requests, responses, and application flow control
category: coldbox
priority: high
triggers:
  - event object
  - request context- event handling
  - request lifecycle
---

# Event Model Implementation Pattern

## When to Use This Skill

Use this skill when working with the ColdBox request context (event object), managing request/response flow, accessing collections, or controlling application execution.

## Core Concepts

The ColdBox Event Object:
- Central hub for the current request
- Provides access to request collection (rc) and private request collection (prc)
- Controls view rendering and data responses
- Manages request metadata and routing information
- Handles redirects and application flow
- Available in all handlers, interceptors, and views

## Event Object Basics (BoxLang)

```boxlang
class Users extends coldbox.system.EventHandler {

    function index( event, rc, prc ) {
        // event = Request context object
        // rc = Request collection (public data from form/URL)
        // prc = Private request collection (app-private data)

        // Get current route information
        var handler = event.getCurrentHandler()     // "Users"
        var action = event.getCurrentAction()       // "index"
        var routedURL = event.getCurrentRoutedURL() // "/users"
        var fullEvent = event.getCurrentEvent()     // "users.index"

        // Get HTTP method
        var method = event.getHTTPMethod()  // GET, POST, PUT, DELETE

        // Check if AJAX request
        if( event.isAjax() ){
            // Handle AJAX request
        }

        // Check if secure request (HTTPS)
        if( event.isSSL() ){
            // Secure connection
        }
    }
}
```

## Request Collection (rc) Usage

```boxlang
class Users extends coldbox.system.EventHandler {

    @inject
    property name="userService";

    function index( event, rc, prc ) {
        // Access URL/form parameters directly from rc
        var page = rc.page ?: 1
        var search = rc.search ?: ""
        var sortBy = rc.sortBy ?: "name"

        // Check if key exists
        if( structKeyExists( rc, "filter" ) ){
            // Apply filter
        }

        // Get value with default
        var limit = event.getValue( "limit", 25 )

        // Get value and cast type
        var id = event.getValue( name="id", defaultValue=0, type="numeric" )

        // Set value in rc
        event.setValue( "processed", true )

        // Bulk set values
        event.setValues({
            page: 1,
            limit: 50,
            sorted: true
        })

        // Remove value from rc
        event.removeValue( "tempData" )

        // Get entire rc as struct
        var requestData = event.getCollection()

        // Replace entire rc
        event.setCollection({
            newData: "value"
        })

        prc.users = userService.list(
            page = page,
            search = search,
            sortBy = sortBy
        )

        event.setView( "users/index" )
    }

    function create( event, rc, prc ) {
        // Form data is automatically in rc
        var userData = {
            firstName: rc.firstName ?: "",
            lastName: rc.lastName ?: "",
            email: rc.email ?: ""
        }

        var user = userService.create( userData )

        relocate( uri = "/users/#user.getId()#" )
    }
}
```

## Private Request Collection (prc) Usage

```boxlang
class Products extends coldbox.system.EventHandler {

    @inject
    property name="productService";

    function index( event, rc, prc ) {
        // Store data for views in prc (not accessible from URL/form)
        prc.products = productService.list()
        prc.categories = productService.getCategories()

        // Set page metadata
        prc.pageTitle = "Products"
        prc.pageDescription = "Browse our product catalog"

        // Store authenticated user
        prc.user = auth().user()

        // Store configuration
        prc.settings = {
            perPage: 25,
            allowFilters: true
        }

        // prc data is accessible in views but NOT from URL parameters
        event.setView( "products/index" )
    }

    function show( event, rc, prc ) {
        var productId = rc.id ?: 0

        // Store data for view
        prc.product = productService.getById( productId )
        prc.relatedProducts = productService.getRelated( productId )

        // Add breadcrumbs
        prc.breadcrumbs = [
            { title: "Home", url: "/" },
            { title: "Products", url: "/products" },
            { title: prc.product.getName(), url: "" }
        ]

        event.setView( "products/show" )
    }
}
```

## View Rendering

```boxlang
class Pages extends coldbox.system.EventHandler {

    function index( event, rc, prc ) {
        prc.pageData = getPageData()

        // Set view
        event.setView( "pages/index" )

        // Set view with layout
        event.setView(
            view = "pages/index",
            layout = "Main"
        )

        // Set view without layout
        event.setView(
            view = "pages/raw",
            nolayout = true
        )

        // Set view from module
        event.setView(
            view = "dashboard/main",
            module = "admin"
        )

        // Set view with arguments
        event.setView(
            view = "widgets/chart",
            args = {
                data: prc.chartData,
                title: "Sales Report"
            }
        )

        // Cache view output
        event.setView(
            view = "pages/cached",
            cache = true,
            cacheTimeout = 60,
            cacheKey = "page-index"
        )
    }

    function dynamicView( event, rc, prc ) {
        // Conditional view selection
        if( event.isAjax() ){
            event.setView( view = "pages/partial", nolayout = true )
        } else if( device.isMobile() ){
            event.setView( view = "pages/mobile", layout = "Mobile" )
        } else {
            event.setView( "pages/index" )
        }
    }

    function setLayout( event, rc, prc ) {
        // Set layout only
        event.setLayout( "Modern" )

        // Set layout from module
        event.setLayout( name = "Dashboard", module = "admin" )

        // Get current layout
        var currentLayout = event.getCurrentLayout()
    }
}
```

## Data Rendering (REST APIs)

```boxlang
class api_Products extends coldbox.system.RestHandler {

    @inject
    property name="productService";

    function index( event, rc, prc ) {
        var products = productService.list()

        // Render JSON
        event.renderData(
            type = "json",
            data = products,
            statusCode = 200
        )

        // Render XML
        event.renderData(
            type = "xml",
            data = products,
            statusCode = 200
        )

        // Render with custom content type
        event.renderData(
            type = "json",
            data = products,
            contentType = "application/vnd.api+json",
            statusCode = 200
        )

        // Render plain text
        event.renderData(
            type = "plain",
            data = "Hello World",
            statusCode = 200
        )

        // Render HTML
        event.renderData(
            type = "html",
            data = "<h1>Welcome</h1>",
            statusCode = 200
        )
    }

    function create( event, rc, prc ) {
        try {
            var product = productService.create( rc )

            event.renderData(
                type = "json",
                data = {
                    success: true,
                    data: product
                },
                statusCode = 201,
                statusText = "Created"
            )
        } catch( ValidationException e ){
            event.renderData(
                type = "json",
                data = {
                    error: true,
                    message: e.message,
                    errors: e.getErrors()
                },
                statusCode = 422,
                statusText = "Unprocessable Entity"
            )
        }
    }
}
```

## Redirects and Flow Control

```boxlang
class Users extends coldbox.system.EventHandler {

    function create( event, rc, prc ) {
        var user = userService.create( rc )

        // Simple relocate to event
        relocate( "users.index" )

        // Relocate with query string
        relocate( event = "users.show", queryString = "id=#user.getId()#" )

        // Relocate to URI
        relocate( uri = "/users/#user.getId()#" )

        // Relocate with status code
        relocate( uri = "/users", statusCode = 301 )

        // Relocate with message
        flash.put( "success", "User created successfully" )
        relocate( "users.index" )

        // Relocate and persist data
        relocate( event = "users.edit", persist = "userForm" )

        // Relocate with SSL
        relocate( event = "secure.payment", ssl = true )
    }

    function delete( event, rc, prc ) {
        userService.delete( rc.id )

        // Relocate with addToken (adds CSRF token to URL)
        relocate(
            event = "users.index",
            addToken = true
        )
    }

    function cancel( event, rc, prc ) {
        // Override event (stops current execution)
        event.overrideEvent( "main.index" )
    }

    function apiError( event, rc, prc ) {
        // Stop execution and return response
        event.renderData(
            type = "json",
            data = { error: "Unauthorized" },
            statusCode = 401
        )

        // No need for return, renderData stops execution
    }
}
```

## HTTP Headers and Metadata

```boxlang
class Downloads extends coldbox.system.EventHandler {

    function file( event, rc, prc ) {
        // Set HTTP header
        event.setHTTPHeader(
            name = "Content-Type",
            value = "application/pdf"
        )

        // Set multiple headers
        event.setHTTPHeader( name = "Cache-Control", value = "no-cache" )
        event.setHTTPHeader( name = "Pragma", value = "no-cache" )

        // Get HTTP header
        var userAgent = event.getHTTPHeader( "User-Agent", "" )
        var authToken = event.getHTTPHeader( "Authorization", "" )
        var apiKey = event.getHTTPHeader( "X-API-Key", "" )

        // Get all headers
        var headers = event.getHTTPHeaders()

        // Set status code
        event.setHTTPStatus( statusCode = 404, statusText = "Not Found" )
    }

    function cors( event, rc, prc ) {
        // Set CORS headers
        event.setHTTPHeader( name = "Access-Control-Allow-Origin", value = "*" )
        event.setHTTPHeader( name = "Access-Control-Allow-Methods", value = "GET,POST,PUT,DELETE" )
        event.setHTTPHeader( name = "Access-Control-Allow-Headers", value = "Content-Type" )
    }
}
```

## Request Information

```boxlang
class Debug extends coldbox.system.EventHandler {

    function requestInfo( event, rc, prc ) {
        prc.info = {
            // Routing
            handler: event.getCurrentHandler(),
            action: event.getCurrentAction(),
            module: event.getCurrentModule(),
            event: event.getCurrentEvent(),
            route: event.getCurrentRoute(),
            routedURL: event.getCurrentRoutedURL(),
            routedNamespace: event.getCurrentRoutedNamespace(),

            // HTTP
            method: event.getHTTPMethod(),
            isAjax: event.isAjax(),
            isSSL: event.isSSL(),
            isProxyRequest: event.isProxyRequest(),

            // Request data
            clientIP: event.getHTTPHeader( "X-Forwarded-For", cgi.remote_addr ),
            userAgent: event.getHTTPHeader( "User-Agent", "" ),
            referer: event.getHTTPHeader( "Referer", "" ),

            // Collections
            rc: event.getCollection(),
            prc: event.getPrivateCollection(),

            // Context
            isEventCacheable: event.isEventCacheable(),
            eventCacheKey: event.getEventCacheKey()
        }

        event.renderData(
            type = "json",
            data = prc.info
        )
    }
}
```

## Event Caching

```boxlang
class Products extends coldbox.system.EventHandler {

    function featured( event, rc, prc ) {
        // Cache this event handler's output
        event.setEventCacheable( true )
        event.setEventCacheTimeout( 60 )  // Cache for 60 minutes
        event.setEventCacheKey( "products-featured" )

        prc.products = productService.getFeatured()
        event.setView( "products/featured" )
    }

    function clearCache( event, rc, prc ) {
        // Clear specific event cache
        event.clearEvent( "products.featured" )

        // Clear all event caches
        event.clearAllEvents()
    }
}
```

## Request Context Decorators

```boxlang
class CustomEventDecorator {

    function configure( event ) {
        // Add custom methods to event object
        event.getCurrentUser = function(){
            return auth().user()
        }

        event.can = function( permission ){
            return auth().can( arguments.permission )
        }

        event.getClientIP = function(){
            return this.getHTTPHeader( "X-Forwarded-For", cgi.remote_addr )
        }
    }
}

// Use in handler
function index( event, rc, prc ) {
    prc.currentUser = event.getCurrentUser()

    if( event.can( "admin.access" ) ){
        // Allow access
    }

    var ip = event.getClientIP()
}
```

## Advanced Event Manipulation

```boxlang
class Advanced extends coldbox.system.EventHandler {

    function parameterBinding( event, rc, prc ) {
        // Event parameter exists
        if( event.valueExists( "id" ) ){
            // Process id
        }

        // Get parameter as specific type
        var id = event.getValue( name="id", defaultValue=0, type="numeric" )
        var active = event.getValue( name="active", defaultValue=false, type="boolean" )

        // Validate parameter
        if( event.getValue( "id", 0 ) <= 0 ){
            flash.put( "error", "Invalid ID" )
            relocate( "main.index" )
        }
    }

    function privateData( event, rc, prc ) {
        // Store private data
        event.setPrivateValue( "internalFlag", true )

        // Get private value
        var flag = event.getPrivateValue( "internalFlag", false )

        // Get entire private collection
        var privateData = event.getPrivateCollection()

        // Set entire private collection
        event.setPrivateCollection({
            user: getCurrentUser(),
            permissions: getPermissions()
        })
    }

    function renderingControl( event, rc, prc ) {
        // Get rendering data
        var renderData = event.getRenderData()

        // Check if NoRender
        if( event.isNoRender() ){
            // Response already rendered
        }

        // Set NoRender (prevent rendering)
        event.noRender()
    }
}
```

## Testing with Event Object

```boxlang
class UsersHandlerTest extends coldbox.system.testing.BaseTestCase {

    function beforeAll() {
        super.beforeAll()
        setup()
    }

    function run() {
        describe( "Users Handler", function(){

            it( "should handle user list request", function(){
                var event = execute(
                    event = "users.index",
                    eventArguments = {
                        page: 2,
                        limit: 50
                    }
                )

                expect( event.getCurrentHandler() ).toBe( "users" )
                expect( event.getCurrentAction() ).toBe( "index" )
                expect( event.getValue( "page" ) ).toBe( 2 )
                expect( prc.users ).toBeArray()
            })

            it( "should redirect after create", function(){
                var event = execute(
                    event = "users.store",
                    eventArguments = {
                        firstName: "John",
                        lastName: "Doe",
                        email: "john@example.com"
                    }
                )

                expect( event.getValue( "relocate_URI", "" ) ).toInclude( "/users/" )
            })

            it( "should return JSON for API request", function(){
                prepareMock( event ).$( "isAjax", true )

                var event = execute( event = "api.users.index" )
                var renderData = event.getRenderData()

                expect( renderData.type ).toBe( "json" )
                expect( renderData.statusCode ).toBe( 200 )
            })
        })
    }
}
```

## Best Practices

1. **Use prc for Views**: Store view data in prc, not rc
2. **Validate Input**: Always validate rc values
3. **Use Defaults**: Provide defaults with getValue()
4. **Type Casting**: Cast types when getting values
5. **Flash Messages**: Use flash scope for user feedback
6. **Named Routes**: Use named routes for redirects
7. **Status Codes**: Return appropriate HTTP status codes
8. **Event Caching**: Cache expensive event handlers
9. **Clean Redirects**: Use relocate() instead of cfLocation
10. **Test Events**: Write tests for event handling

## Common Pitfalls

1. **Modifying rc in Views**: Views should only read, not modify
2. **Missing Validation**: Not validating rc values
3. **Wrong Collection**: Storing view data in rc instead of prc
4. **Direct CGI Access**: Use event methods instead of CGI scope
5. **Not Using Flash**: Flash messages get lost without flash scope
6. **Hardcoded URLs**: Not using event.buildLink() or relocate()
7. **Missing Error Handling**: Not handling invalid input
8. **Over-caching**: Caching dynamic content
9. **Status Code Mistakes**: Using wrong HTTP status codes
10. **Testing Gaps**: Not testing event handler logic

## Related Skills

- `handler-development` - Handler patterns
- `routing-development` - Route configuration
- `view-rendering` - View rendering patterns
- `rest-api-development` - API development
- `interceptor-development` - Interceptor patterns
