---
name: interceptor-development
description: Build ColdBox interceptors for cross-cutting concerns, event listening, and aspect-oriented programming
category: coldbox
priority: medium
triggers:
  - create interceptor
  - build interceptor
  - event listener
  - aop patterns
---

# Interceptor Development Implementation Pattern

## When to Use This Skill

Use this skill when implementing cross-cutting concerns like logging, security, caching, request tracking, or any functionality that needs to execute at specific framework lifecycle points.

## Core Concepts

ColdBox Interceptors:
- Listen to framework and custom interception points
- Implement cross-cutting concerns (logging, security, caching)
- Can modify request/response flow
- Support aspect-oriented programming (AOP)
- Can be chained and ordered by priority
- Registered globally or per-module

## Basic Interceptor Structure (BoxLang)

```boxlang
/**
 * Basic Interceptor
 * Listen to framework events
 */
class BasicInterceptor {

    @inject
    property name="log";

    /**
     * Configure interceptor
     */
    function configure() {
        // Configuration code
    }

    /**
     * Listen to preProcess event
     * Fires before any event execution
     */
    function preProcess( event, interceptData, rc, prc ) {
        log.debug( "Request started: #event.getCurrentEvent()#" )
    }

    /**
     * Listen to postProcess event
     * Fires after event execution completes
     */
    function postProcess( event, interceptData, rc, prc ) {
        log.debug( "Request completed: #event.getCurrentEvent()#" )
    }
}
```

## Security Interceptor (BoxLang)

```boxlang
/**
 * Security Interceptor
 * Check authentication and authorization
 */
class SecurityInterceptor {

    @inject
    property name="authService";

    @inject
    property name="log";

    // Configure interceptor
    function configure() {
        // Define public routes that don't require auth
        variables.publicRoutes = [
            "/",
            "/login",
            "/register",
            "/forgot-password"
        ]
    }

    /**
     * Check security before handler execution
     */
    function preHandler( event, interceptData, rc, prc ) {
        var currentRoute = event.getCurrentRoutedURL()

        // Skip security for public routes
        if( isPublicRoute( currentRoute ) ){
            return
        }

        // Check if user is authenticated
        if( !authService.isAuthenticated() ){
            log.warn( "Unauthorized access attempt: #currentRoute#" )
            flash.put( "error", "Please login to continue" )
            relocate( "security.login" )
        }

        // Check if user has required permissions
        var requiredPermission = getRequiredPermission( event )

        if( len( requiredPermission ) && !authService.can( requiredPermission ) ){
            log.warn( "Forbidden access attempt: #currentRoute# by user: #authService.getUserId()#" )
            flash.put( "error", "Insufficient permissions" )
            relocate( "main.index" )
        }

        // Store user in prc for easy access
        prc.user = authService.getUser()
    }

    /**
     * Check if route is public
     */
    private function isPublicRoute( required string route ) {
        return variables.publicRoutes.find( arguments.route ) > 0
    }

    /**
     * Get required permission from event metadata
     */
    private function getRequiredPermission( required event ) {
        var handler = event.getCurrentHandler()
        var action = event.getCurrentAction()

        // This would check handler metadata for @permission annotation
        // Implementation depends on your security requirements
        return ""
    }
}
```

## Logging Interceptor (BoxLang)

```boxlang
/**
 * Request Logging Interceptor
 * Log detailed request information
 */
class RequestLoggerInterceptor {

    @inject
    property name="log";

    /**
     * Log request start
     */
    function preProcess( event, interceptData, rc, prc ) {
        // Store request start time
        request.startTime = getTickCount()

        var logData = {
            event: event.getCurrentEvent(),
            route: event.getCurrentRoutedURL(),
            method: event.getHTTPMethod(),
            ip: event.getHTTPHeader( "X-Forwarded-For", cgi.remote_addr ),
            userAgent: event.getHTTPHeader( "User-Agent", "" )
        }

        log.info( "Request started", logData )
    }

    /**
     * Log request completion
     */
    function postProcess( event, interceptData, rc, prc ) {
        var duration = getTickCount() - request.startTime

        var logData = {
            event: event.getCurrentEvent(),
            duration: "#duration#ms",
            statusCode: event.getStatusCode()
        }

        if( duration > 1000 ){
            log.warn( "Slow request detected", logData )
        } else {
            log.info( "Request completed", logData )
        }
    }

    /**
     * Log exceptions
     */
    function onException( event, interceptData, rc, prc ) {
        var exception = interceptData.exception

        log.error(
            "Exception in #event.getCurrentEvent()#: #exception.message#",
            exception
        )
    }
}
```

## Caching Interceptor (BoxLang)

```boxlang
/**
 * Response Caching Interceptor
 * Cache handler responses
 */
class CachingInterceptor {

    @inject
    property name="cachebox";

    @inject
    property name="log";

    // Cacheable events
    variables.cacheable = [
        "products.index",
        "products.show",
        "categories.index"
    ]

    /**
     * Check cache before handler execution
     */
    function preHandler( event, interceptData, rc, prc ) {
        var currentEvent = event.getCurrentEvent()

        // Only cache configured events
        if( !variables.cacheable.find( currentEvent ) ){
            return
        }

        var cacheKey = getCacheKey( event, rc )
        var cache = cachebox.getCache( "default" )

        if( cache.lookup( cacheKey ) ){
            var cachedData = cache.get( cacheKey )

            log.debug( "Cache hit: #cacheKey#" )

            // Render cached response and abort handler execution
            event.renderData(
                type = cachedData.type,
                data = cachedData.data
            )

            // Prevent handler from executing
            event.overrideEvent( "" )
        }
    }

    /**
     * Cache response after handler execution
     */
    function postHandler( event, interceptData, rc, prc ) {
        var currentEvent = event.getCurrentEvent()

        if( !variables.cacheable.find( currentEvent ) ){
            return
        }

        var cacheKey = getCacheKey( event, rc )
        var renderedData = event.getRenderData()

        if( !isNull( renderedData ) ){
            cachebox.getCache( "default" ).set(
                cacheKey,
                renderedData,
                60 // Cache for 60 minutes
            )

            log.debug( "Cached response: #cacheKey#" )
        }
    }

    /**
     * Generate cache key from event and request data
     */
    private function getCacheKey( required event, required rc ) {
        var key = event.getCurrentEvent()

        // Include relevant RC keys in cache key
        if( structKeyExists( rc, "id" ) ){
            key &= "-#rc.id#"
        }

        return key
    }
}
```

## CORS Interceptor (BoxLang)

```boxlang
/**
 * CORS Interceptor
 * Handle Cross-Origin Resource Sharing
 */
class CORSInterceptor {

    @inject
    property name="settings";

    /**
     * Add CORS headers to all responses
     */
    function preProcess( event, interceptData, rc, prc ) {
        // Get CORS settings
        var cors = settings.cors ?: {}

        // Set CORS headers
        event.setHTTPHeader(
            name = "Access-Control-Allow-Origin",
            value = cors.allowOrigins ?: "*"
        )

        event.setHTTPHeader(
            name = "Access-Control-Allow-Methods",
            value = cors.allowMethods ?: "GET,POST,PUT,DELETE,OPTIONS"
        )

        event.setHTTPHeader(
            name = "Access-Control-Allow-Headers",
            value = cors.allowHeaders ?: "Content-Type,Authorization"
        )

        if( cors.allowCredentials ?: false ){
            event.setHTTPHeader(
                name = "Access-Control-Allow-Credentials",
                value = "true"
            )
        }

        // Handle OPTIONS preflight request
        if( event.getHTTPMethod() == "OPTIONS" ){
            event.renderData(
                type = "json",
                data = {},
                statusCode = 200
            )
            event.overrideEvent( "" )
        }
    }
}
```

## API Rate Limiting Interceptor (BoxLang)

```boxlang
/**
 * Rate Limiting Interceptor
 * Limit API requests per client
 */
class RateLimitInterceptor {

    @inject
    property name="cachebox";

    /**
     * Check rate limit before request
     */
    function preProcess( event, interceptData, rc, prc ) {
        // Only apply to API routes
        if( !event.getCurrentRoutedURL().startsWith( "/api" ) ){
            return
        }

        var clientIP = event.getHTTPHeader( "X-Forwarded-For", cgi.remote_addr )
        var limit = 100 // requests per window
        var window = 3600 // 1 hour in seconds

        if( !checkRateLimit( clientIP, limit, window ) ){
            event.renderData(
                type = "json",
                data = {
                    error: true,
                    message: "Rate limit exceeded",
                    code: "RATE_LIMIT_EXCEEDED"
                },
                statusCode = 429
            )
            event.overrideEvent( "" )
        }
    }

    /**
     * Check if client has exceeded rate limit
     */
    private function checkRateLimit(
        required string clientId,
        required numeric limit,
        required numeric window
    ){
        var cache = cachebox.getCache( "default" )
        var cacheKey = "ratelimit_#arguments.clientId#"
        var requests = cache.get( cacheKey, 0 )

        if( requests >= arguments.limit ){
            return false
        }

        cache.set( cacheKey, requests + 1, arguments.window )
        return true
    }
}
```

## Custom Interception Points

```boxlang
// In ModuleConfig.cfc or ColdBox.cfc
configure() {
    interceptorSettings = {
        customInterceptionPoints = [
            "onUserLogin",
            "onUserLogout",
            "onOrderCreated",
            "beforePayment",
            "afterPayment"
        ]
    }
}

// Fire custom interception point
function placeOrder( event, rc, prc ) {
    var order = orderService.create( rc )

    // Announce custom event
    announce( "onOrderCreated", { order: order } )

    return order
}

// Listen to custom event in interceptor
class OrderInterceptor {
    function onOrderCreated( event, interceptData ) {
        var order = interceptData.order

        // Send order confirmation email
        mailService.sendOrderConfirmation( order )

        // Create invoice
        invoiceService.create( order )

        // Log order
        log.info( "Order created: #order.getId()#" )
    }
}
```

## Interceptor Registration

### In ColdBox.cfc

```boxlang
configure() {
    coldbox = {
        // ... other settings
    }

    // Register interceptors
    interceptors = [
        { class: "interceptors.SecurityInterceptor" },
        { class: "interceptors.RequestLoggerInterceptor" },
        { class: "interceptors.CachingInterceptor", priority: 1 },
        {
            class: "interceptors.RateLimitInterceptor",
            properties: {
                limit: 100,
                window: 3600
            }
        }
    ]
}
```

### In ModuleConfig.cfc

```boxlang
configure() {
    interceptors = [
        { class: "#moduleMapping#.interceptors.MyInterceptor" }
    ]
}
```

## Framework Interception Points

Common ColdBox interception points:

```boxlang
// Application lifecycle
afterConfigurationLoad()
afterAspectsLoad()
afterCacheElementInsert( eventName, eventArgs )

// Request lifecycle
preProcess( event, interceptData, rc, prc )
preEvent( event, interceptData, rc, prc )
preHandler( event, interceptData, rc, prc )
preLayout( event, interceptData, rc, prc )
preRender( event, interceptData, rc, prc )
postRender( event, interceptData, rc, prc )
postLayout( event, interceptData, rc, prc )
postHandler( event, interceptData, rc, prc )
postEvent( event, interceptData, rc, prc )
postProcess( event, interceptData, rc, prc )

// Error handling
onException( event, interceptData, rc, prc )
onInvalidEvent( event, interceptData, rc, prc )

// Rendering
preViewRender( event, interceptData, rc, prc )
postViewRender( event, interceptData, rc, prc )

// Module events
preModuleLoad( eventArgs )
postModuleLoad( eventArgs )
preModuleUnload( eventArgs )
postModuleUnload( eventArgs )
```

## Best Practices

1. **Keep Interceptors Focused**: One concern per interceptor
2. **Use Proper Point**: Choose the right interception point
3. **Performance**: Interceptors run on every request - keep them fast
4. **Error Handling**: Always handle errors gracefully
5. **Logging**: Log important actions for debugging
6. **Configuration**: Make interceptors configurable
7. **Testing**: Write tests for interceptor logic
8. **Documentation**: Document what interception points you use
9. **Priority**: Use priority to control execution order
10. **Dependency Injection**: Use DI for dependencies

## Common Pitfalls

1. **Heavy Processing**: Slow interceptors affect all requests
2. **Missing Error Handling**: Uncaught errors break the entire request
3. **State Management**: Don't store request state in variables scope
4. **Wrong Interception Point**: Using the wrong lifecycle point
5. **Side Effects**: Modifying data without understanding consequences
6. **Not Skipping Routes**: Applying logic to all routes unnecessarily
7. **Memory Leaks**: Not cleaning up resources
8. **Testing**: Not testing interceptor logic

## Testing Interceptors

```boxlang
class SecurityInterceptorTest extends coldbox.system.testing.BaseTestCase {

    function beforeAll() {
        super.beforeAll()
        setup()

        // Get interceptor instance
        interceptor = getInstance( "SecurityInterceptor" )
    }

    function run() {
        describe( "SecurityInterceptor", function(){

            it( "should allow access to public routes", function(){
                var event = execute( event = "security.login" )
                expect( event.getValue( "relocate_URI", "" ) ).toBe( "" )
            })

            it( "should block unauthenticated users", function(){
                var event = execute( event = "users.index" )
                expect( event.getValue( "relocate_URI", "" ) ).toInclude( "login" )
            })

            it( "should allow authenticated users", function(){
                // Mock authentication
                prepareMock( getInstance( "AuthService" ) )
                    .$( "isAuthenticated", true )
                    .$( "getUser", { id: 1, name: "Test User" } )

                var event = execute( event = "users.index" )
                expect( prc.user ).toBeStruct()
                expect( prc.user.id ).toBe( 1 )
            })
        })
    }
}
```

## Related Skills

- `handler-development` - Handler patterns
- `event-model` - Event-driven architecture
- `security-implementation` - Security patterns
- `cache-integration` - Caching strategies
- `testing-integration` - Integration testing
