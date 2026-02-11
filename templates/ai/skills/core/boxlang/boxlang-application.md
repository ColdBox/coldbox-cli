---
name: BoxLang Application.bx
description: Complete guide to Application.bx configuration file for application settings, datasources, mappings, and lifecycle methods
category: boxlang
priority: high
triggers:
  - application.bx
  - application.cfc
  - application settings
  - application scope
  - datasource
  - mappings
---

# BoxLang Application.bx

## Overview

Application.bx (or Application.cfc) is the configuration file that defines application-wide settings, datasources, mappings, and lifecycle methods. It's the entry point for every request.

## Core Concepts

### Application Fundamentals

- **Application Scope**: Shared across all sessions
- **Session Scope**: User-specific data
- **Request Scope**: Single request data
- **Lifecycle Methods**: onApplicationStart, onRequestStart, etc.
- **Settings**: Timeout, datasources, mappings
- **Security**: Session management, authentication

## Basic Configuration

### Simple Application.bx

```boxlang
/**
 * Application.bx
 */
class {

    // Application name (required)
    this.name = "MyApplication"

    // Application timeout (days)
    this.applicationTimeout = createTimeSpan( 1, 0, 0, 0 )

    // Session management
    this.sessionManagement = true
    this.sessionTimeout = createTimeSpan( 0, 0, 30, 0 )

    // Set mappings
    this.mappings = {
        "/models": expandPath( "./models" ),
        "/views": expandPath( "./views" )
    }

    /**
     * Application startup
     */
    function onApplicationStart() {
        application.startTime = now()
        application.version = "1.0.0"

        return true
    }

    /**
     * Request start
     */
    function onRequestStart( required string targetPage ) {
        // Reinit application if URL param present
        if ( structKeyExists( url, "reinit" ) ) {
            onApplicationStart()
        }

        return true
    }
}
```

## Datasource Configuration

### Single Datasource

```boxlang
class {
    this.name = "MyApp"

    // Default datasource
    this.datasource = "mydb"

    // Datasource definitions
    this.datasources = {
        "mydb": {
            class: "com.mysql.cj.jdbc.Driver",
            connectionString: "jdbc:mysql://localhost:3306/mydb?useSSL=false&allowPublicKeyRetrieval=true",
            username: getSystemProperty( "DB_USERNAME", "root" ),
            password: getSystemProperty( "DB_PASSWORD", "" )
        }
    }
}
```

### Multiple Datasources

```boxlang
class {
    this.name = "MyApp"

    // Default datasource
    this.datasource = "primary"

    this.datasources = {
        "primary": {
            class: "com.mysql.cj.jdbc.Driver",
            connectionString: "jdbc:mysql://localhost:3306/myapp",
            username: getSystemProperty( "DB_USERNAME" ),
            password: getSystemProperty( "DB_PASSWORD" ),
            connectionTimeout: 30,
            maxConnections: 50
        },
        "analytics": {
            class: "org.postgresql.Driver",
            connectionString: "jdbc:postgresql://localhost:5432/analytics",
            username: getSystemProperty( "ANALYTICS_DB_USERNAME" ),
            password: getSystemProperty( "ANALYTICS_DB_PASSWORD" )
        },
        "cache": {
            class: "org.h2.Driver",
            connectionString: "jdbc:h2:mem:cache;DB_CLOSE_DELAY=-1"
        }
    }
}
```

## Application Settings

### Comprehensive Settings

```boxlang
class {

    // Application identity
    this.name = "MyApplication"
    this.applicationTimeout = createTimeSpan( 1, 0, 0, 0 )

    // Session management
    this.sessionManagement = true
    this.sessionTimeout = createTimeSpan( 0, 0, 30, 0 )
    this.sessionCookie = {
        httpOnly: true,
        secure: true,
        sameSite: "strict"
    }

    // Client management
    this.clientManagement = false

    // Request settings
    this.requestTimeout = 30
    this.setClientCookies = true
    this.setDomainCookies = false

    // Script protection
    this.scriptProtect = "all"

    // Compression
    this.compression = true

    // Custom tag paths
    this.customTagPaths = [
        expandPath( "./customtags" )
    ]

    // Mappings
    this.mappings = {
        "/models": expandPath( "./models" ),
        "/views": expandPath( "./views" ),
        "/lib": expandPath( "./lib" )
    }

    // Java settings
    this.javaSettings = {
        loadPaths: [ "./lib" ],
        reloadOnChange: true
    }

    // Locale/timezone
    this.locale = "en_US"
    this.timezone = "America/New_York"
}
```

## Lifecycle Methods

### Request Lifecycle

```boxlang
class {

    this.name = "MyApp"

    /**
     * Application startup (runs once)
     */
    function onApplicationStart() {
        application.startTime = now()

        // Load configuration
        application.config = loadConfig()

        // Initialize services
        application.cache = createObject( "component", "models.CacheService" )

        writeLog( "Application started" )

        return true
    }

    /**
     * Application shutdown
     */
    function onApplicationEnd( required struct applicationScope ) {
        writeLog( "Application ending after #dateDiff( 'n', applicationScope.startTime, now() )# minutes" )
    }

    /**
     * Session startup
     */
    function onSessionStart() {
        session.sessionID = createUUID()
        session.startTime = now()

        writeLog( "Session started: #session.sessionID#" )
    }

    /**
     * Session shutdown
     */
    function onSessionEnd( required struct sessionScope, required struct applicationScope ) {
        writeLog( "Session ended: #sessionScope.sessionID#" )
    }

    /**
     * Request start
     */
    function onRequestStart( required string targetPage ) {
        // Initialize request scope
        request.startTime = getTickCount()

        // Check for reinit
        if ( structKeyExists( url, "reinit" ) && isUserInRole( "admin" ) ) {
            applicationStop()
        }

        return true
    }

    /**
     * Request end
     */
    function onRequestEnd( required string targetPage ) {
        var duration = getTickCount() - request.startTime

        // Log slow requests
        if ( duration > 1000 ) {
            writeLog( "Slow request: #targetPage# (#duration#ms)" )
        }
    }

    /**
     * Error handler
     */
    function onError( required any exception, required string eventName ) {
        writeLog(
            text: "Error in #eventName#: #exception.message#",
            type: "error"
        )

        // Display error page
        include template="views/error.cfm"

        return true
    }

    /**
     * Missing template handler
     */
    function onMissingTemplate( required string targetPage ) {
        writeLog( "Missing template: #targetPage#" )

        // Custom 404 page
        include template="views/404.cfm"

        return true
    }
}
```

## Advanced Configuration

### Environment-Specific Settings

```boxlang
class {

    this.name = "MyApp"

    // Detect environment
    variables.environment = getSystemProperty( "ENVIRONMENT", "development" )

    function onApplicationStart() {
        // Load environment-specific config
        switch ( variables.environment ) {
            case "production":
                loadProductionConfig()
                break

            case "staging":
                loadStagingConfig()
                break

            default:
                loadDevelopmentConfig()
        }

        return true
    }

    private function loadProductionConfig() {
        this.sessionTimeout = createTimeSpan( 0, 2, 0, 0 )
        this.requestTimeout = 30

        application.config = {
            debug: false,
            cacheEnabled: true,
            logLevel: "ERROR"
        }
    }

    private function loadDevelopmentConfig() {
        this.sessionTimeout = createTimeSpan( 0, 0, 30, 0 )
        this.requestTimeout = 120

        application.config = {
            debug: true,
            cacheEnabled: false,
            logLevel: "DEBUG"
        }
    }
}
```

### Custom URL Routing

```boxlang
class {

    this.name = "MyApp"

    function onRequestStart( required string targetPage ) {
        var path = cgi.path_info

        // Custom routing
        if ( reFindNoCase( "^/api/", path ) ) {
            // API request
            request.isAPI = true
            include template="api/index.cfm"
            return false  // Stop normal processing
        }

        if ( reFindNoCase( "^/admin/", path ) ) {
            // Admin area - check authentication
            if ( !isUserAuthenticated() ) {
                location( url="/login", addToken=false )
            }
        }

        return true
    }
}
```

### Security Configuration

```boxlang
class {

    this.name = "SecureApp"

    // Secure session cookies
    this.sessionCookie = {
        httpOnly: true,
        secure: true,
        sameSite: "strict",
        timeout: createTimeSpan( 0, 0, 30, 0 )
    }

    // Script protection
    this.scriptProtect = "all"

    // Secure headers
    function onRequestStart( required string targetPage ) {
        var response = getPageContext().getResponse()

        // Security headers
        response.setHeader( "X-Frame-Options", "DENY" )
        response.setHeader( "X-Content-Type-Options", "nosniff" )
        response.setHeader( "X-XSS-Protection", "1; mode=block" )
        response.setHeader( "Strict-Transport-Security", "max-age=31536000; includeSubDomains" )

        // CORS headers (if needed)
        if ( request.isAPI ) {
            response.setHeader( "Access-Control-Allow-Origin", "https://example.com" )
            response.setHeader( "Access-Control-Allow-Methods", "GET, POST, PUT, DELETE" )
        }

        return true
    }
}
```

## Best Practices

### Design Guidelines

1. **Environment Variables**: Use for sensitive data
2. **Timeouts**: Set appropriate values
3. **Security**: Enable httpOnly, secure cookies
4. **Error Handling**: Implement onError
5. **Logging**: Log important events
6. **Reinit**: Provide admin reinit mechanism
7. **Mappings**: Use for reusable paths
8. **Session Management**: Enable when needed
9. **Performance**: Monitor request times
10. **Documentation**: Document custom settings

### Common Patterns

```boxlang
// ✅ Good: Environment variables for secrets
this.datasources = {
    "mydb": {
        username: getSystemProperty( "DB_USERNAME" ),
        password: getSystemProperty( "DB_PASSWORD" )
    }
}

// ✅ Good: Secure session cookies
this.sessionCookie = {
    httpOnly: true,
    secure: true,
    sameSite: "strict"
}

// ✅ Good: Error logging
function onError( exception, eventName ) {
    writeLog(
        text: "Error: #exception.message#",
        type: "error",
        file: "application"
    )
}
```

## Common Pitfalls

### Pitfalls to Avoid

1. **No Application Name**: Required field
2. **Hardcoded Credentials**: Security risk
3. **No Error Handler**: Poor user experience
4. **Long Timeouts**: Resource waste
5. **Insecure Cookies**: Session hijacking
6. **No Logging**: Hard to debug
7. **Global Variables**: Memory leaks
8. **Complex Logic**: Keep simple
9. **No Reinit**: Hard to update
10. **Missing Return**: Methods must return boolean

### Anti-Patterns

```boxlang
// ❌ Bad: Hardcoded credentials
this.datasources = {
    "mydb": {
        username: "root",
        password: "password123"
    }
}

// ✅ Good: Environment variables
this.datasources = {
    "mydb": {
        username: getSystemProperty( "DB_USERNAME" ),
        password: getSystemProperty( "DB_PASSWORD" )
    }
}

// ❌ Bad: No error handling
function onError( exception, eventName ) {
    // Nothing - user sees error details
}

// ✅ Good: Handle errors gracefully
function onError( exception, eventName ) {
    writeLog(
        text: exception.message,
        type: "error"
    )
    include template="views/error.cfm"
    return true
}

// ❌ Bad: Insecure cookies
this.sessionManagement = true
// No security settings

// ✅ Good: Secure cookies
this.sessionManagement = true
this.sessionCookie = {
    httpOnly: true,
    secure: true,
    sameSite: "strict"
}
```

## Related Skills

- [BoxLang Classes](boxlang-classes.md) - Component structure
- [BoxLang JDBC](boxlang-jdbc.md) - Datasource usage
- [ColdBox Configuration](../coldbox/coldbox-config.md) - Framework config

## References

- [BoxLang Application.bx Documentation](https://boxlang.ortusbooks.com/)
- [OWASP Session Management](https://owasp.org/www-community/Session_Management_Cheat_Sheet)
- [HTTP Security Headers](https://owasp.org/www-project-secure-headers/)
