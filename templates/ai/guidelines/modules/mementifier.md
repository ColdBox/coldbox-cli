# Mementifier Module Guideline

## Overview

Mementifier is a ColdBox module that transforms business objects into native struct/array data structures (mementos) representing object state. It automatically injects `getMemento()` methods into objects, enabling fast and consistent object graph transformations for REST APIs, data serialization, and state management.

**Benefits:**
- Automatic state representation - no manual transformations
- ORM auto-detection - automatically discovers entity properties
- Flexible output profiles - multiple transformation strategies per object
- Relationship handling - control nested object serialization
- Performance optimized - fast transformations with caching

## Installation

```bash
box install mementifier
```

## Configuration

Configure in `config/ColdBox.cfc` under `moduleSettings.mementifier` or create `config/modules/mementifier.cfc`:

```javascript
moduleSettings = {
    mementifier = {
        // Use ISO8601 date/time formatting
        iso8601Format = false,
        // Default date mask
        dateMask = "yyyy-MM-dd",
        // Default time mask  
        timeMask = "HH:mm:ss",
        // Auto-detect ORM entity properties
        ormAutoIncludes = true,
        // Default value for null relationships/getters
        nullDefaultValue = "",
        // Skip getter existence checks (faster but less safe)
        trustedGetters = false,
        // Convert dates to specific timezone (e.g., "UTC", "PST")
        convertToTimezone = "",
        // Auto-cast boolean strings to Java Boolean
        autoCastBooleans = true
    }
}
```

## Usage Pattern

### 1. Declare `this.memento` Structure

Mark objects for mementifier by adding `this.memento` structure:

```javascript
component {
    
    property name="firstName"
    property name="lastName"
    property name="email"
    property name="role" // Relationship
    
    this.memento = {
        defaultIncludes = [
            "firstName",
            "lastName",
            "email",
            "role.roleName", // Nested relationship property
            "avatarLink" // Custom getter
        ],
        defaultExcludes = [
            "password",
            "apiToken"
        ],
        neverInclude = [ "password" ],
        defaults = {
            "role" : {}
        },
        mappers = {
            "lastName" : function( item, memento ) {
                return item.ucase()
            }
        }
    }
    
    string function getAvatarLink() {
        return "https://avatar.example.com/" & getEmail()
    }
}
```

### 2. Call `getMemento()`

Transform objects to mementos:

```javascript
// Basic usage
var userMemento = user.getMemento()

// Dynamic includes/excludes
var memento = user.getMemento(
    includes = "phoneNumber,address",
    excludes = "email"
)

// With profile
var exportData = user.getMemento( profile = "export" )

// Ignore defaults
var minimal = user.getMemento(
    includes = "firstName,lastName",
    ignoreDefaults = true
)
```

## Key Concepts

### Default Includes

Properties and relationships to include by default:

```javascript
defaultIncludes = [
    "firstName",
    "lastName",
    // Relationships
    "role.roleName",
    "role.roleID",
    "permissions",
    // Custom getters
    "avatarLink",
    "fullName"
]

// Auto-detect all properties
defaultIncludes = [ "*" ]
```

**Nested Relationships:**
- Use dot notation: `"role.roleName"`, `"office.address.city"`
- Only specified nested properties are included
- Prevents over-fetching relationship data

**Property Aliasing:**
- Rename in output: `"lastLoginTime:lastLogin"`
- Left side = property/getter name (without "get")
- Right side = alias in memento

### Default Excludes

Properties to exclude from memento:

```javascript
defaultExcludes = [
    "apiToken",
    "userID",
    // Nested exclusions
    "role.roleID",
    "permissions.internalData"
]
```

### Never Include

Last line of defense - always excluded even if dynamically requested:

```javascript
neverInclude = [
    "password",
    "secretKey",
    "role.permissions.systemLevel"
]
```

### Defaults

Default values for null properties:

```javascript
defaults = {
    "role" : {},
    "permissions" : [],
    "status" : "active"
}
```

**Note:** Empty arrays are default for collection relationships.

### Mappers

Transform property values post-retrieval:

```javascript
mappers = {
    // Transform existing property
    "lastName" : function( item, memento ) {
        return item.ucase()
    },
    // Create computed property
    "fullName" : function( _, memento ) {
        return memento.firstName & " " & memento.lastName
    },
    // Format dates
    "createdDate" : function( item, memento ) {
        return dateTimeFormat( item, "full" )
    }
}
```

**Parameters:**
- `item` - The property value (can be null)
- `memento` - The complete memento being built

## Output Profiles

Define multiple transformation strategies per object:

```javascript
this.memento = {
    defaultIncludes = [ "id", "name", "email" ],
    defaultExcludes = [ "detailedStats", "auditLog" ],
    
    profiles = {
        "export" : {
            defaultIncludes = [
                "detailedStats",
                "auditLog",
                "relatedRecords"
            ],
            defaultExcludes = [ "id" ]
        },
        "public" : {
            defaultIncludes = [ "name", "avatarURL" ],
            defaultExcludes = [ "email", "phoneNumber" ]
        }
    }
}

// Append base includes to profile to avoid duplication
this.memento.profiles[ "export" ].defaultIncludes.append(
    this.memento.defaultIncludes,
    true
)
```

**Usage:**

```javascript
// Basic memento
var data = user.getMemento()

// Export profile
var exportData = user.getMemento( profile = "export" )

// Public profile with extras
var publicData = user.getMemento(
    profile = "public",
    includes = "joinedDate"
)
```

**Profile Inheritance:**
- Profiles cascade through object graph
- Child objects without profile fall back to defaults

## Advanced Features

### Results Mapper

Transform arrays of objects into results map format (optimized for indexed lookups):

```javascript
property name="resultsMapper" inject="ResultsMapper@mementifier"

function list() {
    var users = userService.list()
    
    return resultsMapper.process(
        collection = users,
        id = "userID", // Unique identifier key
        includes = "role.roleName",
        excludes = "email"
    )
}

// Returns:
// {
//     "results": [ "uuid1", "uuid2", "uuid3" ],
//     "resultsMap": {
//         "uuid1": { "userID": "uuid1", "name": "John" },
//         "uuid2": { "userID": "uuid2", "name": "Jane" },
//         "uuid3": { "userID": "uuid3", "name": "Bob" }
//     }
// }
```

**Use Cases:**
- Client-side indexed lookups
- Efficient data structures for React/Vue state management
- cffractal integration

### Timezone Conversions

Convert all date/times to specific timezone:

```javascript
// Global setting
mementifier = {
    convertToTimezone = "UTC" // or "PST", "America/Los_Angeles", "GMT-8:00"
}

// Or per-object
this.memento = {
    convertToTimezone = "UTC"
}
```

### Trusted Getters

Skip getter existence checks for performance:

```javascript
// Global setting (faster but less safe)
trustedGetters = true

// Per-object
this.memento = {
    trustedGetters = true
}

// Per-call
user.getMemento( trustedGetters = true )
```

**Use When:**
- Performance critical
- You control all getters
- Objects are well-tested

### Overriding `getMemento()`

Add custom logic while preserving mementifier functionality:

```javascript
struct function getMemento(
    includes = "",
    excludes = "",
    struct mappers = {},
    struct defaults = {},
    boolean ignoreDefaults = false,
    string profile = ""
) {
    // Call mementifier
    var memento = this.$getMemento( argumentCollection = arguments )
    
    // Add custom data
    if ( hasEntryType() ) {
        memento[ "typeSlug" ] = getEntryType().getTypeSlug()
        memento[ "typeName" ] = getEntryType().getTypeName()
    }
    
    // Add computed values
    memento[ "isActive" ] = getStatus() == "active"
    
    return memento
}
```

**Pattern:**
- Original method injected as `$getMemento()`
- Call it first, then enhance the result
- Maintain method signature for consistency

## ORM Integration

Mementifier auto-detects ColdFusion ORM entities:

```javascript
component persistent="true" table="users" {
    
    property name="userID" fieldtype="id"
    property name="firstName"
    property name="lastName"
    property name="email"
    property name="role" cfc="Role" fieldtype="many-to-one"
    
    // No need to list all properties if ormAutoIncludes = true
    this.memento = {
        defaultExcludes = [
            "password"
        ],
        neverInclude = [ "password" ]
    }
}
```

**Benefits:**
- Automatically discovers all properties
- Understands relationships
- Reduces boilerplate configuration

## Best Practices

### Security

```javascript
// Always use neverInclude for sensitive data
neverInclude = [
    "password",
    "apiToken",
    "secretKey",
    "ssn"
]

// Use profiles for different access levels
profiles = {
    "admin" : {
        defaultIncludes = [ "sensitiveData" ]
    },
    "public" : {
        defaultExcludes = [ "email", "phoneNumber" ]
    }
}
```

### Performance

```javascript
// Limit nested includes - only fetch what you need
defaultIncludes = [
    "role.roleName", // Good - specific property
    // Avoid: "role" - fetches entire relationship
]

// Use results mapper for collections
var data = resultsMapper.process( users, "id" )

// Enable trusted getters for known-safe objects
this.memento = {
    trustedGetters = true
}
```

### Maintainability

```javascript
// Group related includes
defaultIncludes = [
    // Identity
    "userID",
    "username",
    "email",
    // Profile
    "firstName",
    "lastName",
    "avatarLink",
    // Relationships
    "role.roleName",
    "department.name"
]

// Use mappers for complex transformations
mappers = {
    "fullName" : function( _, memento ) {
        return memento.firstName & " " & memento.lastName
    }
}

// Document profiles
profiles = {
    "export" : {
        // Full data export including audit fields
    },
    "public" : {
        // Public API - limited data
    }
}
```

### REST API Pattern

```javascript
// handlers/api/Users.cfc
component {
    
    property name="userService" inject
    property name="resultsMapper" inject="ResultsMapper@mementifier"
    
    function index( event, rc, prc ) {
        prc.response = resultsMapper.process(
            userService.list(),
            "id",
            profile = "api"
        )
    }
    
    function show( event, rc, prc ) {
        var user = userService.get( rc.id )
        prc.response = user.getMemento( profile = "api" )
    }
    
    function export( event, rc, prc ) {
        prc.response = userService
            .list()
            .map( function( user ) {
                return user.getMemento( profile = "export" )
            } )
    }
}
```

## Common Patterns

### Computed Properties

```javascript
this.memento = {
    defaultIncludes = [
        "firstName",
        "lastName",
        "fullName", // Computed via getter
        "avatarURL" // Computed via getter
    ]
}

string function getFullName() {
    return getFirstName() & " " & getLastName()
}

string function getAvatarURL() {
    return "https://avatar.example.com/" & hash( getEmail() )
}
```

### Conditional Includes

```javascript
struct function getMemento() {
    var includes = "firstName,lastName,email"
    
    // Add admin-only fields
    if ( isUserInRole( "admin" ) ) {
        includes &= ",apiToken,lastLoginIP"
    }
    
    return this.$getMemento( includes = includes )
}
```

### Pagination with Results Mapper

```javascript
function list( event, rc, prc ) {
    var results = userService.list(
        page = rc.page ?: 1,
        pageSize = rc.pageSize ?: 20
    )
    
    prc.response = {
        "data" : resultsMapper.process( results.data, "id" ),
        "pagination" : {
            "page" : results.page,
            "pageSize" : results.pageSize,
            "totalRecords" : results.totalRecords,
            "totalPages" : results.totalPages
        }
    }
}
```

## Integration Tips

**With cffractal:**
- Use mementifier to create base memento
- Use cffractal for advanced transformations and includes

**With REST APIs:**
- Define multiple profiles per resource
- Use results mapper for collection endpoints
- Set global timezone to UTC

**With ORM:**
- Enable `ormAutoIncludes` to reduce configuration
- Be explicit about relationship includes to avoid N+1 queries
- Use profiles for different entity states (create, update, view)

**With WireBox:**
- Mementifier auto-injects on object creation
- Works with singletons, transients, and entities
- No special configuration needed

## Troubleshooting

**Missing properties in memento:**
- Check `defaultIncludes` array
- Verify getter method exists (`getPropertyName()`)
- Check `neverInclude` array
- Enable `trustedGetters = false` to see getter errors

**Null values appearing:**
- Add to `defaults` struct
- Use mappers to handle nulls
- Check getter returns value not null

**Performance issues:**
- Limit nested includes
- Enable `trustedGetters` for known objects
- Use results mapper for large collections
- Profile your transformations

**Relationships not working:**
- Use dot notation: `"role.roleName"`
- Verify relationship is loaded (avoid lazy loading issues)
- Check that nested object has `this.memento` defined

## Module Information

- **Repository:** github.com/coldbox-modules/mementifier
- **Documentation:** apidocs.ortussolutions.com/coldbox-modules/mementifier
- **ForgeBox:** forgebox.io/view/mementifier
- **Issues:** github.com/coldbox-modules/mementifier/issues
