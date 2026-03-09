---
name: WireBox AOP
description: Complete guide to WireBox aspect-oriented programming, method interception, performance monitoring, logging, security aspects, and cross-cutting concerns
category: wirebox
priority: high
triggers:
  - AOP
  - aspect oriented
  - interceptor
  - interception
  - cross-cutting
  - before
  - after
  - around
---

# WireBox Aspect-Oriented Programming (AOP)

## Overview

WireBox AOP enables separation of cross-cutting concerns (logging, security, transactions, performance monitoring) from business logic through method interception. Interceptors wrap method calls to add behavior before, after, or around method execution.

## Core Concepts

### AOP Terminology

- **Aspect**: Cross-cutting concern (logging, security, transactions)
- **Join Point**: Method execution point where aspects can be applied
- **Advice**: Code executed at join points (before, after, around, onException)
- **Pointcut**: Expression defining which methods to intercept
- **Interceptor**: Component implementing the aspect logic
- **Weaving**: Process of applying aspects to target objects

### Interception Types

1. **before**: Runs before method execution
2. **after**: Runs after method execution (with result)
3. **around**: Wraps method execution (full control)
4. **onException**: Runs when method throws exception

## Basic Interception

### Configuring Interceptors

```boxlang
/**
 * config/WireBox.cfc
 */
class {

    function configure() {

        // Add single interceptor
        map( "UserService" )
            .to( "models.UserService" )
            .asSingleton()
            .addInterceptor( "LoggingInterceptor" )

        // Add multiple interceptors (executed in order)
        map( "OrderService" )
            .to( "models.OrderService" )
            .asSingleton()
            .addInterceptor( "SecurityInterceptor" )
            .addInterceptor( "LoggingInterceptor" )
            .addInterceptor( "PerformanceInterceptor" )
    }
}
```

### Basic Interceptor

```boxlang
/**
 * LoggingInterceptor.cfc
 */
class {

    property name="log" inject="logbox:logger:{this}"

    function before( invocation ) {
        log.debug( "Calling #invocation.getMethod()#" )
    }

    function after( invocation, result ) {
        log.debug( "#invocation.getMethod()# completed" )
        return result
    }

    function onException( invocation, exception ) {
        log.error( "#invocation.getMethod()# failed: #exception.message#" )
        rethrow
    }
}
```

### Invocation Object

```boxlang
/**
 * The invocation object provides access to:
 */
class {

    function before( invocation ) {
        // Get method name
        var methodName = invocation.getMethod()

        // Get arguments
        var args = invocation.getArgs()

        // Get target object
        var target = invocation.getTarget()

        // Get target metadata
        var metadata = invocation.getTargetMD()

        log.info( "Method: #methodName#, Args: #serializeJSON( args )#" )
    }

    function around( invocation ) {
        // Proceed with execution
        var result = invocation.proceed()

        // Can modify result
        return result
    }
}
```

## Common AOP Patterns

### Performance Monitoring

```boxlang
/**
 * PerformanceInterceptor.cfc
 */
class {

    property name="log" inject="logbox:logger:{this}"

    function around( invocation ) {
        var start = getTickCount()
        var methodName = invocation.getMethod()

        try {
            // Execute method
            var result = invocation.proceed()

            var duration = getTickCount() - start

            // Log slow methods
            if ( duration > 1000 ) {
                log.warn( "Slow method: #methodName# (#duration#ms)" )
            } else {
                log.debug( "Method: #methodName# (#duration#ms)" )
            }

            return result

        } catch ( any e ) {
            log.error( "Method failed: #methodName# after #getTickCount() - start#ms" )
            rethrow
        }
    }
}
```

### Audit Logging

```boxlang
/**
 * AuditInterceptor.cfc
 */
class {

    property name="auditService" inject="AuditService"
    property name="authService" inject="AuthService"

    function after( invocation, result ) {
        var methodName = invocation.getMethod()
        var args = invocation.getArgs()

        // Log audit trail for specific methods
        if ( methodName.findNoCase( "create" ) ||
             methodName.findNoCase( "update" ) ||
             methodName.findNoCase( "delete" ) ) {

            auditService.log(
                action: methodName,
                user: authService.getUser().getId(),
                data: args,
                timestamp: now()
            )
        }

        return result
    }
}
```

### Security Authorization

```boxlang
/**
 * SecurityInterceptor.cfc
 */
class {

    property name="authService" inject="AuthService"
    property name="log" inject="logbox:logger:{this}"

    function before( invocation ) {
        var methodName = invocation.getMethod()
        var target = invocation.getTarget()
        var metadata = getMetadata( target[ methodName ] )

        // Check for secured annotation
        if ( structKeyExists( metadata, "secured" ) ) {
            var requiredRole = metadata.secured

            if ( !authService.hasRole( requiredRole ) ) {
                log.warn( "Unauthorized access attempt to #methodName#" )
                throw(
                    type: "SecurityException",
                    message: "Access denied to #methodName#"
                )
            }
        }
    }
}

/**
 * Usage in service
 */
class singleton {

    /**
     * @secured admin
     */
    function deleteUser( userID ) {
        // Only users with 'admin' role can execute this
    }

    /**
     * @secured manager,admin
     */
    function approveOrder( orderID ) {
        // Only managers or admins can execute this
    }
}
```

### Transaction Management

```boxlang
/**
 * TransactionInterceptor.cfc
 */
class {

    property name="log" inject="logbox:logger:{this}"

    function around( invocation ) {
        var methodName = invocation.getMethod()
        var target = invocation.getTarget()
        var metadata = getMetadata( target[ methodName ] )

        // Check for transactional annotation
        if ( structKeyExists( metadata, "transactional" ) ) {
            transaction {
                try {
                    var result = invocation.proceed()
                    transaction action="commit";
                    return result

                } catch ( any e ) {
                    transaction action="rollback";
                    log.error( "Transaction rolled back for #methodName#: #e.message#" )
                    rethrow
                }
            }
        } else {
            return invocation.proceed()
        }
    }
}

/**
 * Usage in service
 */
class singleton {

    /**
     * @transactional true
     */
    function transferFunds( fromAccount, toAccount, amount ) {
        // Entire operation wrapped in transaction
        debit( fromAccount, amount )
        credit( toAccount, amount )
    }
}
```

### Caching Aspect

```boxlang
/**
 * CacheInterceptor.cfc
 */
class {

    property name="cache" inject="cachebox:default"
    property name="log" inject="logbox:logger:{this}"

    function around( invocation ) {
        var methodName = invocation.getMethod()
        var args = invocation.getArgs()
        var target = invocation.getTarget()
        var metadata = getMetadata( target[ methodName ] )

        // Check for cacheable annotation
        if ( structKeyExists( metadata, "cacheable" ) ) {
            var cacheKey = generateCacheKey( methodName, args )

            // Check cache
            var cachedResult = cache.get( cacheKey )
            if ( !isNull( cachedResult ) ) {
                log.debug( "Cache hit for #methodName#" )
                return cachedResult
            }

            // Execute and cache
            log.debug( "Cache miss for #methodName#" )
            var result = invocation.proceed()
            cache.set( cacheKey, result, metadata.cacheable )

            return result
        }

        return invocation.proceed()
    }

    private function generateCacheKey( methodName, args ) {
        return "#methodName#_#hash( serializeJSON( args ) )#"
    }
}

/**
 * Usage in service
 */
class singleton {

    /**
     * Cache for 60 minutes
     * @cacheable 60
     */
    function getConfiguration() {
        // Expensive operation cached for 1 hour
    }
}
```

### Retry Logic

```boxlang
/**
 * RetryInterceptor.cfc
 */
class {

    property name="log" inject="logbox:logger:{this}"

    function around( invocation ) {
        var methodName = invocation.getMethod()
        var target = invocation.getTarget()
        var metadata = getMetadata( target[ methodName ] )

        if ( structKeyExists( metadata, "retry" ) ) {
            var maxRetries = val( metadata.retry )
            var attempt = 0

            while ( attempt < maxRetries ) {
                try {
                    return invocation.proceed()

                } catch ( any e ) {
                    attempt++

                    if ( attempt >= maxRetries ) {
                        log.error( "#methodName# failed after #attempt# attempts" )
                        rethrow
                    }

                    log.warn( "#methodName# failed (attempt #attempt#/#maxRetries#), retrying..." )
                    sleep( 1000 * attempt )  // Exponential backoff
                }
            }
        }

        return invocation.proceed()
    }
}

/**
 * Usage in service
 */
class singleton {

    /**
     * Retry up to 3 times
     * @retry 3
     */
    function callExternalAPI() {
        // Retries on failure
    }
}
```

### Rate Limiting

```boxlang
/**
 * RateLimitInterceptor.cfc
 */
class {

    property name="cache" inject="cachebox:default"
    property name="log" inject="logbox:logger:{this}"

    function before( invocation ) {
        var methodName = invocation.getMethod()
        var target = invocation.getTarget()
        var metadata = getMetadata( target[ methodName ] )

        if ( structKeyExists( metadata, "rateLimit" ) ) {
            var limit = val( metadata.rateLimit )
            var window = 60  // 1 minute window
            var key = "rateLimit_#methodName#"

            var count = cache.get( key, 0 ) + 1

            if ( count > limit ) {
                log.warn( "Rate limit exceeded for #methodName#" )
                throw(
                    type: "RateLimitException",
                    message: "Rate limit exceeded: #limit# calls per minute"
                )
            }

            cache.set( key, count, window )
        }
    }
}

/**
 * Usage in service
 */
class singleton {

    /**
     * Max 100 calls per minute
     * @rateLimit 100
     */
    function sendEmail( to, subject, body ) {
        // Rate limited to prevent abuse
    }
}
```

## Advanced Patterns

### Conditional Interception

```boxlang
/**
 * ConditionalInterceptor.cfc
 */
class {

    property name="log" inject="logbox:logger:{this}"
    property name="settings" inject="coldbox:configSettings"

    function around( invocation ) {
        var methodName = invocation.getMethod()

        // Only intercept in production
        if ( settings.environment == "production" ) {
            log.info( "Production call: #methodName#" )
        }

        return invocation.proceed()
    }
}
```

### Chaining Interceptors

```boxlang
/**
 * Multiple interceptors execute in order
 */
function configure() {

    map( "PaymentService" )
        .to( "models.PaymentService" )
        .asSingleton()
        .addInterceptor( "SecurityInterceptor" )      // 1. Check security
        .addInterceptor( "ValidationInterceptor" )    // 2. Validate input
        .addInterceptor( "LoggingInterceptor" )       // 3. Log call
        .addInterceptor( "PerformanceInterceptor" )   // 4. Monitor performance
        .addInterceptor( "AuditInterceptor" )         // 5. Audit trail
}
```

### Method Filtering

```boxlang
/**
 * SelectiveInterceptor.cfc
 */
class {

    property name="log" inject="logbox:logger:{this}"

    function before( invocation ) {
        var methodName = invocation.getMethod()

        // Only intercept specific methods
        if ( methodName.findNoCase( "save" ) ||
             methodName.findNoCase( "update" ) ||
             methodName.findNoCase( "delete" ) ) {

            log.info( "Data modification: #methodName#" )
        }
    }
}
```

### Modifying Results

```boxlang
/**
 * ResultTransformInterceptor.cfc
 */
class {

    function after( invocation, result ) {
        var methodName = invocation.getMethod()

        // Transform query results to arrays
        if ( isQuery( result ) ) {
            return queryToArray( result )
        }

        // Sanitize output
        if ( isStruct( result ) && structKeyExists( result, "password" ) ) {
            structDelete( result, "password" )
        }

        return result
    }

    private function queryToArray( qry ) {
        var result = []
        for ( var row in qry ) {
            result.append( row )
        }
        return result
    }
}
```

## Testing with AOP

### Testing Interceptors

```boxlang
/**
 * LoggingInterceptorTest.cfc
 */
class extends="testbox.system.BaseSpec" {

    function run() {
        describe( "LoggingInterceptor", () => {

            beforeEach( () => {
                variables.mockLog = createMock( "coldbox.system.logging.Logger" )
                variables.interceptor = createObject( "LoggingInterceptor" )
                interceptor.$property( "log", "variables", mockLog )

                variables.mockInvocation = createMock( "coldbox.system.aop.MethodInvocation" )
            } )

            it( "should log before method execution", () => {
                mockInvocation.$( "getMethod", "testMethod" )

                interceptor.before( mockInvocation )

                expect( mockLog.$count( "debug" ) ).toBe( 1 )
            } )

            it( "should log after method execution", () => {
                mockInvocation.$( "getMethod", "testMethod" )

                interceptor.after( mockInvocation, "result" )

                expect( mockLog.$count( "debug" ) ).toBe( 1 )
            } )
        } )
    }
}
```

### Testing AOP-Enabled Services

```boxlang
class extends="testbox.system.BaseSpec" {

    function run() {
        describe( "AOP UserService", () => {

            beforeEach( () => {
                // Create WireBox with interceptor
                variables.wirebox = createObject( "coldbox.system.ioc.Injector" ).init()

                wirebox.getBinder()
                    .map( "UserService" )
                    .to( "models.UserService" )
                    .addInterceptor( "LoggingInterceptor" )

                variables.service = wirebox.getInstance( "UserService" )
            } )

            it( "should execute with interception", () => {
                var result = service.getUser( 1 )

                expect( result ).toBeStruct()
                // Verify interceptor was called via log assertions
            } )
        } )
    }
}
```

## Best Practices

### Design Guidelines

1. **Single Responsibility**: Each interceptor handles one concern
2. **Order Matters**: Consider interceptor execution order
3. **Performance**: Keep interceptors lightweight
4. **Exception Handling**: Always handle exceptions in interceptors
5. **Stateless**: Interceptors should be stateless
6. **Metadata Driven**: Use annotations for configuration
7. **Logging**: Log interceptor actions for debugging
8. **Testing**: Test interceptors in isolation
9. **Documentation**: Document interceptor behavior
10. **Selective Interception**: Only intercept methods that need it

### Good Patterns

```boxlang
// ✅ Good: Lightweight interceptor
function around( invocation ) {
    var start = getTickCount()
    var result = invocation.proceed()
    log.debug( "Duration: #getTickCount() - start#ms" )
    return result
}

// ✅ Good: Exception handling
function around( invocation ) {
    try {
        return invocation.proceed()
    } catch ( any e ) {
        log.error( "Error: #e.message#" )
        // Handle gracefully or rethrow
        rethrow
    }
}

// ✅ Good: Metadata-driven
if ( structKeyExists( metadata, "secured" ) ) {
    checkSecurity( metadata.secured )
}

// ✅ Good: Selective interception
if ( methodName.findNoCase( "save" ) ) {
    // Only intercept save methods
}
```

### Anti-Patterns

```boxlang
// ❌ Bad: Heavy processing in interceptor
function before( invocation ) {
    // Expensive operation slows down every call
    complexCalculation()
}

// ❌ Bad: Stateful interceptor
class {
    property name="callCount"  // Shared state!

    function before( invocation ) {
        callCount++  // Thread-safety issue
    }
}

// ❌ Bad: Swallowing exceptions
function around( invocation ) {
    try {
        return invocation.proceed()
    } catch ( any e ) {
        return {}  // Silent failure!
    }
}

// ❌ Bad: Modifying arguments incorrectly
function before( invocation ) {
    var args = invocation.getArgs()
    args.newArg = "value"  // May not work as expected
}

// ❌ Bad: Intercepting everything
// Apply interceptors selectively, not to all services
```

## Common Pitfalls

### Pitfalls to Avoid

1. **Performance Overhead**: Too many or heavy interceptors
2. **Exception Mishandling**: Not properly handling/rethrowing exceptions
3. **Stateful Interceptors**: Sharing state across invocations
4. **Circular Interception**: Interceptor calling intercepted method
5. **Order Dependencies**: Interceptors depending on execution order
6. **Side Effects**: Unintended modifications to arguments/results
7. **Missing Return**: Forgetting to return result in after/around
8. **Over-Interception**: Intercepting too many methods
9. **Complex Logic**: Too much business logic in interceptors
10. **Poor Error Messages**: Not providing context in exceptions

### Debug Tips

```boxlang
/**
 * DebugInterceptor.cfc
 */
class {

    property name="log" inject="logbox:logger:{this}"

    function around( invocation ) {
        var methodName = invocation.getMethod()
        var args = invocation.getArgs()

        log.debug( "=== Entering #methodName# ===" )
        log.debug( "Arguments: #serializeJSON( args )#" )

        var start = getTickCount()

        try {
            var result = invocation.proceed()

            log.debug( "Result: #serializeJSON( result )#" )
            log.debug( "Duration: #getTickCount() - start#ms" )
            log.debug( "=== Exiting #methodName# ===" )

            return result

        } catch ( any e ) {
            log.error( "Exception in #methodName#: #e.message#" )
            log.error( "Stack trace: #e.stackTrace#" )
            rethrow
        }
    }
}
```

## Real-World Examples

### Comprehensive Service Interception

```boxlang
/**
 * config/WireBox.cfc
 */
function configure() {

    // User service with full aspect stack
    map( "UserService" )
        .to( "models.services.UserService" )
        .asSingleton()
        .addInterceptor( "SecurityInterceptor" )
        .addInterceptor( "ValidationInterceptor" )
        .addInterceptor( "CacheInterceptor" )
        .addInterceptor( "PerformanceInterceptor" )
        .addInterceptor( "LoggingInterceptor" )
        .addInterceptor( "AuditInterceptor" )

    // Payment service with specialized aspects
    map( "PaymentService" )
        .to( "models.services.PaymentService" )
        .asSingleton()
        .addInterceptor( "SecurityInterceptor" )
        .addInterceptor( "TransactionInterceptor" )
        .addInterceptor( "RetryInterceptor" )
        .addInterceptor( "AuditInterceptor" )
}
```

## Related Skills

- [WireBox DI](wirebox-di.md) - Dependency injection patterns
- [LogBox Logging](../logbox/logbox-logging-patterns.md) - Logging patterns
- [Security Patterns](../security/authentication.md) - Security implementation
- [Performance Optimization](../coldbox/performance-optimization.md) - Performance patterns

## References

- [WireBox AOP Documentation](https://wirebox.ortusbooks.com/advanced-topics/aspect-oriented-programming)
- [Method Interception](https://wirebox.ortusbooks.com/advanced-topics/aop-interceptors)
- [Cross-Cutting Concerns](https://en.wikipedia.org/wiki/Cross-cutting_concern)
