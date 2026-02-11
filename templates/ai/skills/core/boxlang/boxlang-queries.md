---
name: BoxLang Queries
description: Complete guide to BoxLang native query syntax including queryExecute, query objects, query methods, result handling, and modern query patterns
category: boxlang
priority: high
triggers:
  - boxlang queries
  - queryExecute
  - query of queries
  - native queries
  - sql queries
---

# BoxLang Queries

## Overview

BoxLang provides modern, powerful native query capabilities with `queryExecute()`, query methods, and Query of Queries (QoQ). This guide covers BoxLang's native query syntax and patterns.

## Query Execution

### Basic queryExecute

```boxlang
// Simple query
var users = queryExecute(
    "SELECT * FROM users WHERE active = :active",
    { active: true }
)

// With options
var users = queryExecute(
    "SELECT * FROM users",
    {},
    { datasource: "myDB", returntype: "array" }
)
```

### Parameter Binding

```boxlang
// Named parameters (recommended)
var user = queryExecute(
    "SELECT * FROM users WHERE email = :email AND active = :active",
    {
        email: { value: "john@example.com", cfsqltype: "cf_sql_varchar" },
        active: { value: true, cfsqltype: "cf_sql_boolean" }
    }
)

// Positional parameters
var user = queryExecute(
    "SELECT * FROM users WHERE email = ? AND active = ?",
    [
        { value: "john@example.com", cfsqltype: "cf_sql_varchar" },
        { value: true, cfsqltype: "cf_sql_boolean" }
    ]
)

// Shorthand (auto-typed)
var user = queryExecute(
    "SELECT * FROM users WHERE email = :email",
    { email: "john@example.com" }
)
```

### SQL Types

```boxlang
var params = {
    // Strings
    name: { value: "John", cfsqltype: "cf_sql_varchar" },

    // Numbers
    age: { value: 25, cfsqltype: "cf_sql_integer" },
    price: { value: 99.99, cfsqltype: "cf_sql_decimal" },

    // Dates
    birthDate: { value: createDate( 1990, 1, 1 ), cfsqltype: "cf_sql_date" },
    lastLogin: { value: now(), cfsqltype: "cf_sql_timestamp" },

    // Boolean
    active: { value: true, cfsqltype: "cf_sql_boolean" },

    // Binary
    photo: { value: imageData, cfsqltype: "cf_sql_blob" },

    // NULL
    middleName: { value: "", null: true, cfsqltype: "cf_sql_varchar" }
}
```

### Return Types

```boxlang
// Return as query object (default)
var qryUsers = queryExecute(
    "SELECT * FROM users",
    {},
    { returntype: "query" }
)

// Return as array of structs
var arrUsers = queryExecute(
    "SELECT * FROM users",
    {},
    { returntype: "array" }
)

// Return as struct (for single record)
var user = queryExecute(
    "SELECT * FROM users WHERE id = :id",
    { id: 1 },
    { returntype: "struct" }
)
```

## Query Methods

### Iteration

```boxlang
var users = queryExecute( "SELECT * FROM users" )

// For loop
for ( var row in users ) {
    echo( row.firstName & " " & row.lastName )
}

// Each method
users.each( function( row, index ) {
    echo( "#index#: #row.firstName#" )
} )

// Map
var names = users.map( function( row ) {
    return row.firstName & " " & row.lastName
} )

// Filter
var activeUsers = users.filter( function( row ) {
    return row.active == true
} )

// Reduce
var totalAge = users.reduce( function( sum, row ) {
    return sum + row.age
}, 0 )
```

### Query Manipulation

```boxlang
var users = queryExecute( "SELECT * FROM users" )

// Sort
users.sort( function( row1, row2 ) {
    return compare( row1.lastName, row2.lastName )
} )

// Slice (get subset)
var firstTen = users.slice( 1, 10 )

// Append row
queryAddRow( users )
querySetCell( users, "firstName", "John" )
querySetCell( users, "lastName", "Doe" )

// Delete row
queryDeleteRow( users, 5 )

// Get column data
var emails = queryColumnData( users, "email" )

// Column count
var colCount = users.columnCount()

// Row count
var rowCount = users.recordCount

// Column list
var columns = users.columnList()

// Column array
var columnArray = users.columnArray()
```

### Query Conversion

```boxlang
var users = queryExecute( "SELECT * FROM users" )

// Convert to array
var arrUsers = queryToArray( users )

// Convert to struct (by column)
var structUsers = queryToStruct( users, "id" )

// Convert specific columns
var emails = users.reduce( function( acc, row ) {
    acc.append( row.email )
    return acc
}, [] )
```

## Query Objects

### Creating Queries

```boxlang
// Create empty query
var qry = queryNew( "id,firstName,lastName,email", "integer,varchar,varchar,varchar" )

// Add rows
queryAddRow( qry, [
    { id: 1, firstName: "John", lastName: "Doe", email: "john@example.com" },
    { id: 2, firstName: "Jane", lastName: "Smith", email: "jane@example.com" }
] )

// Add single row
queryAddRow( qry )
querySetCell( qry, "id", 3 )
querySetCell( qry, "firstName", "Bob" )

// Get cell value
var firstName = queryGetCell( qry, "firstName", 1 )

// Get row data
var row = queryGetRow( qry, 1 )
```

### Query Metadata

```boxlang
var users = queryExecute( "SELECT * FROM users" )

// Get metadata
var metadata = getMetadata( users )

// Column info
metadata.each( function( col ) {
    echo( "Column: #col.name#, Type: #col.typeName#" )
} )

// Check if column exists
if ( users.columnExists( "email" ) ) {
    // Column exists
}
```

## Query of Queries (QoQ)

### Basic QoQ

```boxlang
// Get data
var users = queryExecute( "SELECT * FROM users" )

// Query the query
var activeUsers = queryExecute(
    "SELECT * FROM users WHERE active = :active",
    { active: true },
    { dbtype: "query" }
)
```

### Advanced QoQ

```boxlang
var users = queryExecute( "SELECT * FROM users" )
var orders = queryExecute( "SELECT * FROM orders" )

// Join queries
var result = queryExecute(
    "
        SELECT u.firstName, u.lastName, COUNT(o.id) as orderCount
        FROM users u
        LEFT JOIN orders o ON u.id = o.userId
        GROUP BY u.firstName, u.lastName
    ",
    {},
    { dbtype: "query" }
)

// Complex filtering
var filtered = queryExecute(
    "
        SELECT *
        FROM users
        WHERE (firstName LIKE :search OR lastName LIKE :search)
        AND active = :active
        ORDER BY lastName
    ",
    {
        search: "%John%",
        active: true
    },
    { dbtype: "query" }
)
```

### QoQ Aggregates

```boxlang
var orders = queryExecute( "SELECT * FROM orders" )

// Aggregate functions
var summary = queryExecute(
    "
        SELECT
            COUNT(*) as totalOrders,
            SUM(total) as totalRevenue,
            AVG(total) as avgOrderValue,
            MIN(total) as minOrder,
            MAX(total) as maxOrder
        FROM orders
    ",
    {},
    { dbtype: "query" }
)
```

## Modern Query Patterns

### Query Service Pattern

```boxlang
/**
 * UserQueryService.cfc
 */
class singleton {

    property name="dsn" inject="coldbox:setting:datasource"

    function list( filters = {} ) {
        var sql = "SELECT * FROM users WHERE 1=1"
        var params = {}

        if ( structKeyExists( filters, "active" ) ) {
            sql &= " AND active = :active"
            params.active = filters.active
        }

        if ( structKeyExists( filters, "role" ) ) {
            sql &= " AND role = :role"
            params.role = filters.role
        }

        sql &= " ORDER BY lastName, firstName"

        return queryExecute(
            sql,
            params,
            { datasource: dsn, returntype: "array" }
        )
    }

    function findByEmail( required string email ) {
        return queryExecute(
            "SELECT * FROM users WHERE email = :email",
            { email: arguments.email },
            { datasource: dsn, returntype: "struct" }
        )
    }

    function create( required struct data ) {
        queryExecute(
            "
                INSERT INTO users (firstName, lastName, email, password, createdAt)
                VALUES (:firstName, :lastName, :email, :password, :createdAt)
            ",
            {
                firstName: data.firstName,
                lastName: data.lastName,
                email: data.email,
                password: data.password,
                createdAt: now()
            },
            { datasource: dsn, result: "insertResult" }
        )

        return insertResult.generatedKey
    }

    function update( required numeric id, required struct data ) {
        queryExecute(
            "
                UPDATE users
                SET firstName = :firstName,
                    lastName = :lastName,
                    email = :email,
                    updatedAt = :updatedAt
                WHERE id = :id
            ",
            {
                id: arguments.id,
                firstName: data.firstName,
                lastName: data.lastName,
                email: data.email,
                updatedAt: now()
            },
            { datasource: dsn }
        )
    }

    function delete( required numeric id ) {
        queryExecute(
            "DELETE FROM users WHERE id = :id",
            { id: arguments.id },
            { datasource: dsn }
        )
    }
}
```

### Dynamic Query Builder

```boxlang
class singleton {

    function buildDynamicQuery( tableName, filters = {}, options = {} ) {
        var sql = "SELECT * FROM #tableName# WHERE 1=1"
        var params = {}

        // Dynamic filtering
        filters.each( function( column, value ) {
            sql &= " AND #column# = :#column#"
            params[ column ] = value
        } )

        // Sorting
        if ( structKeyExists( options, "sortBy" ) ) {
            var direction = options.sortDirection ?: "ASC"
            sql &= " ORDER BY #options.sortBy# #direction#"
        }

        // Pagination
        if ( structKeyExists( options, "limit" ) ) {
            sql &= " LIMIT #options.limit#"

            if ( structKeyExists( options, "offset" ) ) {
                sql &= " OFFSET #options.offset#"
            }
        }

        return queryExecute( sql, params )
    }

    // Usage
    function getUsers( filters ) {
        return buildDynamicQuery(
            "users",
            { active: true, role: "admin" },
            { sortBy: "lastName", limit: 25, offset: 0 }
        )
    }
}
```

### Transaction Handling

```boxlang
function transferFunds( fromAccountId, toAccountId, amount ) {
    transaction {
        try {
            // Debit from account
            queryExecute(
                "UPDATE accounts SET balance = balance - :amount WHERE id = :id",
                { amount: amount, id: fromAccountId }
            )

            // Credit to account
            queryExecute(
                "UPDATE accounts SET balance = balance + :amount WHERE id = :id",
                { amount: amount, id: toAccountId }
            )

            // Log transaction
            queryExecute(
                "
                    INSERT INTO transactions (fromAccount, toAccount, amount, createdAt)
                    VALUES (:fromAccount, :toAccount, :amount, :createdAt)
                ",
                {
                    fromAccount: fromAccountId,
                    toAccount: toAccountId,
                    amount: amount,
                    createdAt: now()
                }
            )

            transaction action="commit";

        } catch ( any e ) {
            transaction action="rollback";
            throw( message: "Transfer failed: #e.message#" )
        }
    }
}
```

### Batch Operations

```boxlang
function batchInsert( records ) {
    var sql = "
        INSERT INTO users (firstName, lastName, email)
        VALUES (:firstName, :lastName, :email)
    "

    transaction {
        try {
            records.each( function( record ) {
                queryExecute( sql, record )
            } )

            transaction action="commit";

        } catch ( any e ) {
            transaction action="rollback";
            rethrow
        }
    }
}

// Better: Use batch parameter
function batchInsertOptimized( records ) {
    var sql = "
        INSERT INTO users (firstName, lastName, email)
        VALUES (:firstName, :lastName, :email)
    "

    queryExecute(
        sql,
        records,
        { batch: true }
    )
}
```

## Advanced Patterns

### Pagination Helper

```boxlang
function paginate( sql, params = {}, page = 1, pageSize = 25 ) {
    // Get total count
    var countSql = "SELECT COUNT(*) as total FROM (#sql#) as countQuery"
    var countResult = queryExecute( countSql, params )
    var total = countResult.total

    // Calculate pagination
    var offset = ( page - 1 ) * pageSize
    var paginatedSql = "#sql# LIMIT #pageSize# OFFSET #offset#"

    // Get page data
    var data = queryExecute( paginatedSql, params, { returntype: "array" } )

    return {
        data: data,
        pagination: {
            page: page,
            pageSize: pageSize,
            total: total,
            totalPages: ceiling( total / pageSize ),
            hasNext: page < ceiling( total / pageSize ),
            hasPrevious: page > 1
        }
    }
}

// Usage
function getUsers( page = 1 ) {
    return paginate(
        "SELECT * FROM users WHERE active = :active ORDER BY lastName",
        { active: true },
        page,
        25
    )
}
```

### Result Caching

```boxlang
class singleton {

    property name="cache" inject="cachebox:default"

    function getCachedQuery( cacheKey, sql, params = {}, timeout = 60 ) {
        // Check cache
        var cached = cache.get( cacheKey )
        if ( !isNull( cached ) ) {
            return cached
        }

        // Execute query
        var result = queryExecute( sql, params, { returntype: "array" } )

        // Cache result
        cache.set( cacheKey, result, timeout )

        return result
    }

    // Usage
    function getActiveUsers() {
        return getCachedQuery(
            "activeUsers",
            "SELECT * FROM users WHERE active = :active",
            { active: true },
            60
        )
    }
}
```

### Parameterized Views

```boxlang
function getUserView( viewType, userId ) {
    var views = {
        "summary": "
            SELECT id, firstName, lastName, email
            FROM users
            WHERE id = :userId
        ",
        "detailed": "
            SELECT u.*, r.name as roleName, COUNT(o.id) as orderCount
            FROM users u
            LEFT JOIN roles r ON u.roleId = r.id
            LEFT JOIN orders o ON u.id = o.userId
            WHERE u.id = :userId
            GROUP BY u.id, r.name
        ",
        "orders": "
            SELECT u.firstName, u.lastName, o.*
            FROM users u
            JOIN orders o ON u.id = o.userId
            WHERE u.id = :userId
            ORDER BY o.createdAt DESC
        "
    }

    if ( !structKeyExists( views, viewType ) ) {
        throw( "Invalid view type: #viewType#" )
    }

    return queryExecute(
        views[ viewType ],
        { userId: userId },
        { returntype: "array" }
    )
}
```

## Best Practices

### Parameter Binding

```boxlang
// ✅ Good: Always use parameter binding
var user = queryExecute(
    "SELECT * FROM users WHERE email = :email",
    { email: userInput }
)

// ❌ Bad: SQL injection vulnerability
var user = queryExecute(
    "SELECT * FROM users WHERE email = '#userInput#'"
)
```

### Error Handling

```boxlang
// ✅ Good: Handle query errors
try {
    var users = queryExecute( "SELECT * FROM users" )
} catch ( database e ) {
    log.error( "Database error: #e.message#" )
    throw( type: "DatabaseException", message: "Failed to retrieve users" )
}
```

### Connection Management

```boxlang
// ✅ Good: Use datasource from settings
property name="dsn" inject="coldbox:setting:datasource"

function getUsers() {
    return queryExecute(
        "SELECT * FROM users",
        {},
        { datasource: dsn }
    )
}

// ❌ Bad: Hard-coded datasource
function getUsers() {
    return queryExecute(
        "SELECT * FROM users",
        {},
        { datasource: "myDB" }
    )
}
```

### Null Handling

```boxlang
// ✅ Good: Explicit null handling
var params = {
    middleName: {
        value: data.middleName ?: "",
        null: !len( data.middleName ),
        cfsqltype: "cf_sql_varchar"
    }
}

// ❌ Bad: Implicit null (may cause issues)
var params = {
    middleName: data.middleName
}
```

## Common Pitfalls

### N+1 Query Problem

```boxlang
// ❌ Bad: N+1 queries
function getUsersWithOrders() {
    var users = queryExecute( "SELECT * FROM users" )

    users.each( function( user ) {
        user.orders = queryExecute(
            "SELECT * FROM orders WHERE userId = :userId",
            { userId: user.id }
        )
    } )

    return users
}

// ✅ Good: Single join query
function getUsersWithOrders() {
    return queryExecute(
        "
            SELECT u.*, o.id as orderId, o.total, o.status
            FROM users u
            LEFT JOIN orders o ON u.id = o.userId
            ORDER BY u.id, o.createdAt
        ",
        {},
        { returntype: "array" }
    )
}
```

### Memory Issues with Large Results

```boxlang
// ❌ Bad: Load all records into memory
var allUsers = queryExecute( "SELECT * FROM users" )  // 1M+ records

// ✅ Good: Use pagination or streaming
function processAllUsers( callback ) {
    var page = 1
    var pageSize = 1000

    do {
        var batch = queryExecute(
            "SELECT * FROM users LIMIT :pageSize OFFSET :offset",
            {
                pageSize: pageSize,
                offset: ( page - 1 ) * pageSize
            }
        )

        batch.each( callback )
        page++

    } while ( batch.recordCount == pageSize )
}
```

## Related Skills

- [CBORM](../orm/cborm.md) - ORM utilities
- [Quick ORM](../orm/orm-quick.md) - Active Record ORM
- [Query Builder](../orm/qb.md) - Fluent query API
- [Database Migrations](../database/migrations.md) - Schema migrations

## References

- [BoxLang Query Documentation](https://boxlang.ortusbooks.com/essentials/queries)
- [Query Functions](https://boxlang.ortusbooks.com/reference/functions/query)
- [CFML Query Reference](https://cfdocs.org/query)
