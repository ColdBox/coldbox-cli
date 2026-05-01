---
name: testbox-expectations
description: "Use this skill when writing fluent expectations in TestBox using expect(), expectAll(), all built-in matchers (toBe, toBeTrue, toBeArray, toHaveKey, toThrow, toMatch, toBeBetween, toBeCloseTo, toInclude, etc.), the not operator (notToBe, notToBeEmpty, etc.), chaining multiple matchers on one expect(), creating custom matchers with addMatchers(), or using expectAll() over collections."
---

# TestBox Expectations — Fluent Assertion DSL

## When to Use This Skill

- Writing fluent `expect( actual ).toBeXxx()` assertions in BDD or xUnit bundles
- Chaining multiple matchers on a single `expect()` call
- Using `expectAll()` to assert every element in an array or struct
- Using the `not` operator to negate any matcher (`notToBe`, `notToBeEmpty`, etc.)
- Building and registering custom matchers with `addMatchers()`

---

## Core Pattern

```boxlang
// expect( actual ).matcher( expected )
expect( result ).toBe( "hello" )

// Chained matchers on same actual value
expect( myArray )
    .toBeArray()
    .notToBeEmpty()
    .toHaveLength( 3 )

// Negative operators — prefix any matcher with "not"
expect( result ).notToBe( "wrong" )
expect( list ).notToBeEmpty()
expect( value ).notToBeNull()
```

---

## All Built-in Matchers

### Equality

```boxlang
expect( result ).toBe( expected )              // case-insensitive equality (simple and complex)
expect( result ).toBeWithCase( expected )      // case-sensitive equality
expect( result ).notToBe( expected )
expect( result ).notToBeWithCase( expected )
```

### Boolean / Truthiness

```boxlang
expect( value ).toBeTrue()
expect( value ).toBeFalse()
expect( value ).toBeNull()
expect( value ).notToBeNull()
```

### Emptiness & Length

```boxlang
expect( collection ).toBeEmpty()        // array, struct, string, query
expect( collection ).notToBeEmpty()
expect( collection ).toHaveLength( n )
expect( collection ).notToHaveLength( n )
```

### Type Checks

```boxlang
// Generic type (uses CF isValid() under the hood)
expect( value ).toBeTypeOf( "array" )   // array, struct, component, numeric, boolean, date, uuid…
expect( value ).notToBeTypeOf( "array" )

// Dynamic shorthand — toBeXxx() where Xxx is any isValid() type
expect( [1,2,3] ).toBeArray()
expect( {} ).toBeStruct()
expect( "03/01/1990" ).toBeUsDate()
expect( createUUID() ).toBeUuid()
expect( 42 ).toBeNumeric()
expect( "hello" ).toBeString()
expect( true ).toBeBoolean()

// Instance check
expect( myObj ).toBeInstanceOf( "models.UserService" )
expect( myObj ).notToBeInstanceOf( "models.OtherService" )
```

### Struct Key Existence

```boxlang
expect( myStruct ).toHaveKey( "email" )
expect( myStruct ).notToHaveKey( "password" )

// Deep key search (nested structs)
expect( myStruct ).toHaveDeepKey( "address" )
expect( myStruct ).notToHaveDeepKey( "ssn" )
```

### String / Array Inclusion

```boxlang
// Case-insensitive
expect( "Hello World" ).toInclude( "hello" )
expect( [1,2,3] ).toInclude( 2 )
expect( "Hello World" ).notToInclude( "foo" )

// Case-sensitive
expect( "Hello World" ).toIncludeWithCase( "Hello" )
expect( "Hello World" ).notToIncludeWithCase( "hello" )   // fails — "hello" != "Hello"
```

### Regular Expressions

```boxlang
expect( "foo@bar.com" ).toMatch( "^[^@]+@[^@]+" )        // case-insensitive
expect( "Hello" ).toMatchWithCase( "^Hello" )             // case-sensitive
expect( "123" ).notToMatch( "[a-z]" )
expect( "ABC" ).notToMatchWithCase( "[a-z]" )
```

### Numeric Comparisons

```boxlang
expect( 5 ).toBeGT( 4 )
expect( 5 ).toBeGTE( 5 )
expect( 5 ).toBeLT( 6 )
expect( 5 ).toBeLTE( 5 )
expect( 5 ).toBeBetween( 1, 10 )
expect( 5 ).notToBeBetween( 20, 30 )

// Approximate equality (numbers or dates)
expect( 3.14159 ).toBeCloseTo( expected: 3.14, delta: 0.01 )
expect( now() ).toBeCloseTo( expected: dateAdd( "s", 1, now() ), delta: 2, datepart: "s" )
```

### Exceptions

```boxlang
// Any exception
expect( () => {
    service.riskyOperation()
} ).toThrow()

// Specific type
expect( () => {
    service.delete( 999 )
} ).toThrow( type: "NotFoundException" )

// Type + message regex
expect( () => {
    service.delete( 999 )
} ).toThrow( type: "NotFoundException", regex: "999" )

// Assert NO exception
expect( () => {
    service.safeOperation()
} ).notToThrow()
```

---

## Chaining Multiple Matchers

All matchers return the expectation object, so you can chain:

```boxlang
expect( response )
    .toBeStruct()
    .toHaveKey( "status" )
    .toHaveKey( "data" )

expect( users )
    .toBeArray()
    .notToBeEmpty()
    .toHaveLength( 5 )

expect( email )
    .toBeString()
    .notToBeEmpty()
    .toMatch( ".+@.+\..+" )
```

---

## `expectAll()` — Collection Assertions

Assert that a matcher applies to **every element** in an array or every value in a struct:

```boxlang
// All values are even numbers
expectAll( [2, 4, 6] ).toSatisfy( ( x ) => x % 2 == 0 )

// All struct values are non-empty
expectAll( { a: "foo", b: "bar" } ).notToBeEmpty()

// All users are active
expectAll( userService.listAll() ).toSatisfy( ( user ) => user.isActive == true )
```

---

## Custom Matchers

Register custom matchers in `beforeAll()` or `beforeEach()` for global availability:

### Inline Struct

```boxlang
function beforeAll() {
    addMatchers( {

        toBeValidEmail: function( expectation, args = {} ) {
            expectation.message = isNull( args.message )
                ? "[#expectation.actual#] is not a valid email address"
                : args.message
            var passes = isValid( "Email", expectation.actual )
            return expectation.isNot ? !passes : passes
        },

        toBePositive: function( expectation, args = {} ) {
            expectation.message = "[#expectation.actual#] is not a positive number"
            return expectation.isNot
                ? expectation.actual <= 0
                : expectation.actual > 0
        },

        toHaveStatus: function( expectation, args = {} ) {
            var expected = args[ 1 ] ?: args.status ?: 200
            expectation.message = "Expected HTTP status [#expected#] but got [#expectation.actual.getStatusCode()#]"
            var passes = expectation.actual.getStatusCode() == expected
            return expectation.isNot ? !passes : passes
        }

    } )
}
```

Usage:

```boxlang
expect( "alice@example.com" ).toBeValidEmail()
expect( -5 ).notToBePositive()
expect( event.getResponse() ).toHaveStatus( 200 )
```

### Class-Based Matchers (Reusable Library)

```boxlang
// tests/helpers/AppMatchers.cfc
component {

    boolean function toBeActiveUser( required expectation, args = {} ) {
        expectation.message = "Expected user to be active"
        var passes = expectation.actual.keyExists( "isActive" ) && expectation.actual.isActive
        return expectation.isNot ? !passes : passes
    }

    boolean function toHavePermission( required expectation, args = {} ) {
        var permission = args[ 1 ] ?: ""
        expectation.message = "Expected user to have permission [#permission#]"
        var passes = expectation.actual.permissions.findNoCase( permission ) > 0
        return expectation.isNot ? !passes : passes
    }

}
```

```boxlang
function beforeAll() {
    addMatchers( "tests.helpers.AppMatchers" )
    // or: addMatchers( new tests.helpers.AppMatchers() )
}

// Usage
expect( adminUser ).toBeActiveUser()
expect( adminUser ).toHavePermission( "MANAGE_USERS" )
expect( guestUser ).notToHavePermission( "MANAGE_USERS" )
```

---

## Custom Matcher Signature Rules

Every custom matcher function must follow this contract:

| Rule | Detail |
|---|---|
| Signature | `boolean function myMatcher( required expectation, args = {} )` |
| Return | `true` = passes, `false` = fails |
| `expectation.actual` | The value passed into `expect()` |
| `expectation.isNot` | `true` when called as `notToMyMatcher()` |
| `expectation.message` | Set this to provide a custom failure message |
| `args` | All arguments passed to the matcher call |

```boxlang
// Template for a custom matcher
boolean function toMeetCriteria( required expectation, args = {} ) {
    expectation.message = args.message ?: "Custom failure message"
    var passes = /* your evaluation */ true
    return expectation.isNot ? !passes : passes
}
```

---

## Matcher Quick Reference

| Matcher | Description |
|---|---|
| `toBe( val )` | Equality (case-insensitive for strings) |
| `toBeWithCase( val )` | Equality (case-sensitive) |
| `toBeTrue()` / `toBeFalse()` | Boolean assertion |
| `toBeNull()` | Null check |
| `toBeEmpty()` | Empty check (array/struct/string/query) |
| `toHaveLength( n )` | Size assertion |
| `toBeTypeOf( type )` | Type via `isValid()` |
| `toBe{Type}()` | e.g. `toBeArray()`, `toBeStruct()` |
| `toBeInstanceOf( class )` | Class/interface check |
| `toHaveKey( key )` | Struct key existence |
| `toHaveDeepKey( key )` | Deep nested struct key |
| `toInclude( needle )` | String/array inclusion |
| `toIncludeWithCase( needle )` | Case-sensitive inclusion |
| `toMatch( regex )` | Regex match (no case) |
| `toMatchWithCase( regex )` | Regex match (case-sensitive) |
| `toBeGT( n )` | Greater than |
| `toBeGTE( n )` | Greater than or equal |
| `toBeLT( n )` | Less than |
| `toBeLTE( n )` | Less than or equal |
| `toBeBetween( min, max )` | Numeric/date range |
| `toBeCloseTo( expected, delta )` | Approximate numeric/date equality |
| `toThrow( [type], [regex] )` | Exception assertion on a closure |
| All of the above prefixed with `not` | Negated version of that matcher |
