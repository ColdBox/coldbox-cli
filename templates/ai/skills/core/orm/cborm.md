---
name: CBORM - ORM Utilities
description: Complete guide to cborm module utilities for Hibernate ORM including active entity, virtual entity services, criteria queries, event handling, and ORM extensions
category: orm
priority: high
triggers:
  - cborm
  - hibernate
  - orm utilities
  - entity service
  - virtual entity
  - criteria query
---

# CBORM - ORM Utilities

## Overview

cborm is a ColdBox module that provides utility services, active entity pattern, virtual entity services, and event handling for Hibernate ORM. It extends native ColdFusion/BoxLang ORM with a clean, consistent API.

## Installation

```bash
box install cborm
```

## Configuration

### Application.cfc

```boxlang
// Enable ORM
this.ormEnabled = true
this.ormSettings = {
    cfclocation: [ "/models" ],
    dbcreate: "update",
    logSQL: true,
    flushAtRequestEnd: false,
    autoManageSession: false,
    eventHandling: true,
    eventHandler: "cborm.models.EventHandler"
}
```

### config/ColdBox.cfc

```boxlang
moduleSettings = {
    cborm: {
        injection: {
            enabled: true,
            include: "",
            exclude: ""
        },
        resources: {
            eventHandler: true,
            transactionHandlers: true
        }
    }
}
```

## BaseORMService

### Basic Service Pattern

```boxlang
/**
 * UserService.cfc
 */
class extends="cborm.models.BaseORMService" singleton {

    /**
     * Constructor
     */
    function init() {
        // Set the entity name
        setEntityName( "User" )
        return this
    }

    /**
     * Get active users
     */
    function getActiveUsers() {
        return newCriteria()
            .eq( "active", true )
            .list( sortOrder: "lastName" )
    }

    /**
     * Find user by email
     */
    function findByEmail( required string email ) {
        return newCriteria()
            .eq( "email", arguments.email )
            .get()
    }
}
```

### Common Service Methods

```boxlang
class extends="cborm.models.BaseORMService" singleton {

    // Create/Update
    function save( required entity ) {
        return super.save( arguments.entity )
    }

    // Delete
    function delete( required entity ) {
        super.delete( arguments.entity )
    }

    // Find by ID
    function get( required id ) {
        return super.get( arguments.id )
    }

    // Find by multiple IDs
    function getAll( required array ids ) {
        return super.getAll( arguments.ids )
    }

    // Get all entities
    function list(
        string sortOrder = "",
        numeric offset = 0,
        numeric max = 0
    ) {
        return super.list( argumentCollection = arguments )
    }

    // Count all
    function count() {
        return super.count()
    }

    // Count with criteria
    function countWhere( required struct criteria ) {
        return super.countWhere( arguments.criteria )
    }

    // Find by criteria
    function findWhere( required struct criteria ) {
        return super.findWhere( arguments.criteria )
    }

    // Find all by criteria
    function findAllWhere(
        required struct criteria,
        string sortOrder = ""
    ) {
        return super.findAllWhere( argumentCollection = arguments )
    }

    // Delete by ID
    function deleteByID( required id ) {
        super.deleteByID( arguments.id )
    }

    // Delete all
    function deleteAll() {
        super.deleteAll()
    }
}
```

## Virtual Entity Service

### Dynamic Entity Access

```boxlang
/**
 * Use VirtualEntityService for any entity without creating a service
 */
class {

    property name="ormService" inject="VirtualEntityService@cborm"

    function getUsers() {
        return ormService
            .newCriteria( "User" )
            .eq( "active", true )
            .list()
    }

    function saveUser( user ) {
        return ormService.save( "User", user )
    }

    function deleteUser( id ) {
        ormService.deleteByID( "User", id )
    }

    function countUsers() {
        return ormService.count( "User" )
    }
}
```

### Generic Operations

```boxlang
property name="ormService" inject="VirtualEntityService@cborm"

function list( entityName, sortOrder = "", offset = 0, max = 0 ) {
    return ormService.list(
        entityName: entityName,
        sortOrder: sortOrder,
        offset: offset,
        max: max
    )
}

function findWhere( entityName, criteria ) {
    return ormService.findWhere(
        entityName: entityName,
        criteria: criteria
    )
}

function get( entityName, id ) {
    return ormService.get( entityName, id )
}
```

## Criteria Queries

### Basic Criteria

```boxlang
/**
 * Using newCriteria() from BaseORMService
 */
class extends="cborm.models.BaseORMService" singleton {

    function init() {
        setEntityName( "User" )
        return this
    }

    function getActiveAdmins() {
        return newCriteria()
            .eq( "active", true )
            .eq( "role", "admin" )
            .list( sortOrder: "lastName" )
    }

    function searchUsers( searchTerm ) {
        return newCriteria()
            .or(
                restrictions.like( "firstName", "%#searchTerm#%" ),
                restrictions.like( "lastName", "%#searchTerm#%" ),
                restrictions.like( "email", "%#searchTerm#%" )
            )
            .list( max: 50 )
    }
}
```

### Advanced Criteria

```boxlang
function findUsers( filters ) {
    var c = newCriteria()

    // Dynamic filtering
    if ( structKeyExists( filters, "active" ) ) {
        c.eq( "active", filters.active )
    }

    if ( structKeyExists( filters, "role" ) ) {
        c.eq( "role", filters.role )
    }

    if ( structKeyExists( filters, "minAge" ) ) {
        c.ge( "age", filters.minAge )
    }

    if ( structKeyExists( filters, "maxAge" ) ) {
        c.le( "age", filters.maxAge )
    }

    // Date range
    if ( structKeyExists( filters, "startDate" ) && structKeyExists( filters, "endDate" ) ) {
        c.between( "createdDate", filters.startDate, filters.endDate )
    }

    return c.list(
        sortOrder: filters.sortOrder ?: "lastName",
        offset: filters.offset ?: 0,
        max: filters.max ?: 25
    )
}
```

### Restrictions

```boxlang
function complexQuery() {
    return newCriteria()
        // Equals
        .eq( "status", "active" )

        // Not equals
        .ne( "role", "guest" )

        // Greater than
        .gt( "age", 18 )

        // Greater than or equal
        .ge( "credits", 100 )

        // Less than
        .lt( "loginAttempts", 5 )

        // Less than or equal
        .le( "failedLogins", 3 )

        // Like
        .like( "email", "%@gmail.com" )

        // In list
        .in( "department", [ "IT", "Engineering", "DevOps" ] )

        // Not in list
        .notIn( "status", [ "deleted", "banned" ] )

        // Between
        .between( "salary", 50000, 100000 )

        // Is null
        .isNull( "deletedDate" )

        // Is not null
        .isNotNull( "emailVerifiedDate" )

        // Is empty (collection)
        .isEmpty( "orders" )

        // Is not empty (collection)
        .isNotEmpty( "permissions" )

        .list()
}
```

### Associations and Joins

```boxlang
function getUsersWithOrders() {
    return newCriteria()
        // Join with association
        .createAlias( "orders", "o" )
        .eq( "o.status", "completed" )
        .gt( "o.total", 100 )
        .list()
}

function getOrdersWithItems() {
    return newCriteria()
        // Left join
        .createAlias( "items", "i", "left" )
        // Inner join (default)
        .createAlias( "customer", "c" )
        .eq( "c.active", true )
        .list( sortOrder: "orderDate desc" )
}

function getUsersWithRoles() {
    return newCriteria()
        .createAlias( "roles", "r" )
        .in( "r.name", [ "admin", "manager" ] )
        // Return distinct results
        .resultTransformer( criteria.DISTINCT_ROOT_ENTITY )
        .list()
}
```

### Projections

```boxlang
function getUserStatistics() {
    var stats = newCriteria()
        .withProjections( property: "id,firstName,lastName,email" )
        .eq( "active", true )
        .list( asQuery: true )

    return stats
}

function getAggregates() {
    return newCriteria()
        .withProjections()
        .count( "id", "totalUsers" )
        .avg( "age", "avgAge" )
        .sum( "credits", "totalCredits" )
        .min( "createdDate", "firstUser" )
        .max( "lastLogin", "lastActivity" )
        .get()
}

function groupByDepartment() {
    return newCriteria()
        .withProjections( property: "department" )
        .count( "id", "userCount" )
        .groupProperty( "department" )
        .list( asQuery: true )
}
```

### Caching

```boxlang
function getCachedUsers() {
    return newCriteria()
        .eq( "active", true )
        // Enable query cache
        .cache( true )
        .cacheRegion( "users" )
        .list()
}
```

## Active Entity Pattern

### Extending ActiveEntity

```boxlang
/**
 * User.cfc
 */
class persistent="true"
      table="users"
      extends="cborm.models.ActiveEntity"
      entityName="User"
      cacheName="User"
      cacheUse="read-write" {

    // Primary key
    property name="id" fieldType="id" generator="native"

    // Attributes
    property name="firstName" ormType="string" length="50"
    property name="lastName" ormType="string" length="50"
    property name="email" ormType="string" length="100" unique="true"
    property name="password" ormType="string" length="255"
    property name="active" ormType="boolean" default="true"
    property name="createdDate" ormType="timestamp" default="now()"
    property name="modifiedDate" ormType="timestamp"

    // Relationships
    property name="role"
             fieldType="many-to-one"
             cfc="Role"
             fkColumn="roleID"
             lazy="true"

    property name="orders"
             fieldType="one-to-many"
             cfc="Order"
             fkColumn="userID"
             cascade="all"
             lazy="extra"

    /**
     * Get full name
     */
    function getFullName() {
        return "#getFirstName()# #getLastName()#"
    }

    /**
     * Before insert
     */
    function preInsert() {
        setCreatedDate( now() )
        setModifiedDate( now() )
    }

    /**
     * Before update
     */
    function preUpdate() {
        setModifiedDate( now() )
    }
}
```

### Using Active Entity

```boxlang
// Create new entity
var user = entityNew( "User" )
user.setFirstName( "John" )
user.setEmail( "john@example.com" )
user.save()  // Active entity method

// Load and update
var user = entityLoad( "User", 1 )
user.setActive( false )
user.save()

// Delete
user.delete()

// Refresh
user.refresh()

// Check if loaded
if ( !user.isLoaded() ) {
    // Entity not found
}

// Get validation errors
if ( !user.isValid() ) {
    var errors = user.getValidationResults().getAllErrors()
}
```

## Transaction Handling

### Declarative Transactions

```boxlang
/**
 * UserService.cfc
 */
class extends="cborm.models.BaseORMService"
      singleton
      transactional {

    function init() {
        setEntityName( "User" )
        return this
    }

    /**
     * Method-level transaction
     * @transactional true
     */
    function registerUser( data ) {
        var user = entityNew( "User" )
        user.populate( data )
        save( user )

        // Send welcome email (outside transaction if it fails)
        mailService.sendWelcome( user )

        return user
    }

    /**
     * Rollback on exception
     * @transactional true
     */
    function transferCredits( fromUserID, toUserID, amount ) {
        var fromUser = get( fromUserID )
        var toUser = get( toUserID )

        if ( fromUser.getCredits() < amount ) {
            throw( type: "InsufficientCredits" )
        }

        fromUser.setCredits( fromUser.getCredits() - amount )
        toUser.setCredits( toUser.getCredits() + amount )

        save( fromUser )
        save( toUser )
    }
}
```

### Manual Transactions

```boxlang
class extends="cborm.models.BaseORMService" singleton {

    property name="ormService" inject="VirtualEntityService@cborm"

    function complexOperation() {
        transaction {
            try {
                var user = entityNew( "User" )
                user.populate( data )
                ormService.save( user )

                var order = entityNew( "Order" )
                order.setUser( user )
                ormService.save( order )

                transaction action="commit";

            } catch ( any e ) {
                transaction action="rollback";
                rethrow
            }
        }
    }
}
```

## Event Handling

### Global ORM Events

```boxlang
/**
 * cborm EventHandler
 * Automatically registered when cborm.resources.eventHandler = true
 */
class {

    property name="log" inject="logbox:logger:{this}"

    function preInsert( entity ) {
        log.info( "Creating #getMetadata( entity ).entityName#" )
    }

    function postInsert( entity ) {
        log.info( "Created #getMetadata( entity ).entityName# with ID: #entity.getId()#" )
    }

    function preUpdate( entity ) {
        log.debug( "Updating #getMetadata( entity ).entityName# ID: #entity.getId()#" )
    }

    function postUpdate( entity ) {
        log.debug( "Updated #getMetadata( entity ).entityName# ID: #entity.getId()#" )
    }

    function preDelete( entity ) {
        log.warn( "Deleting #getMetadata( entity ).entityName# ID: #entity.getId()#" )
    }

    function postDelete( entity ) {
        log.warn( "Deleted #getMetadata( entity ).entityName#" )
    }

    function preLoad( entity ) {
        // Called before entity is loaded
    }

    function postLoad( entity ) {
        // Called after entity is loaded
    }
}
```

### Entity-Level Events

```boxlang
/**
 * User.cfc with event handlers
 */
class persistent="true" extends="cborm.models.ActiveEntity" {

    property name="id" fieldType="id" generator="native"
    property name="email" ormType="string"
    property name="password" ormType="string"
    property name="slug" ormType="string"

    function preInsert() {
        // Generate slug from email
        setSlug( lCase( reReplace( getEmail(), "[^a-zA-Z0-9]", "-", "all" ) ) )

        // Hash password
        if ( len( getPassword() ) < 60 ) {
            setPassword( bcrypt( getPassword() ) )
        }
    }

    function preUpdate() {
        // Rehash password if changed
        if ( isPasswordChanged() && len( getPassword() ) < 60 ) {
            setPassword( bcrypt( getPassword() ) )
        }
    }

    function postLoad() {
        // Decrypt sensitive data
        if ( len( getSSN() ) ) {
            setSSN( decrypt( getSSN() ) )
        }
    }
}
```

## Session Management

### Session Control

```boxlang
class extends="cborm.models.BaseORMService" singleton {

    /**
     * Flush pending changes
     */
    function flushChanges() {
        ormFlush()
    }

    /**
     * Clear session cache
     */
    function clearSession() {
        ormClearSession()
    }

    /**
     * Evict entity from cache
     */
    function evictEntity( entity ) {
        ormEvictEntity( entityName: getEntityName(), entity: entity )
    }

    /**
     * Evict queries from cache
     */
    function evictQueries( cacheName ) {
        ormEvictQueries( cacheName: cacheName )
    }

    /**
     * Reload entity
     */
    function reload( entity ) {
        ormReload( entity )
        return entity
    }
}
```

## Detachment and Merging

### Working with Detached Entities

```boxlang
function handleDetachedEntity() {
    // Load entity
    var user = get( 1 )

    // Detach from session
    ormEvictEntity( entityName: "User", entity: user )

    // Modify detached entity
    user.setEmail( "newemail@example.com" )

    // Merge back to session
    var managedUser = entityMerge( user )

    // Save changes
    save( managedUser )
}
```

## Best Practices

### Service Layer Design

```boxlang
/**
 * ✅ Good: Dedicated service per entity
 */
class extends="cborm.models.BaseORMService" singleton {

    function init() {
        setEntityName( "User" )
        return this
    }

    function findActiveUsers( filters = {} ) {
        var c = newCriteria()
            .eq( "active", true )

        if ( structKeyExists( filters, "role" ) ) {
            c.eq( "role", filters.role )
        }

        return c.list()
    }
}

/**
 * ❌ Bad: Generic service for all entities
 */
class {
    function getEntity( entityName, id ) {
        return entityLoad( entityName, id )
    }
}
```

### Lazy Loading

```boxlang
// ✅ Good: Use lazy loading for associations
property name="orders"
         fieldType="one-to-many"
         cfc="Order"
         lazy="true"  // or "extra"

// ✅ Good: Eager load when needed
function getUserWithOrders( id ) {
    return newCriteria()
        .eq( "id", id )
        .joinTo( "orders", "o" )
        .get()
}

// ❌ Bad: Always eager loading
property name="orders"
         fieldType="one-to-many"
         cfc="Order"
         lazy="false"  // N+1 query problem
```

### Flushing

```boxlang
// ✅ Good: Control flush timing
class extends="cborm.models.BaseORMService" singleton transactional {

    function bulkUpdate( users ) {
        users.each( ( user ) => {
            user.setActive( true )
            save( user )
        } )

        // Flush at end
        ormFlush()
    }
}

// ❌ Bad: Letting ORM auto-flush repeatedly
function bulkUpdate( users ) {
    users.each( ( user ) => {
        save( user )  // Flushes each time
    } )
}
```

## Common Pitfalls

### N+1 Query Problem

```boxlang
// ❌ Bad: N+1 queries
function getUserOrders() {
    var users = list()

    users.each( ( user ) => {
        // Triggers separate query for each user
        var orders = user.getOrders()
    } )
}

// ✅ Good: Eager loading
function getUserOrders() {
    return newCriteria()
        .joinTo( "orders", "o" )
        .list()
}
```

### Session Leaks

```boxlang
// ✅ Good: Clear session in long-running processes
function processLargeDataset() {
    var users = list( max: 1000 )

    users.each( ( user, index ) => {
        processUser( user )

        // Clear every 100
        if ( index % 100 == 0 ) {
            ormFlush()
            ormClearSession()
        }
    } )
}
```

## Related Skills

- [Quick ORM](orm-quick.md) - Active Record ORM patterns
- [Query Builder](qb.md) - QB fluent query API
- [BoxLang Queries](../boxlang/boxlang-queries.md) - Native query patterns
- [Database Migrations](../database/migrations.md) - Schema migrations

## References

- [CBORM Documentation](https://cborm.ortusbooks.com/)
- [Hibernate ORM](https://hibernate.org/orm/documentation/)
- [ColdBox ORM](https://coldbox.ortusbooks.com/digging-deeper/orm)
