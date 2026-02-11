---
name: BoxLang JDBC and Queries
description: Complete guide to database queries and JDBC connections in BoxLang with query syntax, transactions, datasources, and result handling
category: boxlang
priority: high
triggers:
  - boxlang query
  - jdbc
  - database query
  - query execute
  - datasource
  - sql
---

# BoxLang JDBC and Queries

## Overview

BoxLang provides powerful database query capabilities through JDBC with native query syntax, query objects, and transaction support. It supports all major databases with optimized connection pooling.

## Core Concepts

### Query Features

- **Native Query Syntax**: Built-in query blocks
- **Query Objects**: Programmatic query building
- **Transactions**: ACID compliance
- **Connection Pooling**: Automatic management
- **Multiple Databases**: MySQL, PostgreSQL, MSSQL, Oracle

## Datasource Configuration

### Application.bx Configuration

```boxlang
/**
 * Application.bx
 */
class {

    this.name = "MyApp"

    // Default datasource
    this.datasource = "appDB"

    // Datasource definitions
    this.datasources = {
        "appDB": {
            class: "com.mysql.cj.jdbc.Driver",
            connectionString: "jdbc:mysql://localhost:3306/mydb",
            username: "root",
            password: "password"
        },
        "postgresDB": {
            class: "org.postgresql.Driver",
            connectionString: "jdbc:postgresql://localhost:5432/mydb",
            username: "postgres",
            password: "password"
        }
    }

    // Connection pool settings
    this.datasourceSettings = {
        maxConnections: 50,
        timeout: 30000,
        testQuery: "SELECT 1"
    }
}
```

### Environment Variables

```boxlang
// Use environment variables for security
this.datasources = {
    "appDB": {
        class: "com.mysql.cj.jdbc.Driver",
        connectionString: getEnv( "DB_CONNECTION_STRING" ),
        username: getEnv( "DB_USERNAME" ),
        password: getEnv( "DB_PASSWORD" )
    }
}
```

## Query Syntax

### Basic Queries

```boxlang
// Simple select
var users = queryExecute(
    "SELECT * FROM users WHERE isActive = :active",
    { active: true }
)

// With datasource
var users = queryExecute(
    "SELECT * FROM users",
    {},
    { datasource: "appDB" }
)

// Get single value
var count = queryExecute(
    "SELECT COUNT(*) as total FROM users",
    {},
    { returnType: "array" }
)[1].total
```

### Query Parameters

```boxlang
// Named parameters (recommended)
var user = queryExecute(
    "SELECT * FROM users WHERE email = :email AND isActive = :active",
    {
        email: "john@example.com",
        active: true
    }
)

// Positional parameters
var user = queryExecute(
    "SELECT * FROM users WHERE email = ? AND isActive = ?",
    [ "john@example.com", true ]
)

// Typed parameters
var users = queryExecute(
    "SELECT * FROM users WHERE createdAt > :date",
    {
        date: {
            value: dateAdd( "d", -7, now() ),
            cfsqltype: "CF_SQL_TIMESTAMP"
        }
    }
)
```

### Query Block Syntax

```boxlang
// Native query block
query name="users" datasource="appDB" {
    writeOutput( "
        SELECT id, firstName, lastName, email
        FROM users
        WHERE isActive = 1
        ORDER BY lastName, firstName
    " )
}

// With parameters
query name="user" datasource="appDB" {
    writeOutput( "
        SELECT *
        FROM users
        WHERE email = "
    )
    queryparam value="#email#" cfsqltype="CF_SQL_VARCHAR"
}

// Multiple parameters
query name="results" {
    writeOutput( "
        SELECT *
        FROM orders
        WHERE userId = "
    )
    queryparam value="#userId#" cfsqltype="CF_SQL_INTEGER"
    writeOutput( " AND createdAt BETWEEN " )
    queryparam value="#startDate#" cfsqltype="CF_SQL_TIMESTAMP"
    writeOutput( " AND " )
    queryparam value="#endDate#" cfsqltype="CF_SQL_TIMESTAMP"
}
```

## Working with Results

### Result Metadata

```boxlang
// Get result info
var users = queryExecute( "SELECT * FROM users" )

println( users.recordCount )      // Number of rows
println( users.columnList )       // Column names
println( users.currentRow )       // Current row position

// Get column metadata
var metadata = getMetadata( users )
println( metadata.getColumnCount() )
println( metadata.getColumnName( 1 ) )
println( metadata.getColumnType( 1 ) )
```

### Iterating Results

```boxlang
// Loop through query
var users = queryExecute( "SELECT * FROM users" )

for ( var user in users ) {
    println( user.firstName & " " & user.lastName )
    println( user.email )
}

// Using each()
users.each( ( row ) => {
    println( row.firstName )
} )

// Row index
for ( var i = 1; i <= users.recordCount; i++ ) {
    println( users.firstName[i] )
}
```

### Converting Results

```boxlang
// To array of structs
var usersArray = queryExecute(
    "SELECT * FROM users",
    {},
    { returnType: "array" }
)

// Manual conversion
var users = queryExecute( "SELECT * FROM users" )
var usersArray = []

for ( var row in users ) {
    usersArray.append( {
        id: row.id,
        name: row.firstName & " " & row.lastName,
        email: row.email
    } )
}

// To JSON
var usersJSON = serializeJSON( users )
```

## CRUD Operations

### Insert

```boxlang
// Insert single record
queryExecute(
    "INSERT INTO users (firstName, lastName, email, password)
     VALUES (:firstName, :lastName, :email, :password)",
    {
        firstName: "John",
        lastName: "Doe",
        email: "john@example.com",
        password: bcrypt( "password" )
    }
)

// Get generated key
var result = queryExecute(
    "INSERT INTO users (firstName, email)
     VALUES (:firstName, :email)",
    {
        firstName: "John",
        email: "john@example.com"
    },
    { result: "insertResult" }
)

var newID = result.generatedKey
```

### Update

```boxlang
// Update records
queryExecute(
    "UPDATE users
     SET email = :email, updatedAt = :now
     WHERE id = :id",
    {
        email: "newemail@example.com",
        now: now(),
        id: 1
    }
)

// Get affected rows
var result = queryExecute(
    "UPDATE users SET isActive = 0 WHERE lastLoginAt < :date",
    { date: dateAdd( "yyyy", -1, now() ) },
    { result: "updateResult" }
)

println( "Updated #result.recordCount# users" )
```

### Delete

```boxlang
// Delete records
queryExecute(
    "DELETE FROM users WHERE id = :id",
    { id: 1 }
)

// Soft delete
queryExecute(
    "UPDATE users SET deletedAt = :now WHERE id = :id",
    {
        now: now(),
        id: 1
    }
)
```

### Bulk Operations

```boxlang
// Batch insert
transaction {
    var users = [
        { firstName: "John", email: "john@example.com" },
        { firstName: "Jane", email: "jane@example.com" },
        { firstName: "Bob", email: "bob@example.com" }
    ]

    users.each( ( user ) => {
        queryExecute(
            "INSERT INTO users (firstName, email) VALUES (:firstName, :email)",
            user
        )
    } )
}
```

## Transactions

### Basic Transactions

```boxlang
// Transaction block
transaction {
    queryExecute(
        "UPDATE accounts SET balance = balance - :amount WHERE id = :fromId",
        { amount: 100, fromId: 1 }
    )

    queryExecute(
        "UPDATE accounts SET balance = balance + :amount WHERE id = :toId",
        { amount: 100, toId: 2 }
    )
}

// With error handling
try {
    transaction {
        queryExecute( "INSERT INTO users ..." )
        queryExecute( "INSERT INTO profiles ..." )

        // Commit happens automatically
    }
} catch ( any e ) {
    // Rollback happens automatically
    writeLog( "Transaction failed: #e.message#" )
    rethrow
}
```

### Transaction Control

```boxlang
// Manual transaction control
transaction action="begin" {
    try {
        queryExecute( "UPDATE users ..." )
        queryExecute( "UPDATE profiles ..." )

        transaction action="commit"

    } catch ( any e ) {
        transaction action="rollback"
        writeLog( e.message )
    }
}

// Savepoints
transaction {
    queryExecute( "INSERT INTO users ..." )

    transaction action="setsavepoint" savepoint="beforeUpdate"

    queryExecute( "UPDATE users ..." )

    if ( errorOccurred ) {
        transaction action="rollback" savepoint="beforeUpdate"
    }
}
```

### Isolation Levels

```boxlang
// Set isolation level
transaction isolation="read_committed" {
    var users = queryExecute( "SELECT * FROM users" )
    // Process users
}

// Available isolation levels:
// - read_uncommitted
// - read_committed
// - repeatable_read
// - serializable
```

## Advanced Queries

### Stored Procedures

```boxlang
// Call stored procedure
var result = storedProc(
    procedure: "sp_GetUserOrders",
    datasource: "appDB",
    params: [
        { name: "userId", value: 1, type: "IN", cfsqltype: "CF_SQL_INTEGER" },
        { name: "startDate", value: startDate, type: "IN", cfsqltype: "CF_SQL_DATE" },
        { name: "orderCount", type: "OUT", cfsqltype: "CF_SQL_INTEGER", variable: "count" }
    ],
    returnType: "query"
)

println( "Found #count# orders" )
```

### Dynamic Queries

```boxlang
// Build dynamic WHERE clause
function searchUsers( filters = {} ) {
    var sql = "SELECT * FROM users WHERE 1=1"
    var params = {}

    if ( filters.keyExists( "name" ) ) {
        sql &= " AND (firstName LIKE :name OR lastName LIKE :name)"
        params.name = "%#filters.name#%"
    }

    if ( filters.keyExists( "active" ) ) {
        sql &= " AND isActive = :active"
        params.active = filters.active
    }

    sql &= " ORDER BY lastName"

    return queryExecute( sql, params )
}

// Usage
var users = searchUsers( { name: "John", active: true } )
```

### Pagination

```boxlang
function getUsersPaginated( page = 1, pageSize = 25 ) {
    var offset = ( page - 1 ) * pageSize

    var users = queryExecute(
        "SELECT * FROM users
         ORDER BY lastName
         LIMIT :limit OFFSET :offset",
        {
            limit: pageSize,
            offset: offset
        },
        { returnType: "array" }
    )

    var total = queryExecute(
        "SELECT COUNT(*) as total FROM users",
        {},
        { returnType: "array" }
    )[1].total

    return {
        data: users,
        page: page,
        pageSize: pageSize,
        total: total,
        pages: ceiling( total / pageSize )
    }
}
```

## Query of Queries

### QoQ Syntax

```boxlang
// Query existing result set
var users = queryExecute( "SELECT * FROM users" )

// Filter in memory
var activeUsers = queryExecute(
    "SELECT * FROM users WHERE isActive = 1",
    {},
    { dbtype: "query", users: users }
)

// Join queries
var orders = queryExecute( "SELECT * FROM orders" )

var result = queryExecute(
    "SELECT u.firstName, u.lastName, o.orderDate
     FROM users u
     INNER JOIN orders o ON u.id = o.userId",
    {},
    { dbtype: "query", users: users, orders: orders }
)
```

## Best Practices

### Design Guidelines

1. **Use Parameters**: Always use query params
2. **Connection Pooling**: Configure appropriately
3. **Transactions**: Use for multi-statement operations
4. **Error Handling**: Catch and log database errors
5. **Indexes**: Index frequently queried columns
6. **Avoid N+1**: Use JOINs instead of loops
7. **Limit Results**: Use LIMIT/TOP for large datasets
8. **SQL Injection**: Never concatenate user input
9. **Test Queries**: Profile slow queries
10. **Close Resources**: Let BoxLang manage connections

### Common Patterns

```boxlang
// ✅ Good: Parameterized query
queryExecute(
    "SELECT * FROM users WHERE email = :email",
    { email: userEmail }
)

// ✅ Good: Transaction for related operations
transaction {
    queryExecute( "INSERT INTO orders ..." )
    queryExecute( "INSERT INTO order_items ..." )
}

// ✅ Good: Pagination
queryExecute(
    "SELECT * FROM users LIMIT :limit OFFSET :offset",
    { limit: pageSize, offset: ( page - 1 ) * pageSize }
)
```

## Common Pitfalls

### Pitfalls to Avoid

1. **SQL Injection**: Concatenating user input
2. **No Timeouts**: Long-running queries
3. **Missing Indexes**: Slow queries
4. **N+1 Queries**: Query in a loop
5. **No Error Handling**: Unhandled exceptions
6. **Hardcoded Credentials**: Security risk
7. **No Connection Pooling**: Performance issues
8. **Large Result Sets**: Memory problems
9. **No Transactions**: Data inconsistency
10. **Ignoring NULL**: Improper NULL handling

### Anti-Patterns

```boxlang
// ❌ Bad: SQL injection vulnerability
queryExecute( "SELECT * FROM users WHERE email = '#email#'" )

// ✅ Good: Use parameters
queryExecute(
    "SELECT * FROM users WHERE email = :email",
    { email: email }
)

// ❌ Bad: N+1 query problem
var users = queryExecute( "SELECT * FROM users" )
for ( var user in users ) {
    var orders = queryExecute(
        "SELECT * FROM orders WHERE userId = :id",
        { id: user.id }
    )
}

// ✅ Good: Use JOIN
var result = queryExecute(
    "SELECT u.*, o.*
     FROM users u
     LEFT JOIN orders o ON u.id = o.userId"
)

// ❌ Bad: No transaction for related inserts
queryExecute( "INSERT INTO orders ..." )
queryExecute( "INSERT INTO order_items ..." )  // Could fail

// ✅ Good: Use transaction
transaction {
    queryExecute( "INSERT INTO orders ..." )
    queryExecute( "INSERT INTO order_items ..." )
}
```

## Related Skills

- [Database Migrations](database-migrations.md) - Schema management
- [Quick ORM](orm-quick.md) - ORM patterns
- [Query Builder](query-builder.md) - QB fluent API

## References

- [BoxLang Query Documentation](https://boxlang.ortusbooks.com/)
- [JDBC Drivers](https://jdbc.postgresql.org/)
- [SQL Injection Prevention](https://owasp.org/www-community/attacks/SQL_Injection)
