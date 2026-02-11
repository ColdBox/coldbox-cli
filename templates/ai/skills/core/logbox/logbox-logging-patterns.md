---
name: LogBox Logging Patterns
description: Complete guide to LogBox logging, appenders, log levels, categories, and enterprise logging patterns for debugging and monitoring
category: logbox
priority: high
triggers:
  - logbox
  - logging
  - log appender
  - log level
  - log category
  - error logging
  - debug logging
---

# LogBox Logging Patterns

## Overview

LogBox is ColdBox's enterprise logging library providing multi-appender logging, hierarchical categories, log levels, and comprehensive logging patterns. Proper logging is essential for debugging, monitoring, and auditing applications.

## Core Concepts

### LogBox Architecture

- **LogBox**: Central logging factory
- **Logger**: Individual logging instance
- **Appenders**: Output destinations (file, console, database, email)
- **Log Levels**: Severity filtering (FATAL, ERROR, WARN, INFO, DEBUG, TRACE)
- **Categories**: Hierarchical logger organization
- **Layouts**: Format log messages

## Basic Logging

### Accessing LogBox

```boxlang
class extends="coldbox.system.EventHandler" {

    property name="log" inject="logbox:logger:{this}"

    function index( event, rc, prc ) {
        log.info( "Index handler executed" )

        log.debug( "Request collection: #serializeJSON( rc )#" )

        try {
            riskyOperation()
        } catch ( any e ) {
            log.error( "Operation failed: #e.message#", e )
        }
    }
}
```

### Log Levels

```boxlang
class {

    property name="log" inject="logbox:logger:{this}"

    function processOrder( order ) {
        // TRACE: Very detailed
        log.trace( "Order processing started: #order.id#" )

        // DEBUG: Debugging information
        log.debug( "Order data: #serializeJSON( order )#" )

        // INFO: General information
        log.info( "Processing order #order.id#" )

        // WARN: Warning conditions
        if ( order.total > 10000 ) {
            log.warn( "Large order detected: $#order.total#" )
        }

        // ERROR: Error conditions
        try {
            charge( order )
        } catch ( any e ) {
            log.error( "Payment failed for order #order.id#", e )
            rethrow
        }

        // FATAL: System unusable
        if ( !systemAvailable() ) {
            log.fatal( "Payment system unavailable", getSystemStatus() )
        }
    }
}
```

## LogBox Configuration

### LogBox.cfc

```boxlang
/**
 * config/LogBox.cfc
 */
class {

    function configure() {
        logBox = {
            // Define appenders
            appenders: {
                // Console appender
                console: {
                    class: "coldbox.system.logging.appenders.ConsoleAppender"
                },

                // File appender
                files: {
                    class: "coldbox.system.logging.appenders.RollingFileAppender",
                    properties: {
                        filepath: "logs",
                        filename: "app.log",
                        autoExpand: true,
                        fileMaxSize: 3000,  // KB
                        fileMaxArchives: 5
                    }
                },

                // Error file appender
                errorFile: {
                    class: "coldbox.system.logging.appenders.RollingFileAppender",
                    properties: {
                        filepath: "logs",
                        filename: "errors.log",
                        autoExpand: true,
                        fileMaxSize: 5000,
                        fileMaxArchives: 10
                    }
                },

                // Email appender for critical errors
                email: {
                    class: "coldbox.system.logging.appenders.EmailAppender",
                    properties: {
                        subject: "ColdBox Error",
                        from: "errors@myapp.com",
                        to: "admin@myapp.com",
                        server: "smtp.gmail.com",
                        port: 587,
                        useSSL: true,
                        username: "${EMAIL_USER}",
                        password: "${EMAIL_PASS}"
                    }
                }
            },

            // Root logger
            root: {
                levelMin: "INFO",
                levelMax: "FATAL",
                appenders: "*"  // All appenders
            },

            // Category loggers
            categories: {
                // SQL logging
                "models.dao": {
                    levelMin: "DEBUG",
                    appenders: "files"
                },

                // Error logging
                "error": {
                    levelMin: "ERROR",
                    levelMax: "FATAL",
                    appenders: "errorFile,email"
                },

                // Security logging
                "security": {
                    levelMin: "WARN",
                    appenders: "files"
                }
            }
        }
    }
}
```

### Environment-Specific Configuration

```boxlang
/**
 * config/LogBox.cfc
 */
class {

    function configure() {
        logBox = {
            appenders: {
                console: {
                    class: "coldbox.system.logging.appenders.ConsoleAppender"
                },
                files: {
                    class: "coldbox.system.logging.appenders.RollingFileAppender",
                    properties: {
                        filepath: "logs",
                        filename: "app.log"
                    }
                }
            },

            root: {
                levelMin: getSetting( "environment" ) == "production" ? "WARN" : "DEBUG",
                appenders: "*"
            }
        }
    }
}
```

## Service Layer Logging

### Logging in Services

```boxlang
/**
 * UserService.cfc
 */
class singleton {

    property name="log" inject="logbox:logger:{this}"
    property name="userDAO" inject="UserDAO"

    function create( required struct data ) {
        log.info( "Creating user: #data.email#" )
        log.debug( "User data: #serializeJSON( data )#" )

        try {
            var user = userDAO.create( data )

            log.info( "User created successfully: #user.id#" )

            return user

        } catch ( any e ) {
            log.error( "User creation failed: #e.message#", e )
            log.debug( "Exception detail: #e.detail#" )

            rethrow
        }
    }

    function authenticate( email, password ) {
        log.info( "Authentication attempt: #email#" )

        try {
            var user = userDAO.findByEmail( email )

            if ( !bcrypt.checkPassword( password, user.password ) ) {
                log.warn( "Failed login attempt: #email#" )
                throw( "Invalid credentials" )
            }

            log.info( "Successful login: #email#" )

            return user

        } catch ( any e ) {
            log.error( "Authentication error: #e.message#" )
            rethrow
        }
    }
}
```

### Contextual Logging

```boxlang
class singleton {

    property name="log" inject="logbox:logger:{this}"

    function processPayment( orderID, amount ) {
        // Add context to log messages
        var context = {
            orderID: orderID,
            amount: amount,
            timestamp: now()
        }

        log.info( "Processing payment", context )

        try {
            var result = chargeCard( amount )

            context.transactionID = result.id
            log.info( "Payment successful", context )

            return result

        } catch ( any e ) {
            context.error = e.message
            log.error( "Payment failed", context )

            rethrow
        }
    }
}
```

## Log Appenders

### File Appender

```boxlang
// Simple file appender
files: {
    class: "coldbox.system.logging.appenders.RollingFileAppender",
    properties: {
        filepath: "logs",
        filename: "app.log",
        autoExpand: true,
        fileMaxSize: 3000,  // KB
        fileMaxArchives: 5
    }
}
```

### Console Appender

```boxlang
// Development console output
console: {
    class: "coldbox.system.logging.appenders.ConsoleAppender",
    properties: {
        name: "ConsoleAppender"
    }
}
```

### Database Appender

```boxlang
// Log to database
db: {
    class: "coldbox.system.logging.appenders.DBAppender",
    properties: {
        dsn: "mydsn",
        table: "logs",
        columnMap: {
            severity: "log_level",
            category: "category",
            message: "message",
            extraInfo: "extra_info",
            timestamp: "log_date"
        }
    }
}
```

### Email Appender

```boxlang
// Email critical errors
email: {
    class: "coldbox.system.logging.appenders.EmailAppender",
    properties: {
        subject: "Application Error",
        from: "errors@app.com",
        to: "admin@app.com",
        server: "smtp.gmail.com",
        port: 587,
        useSSL: true
    }
}
```

### Custom Appender

```boxlang
/**
 * SlackAppender.cfc
 */
class extends="coldbox.system.logging.AbstractAppender" {

    property name="webhookURL"

    function init( required name, properties = {} ) {
        super.init( argumentCollection = arguments )

        variables.webhookURL = getProperty( "webhookURL" )

        return this
    }

    function logMessage( required logEvent ) {
        var message = {
            text: "#arguments.logEvent.getSeverity()#: #arguments.logEvent.getMessage()#",
            username: "LogBox",
            icon_emoji: ":warning:"
        }

        cfhttp(
            url: variables.webhookURL,
            method: "POST",
            result: "httpResult"
        ) {
            cfhttpparam(
                type: "body",
                value: serializeJSON( message )
            )
        }
    }
}
```

## Log Categories

### Category Hierarchy

```boxlang
// config/LogBox.cfc
categories: {
    // Root category for models
    "models": {
        levelMin: "INFO",
        appenders: "files"
    },

    // Specific DAO logging
    "models.dao": {
        levelMin: "DEBUG",
        appenders: "files"
    },

    // User DAO with SQL logging
    "models.dao.UserDAO": {
        levelMin: "TRACE",
        appenders: "files,console"
    }
}
```

### Using Categorized Loggers

```boxlang
/**
 * UserDAO.cfc
 */
class singleton {

    // Inject category-specific logger
    property name="log" inject="logbox:logger:models.dao.UserDAO"

    function list() {
        log.debug( "Listing users" )

        var sql = "SELECT * FROM users"
        log.trace( "SQL: #sql#" )

        var users = queryExecute( sql )

        log.debug( "Found #users.recordCount# users" )

        return users
    }
}
```

## Advanced Patterns

### Structured Logging

```boxlang
class singleton {

    property name="log" inject="logbox:logger:{this}"

    function processOrder( order ) {
        // Structured log data
        var logData = {
            event: "order.process",
            orderID: order.id,
            userID: order.userID,
            total: order.total,
            items: order.items.len(),
            timestamp: now()
        }

        log.info( "Processing order", logData )

        try {
            // Process order
            var result = charge( order )

            logData.result = "success"
            logData.transactionID = result.id

            log.info( "Order processed", logData )

        } catch ( any e ) {
            logData.result = "error"
            logData.error = e.message

            log.error( "Order processing failed", logData )
        }
    }
}
```

### Performance Logging

```boxlang
class singleton {

    property name="log" inject="logbox:logger:{this}"

    function expensiveOperation() {
        var start = getTickCount()

        log.debug( "Starting expensive operation" )

        try {
            var result = doWork()

            var duration = getTickCount() - start

            log.info( "Operation completed in #duration#ms" )

            if ( duration > 5000 ) {
                log.warn( "Operation exceeded threshold: #duration#ms" )
            }

            return result

        } catch ( any e ) {
            var duration = getTickCount() - start

            log.error( "Operation failed after #duration#ms: #e.message#", e )

            rethrow
        }
    }
}
```

### Request Logging in Handlers

```boxlang
class extends="coldbox.system.EventHandler" {

    property name="log" inject="logbox:logger:{this}"

    function preHandler( event, rc, prc ) {
        // Log all requests
        var requestData = {
            event: event.getCurrentEvent(),
            ip: event.getHTTPHeader( "REMOTE_ADDR" ),
            userAgent: event.getHTTPHeader( "USER-AGENT" ),
            timestamp: now()
        }

        log.info( "Request started", requestData )

        // Store start time
        prc.requestStart = getTickCount()
    }

    function postHandler( event, rc, prc ) {
        // Log request completion
        var duration = getTickCount() - prc.requestStart

        var requestData = {
            event: event.getCurrentEvent(),
            duration: duration,
            statusCode: event.getStatusCode()
        }

        log.info( "Request completed", requestData )

        // Warn on slow requests
        if ( duration > 3000 ) {
            log.warn( "Slow request detected: #duration#ms", requestData )
        }
    }
}
```

### Error Logging with Context

```boxlang
class extends="coldbox.system.EventHandler" {

    property name="log" inject="logbox:logger:error"

    function onException( event, rc, prc, faultAction, exception ) {
        // Comprehensive error logging
        var errorData = {
            message: exception.message,
            detail: exception.detail,
            type: exception.type,
            event: faultAction,
            stackTrace: exception.stackTrace,

            // Request context
            requestEvent: event.getCurrentEvent(),
            rc: rc,

            // User context
            userID: prc.userID ?: "guest",
            ip: event.getHTTPHeader( "REMOTE_ADDR" ),

            // Server context
            environment: getSetting( "environment" ),
            timestamp: now()
        }

        log.error( "Unhandled exception", errorData )

        // Rethrow for error handler
        rethrow
    }
}
```

## Best Practices

### Design Guidelines

1. **Appropriate Levels**: Use correct log levels
2. **Meaningful Messages**: Clear, descriptive log messages
3. **Context**: Include relevant data
4. **Performance**: Avoid excessive logging in production
5. **Security**: Don't log sensitive data (passwords, tokens)
6. **Categories**: Organize loggers hierarchically
7. **Appenders**: Use appropriate output destinations
8. **Rotation**: Implement log rotation for files
9. **Monitoring**: Monitor log files regularly
10. **Testing**: Test logging in all environments

### Common Patterns

```boxlang
// ✅ Good: Clear message with context
log.info( "User created: #user.email#" )

// ✅ Good: Exception logging
catch ( any e ) {
    log.error( "Operation failed: #e.message#", e )
}

// ✅ Good: Structured data
log.info( "Order processed", {
    orderID: order.id,
    total: order.total,
    items: order.items.len()
} )

// ✅ Good: Performance logging
var start = getTickCount()
// ... operation ...
log.debug( "Operation took #getTickCount() - start#ms" )
```

## Common Pitfalls

### Pitfalls to Avoid

1. **Over-Logging**: Logging everything in production
2. **Under-Logging**: Not logging enough for debugging
3. **Wrong Levels**: Using INFO for errors
4. **No Context**: Vague log messages
5. **Sensitive Data**: Logging passwords or tokens
6. **No Rotation**: Unbounded log files
7. **Synchronous Emails**: Blocking on email appenders
8. **No Monitoring**: Not reviewing logs
9. **String Concatenation**: Building complex log messages unnecessarily
10. **Testing in Production**: Different logging in dev vs prod

### Anti-Patterns

```boxlang
// ❌ Bad: No context
log.error( "Error occurred" )

// ✅ Good: With context
log.error( "User creation failed for #email#: #e.message#", e )

// ❌ Bad: Logging sensitive data
log.debug( "Password: #password#" )

// ✅ Good: Sanitized
log.debug( "Password length: #len( password )#" )

// ❌ Bad: Wrong level
log.info( "Critical system failure!" )

// ✅ Good: Correct level
log.fatal( "Critical system failure: #details#" )

// ❌ Bad: String concatenation for unused logs
log.debug( "Data: #serializeJSON( complexObject )#" )

// ✅ Good: Lazy evaluation (if supported)
log.debug( () => "Data: #serializeJSON( complexObject )#" )
```

## Related Skills

- [Handler Development](../coldbox/handler-development.md) - Handler patterns
- [WireBox DI Patterns](../wirebox/wirebox-di-patterns.md) - Dependency injection
- [CacheBox Caching](../cachebox/cachebox-caching-patterns.md) - Caching patterns

## References

- [LogBox Documentation](https://logbox.ortusbooks.com/)
- [Log Appenders](https://logbox.ortusbooks.com/appenders)
- [Log Levels](https://logbox.ortusbooks.com/essentials/log-levels)
