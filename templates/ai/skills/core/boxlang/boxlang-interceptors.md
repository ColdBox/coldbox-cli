---
name: BoxLang Interceptors
description: Complete guide to BoxLang interceptor pattern for aspect-oriented programming with announcement points and event-driven architecture
category: boxlang
priority: high
triggers:
  - boxlang intercept
  - interceptor
  - announcement
  - listen
  - aspect oriented
---

# BoxLang Interceptors

## Overview

BoxLang interceptors provide aspect-oriented programming (AOP) capabilities through an event-driven pattern. Interceptors listen to announcement points and execute code before/after operations.

## Core Concepts

### Interceptor Pattern

- **Announcement Points**: Named events
- **Interception Points**: Callback methods
- **State**: Shared data between interceptors
- **Priority**: Execution order
- **Asynchronous**: Background execution

## Basic Interceptors

### Creating Interceptors

```boxlang
/**
 * interceptors/RequestLogger.cfc
 */
class {

    /**
     * Listen to request start
     */
    function onRequestStart( struct interceptData ) {
        var startTime = getTickCount()

        if ( !isDefined( "request" ) ) {
            request = {}
        }

        request.startTime = startTime

        writeLog(
            text: "Request started: #cgi.script_name#",
            type: "information"
        )
    }

    /**
     * Listen to request end
     */
    function onRequestEnd( struct interceptData ) {
        var duration = getTickCount() - request.startTime

        writeLog(
            text: "Request completed in #duration#ms: #cgi.script_name#",
            type: "information"
        )
    }
}
```

### Registering Interceptors

```boxlang
/**
 * Application.bx
 */
class {

    this.name = "MyApp"

    // Register interceptors
    this.interceptors = [
        { class: "interceptors.RequestLogger" },
        { class: "interceptors.SecurityCheck", priority: 1 },
        { class: "interceptors.CacheWarmer", priority: 10 }
    ]

    function onApplicationStart() {
        // Announce application start
        announce( "onApplicationStart", { timestamp: now() } )
    }
}
```

## Announcement System

### Announcing Events

```boxlang
// Basic announcement
announce( "myCustomEvent" )

// With data
announce( "userCreated", {
    userID: newUser.id,
    email: newUser.email,
    timestamp: now()
} )

// Async announcement
announceAsync( "emailQueued", {
    to: user.email,
    subject: "Welcome"
} )
```

### Listening to Events

```boxlang
/**
 * interceptors/UserEvents.cfc
 */
class {

    /**
     * Listen to user creation
     */
    function onUserCreated( interceptData ) {
        var userID = interceptData.userID
        var email = interceptData.email

        // Send welcome email
        mailService.sendWelcome( email )

        // Create user profile
        profileService.create( userID )

        // Log event
        auditService.log( "User created: #email#" )
    }

    /**
     * Listen to user update
     */
    function onUserUpdated( interceptData ) {
        var userID = interceptData.userID

        // Clear user cache
        cacheRemove( "user_#userID#" )

        // Update search index
        searchService.indexUser( userID )
    }
}
```

## Interceptor Patterns

### Pre/Post Operation

```boxlang
/**
 * interceptors/DataSanitizer.cfc
 */
class {

    /**
     * Before save - sanitize data
     */
    function preDataSave( interceptData ) {
        var data = interceptData.data

        // Sanitize HTML
        if ( data.keyExists( "description" ) ) {
            data.description = htmlEditFormat( data.description )
        }

        // Trim strings
        data.each( ( key, value ) => {
            if ( isSimpleValue( value ) ) {
                data[key] = trim( value )
            }
        } )

        // Update intercept data
        interceptData.data = data
    }

    /**
     * After save - clear cache
     */
    function postDataSave( interceptData ) {
        var entityName = interceptData.entityName
        var entityID = interceptData.entityID

        // Clear cache
        cacheRemove( "#entityName#_#entityID#" )
    }
}
```

### Validation Interceptor

```boxlang
/**
 * interceptors/ValidationInterceptor.cfc
 */
class {

    property name="validationService" inject="ValidationService"

    /**
     * Before save - validate data
     */
    function preEntitySave( interceptData ) {
        var entity = interceptData.entity
        var validationResult = validationService.validate( entity )

        if ( !validationResult.hasErrors() ) {
            return
        }

        // Stop processing
        interceptData.abortProcessing = true
        interceptData.errors = validationResult.getAllErrors()

        throw(
            type: "ValidationException",
            message: "Validation failed",
            detail: serializeJSON( validationResult.getAllErrors() )
        )
    }
}
```

### Security Interceptor

```boxlang
/**
 * interceptors/SecurityInterceptor.cfc
 */
class {

    property name="authService" inject="AuthService"

    /**
     * Check authentication before handler execution
     */
    function preHandler( interceptData ) {
        var event = interceptData.event
        var handler = interceptData.handler
        var action = interceptData.action

        // Skip authentication for public handlers
        if ( listFindNoCase( "home,auth", handler ) > 0 ) {
            return
        }

        // Check if user is authenticated
        if ( !authService.isLoggedIn() ) {
            event.overrideEvent( "auth.login" )
            interceptData.abortProcessing = true
        }
    }
}
```

## Advanced Patterns

### Chain of Responsibility

```boxlang
/**
 * Multiple interceptors processing in order
 */

// Interceptor 1 - Log request
class RequestLogger {
    function onRequest( interceptData ) {
        writeLog( "Request: #interceptData.path#" )
    }
}

// Interceptor 2 - Check authentication
class AuthCheck {
    function onRequest( interceptData ) {
        if ( !isAuthenticated() ) {
            interceptData.abortProcessing = true
            interceptData.response = "Unauthorized"
        }
    }
}

// Interceptor 3 - Check rate limiting
class RateLimiter {
    function onRequest( interceptData ) {
        if ( exceedsRateLimit( interceptData.ip ) ) {
            interceptData.abortProcessing = true
            interceptData.response = "Too many requests"
        }
    }
}

// Register with priority
this.interceptors = [
    { class: "RequestLogger", priority: 1 },
    { class: "AuthCheck", priority: 2 },
    { class: "RateLimiter", priority: 3 }
]
```

### Async Processing

```boxlang
/**
 * interceptors/AsyncProcessor.cfc
 */
class {

    /**
     * Process email queue asynchronously
     */
    function onEmailQueued( interceptData ) {
        // Runs in background
        announceAsync( "processEmail", {
            to: interceptData.to,
            subject: interceptData.subject,
            body: interceptData.body
        } )
    }

    /**
     * Process email
     */
    function onProcessEmail( interceptData ) {
        // Actual email sending logic
        mailService.send(
            to: interceptData.to,
            subject: interceptData.subject,
            body: interceptData.body
        )
    }
}
```

### Interceptor State

```boxlang
/**
 * Maintain state across interception points
 */
class {

    variables.requestCount = 0
    variables.cache = {}

    function onRequestStart( interceptData ) {
        variables.requestCount++

        // Store request data
        var requestID = createUUID()
        variables.cache[requestID] = {
            startTime: getTickCount(),
            path: cgi.script_name
        }

        interceptData.requestID = requestID
    }

    function onRequestEnd( interceptData ) {
        var requestID = interceptData.requestID

        if ( variables.cache.keyExists( requestID ) ) {
            var requestData = variables.cache[requestID]
            var duration = getTickCount() - requestData.startTime

            writeLog( "Request #requestID# completed in #duration#ms" )

            // Cleanup
            structDelete( variables.cache, requestID )
        }
    }
}
```

## ColdBox Integration

### ColdBox Interceptors

```boxlang
/**
 * ColdBox-specific interceptor
 */
component extends="coldbox.system.Interceptor" {

    /**
     * After handler execution
     */
    function postHandler( event, interceptData ) {
        var handler = interceptData.handler
        var action = interceptData.action

        // Log handler execution
        log.info(
            "Handler executed: #handler#.#action#",
            {
                event: event.getCurrentEvent(),
                user: auth().user().id
            }
        )
    }

    /**
     * Before view rendering
     */
    function preViewRender( event, interceptData ) {
        var view = interceptData.view

        // Add global view variables
        interceptData.args.append( {
            currentYear: year( now() ),
            appName: getSetting( "appName" )
        } )
    }
}
```

## Best Practices

### Design Guidelines

1. **Single Responsibility**: One concern per interceptor
2. **Non-Blocking**: Keep interceptors fast
3. **Error Handling**: Catch and log errors
4. **Priority**: Order execution appropriately
5. **State Management**: Minimize shared state
6. **Documentation**: Document interception points
7. **Testing**: Unit test interceptors
8. **Async**: Use for long-running tasks
9. **Conditional**: Check before processing
10. **Cleanup**: Release resources

### Common Patterns

```boxlang
// ✅ Good: Fast interception
function onRequest( interceptData ) {
    // Quick logging
    writeLog( interceptData.path )
}

// ✅ Good: Error handling
function onUserCreated( interceptData ) {
    try {
        sendWelcomeEmail( interceptData.userID )
    } catch ( any e ) {
        writeLog( "Email failed: #e.message#" )
        // Don't rethrow - don't break user creation
    }
}

// ✅ Good: Conditional processing
function onDataSave( interceptData ) {
    if ( interceptData.entityName != "User" ) {
        return  // Skip for non-users
    }

    // Process user-specific logic
}
```

## Common Pitfalls

### Pitfalls to Avoid

1. **Slow Operations**: Blocking interceptors
2. **Tight Coupling**: Dependencies on specific implementations
3. **No Error Handling**: Uncaught exceptions
4. **State Pollution**: Modifying global state
5. **Recursion**: Announcing same event
6. **Missing Priority**: Wrong execution order
7. **Memory Leaks**: Not cleaning up
8. **Synchronous**: Long-running operations
9. **Over-Engineering**: Too many interceptors
10. **Poor Naming**: Unclear interception points

### Anti-Patterns

```boxlang
// ❌ Bad: Slow operation
function onRequest( interceptData ) {
    // Blocks request
    var data = makeSlowDatabaseQuery()
}

// ✅ Good: Async operation
function onRequest( interceptData ) {
    announceAsync( "processData", interceptData )
}

// ❌ Bad: No error handling
function onUserCreated( interceptData ) {
    sendEmail( interceptData.email )  // Could fail
}

// ✅ Good: Handle errors
function onUserCreated( interceptData ) {
    try {
        sendEmail( interceptData.email )
    } catch ( any e ) {
        writeLog( "Email error: #e.message#" )
    }
}

// ❌ Bad: Recursion
function onDataSave( interceptData ) {
    // This triggers onDataSave again!
    announce( "onDataSave", data )
}

// ✅ Good: Different event
function onDataSave( interceptData ) {
    announce( "afterDataSave", data )
}
```

## Related Skills

- [ColdBox Interceptor Development](../coldbox/interceptor-development.md) - ColdBox interceptors
- [BoxLang Classes](boxlang-classes.md) - Class development
- [BoxLang Modules](boxlang-modules.md) - Module integration

## References

- [BoxLang Interceptors Documentation](https://boxlang.ortusbooks.com/)
- [Aspect-Oriented Programming](https://en.wikipedia.org/wiki/Aspect-oriented_programming)
- [Observer Pattern](https://refactoring.guru/design-patterns/observer)
