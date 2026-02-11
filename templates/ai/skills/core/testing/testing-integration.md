---
name: Integration Testing
description: Comprehensive guide to integration testing in ColdBox applications, including database integration, API testing, external service integration, and full-stack testing strategies
category: testing
priority: high
triggers:
  - integration test
  - integration testing
  - end-to-end test
  - database test
  - API integration
  - service integration
  - full stack test
---

# Integration Testing

## Overview

Integration testing verifies that multiple components work together correctly. Unlike unit tests that isolate components, integration tests validate interactions between layers such as handlers, services, databases, APIs, and external systems. These tests ensure the application functions properly as a cohesive system.

## Core Concepts

### Integration Test Characteristics

- **Multi-Component**: Tests multiple components working together
- **Real Dependencies**: Uses actual databases, APIs (or test versions)
- **Slower Execution**: Takes longer than unit tests
- **Environment-Specific**: May require specific test environment setup
- **Data State**: Manages test data and database state

### Test Pyramid

```
    /\
   /  \     E2E Tests (Few)
  /----\
 /      \   Integration Tests (Some)
/--------\
\--------/  Unit Tests (Many)
```

## Basic Integration Test Structure

### ColdBox Integration Test

```boxlang
/**
 * UserWorkflowIntegrationSpec.bx
 * Integration tests for user management workflow
 */
component extends="coldbox.system.testing.BaseTestCase" appMapping="/root" {

    /*********************************** LIFE CYCLE Methods ***********************************/

    function beforeAll() {
        super.beforeAll()
        super.setup()

        // Get actual services (no mocking)
        userService = getInstance( "UserService" )
        mailService = getInstance( "MailService" )

        // Setup test database
        setupTestDatabase()
    }

    function afterAll() {
        // Cleanup test data
        cleanupTestDatabase()
        super.afterAll()
    }

    function beforeEach() {
        // Reset database to known state
        resetDatabaseState()
    }

    /*********************************** TEST SUITES ***********************************/

    function run() {
        describe( "User Registration Workflow", () => {

            it( "should complete full registration process", () => {
                // Step 1: Submit registration
                event = execute(
                    event = "users.register",
                    eventArguments = {
                        name: "John Doe",
                        email: "john@example.com",
                        password: "SecurePass123!"
                    }
                )

                // Step 2: Verify user created in database
                user = userService.findByEmail( "john@example.com" )
                expect( user ).notToBeNull()
                expect( user.name ).toBe( "John Doe" )
                expect( user.verified ).toBeFalse()

                // Step 3: Verify welcome email sent
                mailQueue = mailService.getQueue()
                expect( mailQueue ).toHaveLength( 1 )
                expect( mailQueue[1].to ).toBe( "john@example.com" )
                expect( mailQueue[1].subject ).toInclude( "Welcome" )

                // Step 4: Verify redirect to confirmation page
                expect( event.getValue( "relocate_URI" ) ).toInclude( "/users/confirm" )
            } )

            it( "should verify email and activate account", () => {
                // Setup: Create unverified user
                user = userService.create( {
                    name: "John Doe",
                    email: "john@example.com",
                    password: "SecurePass123!",
                    verificationToken: "abc123"
                } )

                // Execute verification
                event = execute(
                    event = "users.verify",
                    eventArguments = { token: "abc123" }
                )

                // Verify account activated
                verifiedUser = userService.find( user.id )
                expect( verifiedUser.verified ).toBeTrue()
                expect( verifiedUser.verificationToken ).toBeNull()

                // Verify can now login
                loginEvent = execute(
                    event = "auth.login",
                    eventArguments = {
                        email: "john@example.com",
                        password: "SecurePass123!"
                    }
                )

                expect( loginEvent.getPrivateValue( "oCurrentUser" ) ).notToBeNull()
            } )
        } )
    }

    /*********************************** HELPER Methods ***********************************/

    private function setupTestDatabase() {
        // Create test database schema
        queryExecute( "
            CREATE TABLE IF NOT EXISTS users (
                id INT AUTO_INCREMENT PRIMARY KEY,
                name VARCHAR(255),
                email VARCHAR(255) UNIQUE,
                password VARCHAR(255),
                verified BOOLEAN DEFAULT 0,
                verificationToken VARCHAR(255),
                createdDate DATETIME
            )
        " )
    }

    private function cleanupTestDatabase() {
        queryExecute( "DROP TABLE IF EXISTS users" )
    }

    private function resetDatabaseState() {
        queryExecute( "TRUNCATE TABLE users" )
    }
}
```

## Database Integration Testing

### Testing with Real Database

```boxlang
describe( "User Service Database Integration", () => {

    beforeEach( () => {
        // Insert test data
        queryExecute( "
            INSERT INTO users (name, email, verified)
            VALUES ('Test User', 'test@example.com', 1)
        " )
    } )

    afterEach( () => {
        // Clean up test data
        queryExecute( "DELETE FROM users WHERE email = 'test@example.com'" )
    } )

    it( "should persist user to database", () => {
        userData = {
            name: "John Doe",
            email: "john@example.com",
            password: "SecurePass123!"
        }

        // Create through service (real database interaction)
        user = userService.create( userData )

        // Verify in database
        result = queryExecute(
            "SELECT * FROM users WHERE id = :id",
            { id: user.id }
        )

        expect( result.recordCount ).toBe( 1 )
        expect( result.name[1] ).toBe( "John Doe" )
        expect( result.email[1] ).toBe( "john@example.com" )
    } )

    it( "should update user in database", () => {
        // Get existing user
        user = userService.findByEmail( "test@example.com" )

        // Update
        user.name = "Updated Name"
        userService.update( user )

        // Verify update persisted
        result = queryExecute(
            "SELECT name FROM users WHERE id = :id",
            { id: user.id }
        )

        expect( result.name[1] ).toBe( "Updated Name" )
    } )

    it( "should delete user from database", () => {
        user = userService.findByEmail( "test@example.com" )

        userService.delete( user.id )

        result = queryExecute(
            "SELECT * FROM users WHERE id = :id",
            { id: user.id }
        )

        expect( result.recordCount ).toBe( 0 )
    } )
} )
```

### Testing Database Transactions

```boxlang
describe( "Transaction handling", () => {

    it( "should rollback on error", () => {
        initialCount = queryExecute( "SELECT COUNT(*) as count FROM users" ).count[1]

        try {
            transaction {
                // Create user
                queryExecute( "
                    INSERT INTO users (name, email)
                    VALUES ('Test', 'test@example.com')
                " )

                // Cause error (duplicate email)
                queryExecute( "
                    INSERT INTO users (name, email)
                    VALUES ('Test2', 'test@example.com')
                " )
            }
        } catch ( any e ) {
            // Expected error
        }

        // Verify no users were created (rolled back)
        finalCount = queryExecute( "SELECT COUNT(*) as count FROM users" ).count[1]
        expect( finalCount ).toBe( initialCount )
    } )

    it( "should commit on success", () => {
        initialCount = queryExecute( "SELECT COUNT(*) as count FROM users" ).count[1]

        transaction {
            queryExecute( "
                INSERT INTO users (name, email)
                VALUES ('Test', 'test1@example.com')
            " )

            queryExecute( "
                INSERT INTO users (name, email)
                VALUES ('Test2', 'test2@example.com')
            " )
        }

        finalCount = queryExecute( "SELECT COUNT(*) as count FROM users" ).count[1]
        expect( finalCount ).toBe( initialCount + 2 )
    } )
} )
```

## API Integration Testing

### Testing External API Integration

```boxlang
describe( "External API Integration", () => {

    beforeAll( () => {
        apiService = getInstance( "ExternalAPIService" )
        // Use test API endpoint
        apiService.setBaseURL( "https://api.test.example.com" )
    } )

    it( "should fetch data from external API", () => {
        result = apiService.getUserData( 123 )

        expect( result ).toBeStruct()
        expect( result ).toHaveKey( "id" )
        expect( result ).toHaveKey( "name" )
        expect( result.id ).toBe( 123 )
    } )

    it( "should handle API errors gracefully", () => {
        // Request non-existent resource
        result = apiService.getUserData( 99999 )

        expect( result.success ).toBeFalse()
        expect( result.error ).toInclude( "Not Found" )
    } )

    it( "should retry on timeout", () => {
        // API service should implement retry logic
        result = apiService.getDataWithRetry( 123 )

        expect( result.success ).toBeTrue()
        expect( result.retries ).toBeGTE( 0 )
    } )
} )
```

### Testing REST API Endpoints

```boxlang
describe( "REST API Endpoints", () => {

    it( "should create resource via POST", () => {
        event = execute(
            event = "api.users.create",
            eventArguments = {
                name: "John Doe",
                email: "john@example.com"
            }
        )

        data = event.getRenderData()
        expect( data.statusCode ).toBe( 201 )

        response = deserializeJSON( data.data )
        expect( response.data.id ).toBeNumeric()

        // Verify in database
        user = userService.find( response.data.id )
        expect( user.name ).toBe( "John Doe" )
    } )

    it( "should retrieve resource via GET", () => {
        // Setup: Create user
        user = userService.create( {
            name: "John Doe",
            email: "john@example.com"
        } )

        // Retrieve via API
        event = execute(
            event = "api.users.show",
            eventArguments = { id: user.id }
        )

        data = event.getRenderData()
        expect( data.statusCode ).toBe( 200 )

        response = deserializeJSON( data.data )
        expect( response.data.name ).toBe( "John Doe" )
    } )

    it( "should update resource via PUT", () => {
        user = userService.create( {
            name: "John Doe",
            email: "john@example.com"
        } )

        event = execute(
            event = "api.users.update",
            eventArguments = {
                id: user.id,
                name: "John Updated"
            }
        )

        data = event.getRenderData()
        expect( data.statusCode ).toBe( 200 )

        // Verify update persisted
        updatedUser = userService.find( user.id )
        expect( updatedUser.name ).toBe( "John Updated" )
    } )

    it( "should delete resource via DELETE", () => {
        user = userService.create( {
            name: "John Doe",
            email: "john@example.com"
        } )

        event = execute(
            event = "api.users.delete",
            eventArguments = { id: user.id }
        )

        data = event.getRenderData()
        expect( data.statusCode ).toBe( 204 )

        // Verify deleted from database
        deletedUser = userService.find( user.id )
        expect( deletedUser ).toBeNull()
    } )
} )
```

## Service Layer Integration

### Testing Service Dependencies

```boxlang
describe( "Order Service Integration", () => {

    beforeAll( () => {
        orderService = getInstance( "OrderService" )
        paymentService = getInstance( "PaymentService" )
        inventoryService = getInstance( "InventoryService" )
        mailService = getInstance( "MailService" )
    } )

    it( "should complete full order workflow", () => {
        // Create customer
        customer = createTestCustomer()

        // Create order
        order = orderService.create( {
            customerId: customer.id,
            items: [
                { productId: 1, quantity: 2, price: 50 },
                { productId: 2, quantity: 1, price: 30 }
            ]
        } )

        expect( order.id ).toBeNumeric()
        expect( order.total ).toBe( 130 )
        expect( order.status ).toBe( "pending" )

        // Process payment
        payment = paymentService.process( order.id, {
            amount: order.total,
            method: "credit_card"
        } )

        expect( payment.success ).toBeTrue()

        // Verify inventory updated
        product1 = inventoryService.getProduct( 1 )
        expect( product1.quantity ).toBeLT( product1.initialQuantity )

        // Verify order status updated
        updatedOrder = orderService.find( order.id )
        expect( updatedOrder.status ).toBe( "paid" )

        // Verify confirmation email sent
        emails = mailService.getQueue()
        confirmationEmail = emails.find( ( e ) => e.to == customer.email )
        expect( confirmationEmail ).notToBeNull()
        expect( confirmationEmail.subject ).toInclude( "Order Confirmation" )
    } )
} )
```

## Cache Integration Testing

### Testing Cache Behavior

```boxlang
describe( "Cache Integration", () => {

    beforeEach( () => {
        cacheService = getInstance( "CacheService" )
        cacheService.clearAll()
    } )

    it( "should cache query results", () => {
        // First call - not cached
        startTime = getTickCount()
        result1 = userService.listUsers()
        duration1 = getTickCount() - startTime

        // Second call - should be cached
        startTime = getTickCount()
        result2 = userService.listUsers()
        duration2 = getTickCount() - startTime

        // Results should be identical
        expect( result1 ).toBe( result2 )

        // Cached call should be faster
        expect( duration2 ).toBeLT( duration1 )
    } )

    it( "should invalidate cache on update", () => {
        // Populate cache
        users = userService.listUsers()

        // Verify cached
        cached = cacheService.get( "userList" )
        expect( cached ).notToBeNull()

        // Update user
        userService.create( {
            name: "New User",
            email: "new@example.com"
        } )

        // Cache should be cleared
        cached = cacheService.get( "userList" )
        expect( cached ).toBeNull()
    } )
} )
```

## File System Integration

### Testing File Operations

```boxlang
describe( "File Upload Integration", () => {

    beforeAll( () => {
        uploadService = getInstance( "UploadService" )
        testUploadDir = expandPath( "/tests/uploads" )

        if ( !directoryExists( testUploadDir ) ) {
            directoryCreate( testUploadDir )
        }
    } )

    afterAll( () => {
        if ( directoryExists( testUploadDir ) ) {
            directoryDelete( testUploadDir, true )
        }
    } )

    it( "should upload and process file", () => {
        // Create test file
        testFile = "#testUploadDir#/test.txt"
        fileWrite( testFile, "Test content" )

        // Upload through service
        result = uploadService.upload( testFile, "documents" )

        expect( result.success ).toBeTrue()
        expect( result.path ).toInclude( "documents" )

        // Verify file exists in destination
        expect( fileExists( result.fullPath ) ).toBeTrue()
    } )
} )
```

## Testing Async Operations

### Testing Background Jobs

```boxlang
describe( "Background Job Integration", () => {

    it( "should process job asynchronously", () => {
        jobService = getInstance( "JobService" )

        // Submit job
        jobId = jobService.submitJob( "processReports", {
            type: "weekly",
            format: "pdf"
        } )

        expect( jobId ).toBeNumeric()

        // Wait for job completion (with timeout)
        timeout = 5000 // 5 seconds
        startTime = getTickCount()

        while ( getTickCount() - startTime < timeout ) {
            job = jobService.getJobStatus( jobId )

            if ( job.status == "completed" ) {
                break
            }

            sleep( 100 )
        }

        // Verify job completed
        job = jobService.getJobStatus( jobId )
        expect( job.status ).toBe( "completed" )
        expect( job.result ).toHaveKey( "reportPath" )
    } )
} )
```

## Environment Configuration

### Test Environment Setup

```boxlang
/**
 * BaseIntegrationTest.bx
 * Base class for integration tests
 */
component extends="coldbox.system.testing.BaseTestCase" {

    function beforeAll() {
        super.beforeAll()

        // Load test environment configuration
        loadTestEnvironment()

        // Setup test database
        setupTestDatabase()

        super.setup()
    }

    function afterAll() {
        cleanupTestDatabase()
        super.afterAll()
    }

    private function loadTestEnvironment() {
        // Set test-specific environment variables
        systemSetEnv( "ENVIRONMENT", "testing" )
        systemSetEnv( "DB_NAME", "test_db" )
        systemSetEnv( "CACHE_ENABLED", "false" )
        systemSetEnv( "MAIL_ENABLED", "false" )
    }

    private function setupTestDatabase() {
        // Run migrations for test database
        getInstance( "MigrationService" ).runMigrations()

        // Seed test data
        getInstance( "SeederService" ).seed( "TestSeeder" )
    }

    private function cleanupTestDatabase() {
        // Rollback all migrations
        getInstance( "MigrationService" ).rollbackAll()
    }
}
```

## Best Practices

### Design Guidelines

1. **Test Real Interactions**: Use actual components, not mocks
2. **Isolate Test Data**: Each test should manage its own data
3. **Clean Up**: Always clean up test data after tests
4. **Use Transactions**: Wrap tests in transactions for automatic rollback
5. **Test State Management**: Verify data persistence
6. **Test Error Scenarios**: Include failure cases
7. **Performance Awareness**: Integration tests are slower
8. **Environment Separation**: Use dedicated test environment
9. **Idempotency**: Tests should be repeatable
10. **Test Dependencies**: Verify component interactions

### Common Patterns

```boxlang
// ✅ Good: Clean database state
beforeEach( () => {
    queryExecute( "DELETE FROM test_users" )
} )

// ✅ Good: Test complete workflow
it( "should complete user registration workflow", () => {
    // Register → Verify Email → Login → Access Protected Resource
} )

// ✅ Good: Verify persistence
it( "should persist changes", () => {
    service.update( id, data )

    // Verify in database
    result = queryExecute( "SELECT * FROM users WHERE id = :id", { id: id } )
    expect( result.recordCount ).toBe( 1 )
} )
```

## Common Pitfalls

### Pitfalls to Avoid

1. **Shared State**: Tests affecting each other
2. **No Cleanup**: Leaving test data in database
3. **External Dependencies**: Tests failing due to external services
4. **Hardcoded IDs**: Using specific database IDs
5. **No Timeouts**: Async tests hanging indefinitely
6. **Production Data**: Running tests against production
7. **Slow Tests**: Not optimizing integration tests
8. **Missing Transactions**: Not using transactions for isolation
9. **Brittle Tests**: Tests break with schema changes
10. **No Error Testing**: Only testing happy paths

### Troubleshooting

```boxlang
// Debug database state
it( "should have correct data", () => {
    result = queryExecute( "SELECT * FROM users" )
    writeDump( var = result, label = "Current Database State" )

    // Add debugging
    expect( result.recordCount ).toBeGT( 0 )
} )

// Add timeout protection
it( "should complete async operation", () => {
    startTime = getTickCount()
    timeout = 5000

    while ( !isComplete() && ( getTickCount() - startTime < timeout ) ) {
        sleep( 100 )
    }

    expect( isComplete() ).toBeTrue( "Operation timed out" )
} )
```

## Related Skills

- [Unit Testing](testing-unit.md) - Unit test patterns
- [Testing Handlers](testing-handler.md) - Handler testing
- [Testing Mocking](testing-mocking.md) - Mocking dependencies
- [Testing Fixtures](testing-fixtures.md) - Test data management

## References

- [ColdBox Testing](https://coldbox.ortusbooks.com/testing/testing-coldbox-applications)
- [TestBox Documentation](https://testbox.ortusbooks.com/)
- [Database Testing Patterns](https://testbox.ortusbooks.com/primers/integration-testing)
