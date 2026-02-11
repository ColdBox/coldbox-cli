---
name: boxlang-streams
description: Master BoxLang Stream API for functional-style data processing with lazy evaluation, filtering, mapping, and collection operations
category: boxlang
priority: high
---

# BoxLang Streams Skill

## When to Use This Skill

Use this skill when:
- Processing collections with functional-style operations
- Building complex data transformation pipelines
- Implementing lazy evaluation for performance
- Filtering, mapping, and reducing large datasets
- Chaining multiple operations on collections
- Working with infinite or large data sequences

## Stream Basics

### What is a Stream?

A Stream is a sequence of elements supporting sequential and parallel aggregate operations. Streams are lazy - they don't process elements until a terminal operation is called.

```boxlang
// Create stream from array
var numbers = [ 1, 2, 3, 4, 5 ]
var stream = numbers.stream()

// Process with operations
var result = stream
    .filter( ( n ) => n % 2 == 0 )
    .map( ( n ) => n * 2 )
    .collect()

// Result: [ 4, 8 ]
```

### Creating Streams

```boxlang
// From array
var arrayStream = [ 1, 2, 3 ].stream()

// From query
var users = queryExecute( "SELECT * FROM users" )
var userStream = users.stream()

// From struct
var data = { name: "John", age: 30 }
var structStream = data.stream()

// From range
var rangeStream = range( 1, 100 ).stream()

// Empty stream
var emptyStream = [].stream()

// Infinite stream (use with limit!)
var infiniteStream = Stream.iterate( 0, ( n ) => n + 1 )
```

## Intermediate Operations

### filter() - Select Elements

```boxlang
// Filter even numbers
var evens = [ 1, 2, 3, 4, 5, 6 ]
    .stream()
    .filter( ( n ) => n % 2 == 0 )
    .collect()
// Result: [ 2, 4, 6 ]

// Filter active users
var activeUsers = queryExecute( "SELECT * FROM users" )
    .stream()
    .filter( ( user ) => user.active == true )
    .collect()

// Filter by multiple conditions
var results = data
    .stream()
    .filter( ( item ) => item.price > 10 && item.inStock )
    .collect()

// Filter with complex logic
var premiumUsers = users
    .stream()
    .filter( ( user ) => {
        return user.subscriptionLevel == "premium" &&
               dateDiff( "d", user.joinDate, now() ) > 365
    })
    .collect()
```

### map() - Transform Elements

```boxlang
// Square numbers
var squared = [ 1, 2, 3, 4 ]
    .stream()
    .map( ( n ) => n * n )
    .collect()
// Result: [ 1, 4, 9, 16 ]

// Extract property
var userNames = users
    .stream()
    .map( ( user ) => user.name )
    .collect()

// Transform objects
var userDTOs = users
    .stream()
    .map( ( user ) => {
        return {
            id: user.id,
            fullName: "#user.firstName# #user.lastName#",
            email: user.email
        }
    })
    .collect()

// Chain transformations
var processed = data
    .stream()
    .map( ( item ) => item.value )
    .map( ( value ) => value * 2 )
    .map( ( value ) => value + 10 )
    .collect()
```

### flatMap() - Flatten Nested Structures

```boxlang
// Flatten nested arrays
var nested = [ [ 1, 2 ], [ 3, 4 ], [ 5, 6 ] ]
var flattened = nested
    .stream()
    .flatMap( ( arr ) => arr.stream() )
    .collect()
// Result: [ 1, 2, 3, 4, 5, 6 ]

// Extract nested data
var orders = [
    { items: [ "apple", "banana" ] },
    { items: [ "orange" ] },
    { items: [ "grape", "melon" ] }
]

var allItems = orders
    .stream()
    .flatMap( ( order ) => order.items.stream() )
    .collect()
// Result: [ "apple", "banana", "orange", "grape", "melon" ]

// Complex nested structure
var departments = [
    {
        name: "Engineering",
        teams: [
            { name: "Backend", members: [ "Alice", "Bob" ] },
            { name: "Frontend", members: [ "Charlie" ] }
        ]
    },
    {
        name: "Sales",
        teams: [
            { name: "Enterprise", members: [ "David", "Eve" ] }
        ]
    }
]

var allMembers = departments
    .stream()
    .flatMap( ( dept ) => dept.teams.stream() )
    .flatMap( ( team ) => team.members.stream() )
    .collect()
```

### distinct() - Remove Duplicates

```boxlang
// Remove duplicate numbers
var unique = [ 1, 2, 2, 3, 3, 3, 4 ]
    .stream()
    .distinct()
    .collect()
// Result: [ 1, 2, 3, 4 ]

// Unique values from query
var uniqueCategories = products
    .stream()
    .map( ( product ) => product.category )
    .distinct()
    .collect()

// Distinct objects by property
var uniqueUsers = users
    .stream()
    .distinctBy( ( user ) => user.email )
    .collect()
```

### sorted() - Sort Elements

```boxlang
// Sort numbers ascending
var sorted = [ 3, 1, 4, 1, 5, 9 ]
    .stream()
    .sorted()
    .collect()
// Result: [ 1, 1, 3, 4, 5, 9 ]

// Sort descending
var descending = [ 3, 1, 4, 1, 5, 9 ]
    .stream()
    .sorted( ( a, b ) => b - a )
    .collect()

// Sort objects by property
var sortedUsers = users
    .stream()
    .sorted( ( a, b ) => compare( a.lastName, b.lastName ) )
    .collect()

// Complex sorting
var sortedProducts = products
    .stream()
    .sorted( ( a, b ) => {
        // First by category, then by price
        var catCompare = compare( a.category, b.category )
        if ( catCompare != 0 ) return catCompare
        return a.price - b.price
    })
    .collect()
```

### limit() and skip() - Control Stream Size

```boxlang
// Take first 5 elements
var firstFive = [ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 ]
    .stream()
    .limit( 5 )
    .collect()
// Result: [ 1, 2, 3, 4, 5 ]

// Skip first 3, take next 5
var middle = range( 1, 100 )
    .stream()
    .skip( 3 )
    .limit( 5 )
    .collect()
// Result: [ 4, 5, 6, 7, 8 ]

// Pagination
var pageSize = 10
var page = 2
var paginatedResults = allRecords
    .stream()
    .skip( ( page - 1 ) * pageSize )
    .limit( pageSize )
    .collect()
```

### peek() - Side Effects Without Modification

```boxlang
// Debug stream operations
var result = [ 1, 2, 3, 4, 5 ]
    .stream()
    .filter( ( n ) => n % 2 == 0 )
    .peek( ( n ) => writeOutput( "After filter: #n#<br>" ) )
    .map( ( n ) => n * 2 )
    .peek( ( n ) => writeOutput( "After map: #n#<br>" ) )
    .collect()

// Log processing
var processed = users
    .stream()
    .peek( ( user ) => log.debug( "Processing user: #user.id#" ) )
    .filter( ( user ) => user.active )
    .peek( ( user ) => log.info( "Active user: #user.id#" ) )
    .collect()
```

## Terminal Operations

### collect() - Materialize Stream

```boxlang
// Collect to array
var array = stream.collect()

// Collect to specific type
var list = stream.collect( "list" )

// Collect with collector
var customCollection = stream.collect( Collectors.toList() )
```

### forEach() - Iterate Elements

```boxlang
// Print each element
[ 1, 2, 3, 4, 5 ]
    .stream()
    .forEach( ( n ) => writeOutput( n ) )

// Process each user
users
    .stream()
    .filter( ( user ) => user.needsNotification )
    .forEach( ( user ) => sendEmail( user.email, "Reminder" ) )

// Side effects with forEach
var total = 0
numbers
    .stream()
    .forEach( ( n ) => total += n )
```

### reduce() - Aggregate Values

```boxlang
// Sum numbers
var sum = [ 1, 2, 3, 4, 5 ]
    .stream()
    .reduce( 0, ( acc, n ) => acc + n )
// Result: 15

// Product
var product = [ 1, 2, 3, 4, 5 ]
    .stream()
    .reduce( 1, ( acc, n ) => acc * n )
// Result: 120

// Concatenate strings
var sentence = [ "Hello", "World", "from", "BoxLang" ]
    .stream()
    .reduce( "", ( acc, word ) => acc & " " & word )
    .trim()
// Result: "Hello World from BoxLang"

// Complex reduction
var summary = orders
    .stream()
    .reduce(
        { total: 0, count: 0 },
        ( acc, order ) => {
            return {
                total: acc.total + order.amount,
                count: acc.count + 1
            }
        }
    )
```

### count() - Count Elements

```boxlang
// Count all elements
var total = [ 1, 2, 3, 4, 5 ].stream().count()
// Result: 5

// Count filtered elements
var activeCount = users
    .stream()
    .filter( ( user ) => user.active )
    .count()

// Count matching condition
var expensiveProducts = products
    .stream()
    .filter( ( p ) => p.price > 100 )
    .count()
```

### anyMatch(), allMatch(), noneMatch() - Test Conditions

```boxlang
// Check if any element matches
var hasEven = [ 1, 3, 5, 7, 8 ]
    .stream()
    .anyMatch( ( n ) => n % 2 == 0 )
// Result: true

// Check if all elements match
var allPositive = [ 1, 2, 3, 4, 5 ]
    .stream()
    .allMatch( ( n ) => n > 0 )
// Result: true

// Check if no elements match
var noNegatives = [ 1, 2, 3, 4, 5 ]
    .stream()
    .noneMatch( ( n ) => n < 0 )
// Result: true

// Complex matching
var allValid = users
    .stream()
    .allMatch( ( user ) => {
        return len( user.email ) > 0 &&
               isValid( "email", user.email )
    })
```

### findFirst() and findAny()

```boxlang
// Find first element
var firstEven = [ 1, 3, 5, 7, 8, 10 ]
    .stream()
    .filter( ( n ) => n % 2 == 0 )
    .findFirst()
// Result: 8

// Find any matching element
var anyAdmin = users
    .stream()
    .filter( ( user ) => user.role == "admin" )
    .findAny()

// Find with default
var result = collection
    .stream()
    .filter( condition )
    .findFirst()
    .orElse( defaultValue )
```

### min() and max()

```boxlang
// Find minimum
var min = [ 5, 2, 8, 1, 9 ]
    .stream()
    .min()
// Result: 1

// Find maximum
var max = [ 5, 2, 8, 1, 9 ]
    .stream()
    .max()
// Result: 9

// Min/Max with comparator
var youngestUser = users
    .stream()
    .min( ( a, b ) => a.age - b.age )

var mostExpensive = products
    .stream()
    .max( ( a, b ) => a.price - b.price )
```

## Advanced Stream Operations

### Parallel Streams

```boxlang
// Process in parallel for large datasets
var results = largeDataset
    .parallelStream()
    .filter( complexFilterCondition )
    .map( expensiveTransformation )
    .collect()

// Sequential vs Parallel
var sequential = data.stream().filter( condition ).collect()
var parallel = data.parallelStream().filter( condition ).collect()
```

### Grouping and Partitioning

```boxlang
// Group by property
var byCategory = products
    .stream()
    .groupBy( ( product ) => product.category )
// Result: { "Electronics": [...], "Books": [...], ... }

// Partition by condition
var partitioned = numbers
    .stream()
    .partition( ( n ) => n % 2 == 0 )
// Result: { true: [even numbers], false: [odd numbers] }

// Complex grouping
var usersByRole = users
    .stream()
    .groupBy( ( user ) => user.role )
    .mapValues( ( users ) => users.collect() )
```

### Stateful Operations

```boxlang
// Running sum
var runningSum = []
var result = numbers
    .stream()
    .peek( ( n ) => {
        var sum = runningSum.isEmpty() ? 0 : runningSum.last()
        runningSum.append( sum + n )
    })
    .collect()

// Indexed processing
var indexed = data
    .stream()
    .zipWithIndex()
    .map( ( pair ) => {
        return {
            index: pair.index,
            value: pair.value
        }
    })
    .collect()
```

## Practical Examples

### Data Transformation Pipeline

```boxlang
// Complex data processing
var report = rawData
    .stream()
    .filter( ( record ) => record.status == "active" )
    .map( ( record ) => {
        return {
            id: record.id,
            revenue: record.amount * 1.1,  // Add 10% markup
            date: dateFormat( record.createdDate, "yyyy-mm-dd" )
        }
    })
    .filter( ( record ) => record.revenue > 1000 )
    .sorted( ( a, b ) => b.revenue - a.revenue )
    .limit( 10 )
    .collect()
```

### Query Processing

```boxlang
// Process database results
var userSummary = queryExecute( "SELECT * FROM users" )
    .stream()
    .filter( ( user ) => user.active )
    .map( ( user ) => {
        return {
            name: "#user.firstName# #user.lastName#",
            email: user.email,
            orderCount: getOrderCount( user.id )
        }
    })
    .sorted( ( a, b ) => b.orderCount - a.orderCount )
    .limit( 20 )
    .collect()
```

### Aggregation Operations

```boxlang
// Calculate statistics
var stats = numbers
    .stream()
    .collect( Collectors.summarizingInt() )
// Contains: count, sum, min, average, max

// Custom aggregation
var summary = sales
    .stream()
    .reduce(
        {
            total: 0,
            count: 0,
            max: 0,
            min: 999999
        },
        ( acc, sale ) => {
            return {
                total: acc.total + sale.amount,
                count: acc.count + 1,
                max: max( acc.max, sale.amount ),
                min: min( acc.min, sale.amount )
            }
        }
    )

var average = summary.total / summary.count
```

## Best Practices

### ✅ DO: Chain Operations Efficiently

```boxlang
// Good - Efficient chaining
var result = data
    .stream()
    .filter( condition1 )      // Reduces dataset early
    .map( transformation )     // Transform only filtered items
    .filter( condition2 )      // Further reduce
    .collect()

// Less efficient
var filtered1 = data.stream().filter( condition1 ).collect()
var mapped = filtered1.stream().map( transformation ).collect()
var filtered2 = mapped.stream().filter( condition2 ).collect()
```

### ✅ DO: Use Lazy Evaluation

```boxlang
// Good - Lazy evaluation
var stream = largeDataset
    .stream()
    .filter( expensiveOperation )
    .map( anotherExpensiveOperation )

// Nothing happens until terminal operation
var result = stream.findFirst()  // Only processes until first match

// Bad - Eager evaluation
var filtered = largeDataset.filter( expensiveOperation )
var mapped = filtered.map( anotherExpensiveOperation )
var result = mapped[1]  // Processed entire dataset
```

### ✅ DO: Use Appropriate Terminal Operations

```boxlang
// Good - Use findFirst() instead of collect() when only need one
var firstMatch = users
    .stream()
    .filter( ( user ) => user.email == searchEmail )
    .findFirst()

// Bad - Collects all matches unnecessarily
var allMatches = users
    .stream()
    .filter( ( user ) => user.email == searchEmail )
    .collect()
var first = allMatches[1]
```

### ✅ DO: Use Parallel Streams for Large Datasets

```boxlang
// Good - Parallel for large, CPU-intensive operations
var results = millionsOfRecords
    .parallelStream()
    .filter( cpuIntensiveOperation )
    .map( anotherCpuIntensiveOperation )
    .collect()

// Sequential is fine for small datasets
var results = [ 1, 2, 3, 4, 5 ]
    .stream()
    .map( ( n ) => n * 2 )
    .collect()
```

## Common Mistakes

### ❌ Modifying Source During Stream

```boxlang
// Wrong - Modifying source collection
var list = [ 1, 2, 3, 4, 5 ]
list.stream()
    .forEach( ( n ) => list.append( n * 2 ) )  // ❌ ConcurrentModificationException

// Right - Create new collection
var doubled = list
    .stream()
    .map( ( n ) => n * 2 )
    .collect()
```

### ❌ Reusing Streams

```boxlang
// Wrong - Stream already consumed
var stream = [ 1, 2, 3 ].stream()
var count = stream.count()
var list = stream.collect()  // ❌ Stream already operated upon

// Right - Create new stream for each operation
var data = [ 1, 2, 3 ]
var count = data.stream().count()
var list = data.stream().collect()
```

### ❌ Unnecessary collect() Calls

```boxlang
// Wrong - Multiple intermediate collections
var result = data
    .stream()
    .filter( condition1 )
    .collect()                    // ❌ Unnecessary
    .stream()
    .map( transformation )
    .collect()                    // ❌ Unnecessary
    .stream()
    .filter( condition2 )
    .collect()

// Right - Single stream pipeline
var result = data
    .stream()
    .filter( condition1 )
    .map( transformation )
    .filter( condition2 )
    .collect()
```

### ❌ Side Effects in map()

```boxlang
// Wrong - Side effects in map
var total = 0
var result = numbers
    .stream()
    .map( ( n ) => {
        total += n  // ❌ Side effect
        return n * 2
    })
    .collect()

// Right - Use reduce for aggregation
var total = numbers
    .stream()
    .reduce( 0, ( acc, n ) => acc + n )

var doubled = numbers
    .stream()
    .map( ( n ) => n * 2 )
    .collect()
```

## Testing Streams

```boxlang
component extends="testbox.system.BaseSpec" {

    function run() {
        describe( "Stream Operations", () => {

            it( "should filter elements", () => {
                var result = [ 1, 2, 3, 4, 5 ]
                    .stream()
                    .filter( ( n ) => n % 2 == 0 )
                    .collect()

                expect( result ).toBe( [ 2, 4 ] )
            })

            it( "should map elements", () => {
                var result = [ 1, 2, 3 ]
                    .stream()
                    .map( ( n ) => n * 2 )
                    .collect()

                expect( result ).toBe( [ 2, 4, 6 ] )
            })

            it( "should chain operations", () => {
                var result = [ 1, 2, 3, 4, 5 ]
                    .stream()
                    .filter( ( n ) => n > 2 )
                    .map( ( n ) => n * 2 )
                    .collect()

                expect( result ).toBe( [ 6, 8, 10 ] )
            })

            it( "should reduce to single value", () => {
                var sum = [ 1, 2, 3, 4, 5 ]
                    .stream()
                    .reduce( 0, ( acc, n ) => acc + n )

                expect( sum ).toBe( 15 )
            })

            it( "should handle empty streams", () => {
                var result = []
                    .stream()
                    .filter( ( n ) => true )
                    .collect()

                expect( result ).toBeEmpty()
            })
        })
    }
}
```

## Additional Resources

- BoxLang Stream API Documentation
- Java Stream API Reference
- Functional Programming in BoxLang
- Stream Performance Optimization
- Parallel Processing Guide
- Lambda Expressions Best Practices
