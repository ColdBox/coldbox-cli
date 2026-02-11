---
name: Testing with Mocking
description: Complete guide to mocking dependencies in tests using MockBox, including creating mocks, stubs, spies, and verification patterns
category: testing
priority: high
triggers:
  - mock
  - mocking
  - mockbox
  - stub
  - spy
  - test double
  - dependency isolation
---

# Testing with Mocking

## Overview

Mocking is a technique for isolating code under test by replacing dependencies with controlled test doubles. MockBox is the mocking/stubbing framework included with TestBox that provides powerful capabilities for creating mocks, stubs, and spies. This enables true unit testing by eliminating external dependencies.

## Core Concepts

### Test Doubles Types

- **Mock**: Fully controlled test double with verification
- **Stub**: Returns predetermined values
- **Spy**: Real object with call tracking
- **Partial Mock**: Real object with some methods mocked
- **Fake**: Simplified working implementation

### When to Mock

✅ **Good candidates for mocking**:
- External services (APIs, email, payment gateways)
- Database access
- File system operations
- Time-dependent operations
- Complex dependencies
- Slow operations

❌ **Don't mock**:
- Simple value objects
- Data structures
- The class under test
- Framework classes (usually)

## MockBox Basics

### Creating Mocks

```boxlang
describe( "UserService", () => {

    beforeEach( () => {
        // Create MockBox instance
        mockBox = createMock( "coldbox.system.testing.MockBox" )

        // Create mock dependencies
        mockUserDAO = mockBox.createMock( "models.UserDAO" )
        mockMailService = mockBox.createMock( "models.MailService" )

        // Inject mocks into service under test
        userService = createObject( "models.UserService" )
        userService.setUserDAO( mockUserDAO )
        userService.setMailService( mockMailService )
    } )

    it( "should create user and send welcome email", () => {
        userData = {
            name: "John Doe",
            email: "john@example.com"
        }

        // Setup mock return value
        mockUser = { id: 1, name: "John Doe", email: "john@example.com" }
        mockUserDAO.$( "create", mockUser )
        mockMailService.$( "sendWelcomeEmail", true )

        // Execute
        result = userService.createUser( userData )

        // Verify
        expect( result ).toBe( mockUser )
        expect( mockUserDAO.$once( "create" ) ).toBeTrue()
        expect( mockMailService.$once( "sendWelcomeEmail" ) ).toBeTrue()
    } )
} )
```

### Stubbing Method Returns

```boxlang
describe( "Stubbing methods", () => {

    it( "should stub simple return value", () => {
        mockUserDAO = mockBox.createMock( "models.UserDAO" )

        // Stub method to return specific value
        mockUserDAO.$( "find", { id: 1, name: "John" } )

        result = mockUserDAO.find( 1 )
        expect( result.name ).toBe( "John" )
    } )

    it( "should stub multiple return values in sequence", () => {
        mockUserDAO = mockBox.createMock( "models.UserDAO" )

        // Return different values on successive calls
        mockUserDAO.$( "getNextUser" ).$results(
            { id: 1, name: "John" },
            { id: 2, name: "Jane" },
            null  // No more users
        )

        expect( mockUserDAO.getNextUser().id ).toBe( 1 )
        expect( mockUserDAO.getNextUser().id ).toBe( 2 )
        expect( mockUserDAO.getNextUser() ).toBeNull()
    } )

    it( "should stub with callback", () => {
        mockUserDAO = mockBox.createMock( "models.UserDAO" )

        // Use callback for dynamic return values
        mockUserDAO.$( "find" ).$callback( ( id ) => {
            return {
                id: id,
                name: "User ##id##"
            }
        } )

        result = mockUserDAO.find( 5 )
        expect( result.name ).toBe( "User 5" )
    } )
} )
```

## Advanced Mocking Techniques

### Argument Matching

```boxlang
describe( "Argument matching", () => {

    it( "should match specific arguments", () => {
        mockMailService = mockBox.createMock( "models.MailService" )

        // Stub only when specific arguments are passed
        mockMailService.$( "send", true ).$args(
            to = "john@example.com",
            subject = "Welcome"
        )

        // Returns true for matching arguments
        result = mockMailService.send(
            to = "john@example.com",
            subject = "Welcome",
            body = "Hello"
        )
        expect( result ).toBeTrue()

        // Returns null for non-matching arguments
        result = mockMailService.send( to = "other@example.com" )
        expect( result ).toBeNull()
    } )

    it( "should use argument matchers", () => {
        mockUserDAO = mockBox.createMock( "models.UserDAO" )

        // Match any numeric ID
        mockUserDAO.$( "find", { id: 1, name: "User" } ).$args(
            mockBox.match.numeric()
        )

        expect( mockUserDAO.find( 1 ).name ).toBe( "User" )
        expect( mockUserDAO.find( 999 ).name ).toBe( "User" )
    } )

    it( "should use custom matcher", () => {
        mockUserDAO = mockBox.createMock( "models.UserDAO" )

        // Custom matcher function
        mockUserDAO.$( "findByEmail", { id: 1 } ).$args(
            mockBox.match.custom( ( email ) => {
                return email.endsWith( "@example.com" )
            } )
        )

        expect( mockUserDAO.findByEmail( "john@example.com" ).id ).toBe( 1 )
        expect( mockUserDAO.findByEmail( "jane@example.com" ).id ).toBe( 1 )
        expect( mockUserDAO.findByEmail( "invalid@other.com" ) ).toBeNull()
    } )
} )
```

### Throwing Exceptions

```boxlang
describe( "Exception stubbing", () => {

    it( "should throw exception", () => {
        mockUserDAO = mockBox.createMock( "models.UserDAO" )

        // Stub method to throw exception
        mockUserDAO.$( "find" ).$throws(
            type = "RecordNotFound",
            message = "User not found"
        )

        expect( () => {
            mockUserDAO.find( 999 )
        } ).toThrow( type = "RecordNotFound" )
    } )

    it( "should handle service errors gracefully", () => {
        mockPaymentService = mockBox.createMock( "models.PaymentService" )

        mockPaymentService.$( "processPayment" ).$throws(
            type = "PaymentError",
            message = "Insufficient funds"
        )

        orderService = createObject( "models.OrderService" )
        orderService.setPaymentService( mockPaymentService )

        result = orderService.createOrder( { total: 100 } )

        // Service should handle error gracefully
        expect( result.success ).toBeFalse()
        expect( result.error ).toInclude( "payment" )
    } )
} )
```

## Verifying Interactions

### Call Verification

```boxlang
describe( "Call verification", () => {

    it( "should verify method was called", () => {
        mockMailService = mockBox.createMock( "models.MailService" )
        mockMailService.$( "send", true )

        mailService.send( to = "john@example.com" )

        // Verify called at least once
        expect( mockMailService.$once( "send" ) ).toBeTrue()
    } )

    it( "should verify call count", () => {
        mockLogger = mockBox.createMock( "models.Logger" )
        mockLogger.$( "log" )

        mockLogger.log( "Message 1" )
        mockLogger.log( "Message 2" )
        mockLogger.log( "Message 3" )

        // Verify exact call count
        expect( mockLogger.$times( 3, "log" ) ).toBeTrue()
    } )

    it( "should verify method never called", () => {
        mockMailService = mockBox.createMock( "models.MailService" )
        mockMailService.$( "sendErrorNotification" )

        // Execute code that shouldn't trigger error notification
        userService.createUser( validData )

        // Verify error notification was never sent
        expect( mockMailService.$never( "sendErrorNotification" ) ).toBeTrue()
    } )

    it( "should verify arguments", () => {
        mockUserDAO = mockBox.createMock( "models.UserDAO" )
        mockUserDAO.$( "update" )

        mockUserDAO.update(
            id = 1,
            data = { name: "John Doe" }
        )

        // Verify called with specific arguments
        expect(
            mockUserDAO.$verify( "update", {
                id: 1,
                data: { name: "John Doe" }
            } )
        ).toBeTrue()
    } )
} )
```

### Call Order Verification

```boxlang
describe( "Call order verification", () => {

    it( "should verify method call order", () => {
        mockLogger = mockBox.createMock( "models.Logger" )
        mockLogger.$( "debug" ).$( "info" ).$( "warn" )

        mockLogger.debug( "Starting process" )
        mockLogger.info( "Process running" )
        mockLogger.warn( "Process completed with warnings" )

        // Verify call order
        callLog = mockLogger.$callLog()
        expect( callLog[1].method ).toBe( "debug" )
        expect( callLog[2].method ).toBe( "info" )
        expect( callLog[3].method ).toBe( "warn" )
    } )
} )
```

## Spies

### Creating Spies

```boxlang
describe( "Spies", () => {

    it( "should spy on real object", () => {
        // Create real object
        realUserDAO = createObject( "models.UserDAO" )

        // Convert to spy
        spyUserDAO = mockBox.createSpy( realUserDAO )

        // Call real method (actual database operation)
        users = spyUserDAO.listAll()

        // Verify call was tracked
        expect( spyUserDAO.$once( "listAll" ) ).toBeTrue()

        // Result is from real method
        expect( users ).toBeArray()
    } )

    it( "should spy and override specific method", () => {
        realMailService = createObject( "models.MailService" )
        spyMailService = mockBox.createSpy( realMailService )

        // Override only send() to prevent actual emails
        spyMailService.$( "send", true )

        // Other methods use real implementation
        templates = spyMailService.getTemplates()  // Real method
        sent = spyMailService.send( "test@example.com" )  // Stubbed

        expect( templates ).toBeArray()
        expect( sent ).toBeTrue()
        expect( spyMailService.$once( "send" ) ).toBeTrue()
    } )
} )
```

## Partial Mocks

### Mocking Specific Methods

```boxlang
describe( "Partial mocks", () => {

    it( "should create partial mock", () => {
        userService = createObject( "models.UserService" )

        // Convert to mock
        mockUserService = mockBox.createMock( userService )

        // Stub only specific method
        mockUserService.$( "isUniqueEmail", true )

        // Other methods use real implementation
        userData = { name: "John", email: "john@example.com" }

        // isUniqueEmail() returns stubbed value
        isUnique = mockUserService.isUniqueEmail( "test@example.com" )
        expect( isUnique ).toBeTrue()

        // Other methods work normally (if dependencies are mocked)
    } )

    it( "should call through to real method", () => {
        userService = createObject( "models.UserService" )
        mockUserService = mockBox.createMock( userService )

        // Stub one method
        mockUserService.$( "generateToken", "abc123" )

        // Another method can call through to real implementation
        mockUserService.$( "createToken" ).$callThrough()

        token = mockUserService.createToken( userId = 1 )

        // Real method was called
        expect( mockUserService.$once( "createToken" ) ).toBeTrue()
    } )
} )
```

## Mocking Static Methods

### Class-Level Mocking

```boxlang
describe( "Static method mocking", () => {

    it( "should mock static method", () => {
        // Create mock of utility class
        mockDateUtil = mockBox.createMock( "models.DateUtil" )

        // Stub static method
        mockDateUtil.$( "now", "2024-01-01 12:00:00" )

        result = mockDateUtil.now()
        expect( result ).toBe( "2024-01-01 12:00:00" )
    } )
} )
```

## Mocking Built-in Functions

### Overriding CFML/BoxLang Functions

```boxlang
describe( "Built-in function mocking", () => {

    it( "should mock built-in function", () => {
        // Create mock object with built-in functions
        variables.$mockBox = mockBox

        // Stub now() function
        $mockBox.$( "now", createDateTime( 2024, 1, 1, 12, 0, 0 ) )

        // Note: This works within mock objects, not globally
    } )
} )
```

## Mocking ColdBox Components

### Mocking Request Context

```boxlang
describe( "ColdBox component mocking", () => {

    it( "should mock event object", () => {
        mockEvent = mockBox.createMock( "coldbox.system.web.context.RequestContext" )

        // Stub event methods
        mockEvent.$( "getValue" ).$args( "userId" ).$results( 123 )
        mockEvent.$( "getPrivateValue" ).$args( "user" ).$results( {
            id: 123,
            name: "John Doe"
        } )

        // Use in handler test
        handler = createObject( "handlers.Users" )
        mockEvent = handler.show( mockEvent )

        // Verify event interactions
        expect( mockEvent.$once( "getValue" ) ).toBeTrue()
    } )

    it( "should mock Flash scope", () => {
        mockFlash = mockBox.createMock( "coldbox.system.web.flash.AbstractFlashScope" )

        mockFlash.$( "get" ).$args( "notice" ).$results( "Operation successful" )
        mockFlash.$( "put" )

        // Test flash scope interaction
        message = mockFlash.get( "notice" )
        expect( message ).toBe( "Operation successful" )
    } )
} )
```

### Mocking Dependency Injection

```boxlang
describe( "DI mocking", () => {

    it( "should mock injected dependencies", () => {
        // Create handler
        handler = createObject( "handlers.Users" )

        // Create mock dependencies
        mockUserService = mockBox.createMock( "models.UserService" )
        mockUserService.$( "list", [] )

        // Inject mock (bypassing WireBox)
        handler.userService = mockUserService

        // Test handler
        mockEvent = prepareMock( getRequestContext() )
        handler.index( mockEvent )

        // Verify service was called
        expect( mockUserService.$once( "list" ) ).toBeTrue()
    } )
} )
```

## Testing Patterns

### Repository Pattern Mocking

```boxlang
describe( "Repository pattern", () => {

    it( "should mock repository", () => {
        mockUserRepository = mockBox.createMock( "models.UserRepository" )

        mockUserRepository.$( "find", {
            id: 1,
            name: "John Doe",
            email: "john@example.com"
        } )

        mockUserRepository.$( "save", true )

        userService = createObject( "models.UserService" )
        userService.setRepository( mockUserRepository )

        user = userService.getUser( 1 )
        expect( user.name ).toBe( "John Doe" )

        userService.updateUser( 1, { name: "Jane Doe" } )
        expect( mockUserRepository.$once( "save" ) ).toBeTrue()
    } )
} )
```

### Service Layer Mocking

```boxlang
describe( "Service layer", () => {

    it( "should mock multiple service dependencies", () => {
        mockUserService = mockBox.createMock( "models.UserService" )
        mockAuthService = mockBox.createMock( "models.AuthService" )
        mockMailService = mockBox.createMock( "models.MailService" )

        mockUserService.$( "create", { id: 1 } )
        mockAuthService.$( "generateToken", "abc123" )
        mockMailService.$( "sendWelcomeEmail", true )

        registrationService = createObject( "models.RegistrationService" )
        registrationService.setUserService( mockUserService )
        registrationService.setAuthService( mockAuthService )
        registrationService.setMailService( mockMailService )

        result = registrationService.register( {
            name: "John Doe",
            email: "john@example.com"
        } )

        expect( result.success ).toBeTrue()
        expect( mockUserService.$once( "create" ) ).toBeTrue()
        expect( mockAuthService.$once( "generateToken" ) ).toBeTrue()
        expect( mockMailService.$once( "sendWelcomeEmail" ) ).toBeTrue()
    } )
} )
```

## Best Practices

### Design Guidelines

1. **Mock Dependencies, Not the SUT**: Never mock the system under test
2. **Verify Behavior, Not Calls**: Focus on outcomes, not implementation
3. **Use Appropriate Test Doubles**: Choose mocks, stubs, or spies based on needs
4. **Mock Interfaces**: Mock at abstraction boundaries
5. **One Mock Per Test**: Keep tests focused and simple
6. **Clear Stub Setup**: Make stubbed behavior obvious
7. **Verify Important Calls**: Don't over-verify every interaction
8. **Clean Mock State**: Reset mocks between tests
9. **Realistic Stubs**: Stub with realistic data
10. **Document Complex Setups**: Comment why mocking is needed

### Common Patterns

```boxlang
// ✅ Good: Clear mock setup
beforeEach( () => {
    mockUserDAO = mockBox.createMock( "models.UserDAO" )
    userService = createObject( "models.UserService" )
    userService.setUserDAO( mockUserDAO )
} )

// ✅ Good: Verification focuses on behavior
it( "should notify admin on error", () => {
    mockMailService.$( "sendAdminAlert", true )

    userService.processImport( badData )

    expect( mockMailService.$once( "sendAdminAlert" ) ).toBeTrue()
} )

// ✅ Good: Realistic stub data
mockUserDAO.$( "find", {
    id: 1,
    name: "John Doe",
    email: "john@example.com",
    createdDate: now(),
    active: true
} )
```

## Common Pitfalls

### Pitfalls to Avoid

1. **Over-Mocking**: Mocking everything (test becomes meaningless)
2. **Under-Mocking**: Not isolating enough (slow, fragile tests)
3. **Tight Coupling**: Tests know too much about implementation
4. **Mock Leakage**: Mocks affecting other tests
5. **Complex Setup**: Too much mock configuration
6. **No Verification**: Creating mocks but not verifying
7. **Fragile Tests**: Tests break with refactoring
8. **Testing Mocks**: Verifying mock behavior instead of real behavior
9. **Irrelevant Verification**: Checking unimportant calls
10. **Hidden Dependencies**: Not mocking all dependencies

### Anti-Patterns

```boxlang
// ❌ Bad: Over-verification
it( "should create user", () => {
    userService.create( data )

    // Too detailed - tests implementation, not behavior
    expect( mockUserDAO.$once( "beginTransaction" ) ).toBeTrue()
    expect( mockUserDAO.$once( "insert" ) ).toBeTrue()
    expect( mockUserDAO.$once( "commitTransaction" ) ).toBeTrue()
    expect( mockValidator.$once( "validate" ) ).toBeTrue()
    expect( mockLogger.$times( 3, "debug" ) ).toBeTrue()
} )

// ✅ Good: Test behavior
it( "should create user", () => {
    result = userService.create( data )

    expect( result.id ).toBeNumeric()
    expect( mockUserDAO.$once( "insert" ) ).toBeTrue()
} )

// ❌ Bad: Mocking the system under test
it( "should calculate total", () => {
    mockOrderService = mockBox.createMock( "models.OrderService" )
    mockOrderService.$( "calculateTotal", 100 )

    total = mockOrderService.calculateTotal()  // Testing the mock!
    expect( total ).toBe( 100 )
} )
```

## Debugging Mocks

### Inspecting Mock State

```boxlang
describe( "Debugging", () => {

    it( "should inspect mock calls", () => {
        mockUserDAO = mockBox.createMock( "models.UserDAO" )
        mockUserDAO.$( "find" )

        mockUserDAO.find( 1 )
        mockUserDAO.find( 2 )

        // Get call log
        calls = mockUserDAO.$callLog()
        writeDump( var = calls, label = "Mock Call Log" )

        // Check specific call
        expect( calls ).toHaveLength( 2 )
        expect( calls[1].method ).toBe( "find" )
        expect( calls[1].args[1] ).toBe( 1 )
    } )

    it( "should debug stub configuration", () => {
        mockUserDAO = mockBox.createMock( "models.UserDAO" )
        mockUserDAO.$( "find", { id: 1 } )

        // Get stub configuration
        stubs = mockUserDAO.$getStubs()
        writeDump( var = stubs, label = "Stub Configuration" )
    } )
} )
```

## Related Skills

- [Unit Testing](testing-unit.md) - Unit test fundamentals
- [Integration Testing](testing-integration.md) - Integration test patterns
- [Testing Handlers](testing-handler.md) - Handler testing
- [Testing BDD](testing-bdd.md) - BDD patterns

## References

- [MockBox Documentation](https://testbox.ortusbooks.com/mocking)
- [Test Doubles](https://martinfowler.com/bliki/TestDouble.html)
- [Mocking Best Practices](https://testbox.ortusbooks.com/mocking/mockbox-overview)
