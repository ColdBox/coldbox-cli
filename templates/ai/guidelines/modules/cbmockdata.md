---
title: CBMockData - Test Data Generation
description: Test-data generation guidance with cbMockData, including deterministic fixtures, locale-aware fake data, domain modeling, and scalable seeding strategies.
---

# CBMockData - Test Data Generation

> **Module**: cbmockdata
> **Category**: Testing / Development
> **Purpose**: Generate realistic mock data for testing and development

## Overview

CBMockData generates realistic fake data for testing, seeding databases, and development. It provides generators for names, addresses, emails, lorem ipsum, numbers, dates, and custom data patterns.

## Core Features

- Realistic person data (names, emails, phones)
- Address generation (US and international)
- Lorem ipsum text generation
- Numeric data (integers, decimals, currency)
- Date/time generation
- Custom data patterns
- Bulk data generation
- Locale support
- UUID and GUID generation

## Installation

```bash
box install cbmockdata
```

## Configuration

```javascript
// config/ColdBox.cfc - moduleSettings
moduleSettings = {
    cbmockdata: {
        // Default locale
        locale: "en_US",

        // Custom data providers
        providers: {}
    }
};
```

## Usage Patterns

### Basic Mock Data

```javascript
component {
    property name="mockdata" inject="MockDataService@cbmockdata";

    function generateTestUser() {
        return {
            firstName: mockdata.firstName(),
            lastName: mockdata.lastName(),
            email: mockdata.email(),
            phone: mockdata.phone(),
            age: mockdata.age(),
            ssn: mockdata.ssn(),
            address: mockdata.streetAddress(),
            city: mockdata.city(),
            state: mockdata.state(),
            zip: mockdata.zipCode(),
            company: mockdata.company(),
            jobTitle: mockdata.jobTitle()
        };
    }
}
```

### Bulk Generation

```javascript
// Generate array of mock users
var users = mockdata.mock(
    $num = 100,
    firstName = "firstName",
    lastName = "lastName",
    email = "email",
    age = "age:18..65",
    isActive = "oneof:true:false",
    createdDate = "datetime"
);

// With custom patterns
var products = mockdata.mock(
    $num = 50,
    name = "words:3",
    description = "sentence",
    price = "num:10..1000",
    sku = "uuid",
    category = "oneof:Electronics:Clothing:Books:Toys"
);
```

### Database Seeding

```javascript
// Seed users table
var users = mockdata.mock(
    $num = 1000,
    username = "username",
    email = "email",
    password = "string-secure:12",
    firstName = "firstName",
    lastName = "lastName",
    isActive = "bit",
    createdDate = "datetime",
    updatedDate = "datetime"
);

users.each( function( user ) {
    queryExecute(
        "INSERT INTO users (username, email, password, firstName, lastName, isActive, createdDate, updatedDate)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
        [
            user.username,
            user.email,
            hash( user.password ),
            user.firstName,
            user.lastName,
            user.isActive,
            user.createdDate,
            user.updatedDate
        ]
    );
} );
```

### Custom Patterns

```javascript
// String patterns
mockdata.words( 5 ) // 5 random words
mockdata.sentence() // Random sentence
mockdata.paragraph( 3 ) // 3 paragraphs
mockdata.string( "##-###-####" ) // Pattern: 12-345-6789

// Numeric patterns
mockdata.num( min=1, max=100 )
mockdata.float( min=0, max=1, precision=2 )
mockdata.currency()
mockdata.percentage()

// Date patterns
mockdata.datetime()
mockdata.date()
mockdata.dateRange( from="2020-01-01", to="2023-12-31" )
mockdata.time()

// Random selection
mockdata.oneOf( [ "Admin", "User", "Guest" ] )
mockdata.oneOf( [ true, false ] )

// Boolean/Bit
mockdata.bit()
mockdata.boolean()

// IDs
mockdata.uuid()
mockdata.guid()
mockdata.baUUID()
```

### Testing Integration

```javascript
describe( "User Service", function() {

    beforeEach( function() {
        mockdata = getInstance( "MockDataService@cbmockdata" );
    });

    it( "can create multiple users", function() {
        var testUsers = mockdata.mock(
            $num = 10,
            firstName = "firstName",
            lastName = "lastName",
            email = "email"
        );

        testUsers.each( function( userData ) {
            var user = userService.create( userData );
            expect( user ).toBeComponent();
            expect( user.getEmail() ).toBe( userData.email );
        } );
    });

    it( "handles edge cases", function() {
        // Generate extreme values
        var edgeUser = {
            firstName: mockdata.string( "a", 255 ), // Max length
            age: mockdata.num( 150, 200 ), // Invalid age
            email: "invalid-email" // Invalid format
        };

        expect( function() {
            userService.create( edgeUser );
        } ).toThrow();
    });
});
```

### API Response Mocking

```javascript
// Mock API responses in tests
function mockUserAPIResponse() {
    return {
        data: mockdata.mock(
            $num = 20,
            id = "uuid",
            name = "name",
            email = "email",
            avatar = "imageURL:200:200"
        ),
        pagination: {
            page: 1,
            perPage: 20,
            total: 1000
        }
    };
}
```

## Data Types Reference

```javascript
// Personal
mockdata.firstName()
mockdata.lastName()
mockdata.name()
mockdata.username()
mockdata.email()
mockdata.phone()
mockdata.ssn()
mockdata.age( min=18, max=65 )

// Address
mockdata.streetAddress()
mockdata.city()
mockdata.state()
mockdata.stateAbbr()
mockdata.zipCode()
mockdata.country()
mockdata.latitude()
mockdata.longitude()

// Business
mockdata.company()
mockdata.companySuffix()
mockdata.jobTitle()
mockdata.industry()

// Internet
mockdata.url()
mockdata.domain()
mockdata.ipAddress()
mockdata.userAgent()
mockdata.color()

// Text
mockdata.word()
mockdata.words( count=5 )
mockdata.sentence()
mockdata.paragraph()
mockdata.lorem( words=100 )

// Numbers
mockdata.num( min, max )
mockdata.float( min, max, precision )
mockdata.currency( min, max )

// Dates
mockdata.datetime( from, to )
mockdata.date( from, to )
mockdata.time()
mockdata.timestamp()

// Misc
mockdata.uuid()
mockdata.boolean()
mockdata.imageURL( width, height )
mockdata.fileExtension()
mockdata.mimeType()
```

## Best Practices

1. **Use for Development Only**: Never in production
2. **Consistent Seeding**: Use seed values for reproducible data
3. **Realistic Data**: Generate data that matches production patterns
4. **Locale-Aware**: Use appropriate locale for testing
5. **Boundary Testing**: Generate edge cases (min/max values)
6. **Performance Testing**: Generate large datasets for load testing
7. **Privacy Compliance**: Don't use real user data in tests

## Common Patterns

### Seeder Component

```javascript
component {
    property name="mockdata" inject="MockDataService@cbmockdata";

    function seedUsers( count=100 ) {
        var users = mockdata.mock(
            $num = arguments.count,
            firstName = "firstName",
            lastName = "lastName",
            email = "email",
            password = "string-secure:12",
            isActive = "bit",
            createdDate = "datetime"
        );

        users.each( function( user ) {
            entityNew( "User", user ).save();
        } );

        return users.len();
    }
}
```

### Fixture Generation

```javascript
// Generate test fixtures
function createTestFixtures() {
    return {
        admin: mockdata.mock(
            firstName = "firstName",
            role = "Admin",
            isActive = true
        ),
        regularUser: mockdata.mock(
            firstName = "firstName",
            role = "User",
            isActive = true
        ),
        inactiveUser: mockdata.mock(
            firstName = "firstName",
            role = "User",
            isActive = false
        )
    };
}
```

## Additional Resources

- [TestBox Testing Framework](https://testbox.ortusbooks.com)
- [Database Seeding Best Practices](https://en.wikipedia.org/wiki/Database_seeding)
