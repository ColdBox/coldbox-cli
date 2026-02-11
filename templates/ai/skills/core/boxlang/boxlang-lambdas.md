---
name: boxlang-lambdas
description: Master lambda expressions, arrow functions, and functional programming with BoxLang closures
category: boxlang
priority: high
---

# BoxLang Lambdas Skill

## When to Use This Skill

Use this skill when:
- Writing concise inline functions
- Working with array/struct iteration methods
- Implementing functional programming patterns
- Creating callbacks and event handlers
- Simplifying code with arrow syntax

## Lambda Arrow Functions

### Basic Arrow Syntax

```boxlang
class LambdaExamples {
    function demonstrateBasics() {
        // Simple arrow function
        var double = ( n ) => n * 2

        // Multiple parameters
        var add = ( a, b ) => a + b

        // No parameters
        var getTimestamp = () => now()

        // Single parameter (parentheses optional)
        var square = n => n * n

        // Call the lambdas
        var result1 = double( 5 )        // 10
        var result2 = add( 3, 7 )         // 10
        var result3 = getTimestamp()      // Current datetime
        var result4 = square( 4 )         // 16
    }
}
```

### Multi-Line Lambdas

```boxlang
class ComplexLambdas {
    function demo() {
        // Lambda with block body
        var processUser = ( user ) => {
            var fullName = "#user.firstName# #user.lastName#"
            var email = lCase( user.email )
            return {
                name: fullName,
                email: email,
                active: user.active?: true
            }
        }

        // Lambda with multiple statements
        var validate = ( data ) => {
            if ( !structKeyExists( data, "email" ) ) {
                return { valid: false, error: "Email required" }
            }

            if ( !isValid( "email", data.email ) ) {
                return { valid: false, error: "Invalid email" }
            }

            return { valid: true }
        }
    }
}
```

## Lambdas with Array Methods

### Map - Transform Elements

```boxlang
class ArrayTransformations {
    function transformData( required array users ) {
        // Extract property
        var names = users.map( ( user ) => user.name )

        // Transform to different structure
        var userDTOs = users.map( ( user ) => {
            return {
                id: user.getId(),
                display: "#user.getName()# (#user.getEmail()#)",
                metadata: {
                    created: user.getCreatedDate(),
                    status: user.getStatus()
                }
            }
        })

        // Chain transformations
        var initials = users
            .map( ( u ) => u.name )
            .map( ( name ) => name.split( " " ) )
            .map( ( parts ) => parts.map( ( p ) => left( p, 1 ) ).toList( "" ) )

        return {
            names: names,
            dtos: userDTOs,
            initials: initials
        }
    }
}
```

### Filter - Select Elements

```boxlang
class ArrayFiltering {
    function filterData( required array items ) {
        // Simple condition
        var active = items.filter( ( item ) => item.active )

        // Complex condition
        var qualifiedUsers = items.filter( ( user ) => {
            return user.age >= 18
                && user.verified
                && !user.banned
        })

        // With index parameter
        var evenIndexed = items.filter( ( item, index ) => {
            return index % 2 == 0
        })

        // Chaining filters
        var result = items
            .filter( ( item ) => item.type == "premium" )
            .filter( ( item ) => item.price > 100 )
            .filter( ( item ) => item.inStock )

        return {
            active: active,
            qualified: qualifiedUsers,
            result: result
        }
    }
}
```

### Reduce - Accumulate Values

```boxlang
class ArrayReduction {
    function aggregateData( required array numbers ) {
        // Sum
        var total = numbers.reduce( ( sum, n ) => sum + n, 0 )

        // Product
        var product = numbers.reduce( ( acc, n ) => acc * n, 1 )

        // Max value
        var max = numbers.reduce( ( max, n ) => n > max ? n : max, numbers[1] )

        // Build object
        var users = [
            { id: 1, name: "John" },
            { id: 2, name: "Jane" }
        ]
        var userMap = users.reduce( ( map, user ) => {
            map[user.id] = user.name
            return map
        }, {})

        // Group by property
        var orders = [
            { status: "completed", amount: 100 },
            { status: "pending", amount: 50 },
            { status: "completed", amount: 75 }
        ]
        var grouped = orders.reduce( ( acc, order ) => {
            if ( !structKeyExists( acc, order.status ) ) {
                acc[order.status] = []
            }
            acc[order.status].append( order )
            return acc
        }, {})

        return {
            total: total,
            product: product,
            max: max,
            userMap: userMap,
            grouped: grouped
        }
    }
}
```

### Each - Side Effects

```boxlang
class ArrayIteration {
    @inject
    property name="log";

    function processItems( required array items ) {
        // Log each item
        items.each( ( item ) => {
            log.info( "Processing: #item.name#" )
        })

        // With index
        items.each( ( item, index ) => {
            log.debug( "#index#: #item#" )
        })

        // Multiple operations
        items.each( ( item ) => {
            var validated = validate( item )
            if ( validated.success ) {
                save( item )
                notify( item )
            }
        })
    }
}
```

### Find - Locate Element

```boxlang
class ArraySearch {
    function findItems( required array users ) {
        // Find first match
        var admin = users.find( ( user ) => user.role == "admin" )

        // Find with complex condition
        var targetUser = users.find( ( user ) => {
            return user.department == "Engineering"
                && user.level >= 5
        })

        // Some - check if any match
        var hasAdmin = users.some( ( user ) => user.role == "admin" )

        // Every - check if all match
        var allVerified = users.every( ( user ) => user.verified )

        return {
            admin: admin,
            target: targetUser,
            hasAdmin: hasAdmin,
            allVerified: allVerified
        }
    }
}
```

## Lambdas with Struct Methods

### Struct Map

```boxlang
class StructTransform {
    function processConfig( required struct config ) {
        // Transform all values
        var upperConfig = config.map( ( key, value ) => uCase( value ) )

        // Transform with key and value
        var prefixed = config.map( ( key, value ) => {
            return "APP_#uCase(key)#:#value#"
        })

        // Build new structure
        var normalized = config.map( ( key, value ) => {
            return {
                key: key,
                value: value,
                type: isNumeric( value ) ? "number" : "string"
            }
        })

        return {
            upper: upperConfig,
            prefixed: prefixed,
            normalized: normalized
        }
    }
}
```

### Struct Filter

```boxlang
class StructFiltering {
    function filterSettings( required struct settings ) {
        // Filter by key
        var dbSettings = settings.filter( ( key, value ) => {
            return key.startsWith( "db_" )
        })

        // Filter by value
        var enabledFeatures = settings.filter( ( key, value ) => {
            return isBoolean( value ) && value == true
        })

        // Complex filtering
        var required = settings.filter( ( key, value ) => {
            return key.endsWith( "_required" ) && !isNull( value )
        })

        return {
            database: dbSettings,
            enabled: enabledFeatures,
            required: required
        }
    }
}
```

### Struct Each

```boxlang
class StructIteration {
    function validateConfig( required struct config ) {
        var errors = []

        // Validate each entry
        config.each( ( key, value ) => {
            if ( isNull( value ) || value == "" ) {
                errors.append( "Missing value for: #key#" )
            }
        })

        return {
            valid: errors.isEmpty(),
            errors: errors
        }
    }
}
```

## Closure Scope and Variable Capture

### Accessing Outer Scope

```boxlang
class ScopeExample {
    function createMultiplier( required numeric factor ) {
        // Lambda captures 'factor' from outer scope
        return ( n ) => n * factor
    }

    function createCounter( numeric start = 0 ) {
        var count = start

        // Closure maintains reference to 'count'
        return () => {
            count++
            return count
        }
    }

    function createGreeter( required string prefix ) {
        // Multiple closures sharing same scope
        return {
            greet: ( name ) => "#prefix# #name#!",
            farewell: ( name ) => "#prefix# goodbye, #name#!",
            getPrefix: () => prefix
        }
    }
}

// Usage
var times2 = new ScopeExample().createMultiplier( 2 )
var times5 = new ScopeExample().createMultiplier( 5 )

times2( 10 )  // 20
times5( 10 )  // 50

var counter = new ScopeExample().createCounter( 10 )
counter()  // 11
counter()  // 12

var greeter = new ScopeExample().createGreeter( "Hello" )
greeter.greet( "World" )  // "Hello World!"
```

### Variable Capture in Loops

```boxlang
class LoopCapture {
    function createHandlers() {
        var handlers = []

        // WRONG - all closures reference same 'i'
        for ( var i = 1; i <= 3; i++ ) {
            handlers.append( () => i )  // ❌ All return 4!
        }

        // RIGHT - capture value in new scope
        var correctHandlers = []
        for ( var i = 1; i <= 3; i++ ) {
            var value = i  // Create new variable
            correctHandlers.append( () => value )  // ✅ Each returns correct value
        }

        // BEST - use array methods
        var bestHandlers = [1, 2, 3].map( ( n ) => () => n )

        return {
            wrong: handlers.map( ( h ) => h() ),      // [4, 4, 4]
            correct: correctHandlers.map( ( h ) => h() ),  // [1, 2, 3]
            best: bestHandlers.map( ( h ) => h() )    // [1, 2, 3]
        }
    }
}
```

## Practical Patterns

### Pipeline Processing

```boxlang
class Pipeline {
    function processUsers( required array users ) {
        return users
            .filter( ( u ) => u.active )
            .filter( ( u ) => u.verified )
            .map( ( u ) => {
                return {
                    id: u.id,
                    name: u.name,
                    email: lCase( u.email ),
                    displayName: uCase( u.name )
                }
            })
            .sort( ( a, b ) => compare( a.name, b.name ) )
    }
}
```

### Partial Application

```boxlang
class PartialApplication {
    function multiply( required numeric a, required numeric b ) {
        return a * b
    }

    function createPartial( required function fn, required array fixedArgs ) {
        return ( ...args ) => {
            var allArgs = duplicate( fixedArgs )
            for ( var arg in args ) {
                allArgs.append( arg )
            }
            return fn( argumentCollection = allArgs )
        }
    }

    function demo() {
        // Create specialized function
        var double = createPartial( multiply, [2] )
        var triple = createPartial( multiply, [3] )

        double( 5 )  // 10
        triple( 5 )  // 15
    }
}
```

### Memoization

```boxlang
class Memoization {
    function memoize( required function fn ) {
        var cache = {}

        return ( x ) => {
            var key = toString( x )

            if ( !cache.keyExists( key ) ) {
                cache[key] = fn( x )
            }

            return cache[key]
        }
    }

    function demo() {
        // Expensive function
        var fibonacci = ( n ) => {
            if ( n <= 1 ) return n
            return fibonacci( n - 1 ) + fibonacci( n - 2 )
        }

        // Memoized version
        var fastFib = memoize( fibonacci )

        fastFib( 40 )  // Fast on subsequent calls
    }
}
```

## Best Practices

### ✅ DO: Use Arrow Functions for Short Operations

```boxlang
// Good - concise and clear
var doubled = numbers.map( ( n ) => n * 2 )
var active = users.filter( ( u ) => u.active )
var names = users.map( ( u ) => u.name )
```

### ✅ DO: Use Blocks for Complex Logic

```boxlang
// Good - multi-line when needed
var processed = items.map( ( item ) => {
    var validated = validate( item )
    var transformed = transform( validated )
    var enriched = enrich( transformed )
    return enriched
})
```

### ✅ DO: Be Careful with Scope in Closures

```boxlang
// Good - capture value explicitly
function createHandlers( items ) {
    return items.map( ( item ) => {
        return () => process( item )  // Captures item value
    })
}
```

### ❌ DON'T: Use arguments Scope in Lambdas

```boxlang
// Wrong
function filter( items, status ) {
    return items.filter( ( item ) => item.status == arguments.status )  // ❌ Fails!
}

// Right
function filter( items, status ) {
    return items.filter( ( item ) => item.status == status )  // ✅ Works
}
```

## Testing Lambdas

```boxlang
component extends="testbox.system.BaseSpec" {
    function run() {
        describe( "Lambda Functions", () => {
            it( "should map arrays", () => {
                var numbers = [1, 2, 3]
                var doubled = numbers.map( ( n ) => n * 2 )
                expect( doubled ).toBe( [2, 4, 6] )
            })

            it( "should filter arrays", () => {
                var numbers = [1, 2, 3, 4, 5]
                var evens = numbers.filter( ( n ) => n % 2 == 0 )
                expect( evens ).toBe( [2, 4] )
            })

            it( "should reduce arrays", () => {
                var numbers = [1, 2, 3, 4, 5]
                var sum = numbers.reduce( ( acc, n ) => acc + n, 0 )
                expect( sum ).toBe( 15 )
            })

            it( "should capture closure scope", () => {
                var counter = createCounter( 10 )
                expect( counter() ).toBe( 11 )
                expect( counter() ).toBe( 12 )
            })
        })
    }

    private function createCounter( start ) {
        var count = start
        return () => ++count
    }
}
```

## Additional Resources

- BoxLang Lambda Documentation
- Functional Programming Guide
- Closure Scope Rules
- Array and Struct Methods
