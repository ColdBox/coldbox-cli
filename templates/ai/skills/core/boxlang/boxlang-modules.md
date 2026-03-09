---
name: boxlang-modules
description: Master BoxLang module system including imports, exports, module structure, and namespace management
category: boxlang
priority: high
---

# BoxLang Modules Skill

## When to Use This Skill

Use this skill when:
- Creating reusable BoxLang modules
- Organizing code into logical namespaces
- Managing dependencies between modules
- Importing and exporting functionality
- Building modular applications with clear boundaries
- Packaging code libraries for distribution

## Module System Overview

### What is a BoxLang Module?

A BoxLang module is a self-contained unit of code with its own namespace, imports, and exports. Modules help organize code, manage dependencies, and provide clear encapsulation boundaries.

```boxlang
// Simple module definition
module MyModule {
    // Module code here
    class UserService {
        function getUsers() {
            return [ "user1", "user2" ]
        }
    }
}
```

## Basic Module Structure

### Simple Module with Exports

```boxlang
module com.myapp.services {

    // Export a class
    export class UserService {
        function getUsers() {
            return queryExecute( "SELECT * FROM users" )
        }

        function getUserById( required numeric id ) {
            return queryExecute(
                "SELECT * FROM users WHERE id = :id",
                { id: arguments.id }
            )
        }
    }

    // Export a function
    export function formatUserName( required struct user ) {
        return "#user.firstName# #user.lastName#"
    }

    // Private (not exported) function
    function validateUser( required struct user ) {
        return len( user.email ) > 0 && len( user.firstName ) > 0
    }
}
```

### Module with Multiple Exports

```boxlang
module com.myapp.utils {

    // Export multiple classes
    export class StringHelper {
        static function capitalize( required string text ) {
            return uCase( left( text, 1 ) ) & lCase( mid( text, 2, len( text ) ) )
        }

        static function slugify( required string text ) {
            return reReplace( lCase( text ), "[^a-z0-9]+", "-", "all" )
        }
    }

    export class DateHelper {
        static function formatDate( required date dateValue, string format = "yyyy-MM-dd" ) {
            return dateFormat( dateValue, format )
        }

        static function isWeekend( required date dateValue ) {
            var dayOfWeek = dayOfWeek( dateValue )
            return dayOfWeek == 1 || dayOfWeek == 7
        }
    }

    export class NumberHelper {
        static function formatCurrency( required numeric amount, string symbol = "$" ) {
            return symbol & numberFormat( amount, "0.00" )
        }
    }
}
```

## Importing Modules

### Basic Imports

```boxlang
// Import entire module
import com.myapp.services.UserService

// Use the imported class
var userService = new UserService()
var users = userService.getUsers()
```

### Named Imports

```boxlang
// Import specific classes
import com.myapp.utils.{ StringHelper, DateHelper }

// Use imported classes
var slug = StringHelper.slugify( "Hello World" )
var formattedDate = DateHelper.formatDate( now() )
```

### Import with Aliases

```boxlang
// Import with alias
import com.myapp.services.UserService as US
import com.myapp.services.AdminService as AS

var userService = new US()
var adminService = new AS()
```

### Wildcard Imports

```boxlang
// Import all exports from a module
import com.myapp.utils.*

var slug = StringHelper.slugify( "Test" )
var formatted = DateHelper.formatDate( now() )
var price = NumberHelper.formatCurrency( 29.99 )
```

## Module File Structure

### File-Based Modules

Each BoxLang class can be a module:

```boxlang
// /models/UserService.bx
class UserService {
    @inject
    property name="userDAO";

    function getUsers() {
        return userDAO.list()
    }

    function createUser( required struct data ) {
        return userDAO.create( data )
    }
}

// /handlers/Main.bx
import models.UserService

component {
    @inject
    property name="userService";

    function index( event, rc, prc ) {
        prc.users = userService.getUsers()
        event.setView( "main/index" )
    }
}
```

### Package Structure

```
/app
  /models
    /user
      UserService.bx
      UserValidator.bx
      UserRepository.bx
    /order
      OrderService.bx
      OrderProcessor.bx
  /handlers
    User.bx
    Order.bx
```

## Module Namespacing

### Hierarchical Namespaces

```boxlang
// Define nested namespaces
module com.mycompany.myapp.data {
    export class Database {
        function connect() {
            return "Connected to database"
        }
    }
}

module com.mycompany.myapp.services {
    import com.mycompany.myapp.data.Database

    export class DataService {
        property name="db";

        init() {
            variables.db = new Database()
            return this
        }
    }
}
```

### Namespace Best Practices

```boxlang
// Good namespace organization
module com.mycompany.{
    module core {
        export class Logger { }
        export class Config { }
    }

    module data {
        export class Repository { }
        export class Query { }
    }

    module services {
        import com.mycompany.data.Repository

        export class UserService {
            @inject
            property name="repository";
        }
    }
}
```

## Module Configuration

### Module with Configuration

```boxlang
module com.myapp.email {

    // Module-level configuration
    var config = {
        server: "smtp.example.com",
        port: 587,
        username: "",
        password: ""
    }

    export class EmailService {
        function configure( required struct settings ) {
            config.username = settings.username
            config.password = settings.password
        }

        function send( required struct mail ) {
            // Use config to send email
            return sendEmail(
                to: mail.to,
                from: mail.from,
                subject: mail.subject,
                body: mail.body,
                server: config.server,
                port: config.port,
                username: config.username,
                password: config.password
            )
        }
    }
}
```

## ColdBox Module Structure

### ColdBox Application Module

```boxlang
// ModuleConfig.bx
class ModuleConfig {

    property name="title" default="My Module";
    property name="author" default="Your Name";
    property name="version" default="1.0.0";

    function configure() {
        settings = {
            apiKey: "",
            endpoint: "https://api.example.com"
        }

        // Interceptor Settings
        interceptorSettings = {
            customInterceptionPoints: [ "onUserLogin", "onUserLogout" ]
        }

        // Model Bindings
        binder.map( "MyService" )
            .to( "models.MyService" )
            .asSingleton()
    }

    function onLoad() {
        // Module loaded
        log.info( "Module loaded: #variables.title#" )
    }

    function onUnload() {
        // Module unloaded
        log.info( "Module unloaded: #variables.title#" )
    }
}
```

### ColdBox Module Directory Structure

```
/modules/mymodule
  ModuleConfig.bx
  /models
    MyService.bx
  /handlers
    Main.bx
  /views
    main/
      index.cfm
  /interceptors
    Security.bx
```

### Module Routes

```boxlang
// ModuleConfig.bx
class ModuleConfig {

    function configure() {
        // Module routes
        router
            .route( "/api/users" )
            .withAction( { GET: "list", POST: "create" } )
            .toHandler( "User" )

            .route( "/api/users/:id" )
            .withAction( { GET: "show", PUT: "update", DELETE: "delete" } )
            .toHandler( "User" )
    }
}
```

## Module Dependencies

### Declaring Dependencies

```boxlang
// ModuleConfig.bx
class ModuleConfig {

    // Modules this module depends on
    property name="dependencies" default=[ "cborm", "cbvalidation", "cbsecurity" ];

    function configure() {
        // Configuration
    }
}
```

### Using Module Services

```boxlang
// In your handler
component {

    @inject("ValidationService@cbvalidation")
    property name="validator";

    @inject("SecurityService@cbsecurity")
    property name="security";

    function save( event, rc, prc ) {
        // Use injected services from other modules
        var result = validator.validate( rc )

        if ( result.hasErrors() ) {
            return result.getErrors()
        }

        event.setView( "user/success" )
    }
}
```

## Module Exports and Visibility

### Public vs Private Exports

```boxlang
module com.myapp.core {

    // Public - exported
    export class PublicService {
        function doSomething() {
            return "Public"
        }
    }

    // Private - not exported
    class InternalHelper {
        function internalOperation() {
            return "Private"
        }
    }

    // Public service using private helper
    export class MainService {
        function execute() {
            var helper = new InternalHelper()
            return helper.internalOperation()
        }
    }
}
```

### Selective Exports

```boxlang
module com.myapp.data {

    // Export specific functionality
    class BaseRepository {
        function list() { }
        function get( id ) { }
        function save( entity ) { }
        function delete( id ) { }

        // Private helper
        private function validateEntity( entity ) { }
    }

    // Only export specific repositories
    export class UserRepository extends BaseRepository { }
    export class OrderRepository extends BaseRepository { }

    // Keep this one internal
    class AuditRepository extends BaseRepository { }
}
```

## Best Practices

### ✅ DO: Use Clear Module Names

```boxlang
// Good - Clear purpose
module com.mycompany.myapp.services { }
module com.mycompany.myapp.models { }
module com.mycompany.myapp.utils { }

// Bad - Unclear
module stuff { }
module misc { }
```

### ✅ DO: Organize Related Functionality

```boxlang
// Good - Related classes in same module
module com.myapp.user {
    export class UserService { }
    export class UserValidator { }
    export class UserRepository { }
}

// Bad - Scattered organization
module services {
    export class UserService { }
    export class OrderService { }
    export class EmailService { }
}
```

### ✅ DO: Use Explicit Imports

```boxlang
// Good - Clear what you're using
import com.myapp.services.UserService
import com.myapp.services.OrderService

var userService = new UserService()
var orderService = new OrderService()

// Avoid - Can cause confusion
import com.myapp.services.*
```

### ✅ DO: Version Your Modules

```boxlang
// ModuleConfig.bx
class ModuleConfig {
    property name="version" default="1.2.3";
    property name="semanticVersion" default="1.2.3+build.234";

    function configure() {
        // Module configuration
    }
}
```

### ✅ DO: Document Module APIs

```boxlang
/**
 * User management services
 *
 * @author Your Name
 * @version 1.0.0
 */
module com.myapp.user {

    /**
     * Service for user CRUD operations
     */
    export class UserService {

        /**
         * Get all users
         *
         * @return Query of user records
         */
        function getUsers() {
            return queryExecute( "SELECT * FROM users" )
        }
    }
}
```

## Common Mistakes

### ❌ Not Exporting Classes

```boxlang
// Wrong - Class not exported
module com.myapp.services {
    class UserService {  // ❌ Missing export
        function getUsers() { }
    }
}

// Right
module com.myapp.services {
    export class UserService {  // ✅
        function getUsers() { }
    }
}
```

### ❌ Circular Dependencies

```boxlang
// Wrong - Circular dependency
// Module A
module com.myapp.a {
    import com.myapp.b.ServiceB

    export class ServiceA {
        function doSomething() {
            var b = new ServiceB()  // ❌ Calls B
        }
    }
}

// Module B
module com.myapp.b {
    import com.myapp.a.ServiceA

    export class ServiceB {
        function doSomething() {
            var a = new ServiceA()  // ❌ Calls A
        }
    }
}

// Right - Use dependency injection
module com.myapp.a {
    export class ServiceA {
        @inject
        property name="serviceB";  // ✅ Injected

        function doSomething() {
            serviceB.doSomethingElse()
        }
    }
}
```

### ❌ Deep Nesting

```boxlang
// Avoid - Too deep
module com.mycompany.myapp.services.user.management.operations { }

// Better - Flatter structure
module com.mycompany.myapp.user { }
```

### ❌ Mixing Concerns in Modules

```boxlang
// Wrong - Mixed concerns
module com.myapp.stuff {
    export class UserService { }
    export class EmailSender { }
    export class FileUploader { }
    export class PaymentProcessor { }
}

// Right - Organized by concern
module com.myapp.user {
    export class UserService { }
}

module com.myapp.email {
    export class EmailService { }
}

module com.myapp.storage {
    export class FileService { }
}

module com.myapp.payment {
    export class PaymentService { }
}
```

## Testing Modules

### Testing Module Exports

```boxlang
component extends="testbox.system.BaseSpec" {

    function run() {
        describe( "UserService Module", () => {

            beforeEach( () => {
                // Import module
                import com.myapp.services.UserService
                variables.userService = new UserService()
            })

            it( "should export UserService class", () => {
                expect( variables.userService ).toBeComponent()
            })

            it( "should have required methods", () => {
                expect( variables.userService ).toHaveKey( "getUsers" )
                expect( variables.userService ).toHaveKey( "getUserById" )
            })

            it( "should return users", () => {
                var users = userService.getUsers()
                expect( users ).toBeQuery()
            })
        })
    }
}
```

### Testing Module Integration

```boxlang
component extends="testbox.system.BaseSpec" {

    function run() {
        describe( "Module Integration", () => {

            it( "should wire dependencies between modules", () => {
                var userHandler = getInstance( "User" )

                // Check that cross-module dependencies are wired
                expect( userHandler.getUserService() ).toBeComponent()
                expect( userHandler.getEmailService() ).toBeComponent()
            })

            it( "should load module configuration", () => {
                var moduleSettings = getModuleSettings( "mymodule" )

                expect( moduleSettings ).toBeStruct()
                expect( moduleSettings ).toHaveKey( "apiKey" )
            })
        })
    }
}
```

### Testing Module Isolation

```boxlang
component extends="testbox.system.BaseSpec" {

    function run() {
        describe( "Module Isolation", () => {

            it( "should not expose private classes", () => {
                // This should fail - InternalHelper is not exported
                expect( function() {
                    import com.myapp.core.InternalHelper
                    new InternalHelper()
                }).toThrow()
            })

            it( "should only expose exported functionality", () => {
                import com.myapp.core.PublicService
                var service = new PublicService()

                expect( service ).toHaveKey( "doSomething" )
                expect( service ).notToHaveKey( "internalOperation" )
            })
        })
    }
}
```

## Additional Resources

- BoxLang Module Documentation
- ColdBox Module Development Guide
- ForgeBox: Module Repository
- CommandBox Module Creation
- Module Versioning Best Practices
- Semantic Versioning (SemVer)
- Module Testing Strategies
