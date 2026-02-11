# CBORM Module Guidelines

## Overview

CBORM enhances ColdFusion's Hibernate ORM with service layers, Active Record pattern, fluent criteria queries, dynamic finders, entity population, and validation. It provides a powerful abstraction over Hibernate.

## Installation

```bash
box install cborm
```

## Configuration

In `config/ColdBox.cfc`:

```boxlang
moduleSettings = {
    cborm = {
        // Enable injection
        injection = {
            enabled = true,
            include = "",
            exclude = ""
        },
        
        // Default datasource
        datasource = "",
        
        // Enable query caching
        caching = {
            enabled = false,
            cacheRegion = "ormCache"
        }
    }
}
```

## Base ORM Service

The foundational service for working with ANY entity:

### Injection

```boxlang
// Inject base ORM service
property name="ormService" inject="BaseORMService@cborm";
property name="ormService" inject="entityService";
```

### Basic Operations

```boxlang
// Get by ID
var user = ormService.get( "User", 1 )

// Get or fail (throws exception)
var user = ormService.getOrFail( "User", 1 )

// Get all
var users = ormService.getAll( "User" )

// Count
var count = ormService.count( "User" )

// Find by criteria
var users = ormService.findWhere(
    entityName = "User",
    criteria = { active: true, role: "admin" }
)

// New entity
var user = ormService.new( "User" )

// Populate entity
var user = ormService.populate(
    target = ormService.new( "User" ),
    memento = {
        firstName: "John",
        lastName: "Doe",
        email: "[email protected]"
    }
)

// Save entity
ormService.save( user )

// Delete entity
ormService.delete( user )

// Delete by ID
ormService.deleteByID( "User", 1 )
```

## Virtual Entity Service

Bound to a specific entity - no need to pass entity name:

### Injection

```boxlang
// Inject virtual service for User entity
property name="userService" inject="entityService:User";

// Multiple entity services
property name="userService" inject="entityService:User";
property name="postService" inject="entityService:Post";
property name="orderService" inject="entityService:Order";
```

### Usage

```boxlang
// All methods from BaseORMService, without entityName argument
var users = userService.list()
var user = userService.get( 1 )
var user = userService.getOrFail( 1 )
var count = userService.count()
var activeUsers = userService.findWhere( { active: true } )

// New entity
var user = userService.new( {
    firstName: "John",
    lastName: "Doe"
} )

// Save
userService.save( user )

// Delete
userService.delete( user )
```

### Mapping Custom Virtual Services

```boxlang
// config/WireBox.cfc
map( "UserService" )
    .to( "cborm.models.VirtualEntityService" )
    .asSingleton()
    .initArg( name="entityName", value="User" )
    .initArg( name="useQueryCaching", value=true )

// Usage
property name="userService" inject="UserService";
```

## Criteria Queries

Fluent API for building Hibernate criteria queries:

### Basic Criteria

```boxlang
// Simple criteria
var users = userService.newCriteria()
    .eq( "active", true )
    .like( "email", "%@gmail.com" )
    .list()

// With ordering
var users = userService.newCriteria()
    .isTrue( "active" )
    .order( "lastName" )
    .order( "firstName" )
    .list()

// Pagination
var users = userService.newCriteria()
    .isTrue( "active" )
    .list( max=25, offset=0 )

// Get single result
var user = userService.newCriteria()
    .eq( "email", "[email protected]" )
    .get()

// Count
var count = userService.newCriteria()
    .isTrue( "active" )
    .count()
```

### Restrictions

```boxlang
// Equality
.eq( "status", "active" )
.ne( "status", "deleted" )

// Null checks
.isNull( "deletedAt" )
.isNotNull( "emailVerifiedAt" )

// Boolean
.isTrue( "active" )
.isFalse( "banned" )

// Comparisons
.gt( "age", 18 )        // Greater than
.ge( "age", 18 )        // Greater than or equal
.lt( "age", 65 )        // Less than
.le( "age", 65 )        // Less than or equal

// Between
.between( "age", 18, 65 )

// Like
.like( "email", "%@example.com" )
.ilike( "name", "%john%" ) // Case insensitive

// In list
.in( "status", [ "active", "pending" ] )

// SQL restriction
.sql( "userName = ? and age > ?", [ "john", 18 ] )
```

### Joins

```boxlang
// Join to association
var posts = postService.newCriteria()
    .joinTo( "author" )
    .eq( "firstName", "John" )
    .list()

// Left join
var posts = postService.newCriteria()
    .joinTo( "comments", "left" )
    .isNull( "approvedAt" )
    .list()

// Multiple joins
var posts = postService.newCriteria()
    .joinTo( "author" )
    .eq( "active", true )
    .joinTo( "category" )
    .in( "name", [ "Technology", "Programming" ] )
    .list()
```

### Logical Grouping

```boxlang
// AND (default)
var users = userService.newCriteria()
    .eq( "active", true )
    .gt( "age", 18 )
    .list()

// OR
var users = userService.newCriteria()
    .or(
        userService.getRestrictions().eq( "role", "admin" ),
        userService.getRestrictions().eq( "role", "moderator" )
    )
    .list()

// Complex grouping
var users = userService.newCriteria()
    .isTrue( "active" )
    .or(
        userService.getRestrictions().eq( "role", "admin" ),
        userService.getRestrictions().and(
            userService.getRestrictions().eq( "role", "user" ),
            userService.getRestrictions().gt( "points", 1000 )
        )
    )
    .list()
```

### Result Transformations

```boxlang
// As array of objects (default)
var users = userService.newCriteria()
    .isTrue( "active" )
    .list()

// As array of structs
var users = userService.newCriteria()
    .isTrue( "active" )
    .asStruct()
    .list()

// As query
var qUsers = userService.newCriteria()
    .isTrue( "active" )
    .asQuery()
    .list()

// As stream (cbStreams)
var userStream = userService.newCriteria()
    .isTrue( "active" )
    .asStream()
    .list()

// Distinct results
var uniqueEmails = userService.newCriteria()
    .distinct()
    .withProjections( property="email" )
    .list()
```

### Projections

```boxlang
// Select specific properties
var userData = userService.newCriteria()
    .withProjections( property="id,firstName,lastName,email" )
    .asStruct()
    .list()

// Count
var userCount = userService.newCriteria()
    .withProjections( count="id" )
    .get()

// Aggregates
var stats = userService.newCriteria()
    .withProjections( 
        property = "role",
        count = "id",
        avg = "age",
        max = "points"
    )
    .asStruct()
    .list()
```

## Dynamic Finders

Convention-based query methods:

```boxlang
// Find by single property
var user = userService.findByEmail( "[email protected]" )
var users = userService.findAllByRole( "admin" )

// Find by multiple properties
var user = userService.findByEmailAndActive( "[email protected]", true )
var users = userService.findAllByRoleAndActive( "admin", true )

// Count by property
var count = userService.countByRole( "admin" )
var count = userService.countByActive( true )

// Count by multiple properties
var count = userService.countByRoleAndActive( "admin", true )

// With operators
var users = userService.findAllByAgeGreaterThan( 18 )
var users = userService.findAllByPointsLessThan( 100 )
var users = userService.findAllByCreatedDateBetween( startDate, endDate )
var users = userService.findAllByEmailLike( "%@gmail.com" )
```

## Active Entity

Entities that inherit from ActiveEntity get Active Record pattern:

### Defining Active Entity

```boxlang
component 
    extends="cborm.models.ActiveEntity"
    entityName="User"
    table="users"
{
    property name="id" fieldtype="id" generator="increment";
    property name="firstName";
    property name="lastName";
    property name="email";
    property name="password";
    property name="active" ormtype="boolean";
    
    // Relationships
    property name="posts" fieldtype="one-to-many" cfc="Post" fkcolumn="userId";
    property name="profile" fieldtype="one-to-one" cfc="Profile" fkcolumn="userId";
}
```

### Using Active Entity

```boxlang
// Create new
var user = getInstance( "User" ).new( {
    firstName: "John",
    lastName: "Doe",
    email: "[email protected]"
} )

// Save
user.save()

// Refresh from DB
user.refresh()

// Delete
user.delete()

// Criteria from entity
var users = getInstance( "User" )
    .newCriteria()
    .isTrue( "active" )
    .list()

// Get by ID
var user = getInstance( "User" ).get( 1 )
var user = getInstance( "User" ).getOrFail( 1 )

// Dynamic finders on entity
var user = getInstance( "User" ).findByEmail( "[email protected]" )
var users = getInstance( "User" ).findAllByActive( true )
```

## Best Practices

- **Use Virtual Entity Services** - Create service layers for each entity
- **Leverage criteria queries** - More flexible than HQL for complex queries
- **Use dynamic finders** - Simplify common queries
- **Enable query caching** - Cache expensive queries
- **Use projections** - Only retrieve needed properties
- **Lazy load associations** - Prevent N+1 queries with careful fetch strategies
- **Use transactions** - Wrap multiple ORM operations
- **Clear session when needed** - Avoid stale data with ormFlush()
- **Index foreign keys** - Ensure proper database indexing
- **Test with actual database** - Don't rely only on in-memory tests

## Documentation

For complete CBORM documentation, criteria queries, and Active Entity features, visit:
https://coldbox-orm.ortusbooks.com
