---
name: boxlang-types
description: Master BoxLang type system including type hints, type checking, type coercion, and strong typing for robust code
category: boxlang
priority: high
---

# BoxLang Types Skill

## When to Use This Skill

Use this skill when:
- Declaring function parameters and return types
- Defining class properties with type constraints
- Implementing type-safe interfaces and contracts
- Performing type checking and validation
- Working with generic types and type parameters
- Converting between different data types
- Ensuring type safety in large applications

## Type System Overview

### BoxLang Type System

BoxLang supports both dynamic and static typing, allowing developers to choose the level of type safety appropriate for their application.

```boxlang
// Dynamic typing (traditional)
function getValue() {
    return "hello"
}

// Static typing (with type hints)
function getValue(): string {
    return "hello"
}
```

## Basic Type Annotations

### Function Parameter Types

```boxlang
// Simple types
function greet( string name ) {
    return "Hello, #name#"
}

// Multiple parameters with types
function calculateTotal( numeric price, numeric quantity, boolean includeTax ) {
    var subtotal = price * quantity
    return includeTax ? subtotal * 1.1 : subtotal
}

// Optional parameters with types
function formatName( string firstName, string lastName = "", boolean uppercase = false ) {
    var fullName = firstName & " " & lastName
    return uppercase ? uCase( fullName ) : fullName
}

// Required parameters
function processUser( required string email, required numeric userId ) {
    // Both parameters are required
    return { email: email, id: userId }
}
```

### Function Return Types

```boxlang
// Explicit return type
function getUsers(): array {
    return [ "user1", "user2", "user3" ]
}

// Numeric return type
function calculateSum( numeric a, numeric b ): numeric {
    return a + b
}

// Struct return type
function getUserData( numeric id ): struct {
    return {
        id: id,
        name: "John Doe",
        email: "john@example.com"
    }
}

// Query return type
function fetchUsers(): query {
    return queryExecute( "SELECT * FROM users" )
}

// Void return type (no return value)
function logMessage( string message ): void {
    writeLog( message )
    // No return statement needed
}
```

### Property Types

```boxlang
@accessors=true
class User {
    // Simple property types
    property name="id" type="numeric";
    property name="username" type="string";
    property name="email" type="string";
    property name="active" type="boolean" default="true";

    // Date type
    property name="createdDate" type="date";

    // Array type
    property name="roles" type="array" default=[];

    // Struct type
    property name="metadata" type="struct" default={};

    // Component type
    property name="profile" type="Profile";
}
```

## Built-in Types

### Primitive Types

```boxlang
// String
var name: string = "John Doe"
var description: string = "A long text..."

// Numeric (integers and decimals)
var age: numeric = 30
var price: numeric = 29.99
var count: numeric = 100

// Boolean
var isActive: boolean = true
var hasPermission: boolean = false

// Date
var birthDate: date = now()
var eventDate: date = createDate( 2024, 12, 25 )
```

### Complex Types

```boxlang
// Array
var numbers: array = [ 1, 2, 3, 4, 5 ]
var names: array = [ "Alice", "Bob", "Charlie" ]
var mixed: array = [ 1, "two", true, now() ]

// Struct
var user: struct = {
    id: 1,
    name: "John",
    email: "john@example.com"
}

// Query
var users: query = queryExecute( "SELECT * FROM users" )

// Component/Class
var userService: UserService = new UserService()
var validator: IValidator = new EmailValidator()
```

### Special Types

```boxlang
// Any type (accepts anything)
function processData( any data ): any {
    return data
}

// Void type (no return value)
function logEvent( string event ): void {
    writeLog( event )
}

// Null type
var result: nullable string = null
var maybeUser: nullable User = getUserById( id )
```

## Type Checking and Validation

### Runtime Type Checking

```boxlang
// Check variable type
var value = "hello"
if ( isSimpleValue( value ) ) {
    writeOutput( "Simple value" )
}

// Type checking functions
isArray( [] )              // true
isStruct( {} )             // true
isNumeric( 42 )            // true
isBoolean( true )          // true
isDate( now() )            // true
isQuery( users )           // true
isComponent( userService ) // true

// Check specific component type
if ( isInstanceOf( user, "User" ) ) {
    // user is instanceof User
}
```

### Type Guards

```boxlang
function processValue( any value ): string {
    // Type guard with isNumeric
    if ( isNumeric( value ) ) {
        return "Number: #value#"
    }

    // Type guard with isArray
    if ( isArray( value ) ) {
        return "Array with #arrayLen( value )# items"
    }

    // Type guard with isStruct
    if ( isStruct( value ) ) {
        return "Struct with #structCount( value )# keys"
    }

    // Default case
    return "String: #value#"
}
```

### Type Assertions

```boxlang
// Assert parameter types
function divide( numeric a, numeric b ): numeric {
    if ( !isNumeric( a ) || !isNumeric( b ) ) {
        throw( type="InvalidArgument", message="Both arguments must be numeric" )
    }

    if ( b == 0 ) {
        throw( type="DivisionByZero", message="Cannot divide by zero" )
    }

    return a / b
}

// Assert return type
function getUsers(): array {
    var users = queryToArray( queryExecute( "SELECT * FROM users" ) )

    if ( !isArray( users ) ) {
        throw( type="InvalidReturnType", message="Expected array" )
    }

    return users
}
```

## Type Coercion and Conversion

### Automatic Type Coercion

```boxlang
// String to numeric
var sum = "10" + 5  // 15 (string coerced to number)

// Numeric to string
var text = "Value: " & 42  // "Value: 42" (number coerced to string)

// Boolean to string
var flag = true
var message = "Active: " & flag  // "Active: true"
```

### Explicit Type Conversion

```boxlang
// To string
var text = toString( 42 )
var json = serializeJSON( { name: "John" } )

// To numeric
var number = val( "123" )
var parsed = parseNumber( "1,234.56" )

// To boolean
var flag = parseBoolean( "true" )
var isTrue = ( "yes" == "yes" )  // true

// To date
var date = parseDateTime( "2024-12-25" )
var timestamp = now()

// To array
var arr = listToArray( "a,b,c" )
var queryArr = queryToArray( users )

// To struct
var obj = deserializeJSON( '{"name":"John"}' )
var converted = queryRowToStruct( users, 1 )
```

### Safe Type Conversion

```boxlang
// Try conversion with error handling
function safeParseNumber( string value ): numeric {
    try {
        return val( value )
    } catch ( any e ) {
        return 0  // Default value
    }
}

// Nullable conversion
function parseOptionalNumber( string value ): nullable numeric {
    if ( !isNumeric( value ) ) {
        return null
    }
    return val( value )
}

// Conversion with validation
function convertToDate( string value ): date {
    if ( !isDate( value ) ) {
        throw( type="InvalidDate", message="Cannot convert '#value#' to date" )
    }
    return parseDateTime( value )
}
```

## Generic Types and Type Parameters

### Generic Functions

```boxlang
// Generic function with type parameter
function<T> firstElement( array<T> items ): T {
    if ( items.isEmpty() ) {
        throw( message="Array is empty" )
    }
    return items[1]
}

// Usage
var firstNumber = firstElement<numeric>( [ 1, 2, 3 ] )  // numeric
var firstString = firstElement<string>( [ "a", "b" ] )  // string

// Generic with constraints
function<T extends BaseService> processService( T service ): struct {
    return {
        name: service.getName(),
        status: service.getStatus()
    }
}
```

### Generic Classes

```boxlang
// Generic class
class Repository<T> {
    private array items = []

    function add( T item ): void {
        items.append( item )
    }

    function getAll(): array<T> {
        return items
    }

    function findById( numeric id ): nullable T {
        return items.find( ( item ) => item.id == id )
    }
}

// Usage
var userRepo = new Repository<User>()
userRepo.add( new User( id: 1, name: "John" ) )

var productRepo = new Repository<Product>()
productRepo.add( new Product( id: 1, name: "Widget" ) )
```

## Interface Type Definitions

### Defining Interfaces

```boxlang
interface IRepository {
    // Method signatures with types
    function save( any entity ): numeric;
    function findById( numeric id ): nullable any;
    function findAll(): array;
    function delete( numeric id ): boolean;
}

interface IValidator {
    function validate( any data ): struct;
    function isValid( any data ): boolean;
}
```

### Implementing Interfaces

```boxlang
class UserRepository implements IRepository {

    function save( any entity ): numeric {
        // Implementation
        return entitySave( entity )
    }

    function findById( numeric id ): nullable any {
        return entityLoadByPK( "User", id )
    }

    function findAll(): array {
        return entityLoad( "User" )
    }

    function delete( numeric id ): boolean {
        var entity = findById( id )
        if ( !isNull( entity ) ) {
            entityDelete( entity )
            return true
        }
        return false
    }
}
```

## Nullable Types

### Working with Null Values

```boxlang
// Nullable parameter
function getUserById( numeric id ): nullable User {
    var user = queryExecute(
        "SELECT * FROM users WHERE id = :id",
        { id: id }
    )

    if ( user.recordCount == 0 ) {
        return null
    }

    return mapUser( user )
}

// Null checking
var user = getUserById( 1 )
if ( !isNull( user ) ) {
    writeOutput( user.getName() )
} else {
    writeOutput( "User not found" )
}

// Elvis operator for null coalescing
var name = user?.getName() ?: "Unknown"
var email = user?.getEmail() ?: "no-email@example.com"
```

### Optional Chaining

```boxlang
// Safe navigation
var city = user?.getAddress()?.getCity() ?: "Unknown"

// Array/struct safe access
var value = data?.items?[1]?.name ?: "N/A"

// With function calls
var count = service?.getUsers()?.len() ?: 0
```

## Type Aliases and Custom Types

### Defining Type Aliases

```boxlang
// Type alias for complex types
typedef UserId = numeric
typedef EmailAddress = string
typedef UserData = struct

// Using type aliases
function getUserById( UserId id ): nullable User {
    // Implementation
}

function sendEmail( EmailAddress to, string subject, string body ): void {
    // Implementation
}

function processUserData( UserData data ): User {
    // Implementation
}
```

### Union Types

```boxlang
// Function accepting multiple types
function processInput( string|numeric|boolean value ): string {
    if ( isNumeric( value ) ) {
        return "Number: #value#"
    } else if ( isBoolean( value ) ) {
        return "Boolean: #value#"
    } else {
        return "String: #value#"
    }
}

// Nullable as union type
typedef nullable string = string | null
```

## Best Practices

### ✅ DO: Use Type Hints for Public APIs

```boxlang
// Good - Clear contract
class UserService {
    function createUser( required string email, required string name ): User {
        return new User( email: email, name: name )
    }

    function getUserById( required numeric id ): nullable User {
        return find( id )
    }
}

// Avoid - Unclear what's expected
class UserService {
    function createUser( email, name ) {
        return new User( email: email, name: name )
    }
}
```

### ✅ DO: Use Strict Types in Critical Code

```boxlang
// Good - Type safety in financial code
class PaymentProcessor {
    function processPayment(
        required numeric amount,
        required string currency,
        required struct cardData
    ): struct {
        if ( !isNumeric( amount ) || amount <= 0 ) {
            throw( type="InvalidAmount" )
        }

        // Process payment
        return { success: true, transactionId: generateId() }
    }
}
```

### ✅ DO: Document Complex Types

```boxlang
/**
 * Process user registration
 *
 * @param userData struct { email: string, name: string, age: numeric }
 * @return User The created user instance
 */
function register( required struct userData ): User {
    // Implementation
}
```

### ✅ DO: Use Nullable for Optional Returns

```boxlang
// Good - Clear that result might be null
function findUser( string email ): nullable User {
    var users = getUsersByEmail( email )
    return users.isEmpty() ? null : users[1]
}

// Use it safely
var user = findUser( "john@example.com" )
if ( !isNull( user ) ) {
    process( user )
}
```

### ✅ DO: Validate Types at Boundaries

```boxlang
// Good - Validate at API boundaries
function apiHandler( event, rc, prc ) {
    // Validate input types
    if ( !isNumeric( rc.userId ?: "" ) ) {
        return { error: "Invalid user ID" }
    }

    var userId = val( rc.userId )
    var user = userService.getUserById( userId )

    return { data: user }
}
```

## Common Mistakes

### ❌ Not Checking Types Before Use

```boxlang
// Wrong - Assumes type without checking
function processValue( any value ) {
    return value.toUpperCase()  // ❌ Fails if not string
}

// Right - Check type first
function processValue( any value ): string {
    if ( !isSimpleValue( value ) ) {
        throw( type="InvalidType", message="Expected simple value" )
    }
    return toString( value ).toUpperCase()
}
```

### ❌ Ignoring Null Values

```boxlang
// Wrong - Doesn't handle null
function getUserName( numeric id ): string {
    var user = getUserById( id )
    return user.getName()  // ❌ Fails if user is null
}

// Right - Handle null case
function getUserName( numeric id ): string {
    var user = getUserById( id )
    return !isNull( user ) ? user.getName() : "Unknown"
}
```

### ❌ Loose Type Comparisons

```boxlang
// Wrong - Loose comparison
if ( value == true ) {  // ❌ "1" == true is true
    doSomething()
}

// Right - Strict type check
if ( isBoolean( value ) && value == true ) {
    doSomething()
}
```

### ❌ Assuming Type Coercion Always Works

```boxlang
// Wrong - Assumes coercion
function calculate( value1, value2 ) {
    return value1 + value2  // ❌ Might concatenate strings
}

// Right - Explicit types
function calculate( numeric value1, numeric value2 ): numeric {
    return value1 + value2  // ✅ Always adds numbers
}
```

## Testing Type Safety

```boxlang
component extends="testbox.system.BaseSpec" {

    function run() {
        describe( "Type Safety", () => {

            it( "should enforce parameter types", () => {
                var service = new UserService()

                // This should work
                var user = service.createUser(
                    email: "test@example.com",
                    name: "Test User"
                )
                expect( user ).toBeInstanceOf( "User" )

                // This should fail
                expect( function() {
                    service.createUser(
                        email: 123,  // Wrong type
                        name: "Test"
                    )
                }).toThrow()
            })

            it( "should return correct types", () => {
                var result = mathService.add( 5, 3 )

                expect( result ).toBeNumeric()
                expect( result ).toBe( 8 )
            })

            it( "should handle nullable returns", () => {
                var user = userService.findByEmail( "nonexistent@example.com" )

                expect( isNull( user ) ).toBeTrue()
            })

            it( "should validate type conversions", () => {
                expect( toString( 42 ) ).toBe( "42" )
                expect( val( "123" ) ).toBe( 123 )
                expect( parseBoolean( "true" ) ).toBeTrue()
            })
        })
    }
}
```

## Additional Resources

- BoxLang Type System Documentation
- Type Hints and Annotations Guide
- Strong Typing Best Practices
- Type Safety in Large Applications
- Generic Programming in BoxLang
- Interface Design Patterns
- Null Safety Techniques
