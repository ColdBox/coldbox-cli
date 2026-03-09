---
name: BoxLang Property Files
description: Complete guide to reading and managing Java properties files and BoxLang configuration files with property loading and management
category: boxlang
priority: medium
triggers:
  - boxlang properties
  - property file
  - config file
  - properties file
  - configuration management
---

# BoxLang Property Files

## Overview

BoxLang provides utilities for reading and managing Java-style properties files (.properties) for configuration management. Properties files store key-value pairs for application settings.

## Core Concepts

### Properties File Format

```properties
# Application settings
app.name=MyApplication
app.version=1.0.0
app.environment=development

# Database configuration
db.host=localhost
db.port=3306
db.name=mydb
db.username=root
db.password=secret

# Feature flags
feature.newUI=true
feature.betaAccess=false
```

## Reading Properties

### Load Properties File

```boxlang
// Load properties
var props = createObject( "java", "java.util.Properties" ).init()
var fileInput = createObject( "java", "java.io.FileInputStream" ).init(
    expandPath( "/config/app.properties" )
)

try {
    props.load( fileInput )
} finally {
    fileInput.close()
}

// Get property values
var appName = props.getProperty( "app.name" )
var dbHost = props.getProperty( "db.host", "localhost" )  // With default

println( "App: #appName#" )
println( "Database: #dbHost#" )
```

### BoxLang Helper Function

```boxlang
/**
 * Load properties file into struct
 */
function loadProperties( required filePath ) {
    if ( !fileExists( filePath ) ) {
        throw( "Properties file not found: #filePath#" )
    }

    var props = createObject( "java", "java.util.Properties" ).init()
    var fileInput = createObject( "java", "java.io.FileInputStream" ).init( filePath )

    try {
        props.load( fileInput )
    } finally {
        fileInput.close()
    }

    // Convert to struct
    var config = {}
    var keys = props.propertyNames()

    while ( keys.hasMoreElements() ) {
        var key = keys.nextElement()
        config[key] = props.getProperty( key )
    }

    return config
}

// Usage
var config = loadProperties( expandPath( "/config/app.properties" ) )
println( config.app_name )
```

## Writing Properties

### Save Properties File

```boxlang
/**
 * Save properties to file
 */
function saveProperties( required filePath, required properties ) {
    var props = createObject( "java", "java.util.Properties" ).init()

    // Add properties
    properties.each( ( key, value ) => {
        props.setProperty( key, toString( value ) )
    } )

    // Save to file
    var fileOutput = createObject( "java", "java.io.FileOutputStream" ).init( filePath )

    try {
        props.store( fileOutput, "Application Configuration" )
    } finally {
        fileOutput.close()
    }
}

// Usage
saveProperties(
    expandPath( "/config/app.properties" ),
    {
        "app.name": "MyApp",
        "app.version": "1.0.0",
        "db.host": "localhost"
    }
)
```

## Configuration Management

### Configuration Service

```boxlang
/**
 * models/ConfigService.cfc
 */
class singleton {

    variables.config = {}
    variables.filePath = ""

    /**
     * Initialize from properties file
     */
    function init( required filePath ) {
        variables.filePath = arguments.filePath
        reload()
        return this
    }

    /**
     * Load/reload configuration
     */
    function reload() {
        variables.config = loadPropertiesFile( filePath )
    }

    /**
     * Get configuration value
     */
    function get( required key, defaultValue = "" ) {
        return config.keyExists( key ) ? config[key] : defaultValue
    }

    /**
     * Set configuration value
     */
    function set( required key, required value ) {
        config[key] = value
    }

    /**
     * Save configuration
     */
    function save() {
        savePropertiesFile( filePath, config )
    }

    /**
     * Get all configuration
     */
    function getAll() {
        return config.copy()
    }

    /**
     * Check if key exists
     */
    function has( required key ) {
        return config.keyExists( key )
    }

    private function loadPropertiesFile( path ) {
        var props = createObject( "java", "java.util.Properties" ).init()
        var input = createObject( "java", "java.io.FileInputStream" ).init( path )

        try {
            props.load( input )

            var result = {}
            var keys = props.propertyNames()

            while ( keys.hasMoreElements() ) {
                var key = keys.nextElement()
                result[key] = props.getProperty( key )
            }

            return result

        } finally {
            input.close()
        }
    }

    private function savePropertiesFile( path, data ) {
        var props = createObject( "java", "java.util.Properties" ).init()

        data.each( ( key, value ) => {
            props.setProperty( key, toString( value ) )
        } )

        var output = createObject( "java", "java.io.FileOutputStream" ).init( path )

        try {
            props.store( output, "Generated Configuration" )
        } finally {
            output.close()
        }
    }
}
```

### Usage in Application

```boxlang
/**
 * Application.bx
 */
class {

    this.name = "MyApp"

    function onApplicationStart() {
        // Load configuration
        application.config = new models.ConfigService(
            expandPath( "/config/app.properties" )
        )

        // Set app name from config
        this.name = application.config.get( "app.name", "MyApp" )

        // Configure datasource from properties
        this.datasource = application.config.get( "db.name" )

        this.datasources = {
            "#this.datasource#": {
                class: application.config.get( "db.driver" ),
                connectionString: buildConnectionString(),
                username: application.config.get( "db.username" ),
                password: application.config.get( "db.password" )
            }
        }
    }

    private function buildConnectionString() {
        var host = application.config.get( "db.host", "localhost" )
        var port = application.config.get( "db.port", "3306" )
        var name = application.config.get( "db.name" )

        return "jdbc:mysql://#host#:#port#/#name#"
    }
}
```

## Environment-Specific Configuration

### Multi-Environment Setup

```boxlang
/**
 * Load environment-specific properties
 */
function loadConfig() {
    var environment = getEnvironment()

    // Load base config
    var config = loadProperties( expandPath( "/config/app.properties" ) )

    // Load environment overrides
    var envFile = expandPath( "/config/app.#environment#.properties" )

    if ( fileExists( envFile ) ) {
        var envConfig = loadProperties( envFile )
        config.append( envConfig )
    }

    return config
}

function getEnvironment() {
    // Check environment variable
    var env = getEnv( "APP_ENV" )

    if ( env.len() > 0 ) {
        return env
    }

    // Detect from hostname
    var host = cgi.server_name

    if ( host.findNoCase( "localhost" ) > 0 ) {
        return "development"
    } else if ( host.findNoCase( "staging" ) > 0 ) {
        return "staging"
    } else {
        return "production"
    }
}
```

### Configuration Files

```properties
# config/app.properties (base)
app.name=MyApp
app.debug=false

# config/app.development.properties
app.debug=true
db.host=localhost
db.name=myapp_dev

# config/app.production.properties
app.debug=false
db.host=prod-db.example.com
db.name=myapp_prod
```

## Advanced Patterns

### Nested Properties

```boxlang
/**
 * Parse nested properties into struct
 */
function parseNestedProperties( properties ) {
    var result = {}

    properties.each( ( key, value ) => {
        var parts = key.listToArray( "." )
        var current = result

        for ( var i = 1; i <= parts.len() - 1; i++ ) {
            var part = parts[i]

            if ( !current.keyExists( part ) ) {
                current[part] = {}
            }

            current = current[part]
        }

        current[ parts.last() ] = value
    } )

    return result
}

// Convert flat properties to nested struct
var flat = {
    "database.host": "localhost",
    "database.port": "3306",
    "database.name": "mydb",
    "cache.enabled": "true",
    "cache.timeout": "60"
}

var nested = parseNestedProperties( flat )
// {
//     database: {
//         host: "localhost",
//         port: "3306",
//         name: "mydb"
//     },
//     cache: {
//         enabled: "true",
//         timeout: "60"
//     }
// }
```

### Type Conversion

```boxlang
/**
 * Get typed property values
 */
class {

    variables.config = {}

    function getString( required key, defaultValue = "" ) {
        return get( key, defaultValue )
    }

    function getInt( required key, defaultValue = 0 ) {
        var value = get( key, defaultValue )
        return isNumeric( value ) ? val( value ) : defaultValue
    }

    function getBoolean( required key, defaultValue = false ) {
        var value = lCase( get( key, defaultValue ) )
        return listFindNoCase( "true,yes,1", value ) > 0
    }

    function getList( required key, delimiter = ",", defaultValue = [] ) {
        var value = get( key, "" )
        return value.len() > 0 ? value.listToArray( delimiter ) : defaultValue
    }
}

// Usage
var port = config.getInt( "db.port", 3306 )
var debug = config.getBoolean( "app.debug", false )
var admins = config.getList( "app.admins", "," )
```

## Best Practices

### Design Guidelines

1. **Environment Variables**: Use for sensitive data
2. **Defaults**: Provide sensible defaults
3. **Validation**: Validate configuration values
4. **Documentation**: Comment property files
5. **Version Control**: Track config files (exclude secrets)
6. **Reloading**: Support runtime reloading
7. **Type Safety**: Convert to appropriate types
8. **Namespacing**: Use dotted notation
9. **Immutability**: Make configs read-only after load
10. **Error Handling**: Handle missing files gracefully

### Common Patterns

```boxlang
// ✅ Good: Environment variables for secrets
db.host=${DB_HOST:localhost}
db.password=${DB_PASSWORD}

// ✅ Good: Defaults
var port = config.get( "server.port", 8080 )

// ✅ Good: Validation
if ( !config.has( "db.host" ) ) {
    throw( "Database host not configured" )
}
```

## Common Pitfalls

### Pitfalls to Avoid

1. **Hardcoded Secrets**: Passwords in properties
2. **No Defaults**: Missing fallback values
3. **No Validation**: Invalid configuration
4. **Global State**: Mutable global config
5. **No Error Handling**: Silent failures
6. **Type Mismatches**: String vs number confusion
7. **No Documentation**: Unclear properties
8. **Overwriting**: Lost configuration
9. **No Versioning**: Breaking changes
10. **Missing Files**: No fallback

### Anti-Patterns

```boxlang
// ❌ Bad: Hardcoded password
db.password=secret123

// ✅ Good: Environment variable
db.password=${DB_PASSWORD}

// ❌ Bad: No default
var port = config.get( "server.port" )  // Could be empty

// ✅ Good: With default
var port = config.get( "server.port", 8080 )

// ❌ Bad: No validation
var port = config.get( "server.port" )
// Could be non-numeric

// ✅ Good: Validate
var port = config.getInt( "server.port", 8080 )
if ( port < 1 || port > 65535 ) {
    throw( "Invalid port: #port#" )
}
```

## Related Skills

- [BoxLang File Handling](boxlang-file-handling.md) - File operations
- [BoxLang Application.bx](boxlang-application.md) - Application configuration
- [ColdBox Configuration](../coldbox/coldbox-configuration.md) - ColdBox settings

## References

- [Java Properties Documentation](https://docs.oracle.com/en/java/javase/11/docs/api/java.base/java/util/Properties.html)
- [12 Factor App Configuration](https://12factor.net/config)
- [Configuration Management Best Practices](https://www.redhat.com/en/topics/automation/what-is-configuration-management)
