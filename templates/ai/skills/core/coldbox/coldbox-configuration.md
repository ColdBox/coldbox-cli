---
name: ColdBox Configuration
description: Complete guide to configuring ColdBox applications including ColdBox.cfc setup, settings, conventions, environment detection, and module configuration
category: coldbox
priority: high
triggers:
  - coldbox configuration
  - ColdBox.cfc
  - application settings
  - environment detection
  - coldbox conventions
  - module settings
---

# ColdBox Configuration

## Overview

ColdBox applications are configured through `config/ColdBox.cfc`. This file controls framework behavior, application settings, conventions, module configuration, and environment-specific settings. Proper configuration ensures optimal performance and maintainability.

## Core Configuration Structure

### Basic ColdBox.cfc (BoxLang)

```boxlang
/**
 * ColdBox.cfc
 * Main application configuration
 */
class {

    function configure() {
        // ColdBox Settings
        coldbox = {
            appName: "My Application",
            appMapping: "/",
            defaultEvent: "main.index",
            reinitPassword: "",
            handlersIndexAutoReload: true,
            customErrorTemplate: "/includes/errors/error.cfm"
        }

        // Application Settings
        settings = {
            // Your application settings
        }

        // Module Settings
        moduleSettings = {
            // Module-specific settings
        }

        // Environment Detection
        environments = {
            development: "localhost,127.0.0.1",
            staging: "staging.example.com",
            production: "example.com"
        }

        // Interceptors
        interceptors = [
            { class: "coldbox.system.interceptors.SES" }
        ]

        // Layouts
        layoutSettings = {
            defaultLayout: "Main.cfm"
        }

        // Handlers
        conventions = {
            handlersLocation: "handlers"
        }
    }
}
```

## ColdBox Settings

### Essential Settings

```boxlang
coldbox = {
    // Application Identity
    appName: "My App",
    appMapping: "/",  // Root mapping

    // Default Event
    defaultEvent: "main.index",  // Landing page event

    // Security
    reinitPassword: getSystemSetting( "REINIT_PASSWORD", "" ),
    reinitKey: "fwreinit",

    // Development Features
    handlersIndexAutoReload: true,  // Auto-reload on changes
    handlerCaching: false,  // Disable caching in development
    eventCaching: false,
    viewCaching: false,

    // Error Handling
    customErrorTemplate: "/includes/errors/error.cfm",
    exceptionEditor: "vscode",  // or "vscode", "sublime", "textmate"

    // Request Handling
    implicitViews: true,  // Automatic view rendering
    caseSensitiveKeys: true,
    invalidEventHandler: "main.onInvalidEvent",
    invalidHTTPMethodHandler: "main.onInvalidHTTPMethod",

    // Flash Scope
    flash: {
        scope: "session",
        properties: {},
        inflateToRC: true,
        inflateToPRC: false,
        autoPurge: true,
        autoSave: true
    }
}
```

### Production Settings

```boxlang
coldbox = {
    appName: "My App",

    // Performance
    handlersIndexAutoReload: false,
    handlerCaching: true,
    eventCaching: true,
    viewCaching: true,

    // Security
    reinitPassword: getSystemSetting( "REINIT_PASSWORD" ),

    // Error Handling
    customErrorTemplate: "/includes/errors/error.cfm",
    exceptionEditor: ""  // Disable in production
}
```

## Application Settings

### Custom Application Settings

```boxlang
settings = {
    // General
    siteName: "My Application",
    siteURL: getSystemSetting( "SITE_URL", "http://localhost:8080" ),

    // Features
    registrationEnabled: true,
    maintenanceMode: false,

    // Pagination
    defaultPageSize: 25,
    maxPageSize: 100,

    // Upload Settings
    maxUploadSize: 5242880,  // 5MB
    allowedExtensions: "jpg,png,pdf,doc,docx",
    uploadPath: expandPath( "/uploads" ),

    // Email
    emailFrom: getSystemSetting( "EMAIL_FROM", "noreply@example.com" ),
    emailSupport: "support@example.com",

    // External Services
    apiBaseURL: getSystemSetting( "API_URL", "https://api.example.com" ),
    apiKey: getSystemSetting( "API_KEY", "" ),

    // Database
    dsn: getSystemSetting( "DB_DSN", "myapp" ),

    // Cache
    defaultCacheTimeout: 60,  // minutes

    // Logging
    logLevel: "INFO",
    logPath: expandPath( "/logs" )
}
```

### Accessing Settings

```boxlang
class extends="coldbox.system.EventHandler" {

    function index( event, rc, prc ) {
        // Get single setting
        var siteName = getSetting( "siteName" )

        // Get with default
        var pageSize = getSetting( "defaultPageSize", 25 )

        // Check if setting exists
        if ( settingExists( "apiKey" ) ) {
            var apiKey = getSetting( "apiKey" )
        }

        // Get ColdBox setting
        var appName = getApplicationSettings().name

        // Get all settings
        var allSettings = getSettings()
    }
}
```

## Environment Detection

### Configuring Environments

```boxlang
function configure() {
    coldbox = {
        appName: "My App"
    }

    // Environment patterns
    environments = {
        development: "localhost,127.0.0.1,dev.example.com",
        staging: "staging.example.com,stg.example.com",
        production: "example.com,www.example.com"
    }
}

// Environment-specific configuration
function development() {
    coldbox.handlersIndexAutoReload = true
    coldbox.handlerCaching = false
    coldbox.eventCaching = false
    coldbox.viewCaching = false

    settings.logLevel = "DEBUG"
    settings.showDebugger = true
}

function staging() {
    coldbox.handlersIndexAutoReload = false
    coldbox.handlerCaching = true

    settings.logLevel = "INFO"
    settings.showDebugger = true
}

function production() {
    coldbox.handlersIndexAutoReload = false
    coldbox.handlerCaching = true
    coldbox.eventCaching = true
    coldbox.viewCaching = true

    settings.logLevel = "WARN"
    settings.showDebugger = false
}
```

### Using Environment Variables

```boxlang
function configure() {
    settings = {
        // Database
        dsn: getSystemSetting( "DB_NAME", "myapp" ),
        dbHost: getSystemSetting( "DB_HOST", "localhost" ),
        dbPort: getSystemSetting( "DB_PORT", "3306" ),
        dbUser: getSystemSetting( "DB_USER", "root" ),
        dbPassword: getSystemSetting( "DB_PASSWORD", "" ),

        // Redis
        redisHost: getSystemSetting( "REDIS_HOST", "localhost" ),
        redisPort: getSystemSetting( "REDIS_PORT", "6379" ),

        // AWS
        awsAccessKey: getSystemSetting( "AWS_ACCESS_KEY_ID", "" ),
        awsSecretKey: getSystemSetting( "AWS_SECRET_ACCESS_KEY", "" ),
        awsRegion: getSystemSetting( "AWS_REGION", "us-east-1" ),

        // External APIs
        stripePublicKey: getSystemSetting( "STRIPE_PUBLIC_KEY", "" ),
        stripeSecretKey: getSystemSetting( "STRIPE_SECRET_KEY", "" )
    }
}
```

## Module Settings

### Configuring Modules

```boxlang
moduleSettings = {
    // CBSecurity
    cbsecurity: {
        authentication: {
            provider: "authenticationService@cbauth"
        },
        firewall: {
            autoLoadFirewall: true,
            rules: [
                {
                    secureList: "admin",
                    securelist: "admin.*",
                    roles: "admin"
                }
            ]
        }
    },

    // CBAuth
    cbauth: {
        userServiceClass: "UserService"
    },

    // CBORM
    cborm: {
        inject: {
            entityInjection: true
        }
    },

    // CBValidation
    cbvalidation: {
        sharedConstraints: {
            email: { required: true, type: "email" },
            password: { required: true, minLength: 8 }
        }
    },

    // CBMailServices
    cbmailservices: {
        protocol: {
            class: "cbmailservices.models.protocols.SMTPProtocol",
            properties: {
                host: getSystemSetting( "MAIL_HOST", "localhost" ),
                port: getSystemSetting( "MAIL_PORT", "25" ),
                username: getSystemSetting( "MAIL_USERNAME", "" ),
                password: getSystemSetting( "MAIL_PASSWORD", "" )
            }
        }
    },

    // Custom Module
    myModule: {
        enabled: true,
        apiEndpoint: getSetting( "apiBaseURL" ),
        timeout: 30
    }
}
```

## Conventions

### Directory Conventions

```boxlang
conventions = {
    handlersLocation: "handlers",
    viewsLocation: "views",
    layoutsLocation: "layouts",
    modelsLocation: "models",
    includesLocation: "includes",
    modulesLocation: "modules",

    // Event Handling
    eventAction: "index",

    // Handler Conventions
    handlersExternalLocationURLBase: "",
    handlersExternalLocation: "",

    // Model Conventions
    modelsExternalLocation: "",
    modelsExternalLocationURLBase: ""
}
```

### Custom Conventions

```boxlang
conventions = {
    // Custom handler locations
    handlersLocation: "app/handlers",

    // Custom view location
    viewsLocation: "app/views",

    // Custom layouts
    layoutsLocation: "app/layouts",

    // Custom models
    modelsLocation: "app/models",

    // External locations (for shared code)
    modelsExternalLocation: "/shared/models",
    handlersExternalLocation: "/shared/handlers"
}
```

## Interceptors

### Registering Interceptors

```boxlang
interceptors = [
    // SES Routing
    { class: "coldbox.system.interceptors.SES" },

    // Security
    { class: "interceptors.SecurityInterceptor" },

    // Logging
    {
        class: "interceptors.RequestLogger",
        properties: {
            logPath: expandPath( "/logs/requests" )
        }
    },

    // Performance
    {
        class: "interceptors.PerformanceMonitor",
        properties: {
            enabled: getSetting( "environment" ) != "production"
        }
    }
]
```

## Layouts

### Layout Configuration

```boxlang
layoutSettings = {
    defaultLayout: "Main.cfm",
    defaultView: ""
}

// Layout-Event assignments
layouts = [
    { name: "login.cfm", file: "layouts/Login.cfm", views: "security" },
    { name: "admin.cfm", file: "layouts/Admin.cfm", views: "admin" },
    { name: "popup.cfm", file: "layouts/Popup.cfm", views: "popups" }
]
```

## Event Caching

### Cache Configuration

```boxlang
coldbox = {
    // Event Caching
    eventCaching: true,
    eventCacheStorage: "template",  // or "ram"

    // View Caching
    viewCaching: true
}

// Cache Settings via CacheBox
cacheBox = {
    defaultCache: {
        provider: "coldbox.system.cache.providers.CacheBoxColdBoxProvider",
        properties: {
            objectDefaultTimeout: 60,
            objectDefaultLastAccessTimeout: 30,
            reapFrequency: 5,
            maxObjects: 500,
            freeMemoryPercentageThreshold: 0,
            useLastAccessTimeouts: true
        }
    }
}
```

## WireBox Configuration

### DI Configuration

```boxlang
wireBox = {
    singletonReload: true,  // Development only

    // Bindings
    bindings: {
        "UserService": { path: "models.UserService", scope: "singleton" },
        "ILogger": { path: "models.MyLogger" }
    },

    // Scan Locations
    scanLocations: [
        "models"
    ],

    // Stop Recursion
    stopRecursions: [
        "coldbox"
    ]
}
```

## LogBox Configuration

### Logging Configuration

```boxlang
logBox = {
    // Root logger
    appenders: {
        console: { class: "coldbox.system.logging.appenders.ConsoleAppender" },

        files: {
            class: "coldbox.system.logging.appenders.RollingFileAppender",
            properties: {
                filePath: expandPath( "/logs" ),
                fileName: "app",
                autoExpand: true,
                fileMaxSize: 3000,
                fileMaxArchives: 5
            }
        }
    },

    // Root logger configuration
    root: {
        levelMin: "FATAL",
        levelMax: "DEBUG",
        appenders: "*"
    },

    // Category loggers
    categories: {
        "handlers": { levelMin: "INFO" },
        "models": { levelMin: "DEBUG" },
        "interceptors.Security": { levelMin: "WARN", appenders: "files" }
    }
}
```

## Best Practices

### Design Guidelines

1. **Use Environment Variables**: Never hardcode credentials
2. **Environment-Specific Config**: Use environment functions
3. **Modular Settings**: Group related settings
4. **Document Settings**: Add comments for complex configurations
5. **Default Values**: Always provide sensible defaults
6. **Security First**: Never commit secrets
7. **Performance Tuning**: Disable caching in development
8. **Module Configuration**: Centralize module settings
9. **Convention Over Configuration**: Use ColdBox conventions
10. **Testing Configuration**: Create test-specific settings

### Common Patterns

```boxlang
// ✅ Good: Environment variables with defaults
settings = {
    apiKey: getSystemSetting( "API_KEY", "" ),
    timeout: getSystemSetting( "API_TIMEOUT", 30 )
}

// ✅ Good: Environment-specific configuration
function development() {
    coldbox.handlerCaching = false
    settings.debugMode = true
}

function production() {
    coldbox.handlerCaching = true
    settings.debugMode = false
}

// ✅ Good: Modular settings
settings = {
    email: {
        from: getSystemSetting( "EMAIL_FROM" ),
        replyTo: getSystemSetting( "EMAIL_REPLY_TO" )
    },
    upload: {
        maxSize: 5242880,
        allowedTypes: "jpg,png,pdf"
    }
}
```

## Common Pitfalls

### Pitfalls to Avoid

1. **Hardcoded Credentials**: Storing secrets in config
2. **No Environment Detection**: Same config for dev/prod
3. **Missing Defaults**: No fallback values
4. **Over-complication**: Too many settings
5. **No Documentation**: Unclear setting purposes
6. **Cache in Development**: Caching enabled during dev
7. **Ignoring Conventions**: Custom paths unnecessarily
8. **Module Config Errors**: Incorrect module settings
9. **Performance Issues**: Wrong cache settings
10. **Security Risks**: Exposing sensitive data

### Anti-Patterns

```boxlang
// ❌ Bad: Hardcoded credentials
settings = {
    apiKey: "abc123"  // Never do this!
}

// ✅ Good: Environment variable
settings = {
    apiKey: getSystemSetting( "API_KEY", "" )
}

// ❌ Bad: No environment detection
coldbox = {
    handlerCaching: false  // Always false
}

// ✅ Good: Environment-specific
function production() {
    coldbox.handlerCaching = true
}

// ❌ Bad: No defaults
settings = {
    timeout: getSystemSetting( "TIMEOUT" )  // Fails if not set
}

// ✅ Good: With default
settings = {
    timeout: getSystemSetting( "TIMEOUT", 30 )
}
```

## Related Skills

- [Handler Development](handler-development.md) - Handler patterns
- [Module Development](module-development.md) - Module creation
- [Interceptor Development](interceptor-development.md) - Interceptor patterns
- [Event Model](event-model.md) - Event-driven architecture

## References

- [ColdBox Configuration](https://coldbox.ortusbooks.com/getting-started/configuration)
- [Environment Detection](https://coldbox.ortusbooks.com/getting-started/configuration/coldbox.cfc/configuration-directives/environments)
- [Module Configuration](https://coldbox.ortusbooks.com/hmvc/modules)
