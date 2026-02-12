---
name: testing-bdd
description: Practical guide to TestBox BDD workflows, including spec structure, readable scenario naming, expectation style, setup/teardown patterns, and maintainable behavior-focused tests.
category: testing
priority: high
triggers:
  - bdd testing
  - testbox bdd
  - behavior driven
  - spec testing
---

# BDD Testing Implementation Pattern

## When to Use This Skill

Use this skill when writing behavior-driven tests using TestBox's BDD syntax, creating human-readable specifications, or implementing test-driven development workflows.

## Core Concepts

TestBox BDD Testing:
- Uses describe/it/expect syntax
- Human-readable test specifications
- Nested test suites for organization
- Setup/teardown hooks (beforeEach, afterEach, beforeAll, afterAll)
- Rich expectation matchers
- Supports mocking and stubbing
- Integration with ColdBox framework

## Basic BDD Test Structure (BoxLang)

```boxlang
/**
 * User Service BDD Specs
 * tests/specs/unit/UserServiceSpec.cfc
 */
class UserServiceSpec extends testbox.system.BaseSpec {

    function run() {
        describe( "UserService", function(){

            beforeEach( function(){
                // Setup before each test
                userService = getInstance( "UserService" )
            })

            afterEach( function(){
                // Cleanup after each test
                userService = ""
            })

            it( "should create a new user", function(){
                var userData = {
                    firstName: "John",
                    lastName: "Doe",
                    email: "john@example.com"
                }

                var user = userService.create( userData )

                expect( user ).toBeInstanceOf( "User" )
                expect( user.getEmail() ).toBe( "john@example.com" )
                expect( user.getFullName() ).toBe( "John Doe" )
            })

            it( "should find user by email", function(){
                var user = userService.findByEmail( "test@example.com" )

                expect( user ).notToBeNull()
                expect( user.getEmail() ).toBe( "test@example.com" )
            })

            it( "should throw error for invalid email", function(){
                expect( function(){
                    userService.findByEmail( "invalid-email" )
                }).toThrow( "ValidationException" )
            })
        })
    }
}
```

## Nested Test Suites (BoxLang)

```boxlang
class ProductServiceSpec extends testbox.system.BaseSpec {

    function run() {
        describe( "ProductService", function(){

            beforeAll( function(){
                // Run once before all tests in this suite
                productService = getInstance( "ProductService" )
            })

            describe( "CRUD Operations", function(){

                describe( "Create", function(){

                    it( "should create product with valid data", function(){
                        var product = productService.create({
                            name: "Test Product",
                            price: 99.99,
                            sku: "TEST-001"
                        })

                        expect( product.getId() ).toBeGT( 0 )
                        expect( product.getName() ).toBe( "Test Product" )
                    })

                    it( "should require name field", function(){
                        expect( function(){
                            productService.create({ price: 99.99 })
                        }).toThrow( type = "ValidationException" )
                    })

                    it( "should require unique SKU", function(){
                        expect( function(){
                            productService.create({
                                name: "Product",
                                sku: "DUPLICATE-SKU"
                            })
                        }).toThrow( message = "SKU already exists" )
                    })
                })

                describe( "Read", function(){

                    it( "should get product by ID", function(){
                        var product = productService.getById( 1 )
                        expect( product ).notToBeNull()
                        expect( product.getId() ).toBe( 1 )
                    })

                    it( "should return null for invalid ID", function(){
                        var product = productService.getById( 999999 )
                        expect( product ).toBeNull()
                    })

                    it( "should list all products", function(){
                        var products = productService.list()
                        expect( products ).toBeArray()
                        expect( products.len() ).toBeGTE( 0 )
                    })
                })

                describe( "Update", function(){

                    it( "should update product name", function(){
                        var product = productService.update( 1, {
                            name: "Updated Name"
                        })

                        expect( product.getName() ).toBe( "Updated Name" )
                    })

                    it( "should throw error for invalid ID", function(){
                        expect( function(){
                            productService.update( 999999, {})
                        }).toThrow( "EntityNotFoundException" )
                    })
                })

                describe( "Delete", function(){

                    it( "should delete product", function(){
                        var result = productService.delete( 1 )
                        expect( result ).toBeTrue()
                    })

                    it( "should throw error for invalid ID", function(){
                        expect( function(){
                            productService.delete( 999999 )
                        }).toThrow( "EntityNotFoundException" )
                    })
                })
            })

            describe( "Business Logic", function(){

                it( "should calculate discounted price", function(){
                    var originalPrice = 100
                    var discount = 20  // 20%

                    var discountedPrice = productService.calculateDiscount(
                        originalPrice,
                        discount
                    )

                    expect( discountedPrice ).toBe( 80 )
                })

                it( "should check if product is in stock", function(){
                    var inStock = productService.isInStock( 1 )
                    expect( inStock ).toBeBoolean()
                })

                it( "should get related products", function(){
                    var related = productService.getRelated( 1, limit = 5 )
                    expect( related ).toBeArray()
                    expect( related.len() ).toBeLTE( 5 )
                })
            })
        })
    }
}
```

## BDD Expectations/Matchers (BoxLang)

```boxlang
class ExpectationExamplesSpec extends testbox.system.BaseSpec {

    function run() {
        describe( "TestBox Expectations", function(){

            describe( "Equality Matchers", function(){

                it( "toBe() - strict equality", function(){
                    expect( 1 ).toBe( 1 )
                    expect( "hello" ).toBe( "hello" )
                })

                it( "notToBe() - strict inequality", function(){
                    expect( 1 ).notToBe( 2 )
                    expect( "hello" ).notToBe( "world" )
                })

                it( "toEqual() - deep equality", function(){
                    expect( [1, 2, 3] ).toEqual( [1, 2, 3] )
                    expect({ name: "John" }).toEqual({ name: "John" })
                })
            })

            describe( "Numeric Matchers", function(){

                it( "toBeGT() - greater than", function(){
                    expect( 10 ).toBeGT( 5 )
                })

                it( "toBeGTE() - greater than or equal", function(){
                    expect( 10 ).toBeGTE( 10 )
                    expect( 10 ).toBeGTE( 5 )
                })

                it( "toBeLT() - less than", function(){
                    expect( 5 ).toBeLT( 10 )
                })

                it( "toBeLTE() - less than or equal", function(){
                    expect( 5 ).toBeLTE( 5 )
                    expect( 5 ).toBeLTE( 10 )
                })

                it( "toBeCloseTo() - floating point comparison", function(){
                    expect( 0.1 + 0.2 ).toBeCloseTo( 0.3, 1 )
                })
            })

            describe( "Type Matchers", function(){

                it( "toBeArray()", function(){
                    expect( [] ).toBeArray()
                    expect( [1, 2, 3] ).toBeArray()
                })

                it( "toBeStruct()", function(){
                    expect({}).toBeStruct()
                    expect({ name: "John" }).toBeStruct()
                })

                it( "toBeString()", function(){
                    expect( "hello" ).toBeString()
                })

                it( "toBeNumeric()", function(){
                    expect( 123 ).toBeNumeric()
                    expect( 123.45 ).toBeNumeric()
                })

                it( "toBeBoolean()", function(){
                    expect( true ).toBeBoolean()
                    expect( false ).toBeBoolean()
                })

                it( "toBeInstanceOf()", function(){
                    var user = getInstance( "User" )
                    expect( user ).toBeInstanceOf( "User" )
                })
            })

            describe( "Null/Empty Matchers", function(){

                it( "toBeNull()", function(){
                    expect( javacast( "null", "" ) ).toBeNull()
                })

                it( "notToBeNull()", function(){
                    expect( "value" ).notToBeNull()
                })

                it( "toBeEmpty()", function(){
                    expect( "" ).toBeEmpty()
                    expect( [] ).toBeEmpty()
                    expect({}).toBeEmpty()
                })

                it( "notToBeEmpty()", function(){
                    expect( "value" ).notToBeEmpty()
                    expect( [1] ).notToBeEmpty()
                    expect({ key: "value" }).notToBeEmpty()
                })
            })

            describe( "Boolean Matchers", function(){

                it( "toBeTrue()", function(){
                    expect( true ).toBeTrue()
                    expect( 1 == 1 ).toBeTrue()
                })

                it( "toBeFalse()", function(){
                    expect( false ).toBeFalse()
                    expect( 1 == 2 ).toBeFalse()
                })
            })

            describe( "String Matchers", function(){

                it( "toInclude() - string contains", function(){
                    expect( "Hello World" ).toInclude( "World" )
                })

                it( "toMatch() - regex match", function(){
                    expect( "test@example.com" ).toMatch( "^\w+@\w+\.\w+$" )
                })
            })

            describe( "Collection Matchers", function(){

                it( "toHaveKey()", function(){
                    expect({ name: "John", age: 30 }).toHaveKey( "name" )
                })

                it( "toHaveLength()", function(){
                    expect( [1, 2, 3] ).toHaveLength( 3 )
                    expect( "hello" ).toHaveLength( 5 )
                })

                it( "toContain()", function(){
                    expect( [1, 2, 3] ).toContain( 2 )
                })
            })

            describe( "Exception Matchers", function(){

                it( "toThrow() - any exception", function(){
                    expect( function(){
                        throw( message = "Error" )
                    }).toThrow()
                })

                it( "toThrow() - specific type", function(){
                    expect( function(){
                        throw( type = "ValidationException", message = "Invalid" )
                    }).toThrow( type = "ValidationException" )
                })

                it( "toThrow() - specific message", function(){
                    expect( function(){
                        throw( message = "Invalid email" )
                    }).toThrow( message = "Invalid email" )
                })

                it( "notToThrow()", function(){
                    expect( function(){
                        var x = 1 + 1
                    }).notToThrow()
                })
            })
        })
    }
}
```

## Setup and Teardown Hooks (BoxLang)

```boxlang
class LifecycleHooksSpec extends testbox.system.BaseSpec {

    // Properties available to all tests
    property name="testData";
    property name="service";

    function run() {
        describe( "Lifecycle Hooks", function(){

            // Runs ONCE before ALL tests in this suite
            beforeAll( function(){
                // Setup expensive resources
                testData = {
                    users: [],
                    products: []
                }
                service = getInstance( "DataService" )
                service.seedTestData()
            })

            // Runs ONCE after ALL tests in this suite
            afterAll( function(){
                // Cleanup expensive resources
                service.clearTestData()
                testData = {}
            })

            // Runs before EACH test
            beforeEach( function(){
                // Reset state before each test
                testData.currentUser = getInstance( "User" ).new()
            })

            // Runs after EACH test
            afterEach( function(){
                // Cleanup after each test
                testData.currentUser = ""
            })

            it( "test 1", function(){
                expect( testData ).toHaveKey( "users" )
                expect( testData.currentUser ).notToBeNull()
            })

            it( "test 2", function(){
                expect( testData ).toHaveKey( "products" )
                expect( testData.currentUser ).notToBeNull()
            })

            describe( "Nested Suite", function(){

                // These hooks only apply to this nested suite
                beforeEach( function(){
                    testData.nestedData = "value"
                })

                afterEach( function(){
                    structDelete( testData, "nestedData" )
                })

                it( "nested test", function(){
                    expect( testData ).toHaveKey( "nestedData" )
                })
            })
        })
    }
}
```

## Pending/Skipped Tests (BoxLang)

```boxlang
class PendingTestsSpec extends testbox.system.BaseSpec {

    function run() {
        describe( "Feature X", function(){

            // Mark test as pending (will show as skipped)
            xit( "should implement feature X", function(){
                // Test implementation pending
            })

            // Mark entire suite as pending
            xdescribe( "Future Feature", function(){

                it( "test 1", function(){
                    // This whole suite will be skipped
                })

                it( "test 2", function(){
                    // This too
                })
            })

            // Test with pending status
            it( "should be implemented later", function(){
                pending( "Waiting for API changes" )
                // Test code here
            })
        })
    }
}
```

## Testing Async Operations (BoxLang)

```boxlang
class AsyncSpec extends testbox.system.BaseSpec {

    function run() {
        describe( "Async Operations", function(){

            it( "should handle async operation", function(){
                var result = ""

                // Trigger async operation
                asyncService.processData( function( data ){
                    result = data
                })

                // Wait for async operation
                waitsFor( function(){
                    return len( result ) > 0
                }, "async operation to complete", 5000 )

                // Verify result
                runs( function(){
                    expect( result ).notToBeEmpty()
                })
            })
        })
    }
}
```

## Running BDD Tests

```bash
# Run all tests
box testbox run

# Run specific test bundle
box testbox run --bundles=tests.specs.unit.UserServiceSpec

# Run tests matching pattern
box testbox run --labels="database"

# Run with verbose output
box testbox run --verbose

# Run with coverage
box testbox run --coverage

# Run in browser
http://localhost/tests/runner.cfm
```

## Custom Matchers (BoxLang)

```boxlang
class CustomMatchersSpec extends testbox.system.BaseSpec {

    function run() {
        // Add custom matcher
        addMatchers({
            toBeValidEmail: function( expectation, args = {} ){
                var actual = arguments.expectation.actual
                var isValid = reFindNoCase( "^\w+@\w+\.\w+$", actual )

                if( isValid ){
                    return true
                } else {
                    expectation.message = "Expected #actual# to be a valid email"
                    return false
                }
            },

            toHavePermission: function( expectation, args = {} ){
                var user = arguments.expectation.actual
                var permission = arguments.args.permission ?: ""

                if( user.hasPermission( permission ) ){
                    return true
                } else {
                    expectation.message = "Expected user to have permission: #permission#"
                    return false
                }
            }
        })

        describe( "Custom Matchers", function(){

            it( "should validate email", function(){
                expect( "test@example.com" ).toBeValidEmail()
            })

            it( "should check user permissions", function(){
                var user = getInstance( "User" ).new()
                user.addPermission( "admin.access" )

                expect( user ).toHavePermission( permission = "admin.access" )
            })
        })
    }
}
```

## Best Practices

1. **Descriptive Names**: Use clear describe/it names
2. **One Assertion Per Test**: Test one thing at a time
3. **Setup/Teardown**: Use hooks for common setup
4. **Independent Tests**: Tests should not depend on each other
5. **Test Edge Cases**: Test boundary conditions
6. **Readable Expectations**: Use appropriate matchers
7. **Organize Tests**: Group related tests in describe blocks
8. **Mock External Dependencies**: Isolate units under test
9. **Test First**: Write tests before implementation (TDD)
10. **Keep Tests Fast**: Fast tests encourage frequent running

## Common Pitfalls

1. **Dependent Tests**: Tests relying on execution order
2. **Shared State**: Not cleaning up between tests
3. **Too Many Assertions**: Testing multiple things in one test
4. **Poor Names**: Vague describe/it descriptions
5. **No Edge Cases**: Only testing happy path
6. **Slow Tests**: Tests taking too long to run
7. **Missing Cleanup**: Not using after hooks
8. **Hard Dependencies**: Not mocking external services
9. **Complex Setup**: Over-complicated test setup
10. **Ignoring Failures**: Skipping failing tests

## Related Skills

- `testing-unit` - Unit testing patterns
- `testing-handler` - Handler testing
- `testing-mocking` - MockBox patterns
- `testing-integration` - Integration testing
- `testing-fixtures` - Test fixtures
