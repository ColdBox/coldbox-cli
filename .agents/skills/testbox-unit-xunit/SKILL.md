---
name: testbox-unit-xunit
description: "Use this skill when writing xUnit-style tests in TestBox using test functions (testXxx()), setup/teardown lifecycle (beforeTests/afterTests/setup/teardown), $assert assertion object, or the Arrange-Act-Assert (AAA) pattern for unit testing services, models, and utilities in isolation."
---

# xUnit / Unit Testing with TestBox

## When to Use This Skill

- Writing xUnit-style test bundles (functions prefixed with `test`)
- Using `$assert` assertion methods (isTrue, isEqual, includes, throws, etc.)
- Writing `beforeTests()` / `afterTests()` / `setup()` / `teardown()` lifecycle methods
- Unit-testing CFC models, services, or utilities in isolation with mocked dependencies
- Applying the Arrange-Act-Assert (AAA) pattern

---

## Language Reference

| Concept | BoxLang (`.bx`) preferred | CFML (`.cfc`) compatible |
|---|---|---|
| Class declaration | `class extends="testbox.system.BaseSpec" {}` | `component extends="testbox.system.BaseSpec" {}` |
| Test functions | `function testXxx() {}` | `function testXxx() output="false" {}` |
| Scoped var | `var x = ...` | `var x = ...` |

---

## Canonical xUnit Bundle Structure

```boxlang
class labels="unit" extends="testbox.system.BaseSpec" {

    /****** LIFECYCLE ******/

    // Runs ONCE before all test functions in this bundle
    function beforeTests() {
        variables.service = new models.CalculatorService()
    }

    // Runs ONCE after all test functions
    function afterTests() {
        structClear( variables )
    }

    // Runs before EACH test function
    function setup() {
        variables.mockLogger = createMock( "models.Logger" )
        variables.service.setLogger( mockLogger )
    }

    // Runs after EACH test function
    function teardown() {
        mockLogger.$reset()
    }

    /****** TEST METHODS ******/

    function testAddsTwoNumbers() {
        // Arrange
        var a = 5
        var b = 3

        // Act
        var result = service.add( a, b )

        // Assert
        $assert.isEqual( 8, result )
    }

    function testDivideThrowsOnZero() {
        $assert.throws(
            () => service.divide( 10, 0 ),
            "MathException"
        )
    }

    function testSkipped() skip {
        $assert.fail( "Should never run" )
    }

}
```

---

## Lifecycle Method Reference

| Method | When It Runs | Use Case |
|---|---|---|
| `beforeTests()` | Once before all test functions | Initialize shared objects, DB connections, JWT settings |
| `afterTests()` | Once after all test functions | Close connections, delete temp files |
| `setup()` | Before **each** test function | Create fresh mocks, reset state, clear caches |
| `teardown()` | After **each** test function | Roll back transactions, delete records, reset stubs |

```boxlang
function beforeTests() {
    // One-time: load heavy collaborators
    variables.orm = getInstance( "ORMService@cborm" )
    structClear( request )
}

function setup() {
    // Per-test: always get a clean state
    variables.mockDAO = createEmptyMock( "models.UserDAO" )
    variables.sut = new models.UserService( mockDAO )
}
```

---

## `$assert` Assertion Reference

Every test bundle receives `$assert` — an instance of `testbox.system.Assertion`.

```boxlang
// Boolean
$assert.isTrue( myBool )
$assert.isFalse( myBool )

// Equality
$assert.isEqual( expected, actual )
$assert.isEqualWithCase( expected, actual )
$assert.isNotEqual( expected, actual )

// Null
$assert.null( actual )
$assert.notNull( actual )

// Emptiness
$assert.isEmpty( target )     // arrays, structs, strings, queries
$assert.isNotEmpty( target )

// Size
$assert.lengthOf( target, length )
$assert.notLengthOf( target, length )

// Key existence
$assert.key( target, key )
$assert.notKey( target, key )
$assert.deepKey( target, key )
$assert.notDeepKey( target, key )

// Inclusion
$assert.includes( target, needle )              // case-insensitive
$assert.includesWithCase( target, needle )
$assert.notIncludes( target, needle )
$assert.notIncludesWithCase( target, needle )

// Type
$assert.typeOf( type, actual )
$assert.notTypeOf( type, actual )
$assert.instanceOf( actual, typeName )
$assert.notInstanceOf( actual, typeName )

// Numeric comparison
$assert.isGT( actual, target )
$assert.isGTE( actual, target )
$assert.isLT( actual, target )
$assert.isLTE( actual, target )
$assert.between( actual, min, max )
$assert.closeTo( expected, actual, delta )

// String / regex
$assert.match( actual, regex )
$assert.matchWithCase( actual, regex )
$assert.notMatch( actual, regex )

// Exceptions
$assert.throws( target, [type], [regex] )
$assert.notThrows( target, [type], [regex] )

// Force failure
$assert.fail( [message] )

// Skip current test
$assert.skip( message, detail )
```

### BoxLang Dynamic Assertion Methods

In BoxLang you can also invoke any assertion as a free function prefixed with `assert`:

```boxlang
assertIsTrue( myBool )
assertIsEqual( expected, actual )
assertBetween( actual, 1, 100 )
assertThrows( () => badCall(), "MyException" )
```

---

## Arrange-Act-Assert (AAA) Pattern

```boxlang
function testUserCreation() {
    // ARRANGE
    var mockUserDAO = createEmptyMock( "models.UserDAO" )
    mockUserDAO.$( "save" ).$results( { id: 42, name: "Alice" } )
    var sut = new models.UserService( mockUserDAO )
    var data = { name: "Alice", email: "alice@example.com" }

    // ACT
    var result = sut.createUser( data )

    // ASSERT
    $assert.isEqual( 42, result.id )
    $assert.isEqual( "Alice", result.name )
    $assert.isTrue( mockUserDAO.$once( "save" ) )
}
```

---

## Mixing xUnit with Expectations (expect DSL)

You can freely mix `$assert` and `expect()` fluent matchers in the same bundle:

```boxlang
function testUserEmail() {
    var user = sut.findById( 1 )

    // xUnit style
    $assert.isNotEmpty( user )
    $assert.key( user, "email" )

    // BDD fluent style (also available in xUnit bundles)
    expect( user.email ).toMatch( ".+@.+" )
    expect( user.isActive ).toBeTrue()
}
```

---

## Skipping Tests

```boxlang
// Skip via function attribute
function testSomething() skip {
    $assert.fail( "won't run" )
}

// Skip via argument
function testEngineSpecific() skip="#!server.keyExists( 'lucee' )#" {
    $assert.isTrue( luceeOnlyFeature() )
}

// Skip programmatically inline
function testConditional() {
    if ( !featureEnabled ) {
        $assert.skip( "Feature flag is off" )
    }
    $assert.isTrue( myFeature.isActive() )
}
```

---

## Custom Assertions

Register in `beforeTests()` to keep the shared `$assert` object clean:

```boxlang
function beforeTests() {
    addAssertions( {
        isValidEmail: function( actual ) {
            return ( reFindNoCase( "^[^@]+@[^@]+\.[^@]+$", actual ) > 0
                ? true
                : fail( "[#actual#] is not a valid email address" ) )
        },
        isUUID: function( actual ) {
            return ( isValid( "uuid", actual )
                ? true
                : fail( "[#actual#] is not a UUID" ) )
        }
    } )
}

function testEmailValidator() {
    $assert.isValidEmail( "alice@example.com" )
    $assert.isValidEmail( "not-an-email" )  // will fail
}
```

For reusable assertion libraries, register a class path or instance:

```boxlang
function beforeTests() {
    addAssertions( "tests.helpers.CustomAssertions" )
    // or
    addAssertions( new tests.helpers.CustomAssertions() )
}
```

---

## Key Differences: xUnit vs BDD

| Aspect | xUnit | BDD |
|---|---|---|
| Test declaration | `function testXxx()` | `it( "...", () => {} )` |
| Suite declaration | Class-level | `describe( "...", () => {} )` |
| Lifecycle | `beforeTests/setup/teardown/afterTests` | `beforeAll/beforeEach/afterEach/afterAll/aroundEach` |
| Assertions | `$assert.isXxx()` | `expect().toBeXxx()` |
| Skip | `skip` function attribute | `xit()`, `skip()` inline |
| Nesting | Not supported | Unlimited nested `describe` blocks |
| Data binding | Not supported | `it( data={} )` |

---

## CommandBox Scaffolding

```bash
# Create xUnit spec
coldbox create unit name=UserServiceTest open=true

# Scaffold with specific model binding
coldbox create unit name=UserServiceTest methods=testCreate,testUpdate,testDelete
```
