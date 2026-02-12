---
title: QB (Query Builder) Module Guidelines
description: Fluent query builder for database-agnostic SQL generation and query construction
---

# QB (Query Builder) Module Guidelines

## Overview

QB is a fluent query builder for CFML that abstracts SQL generation and provides a database-agnostic API for building queries. It's heavily inspired by Laravel's Eloquent query builder.

## Installation

```bash
box install qb
```

## Configuration

In `config/ColdBox.cfc`:

```boxlang
moduleSettings = {
    qb = {
        // Default grammar (MySQL, Postgres, Oracle, SqlServer, SQLite)
        defaultGrammar = "MySQLGrammar@qb",
        
        // Prevent duplicate joins
        preventDuplicateJoins = false,
        
        // Strict date detection
        strictDateDetection = true,
        
        // Default numeric SQL type
        numericSQLType = "CF_SQL_NUMERIC",
        
        // Return format (array or query)
        defaultReturnFormat = "array"
    }
}
```

## Basic Usage

### Getting a Query Builder Instance

```boxlang
// Via WireBox injection
property name="qb" inject="QueryBuilder@qb";

// Direct instantiation
var qb = wirebox.getInstance( "QueryBuilder@qb" )
```

### Simple Queries

```boxlang
// Select all
var users = qb.from( "users" ).get()

// Select specific columns
var users = qb.from( "users" )
    .select( "id", "name", "email" )
    .get()

// Select with alias
var users = qb.from( "users" )
    .select( "id", "name as fullName" )
    .get()

// Get first result
var user = qb.from( "users" )
    .where( "id", 1 )
    .first()

// Get single value
var email = qb.from( "users" )
    .where( "id", 1 )
    .value( "email" )

// Count
var count = qb.from( "users" )
    .where( "active", true )
    .count()
```

## Where Clauses

### Basic Where

```boxlang
// Equals (default operator)
qb.from( "users" ).where( "active", true )

// With operator
qb.from( "users" ).where( "age", ">=", 18 )

// Multiple where clauses (AND)
qb.from( "users" )
    .where( "active", true )
    .where( "age", ">=", 18 )

// Array of conditions
qb.from( "users" ).where( [
    { column: "active", value: true },
    { column: "age", operator: ">=", value: 18 }
] )
```

### Where Variants

```boxlang
// Where In
qb.from( "users" )
    .whereIn( "id", [ 1, 2, 3, 5, 8 ] )

// Where Not In
qb.from( "users" )
    .whereNotIn( "status", [ "deleted", "banned" ] )

// Where Null
qb.from( "users" )
    .whereNull( "deleted_at" )

// Where Not Null
qb.from( "users" )
    .whereNotNull( "email_verified_at" )

// Where Between
qb.from( "users" )
    .whereBetween( "age", 18, 65 )

// Where Not Between
qb.from( "users" )
    .whereNotBetween( "score", 0, 50 )

// Where Like
qb.from( "users" )
    .whereLike( "email", "%@gmail.com" )

// Where Exists
qb.from( "users" ).whereExists( ( q ) => {
    q.select( qb.raw( 1 ) )
        .from( "orders" )
        .whereColumn( "orders.user_id", "users.id" )
} )
```

### Or Where

```boxlang
qb.from( "users" )
    .where( "active", true )
    .orWhere( "admin", true )

// Or Where In
qb.from( "users" )
    .where( "status", "active" )
    .orWhereIn( "role", [ "admin", "moderator" ] )
```

### Grouped Where Clauses

```boxlang
qb.from( "users" )
    .where( "active", true )
    .where( ( q ) => {
        q.where( "admin", true )
            .orWhere( "moderator", true )
    } )

// SQL: WHERE active = 1 AND (admin = 1 OR moderator = 1)
```

## Joins

### Basic Joins

```boxlang
// Inner join
qb.from( "users" )
    .join( "posts", "users.id", "=", "posts.user_id" )

// Left join
qb.from( "users" )
    .leftJoin( "posts", "users.id", "posts.user_id" )

// Right join
qb.from( "users" )
    .rightJoin( "posts", "users.id", "posts.user_id" )

// Cross join
qb.from( "users" )
    .crossJoin( "roles" )
```

### Advanced Joins

```boxlang
// Join with closure
qb.from( "users" )
    .join( "posts", ( j ) => {
        j.on( "users.id", "=", "posts.user_id" )
         .on( "users.tenant_id", "=", "posts.tenant_id" )
    } )

// Join with where conditions
qb.from( "users" )
    .join( "posts", ( j ) => {
        j.on( "users.id", "posts.user_id" )
         .where( "posts.published", true )
         .whereNotNull( "posts.published_at" )
    } )

// Join to subquery
var subQuery = qb.newQuery()
    .select( "user_id", "COUNT(*) as post_count" )
    .from( "posts" )
    .groupBy( "user_id" )

qb.from( "users as u" )
    .joinSub( "pc", subQuery, "u.id", "=", "pc.user_id" )
```

## Ordering & Limiting

```boxlang
// Order by
qb.from( "users" )
    .orderBy( "created_at", "desc" )

// Multiple order by
qb.from( "users" )
    .orderBy( "last_name" )
    .orderBy( "first_name" )

// Order by raw
qb.from( "users" )
    .orderByRaw( "FIELD(status, 'active', 'pending', 'inactive')" )

// Limit
qb.from( "users" )
    .limit( 10 )

// Offset
qb.from( "users" )
    .limit( 10 )
    .offset( 20 )

// Pagination shortcut
qb.from( "users" )
    .forPage( page = 3, perPage = 25 )
```

## Aggregates

```boxlang
// Count
var count = qb.from( "users" ).count()

// Count with column
var activeCount = qb.from( "users" )
    .where( "active", true )
    .count( "id" )

// Max
var maxAge = qb.from( "users" ).max( "age" )

// Min
var minAge = qb.from( "users" ).min( "age" )

// Sum
var totalRevenue = qb.from( "orders" )
    .where( "status", "completed" )
    .sum( "total" )

// Average
var avgScore = qb.from( "tests" ).avg( "score" )

// Exists
var hasUsers = qb.from( "users" )
    .where( "active", true )
    .exists()
```

## Grouping

```boxlang
// Group by
qb.from( "orders" )
    .select( "user_id", "COUNT(*) as order_count" )
    .groupBy( "user_id" )

// Multiple group by
qb.from( "sales" )
    .select( "region", "product", "SUM(amount) as total" )
    .groupBy( "region", "product" )

// Having
qb.from( "orders" )
    .select( "user_id", "COUNT(*) as order_count" )
    .groupBy( "user_id" )
    .having( "order_count", ">", 5 )

// Having with raw
qb.from( "orders" )
    .select( "user_id", "SUM(total) as revenue" )
    .groupBy( "user_id" )
    .havingRaw( "SUM(total) > 1000" )
```

## Insert

```boxlang
// Single insert
qb.table( "users" ).insert( {
    name: "John Doe",
    email: "[email protected]",
    created_at: now()
} )

// Insert and get ID
var newId = qb.table( "users" ).insertGetId( {
    name: "Jane Doe",
    email: "[email protected]"
} )

// Bulk insert
qb.table( "users" ).insert( [
    { name: "User 1", email: "[email protected]" },
    { name: "User 2", email: "[email protected]" },
    { name: "User 3", email: "[email protected]" }
] )

// Insert with SQL types
qb.table( "users" ).insert( {
    name: "John",
    age: { value: 25, cfsqltype: "CF_SQL_INTEGER" },
    balance: { value: 100.50, cfsqltype: "CF_SQL_DECIMAL", scale: 2 }
} )
```

## Update

```boxlang
// Update
qb.table( "users" )
    .where( "id", 1 )
    .update( {
        name: "Updated Name",
        updated_at: now()
    } )

// Update or insert (upsert)
qb.table( "users" ).updateOrInsert(
    // Match conditions
    { email: "[email protected]" },
    // Values to set
    { name: "John Doe", updated_at: now() }
)

// Increment
qb.table( "users" )
    .where( "id", 1 )
    .increment( "login_count" )

// Increment with amount
qb.table( "users" )
    .where( "id", 1 )
    .increment( "points", 10 )

// Decrement
qb.table( "posts" )
    .where( "id", 5 )
    .decrement( "view_count", 1 )

// Update with additional data
qb.table( "users" )
    .where( "id", 1 )
    .increment( "login_count", 1, {
        last_login: now()
    } )
```

## Delete

```boxlang
// Delete
qb.table( "users" )
    .where( "id", 1 )
    .delete()

// Delete with limit
qb.table( "old_logs" )
    .where( "created_at", "<", dateAdd( "d", -30, now() ) )
    .limit( 1000 )
    .delete()

// Truncate table
qb.table( "temp_data" ).truncate()
```

## Raw Expressions

```boxlang
// Raw select
qb.from( "users" )
    .selectRaw( "COUNT(*) as user_count, status" )
    .groupBy( "status" )

// Raw where
qb.from( "users" )
    .whereRaw( "YEAR(created_at) = ?", [ 2024 ] )

// Raw join
qb.from( "users" )
    .joinRaw( "posts ON users.id = posts.user_id AND posts.published = 1" )

// Raw order by
qb.from( "users" )
    .orderByRaw( "RAND()" )

// Raw value
qb.from( "users" ).insert( {
    name: "John",
    hash: qb.raw( "MD5('password')" )
} )
```

## Subqueries

```boxlang
// Subquery in select
qb.from( "users" )
    .selectRaw( "name" )
    .selectSub( ( q ) => {
        q.from( "orders" )
         .whereColumn( "orders.user_id", "users.id" )
         .selectRaw( "COUNT(*)" )
    }, "order_count" )

// Subquery in where
qb.from( "users" )
    .whereIn( "id", ( q ) => {
        q.from( "orders" )
         .select( "user_id" )
         .where( "total", ">", 1000 )
    } )

// Subquery in from
var subQuery = qb.newQuery()
    .from( "users" )
    .where( "active", true )

qb.fromSub( "active_users", subQuery )
    .select( "name", "email" )
```

## Conditional Queries

```boxlang
qb.from( "users" )
    .when( arguments.searchTerm, ( q, term ) => {
        q.where( "name", "LIKE", "%#term#%" )
    } )
    .when( arguments.status, ( q, status ) => {
        q.where( "status", status )
    } )
    .get()
```

## Pagination

```boxlang
// Manual pagination
var page = rc.page ?: 1
var perPage = 25

var results = qb.from( "users" )
    .where( "active", true )
    .forPage( page, perPage )
    .get()

// Get pagination info
var totalRecords = qb.from( "users" )
    .where( "active", true )
    .count()

var pagination = {
    results: results,
    page: page,
    perPage: perPage,
    totalRecords: totalRecords,
    totalPages: ceiling( totalRecords / perPage )
}
```

## Common Patterns

### Search with Filters

```boxlang
function searchUsers( struct filters = {} ) {
    var q = qb.from( "users" )
    
    // Search term
    if ( filters.keyExists( "search" ) && len( filters.search ) ) {
        q.where( ( subQuery ) => {
            subQuery.where( "name", "LIKE", "%#filters.search#%" )
                   .orWhere( "email", "LIKE", "%#filters.search#%" )
        } )
    }
    
    // Status filter
    if ( filters.keyExists( "status" ) ) {
        q.where( "status", filters.status )
    }
    
    // Date range
    if ( filters.keyExists( "startDate" ) ) {
        q.where( "created_at", ">=", filters.startDate )
    }
    
    if ( filters.keyExists( "endDate" ) ) {
        q.where( "created_at", "<=", filters.endDate )
    }
    
    return q.orderBy( "created_at", "desc" ).get()
}
```

### Repository Pattern

```boxlang
component singleton {
    property name="qb" inject="QueryBuilder@qb";
    
    function getAll() {
        return qb.from( "users" )
            .orderBy( "name" )
            .get()
    }
    
    function getById( required numeric id ) {
        return qb.from( "users" )
            .where( "id", arguments.id )
            .first()
    }
    
    function create( required struct data ) {
        var id = qb.table( "users" ).insertGetId( arguments.data )
        return getById( id )
    }
    
    function update( required numeric id, required struct data ) {
        qb.table( "users" )
            .where( "id", arguments.id )
            .update( arguments.data )
        return getById( id )
    }
    
    function delete( required numeric id ) {
        return qb.table( "users" )
            .where( "id", arguments.id )
            .delete()
    }
}
```

### Complex Reporting Query

```boxlang
function getSalesReport( required date startDate, required date endDate ) {
    return qb.from( "orders as o" )
        .select( [
            "u.name as customer_name",
            "COUNT(o.id) as order_count",
            "SUM(o.total) as total_revenue",
            "AVG(o.total) as avg_order_value"
        ] )
        .join( "users as u", "o.user_id", "u.id" )
        .whereBetween( "o.created_at", arguments.startDate, arguments.endDate )
        .where( "o.status", "completed" )
        .groupBy( "u.id", "u.name" )
        .having( "order_count", ">=", 5 )
        .orderBy( "total_revenue", "desc" )
        .get()
}
```

## Best Practices

- **Use parameter binding** - QB automatically handles SQL injection protection
- **Leverage query builder for complex queries** - Don't resort to raw SQL unless necessary
- **Use transactions** - Wrap multiple operations in transactions when needed
- **Index your columns** - Ensure proper database indexes for performance
- **Use specific selects** - Only select the columns you need
- **Paginate large result sets** - Don't load all records at once
- **Use subqueries judiciously** - They can be powerful but may impact performance
- **Test with explain** - Use database EXPLAIN to optimize slow queries

## Documentation

For complete QB documentation, query methods, and grammar-specific features, visit:
https://qb.ortusbooks.com
