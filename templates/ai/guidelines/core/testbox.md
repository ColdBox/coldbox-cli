# TestBox Testing Guidelines

## Overview

TestBox is a comprehensive BDD (Behavior Driven Development) and TDD (Test Driven Development) testing framework for CFML and BoxLang. It includes MockBox for mocking/stubbing and supports multiple test styles.

## Test Styles

TestBox supports two testing approaches:

### BDD (Behavior Driven Development) - Recommended

Focus on features and behavior using human-readable specifications.

```boxlang
class extends="testbox.system.BaseSpec" {
    function run() {
        describe( "UserService", () => {
            beforeEach( () => {
                variables.userService = new models.UserService()
            } )
            
            it( "can create a new user", () => {
                var user = userService.create( {
                    email: "test@example.com",
                    firstName: "John",
                    lastName: "Doe"
                } )
                
                expect( user ).toBeStruct()
                expect( user ).toHaveKey( "id" )
                expect( user.email ).toBe( "test@example.com" )
            } )
            
            it( "throws exception for invalid email", () => {
                expect( () => {
                    userService.create( { email: "invalid" } )
                } ).toThrow( "ValidationException" )
            } )
        } )
    }
}
```

### xUnit (Test Driven Development)

Traditional unit testing with test methods.

```boxlang
class extends="testbox.system.BaseSpec" {
    function beforeAll() {
        variables.userService = new models.UserService()
    }
    
    function testUserCreation() {
        var user = userService.create( {
            email: "test@example.com"
        } )
        
        expect( user ).toBeStruct()
        expect( user.id ).toBeNumeric()
    }
    
    @test
    function canUpdateUser() {
        var user = userService.create( { email: "test@test.com" } )
        var updated = userService.update( user.id, { firstName: "Updated" } )
        
        expect( updated.firstName ).toBe( "Updated" )
    }
}
```

## BDD Structure

### Suites and Specs

```boxlang
describe( "User Registration Feature", () => {
    // Setup code
    beforeEach( () => {
        variables.userService = new models.UserService()
        variables.testData = {
            email: "test@example.com",
            password: "SecurePass123!"
        }
    } )
    
    // Teardown code
    afterEach( () => {
        // Cleanup if needed
    } )
    
    it( "creates user with valid data", () => {
        var user = userService.register( testData )
        expect( user ).toHaveKey( "id" )
    } )
    
    it( "sends welcome email after registration", () => {
        var user = userService.register( testData )
        // Verify email sent
    } )
    
    // Nested describe blocks
    describe( "Password Validation", () => {
        it( "requires minimum 8 characters", () => {
            testData.password = "short"
            expect( () => {
                userService.register( testData )
            } ).toThrow( "ValidationException" )
        } )
        
        it( "requires at least one number", () => {
            testData.password = "NoNumbers!"
            expect( () => {
                userService.register( testData )
            } ).toThrow()
        } )
    } )
} )
```

### Given-When-Then (BDD Story Format)

```boxlang
story( "As a user, I want to reset my password", () => {
    given( "I have a valid account", () => {
        variables.user = userService.create( {
            email: "user@example.com",
            password: "OldPass123!"
        } )
    } )
    
    when( "I request a password reset", () => {
        variables.resetToken = userService.requestPasswordReset( user.email )
    } )
    
    then( "I should receive a reset token", () => {
        expect( resetToken ).notToBeEmpty()
    } )
    
    then( "I can reset my password with the token", () => {
        var success = userService.resetPassword( 
            resetToken, 
            "NewPass123!" 
        )
        expect( success ).toBeTrue()
    } )
} )
```

## Lifecycle Methods

### BDD Lifecycle

```boxlang
describe( "Test Suite", () => {
    // Runs once before all tests in this suite
    beforeAll( () => {
        variables.database = setupTestDatabase()
    } )
    
    // Runs once after all tests in this suite
    afterAll( () => {
        teardownTestDatabase()
    } )
    
    // Runs before each test
    beforeEach( ( currentSpec ) => {
        variables.user = createTestUser()
    } )
    
    // Runs after each test
    afterEach( ( currentSpec ) => {
        deleteTestUser( variables.user )
    } )
    
    // Wraps each test completely
    aroundEach( ( spec, suite ) => {
        transaction {
            try {
                arguments.spec.body()
            } finally {
                transaction action="rollback"
            }
        }
    } )
} )
```

### xUnit Lifecycle

```boxlang
// Runs once before any tests
function beforeAll() {
    variables.database = setupDatabase()
}

// Runs once after all tests
function afterAll() {
    teardownDatabase()
}

// Runs before each test
function setUp() {
    variables.user = createTestUser()
}

// Runs after each test
function tearDown() {
    deleteTestUser()
}
```

## Assertions & Expectations

### Expectation Syntax (Recommended)

```boxlang
// Equality
expect( actual ).toBe( expected )
expect( actual ).notToBe( expected )
expect( "Hello" ).toBeWithCase( "Hello" )  // Case sensitive

// Type checks
expect( value ).toBeTrue()
expect( value ).toBeFalse()
expect( value ).toBeNull()
expect( value ).toBeNumeric()
expect( value ).toBeString()
expect( value ).toBeArray()
expect( value ).toBeStruct()
expect( value ).toBeQuery()
expect( value ).toBeComponent()

// Struct/Object checks
expect( user ).toHaveKey( "id" )
expect( user ).toHaveKey( "email", "password" )
expect( user ).notToHaveKey( "deleted" )
expect( user ).toHaveLength( 3 )

// Array checks
expect( items ).toBeEmpty()
expect( items ).notToBeEmpty()
expect( items ).toHaveLength( 5 )
expect( items ).toInclude( "value" )

// Numeric comparisons
expect( value ).toBeGT( 5 )      // Greater than
expect( value ).toBeGTE( 5 )     // Greater than or equal
expect( value ).toBeLT( 10 )     // Less than
expect( value ).toBeLTE( 10 )    // Less than or equal
expect( value ).toBeBetween( 1, 10 )
expect( value ).toBeCloseTo( 3.14, 0.01 )

// String matching
expect( str ).toMatch( "regex pattern" )
expect( str ).toInclude( "substring" )

// Exception handling
expect( () => {
    throwError()
} ).toThrow()

expect( () => {
    throwError()
} ).toThrow( type="ValidationException" )

expect( () => {
    throwError()
} ).toThrow( regex=".*error message.*" )

// Instance checks
expect( user ).toBeInstanceOf( "models.User" )

// Satisfying conditions
expect( value ).toSatisfy( ( x ) => x > 0 && x < 100 )

// Collection expectations (all items)
expectAll( [ 2, 4, 6, 8 ] ).toSatisfy( ( x ) => x % 2 == 0 )
```

### Assertion Syntax

```boxlang
// Assertions library (alternative to expectations)
assert( expression, "failure message" )
assertTrue( condition )
assertFalse( condition )
assertEquals( expected, actual )
assertNotEquals( expected, actual )
assertNull( value )
assertNotNull( value )
```

## Mocking with MockBox

### Creating Mocks

```boxlang
describe( "OrderService Tests", () => {
    beforeEach( () => {
        // Create empty mock (no methods)
        variables.mockPaymentGateway = createEmptyMock( "services.PaymentGateway" )
        
        // Create spy (real object with call logging)
        variables.spyEmailService = createMock( "services.EmailService" )
        
        // Create stub (empty object with methods)
        variables.stubLogger = createStub()
    } )
    
    it( "processes payment through gateway", () => {
        // Setup mock behavior
        mockPaymentGateway.$( "processPayment" ).$results( {
            success: true,
            transactionId: "TXN-123"
        } )
        
        var orderService = new models.OrderService( mockPaymentGateway )
        var result = orderService.checkout( orderId=1, amount=100 )
        
        // Verify mock was called
        expect( mockPaymentGateway.$once( "processPayment" ) ).toBeTrue()
        expect( mockPaymentGateway.$times( 1, "processPayment" ) ).toBeTrue()
    } )
    
    it( "sends confirmation email", () => {
        // Setup spy
        spyEmailService.$( "send" ).$results( true )
        
        var orderService = new models.OrderService( emailService=spyEmailService )
        orderService.completeOrder( 1 )
        
        // Verify method was called with specific arguments
        expect( spyEmailService.$once( "send" ) ).toBeTrue()
        var callLog = spyEmailService.$callLog().send
        expect( callLog[ 1 ].to ).toBe( "customer@example.com" )
    } )
} )
```

### Mock Behavior

```boxlang
// Return specific value
mock.$( "methodName" ).$results( returnValue )

// Return different values on subsequent calls
mock.$( "methodName" )
    .$results( firstValue )
    .$results( secondValue )

// Throw exception
mock.$( "methodName" ).$throws( 
    type="CustomException",
    message="Error message"
)

// Call original method
mock.$( "methodName", callOriginal=true )

// Argument matching
mock.$( "methodName" ).$args( arg1="value", arg2="value" )

// Verify calls
expect( mock.$once( "methodName" ) ).toBeTrue()
expect( mock.$times( 3, "methodName" ) ).toBeTrue()
expect( mock.$never( "methodName" ) ).toBeTrue()
expect( mock.$atLeast( 2, "methodName" ) ).toBeTrue()
expect( mock.$atMost( 5, "methodName" ) ).toBeTrue()

// Get call log
var callLog = mock.$callLog().methodName
expect( callLog ).toHaveLength( 2 )
```

## ColdBox Integration Testing

```boxlang
class extends="coldbox.system.testing.BaseTestCase" {
    function beforeAll() {
        super.beforeAll()
        // ColdBox app is available
    }
    
    function testHandlerExecution() {
        // Execute event
        var event = execute( event="users.index", renderResults=true )
        
        // Assert on event
        expect( event.getValue( "users", "" ) ).toBeArray()
        expect( event.getCurrentView() ).toBe( "users/index" )
    }
    
    function testAPIEndpoint() {
        // Execute with POST data
        var event = execute(
            event = "api.users.create",
            renderResults = true,
            route = "/api/users",
            method = "POST"
        )
        
        var response = event.getValue( "data", {} )
        expect( response ).toHaveKey( "id" )
        expect( event.getValue( "statusCode" ) ).toBe( 201 )
    }
}
```

## Running Tests

### CommandBox CLI

```bash
# Run all tests
testbox run

# Run specific directory
testbox run directory=tests/specs/unit

# Run with specific reporter
testbox run reporter=json

# Watch mode (auto-run on changes)
testbox watch

# Generate coverage report
testbox run --coverage
```

## Best Practices

- **Use BDD style** for better readability and documentation
- **Write descriptive test names** that explain what is being tested
- **Use beforeEach/afterEach** for setup and cleanup
- **Mock external dependencies** to isolate unit tests
- **Test one thing per spec** - keep tests focused
- **Use factories** for creating test data consistently
- **Test edge cases** and error conditions
- **Keep tests fast** - avoid unnecessary database calls
- **Use transactions** in integration tests for automatic rollback
- **Run tests in CI/CD** pipeline automatically

## Documentation

For complete TestBox documentation, advanced mocking, and reporters, consult the TestBox MCP server or visit:
https://testbox.ortusbooks.com
