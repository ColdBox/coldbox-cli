---
name: Query Builder (QB)
description: Complete guide to QB fluent query builder API for SQL queries, joins, aggregates, subqueries, CTEs, and database-agnostic query construction
category: orm
priority: high
triggers:
  - query builder
  - qb
  - sql builder
  - fluent queries
  - query api
---

# Query Builder (QB)

## Overview

QB is a fluent, database-agnostic query builder for CFML/BoxLang. It provides an expressive, chainable API for building SQL queries without writing raw SQL, supporting multiple database grammars.

## Installation

```bash
box install qb
```

## Configuration

### config/ColdBox.cfc

```boxlang
moduleSettings = {
    qb: {
        defaultGrammar: "MySQLGrammar",
        defaultDatasource: "appDB"
    }
}
```

### Module Settings

```boxlang
moduleSettings = {
    qb: {
        defaultGrammar: "MySQLGrammar",  // or PostgresGrammar, MSSQLGrammar, OracleGrammar
        defaultDatasource: "myDataSource",
        returnFormat: "query",  // or "array"
        columnFormatter: function( column ) {
            // Transform column names
            return column
        },
        strictDateDetection: false
    }
}
```

## Basic Queries

### SELECT Queries

```boxlang
property name="qb" inject="QueryBuilder@qb"

function getUsers() {
    return qb.from( "users" )
        .get()
}

function getActiveUsers() {
    return qb.from( "users" )
        .where( "active", 1 )
        .get()
}

function getUserColumns() {
    return qb.select( "id", "firstName", "lastName", "email" )
        .from( "users" )
        .get()
}

// Using array for columns
function getUsers() {
    return qb.select( [ "id", "firstName", "lastName" ] )
        .from( "users" )
        .get()
}
```

### WHERE Clauses

```boxlang
// Basic where
qb.from( "users" )
    .where( "active", 1 )
    .get()

// Where with operator
qb.from( "users" )
    .where( "age", ">=", 21 )
    .get()

// Multiple where conditions (AND)
qb.from( "users" )
    .where( "active", 1 )
    .where( "role", "admin" )
    .get()

// OR conditions
qb.from( "users" )
    .where( "role", "admin" )
    .orWhere( "role", "manager" )
    .get()

// Where IN
qb.from( "users" )
    .whereIn( "role", [ "admin", "manager", "supervisor" ] )
    .get()

// Where NOT IN
qb.from( "users" )
    .whereNotIn( "status", [ "deleted", "banned" ] )
    .get()

// Where NULL
qb.from( "users" )
    .whereNull( "deletedAt" )
    .get()

// Where NOT NULL
qb.from( "users" )
    .whereNotNull( "emailVerifiedAt" )
    .get()

// Where BETWEEN
qb.from( "orders" )
    .whereBetween( "total", [ 100, 500 ] )
    .get()

// Where LIKE
qb.from( "users" )
    .where( "email", "like", "%@gmail.com" )
    .get()
```

### Advanced WHERE

```boxlang
// Where with closure (grouping)
qb.from( "users" )
    .where( "active", 1 )
    .where( function( q ) {
        q.where( "role", "admin" )
         .orWhere( "role", "manager" )
    } )
    .get()

// Complex conditions
qb.from( "users" )
    .where( function( q ) {
        q.where( "firstName", "like", "%John%" )
         .orWhere( "lastName", "like", "%John%" )
    } )
    .where( "active", 1 )
    .get()

// Where EXISTS
qb.from( "users" )
    .whereExists( function( q ) {
        q.select( qb.raw( 1 ) )
         .from( "orders" )
         .whereColumn( "orders.userId", "users.id" )
    } )
    .get()

// Where NOT EXISTS
qb.from( "users" )
    .whereNotExists( function( q ) {
        q.select( qb.raw( 1 ) )
         .from( "orders" )
         .whereColumn( "orders.userId", "users.id" )
    } )
    .get()

// Where Column (compare columns)
qb.from( "users" )
    .whereColumn( "firstName", "lastName" )
    .get()

// Where Column with operator
qb.from( "orders" )
    .whereColumn( "subtotal", "<", "total" )
    .get()
```

### ORDER BY and LIMIT

```boxlang
// Order by
qb.from( "users" )
    .orderBy( "lastName" )
    .get()

// Order by descending
qb.from( "users" )
    .orderBy( "createdAt", "desc" )
    .get()

// Multiple order by
qb.from( "users" )
    .orderBy( "lastName" )
    .orderBy( "firstName" )
    .get()

// Limit
qb.from( "users" )
    .limit( 10 )
    .get()

// Limit with offset
qb.from( "users" )
    .limit( 10 )
    .offset( 20 )
    .get()

// Pagination helper
qb.from( "users" )
    .forPage( page: 3, maxRows: 25 )
    .get()
```

### DISTINCT and GROUP BY

```boxlang
// Distinct
qb.from( "users" )
    .distinct()
    .select( "department" )
    .get()

// Group by
qb.from( "orders" )
    .select( "userId" )
    .selectRaw( "COUNT(*) as orderCount" )
    .groupBy( "userId" )
    .get()

// Group by with HAVING
qb.from( "orders" )
    .select( "userId" )
    .selectRaw( "SUM(total) as totalSpent" )
    .groupBy( "userId" )
    .having( "totalSpent", ">", 1000 )
    .get()
```

## JOINS

### Basic Joins

```boxlang
// Inner join
qb.from( "users" )
    .join( "orders", "users.id", "orders.userId" )
    .select( "users.*", "orders.total" )
    .get()

// Left join
qb.from( "users" )
    .leftJoin( "orders", "users.id", "orders.userId" )
    .get()

// Right join
qb.from( "users" )
    .rightJoin( "orders", "users.id", "orders.userId" )
    .get()

// Cross join
qb.from( "sizes" )
    .crossJoin( "colors" )
    .get()
```

### Advanced Joins

```boxlang
// Join with closure
qb.from( "users" )
    .join( "orders", function( j ) {
        j.on( "users.id", "orders.userId" )
         .where( "orders.status", "completed" )
    } )
    .get()

// Multiple join conditions
qb.from( "users" )
    .join( "orders", function( j ) {
        j.on( "users.id", "orders.userId" )
         .on( "users.accountId", "orders.accountId" )
    } )
    .get()

// Join with OR
qb.from( "users" )
    .join( "contacts", function( j ) {
        j.on( "users.email", "contacts.email" )
         .orOn( "users.phone", "contacts.phone" )
    } )
    .get()

// Join subquery
qb.from( "users" )
    .joinSub( "recentOrders", function( q ) {
        q.from( "orders" )
         .where( "createdAt", ">=", dateAdd( "d", -30, now() ) )
    }, "users.id", "recentOrders.userId" )
    .get()
```

## Aggregates

### Aggregate Functions

```boxlang
// Count
var userCount = qb.from( "users" ).count()

// Count distinct
var distinctDepartments = qb.from( "users" )
    .distinct()
    .count( "department" )

// Sum
var totalRevenue = qb.from( "orders" )
    .sum( "total" )

// Average
var avgOrderValue = qb.from( "orders" )
    .avg( "total" )

// Min
var minPrice = qb.from( "products" )
    .min( "price" )

// Max
var maxPrice = qb.from( "products" )
    .max( "price" )
```

### Aggregate with WHERE

```boxlang
// Count active users
var activeUsers = qb.from( "users" )
    .where( "active", 1 )
    .count()

// Sum of completed orders
var completedTotal = qb.from( "orders" )
    .where( "status", "completed" )
    .sum( "total" )

// Average age of admins
var avgAge = qb.from( "users" )
    .where( "role", "admin" )
    .avg( "age" )
```

## INSERT, UPDATE, DELETE

### INSERT

```boxlang
// Insert single record
qb.table( "users" )
    .insert( {
        firstName: "John",
        lastName: "Doe",
        email: "john@example.com",
        createdAt: now()
    } )

// Insert multiple records
qb.table( "users" )
    .insert( [
        { firstName: "John", email: "john@example.com" },
        { firstName: "Jane", email: "jane@example.com" }
    ] )

// Insert and get ID
var newId = qb.table( "users" )
    .insertGetId( {
        firstName: "John",
        email: "john@example.com"
    } )
```

### UPDATE

```boxlang
// Update with where
qb.table( "users" )
    .where( "id", 1 )
    .update( {
        email: "newemail@example.com",
        updatedAt: now()
    } )

// Update multiple records
qb.table( "users" )
    .where( "active", 0 )
    .update( { status: "inactive" } )

// Update or insert (upsert)
qb.table( "users" )
    .updateOrInsert(
        { email: "john@example.com" },
        { firstName: "John", lastName: "Doe" }
    )

// Increment
qb.table( "users" )
    .where( "id", 1 )
    .increment( "loginCount" )

// Decrement
qb.table( "products" )
    .where( "id", 1 )
    .decrement( "stock", 5 )
```

### DELETE

```boxlang
// Delete with where
qb.table( "users" )
    .where( "id", 1 )
    .delete()

// Delete multiple records
qb.table( "users" )
    .where( "active", 0 )
    .where( "lastLogin", "<", dateAdd( "yyyy", -1, now() ) )
    .delete()

// Truncate table
qb.table( "temp_data" )
    .truncate()
```

## Subqueries

### Subquery in SELECT

```boxlang
qb.from( "users" )
    .select( "id", "firstName" )
    .subSelect( "orderCount", function( q ) {
        q.from( "orders" )
         .selectRaw( "COUNT(*)" )
         .whereColumn( "orders.userId", "users.id" )
    } )
    .get()
```

### Subquery in WHERE

```boxlang
qb.from( "users" )
    .whereIn( "id", function( q ) {
        q.select( "userId" )
         .from( "orders" )
         .where( "total", ">", 1000 )
    } )
    .get()
```

### Subquery in FROM

```boxlang
qb.fromSub( "activeUsers", function( q ) {
        q.from( "users" )
         .where( "active", 1 )
    } )
    .where( "role", "admin" )
    .get()
```

## Common Table Expressions (CTEs)

### Basic CTE

```boxlang
qb.with( "activeUsers", function( q ) {
        q.from( "users" )
         .where( "active", 1 )
    } )
    .from( "activeUsers" )
    .where( "role", "admin" )
    .get()
```

### Multiple CTEs

```boxlang
qb.with( "activeUsers", function( q ) {
        q.from( "users" ).where( "active", 1 )
    } )
    .with( "recentOrders", function( q ) {
        q.from( "orders" )
         .where( "createdAt", ">=", dateAdd( "d", -30, now() ) )
    } )
    .from( "activeUsers" )
    .join( "recentOrders", "activeUsers.id", "recentOrders.userId" )
    .get()
```

### Recursive CTE

```boxlang
qb.withRecursive( "tree", function( q ) {
        // Anchor member
        q.from( "categories" )
         .where( "parentId", "IS", "NULL" )
         .unionAll( function( u ) {
             // Recursive member
             u.from( "categories" )
              .join( "tree", "categories.parentId", "tree.id" )
         } )
    } )
    .from( "tree" )
    .get()
```

## Raw Expressions

### Raw SQL

```boxlang
// Raw in select
qb.from( "orders" )
    .select( "id" )
    .selectRaw( "SUM(total) as revenue" )
    .get()

// Raw in where
qb.from( "users" )
    .whereRaw( "YEAR(createdAt) = YEAR(NOW())" )
    .get()

// Raw value
qb.from( "users" )
    .where( "status", qb.raw( "UPPER('active')" ) )
    .get()

// Raw expression
qb.from( "products" )
    .select( "name" )
    .selectRaw( "price * ? as discountedPrice", [ 0.9 ] )
    .get()
```

## UNION Queries

### Union

```boxlang
var query1 = qb.from( "customers" )
    .select( "name", "email" )

var query2 = qb.from( "suppliers" )
    .select( "name", "email" )

query1.union( query2 ).get()
```

### Union All

```boxlang
var query1 = qb.from( "oldOrders" )
    .select( "id", "total" )

var query2 = qb.from( "newOrders" )
    .select( "id", "total" )

query1.unionAll( query2 ).get()
```

## Advanced Patterns

### Dynamic Queries

```boxlang
function searchUsers( filters = {} ) {
    var query = qb.from( "users" )

    // Dynamic filtering
    if ( structKeyExists( filters, "firstName" ) && len( filters.firstName ) ) {
        query.where( "firstName", "like", "%#filters.firstName#%" )
    }

    if ( structKeyExists( filters, "role" ) && len( filters.role ) ) {
        query.where( "role", filters.role )
    }

    if ( structKeyExists( filters, "active" ) ) {
        query.where( "active", filters.active )
    }

    // Dynamic sorting
    if ( structKeyExists( filters, "sortBy" ) && len( filters.sortBy ) ) {
        var direction = filters.sortDirection ?: "asc"
        query.orderBy( filters.sortBy, direction )
    }

    // Pagination
    if ( structKeyExists( filters, "page" ) && structKeyExists( filters, "pageSize" ) ) {
        query.forPage( filters.page, filters.pageSize )
    }

    return query.get()
}
```

### Query Scopes

```boxlang
/**
 * UserService.cfc
 */
class singleton {

    property name="qb" inject="QueryBuilder@qb"

    function newQuery() {
        return qb.from( "users" )
    }

    function active( query ) {
        return query.where( "active", 1 )
    }

    function admins( query ) {
        return query.where( "role", "admin" )
    }

    function recent( query, days = 30 ) {
        return query.where( "createdAt", ">=", dateAdd( "d", -days, now() ) )
    }

    // Usage
    function getRecentActiveAdmins() {
        var query = newQuery()
        active( query )
        admins( query )
        recent( query, 7 )
        return query.get()
    }
}
```

### Transactions

```boxlang
property name="qb" inject="QueryBuilder@qb"

function transferFunds( fromAccount, toAccount, amount ) {
    transaction {
        try {
            qb.table( "accounts" )
                .where( "id", fromAccount )
                .decrement( "balance", amount )

            qb.table( "accounts" )
                .where( "id", toAccount )
                .increment( "balance", amount )

            qb.table( "transactions" )
                .insert( {
                    fromAccount: fromAccount,
                    toAccount: toAccount,
                    amount: amount,
                    createdAt: now()
                } )

            transaction action="commit";

        } catch ( any e ) {
            transaction action="rollback";
            rethrow
        }
    }
}
```

### Pagination

```boxlang
function paginateUsers( page = 1, pageSize = 25, filters = {} ) {
    var query = qb.from( "users" )

    // Apply filters
    if ( structKeyExists( filters, "active" ) ) {
        query.where( "active", filters.active )
    }

    // Get total count
    var totalRecords = query.count()

    // Get page data
    var data = query
        .forPage( page, pageSize )
        .orderBy( "createdAt", "desc" )
        .get()

    return {
        data: data,
        pagination: {
            page: page,
            pageSize: pageSize,
            totalRecords: totalRecords,
            totalPages: ceiling( totalRecords / pageSize ),
            hasNextPage: page < ceiling( totalRecords / pageSize ),
            hasPreviousPage: page > 1
        }
    }
}
```

## Grammar-Specific Features

### MySQL Specific

```boxlang
// Use index hint
qb.from( "users" )
    .useIndex( "idx_email" )
    .where( "email", "john@example.com" )
    .get()

// Insert ignore
qb.table( "users" )
    .insertIgnore( {
        email: "john@example.com",
        name: "John"
    } )
```

### PostgreSQL Specific

```boxlang
// Returning clause
var inserted = qb.table( "users" )
    .returning( "id", "email" )
    .insert( {
        firstName: "John",
        email: "john@example.com"
    } )

// JSONB operations
qb.from( "users" )
    .whereRaw( "preferences->>'theme' = ?", [ "dark" ] )
    .get()
```

## Best Practices

### Query Reusability

```boxlang
// ✅ Good: Reusable query builder
class singleton {

    property name="qb" inject="QueryBuilder@qb"

    function baseQuery() {
        return qb.from( "users" )
            .select( "id", "firstName", "lastName", "email" )
    }

    function getActiveUsers() {
        return baseQuery()
            .where( "active", 1 )
            .get()
    }

    function getAdmins() {
        return baseQuery()
            .where( "role", "admin" )
            .get()
    }
}
```

### Parameter Binding

```boxlang
// ✅ Good: Use parameter binding (automatic in QB)
qb.from( "users" )
    .where( "email", userInput )
    .get()

// ❌ Bad: String concatenation (SQL injection risk)
qb.from( "users" )
    .whereRaw( "email = '#userInput#'" )
    .get()
```

### N+1 Query Problem

```boxlang
// ❌ Bad: N+1 queries
function getUsersWithOrders() {
    var users = qb.from( "users" ).get()

    users.each( ( user ) => {
        // Separate query for each user
        user.orders = qb.from( "orders" )
            .where( "userId", user.id )
            .get()
    } )
}

// ✅ Good: Single join query
function getUsersWithOrders() {
    return qb.from( "users" )
        .leftJoin( "orders", "users.id", "orders.userId" )
        .select( "users.*", "orders.id as orderId", "orders.total" )
        .get()
}
```

## Common Pitfalls

### Column Ambiguity

```boxlang
// ❌ Bad: Ambiguous column name
qb.from( "users" )
    .join( "orders", "users.id", "orders.userId" )
    .where( "status", "active" )  // Which table's status?
    .get()

// ✅ Good: Qualified column names
qb.from( "users" )
    .join( "orders", "users.id", "orders.userId" )
    .where( "users.status", "active" )
    .get()
```

### Query Builder Instance Reuse

```boxlang
// ❌ Bad: Reusing query builder instance
var query = qb.from( "users" )
var activeUsers = query.where( "active", 1 ).get()
var adminUsers = query.where( "role", "admin" ).get()  // Still has active=1 filter!

// ✅ Good: Create new instance
var activeUsers = qb.from( "users" ).where( "active", 1 ).get()
var adminUsers = qb.from( "users" ).where( "role", "admin" ).get()
```

## Related Skills

- [CBORM](cborm.md) - ORM utilities and patterns
- [Quick ORM](orm-quick.md) - Active Record ORM
- [BoxLang Queries](../boxlang/boxlang-queries.md) - Native query syntax
- [Database Migrations](../database/migrations.md) - Schema migrations

## References

- [QB Documentation](https://qb.ortusbooks.com/)
- [Query Builder Patterns](https://qb.ortusbooks.com/query-builder)
- [Grammar Documentation](https://qb.ortusbooks.com/schema-builder/grammars)
