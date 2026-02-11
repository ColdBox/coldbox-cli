---
name: Quick ORM
description: Complete guide to Quick ORM development with entity definitions, relationships, query building, eager loading, and advanced patterns
category: orm
priority: high
triggers:
  - quick orm
  - orm entity
  - active record
  - entity relationships
  - quick queries
---

# Quick ORM

## Overview

Quick is a modern, fluent, Active Record ORM for CFML/BoxLang. It provides an expressive syntax for database operations, relationships, and query building.

## Core Concepts

### Active Record Pattern

- **Entity Classes**: Models representing database tables
- **Fluent Queries**: Chainable query methods
- **Relationships**: Linking entities together
- **Scopes**: Reusable query constraints
- **Accessors/Mutators**: Attribute transformation

## Installation

```bash
box install quick
```

### Configuration

```boxlang
// config/ColdBox.cfc
moduleSettings = {
    quick: {
        defaultGrammar: "MySQLGrammar@qb",
        defaultDatasource: "appDB"
    }
}
```

## Entity Definition

### Basic Entity

```boxlang
/**
 * models/User.cfc
 */
class extends="quick.models.BaseEntity" {
    
    // Table name (optional - defaults to pluralized entity name)
    variables.table = "users"
    
    // Primary key (optional - defaults to "id")
    variables.key = "id"
    
    // Fillable attributes
    variables.fillable = [
        "firstName",
        "lastName",
        "email",
        "password"
    ]
    
    // Hidden attributes (not included in serialization)
    variables.hidden = [
        "password"
    ]
    
    // Cast attributes
    variables.casts = {
        "isActive": "boolean",
        "createdAt": "datetime",
        "settings": "json"
    }
}
```

### Entity with Relationships

```boxlang
/**
 * models/User.cfc
 */
class extends="quick.models.BaseEntity" {
    
    variables.fillable = [
        "name",
        "email"
    ]
    
    /**
     * User has many posts
     */
    function posts() {
        return hasMany( "Post" )
    }
    
    /**
     * User belongs to a role
     */
    function role() {
        return belongsTo( "Role" )
    }
    
    /**
     * User has one profile
     */
    function profile() {
        return hasOne( "Profile" )
    }
    
    /**
     * User belongs to many teams (many-to-many)
     */
    function teams() {
        return belongsTeamany( "Team" )
    }
}
```

## CRUD Operations

### Creating Records

```boxlang
// Create and save
var user = getInstance( "User" )
user.setFirstName( "John" )
user.setLastName( "Doe" )
user.setEmail( "john@example.com" )
user.save()

// Create with struct
var user = getInstance( "User" ).create( {
    firstName: "John",
    lastName: "Doe",
    email: "john@example.com"
} )

// Mass create (ignores fillable)
var user = getInstance( "User" ).forceFill( {
    id: 1,
    firstName: "John",
    email: "john@example.com",
    password: hashedPassword
} ).save()
```

### Reading Records

```boxlang
// Find by primary key
var user = getInstance( "User" ).find( 1 )

// Find or fail (throws exception)
var user = getInstance( "User" ).findOrFail( 1 )

// Find by attribute
var user = getInstance( "User" )
    .where( "email", "john@example.com" )
    .first()

// Get all records
var users = getInstance( "User" ).all()

// Get with constraints
var activeUsers = getInstance( "User" )
    .where( "isActive", true )
    .orderBy( "createdAt", "desc" )
    .get()

// Pagination
var users = getInstance( "User" )
    .orderBy( "name" )
    .paginate( page: 1, maxRows: 25 )
```

### Updating Records

```boxlang
// Find and update
var user = getInstance( "User" ).find( 1 )
user.setEmail( "newemail@example.com" )
user.save()

// Update with struct
user.update( {
    email: "newemail@example.com"
} )

// Bulk update
getInstance( "User" )
    .where( "isActive", false )
    .update( {
        status: "inactive"
    } )
```

### Deleting Records

```boxlang
// Delete instance
var user = getInstance( "User" ).find( 1 )
user.delete()

// Delete by ID
getInstance( "User" ).deleteById( 1 )

// Bulk delete
getInstance( "User" )
    .where( "createdAt", "<", dateAdd( "yyyy", -1, now() ) )
    .delete()
```

## Query Building

### Where Clauses

```boxlang
// Simple where
var users = getInstance( "User" )
    .where( "isActive", true )
    .get()

// Multiple conditions
var users = getInstance( "User" )
    .where( "isActive", true )
    .where( "role", "admin" )
    .get()

// Or where
var users = getInstance( "User" )
    .where( "role", "admin" )
    .orWhere( "role", "moderator" )
    .get()

// Where in
var users = getInstance( "User" )
    .whereIn( "id", [ 1, 2, 3 ] )
    .get()

// Where null
var users = getInstance( "User" )
    .whereNull( "deletedAt" )
    .get()

// Where between
var users = getInstance( "User" )
    .whereBetween( "createdAt", [ startDate, endDate ] )
    .get()

// Complex conditions
var users = getInstance( "User" )
    .where( ( q ) => {
        q.where( "role", "admin" )
         .orWhere( "role", "moderator" )
    } )
    .where( "isActive", true )
    .get()
```

### Ordering and Limiting

```boxlang
// Order by
var users = getInstance( "User" )
    .orderBy( "createdAt", "desc" )
    .get()

// Multiple order by
var users = getInstance( "User" )
    .orderBy( "lastName" )
    .orderBy( "firstName" )
    .get()

// Limit
var users = getInstance( "User" )
    .limit( 10 )
    .get()

// Offset
var users = getInstance( "User" )
    .offset( 20 )
    .limit( 10 )
    .get()
```

## Relationships

### Eager Loading

```boxlang
// Load relationship
var users = getInstance( "User" )
    .with( "posts" )
    .get()

// Multiple relationships
var users = getInstance( "User" )
    .with( [ "posts", "profile", "role" ] )
    .get()

// Nested relationships
var users = getInstance( "User" )
    .with( "posts.comments.author" )
    .get()

// Constrained eager loading
var users = getInstance( "User" )
    .with( {
        "posts": ( q ) => {
            q.where( "published", true )
             .orderBy( "publishedAt", "desc" )
        }
    } )
    .get()
```

### Lazy Loading

```boxlang
// Load relationship after fetching
var user = getInstance( "User" ).find( 1 )

// Access relationship (lazy loads)
var posts = user.posts().get()

// Or use property accessor
var posts = user.getPosts()
```

### Relationship Queries

```boxlang
// Query relationship
var publishedPosts = user.posts()
    .where( "published", true )
    .get()

// Count relationship
var postCount = user.posts().count()

// Check existence
var hasPosts = user.posts().exists()

// Has relationship (query users with posts)
var usersWithPosts = getInstance( "User" )
    .has( "posts" )
    .get()

// Has with condition
var usersWithPublished = getInstance( "User" )
    .has( "posts", ( q ) => {
        q.where( "published", true )
    } )
    .get()
```

## Scopes

### Local Scopes

```boxlang
/**
 * models/User.cfc
 */
class extends="quick.models.BaseEntity" {
    
    /**
     * Scope: Active users
     */
    function scopeActive( query ) {
        return arguments.query.where( "isActive", true )
    }
    
    /**
     * Scope: Users by role
     */
    function scopeRole( query, required role ) {
        return arguments.query.where( "role", arguments.role )
    }
    
    /**
     * Scope: Recent users
     */
    function scopeRecent( query, days = 7 ) {
        return arguments.query.where(
            "createdAt",
            ">=",
            dateAdd( "d", -days, now() )
        )
    }
}

// Usage
var activeUsers = getInstance( "User" )
    .active()
    .get()

var adminUsers = getInstance( "User" )
    .role( "admin" )
    .get()

var recentUsers = getInstance( "User" )
    .recent( 30 )
    .get()

// Chain scopes
var activeAdmins = getInstance( "User" )
    .active()
    .role( "admin" )
    .get()
```

### Global Scopes

```boxlang
/**
 * models/ActiveUser.cfc
 */
class extends="quick.models.BaseEntity" {
    
    variables.table = "users"
    
    /**
     * Apply global scope
     */
    function applyGlobalScopes( query ) {
        return arguments.query.where( "isActive", true )
    }
}

// All queries automatically filtered
var users = getInstance( "ActiveUser" ).all()
// SELECT * FROM users WHERE isActive = 1
```

## Accessors and Mutators

### Accessors (Getters)

```boxlang
/**
 * models/User.cfc
 */
class extends="quick.models.BaseEntity" {
    
    /**
     * Get full name
     */
    function getFullNameAttribute() {
        return "#getFirstName()# #getLastName()#"
    }
    
    /**
     * Format phone number
     */
    function getPhoneAttribute( value ) {
        return formatPhoneNumber( value )
    }
}

// Usage
var user = getInstance( "User" ).find( 1 )
var fullName = user.getFullName()
```

### Mutators (Setters)

```boxlang
/**
 * models/User.cfc
 */
class extends="quick.models.BaseEntity" {
    
    /**
     * Hash password before saving
     */
    function setPasswordAttribute( value ) {
        return bcrypt( value )
    }
    
    /**
     * Normalize email
     */
    function setEmailAttribute( value ) {
        return lCase( trim( value ) )
    }
}

// Usage
var user = getInstance( "User" )
user.setPassword( "secret" )  // Automatically hashed
user.setEmail( "  USER@EXAMPLE.COM  " )  // Normalized to user@example.com
user.save()
```

## Advanced Patterns

### Subselects

```boxlang
// Latest post per user
var users = getInstance( "User" )
    .addSubSelect(
        "lastPostDate",
        getInstance( "Post" )
            .selectRaw( "MAX(published_at)" )
            .whereColumn( "user_id", "users.id" )
    )
    .get()
```

### Query Callbacks

```boxlang
/**
 * models/User.cfc
 */
class extends="quick.models.BaseEntity" {
    
    /**
     * Before create
     */
    function preInsert( entity ) {
        entity.setCreatedAt( now() )
    }
    
    /**
     * Before update
     */
    function preUpdate( entity ) {
        entity.setUpdatedAt( now() )
    }
    
    /**
     * After save
     */
    function postSave( entity ) {
        clearCache()
    }
}
```

### Soft Deletes

```boxlang
/**
 * models/User.cfc
 */
class extends="quick.models.BaseEntity" {
    
    variables.softDeletes = true
    variables.deletedAttributeName = "deletedAt"
    
    // Queries automatically exclude soft deleted records
}

// Soft delete
user.delete()  // Sets deletedAt instead of deleting

// Force delete
user.forceDelete()

// Include soft deleted
var allUsers = getInstance( "User" )
    .withTrashed()
    .get()

// Only soft deleted
var deletedUsers = getInstance( "User" )
    .onlyTrashed()
    .get()

// Restore
user.restore()
```

## Best Practices

### Design Guidelines

1. **Entity Per Table**: One entity class per table
2. **Fillable Attributes**: Define fillable properties
3. **Hidden Attributes**: Hide sensitive data
4. **Use Scopes**: Reusable query constraints
5. **Eager Load**: Prevent N+1 queries
6. **Use Accessors**: Format on retrieval
7. **Use Mutators**: Transform on save
8. **Relationships**: Define entity relationships
9. **Cast Types**: Type casting for attributes
10. **Validate**: Validate before saving

### Common Patterns

```boxlang
// ✅ Good: Eager load relationships
var users = getInstance( "User" )
    .with( "posts" )
    .get()

// ✅ Good: Use scopes
var activeAdmins = getInstance( "User" )
    .active()
    .role( "admin" )
    .get()

// ✅ Good: Use fillable
variables.fillable = [
    "name",
    "email"
]

// ✅ Good: Hide sensitive data
variables.hidden = [
    "password",
    "apiToken"
]
```

## Common Pitfalls

### Pitfalls to Avoid

1. **N+1 Queries**: Not eager loading
2. **Mass Assignment**: No fillable protection
3. **Raw Queries**: Bypassing ORM
4. **No Validation**: Saving invalid data
5. **Circular References**: Infinite loops
6. **No Indexing**: Slow queries
7. **Select All**: Not selecting needed columns
8. **Transaction**: Not using transactions
9. **No Caching**: Repeated queries
10. **Memory Leaks**: Loading too much data

### Anti-Patterns

```boxlang
// ❌ Bad: N+1 query
var users = getInstance( "User" ).all()
for ( var user in users ) {
    var posts = user.getPosts()  // N queries
}

// ✅ Good: Eager load
var users = getInstance( "User" )
    .with( "posts" )
    .get()

// ❌ Bad: No fillable protection
var user = getInstance( "User" ).create( rc )  // Vulnerable

// ✅ Good: Define fillable
variables.fillable = [ "name", "email" ]

// ❌ Bad: Loading too much
var users = getInstance( "User" ).all()

// ✅ Good: Pagination
var users = getInstance( "User" ).paginate( 1, 25 )
```

## Related Skills

- [Query Builder](query-builder.md) - QB fluent queries
- [ORM Relationships](orm-relationships.md) - Entity relationships
- [Database Migrations](database-migrations.md) - Schema management

## References

- [Quick ORM Documentation](https://quick.ortusbooks.com/)
- [Query Builder](https://qb.ortusbooks.com/)
- [Active Record Pattern](https://en.wikipedia.org/wiki/Active_record_pattern)
