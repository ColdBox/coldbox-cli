---
name: Testing ColdBox Handlers
description: Comprehensive guide to testing ColdBox event handlers, including request context mocking, event execution, HTTP method testing, and validation testing for controllers
category: testing
priority: high
triggers:
  - handler test
  - handler testing
  - controller test
  - event handler
  - integration test
  - ColdBox test
  - event context
  - request context
  - mock event
---

# Testing ColdBox Handlers

## Overview

Testing ColdBox handlers ensures that your application controllers properly handle requests, process data, interact with models, and return appropriate responses. Handler tests validate routing, HTTP methods, request/response handling, and integration with the ColdBox framework.

## Core Concepts

### Handler Test Characteristics

- **Framework Integration**: Tests ColdBox request lifecycle
- **Event Execution**: Simulates event execution
- **Context Mocking**: Mock request context (rc/prc)
- **Model Integration**: Test interactions with services/models
- **Response Validation**: Verify views, relocations, data rendering

### Test Types

1. **Unit Tests**: Test handler methods in isolation with mocks
2. **Integration Tests**: Test handlers with real framework execution
3. **HTTP Tests**: Validate HTTP methods (GET, POST, PUT, DELETE)
4. **Security Tests**: Test authentication and authorization

## Basic Handler Test Structure

### BDD Style Handler Spec

```boxlang
/**
 * UsersHandlerSpec.bx
 * Integration tests for Users handler
 */
component extends="coldbox.system.testing.BaseTestCase" appMapping="/root" {

    /*********************************** LIFE CYCLE Methods ***********************************/

    function beforeAll() {
        super.beforeAll()

        // Setup ColdBox application
        super.setup()

        // Dependency injection for mocks
        mockUserService = createMock( "models.UserService" )

        // Inject mock into handler
        getController()
            .getWireBox()
            .getInstance( "UsersHandler" )
            .setUserService( mockUserService )
    }

    function afterAll() {
        super.afterAll()
    }

    /*********************************** TEST SUITES ***********************************/

    function run() {
        describe( "Users Handler", () => {

            beforeEach( () => {
                // Reset mocks before each test
                mockUserService.$reset()
            } )

            describe( "index action", () => {

                it( "should display user list", () => {
                    // Mock service response
                    mockUsers = [
                        { id: 1, name: "John Doe" },
                        { id: 2, name: "Jane Smith" }
                    ]
                    mockUserService.$( "list" ).$results( mockUsers )

                    // Execute event
                    event = execute( event = "users.index", renderResults = true )

                    // Get request context
                    rc = event.getCollection()
                    prc = event.getPrivateCollection()

                    // Assertions
                    expect( prc.users ).toBeArray()
                    expect( prc.users ).toHaveLength( 2 )
                    expect( event.getValue( "cbox_rendered_content" ) ).toInclude( "John Doe" )
                } )

                it( "should handle empty user list", () => {
                    mockUserService.$( "list" ).$results( [] )

                    event = execute( event = "users.index", renderResults = true )
                    prc = event.getPrivateCollection()

                    expect( prc.users ).toBeEmpty()
                } )
            } )

            describe( "show action", () => {

                it( "should display user details", () => {
                    mockUser = { id: 1, name: "John Doe", email: "john@example.com" }
                    mockUserService.$( "find" ).$args( 1 ).$results( mockUser )

                    event = execute(
                        event = "users.show",
                        eventArguments = { id: 1 },
                        renderResults = true
                    )

                    prc = event.getPrivateCollection()

                    expect( prc.user.id ).toBe( 1 )
                    expect( prc.user.name ).toBe( "John Doe" )
                } )

                it( "should redirect when user not found", () => {
                    mockUserService.$( "find" ).$args( 999 ).$results( null )

                    event = execute(
                        event = "users.show",
                        eventArguments = { id: 999 }
                    )

                    expect( event.getValue( "relocate_URI" ) ).toBe( "/users" )
                } )
            } )

            describe( "create action", () => {

                it( "should render create form", () => {
                    event = execute( event = "users.create", renderResults = true )

                    expect( event.getRenderedContent() ).toInclude( "Create User" )
                    expect( event.getRenderedContent() ).toInclude( "form" )
                } )
            } )

            describe( "store action", () => {

                it( "should create new user with valid data", () => {
                    mockUserService
                        .$( "create" )
                        .$results( { id: 1, name: "John Doe" } )

                    event = execute(
                        event = "users.store",
                        eventArguments = {
                            name: "John Doe",
                            email: "john@example.com"
                        }
                    )

                    // Verify service was called
                    expect( mockUserService.$once( "create" ) ).toBeTrue()

                    // Verify redirect
                    expect( event.getValue( "relocate_URI" ) ).toInclude( "/users" )
                } )

                it( "should reject invalid email", () => {
                    mockUserService
                        .$( "create" )
                        .$throw( type = "ValidationException", message = "Invalid email" )

                    event = execute(
                        event = "users.store",
                        eventArguments = {
                            name: "John Doe",
                            email: "invalid-email"
                        }
                    )

                    // Should re-render form with errors
                    expect( event.getValue( "cbox_rendered_content" ) ).toInclude( "Invalid email" )
                } )
            } )

            describe( "update action", () => {

                it( "should update existing user", () => {
                    mockUserService
                        .$( "update" )
                        .$args( 1 )
                        .$results( true )

                    event = execute(
                        event = "users.update",
                        eventArguments = {
                            id: 1,
                            name: "John Updated",
                            email: "john@example.com"
                        }
                    )

                    expect( mockUserService.$once( "update" ) ).toBeTrue()
                    expect( event.getValue( "relocate_URI" ) ).toInclude( "/users/1" )
                } )
            } )

            describe( "delete action", () => {

                it( "should delete user", () => {
                    mockUserService.$( "delete" ).$args( 1 ).$results( true )

                    event = execute(
                        event = "users.delete",
                        eventArguments = { id: 1 }
                    )

                    expect( mockUserService.$once( "delete" ) ).toBeTrue()
                    expect( event.getValue( "relocate_URI" ) ).toBe( "/users" )
                } )
            } )
        } )
    }
}
```

## Testing Request Context (RC/PRC)

### Setting Request Collection

```boxlang
it( "should process form submission", () => {
    // Prepare request collection
    event = execute(
        event = "users.store",
        eventArguments = {
            name: "John Doe",
            email: "john@example.com",
            age: 30
        }
    )

    // Access collections
    rc = event.getCollection()
    prc = event.getPrivateCollection()

    // Verify data
    expect( rc.name ).toBe( "John Doe" )
    expect( rc.email ).toBe( "john@example.com" )
} )
```

### Testing Private Request Collection

```boxlang
it( "should store data in private collection", () => {
    mockUserService.$( "find" ).$results( { id: 1, name: "John" } )

    event = execute( event = "users.show", eventArguments = { id: 1 } )
    prc = event.getPrivateCollection()

    // Handler should store user in prc
    expect( prc ).toHaveKey( "user" )
    expect( prc.user.id ).toBe( 1 )
} )
```

## Testing HTTP Methods

### GET Requests

```boxlang
describe( "GET requests", () => {

    it( "should handle GET /users", () => {
        mockUserService.$( "list" ).$results( [] )

        event = execute(
            event = "users.index",
            renderResults = true
        )

        expect( event.getRenderedContent() ).toInclude( "Users" )
    } )

    it( "should handle GET /users/:id", () => {
        mockUserService.$( "find" ).$results( { id: 1 } )

        event = execute(
            event = "users.show",
            eventArguments = { id: 1 }
        )

        expect( event.getPrivateValue( "user" ) ).toHaveKey( "id" )
    } )
} )
```

### POST Requests

```boxlang
describe( "POST requests", () => {

    it( "should handle POST /users", () => {
        mockUserService.$( "create" ).$results( { id: 1 } )

        event = execute(
            event = "users.store",
            eventArguments = {
                name: "John Doe",
                email: "john@example.com"
            }
        )

        expect( mockUserService.$once( "create" ) ).toBeTrue()
    } )
} )
```

### PUT/PATCH Requests

```boxlang
describe( "PUT requests", () => {

    it( "should handle PUT /users/:id", () => {
        mockUserService.$( "update" ).$results( true )

        event = execute(
            event = "users.update",
            eventArguments = {
                id: 1,
                name: "John Updated"
            }
        )

        expect( mockUserService.$once( "update" ) ).toBeTrue()
    } )
} )
```

### DELETE Requests

```boxlang
describe( "DELETE requests", () => {

    it( "should handle DELETE /users/:id", () => {
        mockUserService.$( "delete" ).$results( true )

        event = execute(
            event = "users.delete",
            eventArguments = { id: 1 }
        )

        expect( mockUserService.$once( "delete" ) ).toBeTrue()
        expect( event.getValue( "relocate_URI" ) ).toBe( "/users" )
    } )
} )
```

## Testing Relocations

### Testing Redirects

```boxlang
it( "should redirect after successful creation", () => {
    mockUserService.$( "create" ).$results( { id: 1 } )

    event = execute(
        event = "users.store",
        eventArguments = { name: "John" }
    )

    // Check relocation occurred
    expect( event.getValue( "relocate_URI", "" ) ).notToBeEmpty()
    expect( event.getValue( "relocate_URI" ) ).toInclude( "/users" )
} )

it( "should redirect with status messages", () => {
    mockUserService.$( "create" ).$results( { id: 1 } )

    event = execute(
        event = "users.store",
        eventArguments = { name: "John" }
    )

    // Check flash scope
    flash = event.getFlash()
    expect( flash.exists( "success" ) ).toBeTrue()
} )
```

## Testing Views

### Rendered Content Testing

```boxlang
it( "should render user list view", () => {
    mockUserService.$( "list" ).$results( [
        { id: 1, name: "John" },
        { id: 2, name: "Jane" }
    ] )

    event = execute( event = "users.index", renderResults = true )
    rendered = event.getRenderedContent()

    expect( rendered ).toInclude( "John" )
    expect( rendered ).toInclude( "Jane" )
    expect( rendered ).toInclude( "<table" )
} )

it( "should display error messages", () => {
    mockUserService
        .$( "create" )
        .$throw( message = "Email already exists" )

    event = execute(
        event = "users.store",
        eventArguments = { email: "duplicate@test.com" },
        renderResults = true
    )

    rendered = event.getRenderedContent()
    expect( rendered ).toInclude( "Email already exists" )
} )
```

## Testing REST Handlers

### JSON API Testing

```boxlang
describe( "REST API Users Handler", () => {

    it( "should return JSON user list", () => {
        mockUserService.$( "list" ).$results( [
            { id: 1, name: "John" }
        ] )

        event = execute( event = "api.users.index" )

        // Get rendered data
        data = event.getRenderData()

        expect( data.type ).toBe( "JSON" )
        expect( data.statusCode ).toBe( 200 )

        // Parse JSON data
        jsonData = deserializeJSON( data.data )
        expect( jsonData.data ).toBeArray()
        expect( jsonData.data[1].name ).toBe( "John" )
    } )

    it( "should return 404 for missing user", () => {
        mockUserService.$( "find" ).$results( null )

        event = execute(
            event = "api.users.show",
            eventArguments = { id: 999 }
        )

        data = event.getRenderData()
        expect( data.statusCode ).toBe( 404 )
    } )

    it( "should return 201 on successful creation", () => {
        mockUserService.$( "create" ).$results( { id: 1 } )

        event = execute(
            event = "api.users.store",
            eventArguments = { name: "John", email: "john@test.com" }
        )

        data = event.getRenderData()
        expect( data.statusCode ).toBe( 201 )
    } )
} )
```

### Testing REST Error Responses

```boxlang
it( "should return 422 for validation errors", () => {
    event = execute(
        event = "api.users.store",
        eventArguments = { name: "", email: "invalid" }
    )

    data = event.getRenderData()
    expect( data.statusCode ).toBe( 422 )

    jsonData = deserializeJSON( data.data )
    expect( jsonData.errors ).toBeStruct()
} )

it( "should return 500 for server errors", () => {
    mockUserService
        .$( "create" )
        .$throw( type = "DatabaseException" )

    event = execute(
        event = "api.users.store",
        eventArguments = { name: "John" }
    )

    data = event.getRenderData()
    expect( data.statusCode ).toBe( 500 )
} )
```

## Testing Handler Security

### Authentication Testing

```boxlang
describe( "Handler security", () => {

    it( "should allow access for authenticated users", () => {
        // Mock authenticated user
        event = execute( event = "users.index" )
        event.setPrivateValue( "oCurrentUser", { id: 1, name: "Admin" } )

        // Execute protected action
        event = execute( event = "users.create" )

        expect( event.getValue( "relocate_URI", "" ) ).toBeEmpty()
    } )

    it( "should redirect unauthorized users", () => {
        // No authenticated user
        event = execute( event = "users.create" )

        expect( event.getValue( "relocate_URI" ) ).toInclude( "/login" )
    } )
} )
```

### Authorization Testing

```boxlang
describe( "Authorization", () => {

    it( "should allow admin to delete users", () => {
        mockAuthService
            .$( "hasPermission" )
            .$args( "deleteUser" )
            .$results( true )

        mockUserService.$( "delete" ).$results( true )

        event = execute(
            event = "users.delete",
            eventArguments = { id: 1 }
        )

        expect( mockUserService.$once( "delete" ) ).toBeTrue()
    } )

    it( "should deny non-admin delete access", () => {
        mockAuthService
            .$( "hasPermission" )
            .$args( "deleteUser" )
            .$results( false )

        event = execute(
            event = "users.delete",
            eventArguments = { id: 1 }
        )

        // Should redirect or show error
        expect( event.getValue( "relocate_URI" ) ).toInclude( "/unauthorized" )
    } )
} )
```

## Testing Form Validation

### Validation Error Testing

```boxlang
describe( "Form validation", () => {

    it( "should validate required fields", () => {
        event = execute(
            event = "users.store",
            eventArguments = { name: "", email: "" },
            renderResults = true
        )

        rendered = event.getRenderedContent()
        expect( rendered ).toInclude( "Name is required" )
        expect( rendered ).toInclude( "Email is required" )
    } )

    it( "should validate email format", () => {
        event = execute(
            event = "users.store",
            eventArguments = {
                name: "John",
                email: "invalid-email"
            },
            renderResults = true
        )

        rendered = event.getRenderedContent()
        expect( rendered ).toInclude( "Invalid email format" )
    } )

    it( "should pass validation with valid data", () => {
        mockUserService.$( "create" ).$results( { id: 1 } )

        event = execute(
            event = "users.store",
            eventArguments = {
                name: "John Doe",
                email: "john@example.com"
            }
        )

        expect( mockUserService.$once( "create" ) ).toBeTrue()
    } )
} )
```

## Testing Flash Scope

### Flash Message Testing

```boxlang
it( "should set success message in flash", () => {
    mockUserService.$( "create" ).$results( { id: 1 } )

    event = execute(
        event = "users.store",
        eventArguments = { name: "John" }
    )

    flash = getController().getRequestService().getFlashScope()
    expect( flash.exists( "success" ) ).toBeTrue()
    expect( flash.get( "success" ) ).toInclude( "created successfully" )
} )

it( "should set error message in flash", () => {
    mockUserService.$( "create" ).$throw( message = "Error occurred" )

    event = execute(
        event = "users.store",
        eventArguments = { name: "John" }
    )

    flash = getController().getRequestService().getFlashScope()
    expect( flash.exists( "error" ) ).toBeTrue()
} )
```

## Testing with MockBox

### Creating Handler Mocks

```boxlang
describe( "Handler with mocked dependencies", () => {

    beforeEach( () => {
        mockUserService = createMock( "models.UserService" )
        mockMailService = createMock( "models.MailService" )

        // Get handler and inject mocks
        handler = getController()
            .getWireBox()
            .getInstance( "UsersHandler" )

        handler.setUserService( mockUserService )
        handler.setMailService( mockMailService )
    } )

    it( "should send welcome email after user creation", () => {
        mockUserService.$( "create" ).$results( {
            id: 1,
            email: "john@example.com"
        } )

        mockMailService.$( "sendWelcome" )

        event = execute(
            event = "users.store",
            eventArguments = {
                name: "John",
                email: "john@example.com"
            }
        )

        // Verify both service calls
        expect( mockUserService.$once( "create" ) ).toBeTrue()
        expect( mockMailService.$once( "sendWelcome" ) ).toBeTrue()
    } )
} )
```

## Best Practices

### Design Guidelines

1. **Test Behavior**: Focus on handler behavior, not implementation
2. **Mock Dependencies**: Mock services and external dependencies
3. **Test All Actions**: Cover all handler methods
4. **Test HTTP Methods**: Verify GET, POST, PUT, DELETE
5. **Test Redirects**: Verify relocations occur correctly
6. **Test Validations**: Cover validation scenarios
7. **Test Errors**: Include error handling tests
8. **Test Security**: Verify authentication/authorization
9. **Use Descriptive Names**: Clear test descriptions
10. **Isolate Tests**: Each test should be independent

### Common Patterns

```boxlang
// ✅ Good: Test one action per test
it( "should create user", () => {
    // Test create action
} )

it( "should update user", () => {
    // Test update action
} )

// ✅ Good: Clean mock setup
beforeEach( () => {
    mockUserService.$reset()
} )

// ✅ Good: Verify mock interactions
expect( mockUserService.$once( "create" ) ).toBeTrue()
expect( mockUserService.$count( "find" ) ).toBe( 2 )
```

## Common Pitfalls

### Pitfalls to Avoid

1. **Not Resetting Mocks**: Reset mocks between tests
2. **Testing Framework**: Don't test ColdBox features
3. **Missing Event Execution**: Always execute() the event
4. **Not Checking Relocations**: Verify redirects occur
5. **Ignoring Flash Scope**: Test flash messages
6. **No Error Testing**: Include failure scenarios
7. **Hardcoded Data**: Use variables for test data
8. **Not Testing Security**: Include auth/auth tests
9. **Over-Mocking**: Only mock external dependencies
10. **Coupled Tests**: Tests depend on execution order

## Related Skills

- [Unit Testing](testing-unit.md) - Unit testing patterns
- [BDD Testing](testing-bdd.md) - Behavior-driven development
- [Testing Mocking](testing-mocking.md) - Mocking with MockBox
- [Testing Integration](testing-integration.md) - Integration testing
- [Handler Development](../coldbox/handler-development.md) - Building handlers

## References

- [ColdBox Testing](https://coldbox.ortusbooks.com/testing/testing-coldbox-applications)
- [TestBox Documentation](https://testbox.ortusbooks.com/)
- [MockBox Documentation](https://testbox.ortusbooks.com/mocking/mockbox)
