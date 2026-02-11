---
name: boxlang-functions
description: Master BoxLang function types, parameters, return types, closures, and functional programming patterns
category: boxlang
priority: high
---

# BoxLang Functions Skill

## When to Use This Skill

Use this skill when:
- Creating functions and methods
- Working with closures and callbacks
- Implementing functional programming patterns
- Using higher-order functions
- Optimizing function design

## Basic Function Syntax

### Modern Function Declaration (No `function` keyword)

```boxlang
class MathService {
    // Simple function
    add( numeric a, numeric b ) {
        return a + b
    }

    // With type hints
    multiply( required numeric a, required numeric b ):numeric {
        return a * b
    }

    // With default arguments
    power( required numeric base, numeric exponent = 2 ):numeric {
        return base ^ exponent
    }

    // No return type
    logOperation( required string operation ) {
        writeLog( "Operation: #operation#" )
    }
}
```

### Traditional Function Declaration (Optional `function` keyword)

```boxlang
class Service {
    // Still valid in BoxLang
    function calculate( required numeric value ) {
        return value * 2
    }
}
```

## Function Parameters

### Required vs Optional

```boxlang
class UserService {
    // Required parameters
    createUser( required string username, required string email ) {
        return {
            username: arguments.username,
            email: arguments.email,
            created: now()
        }
    }

    // Optional with defaults
    findUsers(
        string status = "active",
        numeric maxResults = 100,
        boolean includeDeleted = false
    ) {
        // Implementation
    }

    // Mixed required and optional
    sendEmail(
        required string to,
        required string subject,
        string from = "noreply@example.com",
        string replyTo = arguments.from
    ) {
        // Implementation
    }
}
```

### Named Arguments

```boxlang
// Function definition
function createProduct(
    required string name,
    required numeric price,
    string description = "",
    boolean active = true
) {
    return {
        name: arguments.name,
        price: arguments.price,
        description: arguments.description,
        active: arguments.active
    }
}

// Calling with named arguments
var product = createProduct(
    name = "Widget",
    price = 29.99,
    active = false
)
```

### Variable Arguments

```boxlang
class Logger {
    function log( required string level, required string message ) {
        var args = arguments
        var additionalData = {}

        // Capture any extra arguments
        for ( var key in args ) {
            if ( !listFindNoCase( "level,message", key ) ) {
                additionalData[key] = args[key]
            }
        }

        writeLog(
            type = level,
            text = message,
            application = serializeJSON( additionalData )
        )
    }
}

// Usage
logger.log(
    level = "error",
    message = "Failed to process",
    userId = 123,
    action = "checkout"
)
```

## Return Types

### Explicit Return Types

```boxlang
class Calculator {
    // Numeric return
    function sum( required array numbers ):numeric {
        return numbers.reduce( (acc, n) => acc + n, 0 )
    }

    // String return
    function format( required any value ):string {
        return toString( value )
    }

    // Boolean return
    function isValid( required struct data ):boolean {
        return structKeyExists( data, "id" ) && structKeyExists( data, "name" )
    }

    // Struct return
    function getConfig():struct {
        return {
            version: "1.0",
            debug: false
        }
    }

    // Array return
    function getItems():array {
        return [1, 2, 3, 4, 5]
    }
}
```

### Early Returns

```boxlang
class ValidationService {
    function validate( required struct user ):struct {
        // Early return for quick validation
        if ( !structKeyExists( user, "email" ) ) {
            return {
                valid: false,
                errors: ["Email is required"]
            }
        }

        if ( !isValid( "email", user.email ) ) {
            return {
                valid: false,
                errors: ["Email format is invalid"]
            }
        }

        // Main logic if all checks pass
        return {
            valid: true,
            errors: []
        }
    }
}
```

## Closures and Anonymous Functions

### Basic Closures

```boxlang
class Example {
    function demo() {
        // Anonymous function assigned to variable
        var greet = ( name ) => {
            return "Hello, #name#!"
        }

        // Call the closure
        var message = greet( "World" )

        // Multi-line closure
        var calculate = ( x, y ) => {
            var sum = x + y
            var product = x * y
            return { sum: sum, product: product }
        }
    }
}
```

### Closures with Scope Access

```boxlang
class Counter {
    function createCounter( numeric start = 0 ) {
        var count = start

        // Closure captures 'count' from outer scope
        return () => {
            count++  // Accesses outer variable
            return count
        }
    }
}

// Usage
var counter = new Counter().createCounter( 10 )
counter()  // Returns 11
counter()  // Returns 12
counter()  // Returns 13
```

### Passing Functions as Arguments

```boxlang
class ArrayProcessor {
    function process( required array items, required function callback ) {
        var results = []

        for ( var item in items ) {
            results.append( callback( item ) )
        }

        return results
    }
}

// Usage
var processor = new ArrayProcessor()

// Pass closure as callback
var doubled = processor.process(
    [1, 2, 3, 4, 5],
    ( n ) => n * 2
)

// Pass named function
function square( n ) {
    return n * n
}
var squared = processor.process( [1, 2, 3], square )
```

## Higher-Order Functions

### Array Iteration Methods

```boxlang
class DataProcessor {
    function processData( required array data ) {
        // map - transform each item
        var names = data.map( ( item ) => item.name )

        // filter - select items matching condition
        var activeUsers = data.filter( ( user ) => user.active )

        // reduce - accumulate values
        var total = data.reduce( ( sum, item ) => sum + item.price, 0 )

        // each - iterate without return
        data.each( ( item ) => {
            writeLog( item.toString() )
        })

        // find - get first matching item
        var admin = data.find( ( user ) => user.role == "admin" )

        // some - check if any match
        var hasActive = data.some( ( user ) => user.active )

        // every - check if all match
        var allValid = data.every( ( item ) => item.isValid() )

        return {
            names: names,
            activeUsers: activeUsers,
            total: total
        }
    }
}
```

### Struct Iteration Methods

```boxlang
class ConfigProcessor {
    function processConfig( required struct config ) {
        // map - transform values
        var upperCaseValues = config.map( ( key, value ) => uCase( value ) )

        // filter - select entries
        var requiredSettings = config.filter( ( key, value ) => {
            return key.startsWith( "required_" )
        })

        // each - iterate
        config.each( ( key, value ) => {
            writeLog( "#key#: #value#" )
        })

        return upperCaseValues
    }
}
```

### Custom Higher-Order Functions

```boxlang
class FunctionalUtils {
    // Compose - combine functions
    function compose( required function f, required function g ) {
        return ( x ) => f( g( x ) )
    }

    // Partial application
    function partial( required function fn, required array fixedArgs ) {
        return ( ...args ) => {
            var allArgs = fixedArgs.append( args, true )
            return fn( argumentCollection = allArgs )
        }
    }

    // Memoization
    function memoize( required function fn ) {
        var cache = {}

        return ( x ) => {
            if ( !cache.keyExists( x ) ) {
                cache[x] = fn( x )
            }
            return cache[x]
        }
    }
}

// Usage
var utils = new FunctionalUtils()

// Compose functions
var double = ( n ) => n * 2
var increment = ( n ) => n + 1
var doubleAndIncrement = utils.compose( increment, double )

doubleAndIncrement( 5 )  // Returns 11 (5 * 2 + 1)
```

## Callbacks and Event Handlers

```boxlang
class AsyncProcessor {
    function processAsync( required any data, required function onSuccess, function onError ) {
        try {
            // Process data
            var result = heavyProcessing( data )

            // Call success callback
            onSuccess( result )
        } catch ( any e ) {
            // Call error callback if provided
            if ( !isNull( arguments.onError ) ) {
                onError( e )
            }
        }
    }

    private function heavyProcessing( required any data ) {
        // Simulate processing
        return data
    }
}

// Usage
var processor = new AsyncProcessor()

processor.processAsync(
    data = myData,
    onSuccess = ( result ) => {
        writeOutput( "Success: #result#" )
    },
    onError = ( error ) => {
        writeLog( type="error", text=error.message )
    }
)
```

## Best Practices

### ✅ DO: Use Arrow Functions for Short Callbacks

```boxlang
// Good - concise
var doubled = numbers.map( ( n ) => n * 2 )

// Also good for multi-line
var processed = data.map( ( item ) => {
    var result = item.value * 2
    return result
})
```

### ✅ DO: Use Descriptive Parameter Names

```boxlang
// Good
function calculateDiscount( required numeric originalPrice, required numeric percentage ) {
    return originalPrice * (percentage / 100)
}

// Bad
function calculateDiscount( required numeric p, required numeric pct ) {
    return p * (pct / 100)
}
```

### ✅ DO: Return Early to Reduce Nesting

```boxlang
// Good
function getUser( required numeric id ) {
    if ( !id ) {
        return {}
    }

    if ( !userExists( id ) ) {
        return {}
    }

    return userDAO.get( id )
}

// Bad - excessive nesting
function getUser( required numeric id ) {
    if ( id ) {
        if ( userExists( id ) ) {
            return userDAO.get( id )
        }
    }
    return {}
}
```

### ✅ DO: Keep Functions Small and Focused

```boxlang
// Good - single responsibility
function validateEmail( required string email ) {
    return isValid( "email", email )
}

function validatePassword( required string password ) {
    return len( password ) >= 8 && reFind( "[0-9]", password )
}

function validateUser( required struct user ) {
    return validateEmail( user.email ) && validatePassword( user.password )
}
```

## Common Mistakes

### ❌ Not Handling Missing Arguments

```boxlang
// Wrong
function greet( name ) {
    return "Hello, #arguments.name#!"  // Fails if name not provided
}

// Right
function greet( string name = "Guest" ) {
    return "Hello, #arguments.name#!"
}

// Or check explicitly
function greet( string name ) {
    var userName = arguments.keyExists( "name" ) ? arguments.name : "Guest"
    return "Hello, #userName#!"
}
```

### ❌ Forgetting Return Statement

```boxlang
// Wrong - implicit null return
function double( numeric n ) {
    var result = n * 2
    // Missing return!
}

// Right
function double( numeric n ) {
    return n * 2
}
```

### ❌ Using Variables Scope in Closures Incorrectly

```boxlang
// Wrong - closure can't access argumentsscope directly
function filter( items, name ) {
    return items.filter( ( item ) => item.name == arguments.name )  // ❌ Fails!
}

// Right - capture the value
function filter( items, name ) {
    var targetName = name  // Capture in variables scope
    return items.filter( ( item ) => item.name == targetName )  // ✅ Works
}

// Or just reference unscoped
function filter( items, name ) {
    return items.filter( ( item ) => item.name == name )  // ✅ Works - searches outer scopes
}
```

## Testing Functions

```boxlang
component extends="testbox.system.BaseSpec" {
    function run() {
        describe( "MathService", () => {
            beforeEach( () => {
                variables.math = new models.MathService()
            })

            it( "should add numbers", () => {
                expect( math.add( 2, 3 ) ).toBe( 5 )
            })

            it( "should handle default arguments", () => {
                expect( math.power( 2 ) ).toBe( 4 )  // Uses default exponent of 2
                expect( math.power( 2, 3 ) ).toBe( 8 )
            })

            it( "should work with higher-order functions", () => {
                var numbers = [1, 2, 3, 4, 5]
                var doubled = numbers.map( ( n ) => math.multiply( n, 2 ) )
                expect( doubled ).toBe( [2, 4, 6, 8, 10] )
            })
        })
    }
}
```

## Additional Resources

- BoxLang Functions Documentation
- Functional Programming in BoxLang
- Lambda Expressions Guide
- Closure Scope Rules
