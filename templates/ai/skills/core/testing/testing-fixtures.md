---
name: Testing Fixtures
description: Comprehensive guide to test data management including fixtures, factories, seeders, and data builders for consistent and maintainable test data
category: testing
priority: medium
triggers:
  - test data
  - fixtures
  - factory
  - seeder
  - test builder
  - data setup
---

# Testing Fixtures

## Overview

Test fixtures are the known, fixed state used as a baseline for running tests. They include test data, database records, mock objects, and any other dependencies needed for tests. Proper fixture management ensures tests are consistent, maintainable, and isolated from each other.

## Core Concepts

### Types of Fixtures

- **Static Fixtures**: Hardcoded test data
- **Factory Fixtures**: Dynamically generated test data
- **Database Fixtures**: Pre-populated database records
- **File Fixtures**: Sample files for testing
- **Mock Fixtures**: Pre-configured mock objects

### Fixture Principles

1. **Isolation**: Each test should have its own data
2. **Consistency**: Same data produces same results
3. **Clarity**: Data should be obvious and readable
4. **Minimal**: Only include necessary data
5. **Realistic**: Mimic production data patterns

## Static Fixtures

### Inline Test Data

```boxlang
describe( "User validation", () => {

    it( "should validate valid user data", () => {
        // Inline fixture
        validUser = {
            name: "John Doe",
            email: "john@example.com",
            age: 30,
            active: true
        }

        result = userValidator.validate( validUser )
        expect( result.isValid ).toBeTrue()
    } )

    it( "should reject invalid email", () => {
        invalidUser = {
            name: "John Doe",
            email: "not-an-email",
            age: 30
        }

        result = userValidator.validate( invalidUser )
        expect( result.isValid ).toBeFalse()
        expect( result.errors ).toHaveKey( "email" )
    } )
} )
```

### Shared Fixtures

```boxlang
describe( "User operations", () => {

    // Shared fixture
    variables.validUserData = {
        name: "John Doe",
        email: "john@example.com",
        password: "SecurePass123!",
        age: 30
    }

    beforeEach( () => {
        // Create fresh copy for each test
        variables.testUser = duplicate( validUserData )
    } )

    it( "should create user with valid data", () => {
        user = userService.create( testUser )
        expect( user.id ).toBeNumeric()
    } )

    it( "should update user", () => {
        user = userService.create( testUser )

        testUser.name = "Jane Doe"
        updated = userService.update( user.id, testUser )

        expect( updated.name ).toBe( "Jane Doe" )
    } )
} )
```

### Fixture Files

```boxlang
/**
 * UserFixtures.cfc
 * Centralized user test data
 */
component {

    function getValidUser() {
        return {
            name: "John Doe",
            email: "john@example.com",
            password: "SecurePass123!",
            age: 30,
            active: true
        }
    }

    function getInvalidUsers() {
        return [
            {
                name: "",  // Empty name
                email: "john@example.com",
                error: "name"
            },
            {
                name: "John Doe",
                email: "invalid-email",  // Invalid email
                error: "email"
            },
            {
                name: "John Doe",
                email: "john@example.com",
                age: -5,  // Invalid age
                error: "age"
            }
        ]
    }

    function getUsers( count = 5 ) {
        users = []

        for ( i = 1; i <= count; i++ ) {
            users.append( {
                name: "User ##i##",
                email: "user##i##@example.com",
                age: 25 + i
            } )
        }

        return users
    }
}
```

Using fixture files:

```boxlang
describe( "User service", () => {

    beforeAll( () => {
        fixtures = createObject( "tests.fixtures.UserFixtures" )
    } )

    it( "should create user", () => {
        userData = fixtures.getValidUser()
        user = userService.create( userData )

        expect( user.id ).toBeNumeric()
        expect( user.name ).toBe( userData.name )
    } )

    it( "should validate multiple invalid users", () => {
        invalidUsers = fixtures.getInvalidUsers()

        for ( invalidUser in invalidUsers ) {
            result = userValidator.validate( invalidUser )

            expect( result.isValid ).toBeFalse()
            expect( result.errors ).toHaveKey( invalidUser.error )
        }
    } )
} )
```

## Factory Pattern

### Basic Factory

```boxlang
/**
 * UserFactory.cfc
 * Factory for creating test users
 */
component {

    variables.counter = 0

    function create( overrides = {} ) {
        counter++

        defaults = {
            name: "Test User ##counter##",
            email: "user##counter##@example.com",
            password: "Password##counter##!",
            age: 25 + counter,
            active: true,
            createdDate: now()
        }

        // Merge overrides with defaults
        return structAppend( defaults, overrides, true )
    }

    function createMany( count = 5, overrides = {} ) {
        users = []

        for ( i = 1; i <= count; i++ ) {
            users.append( create( overrides ) )
        }

        return users
    }

    function createInactive( overrides = {} ) {
        overrides.active = false
        return create( overrides )
    }

    function createAdmin( overrides = {} ) {
        overrides.role = "admin"
        overrides.permissions = [ "read", "write", "delete" ]
        return create( overrides )
    }
}
```

Using factories:

```boxlang
describe( "User operations with factory", () => {

    beforeAll( () => {
        userFactory = createObject( "tests.factories.UserFactory" )
    } )

    it( "should create multiple users", () => {
        users = userFactory.createMany( 3 )

        expect( users ).toHaveLength( 3 )
        expect( users[1].email ).toInclude( "user" )
        expect( users[2].email ).toInclude( "user" )
    } )

    it( "should override factory defaults", () => {
        user = userFactory.create( {
            name: "Custom Name",
            age: 50
        } )

        expect( user.name ).toBe( "Custom Name" )
        expect( user.age ).toBe( 50 )
        expect( user.email ).toInclude( "user" )  // Still generated
    } )

    it( "should create admin user", () => {
        admin = userFactory.createAdmin()

        expect( admin.role ).toBe( "admin" )
        expect( admin.permissions ).toHaveLength( 3 )
    } )
} )
```

### Advanced Factory

```boxlang
/**
 * ModelFactory.cfc
 * Generic factory with traits and relationships
 */
component {

    variables.sequences = {}

    function init() {
        reset()
        return this
    }

    function reset() {
        sequences = {}
    }

    function sequence( key, prefix = "" ) {
        if ( !sequences.keyExists( key ) ) {
            sequences[key] = 0
        }

        sequences[key]++

        return prefix & sequences[key]
    }

    function createUser( overrides = {} ) {
        return structAppend( {
            name: "User " & sequence( "user" ),
            email: "user" & sequence( "email" ) & "@example.com",
            password: "Password123!",
            active: true
        }, overrides, true )
    }

    function createPost( overrides = {} ) {
        // Ensure user exists
        if ( !overrides.keyExists( "userId" ) ) {
            user = persistUser( createUser() )
            overrides.userId = user.id
        }

        return structAppend( {
            title: "Post " & sequence( "post" ),
            content: "This is test content for post " & sequence( "post" ),
            userId: overrides.userId,
            published: true,
            publishedDate: now()
        }, overrides, true )
    }

    function createComment( overrides = {} ) {
        // Ensure post and user exist
        if ( !overrides.keyExists( "postId" ) ) {
            post = persistPost( createPost() )
            overrides.postId = post.id
        }

        if ( !overrides.keyExists( "userId" ) ) {
            user = persistUser( createUser() )
            overrides.userId = user.id
        }

        return structAppend( {
            content: "Comment " & sequence( "comment" ),
            postId: overrides.postId,
            userId: overrides.userId,
            createdDate: now()
        }, overrides, true )
    }

    function persistUser( data ) {
        return getUserService().create( data )
    }

    function persistPost( data ) {
        return getPostService().create( data )
    }

    function persistComment( data ) {
        return getCommentService().create( data )
    }

    private function getUserService() {
        return getInstance( "UserService" )
    }

    private function getPostService() {
        return getInstance( "PostService" )
    }

    private function getCommentService() {
        return getInstance( "CommentService" )
    }
}
```

## Database Fixtures

### Migration-Based Fixtures

```boxlang
/**
 * BaseIntegrationTest.cfc
 * Base class with database fixtures
 */
component extends="coldbox.system.testing.BaseTestCase" {

    function beforeAll() {
        super.beforeAll()
        super.setup()

        // Run migrations
        migrationService = getInstance( "MigrationService" )
        migrationService.up()

        // Seed test data
        seedTestData()
    }

    function afterAll() {
        // Rollback migrations
        migrationService = getInstance( "MigrationService" )
        migrationService.down()

        super.afterAll()
    }

    function beforeEach() {
        // Clean tables before each test
        queryExecute( "DELETE FROM comments" )
        queryExecute( "DELETE FROM posts" )
        queryExecute( "DELETE FROM users" )

        // Re-seed if needed
        seedMinimalData()
    }

    private function seedTestData() {
        // Create base users
        queryExecute( "
            INSERT INTO users (name, email, active)
            VALUES
                ('Admin User', 'admin@example.com', 1),
                ('Test User', 'test@example.com', 1)
        " )

        // Create base posts
        queryExecute( "
            INSERT INTO posts (title, content, userId)
            VALUES
                ('Test Post 1', 'Content 1', 1),
                ('Test Post 2', 'Content 2', 2)
        " )
    }

    private function seedMinimalData() {
        // Minimal data for each test
        queryExecute( "
            INSERT INTO users (id, name, email, active)
            VALUES (1, 'Test User', 'test@example.com', 1)
        " )
    }
}
```

### Seeder Classes

```boxlang
/**
 * TestUserSeeder.cfc
 * Seeds users for testing
 */
component {

    function run() {
        users = [
            {
                name: "Admin User",
                email: "admin@example.com",
                role: "admin",
                active: true
            },
            {
                name: "Regular User",
                email: "user@example.com",
                role: "user",
                active: true
            },
            {
                name: "Inactive User",
                email: "inactive@example.com",
                role: "user",
                active: false
            }
        ]

        for ( userData in users ) {
            queryExecute( "
                INSERT INTO users (name, email, role, active)
                VALUES (:name, :email, :role, :active)
            ", userData )
        }
    }
}
```

## File Fixtures

### Sample Files

```boxlang
describe( "File upload processing", () => {

    beforeAll( () => {
        // Create test files directory
        fixturesDir = expandPath( "/tests/fixtures/files" )

        if ( !directoryExists( fixturesDir ) ) {
            directoryCreate( fixturesDir )
        }

        createTestFiles()
    } )

    afterAll( () => {
        // Clean up test files
        if ( directoryExists( fixturesDir ) ) {
            directoryDelete( fixturesDir, true )
        }
    } )

    it( "should process CSV file", () => {
        csvFile = expandPath( "/tests/fixtures/files/users.csv" )

        result = fileProcessor.processCSV( csvFile )

        expect( result.recordCount ).toBe( 5 )
    } )

    private function createTestFiles() {
        // Create sample CSV
        csvContent = "name,email,age#chr(10)#"
        csvContent &= "John Doe,john@example.com,30#chr(10)#"
        csvContent &= "Jane Smith,jane@example.com,25"

        fileWrite(
            expandPath( "/tests/fixtures/files/users.csv" ),
            csvContent
        )

        // Create sample JSON
        jsonContent = serializeJSON( [
            { name: "User 1", email: "user1@example.com" },
            { name: "User 2", email: "user2@example.com" }
        ] )

        fileWrite(
            expandPath( "/tests/fixtures/files/users.json" ),
            jsonContent
        )
    }
} )
```

## Builder Pattern

### Test Data Builders

```boxlang
/**
 * UserBuilder.cfc
 * Builder pattern for creating test users
 */
component {

    variables.data = {}
    variables.counter = 0

    function init() {
        reset()
        return this
    }

    function reset() {
        counter++
        data = {
            name: "User ##counter##",
            email: "user##counter##@example.com",
            password: "Password##counter##!",
            age: 25,
            active: true
        }
        return this
    }

    function withName( name ) {
        data.name = name
        return this
    }

    function withEmail( email ) {
        data.email = email
        return this
    }

    function withAge( age ) {
        data.age = age
        return this
    }

    function inactive() {
        data.active = false
        return this
    }

    function asAdmin() {
        data.role = "admin"
        data.permissions = [ "read", "write", "delete" ]
        return this
    }

    function build() {
        return duplicate( data )
    }

    function create() {
        user = build()
        return getUserService().create( user )
    }

    private function getUserService() {
        return getInstance( "UserService" )
    }
}
```

Using builders:

```boxlang
describe( "User builder", () => {

    beforeAll( () => {
        userBuilder = createObject( "tests.builders.UserBuilder" )
    } )

    beforeEach( () => {
        userBuilder.reset()
    } )

    it( "should build user with defaults", () => {
        user = userBuilder.build()

        expect( user ).toHaveKey( "name" )
        expect( user ).toHaveKey( "email" )
        expect( user.active ).toBeTrue()
    } )

    it( "should build custom user", () => {
        user = userBuilder
            .withName( "John Doe" )
            .withAge( 40 )
            .inactive()
            .build()

        expect( user.name ).toBe( "John Doe" )
        expect( user.age ).toBe( 40 )
        expect( user.active ).toBeFalse()
    } )

    it( "should create and persist admin user", () => {
        admin = userBuilder
            .withName( "Admin User" )
            .asAdmin()
            .create()  // Persists to database

        expect( admin.id ).toBeNumeric()
        expect( admin.role ).toBe( "admin" )
    } )
} )
```

## Best Practices

### Design Guidelines

1. **DRY Fixtures**: Reuse fixture code across tests
2. **Minimal Data**: Include only necessary fields
3. **Clear Names**: Use descriptive fixture names
4. **Isolation**: Each test gets fresh data
5. **Factories Over Fixtures**: Prefer dynamic generation
6. **Readable Data**: Make fixture data obvious
7. **Version Control**: Commit fixture files
8. **Documentation**: Document complex fixtures
9. **Cleanup**: Always clean up after tests
10. **Realistic Data**: Mimic production patterns

### Common Patterns

```boxlang
// ✅ Good: Factory with overrides
user = userFactory.create( {
    email: "specific@example.com"
} )

// ✅ Good: Builder pattern
user = userBuilder
    .withName( "John Doe" )
    .asAdmin()
    .create()

// ✅ Good: Descriptive fixture method
function getValidCreditCard() {
    return {
        number: "4242424242424242",
        exp: "12/25",
        cvv: "123"
    }
}

// ✅ Good: Reset between tests
beforeEach( () => {
    factory.reset()
    cleanDatabase()
} )
```

## Common Pitfalls

### Pitfalls to Avoid

1. **Shared Mutable State**: Tests affecting each other
2. **Large Fixtures**: Too much unnecessary data
3. **Hardcoded IDs**: Relying on specific database IDs
4. **No Cleanup**: Leaving test data behind
5. **Complex Dependencies**: Fixtures depending on fixtures
6. **Inconsistent Data**: Different data in different tests
7. **Brittle Fixtures**: Breaking with schema changes
8. **No Documentation**: Unclear fixture purpose
9. **Production Data**: Using real production data
10. **Copy-Paste**: Duplicating fixture code

### Anti-Patterns

```boxlang
// ❌ Bad: Shared mutable fixture
variables.sharedUser = { name: "John" }

it( "test 1", () => {
    sharedUser.age = 30  // Mutates shared state
} )

it( "test 2", () => {
    expect( sharedUser.age ).toBeUndefined()  // May fail!
} )

// ✅ Good: Fresh copy per test
beforeEach( () => {
    variables.testUser = duplicate( baseUser )
} )

// ❌ Bad: Hardcoded database ID
it( "should find user", () => {
    user = userService.find( 123 )  // Assumes ID 123 exists
} )

// ✅ Good: Create user, use returned ID
it( "should find user", () => {
    created = userService.create( userData )
    user = userService.find( created.id )
} )

// ❌ Bad: Huge fixture
function getMassiveUser() {
    return {
        name: "John",
        email: "john@example.com",
        // 50 more fields...
    }
}

// ✅ Good: Minimal fixture
function getMinimalUser() {
    return {
        name: "John",
        email: "john@example.com"
    }
}
```

## Testing the Fixtures

### Fixture Validation

```boxlang
describe( "UserFactory", () => {

    it( "should create unique users", () => {
        user1 = userFactory.create()
        user2 = userFactory.create()

        expect( user1.email ).notToBe( user2.email )
    } )

    it( "should respect overrides", () => {
        user = userFactory.create( {
            name: "Custom",
            age: 99
        } )

        expect( user.name ).toBe( "Custom" )
        expect( user.age ).toBe( 99 )
    } )
} )
```

## Related Skills

- [Unit Testing](testing-unit.md) - Unit test fundamentals
- [Integration Testing](testing-integration.md) - Integration patterns
- [Testing Mocking](testing-mocking.md) - Mocking strategies
- [Testing BDD](testing-bdd.md) - BDD patterns

## References

- [Test Fixture Patterns](https://martinfowler.com/bliki/TestFixture.html)
- [Object Mother Pattern](https://martinfowler.com/bliki/ObjectMother.html)
- [Test Data Builders](https://www.natpryce.com/articles/000714.html)
