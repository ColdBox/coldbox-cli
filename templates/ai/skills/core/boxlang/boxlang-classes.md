---
name: boxlang-classes
description: Design and implement BoxLang classes with proper structure, inheritance, interfaces, and design patterns
category: boxlang
priority: high
---

# BoxLang Classes Skill

## When to Use This Skill

Use this skill when:
- Creating new BoxLang classes
- Implementing inheritance hierarchies
- Working with interfaces and abstract classes
- Applying object-oriented design patterns
- Building service layers and models

## Basic Class Structure

### Simple Class

```boxlang
class User {
    // Properties
    property name="id" type="numeric";
    property name="username" type="string";
    property name="email" type="string";

    // Constructor
    init( string username = "", string email = "" ) {
        variables.username = arguments.username
        variables.email = arguments.email
        return this
    }

    // Methods
    function getFullIdentifier() {
        return "#variables.username# <#variables.email#>"
    }

    function isValid() {
        return len( variables.username ) > 0 && len( variables.email ) > 0
    }
}
```

### Class with Accessors

```boxlang
@accessors=true
class Product {
    property name="id" type="numeric";
    property name="name" type="string";
    property name="price" type="numeric" default="0";
    property name="active" type="boolean" default="true";

    init() {
        return this
    }

    // Custom method beyond auto-generated getters/setters
    function getDisplayPrice() {
        return dollarFormat( getPrice() )
    }
}

// Usage
var product = new Product()
product.setName( "Widget" )
product.setPrice( 29.99 )
var name = product.getName()  // Auto-generated getter
```

## Inheritance

### Base Class and Subclass

```boxlang
// Base class
class BaseService {
    @inject
    property name="log";

    init() {
        variables.serviceName = getMetadata( this ).name
        return this
    }

    function logInfo( required string message ) {
        log.info( "[#variables.serviceName#] #arguments.message#" )
    }

    function logError( required string message, any exception ) {
        log.error( "[#variables.serviceName#] #arguments.message#", exception )
    }
}

// Subclass
class UserService extends BaseService {
    @inject
    property name="userDAO";

    init() {
        super.init()
        return this
    }

    function createUser( required struct data ) {
        logInfo( "Creating user: #data.username#" )

        try {
            var user = userDAO.create( data )
            logInfo( "User created successfully: #user.getId()#" )
            return user
        } catch ( any e ) {
            logError( "Failed to create user", e )
            rethrow
        }
    }
}
```

### Method Overriding

```boxlang
class Animal {
    function makeSound() {
        return "Some sound"
    }

    function move() {
        return "Moving"
    }
}

class Dog extends Animal {
    // Override parent method
    function makeSound() {
        return "Woof!"
    }

    // Call parent method then extend
    function move() {
        var baseMove = super.move()
        return "#baseMove# by running"
    }

    // New method specific to Dog
    function fetch() {
        return "Fetching ball"
    }
}
```

## Dependency Injection

### Constructor Injection

```boxlang
class OrderService {
    // Dependencies injected by WireBox
    @inject
    property name="orderDAO";

    @inject
    property name="emailService";

    @inject( "CacheStorage@cbstorages" )
    property name="cache";

    init() {
        return this
    }

    function createOrder( required struct data ) {
        var order = orderDAO.create( data )

        // Send confirmation email
        emailService.sendOrderConfirmation( order )

        // Cache for quick lookup
        cache.set( "order-#order.getId()#", order )

        return order
    }
}
```

### Setter Injection

```boxlang
class ReportService {
    property name="reportDAO";
    property name="formatter";

    // WireBox will call these setters
    function setReportDAO( required reportDAO ) {
        variables.reportDAO = arguments.reportDAO
        return this
    }

    function setFormatter( required formatter ) {
        variables.formatter = arguments.formatter
        return this
    }

    function generateReport( required numeric id ) {
        var report = reportDAO.get( id )
        return formatter.format( report )
    }
}
```

## Singleton Pattern

```boxlang
@singleton
class ConfigurationService {
    property name="config";

    init() {
        variables.config = {}
        loadConfiguration()
        return this
    }

    private function loadConfiguration() {
        variables.config = {
            appName: "MyApp",
            version: "1.0.0",
            environment: getSystemSetting( "ENVIRONMENT", "development" )
        }
    }

    function get( required string key, any defaultValue ) {
        return variables.config.keyExists( key )
            ? variables.config[key]
            : arguments.defaultValue ?: ""
    }

    function set( required string key, required any value ) {
        variables.config[key] = arguments.value
        return this
    }
}
```

## Abstract Base Classes

### Pattern Implementation

```boxlang
// Abstract base (not enforced but convention)
class AbstractValidator {
    function validate( required any target ) {
        throw(
            type = "AbstractMethodException",
            message = "validate() must be implemented by subclass"
        )
    }

    // Concrete helper method
    function isRequired( required string value ) {
        return len( trim( value ) ) > 0
    }
}

// Concrete implementation
class UserValidator extends AbstractValidator {
    function validate( required struct user ) {
        var errors = []

        if ( !isRequired( user.username ?: "" ) ) {
            errors.append( "Username is required" )
        }

        if ( !isRequired( user.email ?: "" ) ) {
            errors.append( "Email is required" )
        }

        return {
            isValid: errors.isEmpty(),
            errors: errors
        }
    }
}
```

## Factory Pattern

```boxlang
class RepositoryFactory {
    @inject
    property name="wirebox";

    function getRepository( required string entityName ) {
        // Dynamic repository creation
        var repoName = "#arguments.entityName#Repository"

        if ( wirebox.getBinder().mappingExists( repoName ) ) {
            return wirebox.getInstance( repoName )
        }

        // Create generic repository
        return wirebox.getInstance(
            name = "GenericRepository",
            initArguments = { entityName: arguments.entityName }
        )
    }
}

// Usage
class UserService {
    @inject
    property name="repositoryFactory";

    function init() {
        variables.userRepo = repositoryFactory.getRepository( "User" )
        return this
    }
}
```

## Builder Pattern

```boxlang
class QueryBuilder {
    property name="sql";
    property name="params";
    property name="table";

    init() {
        variables.sql = ""
        variables.params = []
        return this
    }

    function select( required string columns ) {
        variables.sql = "SELECT #arguments.columns#"
        return this
    }

    function from( required string tableName ) {
        variables.table = arguments.tableName
        variables.sql &= " FROM #arguments.tableName#"
        return this
    }

    function where( required string condition, any value ) {
        variables.sql &= " WHERE #arguments.condition#"
        if ( !isNull( arguments.value ) ) {
            variables.params.append( arguments.value )
        }
        return this
    }

    function orderBy( required string column, string direction = "ASC" ) {
        variables.sql &= " ORDER BY #arguments.column# #arguments.direction#"
        return this
    }

    function get() {
        // Execute query
        return queryExecute( variables.sql, variables.params )
    }
}

// Usage
var users = new QueryBuilder()
    .select( "*" )
    .from( "users" )
    .where( "active = ?", true )
    .orderBy( "created_date", "DESC" )
    .get()
```

## Static Methods and Properties

```boxlang
class StringUtils {
    // Static method
    static function slugify( required string text ) {
        return lCase( reReplace( arguments.text, "[^a-zA-Z0-9]+", "-", "all" ) )
    }

    static function truncate( required string text, numeric length = 100 ) {
        if ( len( arguments.text ) <= arguments.length ) {
            return arguments.text
        }
        return left( arguments.text, arguments.length ) & "..."
    }
}

// Usage - no instance needed
var slug = StringUtils::slugify( "Hello World" )
var short = StringUtils::truncate( longText, 50 )
```

## Best Practices

### ✅ DO: Use Clear Class Names

```boxlang
// Good - Clear purpose
class UserService { }
class OrderRepository { }
class EmailValidator { }
class PaymentGateway { }
```

### ✅ DO: Single Responsibility

```boxlang
// Good - Each class has one job
class UserAuthenticator {
    function authenticate( username, password ) {
        // Only handles authentication
    }
}

class UserRepository {
    function save( user ) {
        // Only handles persistence
    }
}

class UserValidator {
    function validate( user ) {
        // Only handles validation
    }
}
```

### ✅ DO: Dependency Injection Over Tight Coupling

```boxlang
// Good - Injected dependencies
class OrderService {
    @inject
    property name="emailService";

    @inject
    property name="inventoryService";

    function processOrder( order ) {
        inventoryService.reserve( order.items )
        emailService.sendConfirmation( order )
    }
}

// Bad - Tight coupling
class OrderService {
    function processOrder( order ) {
        var emailService = new EmailService()  // ❌ Don't do this
        emailService.sendConfirmation( order )
    }
}
```

### ✅ DO: Use Init() for Initialization

```boxlang
class Service {
    @inject
    property name="dependency";

    init() {
        // Initialization logic
        variables.initialized = true
        variables.startTime = now()
        return this  // Important!
    }
}
```

## Common Mistakes

### ❌ Not Returning `this` from Init

```boxlang
// Wrong
class Service {
    init() {
        // Setup code
        // Missing return!
    }
}

// Right
class Service {
    init() {
        // Setup code
        return this  // ✅
    }
}
```

### ❌ Creating Dependencies in Constructor

```boxlang
// Wrong
class Service {
    init() {
        variables.dependency = new Dependency()  // ❌ Tight coupling
        return this
    }
}

// Right
class Service {
    @inject
    property name="dependency";  // ✅ Injected

    init() {
        return this
    }
}
```

### ❌ Not Using Accessors

```boxlang
// Tedious
class User {
    property name="username";

    function getUsername() {
        return variables.username
    }

    function setUsername( required string username ) {
        variables.username = arguments.username
    }
}

// Better
@accessors=true
class User {
    property name="username";
    // Getters/setters auto-generated
}
```

## Testing Classes

```boxlang
component extends="testbox.system.BaseSpec" {
    function run() {
        describe( "UserService", () => {
            beforeEach( () => {
                variables.userService = getInstance( "UserService" )
            })

            it( "should create a user", () => {
                var user = userService.createUser({
                    username: "john",
                    email: "john@example.com"
                })

                expect( user.getId() ).toBeNumeric()
                expect( user.getUsername() ).toBe( "john" )
            })

            it( "should inject dependencies", () => {
                expect( userService.getUserDAO() ).toBeComponent()
            })
        })
    }
}
```

## Additional Resources

- BoxLang OOP Documentation
- ColdBox Dependency Injection Guide
- WireBox Binder DSL
- Design Patterns in BoxLang
