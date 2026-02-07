# Quick ORM Module Guidelines

## Overview

Quick is an ActiveRecord-style ORM (Object Relational Mapper) for CFML built on top of QB. It provides an elegant, fluent interface for working with database records as objects with support for relationships, eager loading, scopes, and more.

## Installation

```bash
box install quick
```

## Configuration

In `config/ColdBox.cfc`:

```boxlang
moduleSettings = {
    quick = {
        // Default grammar
        defaultGrammar = "MySQLGrammar@qb",
        
        // Use null instead of empty strings
        nullCF = false,
        
        // Default return format
        returnFormat = "array"
    }
}
```

## Defining Entities

### Basic Entity

```boxlang
// models/User.cfc
component extends="quick.models.BaseEntity" accessors="true" {
    // Properties map to database columns
    property name="id";
    property name="username";
    property name="email";
    property name="firstName";
    property name="lastName";
    property name="createdDate";
    property name="updatedDate";
}
```

**Conventions:**
- Table name: pluralized snake_case of component name (`User` → `users`)
- Primary key: `id`
- Timestamps: `createdDate` and `updatedDate`

### Custom Table Name

```boxlang
component table="t_users" extends="quick.models.BaseEntity" {
    // ...
}
```

### Custom Primary Key

```boxlang
component extends="quick.models.BaseEntity" {
    variables._key = "user_id"
    
    // Or for composite keys
    variables._key = [ "user_id", "tenant_id" ]
}
```

### Property Attributes

```boxlang
component extends="quick.models.BaseEntity" accessors="true" {
    // Custom column name
    property name="email" column="email_address";
    
    // Read only
    property name="createdDate" readonly="true";
    
    // SQL type
    property name="age" sqltype="CF_SQL_INTEGER";
    
    // Cast to boolean
    property name="active" casts="BooleanCast@quick";
    
    // Cast to JSON
    property name="metadata" casts="JsonCast@quick";
    
    // Not persistent (excluded from DB)
    property name="fullName" persistent="false";
    
    // Insert only
    property name="uuid" insert="true" update="false";
}
```

## Retrieving Records

### Basic Retrieval

```boxlang
// Get all
var users = getInstance( "User" ).all()

// Find by ID
var user = getInstance( "User" ).find( 1 )

// Find or fail (throws exception)
var user = getInstance( "User" ).findOrFail( 1 )

// Find or return new entity
var user = getInstance( "User" ).findOrNew( 1 )

// First record
var user = getInstance( "User" ).first()

// Get specific columns
var users = getInstance( "User" )
    .select( "id", "username", "email" )
    .get()
```

### Querying

```boxlang
// Where clauses
var users = getInstance( "User" )
    .where( "active", true )
    .get()

// Multiple conditions
var users = getInstance( "User" )
    .where( "active", true )
    .where( "age", ">=", 18 )
    .orderBy( "username" )
    .get()

// Where In
var users = getInstance( "User" )
    .whereIn( "id", [ 1, 2, 3, 5 ] )
    .get()

// Where Null
var users = getInstance( "User" )
    .whereNull( "deleted_at" )
    .get()

// Limit & Offset
var users = getInstance( "User" )
    .limit( 10 )
    .offset( 20 )
    .get()

// Pagination
var users = getInstance( "User" )
    .forPage( page = 2, perPage = 25 )
    .get()
```

## Creating & Updating

### Create

```boxlang
// Create and save
var user = getInstance( "User" ).create( {
    username: "johndoe",
    email: "[email protected]",
    firstName: "John",
    lastName: "Doe"
} )

// New instance (not saved)
var user = getInstance( "User" ).new( {
    username: "johndoe"
} )
user.setEmail( "[email protected]" )
user.save()
```

### Update

```boxlang
// Find and update
var user = getInstance( "User" ).findOrFail( 1 )
user.setEmail( "[email protected]" )
user.save()

// Update with fill
var user = getInstance( "User" ).findOrFail( 1 )
user.fill( {
    email: "[email protected]",
    firstName: "Jane"
} ).save()

// Mass update
getInstance( "User" )
    .where( "active", false )
    .update( { status: "inactive" } )
```

### First Or Create

```boxlang
// Find or create
var user = getInstance( "User" ).firstOrCreate(
    { email: "[email protected]" },
    { username: "johndoe", firstName: "John" }
)

// Update or create
var user = getInstance( "User" ).updateOrCreate(
    { email: "[email protected]" },
    { firstName: "John", lastName: "Doe" }
)
```

## Deleting

```boxlang
// Delete instance
var user = getInstance( "User" ).findOrFail( 1 )
user.delete()

// Delete by query
getInstance( "User" )
    .where( "active", false )
    .delete()

// Soft deletes (if configured)
user.delete() // Sets deleted_at timestamp
user.restore() // Restores soft-deleted record
user.forceDelete() // Permanently deletes
```

## Relationships

### One-to-Many (hasMany)

```boxlang
// User has many Posts
component extends="quick.models.BaseEntity" {
    function posts() {
        return hasMany( "Post" )
    }
}

// Usage
var user = getInstance( "User" ).findOrFail( 1 )
var posts = user.getPosts()

// Add post
user.posts().save( newPost )
user.posts().create( { title: "New Post" } )
```

### Belongs To

```boxlang
// Post belongs to User
component extends="quick.models.BaseEntity" {
    function user() {
        return belongsTo( "User" )
    }
}

// Usage
var post = getInstance( "Post" ).findOrFail( 1 )
var user = post.getUser()

// Associate
post.user().associate( user )
post.save()

// Dissociate
post.user().dissociate()
post.save()
```

### Has One

```boxlang
// User has one Profile
component extends="quick.models.BaseEntity" {
    function profile() {
        return hasOne( "Profile" )
    }
}

// Usage
var user = getInstance( "User" ).findOrFail( 1 )
var profile = user.getProfile()

// Create profile
user.profile().create( { bio: "Developer" } )
```

### Many-to-Many (belongsToMany)

```boxlang
// User belongs to many Roles
component extends="quick.models.BaseEntity" {
    function roles() {
        return belongsToMany( "Role" )
    }
}

// Role belongs to many Users
component extends="quick.models.BaseEntity" {
    function users() {
        return belongsToMany( "User" )
    }
}

// Usage
var user = getInstance( "User" ).findOrFail( 1 )
var roles = user.getRoles()

// Attach roles
user.roles().attach( roleId )
user.roles().attach( [ roleId1, roleId2 ] )

// Detach roles
user.roles().detach( roleId )
user.roles().detach() // Detach all

// Sync roles (detach others)
user.roles().sync( [ 1, 2, 3 ] )
```

### Custom Relationship Keys

```boxlang
// Custom foreign key
function posts() {
    return hasMany( "Post", "author_id" )
}

// Custom local key
function posts() {
    return hasMany( "Post", "user_id", "custom_id" )
}

// Custom pivot table
function roles() {
    return belongsToMany(
        "Role",
        "user_roles", // pivot table
        "user_id",    // foreign pivot key
        "role_id"     // related pivot key
    )
}
```

## Eager Loading

Prevent N+1 query problems:

```boxlang
// Eager load relationship
var users = getInstance( "User" )
    .with( "posts" )
    .get()

// Multiple relationships
var users = getInstance( "User" )
    .with( [ "posts", "profile", "roles" ] )
    .get()

// Nested relationships
var users = getInstance( "User" )
    .with( "posts.comments" )
    .get()

// Constrained eager loading
var users = getInstance( "User" )
    .with( {
        "posts": ( q ) => {
            q.where( "published", true )
             .orderBy( "created_at", "desc" )
             .limit( 5 )
        }
    } )
    .get()

// Count relationships
var users = getInstance( "User" )
    .withCount( "posts" )
    .get()

// Each user now has posts_count property
```

## Query Scopes

Reusable query logic:

```boxlang
// Define scope
component extends="quick.models.BaseEntity" {
    function scopeActive( query ) {
        return query.where( "active", true )
    }
    
    function scopeSearch( query, term ) {
        return query.where( ( q ) => {
            q.where( "username", "LIKE", "%#term#%" )
             .orWhere( "email", "LIKE", "%#term#%" )
        } )
    }
    
    function scopeRecent( query ) {
        return query.orderBy( "created_at", "desc" )
    }
}

// Usage
var users = getInstance( "User" )
    .active()
    .search( "john" )
    .recent()
    .get()
```

## Accessors & Mutators

### Accessors (Getters)

```boxlang
component extends="quick.models.BaseEntity" {
    property name="firstName";
    property name="lastName";
    
    // Accessor for full name
    function getFullNameAttribute() {
        return "#getFirstName()# #getLastName()#"
    }
}

// Usage
var user = getInstance( "User" ).first()
var fullName = user.getFullName()
```

### Mutators (Setters)

```boxlang
component extends="quick.models.BaseEntity" {
    property name="email";
    
    // Always lowercase email
    function setEmailAttribute( value ) {
        return lcase( trim( value ) )
    }
}

// Usage
user.setEmail( "  JOHN@EXAMPLE.COM  " )
// Saved as: "john@example.com"
```

## Subselect Properties

```boxlang
component extends="quick.models.BaseEntity" {
    function scopeWithPostCount( query ) {
        return query.addSubselect( "post_count", ( q ) => {
            q.from( "posts" )
             .whereColumn( "posts.user_id", "users.id" )
             .selectRaw( "COUNT(*)" )
        } )
    }
}

// Usage
var users = getInstance( "User" )
    .withPostCount()
    .get()

// Each user now has post_count property
```

## Events/Lifecycle Hooks

```boxlang
component extends="quick.models.BaseEntity" {
    // Before creating
    function preInsert( entity ) {
        entity.setUuid( createUUID() )
    }
    
    // After creating
    function postInsert( entity ) {
        log.info( "User created: #entity.getId()#" )
    }
    
    // Before updating
    function preUpdate( entity ) {
        entity.setUpdatedDate( now() )
    }
    
    // After updating
    function postUpdate( entity ) {
        // Clear cache
    }
    
    // Before deleting
    function preDelete( entity ) {
        // Archive data
    }
    
    // After deleting
    function postDelete( entity ) {
        // Cleanup related data
    }
}
```

## Global Scopes

Apply to all queries automatically:

```boxlang
component extends="quick.models.BaseEntity" {
    function applyGlobalScopes( query ) {
        query.where( "tenant_id", getTenantId() )
    }
}

// All queries automatically include tenant filter
var users = getInstance( "User" ).get()
// WHERE tenant_id = ?
```

## Repository Pattern

```boxlang
component singleton {
    property name="wirebox" inject="wirebox";
    
    function new() {
        return wirebox.getInstance( "User" )
    }
    
    function all() {
        return new().all()
    }
    
    function find( required id ) {
        return new().findOrFail( arguments.id )
    }
    
    function getActive() {
        return new()
            .active()
            .orderBy( "username" )
            .get()
    }
    
    function search( required string term, numeric page = 1 ) {
        return new()
            .search( arguments.term )
            .forPage( arguments.page, 25 )
            .get()
    }
    
    function create( required struct data ) {
        return new().create( arguments.data )
    }
    
    function update( required id, required struct data ) {
        var user = find( arguments.id )
        user.fill( arguments.data ).save()
        return user
    }
    
    function delete( required id ) {
        var user = find( arguments.id )
        user.delete()
    }
}
```

## Service Layer Integration

```boxlang
component singleton {
    property name="userRepo" inject="UserRepository";
    property name="log" inject="logbox:logger:{this}";
    
    function register( required struct data ) {
        transaction {
            try {
                // Hash password
                data.password = bcrypt.hashPassword( data.password )
                
                // Create user
                var user = userRepo.create( data )
                
                // Assign default role
                var defaultRole = getInstance( "Role" )
                    .where( "name", "user" )
                    .first()
                user.roles().attach( defaultRole.getId() )
                
                // Send welcome email
                mailService.sendWelcome( user )
                
                log.info( "User registered: #user.getEmail()#" )
                
                return user
            } catch ( any e ) {
                transaction action="rollback"
                log.error( "Registration failed", e )
                rethrow
            }
        }
    }
}
```

## Common Patterns

### Soft Deletes

```boxlang
component extends="quick.models.BaseEntity" {
    variables._softDeletes = true
    variables._softDeleteColumn = "deleted_at"
    
    // Soft deleted records excluded by default
}

// Include soft deleted
var users = getInstance( "User" )
    .withTrashed()
    .get()

// Only soft deleted
var users = getInstance( "User" )
    .onlyTrashed()
    .get()
```

### UUID Keys

```boxlang
component extends="quick.models.BaseEntity" {
    variables._keyType = "UUID"
    
    function keyType() {
        return wirebox.getInstance( "UUIDKeyType@quick" )
    }
}
```

### Multi-Tenancy

```boxlang
component extends="quick.models.BaseEntity" {
    property name="tenantId";
    
    function applyGlobalScopes( query ) {
        query.where( "tenant_id", session.tenantId )
    }
    
    function preInsert( entity ) {
        entity.setTenantId( session.tenantId )
    }
}
```

## Best Practices

- **Use repositories** - Abstract entity access in repository classes
- **Eager load relationships** - Prevent N+1 queries with `with()`
- **Use scopes** - Encapsulate reusable query logic
- **Leverage accessors** - Compute derived properties
- **Use transactions** - Wrap multi-step operations
- **Define relationships** - Use hasMany, belongsTo, etc.
- **Use query scopes** - Keep queries DRY and readable
- **Avoid mass assignment vulnerabilities** - Validate input data
- **Index foreign keys** - Ensure proper database indexes

## Documentation

For complete Quick ORM documentation, relationships, and advanced features, visit:
https://quick.ortusbooks.com
