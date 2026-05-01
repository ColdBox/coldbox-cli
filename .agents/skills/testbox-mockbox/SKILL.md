---
name: testbox-mockbox
description: "Use this skill when creating mocks, stubs, and spies in TestBox using MockBox: createMock(), createEmptyMock(), prepareMock(), stubbing methods with $(), chaining $args()/$results()/$throws(), verifying call counts with $once()/$never()/$times()/$atLeast()/$atMost(), reading call logs with $callLog(), injecting mock properties with $property(), simulating queries with querySim(), or spying on real methods with $spy()."
---

# MockBox — Mocking & Stubbing in TestBox

## When to Use This Skill

- Replacing real dependencies (DAOs, APIs, email services) with controlled test doubles
- Stubbing method return values for different arguments
- Verifying how many times a method was called and with what arguments
- Making a method throw a specific exception
- Spying on internal private methods of the object under test
- Injecting mock property values directly into objects

---

## Creating Test Doubles

```boxlang
// Full mock — real class instantiated, all methods can be stubbed
variables.mockUserService = createMock( "models.UserService" )

// Full mock from an already-instantiated object
variables.mockUserService = createMock( object: new models.UserService() )

// Empty mock — all methods wiped; you must stub every method used
variables.mockDAO = createEmptyMock( "models.UserDAO" )

// Partial mock — decorate a real object; unstubbed methods execute normally
variables.spySecurity = prepareMock( new models.SecurityService() )
```

| Factory | Methods kept? | Use case |
|---|---|---|
| `createMock()` | Yes (stubbable) | Replace collaborator dependencies |
| `createEmptyMock()` | No (all wiped) | Mock an interface or abstract base |
| `prepareMock()` | Yes (targeted stubs only) | Spy on internal private methods |

---

## Stubbing Return Values — `$()`

```boxlang
// Return a fixed value every call
mockDAO.$( "findById" ).$results( { id: 1, name: "Alice" } )

// Shorthand: inline returns
mockDAO.$( "findById", { id: 1, name: "Alice" } )

// Multiple sequential results (cycles on last after exhausting)
mockDAO.$( "getNextRecord" ).$results( { id: 1 }, { id: 2 }, { id: 3 } )
// call1 → {id:1},  call2 → {id:2},  call3+ → {id:3}

// Chain multiple stubs on one mock
mockService.$( "isFound", false ).$( "isDirty", false ).$( "isSaved", true )

// Dynamic result via callback (receives caller arguments as array)
mockCalc.$( "calculate", ( args ) => args[ 1 ] * 2 )

// Void method (returns nothing, just track calls)
mockEmailService.$( "send" )
```

---

## Argument-Specific Stubs — `$args()`

When the same method is called with **different arguments** and must return different values:

```boxlang
// Positional
mockConfig.$( "getKey" )
    .$args( "debugMode" ).$results( true )
    .$args( "outgoingMail" ).$results( "dev@example.com" )

// Named
mockConfig.$( "getKey" )
    .$args( name: "debugMode" ).$results( true )
    .$args( name: "outgoingMail" ).$results( "dev@example.com" )

// Usage
expect( mockConfig.getKey( "debugMode" ) ).toBeTrue()
expect( mockConfig.getKey( "outgoingMail" ) ).toBe( "dev@example.com" )
```

> Always follow `$args()` with `$results()`.

---

## Throwing Exceptions — `$throws()`

```boxlang
// Chain approach
mockDAO.$( "delete" )
    .$args( id: 999 )
    .$throws( type: "NotFoundException", message: "Record 999 not found" )

// Inline approach
mockDAO.$(
    method:         "delete",
    throwException: true,
    throwType:      "NotFoundException",
    throwMessage:   "Record not found",
    throwDetail:    "id=999",
    throwErrorCode: "404"
)

// Confirm in spec
expect( () => service.delete( 999 ) ).toThrow( type: "NotFoundException" )
```

---

## Injecting Properties — `$property()`

Inject a mock directly into any scope of the SUT without needing a setter:

```boxlang
prepareMock( variables.sut )
    .$property(
        propertyName:  "userRepository",
        propertyScope: "variables",   // default
        mock:          mockUserRepository
    )

// Read it back
var injected = variables.sut.$getProperty( "userRepository" )
```

---

## Query Simulation — `querySim()`

Build query objects inline using pipe-delimited syntax:

```boxlang
var userQuery = querySim(
    "id, name, email
    1 | Alice Majano   | alice@example.com
    2 | Bob Clapton    | bob@example.com
    3 | Carol Degeneres| carol@example.com"
)

mockDAO.$( "findAll" ).$results( userQuery )

var result = userService.listAll()
expect( result.recordCount ).toBe( 3 )
expect( result.name[ 1 ] ).toBe( "Alice Majano" )
```

---

## Spying on Real Methods — `$spy()`

The real implementation still executes; MockBox logs calls so you can verify them:

```boxlang
prepareMock( variables.sut )
variables.sut.$spy( "sendWelcomeEmail" )

userService.register( { name: "Alice", email: "alice@example.com" } )

expect( variables.sut.$once( "sendWelcomeEmail" ) ).toBeTrue()
```

---

## Verification Methods

```boxlang
// Exactly once
expect( mockEmailService.$once( "send" ) ).toBeTrue()

// Never called
expect( mockAuditService.$never( "logError" ) ).toBeTrue()

// Exactly N times
expect( mockDAO.$times( 3, "findById" ) ).toBeTrue()
expect( mockDAO.$verifyCallCount( 3, "findById" ) ).toBeTrue()   // alias

// At least N (>= N)
expect( mockDAO.$atLeast( 2, "findById" ) ).toBeTrue()

// At most N (<= N)
expect( mockDAO.$atMost( 5, "save" ) ).toBeTrue()

// Raw count
var total     = mockDAO.$count()            // all methods
var saveCount = mockDAO.$count( "save" )    // specific method
```

---

## Inspecting Call Logs — `$callLog()`

`$callLog()` returns a struct keyed by method name; each value is an array of argument structs.

```boxlang
mockSession.$( "setVar", callLogging: true )
mockSession.setVar( "Hello", "World" )
mockSession.setVar( "Name",  "Alice" )

var logs = mockSession.$callLog()
// logs.setVar is an array of 2 ordered argument structs
expect( logs.setVar ).toHaveLength( 2 )
expect( logs.setVar[ 1 ][ "1" ] ).toBe( "Hello" )   // positional key "1"
expect( logs.setVar[ 2 ][ "1" ] ).toBe( "Name" )
```

---

## Resetting Between Specs

```boxlang
afterEach( () => {
    mockDAO.$reset()             // clears $count, $callLog, all stubs remain
    mockEmailService.$reset()
} )
```

---

## Complete Integration Example

```boxlang
class extends="testbox.system.BaseSpec" {

    function beforeAll() {
        variables.mockUserDAO     = createEmptyMock( "models.UserDAO" )
        variables.mockEmailService = createEmptyMock( "models.EmailService" )

        variables.sut = prepareMock( new models.UserService() )
            .$property( propertyName: "userDAO",      mock: mockUserDAO )
            .$property( propertyName: "emailService", mock: mockEmailService )
    }

    function run() {

        describe( "UserService.register()", () => {

            beforeEach( () => {
                mockUserDAO.$reset()
                mockEmailService.$reset()
            } )

            it( "saves user and sends welcome email", () => {
                mockUserDAO.$( "save" ).$results( { id: 1, name: "Alice" } )
                mockEmailService.$( "sendWelcome" )

                var result = sut.register( { name: "Alice", email: "alice@example.com" } )

                expect( result.id ).toBe( 1 )
                expect( mockUserDAO.$once( "save" ) ).toBeTrue()
                expect( mockEmailService.$once( "sendWelcome" ) ).toBeTrue()
            } )

            it( "does not send email when save fails", () => {
                mockUserDAO.$( "save" )
                    .$throws( type: "DatabaseException", message: "Duplicate entry" )

                expect( () => sut.register( { name: "Dup", email: "dup@example.com" } ) )
                    .toThrow( type: "DatabaseException" )

                expect( mockEmailService.$never( "sendWelcome" ) ).toBeTrue()
            } )

            it( "calls save with the correct data arguments", () => {
                mockUserDAO.$( "save", callLogging: true ).$results( { id: 2 } )
                mockEmailService.$( "sendWelcome" )

                sut.register( { name: "Bob", email: "bob@example.com" } )

                var log = mockUserDAO.$callLog()
                expect( log.save[ 1 ] ).toHaveKey( "name" )
                expect( log.save[ 1 ].name ).toBe( "Bob" )
            } )

        } )

    }

}
```

---

## Quick Reference

| Method | Returns | Description |
|---|---|---|
| `createMock( className\|object )` | mock | Full mock, methods intact |
| `createEmptyMock( className\|object )` | mock | All methods wiped |
| `prepareMock( object )` | mock | Decorate existing instance |
| `mock.$( method, [returns] )` | mock | Stub a method |
| `mock.$args( ...args )` | mock | Match specific call arguments |
| `mock.$results( ...values )` | mock | Set sequential return values |
| `mock.$throws( type, message, detail )` | mock | Make method throw |
| `mock.$property( name, scope, mock )` | mock | Inject into any scope |
| `mock.$getProperty( name, [scope] )` | any | Read internal property |
| `mock.$spy( method )` | mock | Spy on real method (real runs + log) |
| `querySim( dsv )` | query | Build query from pipe-delimited string |
| `mock.$once( [method] )` | boolean | Called exactly once |
| `mock.$never( [method] )` | boolean | Never called |
| `mock.$times( n, [method] )` | boolean | Called exactly N times |
| `mock.$atLeast( n, [method] )` | boolean | Called >= N times |
| `mock.$atMost( n, [method] )` | boolean | Called <= N times |
| `mock.$count( [method] )` | numeric | Call count |
| `mock.$callLog()` | struct | All call argument logs |
| `mock.$reset()` | void | Reset counters and logs |
| `mock.$debug()` | struct | Debugging info |
