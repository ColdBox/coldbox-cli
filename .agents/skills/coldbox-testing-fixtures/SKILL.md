---
name: coldbox-testing-fixtures
description: "Use this skill when creating test fixtures, factory patterns, or test data builders in ColdBox/TestBox, setting up shared fixture files, creating user/model factories with overrides, using cbMockData for realistic fake data generation, or managing test data setup and teardown."
---

# Testing Fixtures in ColdBox

## Overview

Test fixtures provide the known, fixed state needed to run tests. They include static test data, factory classes that generate dynamic data, and fixture files for shared data across tests. Good fixture management keeps tests isolated, readable, and maintainable.

## Language Mode Reference

Examples use **BoxLang (`.bx`)** syntax by default. Adapt for your target language:

| Concept | BoxLang (`.bx`) | CFML (`.cfc`) |
|---------|-----------------|---------------|
| Class declaration | `class [extends="..."] {` | `component [extends="..."] {` |
| DI annotation | `@inject` above `property name="svc";` | `property name="svc" inject="svc";` |
| View templates | `.bxm` suffix | `.cfm` / `.cfml` suffix |
| Tag prefix | `<bx:if>`, `<bx:output>`, `<bx:set>` | `<cfif>`, `<cfoutput>`, `<cfset>` |

> **CFML Compat Mode**: With BoxLang + CFML Compat module, `.bx` and `.cfc` files coexist freely. BoxLang-native classes use `class {}` (`.bx` files); CFML-compat classes use `component {}` (`.cfc` files).

## Static Inline Fixtures

```boxlang
describe( "User validation", () => {

    it( "should validate valid user data", () => {
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

## Shared Fixture Variables

```boxlang
describe( "User operations", () => {

    // Define shared test data at describe scope
    variables.validUserData = {
        name: "John Doe",
        email: "john@example.com",
        password: "SecurePass123!",
        age: 30
    }

    beforeEach( () => {
        // Create a fresh copy for each test to prevent mutation
        variables.testUser = duplicate( validUserData )
    } )

    it( "should create user with valid data", () => {
        user = userService.create( testUser )
        expect( user.id ).toBeNumeric()
    } )

    it( "should update user name", () => {
        user = userService.create( testUser )
        testUser.name = "Jane Doe"

        updated = userService.update( user.id, testUser )
        expect( updated.name ).toBe( "Jane Doe" )
    } )
} )
```

## Fixture File Pattern

```boxlang
/**
 * tests/fixtures/UserFixtures.cfc
 * Centralized test data for user-related tests
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

    function getAdminUser() {
        return getValidUser().append( {
            email: "admin@example.com",
            role: "admin",
            permissions: [ "read", "write", "delete" ]
        }, true )
    }

    function getInvalidUsers() {
        return [
            { name: "", email: "john@example.com", _errorField: "name" },
            { name: "John", email: "invalid-email", _errorField: "email" },
            { name: "John", email: "john@example.com", age: -5, _errorField: "age" }
        ]
    }

    function getUsers( required numeric count = 5 ) {
        users = []

        for ( i = 1; i <= count; i++ ) {
            users.append( {
                name: "User ##i##",
                email: "user##i##@example.com",
                age: 20 + i
            } )
        }

        return users
    }
}
```

Using fixture file:

```boxlang
component extends="testbox.system.BaseSpec" {

    function run() {
        describe( "User service with fixture file", () => {

            beforeAll( () => {
                variables.fixtures    = new tests.fixtures.UserFixtures()
                variables.userService = getInstance( "UserService" )
            } )

            it( "should create valid user", () => {
                userData = fixtures.getValidUser()
                user     = userService.create( userData )

                expect( user.id ).toBeNumeric()
                expect( user.name ).toBe( userData.name )
            } )

            it( "should reject all invalid formats", () => {
                for ( invalidUser in fixtures.getInvalidUsers() ) {
                    result = userService.validate( invalidUser )
                    expect( result.isValid ).toBeFalse()
                    expect( result.errors ).toHaveKey( invalidUser._errorField )
                }
            } )
        } )
    }
}
```

## Factory Pattern

```boxlang
/**
 * tests/factories/UserFactory.cfc
 * Dynamic test data factory with sequence counter
 */
component singleton {

    variables.counter = 0

    function create( struct overrides = {} ) {
        variables.counter++

        defaults = {
            name:        "Test User ##counter##",
            email:       "testuser##counter##@example.com",
            password:    "Password##counter##!",
            age:         20 + counter,
            active:      true,
            createdDate: now()
        }

        return structAppend( defaults, overrides, true )
    }

    function createMany( required numeric count, struct overrides = {} ) {
        return listToArray( repeatString( ",", count - 1 ) )
            .map( () => create( overrides ) )
    }

    function createAdmin( struct overrides = {} ) {
        return create( {
            role: "admin",
            permissions: [ "read", "write", "delete" ]
        }.append( overrides, true ) )
    }

    function createInactive( struct overrides = {} ) {
        return create( { active: false }.append( overrides, true ) )
    }

    function reset() {
        variables.counter = 0
    }
}
```

Using factory:

```boxlang
component extends="testbox.system.BaseSpec" {

    function run() {
        describe( "With factory", () => {

            beforeAll( () => {
                variables.factory     = new tests.factories.UserFactory()
                variables.userService = getInstance( "UserService" )
            } )

            beforeEach( () => {
                factory.reset()
            } )

            it( "should process multiple users", () => {
                // Create 3 test users
                users = factory.createMany( 3 )
                    .map( u => userService.create( u ) )

                expect( users ).toHaveLength( 3 )
                expect( users[1].name ).toBe( "Test User 1" )
            } )

            it( "should grant admin privileges", () => {
                admin = factory.createAdmin( { email: "customadmin@test.com" } )
                user  = userService.create( admin )

                expect( user.role ).toBe( "admin" )
            } )
        } )
    }
}
```

## Using cbMockData for Realistic Fake Data

> For the full cbMockData type reference, see the `testbox-cbmockdata` skill.

**WireBox ID**: `MockData@cbMockData`

cbMockData is bundled with TestBox — no separate install required.

```boxlang
component extends="testbox.system.BaseSpec" {

    property name="mockData" inject="MockData@cbMockData"

    function run() {
        describe( "With cbMockData", () => {

            it( "should generate a realistic user", () => {
                var userData = mockData.mock(
                    $returnType: "struct",
                    firstName:   "fname",
                    lastName:    "lname",
                    email:       "email",
                    age:         "age",
                    bio:         "sentence"
                )

                expect( userData.firstName ).toBeString()
                expect( userData.email ).toMatch( ".+@.+" )
                expect( userData.age ).toBeNumeric()
            } )

            it( "should generate a collection of users", () => {
                var users = mockData.mock(
                    $num:   10,
                    id:     "autoincrement",
                    name:   "name",
                    email:  "email",
                    status: "oneof:active:inactive:pending"
                )

                expect( users ).toHaveLength( 10 )
                expect( [ "active", "inactive", "pending" ] ).toInclude( users[ 1 ].status )
            } )

            it( "should generate nested objects", () => {
                var order = mockData.mock(
                    $returnType: "struct",
                    id:          "autoincrement",
                    customerId:  "uuid",
                    total:       "rnd:50:500",
                    items: {
                        $num:  "rnd:1:5",
                        sku:   "uuid",
                        name:  "words",
                        price: "rnd:5:100"
                    }
                )

                expect( order ).toHaveKey( "items" )
                expect( order.items ).toBeArray()
            } )

        } )
    }
}
```

## Database Seeder Pattern

```boxlang
/**
 * tests/fixtures/DatabaseSeeder.cfc
 */
component singleton {

    function seedUsers( required numeric count = 5 ) {
        factory = new tests.factories.UserFactory()
        users = []

        for ( i = 1; i <= count; i++ ) {
            data = factory.create()
            qry = queryExecute(
                "INSERT INTO users (name, email) VALUES (:name, :email)",
                { name: data.name, email: data.email },
                { datasource: "testdb" }
            )
            data.id = qry.generatedKey
            users.append( data )
        }

        return users
    }

    function cleanup() {
        queryExecute( "DELETE FROM users WHERE email LIKE 'testuser%@example.com'", {}, { datasource: "testdb" } )
    }
}
```

## Best Practices

1. **Always `duplicate()`** shared fixture data before mutating in tests to prevent cross-test contamination
2. **Use factories** for dynamic, unique data — avoids duplicate key violations
3. **Use fixture files** for complex, reusable test data sets
4. **Keep fixtures minimal** — only include fields the test actually needs
5. **Reset factory counters** in `beforeEach` for predictable sequences
6. **Namespace test emails** — use `testuser@example.com` pattern for easy cleanup
