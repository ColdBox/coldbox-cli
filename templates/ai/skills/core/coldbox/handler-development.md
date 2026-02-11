---
name: handler-development
description: Implementation patterns for ColdBox handler development including CRUD operations, dependency injection, and event handling
category: coldbox
priority: high
triggers:
  - create handler
  - build handler
  - implement handler
  - controller patterns
---

# Handler Development Implementation Pattern

## When to Use This Skill

Use this skill when creating ColdBox handlers (controllers) for handling HTTP requests, implementing CRUD operations, or building web interfaces.

## Core Concepts

Handlers are ColdBox's controllers that:
- Handle HTTP requests and orchestrate application flow
- Receive the event object, request collection (rc), and private request collection (prc)
- Use dependency injection for services and models
- Return views or data responses
- Can be secured with security annotations

## Implementation Steps

1. Define handler name and actions
2. Add dependency injection for required services
3. Implement actions with event, rc, prc parameters
4. Process request data and delegate to services
5. Populate prc with view data or use event.renderData() for APIs
6. Add security annotations if needed
7. Write handler tests

## Basic Handler Template (BoxLang)

```boxlang
class Users extends coldbox.system.EventHandler {

    @inject
    property name="userService";

    @inject
    property name="validationManager";

    /**
     * Display list of users
     */
    function index( event, rc, prc ) {
        prc.users = userService.list(
            page = rc.page ?: 1,
            limit = rc.limit ?: 25
        )
        event.setView( "users/index" )
    }

    /**
     * Display single user
     */
    function show( event, rc, prc ) {
        prc.user = userService.getById( rc.id ?: 0 )
        event.setView( "users/show" )
    }

    /**
     * Display create form
     */
    function create( event, rc, prc ) {
        prc.user = userService.new()
        event.setView( "users/create" )
    }

    /**
     * Store new user
     */
    function store( event, rc, prc ) {
        var result = userService.create( rc )

        if( result.hasErrors() ){
            flash.put( "errors", result.getErrors() )
            flash.put( "data", rc )
            relocate( "users.create" )
        }

        flash.put( "success", "User created successfully" )
        relocate( uri = "/users/#result.getId()#" )
    }

    /**
     * Display edit form
     */
    function edit( event, rc, prc ) {
        prc.user = userService.getById( rc.id ?: 0 )
        event.setView( "users/edit" )
    }

    /**
     * Update existing user
     */
    function update( event, rc, prc ) {
        var result = userService.update( rc.id ?: 0, rc )

        if( result.hasErrors() ){
            flash.put( "errors", result.getErrors() )
            flash.put( "data", rc )
            relocate( "users.edit", { id: rc.id } )
        }

        flash.put( "success", "User updated successfully" )
        relocate( uri = "/users/#rc.id#" )
    }

    /**
     * Delete user
     */
    function delete( event, rc, prc ) {
        userService.delete( rc.id ?: 0 )
        flash.put( "success", "User deleted successfully" )
        relocate( "users.index" )
    }
}
```

## Handler with Validation (BoxLang)

```boxlang
class Users extends coldbox.system.EventHandler {

    @inject
    property name="userService";

    @inject
    property name="validationManager";

    function store( event, rc, prc ) {
        // Define validation constraints
        var constraints = {
            "firstName": { required: true, type: "string", min: 2 },
            "lastName": { required: true, type: "string", min: 2 },
            "email": { required: true, type: "email" },
            "password": { required: true, type: "string", min: 8 }
        }

        // Validate input
        var validationResult = validationManager.validate(
            target = rc,
            constraints = constraints
        )

        if( validationResult.hasErrors() ){
            flash.put( "errors", validationResult.getAllErrors() )
            flash.put( "data", rc )
            relocate( "users.create" )
        }

        // Create user
        var user = userService.create( rc )
        flash.put( "success", "User created successfully" )
        relocate( uri = "/users/#user.getId()#" )
    }
}
```

## Secured Handler (BoxLang)

```boxlang
class Admin extends coldbox.system.EventHandler {

    // Secure entire handler - requires authentication
    this.preHandler = "checkAuth"

    @inject
    property name="userService";

    /**
     * Check authentication before any action
     */
    private function checkAuth( event, rc, prc, action ) {
        if( !auth().check() ){
            flash.put( "error", "Please login to continue" )
            relocate( "security.login" )
        }

        if( !auth().user().hasRole( "admin" ) ){
            flash.put( "error", "Insufficient permissions" )
            relocate( "main.index" )
        }
    }

    function index( event, rc, prc ) {
        prc.users = userService.list()
        event.setView( "admin/index" )
    }

    // Using security annotations (requires CBSecurity)
    @secured
    @permissions( "admin.users.delete" )
    function delete( event, rc, prc ) {
        userService.delete( rc.id ?: 0 )
        flash.put( "success", "User deleted" )
        relocate( "admin.index" )
    }
}
```

## REST Handler (BoxLang)

```boxlang
class api_Users extends coldbox.system.RestHandler {

    @inject
    property name="userService";

    function index( event, rc, prc ) {
        var users = userService.list(
            page = rc.page ?: 1,
            limit = rc.limit ?: 25
        )

        event.renderData(
            data = users,
            statusCode = 200
        )
    }

    function show( event, rc, prc ) {
        var user = userService.getById( rc.id ?: 0 )

        if( isNull( user ) ){
            event.renderData(
                data = { "error": "User not found" },
                statusCode = 404
            )
            return
        }

        event.renderData(
            data = user,
            statusCode = 200
        )
    }

    function create( event, rc, prc ) {
        var result = userService.create( rc )

        if( result.hasErrors() ){
            event.renderData(
                data = { "errors": result.getErrors() },
                statusCode = 422
            )
            return
        }

        event.renderData(
            data = result,
            statusCode = 201
        )
    }

    function update( event, rc, prc ) {
        var result = userService.update( rc.id ?: 0, rc )

        if( result.hasErrors() ){
            event.renderData(
                data = { "errors": result.getErrors() },
                statusCode = 422
            )
            return
        }

        event.renderData(
            data = result,
            statusCode = 200
        )
    }

    function delete( event, rc, prc ) {
        userService.delete( rc.id ?: 0 )

        event.renderData(
            data = { "message": "User deleted successfully" },
            statusCode = 204
        )
    }
}
```

## Handler with Around Advices (BoxLang)

```boxlang
class Products extends coldbox.system.EventHandler {

    // Run before ALL actions
    this.preHandler = "setupDefaults"

    // Run after ALL actions
    this.postHandler = "logActivity"

    // Run around specific actions
    this.aroundHandler_only = {
        actions: "create,update,delete",
        handler: "transactionWrapper"
    }

    @inject
    property name="productService";

    private function setupDefaults( event, rc, prc, action ) {
        prc.pageTitle = "Products"
        prc.breadcrumbs = []
    }

    private function logActivity( event, rc, prc, action ) {
        log.info( "Executed action: #action#" )
    }

    private function transactionWrapper( event, rc, prc, targetAction ) {
        transaction {
            try {
                // Execute the target action
                arguments.targetAction( event, rc, prc )
                transactionCommit()
            } catch( any e ){
                transactionRollback()
                rethrow
            }
        }
    }

    function index( event, rc, prc ) {
        prc.products = productService.list()
        event.setView( "products/index" )
    }

    function create( event, rc, prc ) {
        var product = productService.create( rc )
        flash.put( "success", "Product created" )
        relocate( uri = "/products/#product.getId()#" )
    }
}
```

## Best Practices

1. **Keep Handlers Thin**: Delegate business logic to services
2. **Use Dependency Injection**: Inject services, not direct instantiation
3. **Validate All Input**: Use CBValidation or manual validation
4. **Use prc for Views**: Set view data in prc, not rc
5. **Use rc for Forms**: Request data comes from rc
6. **Return Proper Status Codes**: Use appropriate HTTP status codes
7. **Flash Messages**: Use flash scope for user feedback
8. **Security First**: Add authentication/authorization checks
9. **Error Handling**: Always handle errors gracefully
10. **Method Documentation**: Document what each action does

## Common Pitfalls

1. **Business Logic in Handlers**: Move complex logic to services
2. **Not Validating Input**: Always validate user input
3. **Direct Database Calls**: Use services/models, not raw queries
4. **Missing Error Handling**: Always catch and handle errors
5. **Wrong HTTP Methods**: Use proper HTTP verbs (GET, POST, PUT, DELETE)
6. **Not Using Flash Scope**: Flash messages get lost without flash scope
7. **Security Bypass**: Don't skip authentication/authorization checks
8. **Large Action Methods**: Break complex actions into smaller methods
9. **Not Testing**: Write tests for all handler actions

## Event Object Methods

```boxlang
// View rendering
event.setView( "users/index" )
event.setLayout( "Main" )

// Data rendering (REST)
event.renderData( data = myData, statusCode = 200 )

// Redirects
relocate( "users.index" )
relocate( uri = "/users/5" )

// Request data
var user = event.getValue( "user", {} )
var id = event.getValue( "id", 0 )

// Private request collection
prc.user = userService.getById( id )

// Current route
var route = event.getCurrentRoute()
var routedURL = event.getCurrentRoutedURL()

// HTTP method
var method = event.getHTTPMethod()

// Headers
event.setHTTPHeader( name = "X-Custom", value = "value" )
```

## Integration Points

### With Services

```boxlang
class Users extends coldbox.system.EventHandler {
    @inject
    property name="userService";

    function index( event, rc, prc ) {
        prc.users = userService.list()
        event.setView( "users/index" )
    }
}
```

### With Validation

```boxlang
@inject
property name="validationManager";

function store( event, rc, prc ) {
    var result = validationManager.validate(
        target = rc,
        constraints = {
            email: { required: true, type: "email" }
        }
    )

    if( result.hasErrors() ){
        // Handle errors
    }
}
```

### With Security

```boxlang
@secured
@permissions( "users.delete" )
function delete( event, rc, prc ) {
    userService.delete( rc.id )
    relocate( "users.index" )
}
```

## Testing Handlers

```boxlang
class UsersTest extends coldbox.system.testing.BaseTestCase {

    function beforeAll() {
        super.beforeAll()
        setup()
    }

    function run() {
        describe( "Users Handler", function(){

            it( "should display user list", function(){
                var event = execute( event = "users.index", renderResults = true )
                expect( event.getRenderedContent() ).toInclude( "Users" )
            })

            it( "should create new user", function(){
                var event = execute(
                    event = "users.store",
                    eventArguments = {
                        firstName = "John",
                        lastName = "Doe",
                        email = "john@example.com"
                    }
                )
                expect( event.getValue( "relocate_URI", "" ) ).toInclude( "/users/" )
            })

            it( "should validate user input", function(){
                var event = execute(
                    event = "users.store",
                    eventArguments = {
                        firstName = "John"
                        // Missing required fields
                    }
                )
                expect( flash.get( "errors" ) ).notToBeEmpty()
            })
        })
    }
}
```

## Related Skills

- `rest-api-development` - Building REST APIs
- `routing-development` - Route configuration
- `event-model` - Event-driven architecture
- `testing-handler` - Testing patterns
- `security-implementation` - Security patterns
- `view-rendering` - View patterns
- `interceptor-development` - Interceptor patterns
