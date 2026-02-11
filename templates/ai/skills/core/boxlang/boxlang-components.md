---
name: BoxLang Components
description: Complete guide to BoxLang component-based architecture with CFCs, interfaces, composition, and object-oriented design patterns
category: boxlang
priority: high
triggers:
  - boxlang component
  - cfc
  - class
  - interface
  - composition
  - object oriented
---

# BoxLang Components

## Overview

BoxLang components (CFCs) are the foundation of object-oriented programming in BoxLang. They encapsulate data and behavior, support inheritance, interfaces, and modern class syntax.

## Core Concepts

### Component Fundamentals

- **Classes**: Modern `class` syntax
- **Properties**: Component variables with metadata
- **Methods**: Functions within components
- **Constructors**: `init()` method
- **Inheritance**: `extends` keyword
- **Interfaces**: `implements` keyword
- **Composition**: Has-A relationships

## Basic Components

### Simple Component

```boxlang
/**
 * models/User.cfc
 */
class {

    // Properties
    property name="id" type="numeric"
    property name="email" type="string"
    property name="firstName" type="string"
    property name="lastName" type="string"

    /**
     * Constructor
     */
    function init(
        required string email,
        required string firstName,
        required string lastName
    ) {
        variables.id = 0
        variables.email = email
        variables.firstName = firstName
        variables.lastName = lastName

        return this
    }

    /**
     * Get full name
     */
    function getFullName() {
        return "#variables.firstName# #variables.lastName#"
    }

    /**
     * Check if user is persisted
     */
    function isPersisted() {
        return variables.id > 0
    }
}
```

### Using Components

```boxlang
// Create instance
var user = new models.User(
    email: "john@example.com",
    firstName: "John",
    lastName: "Doe"
)

// Call methods
writeDump( user.getFullName() )  // "John Doe"

// Access properties
writeDump( user.getEmail() )  // "john@example.com"

// Check state
if ( user.isPersisted() ) {
    writeOutput( "User has ID: #user.getId()#" )
}
```

## Properties

### Property Metadata

```boxlang
class {

    // Simple property
    property name="name"

    // Typed property
    property name="age" type="numeric"

    // Property with default
    property name="active" type="boolean" default="true"

    // Dependency injection
    property name="userService" inject="UserService"

    // Validation
    property name="email" type="string" required="true"

    // Documentation
    property name="status" hint="User account status" type="string"

    // Custom getter/setter
    property name="password" getter="false" setter="true"
}
```

### Custom Accessors

```boxlang
class {

    property name="email" type="string"
    property name="password" setter="false"

    /**
     * Custom email setter with validation
     */
    function setEmail( required string email ) {
        if ( !isValid( "email", email ) ) {
            throw( type="ValidationException", message="Invalid email" )
        }
        variables.email = lcase( email )
    }

    /**
     * Custom password setter with hashing
     */
    function setPassword( required string password ) {
        variables.password = hash( password, "SHA-256" )
    }

    /**
     * Verify password
     */
    function verifyPassword( required string password ) {
        return hash( password, "SHA-256" ) == variables.password
    }
}
```

## Inheritance

### Extending Components

```boxlang
/**
 * Base class
 * models/BaseEntity.cfc
 */
class {

    property name="id" type="numeric"
    property name="createdDate" type="date"
    property name="modifiedDate" type="date"

    function init() {
        variables.id = 0
        variables.createdDate = now()
        variables.modifiedDate = now()
        return this
    }

    function isPersisted() {
        return variables.id > 0
    }

    function touch() {
        variables.modifiedDate = now()
        return this
    }
}

/**
 * Derived class
 * models/User.cfc
 */
class extends="BaseEntity" {

    property name="email" type="string"
    property name="name" type="string"

    function init(
        required string email,
        required string name
    ) {
        super.init()

        variables.email = email
        variables.name = name

        return this
    }

    function update( required string name ) {
        variables.name = name
        super.touch()
    }
}
```

## Interfaces

### Defining Interfaces

```boxlang
/**
 * models/IRepository.cfc
 */
interface {

    /**
     * Find entity by ID
     */
    function findById( required numeric id )

    /**
     * Find all entities
     */
    function findAll()

    /**
     * Save entity
     */
    function save( required any entity )

    /**
     * Delete entity
     */
    function delete( required numeric id )
}
```

### Implementing Interfaces

```boxlang
/**
 * models/UserRepository.cfc
 */
class implements="IRepository" {

    property name="datasource" inject="coldbox:setting:datasource"

    function findById( required numeric id ) {
        var qUser = queryExecute(
            "SELECT * FROM users WHERE id = :id",
            { id: id },
            { datasource: variables.datasource }
        )

        return qUser.recordCount ? queryRowToStruct( qUser ) : {}
    }

    function findAll() {
        return queryExecute(
            "SELECT * FROM users ORDER BY name",
            {},
            { datasource: variables.datasource }
        )
    }

    function save( required any entity ) {
        if ( entity.isPersisted() ) {
            return update( entity )
        }
        return insert( entity )
    }

    function delete( required numeric id ) {
        queryExecute(
            "DELETE FROM users WHERE id = :id",
            { id: id },
            { datasource: variables.datasource }
        )
    }

    // Private helper methods
    private function insert( required any entity ) {
        var result = queryExecute(
            "INSERT INTO users (email, name) VALUES (:email, :name)",
            {
                email: entity.getEmail(),
                name: entity.getName()
            },
            {
                datasource: variables.datasource,
                result: "result"
            }
        )

        entity.setId( result.generatedKey )
        return entity
    }

    private function update( required any entity ) {
        queryExecute(
            "UPDATE users SET email = :email, name = :name WHERE id = :id",
            {
                id: entity.getId(),
                email: entity.getEmail(),
                name: entity.getName()
            },
            { datasource: variables.datasource }
        )

        return entity
    }
}
```

## Composition

### Has-A Relationships

```boxlang
/**
 * models/Address.cfc
 */
class {
    property name="street" type="string"
    property name="city" type="string"
    property name="state" type="string"
    property name="zip" type="string"

    function init(
        required string street,
        required string city,
        required string state,
        required string zip
    ) {
        variables.street = street
        variables.city = city
        variables.state = state
        variables.zip = zip
        return this
    }

    function toString() {
        return "#variables.street#, #variables.city#, #variables.state# #variables.zip#"
    }
}

/**
 * models/Customer.cfc
 */
class {
    property name="name" type="string"
    property name="email" type="string"
    property name="address" type="Address"

    function init(
        required string name,
        required string email
    ) {
        variables.name = name
        variables.email = email
        return this
    }

    function setAddress( required Address address ) {
        variables.address = address
        return this
    }

    function getMailingAddress() {
        return variables.address.toString()
    }
}
```

### Using Composition

```boxlang
var address = new models.Address(
    street: "123 Main St",
    city: "Boston",
    state: "MA",
    zip: "02101"
)

var customer = new models.Customer(
    name: "John Doe",
    email: "john@example.com"
)
.setAddress( address )

writeOutput( customer.getMailingAddress() )
```

## Advanced Patterns

### Abstract Base Classes

```boxlang
/**
 * models/BaseService.cfc
 */
class {

    property name="wirebox" inject="wirebox"
    property name="log" inject="logbox:logger:{this}"

    /**
     * Must be implemented by subclasses
     */
    function getRepositoryName() {
        throw(
            type: "AbstractMethodException",
            message: "getRepositoryName() must be implemented"
        )
    }

    /**
     * Get repository
     */
    function getRepository() {
        return variables.wirebox.getInstance( getRepositoryName() )
    }

    /**
     * Find by ID with caching
     */
    function findById( required numeric id ) {
        return cacheGetOrSet(
            key: "#getRepositoryName()#_#id#",
            produce: () => getRepository().findById( id )
        )
    }
}

/**
 * models/UserService.cfc
 */
class extends="BaseService" {

    function getRepositoryName() {
        return "UserRepository"
    }

    function findByEmail( required string email ) {
        return getRepository().findByEmail( email )
    }
}
```

### Mixins

```boxlang
/**
 * models/mixins/Timestampable.cfc
 */
class {

    function injectTimestamps() {
        this.createdDate = now()
        this.modifiedDate = now()
    }

    function touch() {
        this.modifiedDate = now()
        return this
    }

    function getAge() {
        return dateDiff( "d", this.createdDate, now() )
    }
}

/**
 * Use mixin
 */
var user = new models.User()

// Mix in methods
var mixin = new models.mixins.Timestampable()
user.injectTimestamps = mixin.injectTimestamps
user.touch = mixin.touch
user.getAge = mixin.getAge

// Use mixed-in methods
user.injectTimestamps()
writeDump( user.getAge() )
```

### Builder Pattern

```boxlang
/**
 * models/QueryBuilder.cfc
 */
class {

    variables.select = "*"
    variables.from = ""
    variables.where = []
    variables.orderBy = []

    function select( required string columns ) {
        variables.select = columns
        return this
    }

    function from( required string table ) {
        variables.from = table
        return this
    }

    function where( required string condition, required any value ) {
        variables.where.append( {
            condition: condition,
            value: value
        } )
        return this
    }

    function orderBy( required string column, string direction = "ASC" ) {
        variables.orderBy.append( "#column# #direction#" )
        return this
    }

    function build() {
        var sql = "SELECT #variables.select# FROM #variables.from#"

        if ( variables.where.len() ) {
            sql &= " WHERE " & variables.where
                .map( ( w ) => w.condition )
                .toList( " AND " )
        }

        if ( variables.orderBy.len() ) {
            sql &= " ORDER BY " & variables.orderBy.toList( ", " )
        }

        return sql
    }

    function execute() {
        var params = {}
        variables.where.each( ( w, i ) => {
            params["param#i#"] = w.value
        } )

        return queryExecute( build(), params )
    }
}

// Usage
var results = new models.QueryBuilder()
    .select( "name, email" )
    .from( "users" )
    .where( "active = :active", true )
    .where( "age > :age", 18 )
    .orderBy( "name" )
    .execute()
```

## Best Practices

### Design Guidelines

1. **Single Responsibility**: One purpose per class
2. **Small Methods**: Keep methods focused
3. **Composition**: Favor over inheritance
4. **Interfaces**: Define contracts
5. **Immutability**: Consider immutable objects
6. **Encapsulation**: Hide implementation
7. **Documentation**: Document public API
8. **Testing**: Write unit tests
9. **Naming**: Clear, descriptive names
10. **Dependencies**: Use injection

### Common Patterns

```boxlang
// ✅ Good: Constructor injection
class {
    property name="userService" inject="UserService"
    property name="log" inject="logbox:logger:{this}"
}

// ✅ Good: Fluent interface
function setName( required string name ) {
    variables.name = name
    return this
}

// ✅ Good: Validation in setters
function setEmail( required string email ) {
    if ( !isValid( "email", email ) ) {
        throw( type="ValidationException", message="Invalid email" )
    }
    variables.email = email
}
```

## Common Pitfalls

### Pitfalls to Avoid

1. **God Objects**: Too many responsibilities
2. **Deep Inheritance**: Complex hierarchies
3. **Public Properties**: Break encapsulation
4. **No Interfaces**: Tight coupling
5. **Mutable State**: Shared references
6. **Large Classes**: Hard to maintain
7. **Static Dependencies**: Hard to test
8. **No Validation**: Invalid state
9. **Tight Coupling**: Hard to change
10. **No Documentation**: Hard to use

### Anti-Patterns

```boxlang
// ❌ Bad: Public properties
class {
    this.name = "John"
    this.email = "john@example.com"
}

// ✅ Good: Private with accessors
class {
    property name="name" type="string"
    property name="email" type="string"
}

// ❌ Bad: No validation
function setAge( required numeric age ) {
    variables.age = age
}

// ✅ Good: Validate input
function setAge( required numeric age ) {
    if ( age < 0 || age > 150 ) {
        throw( type="ValidationException", message="Invalid age" )
    }
    variables.age = age
}

// ❌ Bad: Deep inheritance
class extends="BaseService"
      extends="AbstractService"
      extends="GenericService" {
}

// ✅ Good: Composition
class {
    property name="service" inject="BaseService"
}
```

## Related Skills

- [BoxLang Classes](boxlang-classes.md) - Class syntax
- [BoxLang Modules](boxlang-modules.md) - Module development
- [Dependency Injection](../coldbox/dependency-injection.md) - WireBox DI

## References

- [BoxLang Components Documentation](https://boxlang.ortusbooks.com/)
- [Object-Oriented Design Principles](https://en.wikipedia.org/wiki/SOLID)
- [Design Patterns](https://refactoring.guru/design-patterns)
