---
name: Unit Testing in TestBox
description: Comprehensive guide to writing unit tests with TestBox, including test organization, assertions, expectations, data providers, and testing best practices for isolated component testing
category: testing
priority: high
triggers:
  - unit test
  - unit testing
  - TestBox
  - component test
  - function test
  - method test
  - test case
  - expectations
  - assertions
---

# Unit Testing in TestBox

## Overview

Unit testing focuses on testing individual components, functions, or methods in isolation. TestBox provides a comprehensive testing framework supporting both BDD (describe/it) and xUnit (test methods) syntax for writing unit tests. Effective unit tests are fast, isolated, and test a single unit of functionality.

## Core Concepts

### Unit Test Characteristics

**Good Unit Tests Are:**
- ✅ **Fast** - Execute in milliseconds
- ✅ **Isolated** - No dependencies on external systems
- ✅ **Repeatable** - Same results every time
- ✅ **Self-Validating** - Clear pass/fail results
- ✅ **Timely** - Written before or with code

### Test Structure (AAA Pattern)

```boxlang
// Arrange - Set up test data and conditions
// Act - Execute the code being tested
// Assert - Verify the expected outcome

it( "should calculate total price correctly", () => {
    // Arrange
    calculator = new PriceCalculator()
    price = 100
    taxRate = 0.08

    // Act
    total = calculator.calculateTotal( price, taxRate )

    // Assert
    expect( total ).toBe( 108 )
} )
```

## Basic Unit Test Structure

### BDD Style Test Spec

```boxlang
/**
 * UserServiceSpec.bx
 * Unit tests for UserService component
 */
component extends="testbox.system.BaseSpec" {

    /*********************************** LIFE CYCLE Methods ***********************************/

    function beforeAll() {
        // Runs once before all tests in this spec
        userService = new models.UserService()
    }

    function afterAll() {
        // Runs once after all tests in this spec
        structClear( variables )
    }

    function beforeEach() {
        // Runs before each test
        testUser = {
            id: 1,
            name: "John Doe",
            email: "john@example.com",
            active: true
        }
    }

    function afterEach() {
        // Runs after each test
        testUser = {}
    }

    /*********************************** TEST SUITES ***********************************/

    function run() {
        describe( "UserService", () => {

            describe( "validateEmail()", () => {

                it( "should validate correct email format", () => {
                    result = userService.validateEmail( "john@example.com" )
                    expect( result ).toBeTrue()
                } )

                it( "should reject invalid email format", () => {
                    result = userService.validateEmail( "invalid-email" )
                    expect( result ).toBeFalse()
                } )

                it( "should reject empty email", () => {
                    result = userService.validateEmail( "" )
                    expect( result ).toBeFalse()
                } )
            } )

            describe( "formatName()", () => {

                it( "should capitalize first and last name", () => {
                    result = userService.formatName( "john", "doe" )
                    expect( result ).toBe( "John Doe" )
                } )

                it( "should handle single name", () => {
                    result = userService.formatName( "john", "" )
                    expect( result ).toBe( "John" )
                } )

                it( "should trim whitespace", () => {
                    result = userService.formatName( "  john  ", "  doe  " )
                    expect( result ).toBe( "John Doe" )
                } )
            } )

            describe( "calculateAge()", () => {

                it( "should calculate age from birthdate", () => {
                    birthDate = createDate( 1990, 1, 1 )
                    age = userService.calculateAge( birthDate )
                    expect( age ).toBeGTE( 34 )
                } )

                it( "should return 0 for future dates", () => {
                    futureDate = dateAdd( "yyyy", 1, now() )
                    age = userService.calculateAge( futureDate )
                    expect( age ).toBe( 0 )
                } )
            } )
        } )
    }
}
```

### xUnit Style Test Case

```boxlang
/**
 * CalculatorTest.bx
 * xUnit style unit tests
 */
component extends="testbox.system.BaseSpec" {

    function beforeTests() {
        calculator = new models.Calculator()
    }

    function testAdd() {
        result = calculator.add( 5, 3 )
        $assert.isEqual( result, 8 )
    }

    function testSubtract() {
        result = calculator.subtract( 10, 3 )
        $assert.isEqual( result, 7 )
    }

    function testMultiply() {
        result = calculator.multiply( 4, 5 )
        $assert.isEqual( result, 20 )
    }

    function testDivide() {
        result = calculator.divide( 10, 2 )
        $assert.isEqual( result, 5 )
    }

    function testDivideByZero() {
        $assert.throws( () => calculator.divide( 10, 0 ) )
    }
}
```

## Expectations and Matchers

### Common Expectations

```boxlang
// Equality
expect( actual ).toBe( expected )
expect( actual ).notToBe( expected )

// Truthiness
expect( value ).toBeTrue()
expect( value ).toBeFalse()
expect( value ).toBeDefined()
expect( value ).toBeNull()

// Numeric comparisons
expect( value ).toBeGT( 10 )      // Greater than
expect( value ).toBeGTE( 10 )     // Greater than or equal
expect( value ).toBeLT( 100 )     // Less than
expect( value ).toBeLTE( 100 )    // Less than or equal
expect( value ).toBeCloseTo( 10.5, 0.1 ) // Within delta

// String matchers
expect( str ).toInclude( "substring" )
expect( str ).toMatch( "regex" )
expect( str ).toBeEmpty()

// Collection matchers
expect( array ).toHaveLength( 5 )
expect( array ).toBeEmpty()
expect( array ).toInclude( item )
expect( struct ).toHaveKey( "name" )

// Type matchers
expect( value ).toBeTypeOf( "numeric" )
expect( value ).toBeInstanceOf( "UserService" )
expect( value ).toBeArray()
expect( value ).toBeStruct()
expect( value ).toBeString()
expect( value ).toBeNumeric()
expect( value ).toBeBoolean()
```

### Custom Matchers

```boxlang
// Create custom matcher
function toBeValidEmail( expectation, args = {} ) {
    regex = "^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}$"

    if ( reFindNoCase( regex, arguments.expectation.actual ) ) {
        expectation.pass( "Expected [#arguments.expectation.actual#] to be valid email" )
    } else {
        expectation.fail( "Expected [#arguments.expectation.actual#] to be valid email" )
    }
}

// Use custom matcher
expect( email ).toBeValidEmail()
```

## Testing Different Scenarios

### Testing Return Values

```boxlang
describe( "Calculator operations", () => {

    it( "should return correct sum", () => {
        result = calculator.add( 5, 3 )
        expect( result ).toBe( 8 )
        expect( result ).toBeNumeric()
    } )

    it( "should return struct with multiple values", () => {
        result = calculator.getStatistics()

        expect( result ).toBeStruct()
        expect( result ).toHaveKey( "total" )
        expect( result ).toHaveKey( "average" )
        expect( result.total ).toBeNumeric()
    } )

    it( "should return array of results", () => {
        results = calculator.calculateBatch( [ 1, 2, 3 ] )

        expect( results ).toBeArray()
        expect( results ).toHaveLength( 3 )
        expect( results[1] ).toBe( 2 )
    } )
} )
```

### Testing Exceptions

```boxlang
describe( "Error handling", () => {

    it( "should throw exception for invalid input", () => {
        expect( () => calculator.divide( 10, 0 ) )
            .toThrow()
    } )

    it( "should throw specific exception type", () => {
        expect( () => calculator.divide( 10, 0 ) )
            .toThrow( "DivisionByZeroException" )
    } )

    it( "should throw exception with message", () => {
        expect( () => calculator.divide( 10, 0 ) )
            .toThrow( message = "Cannot divide by zero" )
    } )

    it( "should not throw exception for valid input", () => {
        expect( () => calculator.divide( 10, 2 ) )
            .notToThrow()
    } )
} )
```

### Testing Edge Cases

```boxlang
describe( "Edge cases", () => {

    it( "should handle null values", () => {
        result = userService.formatName( null, null )
        expect( result ).toBe( "" )
    } )

    it( "should handle empty strings", () => {
        result = userService.formatName( "", "" )
        expect( result ).toBe( "" )
    } )

    it( "should handle very large numbers", () => {
        result = calculator.add( 999999999, 1 )
        expect( result ).toBe( 1000000000 )
    } )

    it( "should handle very small numbers", () => {
        result = calculator.multiply( 0.0001, 0.0001 )
        expect( result ).toBeCloseTo( 0.00000001, 0.000000001 )
    } )

    it( "should handle empty arrays", () => {
        result = arrayService.sum( [] )
        expect( result ).toBe( 0 )
    } )

    it( "should handle single item arrays", () => {
        result = arrayService.sum( [ 42 ] )
        expect( result ).toBe( 42 )
    } )
} )
```

### Testing Boolean Logic

```boxlang
describe( "Boolean operations", () => {

    it( "should validate active user", () => {
        user = { active: true, verified: true }
        result = userService.canLogin( user )
        expect( result ).toBeTrue()
    } )

    it( "should reject inactive user", () => {
        user = { active: false, verified: true }
        result = userService.canLogin( user )
        expect( result ).toBeFalse()
    } )

    it( "should check multiple conditions", () => {
        user = { age: 25, hasLicense: true, insured: true }
        result = rentalService.canRent( user )
        expect( result ).toBeTrue()
    } )
} )
```

## Data-Driven Testing

### Using Data Providers

```boxlang
describe( "Email validation with data provider", () => {

    // Define test data
    emailTestCases = [
        { email: "valid@example.com", expected: true },
        { email: "user.name@example.com", expected: true },
        { email: "user+tag@example.co.uk", expected: true },
        { email: "invalid@", expected: false },
        { email: "@example.com", expected: false },
        { email: "no-at-sign.com", expected: false },
        { email: "", expected: false }
    ]

    // Run test for each case
    emailTestCases.each( ( testCase ) => {
        it( "should validate '#testCase.email#' as #testCase.expected#", () => {
            result = userService.validateEmail( testCase.email )
            expect( result ).toBe( testCase.expected )
        } )
    } )
} )
```

### Parameterized Tests

```boxlang
describe( "Calculator with multiple inputs", () => {

    testData = [
        { a: 2, b: 2, expected: 4 },
        { a: 5, b: 3, expected: 8 },
        { a: 0, b: 10, expected: 10 },
        { a: -5, b: 5, expected: 0 },
        { a: 100, b: -50, expected: 50 }
    ]

    testData.each( ( data ) => {
        it( "should add #data.a# + #data.b# = #data.expected#", () => {
            result = calculator.add( data.a, data.b )
            expect( result ).toBe( data.expected )
        } )
    } )
} )
```

## Testing Private Methods

### Indirect Testing (Preferred)

```boxlang
// Test private methods through public interface
describe( "UserService public methods", () => {

    it( "should validate and format user data", () => {
        // processUser() internally calls private _validateData() and _formatData()
        result = userService.processUser( {
            name: "john doe",
            email: "test@example.com"
        } )

        expect( result.success ).toBeTrue()
        expect( result.name ).toBe( "John Doe" ) // formatted by private method
    } )
} )
```

### Direct Testing (When Necessary)

```boxlang
// Access private method using getMetadata
describe( "Private method testing", () => {

    it( "should test private validation method", () => {
        // Get component metadata
        metadata = getMetadata( userService )

        // Find private method
        privateMethod = metadata.functions.find( ( f ) => f.name == "_validateEmail" )

        // Invoke private method
        result = invoke( userService, "_validateEmail", { email: "test@example.com" } )

        expect( result ).toBeTrue()
    } )
} )
```

## Testing Pure Functions

### Stateless Function Tests

```boxlang
describe( "Pure utility functions", () => {

    it( "should format currency consistently", () => {
        result1 = utils.formatCurrency( 1234.56 )
        result2 = utils.formatCurrency( 1234.56 )

        expect( result1 ).toBe( result2 )
        expect( result1 ).toBe( "$1,234.56" )
    } )

    it( "should calculate percentage", () => {
        result = mathUtils.percentage( 50, 200 )
        expect( result ).toBe( 25 )
    } )

    it( "should convert temperature", () => {
        fahrenheit = tempUtils.celsiusToFahrenheit( 0 )
        expect( fahrenheit ).toBe( 32 )

        celsius = tempUtils.fahrenheitToCelsius( 32 )
        expect( celsius ).toBe( 0 )
    } )
} )
```

## Testing Object State

### Testing State Changes

```boxlang
describe( "ShoppingCart state management", () => {

    beforeEach( () => {
        cart = new models.ShoppingCart()
    } )

    it( "should start with empty cart", () => {
        expect( cart.getItemCount() ).toBe( 0 )
        expect( cart.getTotal() ).toBe( 0 )
    } )

    it( "should add item to cart", () => {
        cart.addItem( { id: 1, name: "Product", price: 10 } )

        expect( cart.getItemCount() ).toBe( 1 )
        expect( cart.getTotal() ).toBe( 10 )
    } )

    it( "should update quantities", () => {
        cart.addItem( { id: 1, name: "Product", price: 10 } )
        cart.addItem( { id: 1, name: "Product", price: 10 } )

        expect( cart.getItemCount() ).toBe( 1 )
        expect( cart.getItemQuantity( 1 ) ).toBe( 2 )
        expect( cart.getTotal() ).toBe( 20 )
    } )

    it( "should remove item from cart", () => {
        cart.addItem( { id: 1, name: "Product", price: 10 } )
        cart.removeItem( 1 )

        expect( cart.getItemCount() ).toBe( 0 )
        expect( cart.getTotal() ).toBe( 0 )
    } )
} )
```

## Performance Testing in Unit Tests

### Testing Execution Time

```boxlang
describe( "Performance tests", () => {

    it( "should execute search within acceptable time", () => {
        startTime = getTickCount()

        results = searchService.search( "test query" )

        duration = getTickCount() - startTime

        expect( duration ).toBeLT( 100 ) // Less than 100ms
        expect( results ).toBeArray()
    } )

    it( "should handle large datasets efficiently", () => {
        largeDataset = []
        for ( i = 1; i <= 10000; i++ ) {
            largeDataset.append( { id: i, value: "item#i#" } )
        }

        startTime = getTickCount()
        result = dataProcessor.process( largeDataset )
        duration = getTickCount() - startTime

        expect( duration ).toBeLT( 1000 ) // Less than 1 second
    } )
} )
```

## Test Organization Best Practices

### Grouping Related Tests

```boxlang
describe( "UserService", () => {

    describe( "User Creation", () => {
        it( "should create user with valid data", () => {
            // Test implementation
        } )

        it( "should reject duplicate email", () => {
            // Test implementation
        } )
    } )

    describe( "User Validation", () => {
        it( "should validate email format", () => {
            // Test implementation
        } )

        it( "should validate password strength", () => {
            // Test implementation
        } )
    } )

    describe( "User Updates", () => {
        it( "should update user profile", () => {
            // Test implementation
        } )

        it( "should prevent unauthorized updates", () => {
            // Test implementation
        } )
    } )
} )
```

### Test Naming Conventions

```boxlang
// ✅ Good: Descriptive test names
it( "should calculate total with tax included", () => {} )
it( "should throw exception when user not found", () => {} )
it( "should return empty array for no results", () => {} )

// ❌ Bad: Vague test names
it( "test1", () => {} )
it( "should work", () => {} )
it( "calculation", () => {} )

// Pattern: should [expected behavior] when [condition]
it( "should return 404 when user does not exist", () => {} )
it( "should send email when order is confirmed", () => {} )
it( "should cache result when cache is enabled", () => {} )
```

## Testing Best Practices

### FIRST Principles

**Fast**
```boxlang
// ✅ Fast unit test
it( "should validate email format", () => {
    result = validator.validateEmail( "test@example.com" )
    expect( result ).toBeTrue()
} )

// ❌ Slow test (integration, not unit)
it( "should save user to database", () => {
    user = userService.save( userData ) // Database call
    expect( user.id ).toBeNumeric()
} )
```

**Independent**
```boxlang
// ✅ Independent tests
beforeEach( () => {
    calculator = new Calculator() // Fresh instance each test
} )

it( "test 1", () => {
    result = calculator.add( 2, 2 )
    expect( result ).toBe( 4 )
} )

it( "test 2", () => {
    result = calculator.multiply( 3, 3 )
    expect( result ).toBe( 9 )
} )

// ❌ Dependent tests
it( "test 1", () => {
    calculator.add( 2, 2 ) // Sets internal state
} )

it( "test 2", () => {
    result = calculator.getLastResult() // Depends on test 1
    expect( result ).toBe( 4 )
} )
```

**Repeatable**
```boxlang
// ✅ Repeatable (deterministic)
it( "should calculate percentage", () => {
    result = mathUtils.percentage( 50, 200 )
    expect( result ).toBe( 25 )
} )

// ❌ Not repeatable (uses current time)
it( "should return current year", () => {
    result = dateUtils.getCurrentYear()
    expect( result ).toBe( 2024 ) // Fails next year!
} )

// ✅ Fixed: Use dependency injection
it( "should return provided year", () => {
    mockDate = createDate( 2024, 1, 1 )
    result = dateUtils.getYear( mockDate )
    expect( result ).toBe( 2024 )
} )
```

**Self-Validating**
```boxlang
// ✅ Clear pass/fail
it( "should return valid user", () => {
    user = userService.find( 1 )
    expect( user.id ).toBe( 1 )
    expect( user.name ).notToBeEmpty()
} )

// ❌ Requires manual inspection
it( "should return user", () => {
    user = userService.find( 1 )
    writeDump( user ) // Manual check required
} )
```

**Timely**
```boxlang
// Write tests as you write code (TDD)
// Or immediately after (Test-After Development)
// Don't wait until the end of development
```

### One Assertion Per Test (When Possible)

```boxlang
// ✅ Preferred: Single assertion
it( "should return user ID", () => {
    user = userService.find( 1 )
    expect( user.id ).toBe( 1 )
} )

it( "should return user name", () => {
    user = userService.find( 1 )
    expect( user.name ).toBe( "John Doe" )
} )

// ✅ Also acceptable: Multiple related assertions
it( "should return complete user object", () => {
    user = userService.find( 1 )
    expect( user.id ).toBe( 1 )
    expect( user.name ).toBe( "John Doe" )
    expect( user.email ).toBe( "john@example.com" )
} )
```

## Common Pitfalls

### Pitfalls to Avoid

1. **Testing Implementation**: Test behavior, not implementation details
2. **Too Many Assertions**: Keep tests focused
3. **Not Testing Edge Cases**: Test boundaries and error conditions
4. **Hardcoded Data**: Use variables for test data
5. **External Dependencies**: Unit tests should be isolated
6. **Testing Frameworks**: Don't test BoxLang or TestBox features
7. **Brittle Tests**: Tests break with minor refactoring
8. **No Negative Tests**: Test failure scenarios
9. **Duplicate Code**: Use beforeEach() for common setup
10. **Poor Test Names**: Test names should describe expected behavior

### Troubleshooting

```boxlang
// Debug failing tests
it( "should process data", () => {
    result = service.process( testData )

    // Add debug output
    writeDump( var = result, label = "Result" )
    writeDump( var = testData, label = "Input" )

    expect( result.success ).toBeTrue()
} )

// Isolate failing test with fdescribe/fit (focused tests)
fdescribe( "Focused test suite", () => {
    fit( "only this test runs", () => {
        // Test implementation
    } )
} )

// Skip tests temporarily with xdescribe/xit
xdescribe( "Skipped suite", () => {
    xit( "skipped test", () => {
        // Not executed
    } )
} )
```

## Related Skills

- [BDD Testing](testing-bdd.md) - Behavior-driven development patterns
- [Testing Mocking](testing-mocking.md) - Mocking dependencies
- [Testing Handlers](testing-handler.md) - Testing ColdBox handlers
- [Testing Coverage](testing-coverage.md) - Code coverage analysis

## References

- [TestBox Documentation](https://testbox.ortusbooks.com/)
- [TestBox Expectations](https://testbox.ortusbooks.com/primers/testbox-bdd-primer/expectations)
- [TestBox Matchers](https://testbox.ortusbooks.com/primers/testbox-bdd-primer/expectation-methods)
