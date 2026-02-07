# WireBox Dependency Injection Guidelines

## Overview

WireBox is ColdBox's dependency injection and AOP (Aspect-Oriented Programming) framework. It manages object lifecycles, resolves dependencies automatically, and provides advanced features like AOP, virtual inheritance, and object mocking.

## Dependency Injection Basics

### Property Injection (Recommended)

```boxlang
class UserService {
    // Auto-discovery by name
    property name="userDAO" inject;
    
    // Explicit mapping
    property name="userDAO" inject="UserDAO";
    
    // By ID
    property name="userDAO" inject="id:UserDAO";
    
    // By DSL (Domain Specific Language)
    property name="cache" inject="cachebox:default";
    property name="log" inject="logbox:logger:{this}";
    property name="settings" inject="coldbox:setting:mySettings";
    property name="wirebox" inject="wirebox";
}
```

### Constructor Injection

```boxlang
class UserService {
    variables.userDAO = ""
    
    function init( required userDAO inject="UserDAO" ) {
        variables.userDAO = arguments.userDAO
        return this
    }
}
```

### Setter Injection

```boxlang
class UserService {
    property name="userDAO";
    
    function setUserDAO( required userDAO ) inject="UserDAO" {
        variables.userDAO = arguments.userDAO
        return this
    }
}
```

## Injection DSL

WireBox provides a powerful DSL for injecting various types of objects and values.

### Model Injection

```boxlang
// By name (auto-discovery in /models)
property name="userService" inject;

// By path
property name="userService" inject="models.services.UserService";

// By ID
property name="userService" inject="id:UserService";

// By provider (get a provider that returns the instance)
property name="userProvider" inject="provider:UserService";
```

### CacheBox DSL

```boxlang
// Inject default cache
property name="cache" inject="cachebox:default";

// Inject named cache
property name="cache" inject="cachebox:template";
property name="apiCache" inject="cachebox:api";

// Inject CacheBox factory
property name="cacheFactory" inject="cachebox";
```

### LogBox DSL

```boxlang
// Inject logger for this class
property name="log" inject="logbox:logger:{this}";

// Inject named logger
property name="log" inject="logbox:logger:myapp.security";

// Inject root logger
property name="log" inject="logbox:root";

// Inject LogBox factory
property name="logBox" inject="logbox";
```

### ColdBox DSL

```boxlang
// Inject ColdBox controller
property name="controller" inject="coldbox";

// Inject application settings
property name="appName" inject="coldbox:setting:appName";
property name="dsn" inject="coldbox:setting:datasource";

// Inject config structures
property name="settings" inject="coldbox:configSettings";
property name="coldboxSettings" inject="coldbox:coldboxSettings";

// Inject flash scope
property name="flash" inject="coldbox:flash";

// Inject interceptor service
property name="interceptorService" inject="coldbox:interceptorService";

// Inject request context
property name="requestContext" inject="coldbox:requestContext";

// Inject renderer
property name="renderer" inject="coldbox:renderer";
```

### WireBox DSL

```boxlang
// Inject WireBox injector
property name="wirebox" inject="wirebox";

// Inject binder
property name="binder" inject="wirebox:binder";

// Inject event manager
property name="eventManager" inject="wirebox:eventManager";

// Inject populator
property name="populator" inject="wirebox:populator";
```

### Java DSL

```boxlang
// Inject Java classes
property name="system" inject="java:java.lang.System";
property name="stringBuilder" inject="java:java.lang.StringBuilder";
```

### EntityService DSL (ORM)

```boxlang
// Inject entity service for specific entity
property name="userService" inject="entityService:User";
property name="orderService" inject="entityService:Order";
```

## Object Scopes

Control the lifecycle of your objects with scopes.

### Available Scopes

```boxlang
// Transient (default) - New instance every time
@scope="transient"
class TransientService {}

// Singleton - One instance for application lifetime
@scope="singleton"
class ConfigService {}

// Request - One instance per request
@scope="request"
class RequestService {}

// Session - One instance per session
@scope="session"
class UserSession {}

// Cache - Cached instance (with timeout)
@scope="cachebox"
class CachedService {}

// Server - One instance in server scope
@scope="server"
class ServerWideService {}
```

### Scope Examples

```boxlang
// Singleton service
component singleton {
    property name="configData";
    
    function init() {
        variables.configData = loadConfig()
        return this
    }
}

// Request-scoped service
@scope="request"
class RequestLogger {
    property name="logs" type="array";
    
    function init() {
        variables.logs = []
        return this
    }
    
    function addLog( required string message ) {
        variables.logs.append( message )
    }
}
```

## Binder Configuration

Configure WireBox mappings in `config/WireBox.cfc`:

```boxlang
component extends="coldbox.system.ioc.config.Binder" {
    function configure() {
        // Map by convention (models folder auto-scanned)
        mapDirectory( "models" )
        
        // Map with explicit configuration
        map( "UserService" )
            .to( "models.services.UserService" )
            .asSingleton()
        
        map( "UserDAO" )
            .to( "models.dao.UserDAO" )
            .initArg( name="datasource", value="myDB" )
        
        // Map interface to implementation
        map( "IUserService" )
            .to( "models.services.UserServiceImpl" )
            .asSingleton()
        
        // Map with constructor arguments
        map( "MailService" )
            .to( "models.MailService" )
            .initArg( name="host", value="smtp.example.com" )
            .initArg( name="port", value=587 )
            .asSingleton()
        
        // Map with property injection
        map( "OrderService" )
            .to( "models.OrderService" )
            .property( name="taxRate", value=0.08 )
            .property( name="cache", dsl="cachebox:default" )
        
        // Map with provider
        map( "DatabaseConnection" )
            .toProvider( "models.providers.DatabaseProvider" )
            .asSingleton()
        
        // Map with factory method
        map( "Config" )
            .toFactoryMethod( "models.ConfigFactory", "create" )
            .asSingleton()
        
        // Map with virtual inheritance
        mapPath( "models.BaseService" )
            .asVirtualInheritance()
    }
}
```

## Provider Pattern

Providers delay object creation until it's actually needed.

### Using Providers

```boxlang
class OrderService {
    // Inject provider instead of instance
    property name="userServiceProvider" inject="provider:UserService";
    
    function processOrder( required numeric userId ) {
        // Get instance when needed
        var userService = userServiceProvider.get()
        var user = userService.getById( userId )
        
        // Process order...
    }
}
```

### Creating Custom Providers

```boxlang
class DatabaseProvider {
    function get() {
        // Create and return database connection
        var connection = new models.DatabaseConnection()
        connection.connect( 
            host = getSetting( "dbHost" ),
            database = getSetting( "dbName" )
        )
        return connection
    }
}
```

## Object Populator

WireBox includes an object populator for filling objects from structs, JSON, XML, or queries.

### Populating Objects

```boxlang
class UserService {
    property name="populator" inject="wirebox:populator";
    property name="wirebox" inject="wirebox";
    
    function create( required struct data ) {
        // Create empty instance
        var user = wirebox.getInstance( "User" )
        
        // Populate from struct
        populator.populateFromStruct( 
            target = user,
            memento = arguments.data,
            exclude = "id,createdDate"
        )
        
        return user.save()
    }
    
    function createFromJSON( required string json ) {
        var user = wirebox.getInstance( "User" )
        
        // Populate from JSON
        populator.populateFromJSON( 
            target = user,
            JSONString = arguments.json
        )
        
        return user
    }
}
```

### Populate Methods

```boxlang
// From struct
populator.populateFromStruct( target, memento, exclude, include )

// From JSON
populator.populateFromJSON( target, JSONString, exclude, include )

// From XML
populator.populateFromXML( target, xml, exclude, include )

// From query (specific row)
populator.populateFromQuery( target, qry, rowNumber, exclude, include )

// From query to array of objects
var users = populator.populateFromQueryWithPrefix( 
    target = "User",
    qry = qUsers,
    prefix = "user_"
)
```

## AOP (Aspect-Oriented Programming)

Add cross-cutting concerns without modifying original code.

### Method Interception

```boxlang
// In WireBox.cfc binder
map( "UserService" )
    .to( "models.UserService" )
    .asSingleton()
    .withAOP()
    .aspect( "LoggingAspect" )

// Create aspect
class LoggingAspect {
    property name="log" inject="logbox:logger:{this}";
    
    function around( invocation ) {
        var method = invocation.getMethod()
        var args = invocation.getArgs()
        
        log.debug( "Before: #method#" )
        var startTime = getTickCount()
        
        try {
            var result = invocation.proceed()
            log.debug( "After: #method# (#getTickCount() - startTime#ms)" )
            return result
        } catch ( any e ) {
            log.error( "Exception in #method#", e )
            rethrow
        }
    }
}
```

## Virtual Inheritance

Allow WireBox to automatically extend base classes for you.

```boxlang
// In config/WireBox.cfc
mapPath( "models.BaseModel" )
    .asVirtualInheritance()

// Your models can omit extends
class User {
    // No extends needed - WireBox adds it automatically
    property name="id";
    property name="email";
}
```

## getInstance() Methods

Get instances programmatically when property injection isn't possible.

```boxlang
// Basic getInstance
var userService = getInstance( "UserService" )

// With init arguments
var service = getInstance(
    name = "MailService",
    initArguments = { host: "smtp.example.com" }
)

// With DSL
var cache = getInstance( dsl = "cachebox:default" )
var log = getInstance( dsl = "logbox:logger:myapp" )

// Check if instance exists
if ( wirebox.containsInstance( "UserService" ) ) {
    var service = wirebox.getInstance( "UserService" )
}

// Get all instances of a type
var services = wirebox.getInstancesByType( "IService" )
```

## Event Model

Listen to WireBox lifecycle events.

### Available Events

```boxlang
// Object lifecycle
beforeInstanceCreation
afterInstanceCreation
beforeInstanceAutowire
afterInstanceAutowire

// Injection
beforeInstanceInject
afterInstanceInject
```

### Listening to Events

```boxlang
// In Interceptor
function afterInstanceCreation( event, interceptData ) {
    var mapping = interceptData.mapping
    var target = interceptData.target
    
    log.debug( "Created: #mapping.getName()#" )
}
```

## Best Practices

- **Use property injection** - Cleaner and more maintainable than manual getInstance() calls
- **Leverage DSL** - Use appropriate DSL for framework components
- **Singleton by default for services** - Stateless services should be singletons
- **Use providers for expensive objects** - Delay creation until actually needed
- **Use request scope for stateful services** - Anything tied to a specific request
- **Map interfaces to implementations** - Enables easy swapping of implementations
- **Use AOP for cross-cutting concerns** - Logging, security, caching, transactions
- **Virtual inheritance for base classes** - Cleaner code without explicit extends

## Documentation

For complete WireBox documentation, advanced AOP, and mapping strategies, consult the WireBox MCP server or visit:
https://wirebox.ortusbooks.com
