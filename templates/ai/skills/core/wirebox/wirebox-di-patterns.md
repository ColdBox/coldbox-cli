---
name: WireBox DI Patterns
description: Complete guide to WireBox dependency injection, binder DSL, object scopes, providers, AOP, and advanced DI patterns
category: wirebox
priority: high
triggers:
  - wirebox
  - dependency injection
  - DI
  - injection
  - binder
  - provider
  - AOP
  - aspect oriented
---

# WireBox DI Patterns

## Overview

WireBox is ColdBox's enterprise dependency injection and AOP framework providing constructor, setter, and property injection with powerful object lifecycle management. Proper DI reduces coupling and improves testability.

## Core Concepts

### WireBox Architecture

- **Injector**: Object factory and DI container
- **Binder**: DSL for configuring dependencies
- **Scopes**: Object lifecycle management (singleton, transient, request, session)
- **Providers**: Lazy-loaded dependencies
- **AOP**: Aspect-oriented programming (interceptors)

## Basic Injection

### Property Injection

```boxlang
/**
 * UserService.cfc
 */
class singleton {

    // Basic injection
    property name="userDAO" inject="UserDAO"

    // ID injection
    property name="settings" inject="coldbox:setting:applicationSettings"

    // Provider injection
    property name="mailService" inject="provider:MailService"

    // LogBox injection
    property name="log" inject="logbox:logger:{this}"

    // CacheBox injection
    property name="cache" inject="cachebox:default"

    function list() {
        return userDAO.list()
    }
}
```

### Constructor Injection

```boxlang
/**
 * OrderService.cfc
 */
class singleton {

    property name="orderDAO"
    property name="paymentService"
    property name="log"

    function init(
        required orderDAO,
        required paymentService,
        required log inject="logbox:logger:{this}"
    ) {
        variables.orderDAO = arguments.orderDAO
        variables.paymentService = arguments.paymentService
        variables.log = arguments.log

        return this
    }

    function create( order ) {
        log.info( "Creating order" )
        return orderDAO.create( order )
    }
}
```

### Setter Injection

```boxlang
/**
 * ReportService.cfc
 */
class singleton {

    property name="reportDAO"

    function setReportDAO( required reportDAO ) {
        variables.reportDAO = arguments.reportDAO
        return this
    }

    function generate() {
        return reportDAO.generateReport()
    }
}
```

## Injection DSL

### Common Injection Types

```boxlang
class {

    // Model injection
    property name="userService" inject="UserService"

    // ID injection (namespace)
    property name="service" inject="id:MyService"

    // Model with ID
    property name="dao" inject="model:UserDAO"

    // ColdBox setting
    property name="dsn" inject="coldbox:setting:datasource"

    // ColdBox interceptor
    property name="security" inject="coldbox:interceptor:Security"

    // Module setting
    property name="apiKey" inject="coldbox:moduleSettings:mymodule:apiKey"

    // LogBox logger
    property name="log" inject="logbox:logger:{this}"
    property name="rootLogger" inject="logbox:root"

    // CacheBox cache
    property name="cache" inject="cachebox:default"
    property name="queryCache" inject="cachebox:query"

    // Provider (lazy loading)
    property name="mailService" inject="provider:MailService"

    // EntityService (ORM)
    property name="userService" inject="entityService:User"
}
```

### ColdBox Injections

```boxlang
class extends="coldbox.system.EventHandler" {

    // Controller
    property name="controller" inject="coldbox"

    // Request service
    property name="requestService" inject="coldbox:requestService"

    // Renderer
    property name="renderer" inject="coldbox:renderer"

    // Flash RAM
    property name="flash" inject="coldbox:flash"

    // Data marshaller
    property name="marshaller" inject="coldbox:dataMarshaller"

    // Event pool
    property name="eventPool" inject="coldbox:eventPool"
}
```

## Binder Configuration

### config/WireBox.cfc

```boxlang
/**
 * config/WireBox.cfc
 */
class {

    function configure() {
        // Map DSL
        map( "UserService" )
            .to( "models.services.UserService" )
            .asSingleton()

        // Map with init arguments
        map( "PaymentGateway" )
            .to( "models.gateways.StripeGateway" )
            .asSingleton()
            .initWith( apiKey: "${STRIPE_KEY}" )

        // Map interface to implementation
        map( "IUserService" )
            .to( "models.services.UserService" )

        // Map to value
        map( "dsn" )
            .toValue( "mydsn" )

        // Map to factory method
        map( "S3Client" )
            .toFactoryMethod( "AWSFactory", "createS3Client" )

        // Map with provider
        map( "ExpensiveService" )
            .to( "models.ExpensiveService" )
            .asProvider()

        // Map with virtual inheritance
        map( "BaseService" )
            .to( "models.BaseService" )
            .virtualInheritance( "UserService" )

        // Parent settings
        parentInjector( wirebox )

        // Scope registration
        scopeRegistration = {
            enabled: true,
            scope: "application",
            key: "wirebox"
        }

        // Custom DSL
        customDSL = {
            myDSL: "models.MyCustomDSL"
        }
    }
}
```

### Binder DSL Methods

```boxlang
function configure() {

    // Basic mapping
    map( "UserService" )
        .to( "models.UserService" )

    // Singleton scope
    map( "UserService" )
        .to( "models.UserService" )
        .asSingleton()

    // Transient scope (new instance each time)
    map( "UserDTO" )
        .to( "models.UserDTO" )
        .asTransient()

    // No scope (new instance)
    map( "TempService" )
        .to( "models.TempService" )
        .noScope()

    // Request scope
    map( "RequestService" )
        .to( "models.RequestService" )
        .intoRequestScope()

    // Session scope
    map( "CartService" )
        .to( "models.CartService" )
        .intoSessionScope()

    // Cache scope
    map( "ConfigService" )
        .to( "models.ConfigService" )
        .intoCacheBox( "default", 60 )

    // Init arguments
    map( "MailService" )
        .to( "models.MailService" )
        .initWith(
            server: "smtp.gmail.com",
            port: 587
        )

    // Init argument DSL
    map( "UserService" )
        .to( "models.UserService" )
        .initArg( name: "cache", dsl: "cachebox:default" )

    // Setter injection
    map( "ReportService" )
        .to( "models.ReportService" )
        .setter( name: "logger", dsl: "logbox:logger:{this}" )

    // Property injection
    map( "OrderService" )
        .to( "models.OrderService" )
        .property( name: "log", dsl: "logbox:logger:{this}" )

    // Method injection (after creation)
    map( "CacheService" )
        .to( "models.CacheService" )
        .method( name: "configure", argName: "settings", value: getSettings() )

    // Mixing injections
    map( "ComplexService" )
        .to( "models.ComplexService" )
        .asSingleton()
        .initWith( setting: "value" )
        .setter( name: "log", dsl: "logbox:logger:{this}" )
        .property( name: "cache", dsl: "cachebox:default" )
}
```

## Object Scopes

### Scope Types

```boxlang
// Singleton - One instance for entire application
property name="userService" inject="UserService" scope="singleton"

// Transient - New instance every time
property name="userDTO" inject="UserDTO" scope="transient"

// Request - One instance per HTTP request
property name="requestContext" inject="RequestContext" scope="request"

// Session - One instance per user session
property name="cart" inject="Cart" scope="session"

// CacheBox - Cached instance
property name="config" inject="ConfigService" scope="cachebox"
```

### Custom Scopes

```boxlang
/**
 * config/WireBox.cfc
 */
function configure() {

    // Register custom scope
    scopeRegistration = {
        enabled: true,
        scope: "application",
        key: "wirebox"
    }

    // Map to custom scope
    map( "TenantService" )
        .to( "models.TenantService" )
        .intoScope( "tenant" )
}
```

## Providers

### Using Providers

```boxlang
/**
 * UserService.cfc
 */
class singleton {

    // Provider injection for lazy loading
    property name="mailServiceProvider" inject="provider:MailService"

    function sendWelcomeEmail( user ) {
        // Get instance from provider (lazy loaded)
        var mailService = mailServiceProvider.$get()

        mailService.send(
            to: user.email,
            subject: "Welcome!",
            body: "Welcome to our app"
        )
    }
}
```

### Provider Pattern

```boxlang
/**
 * Avoid circular dependencies
 */
class singleton {

    // Use provider to break circular dependency
    property name="orderServiceProvider" inject="provider:OrderService"
    property name="userService" inject="UserService"

    function processOrder( orderID ) {
        var orderService = orderServiceProvider.$get()
        return orderService.process( orderID )
    }
}
```

### Custom Provider

```boxlang
/**
 * DatabaseProvider.cfc
 */
class implements="coldbox.system.ioc.IProvider" singleton {

    property name="wirebox" inject="wirebox"
    property name="settings" inject="coldbox:configSettings"

    function $get() {
        return wirebox.getInstance( "DatabaseService" )
            .configure( settings.database )
    }
}
```

## Aspect-Oriented Programming (AOP)

### Method Interception

```boxlang
/**
 * config/WireBox.cfc
 */
function configure() {

    // Add AOP interceptor
    map( "UserService" )
        .to( "models.UserService" )
        .asSingleton()
        .addInterceptor( "LoggingInterceptor" )
}

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

### Performance Monitoring

```boxlang
/**
 * PerformanceInterceptor.cfc
 */
class {

    property name="log" inject="logbox:logger:{this}"

    function around( invocation ) {
        var start = getTickCount()

        try {
            var result = invocation.proceed()

            var duration = getTickCount() - start

            if ( duration > 1000 ) {
                log.warn( "Slow method: #invocation.getMethod()# (#duration#ms)" )
            }

            return result

        } catch ( any e ) {
            log.error( "Method failed: #invocation.getMethod()#" )
            rethrow
        }
    }
}
```

## Advanced Patterns

### Factory Pattern

```boxlang
/**
 * UserFactory.cfc
 */
class singleton {

    property name="wirebox" inject="wirebox"

    function createUser( type ) {
        switch ( type ) {
            case "admin":
                return wirebox.getInstance( "AdminUser" )
            case "customer":
                return wirebox.getInstance( "CustomerUser" )
            default:
                return wirebox.getInstance( "GuestUser" )
        }
    }
}

// Usage
property name="userFactory" inject="UserFactory"

function register( event, rc, prc ) {
    var user = userFactory.createUser( rc.type )
}
```

### Repository Pattern

```boxlang
/**
 * IUserRepository.cfc
 */
interface {
    function findById( id )
    function findAll()
    function save( entity )
    function delete( id )
}

/**
 * UserRepository.cfc
 */
class singleton implements="IUserRepository" {

    property name="wirebox" inject="wirebox"
    property name="log" inject="logbox:logger:{this}"

    function findById( required id ) {
        return queryExecute( "SELECT * FROM users WHERE id = :id", { id: id } )
    }

    function findAll() {
        return queryExecute( "SELECT * FROM users" )
    }

    function save( required entity ) {
        // Save logic
    }

    function delete( required id ) {
        // Delete logic
    }
}

// Bind interface to implementation
map( "IUserRepository" )
    .to( "models.repositories.UserRepository" )
    .asSingleton()
```

### Service Locator Pattern

```boxlang
/**
 * ServiceLocator.cfc
 */
class singleton {

    property name="wirebox" inject="wirebox"

    function getService( required name ) {
        return wirebox.getInstance( arguments.name )
    }

    function getInstance( required name, initArguments = {} ) {
        return wirebox.getInstance(
            name: arguments.name,
            initArguments: arguments.initArguments
        )
    }
}
```

### Virtual Inheritance

```boxlang
/**
 * config/WireBox.cfc
 */
function configure() {

    // Base service with common functionality
    map( "BaseService" )
        .to( "models.BaseService" )
        .virtualInheritance()

    // Services inherit from BaseService
    map( "UserService" )
        .to( "models.UserService" )
        .parent( "BaseService" )

    map( "OrderService" )
        .to( "models.OrderService" )
        .parent( "BaseService" )
}
```

## Testing with WireBox

### Mocking Dependencies

```boxlang
/**
 * UserServiceTest.cfc
 */
class extends="testbox.system.BaseSpec" {

    function run() {
        describe( "UserService", () => {

            beforeEach( () => {
                // Create mock DAO
                variables.mockDAO = createMock( "models.UserDAO" )

                // Create service with mocked dependency
                variables.service = createMock( "models.UserService" )
                service.$property( "userDAO", "variables", mockDAO )
            } )

            it( "should list users", () => {
                // Setup mock
                mockDAO.$( "list", [ { id: 1, name: "John" } ] )

                // Test
                var result = service.list()

                // Verify
                expect( result ).toHaveLength( 1 )
                expect( mockDAO.$count( "list" ) ).toBe( 1 )
            } )
        } )
    }
}
```

### Isolated Testing

```boxlang
class extends="testbox.system.BaseSpec" {

    function run() {
        describe( "OrderService", () => {

            beforeEach( () => {
                // Create new WireBox for testing
                variables.wirebox = createObject( "component", "coldbox.system.ioc.Injector" ).init()

                // Configure test mappings
                wirebox.getBinder()
                    .map( "OrderDAO" )
                    .to( "tests.mocks.MockOrderDAO" )

                // Get service with test dependencies
                variables.service = wirebox.getInstance( "OrderService" )
            } )

            it( "should process order", () => {
                var order = { id: 1, total: 100 }
                var result = service.process( order )

                expect( result.success ).toBeTrue()
            } )
        } )
    }
}
```

## Best Practices

### Design Guidelines

1. **Interface Programming**: Code to interfaces, not implementations
2. **Constructor Injection**: Prefer constructor over setter/property injection
3. **Explicit Dependencies**: Make dependencies explicit
4. **Single Responsibility**: One responsibility per class
5. **Avoid Circular Dependencies**: Use providers if needed
6. **Appropriate Scopes**: Use correct object scopes
7. **Testability**: Design for easy testing
8. **Configuration**: Use binder for complex configurations
9. **Lazy Loading**: Use providers for expensive objects
10. **Documentation**: Document injection points

### Common Patterns

```boxlang
// ✅ Good: Property injection
property name="userService" inject="UserService"

// ✅ Good: Constructor injection
function init( required userService ) {
    variables.userService = arguments.userService
    return this
}

// ✅ Good: Provider for lazy loading
property name="mailServiceProvider" inject="provider:MailService"

// ✅ Good: Singleton scope
class singleton {
    property name="cache" inject="cachebox:default"
}
```

## Common Pitfalls

### Pitfalls to Avoid

1. **Circular Dependencies**: A depends on B, B depends on A
2. **Wrong Scopes**: Using transient for expensive objects
3. **Over-Injection**: Injecting too many dependencies
4. **Missing Annotations**: Forgetting injection annotations
5. **Property Shadowing**: Conflicting variable names
6. **No Interfaces**: Tight coupling to implementations
7. **Service Locator Overuse**: Anti-pattern if overused
8. **Mutable Singletons**: Thread safety issues
9. **Constructor Complexity**: Too much logic in init()
10. **Hard-Coded Dependencies**: Not using DI at all

### Anti-Patterns

```boxlang
// ❌ Bad: Hard-coded dependency
function getUsers() {
    var userDAO = createObject( "UserDAO" )
    return userDAO.list()
}

// ✅ Good: Injected dependency
property name="userDAO" inject="UserDAO"

function getUsers() {
    return userDAO.list()
}

// ❌ Bad: Service locator everywhere
function process() {
    var service1 = wirebox.getInstance( "Service1" )
    var service2 = wirebox.getInstance( "Service2" )
}

// ✅ Good: Direct injection
property name="service1" inject="Service1"
property name="service2" inject="Service2"

// ❌ Bad: Circular dependency
class {
    property name="orderService" inject="OrderService"
}

// ✅ Good: Provider to break cycle
class {
    property name="orderServiceProvider" inject="provider:OrderService"
}
```

## Related Skills

- [ColdBox Handler Development](../coldbox/handler-development.md) - Handler patterns
- [LogBox Logging](../logbox/logbox-logging-patterns.md) - Logging patterns
- [CacheBox Caching](../cachebox/cachebox-caching-patterns.md) - Caching patterns

## References

- [WireBox Documentation](https://wirebox.ortusbooks.com/)
- [Injection DSL](https://wirebox.ortusbooks.com/usage/injection-dsl)
- [Binder Configuration](https://wirebox.ortusbooks.com/configuration/binder-configuration)
