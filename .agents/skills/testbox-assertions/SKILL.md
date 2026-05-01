---
name: testbox-assertions
description: "Use this skill when using the TestBox $assert object for xUnit-style assertions: isTrue, isEqual, includes, isEmpty, key, instanceOf, throws, between, closeTo, lengthOf, match, null, typeOf, and others; registering custom assertion functions with addAssertions(); or using BoxLang dynamic assertion methods (assertIsTrue, assertBetween, etc.)."
---

# TestBox Assertions — `$assert` Reference

## When to Use This Skill

- Writing xUnit-style assertions using the `$assert` object in test functions
- Using the full `testbox.system.Assertion` API for validation
- Registering inline or class-based custom assertions with `addAssertions()`
- Using BoxLang dynamic `assertXxx()` method variants

---

## The `$assert` Object

Every TestBox bundle receives `$assert` — an instance of `testbox.system.Assertion`. It is available in both xUnit test functions and BDD `it()` blocks.

```boxlang
function testUserCreation() {
    var user = userService.create( { name: "Alice", email: "alice@example.com" } )
    $assert.isNotNull( user )
    $assert.isEqual( "Alice", user.name )
    $assert.typeOf( "struct", user )
}
```

---

## Complete Assertion Reference

### Boolean

```boxlang
$assert.isTrue( actual, [message] )
$assert.isFalse( actual, [message] )
```

### Equality

```boxlang
$assert.isEqual( expected, actual, [message] )                // case-insensitive
$assert.isEqualWithCase( expected, actual, [message] )
$assert.isNotEqual( expected, actual, [message] )
```

### Null

```boxlang
$assert.null( actual, [message] )
$assert.notNull( actual, [message] )
```

### Emptiness

```boxlang
$assert.isEmpty( target, [message] )      // array, struct, string, query
$assert.isNotEmpty( target, [message] )
```

### Size / Length

```boxlang
$assert.lengthOf( target, length, [message] )
$assert.notLengthOf( target, length, [message] )
```

### Key Existence (Structs)

```boxlang
$assert.key( target, key, [message] )
$assert.notKey( target, key, [message] )
$assert.deepKey( target, key, [message] )        // recursive search
$assert.notDeepKey( target, key, [message] )
```

### Inclusion (Strings / Arrays)

```boxlang
$assert.includes( target, needle, [message] )              // case-insensitive
$assert.includesWithCase( target, needle, [message] )
$assert.notIncludes( target, needle, [message] )
$assert.notIncludesWithCase( target, needle, [message] )
```

### Type Checks

```boxlang
$assert.typeOf( type, actual, [message] )       // uses isValid() under the hood
$assert.notTypeOf( type, actual, [message] )
$assert.instanceOf( actual, typeName, [message] )
$assert.notInstanceOf( actual, typeName, [message] )
```

Common `type` values: `array`, `struct`, `component`, `numeric`, `boolean`, `date`, `string`, `uuid`, `email`, `url`, `query`

### Numeric Comparisons

```boxlang
$assert.isGT( actual, target, [message] )
$assert.isGTE( actual, target, [message] )
$assert.isLT( actual, target, [message] )
$assert.isLTE( actual, target, [message] )
$assert.between( actual, min, max, [message] )
$assert.closeTo( expected, actual, delta, [datePart], [message] )
```

### String / Regex

```boxlang
$assert.match( actual, regex, [message] )            // case-insensitive
$assert.matchWithCase( actual, regex, [message] )
$assert.notMatch( actual, regex, [message] )
```

### Exceptions

```boxlang
// Assert a closure THROWS
$assert.throws( target, [type], [regex], [message] )

// target must be a closure/function reference
$assert.throws( () => service.delete( 999 ), "NotFoundException" )
$assert.throws( () => service.delete( 999 ), "NotFoundException", "999" )

// Assert a closure DOES NOT throw
$assert.notThrows( target, [type], [regex], [message] )
$assert.notThrows( () => service.safeOperation() )
```

### Force Pass/Fail/Skip

```boxlang
$assert.fail( [message] )             // forcibly fail the test
$assert.skip( message, [detail] )     // skip current test with a message
```

### Generic Expression Assert

```boxlang
$assert.assert( expression, [message] )
// example:
$assert.assert( user.age >= 18, "User must be an adult" )
```

---

## BoxLang Dynamic Assertion Methods

When running tests in BoxLang, you can call any `$assert` method as a top-level function by prefixing it with `assert`:

```boxlang
// Standard $assert style
$assert.isTrue( myBool )
$assert.isEqual( expected, actual )
$assert.between( value, 1, 100 )

// BoxLang dynamic method style (identical behaviour)
assertIsTrue( myBool )
assertIsEqual( expected, actual )
assertBetween( value, 1, 100 )
assertThrows( () => badCall(), "MyException" )
assertCloseTo( 3.14, 3.14159, 0.01 )
```

---

## Common Assertion Patterns

```boxlang
// Struct shape
$assert.isNotEmpty( responseData )
$assert.key( responseData, "id" )
$assert.key( responseData, "name" )
$assert.typeOf( "numeric", responseData.id )

// Array contents
$assert.typeOf( "array", results )
$assert.isNotEmpty( results )
$assert.lengthOf( results, 3 )
$assert.includes( results, "expectedValue" )

// Exception handling
$assert.throws(
    () => userService.findById( -1 ),
    "ValidationException",
    "-1"
)

// Approximate date equality
$assert.closeTo(
    expected: now(),
    actual:   user.createdAt,
    delta:    2,
    datePart: "s"
)
```

---

## Custom Assertions

### Inline Registration

Register in `beforeTests()` (xUnit) or `beforeAll()` (BDD) to keep assertions clean across specs:

```boxlang
function beforeTests() {
    addAssertions( {

        isValidEmail: function( actual ) {
            return isValid( "email", actual )
                ? true
                : fail( "[#actual#] is not a valid email address" )
        },

        isUUID: function( actual ) {
            return isValid( "uuid", actual )
                ? true
                : fail( "[#actual#] is not a UUID" )
        },

        hasNoErrors: function( actual ) {
            return ( actual.keyExists( "errors" ) && !actual.errors.isEmpty() )
                ? fail( "Response has errors: #serializeJSON( actual.errors )#" )
                : true
        }

    } )
}

// Usage
function testEmailValidation() {
    $assert.isValidEmail( "alice@example.com" )     // passes
    $assert.isValidEmail( "not-an-email" )           // fails
    $assert.isUUID( createUUID() )
}
```

### Class-Based Assertion Library

For shared, reusable assertions across multiple test bundles:

```boxlang
// tests/helpers/AppAssertions.cfc
component {

    function assertIsActiveUser( expected, actual ) {
        return ( actual.keyExists( "isActive" ) && actual.isActive )
            ? true
            : fail( "User [#actual.name ?: 'unknown'#] is not active" )
    }

    function assertHasPermission( expected, actual ) {
        return ( actual.permissions.findNoCase( expected ) > 0 )
            ? true
            : fail( "User does not have permission [#expected#]" )
    }

    function assertResponseSuccess( expected, actual ) {
        return actual.success
            ? true
            : fail( "Response was not successful. Message: #actual.message ?: ''#" )
    }

}
```

```boxlang
function beforeTests() {
    // Single class
    addAssertions( "tests.helpers.AppAssertions" )

    // Multiple classes
    addAssertions( "tests.helpers.AppAssertions,tests.helpers.SecurityAssertions" )
    // or array:
    addAssertions( [ "tests.helpers.AppAssertions", "tests.helpers.SecurityAssertions" ] )
}

function testAdminUser() {
    var admin = userService.findById( 1 )
    $assert.isActiveUser( admin )
    $assert.hasPermission( "ADMIN", admin )
}
```

---

## `$assert` vs `expect()` Guide

Use `$assert` when:
- Writing xUnit-style test functions
- You prefer imperative `isEqual( a, b )` syntax
- You need `assert( expression )` for arbitrary boolean checks

Use `expect()` when:
- Writing BDD specs
- You want fluent chaining: `expect( x ).toBe( y ).toHaveKey( "z" )`
- You want `expectAll()` for collection assertions
- You want custom matchers with `not` negation

Both are available in the same bundle — mix freely.
