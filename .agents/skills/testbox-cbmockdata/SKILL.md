---
name: testbox-cbmockdata
description: "Use this skill when generating realistic fake/mock data in tests using cbMockData (WireBox ID: MockData@cbMockData): age, boolean, date, datetime, email, fname, lname, name, num, sentence, ssn, string, tel, uuid, url, words, lorem, baconlorem, imageurl, ipaddress, autoincrement, oneof, rnd/rand; generating arrays of objects, nested objects, arrays of values, or using custom supplier closures."
---

# cbMockData — Test Data Generation Reference

## When to Use This Skill

- Generating realistic fake data for test seeding, fixtures, or factories
- Creating arrays of mock objects (users, orders, products, etc.)
- Producing nested or related data structures
- Using custom supplier closures for computed or conditional test data

---

## Overview

`cbMockData` is a data generation module bundled with TestBox. It generates realistic fake values — names, emails, dates, SSNs, UUIDs, lorem ipsum, and more — via a simple fluent API.

**WireBox ID**: `MockData@cbMockData`

**Module**: Included automatically with TestBox. No separate installation needed.

---

## Getting an Instance

### In Tests via WireBox

```boxlang
property name="mockData" inject="MockData@cbMockData"

// or get it lazily inside a method:
var mockData = getInstance( "MockData@cbMockData" )
```

### Directly (No WireBox)

```boxlang
var mockData = new cbmockdata.models.MockData()
```

### In BDD `beforeAll()`

```boxlang
component extends="testbox.system.BaseSpec" {

    property name="mockData" inject="MockData@cbMockData"

    function run() {
        describe( "User registration", () => {

            var user = {}

            beforeAll( () => {
                user = mockData.mock(
                    fname: "fname",
                    lname: "lname",
                    email: "email"
                )
            } )

            it( "has a valid email", () => {
                expect( user.email ).toMatch( ".+@.+\..+" )
            } )

        } )
    }

}
```

---

## The `mock()` Method

```
mockData.mock(
    [fieldName]:  "[typeString]",   // repeated for each field
    $num:         10,               // number of records to return (default: 1)
    $returnType:  "array"           // "array" | "struct" (default: "array")
)
```

- When `$num > 1` the return is always an array.
- When `$num == 1` and `$returnType == "struct"` a single struct is returned.

---

## All Type Strings

| Type | Description | Example Output |
|---|---|---|
| `age` | Age 1–99 | `34` |
| `all_age` | Age 1–120 | `89` |
| `autoincrement` | Incrementing integer per call | `1`, `2`, `3` |
| `baconlorem` | Bacon ipsum sentences | `"Bacon ipsum dolor amet..."` |
| `boolean` | `true` or `false` | `true` |
| `boolean-digit` | `1` or `0` | `1` |
| `date` | Date string | `"2023-04-15"` |
| `datetime` | Date+time string | `"2023-04-15 14:32:00"` |
| `datetime-iso` | ISO 8601 datetime | `"2023-04-15T14:32:00Z"` |
| `email` | Valid email address | `"alice.smith@example.com"` |
| `fname` | First name | `"Alice"` |
| `lname` | Last name | `"Smith"` |
| `name` | Full name | `"Alice Smith"` |
| `num` | Number 1–9999 | `4721` |
| `oneof:a:b:c` | Random pick from colon-separated list | `"b"` |
| `rnd:min:max` / `rand:min:max` | Random integer in range | `rnd:1:100` → `57` |
| `sentence` | Lorem ipsum sentence | `"Lorem ipsum dolor..."` |
| `ssn` | US SSN format | `"123-45-6789"` |
| `string` | Random alphanumeric string | `"aB3kZ9"` |
| `string-alpha` | Random alphabetic string | `"AbCdEf"` |
| `string-numeric` | Random numeric string | `"482910"` |
| `string-secure` | Cryptographically random string | `"x9Qa#mK..."` |
| `tel` | Phone number | `"(555) 867-5309"` |
| `uuid` | UUID v4 | `"550e8400-e29b-41d4-a716-..."` |
| `guid` | GUID (same as uuid) | `"550e8400-..."` |
| `url` | URL | `"https://example.com/path"` |
| `words` | 1–5 random words | `"lorem ipsum dolor"` |
| `lorem` | Paragraph of lorem ipsum | `"Lorem ipsum..."` |
| `imageurl` | Placehold.it image URL | `"https://placehold.it/320x200"` |
| `ipaddress` | IPv4 address | `"192.168.1.42"` |

---

## Basic Usage

### Single Record (Struct)

```boxlang
var user = mockData.mock(
    $returnType: "struct",
    id:          "autoincrement",
    firstName:   "fname",
    lastName:    "lname",
    email:       "email",
    phone:       "tel",
    age:         "age",
    isActive:    "boolean",
    createdAt:   "datetime-iso"
)
// user.firstName => "Alice"
// user.email     => "alice@example.com"
// user.isActive  => true
```

### Array of Records

```boxlang
// By default $num returns an array
var users = mockData.mock(
    $num:      20,
    id:        "autoincrement",
    firstName: "fname",
    lastName:  "lname",
    email:     "email",
    role:      "oneof:admin:editor:viewer"
)
// returns array of 20 user structs
// each has a unique id (1-20), random names/emails, and one of 3 roles
```

---

## Advanced Patterns

### Fixed Value (Non-Type)

Any value that is NOT a recognized type string is used as-is:

```boxlang
var record = mockData.mock(
    $returnType: "struct",
    status:      "active",        // literal string — always "active"
    version:     1,               // literal number — always 1
    source:      "test-suite"
)
```

### `oneof` — Enumerated Values

```boxlang
var order = mockData.mock(
    $returnType: "struct",
    status:      "oneof:pending:processing:shipped:delivered:cancelled",
    priority:    "oneof:low:medium:high",
    paymentType: "oneof:credit:debit:paypal"
)
```

### `rnd` / `rand` — Numeric Range

```boxlang
var product = mockData.mock(
    $returnType: "struct",
    price:       "rnd:10:999",     // integer 10–999
    quantity:    "rand:1:50",      // integer 1–50
    discount:    "rnd:0:40"        // integer 0–40 (percent)
)
```

---

## Nested Data Structures

### Array of Objects (Nested Array)

```boxlang
var orders = mockData.mock(
    $num:       5,
    id:         "autoincrement",
    customerId: "uuid",
    total:      "rnd:50:5000",
    items: {               // nested: array of item structs
        $num:   "rnd:1:5",
        sku:    "uuid",
        name:   "words",
        price:  "rnd:5:200",
        qty:    "rnd:1:10"
    }
)
// Each order has an `items` array with 1–5 item structs
```

### Nested Object (Single Struct)

```boxlang
var userWithAddress = mockData.mock(
    $returnType: "struct",
    id:          "autoincrement",
    name:        "name",
    email:       "email",
    address: {        // nested single struct (no $num = single object)
        street:  "words",
        city:    "words",
        country: "oneof:US:CA:UK:AU"
    }
)
```

### Array of Scalar Values

```boxlang
var record = mockData.mock(
    $returnType: "struct",
    id:          "autoincrement",
    tags:        [ "words" ]      // array wrapper = array of that type
    // tags will be an array of random word strings
)
```

---

## Custom Supplier Closures

When no built-in type covers your need, pass a closure. The closure receives the current mock struct (partial, built so far) and returns the value:

```boxlang
var record = mockData.mock(
    $returnType: "struct",
    firstName:   "fname",
    lastName:    "lname",
    email:       function( current ) {
        // derive email from already-generated names
        return lCase( current.firstName & "." & current.lastName & "@example.com" )
    },
    slug:        function( current ) {
        return lCase( replace( current.firstName & "-" & current.lastName, " ", "-", "all" ) )
    },
    score:       function( current ) {
        return randRange( 0, 100 )
    }
)
```

---

## Integration with Test Factories

Use cbMockData inside a factory helper to produce consistent test data across specs:

```boxlang
// tests/helpers/UserFactory.bx
class {
    property name="mockData" inject="MockData@cbMockData"

    // Return a valid user struct
    function make( struct overrides={} ) {
        var user = mockData.mock(
            $returnType: "struct",
            id:          "autoincrement",
            firstName:   "fname",
            lastName:    "lname",
            email:       "email",
            role:        "oneof:admin:editor:viewer",
            isActive:    "boolean",
            createdAt:   "datetime-iso"
        )
        // merge overrides onto generated defaults
        return user.append( overrides, true )
    }

    // Return N user structs
    function makeMany( numeric count=5, struct overrides={} ) {
        return mockData.mock(
            $num:      count,
            id:        "autoincrement",
            firstName: "fname",
            lastName:  "lname",
            email:     "email",
            role:      "oneof:admin:editor:viewer",
            isActive:  "boolean"
        ).map( ( u ) => u.append( overrides, true ) )
    }

}
```

```boxlang
// In a test bundle
property name="userFactory" inject="UserFactory@myApp"

function run() {
    describe( "UserService", () => {

        it( "can find admin users", () => {
            var admin = userFactory.make( { role: "admin" } )
            userService.seed( admin )
            expect( userService.getAdmins() ).notToBeEmpty()
        } )

    } )
}
```

---

## Quick Reference

```boxlang
// Single struct
mockData.mock( $returnType: "struct", email: "email", name: "name" )

// Array of 10
mockData.mock( $num: 10, id: "autoincrement", name: "name" )

// Enum / pick one
mockData.mock( $returnType: "struct", status: "oneof:active:inactive:pending" )

// Range
mockData.mock( $returnType: "struct", score: "rnd:1:100" )

// Nested objects
mockData.mock( $num: 3, name: "name", address: { city: "words", country: "oneof:US:UK" } )

// Supplier closure
mockData.mock( $returnType: "struct", id: "autoincrement", label: ( curr ) => "Item-#curr.id#" )
```
