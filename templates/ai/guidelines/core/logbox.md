# LogBox Logging Guidelines

## Overview

LogBox is ColdBox's enterprise logging and messaging framework. It provides flexible, extensible logging with multiple appenders, severity levels, and categories.

## Getting a Logger

### Injection (Recommended)

```boxlang
// In handlers, models, or any WireBox-managed object
property name="log" inject="logbox:logger:{this}";

// Named category logger
property name="log" inject="logbox:logger:myapp.security";

// Root logger
property name="log" inject="logbox:root";
```

### Manual Retrieval

```boxlang
var log = logBox.getLogger( this );
var log = logBox.getLogger( "myapp.security" );
var log = logBox.getRootLogger();
```

## Logging Methods

```boxlang
// Severity levels (from most to least severe)
log.fatal( "Critical system failure", extraInfo )
log.error( "An error occurred", extraInfo )
log.warn( "Warning message", extraInfo )
log.info( "Informational message", extraInfo )
log.debug( "Debug details", extraInfo )

// Check before logging (performance optimization)
if ( log.canDebug() ) {
    log.debug( "Expensive operation: #serializeJSON( complexData )#" )
}
```

## Configuration

Configure LogBox in `config/ColdBox.cfc`:

```boxlang
logBox = {
    // Appenders
    appenders : {
        console : {
            class : "coldbox.system.logging.appenders.ConsoleAppender"
        },
        errorLog : {
            class : "coldbox.system.logging.appenders.FileAppender",
            properties : {
                filePath : "/logs",
                fileName : "errors"
            },
            levelMin : "FATAL",
            levelMax : "ERROR"
        },
        appLog : {
            class : "coldbox.system.logging.appenders.RollingFileAppender",
            properties : {
                filePath : "/logs",
                fileName : "app",
                maxArchives : 5,
                maxFileSize : 2000 // KB
            }
        }
    },

    // Root logger
    root : {
        levelMax : "INFO",
        appenders : "*" // Use all appenders
    },

    // Granular categories
    categories : {
        "coldbox.system" : {
            levelMax : "WARN",
            appenders : "console"
        },
        "myapp.security" : {
            levelMax : "DEBUG",
            appenders : "errorLog,appLog"
        }
    }
}
```

## Severity Levels

- **FATAL (0)** - Critical errors that cause application failure
- **ERROR (1)** - Errors that should be investigated
- **WARN (2)** - Warnings that don't prevent operation
- **INFO (3)** - Informational messages
- **DEBUG (4)** - Detailed debugging information
- **OFF (5)** - Disable logging

## Built-in Appenders

### ConsoleAppender
Logs to system console output.

```boxlang
appenders : {
    console : {
        class : "coldbox.system.logging.appenders.ConsoleAppender"
    }
}
```

### FileAppender
Logs to a single file.

```boxlang
appenders : {
    fileLog : {
        class : "coldbox.system.logging.appenders.FileAppender",
        properties : {
            filePath : "/logs",
            fileName : "app",
            fileEncoding : "UTF-8",
            autoExpand : true
        }
    }
}
```

### RollingFileAppender
Logs to rotating files based on size.

```boxlang
appenders : {
    rollingLog : {
        class : "coldbox.system.logging.appenders.RollingFileAppender",
        properties : {
            filePath : "/logs",
            fileName : "app",
            maxFileSize : 2000, // KB
            maxArchives : 5
        }
    }
}
```

### DBAppender
Logs to a database table.

```boxlang
appenders : {
    dbLog : {
        class : "coldbox.system.logging.appenders.DBAppender",
        properties : {
            dsn : "myDatasource",
            table : "logs",
            columnMap : {
                severity : "severity",
                category : "category",
                logdate : "timestamp",
                message : "message"
            }
        }
    }
}
```

## Best Practices

### Use Conditional Logging

```boxlang
// Good - avoids string building when debug is off
if ( log.canDebug() ) {
    log.debug( "User data: #serializeJSON( userData )#" )
}

// Bad - always builds the string
log.debug( "User data: #serializeJSON( userData )#" )
```

### Use Categories

```boxlang
// Organize logs by functional area
property name="log" inject="logbox:logger:myapp.security";
property name="log" inject="logbox:logger:myapp.payment";
property name="log" inject="logbox:logger:myapp.api";
```

### Include Context with extraInfo

```boxlang
log.error(
    "Payment processing failed",
    {
        userId : event.getValue( "userId" ),
        amount : amount,
        gateway : gatewayName,
        errorCode : result.errorCode
    }
)
```

### Handler/Interceptor Example

```boxlang
class Users extends coldbox.system.EventHandler {
    property name="log" inject="logbox:logger:{this}";
    property name="userService" inject;

    function index( event, rc, prc ) {
        log.info( "Listing users for admin panel" )

        try {
            prc.users = userService.getAll()
            event.setView( "users/index" )
        } catch ( any e ) {
            log.error(
                "Failed to retrieve users",
                { exception : e }
            )
            event.setView( "errors/generic" )
        }
    }
}
```

## Documentation

For complete LogBox documentation and advanced features, consult the LogBox MCP server or visit:
https://logbox.ortusbooks.com
