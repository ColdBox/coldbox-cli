---
name: boxlang-syntax
description: Master BoxLang syntax including class definitions, properties, methods, and modern language features
category: boxlang
priority: high
---

# BoxLang Syntax Skill

## When to Use This Skill

Use this skill when:
- Writing new BoxLang classes and components
- Converting CFML code to BoxLang syntax
- Understanding BoxLang language features
- Learning modern BoxLang patterns

## Class Definition Syntax

### Basic Class Structure

```boxlang
class MyClass {
    // Properties
    property name="myProperty";

    // Constructor (optional)
    function init() {
        return this
    }

    // Methods
    function myMethod() {
        return "result"
    }
}
```

### Class with Inheritance

```boxlang
class UserService extends BaseService {
    // Inherits from BaseService
    property name="userDAO" inject="UserDAO";

    function init() {
        super.init()
        return this
    }

    function getUser( required numeric id ) {
        return userDAO.get( id )
    }
}
```

### Class with Annotations

```boxlang
@singleton
class CacheService {
    @inject( "CacheProvider@cachebox" )
    property name="cache";

    @accessors=true
    property name="defaultTimeout" type="numeric" default="60";

    function store( required string key, required any value ) {
        cache.set( key, value, defaultTimeout )
    }
}
```

## Property Declarations

### Basic Properties

```boxlang
class User {
    // Simple property
    property name="username";

    // Typed property
    property name="age" type="numeric";

    // Property with default
    property name="active" type="boolean" default="true";

    // Property with annotation
    @inject( "SecurityService" )
    property name="securityService";
}
```

### Automatic Getters/Setters

```boxlang
@accessors=true
class Product {
    property name="id" type="numeric";
    property name="name" type="string";
    property name="price" type="numeric";
}

// Automatically generates:
// getId(), setId()
// getName(), setName()
// getPrice(), setPrice()
```

## Method Syntax

### Functions Without `function` Keyword

```boxlang
class MathService {
    // Modern syntax - no 'function' keyword needed
    add( required numeric a, required numeric b ) {
        return a + b
    }

    multiply( required numeric a, required numeric b ) {
        return a * b
    }

    // With default arguments
    power( required numeric base, numeric exponent = 2 ) {
        return base ^ exponent
    }
}
```

### Method Annotations

```boxlang
class APIHandler extends coldbox.system.EventHandler {
    @inject( "UserService" )
    property name="userService";

    // Secured action
    @secured( "user" )
    function index( event, rc, prc ) {
        prc.users = userService.list()
        return event.renderData( data = prc.users )
    }

    // Rate limited
    @rateLimit( "10 per minute" )
    function search( event, rc, prc ) {
        return event.renderData(
            data = userService.search( rc.query ?: "" )
        )
    }
}
```

## Variables and Scoping

### Variable Declaration

```boxlang
class Example {
    function demo() {
        // Local variable
        var myVar = "value"

        // Multiple declarations
        var x = 1, y = 2, z = 3

        // Type hints
        var count:numeric = 0
        var name:string = "John"
        var active:boolean = true

        // Arrays and structs
        var items = []
        var config = {}
    }
}
```

### Scope Access

```boxlang
class ScopeExample {
    property name="instanceVar";

    function example() {
        // Local scope (preferred)
        var localVar = "local"

        // Instance scope
        variables.instanceVar = "instance"
        this.instanceVar = "public"

        // Arguments scope
        function process( value ) {
            return arguments.value
        }

        // Unscoped (searches in order)
        myVar = "value"  // Creates in variables scope if not found
    }
}
```

## Control Structures

### If/Else

```boxlang
class ControlFlow {
    function checkAge( numeric age ) {
        if ( age < 18 ) {
            return "minor"
        } else if ( age < 65 ) {
            return "adult"
        } else {
            return "senior"
        }
    }

    // Ternary operator
    function getStatus( boolean active ) {
        return active ? "Active" : "Inactive"
    }

    // Elvis operator (null coalescing)
    function getName( user ) {
        return user.name ?: "Unknown"
    }
}
```

### Loops

```boxlang
class LoopExamples {
    function demonstrateLoops() {
        // For loop
        for ( var i = 0; i < 10; i++ ) {
            // Do something
        }

        // For-in loop (array)
        var items = [1, 2, 3, 4, 5]
        for ( var item in items ) {
            // Process item
        }

        // For-in loop (struct)
        var config = { key1: "value1", key2: "value2" }
        for ( var key in config ) {
            var value = config[key]
        }

        // While loop
        var counter = 0
        while ( counter < 5 ) {
            counter++
        }

        // Do-while loop
        do {
            // Execute at least once
        } while ( condition )
    }
}
```

### Switch Statements

```boxlang
class SwitchExample {
    function getColor( string type ) {
        switch ( type ) {
            case "error":
                return "red"
            case "warning":
                return "yellow"
            case "success":
                return "green"
            default:
                return "gray"
        }
    }
}
```

## String Operations

### String Interpolation

```boxlang
class StringExample {
    function greet( string name ) {
        // String interpolation
        return "Hello, #name#!"
    }

    function buildMessage( user ) {
        var message = "User: #user.name# (ID: #user.id#)"
        return message
    }

    // Multi-line strings
    function getTemplate() {
        return "
            <div>
                <h1>Title</h1>
                <p>Content</p>
            </div>
        "
    }
}
```

## Array and Struct Literals

### Arrays

```boxlang
class ArrayExamples {
    function demo() {
        // Array literal
        var numbers = [1, 2, 3, 4, 5]

        // Mixed types
        var mixed = [1, "two", true, { key: "value" }]

        // Array methods
        numbers.append( 6 )
        numbers.prepend( 0 )
        var doubled = numbers.map( (n) => n * 2 )
        var evens = numbers.filter( (n) => n % 2 == 0 )
    }
}
```

### Structs

```boxlang
class StructExamples {
    function demo() {
        // Struct literal
        var user = {
            id: 1,
            name: "John Doe",
            email: "john@example.com",
            active: true
        }

        // Nested structs
        var config = {
            database: {
                host: "localhost",
                port: 3306
            },
            cache: {
                enabled: true,
                timeout: 3600
            }
        }

        // Dynamic keys
        var key = "username"
        var data = {
            "#key#": "john"
        }
    }
}
```

## Best Practices

### DO Use Modern Syntax

```boxlang
// ✅ GOOD - Modern BoxLang
class UserService {
    @inject
    property name="userDAO";

    list() {
        return userDAO.list()
    }
}
```

### DON'T Use CFML Legacy Syntax

```boxlang
// ❌ AVOID - Old CFML style
component {
    property name="userDAO" inject="UserDAO";

    function list() {
        return userDAO.list();
    }
}
```

### Use Type Hints

```boxlang
// ✅ GOOD - Type hints for clarity
function calculateTotal(
    required numeric price,
    required numeric quantity,
    numeric discount = 0
):numeric {
    var total = price * quantity
    return total - (total * discount / 100)
}
```

### Avoid Semicolons (Unless Required)

```boxlang
// ✅ GOOD - No semicolons needed
class Example {
    function demo() {
        var x = 1
        var y = 2
        return x + y
    }
}

// ✅ GOOD - Semicolon only for property declarations
class Service {
    @inject
    property name="dependency";  // Semicolon here is fine
}
```

## Common Mistakes

### ❌ Forgetting to Use `class` Instead of `component`

```boxlang
// Wrong
component extends="Base" {
}

// Right
class extends="Base" {
}
```

### ❌ Using `function` Keyword Unnecessarily

```boxlang
// Acceptable but not preferred
class Service {
    function myMethod() {
    }
}

// Preferred
class Service {
    myMethod() {
    }
}
```

### ❌ Not Using Property Injection Syntax

```boxlang
// Old style
class Service {
    property name="userDAO" inject="UserDAO";
}

// Modern style
class Service {
    @inject
    property name="userDAO";
}
```

## Testing BoxLang Syntax

```boxlang
component extends="testbox.system.BaseSpec" {
    function run() {
        describe( "BoxLang Syntax", () => {
            it( "should use modern class syntax", () => {
                var service = new models.UserService()
                expect( service ).toBeInstanceOf( "models.UserService" )
            })

            it( "should support property injection", () => {
                var service = getInstance( "UserService" )
                expect( service.getUserDAO() ).toBeComponent()
            })
        })
    }
}
```

## Additional Resources

- BoxLang Documentation: https://boxlang.ortusbooks.com
- Modern Syntax Guide: Focus on class-based development
- Migration Guide: Converting from CFML to BoxLang
