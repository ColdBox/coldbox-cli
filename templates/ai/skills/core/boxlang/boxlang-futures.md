---
name: BoxLang Futures and Async Programming
description: Comprehensive guide to async programming in BoxLang using BoxFutures, async pipelines, parallel computations, and promise patterns for modern concurrent programming
category: boxlang
priority: high
triggers:
  - async
  - BoxFuture
  - promise
  - CompletableFuture
  - async pipeline
  - parallel
  - concurrent
  - asyncRun
  - asyncAll
  - asyncAny
  - futureNew
  - then
  - thenRun
  - thenCompose
---

# BoxLang Futures and Async Programming

## Overview

BoxLang provides a comprehensive async programming framework built on Java's CompletableFuture but enhanced with dynamic language features and developer-friendly APIs. BoxFuture is the core type for async operations, enabling modern patterns like promises, pipelines, and parallel computations.

## Core Concepts

### BoxFuture

BoxFuture extends Java's CompletableFuture with BoxLang-specific enhancements:

- **Promise-like API**: `then()`, `catch()`, chaining operations
- **Dynamic Type Support**: Works seamlessly with BoxLang types
- **Executor Integration**: Configurable execution on custom thread pools
- **Error Handling**: Comprehensive exception handling patterns
- **Composition**: Combine multiple futures with `all()`, `any()`, `race()`

### Async Execution Models

1. **Fire and Forget**: Execute without waiting for result
2. **Promise Pattern**: Chain operations on future results
3. **Parallel Execution**: Run multiple operations concurrently
4. **Pipeline Pattern**: Sequential async operations
5. **Race Conditions**: First-to-complete wins

## Creating Futures

### Basic Future Creation

```boxlang
// Create completed future with immediate value
completed = futureNew( "Hello World" )
result = completed.get() // Returns "Hello World"

// Create future from function (executes async)
future = futureNew( () => {
    sleep( 1000 )
    return "Async result"
} )
result = future.get() // Blocks until complete

// Create empty/incomplete future
empty = futureNew()
// Complete it later
empty.complete( "Value" )

// Create with custom executor
customExecutor = executorNew( "virtual", "my-executor" )
future = futureNew(
    () => expensiveOperation(),
    customExecutor
)
```

### Factory Methods

```boxlang
import ortus.boxlang.runtime.async.BoxFuture

// Completed future
completed = BoxFuture.completedFuture( result )

// Failed future
failed = BoxFuture.failedFuture( "Error message" )

// From value
valueFuture = BoxFuture.ofValue( 42 )

// From Java CompletableFuture
javaFuture = CompletableFuture.completedFuture( "test" )
boxFuture = BoxFuture.ofCompletableFuture( javaFuture )
```

## Async Execution

### asyncRun() - Single Async Operation

```boxlang
// Execute function async (fire and forget)
future = asyncRun( () => {
    logger.info( "Background task started" )
    processLargeFile()
    logger.info( "Background task completed" )
} )

// Wait for completion
future.get()

// With custom executor
future = asyncRun(
    () => cpuIntensiveTask(),
    executorNew( "fixed", "cpu-pool", 8 )
)
```

### Real-World Async Execution Example

```boxlang
/**
 * Process upload async and return immediately
 */
function uploadFile( file, userId ) {
    // Start async processing
    future = asyncRun( () => {
        try {
            // Validate file
            validationResult = validateFile( file )
            if ( !validationResult.valid ) {
                logger.warn( "Invalid file upload: #validationResult.reason#" )
                return
            }

            // Process file (expensive operation)
            processedPath = processFile( file )

            // Upload to storage
            storageUrl = storageService.upload( processedPath )

            // Update database
            fileService.recordUpload( userId, storageUrl )

            // Send notification
            notificationService.notifyUser( userId, "File processed successfully" )

        } catch ( any e ) {
            logger.error( "File processing failed: #e.message#", e )
            notificationService.notifyUser( userId, "File processing failed" )
        }
    } )

    // Return immediately
    return {
        success: true,
        message: "File upload queued for processing",
        futureId: future.hashCode()
    }
}
```

## Async Pipelines

### then() - Transform Results

```boxlang
// Chain transformations
result = futureNew( () => fetchUserData( 123 ) )
    .then( user => {
        // Transform user data
        return {
            id: user.id,
            name: user.fullName,
            email: user.email
        }
    } )
    .then( userData => {
        // Further transformation
        userData.timestamp = now()
        return userData
    } )
    .get()
```

### thenRun() - Execute Without Return

```boxlang
// Execute side effects
futureNew( () => generateReport() )
    .thenRun( () => {
        // Notification side effect (no return value)
        sendEmail( "admin@example.com", "Report generated" )
    } )
    .thenRun( () => {
        // Cleanup side effect
        cleanupTempFiles()
    } )
    .get()
```

### thenCompose() - Chain Dependent Futures

```boxlang
// Compose async operations
result = futureNew( () => getUserId( email ) )
    .thenCompose( userId => {
        // Return another future
        return futureNew( () => getUserProfile( userId ) )
    } )
    .thenCompose( profile => {
        // Another dependent future
        return futureNew( () => getProfilePreferences( profile.id ) )
    } )
    .get()
```

### Complex Pipeline Example

```boxlang
/**
 * Multi-stage data processing pipeline
 */
function processOrder( orderId ) {
    return futureNew( () => orderService.find( orderId ) )
        .then( order => {
            // Validate order
            if ( !order.isValid() ) {
                throw( type = "InvalidOrder", message = "Order validation failed" )
            }
            return order
        } )
        .thenCompose( order => {
            // Fetch customer (async)
            return futureNew( () => customerService.find( order.customerId ) )
                .then( customer => {
                    return { order: order, customer: customer }
                } )
        } )
        .thenCompose( data => {
            // Process payment (async)
            return futureNew( () =>
                paymentService.charge( data.customer, data.order.total )
            )
            .then( payment => {
                data.payment = payment
                return data
            } )
        } )
        .then( data => {
            // Update order status
            orderService.updateStatus( data.order.id, "paid" )
            return data
        } )
        .thenRun( () => {
            // Send confirmation email
            emailService.sendOrderConfirmation( data.customer, data.order )
        } )
        .get()
}
```

## Error Handling

### exceptionally() - Handle Errors

```boxlang
// Handle errors with fallback value
result = futureNew( () => riskyOperation() )
    .exceptionally( exception => {
        logger.error( "Operation failed: #exception.message#" )
        return "default-value" // Fallback
    } )
    .get()
```

### handle() - Error or Success

```boxlang
// Handle both success and failure
result = futureNew( () => fetchData() )
    .handle( ( result, exception ) => {
        if ( !isNull( exception ) ) {
            logger.error( "Fetch failed: #exception.message#" )
            return { success: false, error: exception.message }
        }
        return { success: true, data: result }
    } )
    .get()
```

### whenComplete() - Cleanup Actions

```boxlang
// Always execute cleanup (like finally)
futureNew( () => processWithResources() )
    .whenComplete( ( result, exception ) => {
        // Always runs, regardless of success/failure
        cleanupResources()

        if ( !isNull( exception ) ) {
            logger.error( "Processing failed: #exception.message#" )
        } else {
            logger.info( "Processing completed successfully" )
        }
    } )
    .get()
```

### Comprehensive Error Handling

```boxlang
/**
 * Robust async operation with error handling
 */
function robustDataFetch( source ) {
    return futureNew( () => fetchDataFrom( source ) )
        .then( data => {
            // Validate data
            if ( !isValidData( data ) ) {
                throw( type = "DataValidationError", message = "Invalid data format" )
            }
            return data
        } )
        .exceptionally( exception => {
            // Log and handle specific exceptions
            logger.error( "Data fetch failed: #exception.message#", exception )

            // Return cached data as fallback
            cached = cacheService.get( "data-#source#" )
            if ( !isNull( cached ) ) {
                logger.info( "Returning cached data for #source#" )
                return cached
            }

            // No cached data available
            throw(
                type = "DataUnavailable",
                message = "Unable to fetch data from #source# and no cache available"
            )
        } )
        .whenComplete( ( result, exception ) => {
            // Update metrics
            if ( isNull( exception ) ) {
                metricsService.incrementSuccess( "data-fetch-#source#" )
            } else {
                metricsService.incrementFailure( "data-fetch-#source#" )
            }
        } )
}
```

## Parallel Computations

### asyncAll() - Execute All in Parallel

```boxlang
// Execute multiple functions in parallel
futures = [
    () => fetchUserData( 1 ),
    () => fetchUserData( 2 ),
    () => fetchUserData( 3 )
]

// All execute concurrently, results in order
results = asyncAll( futures ).get()
// results = [ userData1, userData2, userData3 ]
```

### asyncAll() With Mixed Types

```boxlang
// Mix functions, futures, and values
operations = [
    // Function to execute
    () => performCalculation(),

    // Pre-created future
    futureNew( () => fetchFromAPI() ),

    // Another function
    () => processLocalData(),

    // Immediate value (already completed)
    "static-value"
]

allResults = asyncAll( operations )
    .then( results => {
        // Process all results together
        return combineResults( results )
    } )
    .get()
```

### Real-World Parallel Example

```boxlang
/**
 * Load dashboard data in parallel
 */
function loadDashboard( userId ) {
    // Start all data fetches in parallel
    dataFutures = asyncAll( [
        () => userService.getProfile( userId ),
        () => orderService.getRecentOrders( userId ),
        () => notificationService.getUnread( userId ),
        () => analyticsService.getUserStats( userId ),
        () => recommendationService.getPersonalized( userId )
    ] )

    // Transform results when all complete
    return dataFutures.then( results => {
        return {
            profile: results[1],
            recentOrders: results[2],
            notifications: results[3],
            stats: results[4],
            recommendations: results[5],
            loadTime: now()
        }
    } )
}

// Usage
dashboard = loadDashboard( userId ).get()
```

### asyncAny() - First to Complete

```boxlang
// Race multiple operations, first wins
sources = [
    () => fetchFromPrimaryAPI(),
    () => fetchFromSecondaryAPI(),
    () => fetchFromCache()
]

// Returns result from fastest source
result = asyncAny( sources ).get()
```

### asyncAny() With Fallbacks

```boxlang
/**
 * Try multiple data sources, use first available
 */
function getDataWithFallback( query ) {
    return asyncAny( [
        // Try cache first (fastest)
        () => {
            cached = cacheService.get( "data-#query#" )
            if ( isNull( cached ) ) {
                throw( "Cache miss" )
            }
            return { source: "cache", data: cached }
        },

        // Try primary API
        () => {
            data = primaryAPI.fetch( query )
            return { source: "primary", data: data }
        },

        // Try backup API
        () => {
            data = backupAPI.fetch( query )
            return { source: "backup", data: data }
        }
    ] )
    .then( result => {
        logger.info( "Data fetched from: #result.source#" )

        // Cache if not from cache
        if ( result.source != "cache" ) {
            cacheService.set( "data-#query#", result.data, 300 )
        }

        return result.data
    } )
}
```

## Advanced Patterns

### allOf() - Wait for Multiple Futures

```boxlang
// Create multiple futures
future1 = futureNew( () => task1() )
future2 = futureNew( () => task2() )
future3 = futureNew( () => task3() )

// Wait for all to complete
BoxFuture.allOf( future1, future2, future3 ).get()

// Now all futures are complete, get results
result1 = future1.get()
result2 = future2.get()
result3 = future3.get()
```

### anyOf() - Wait for First Completion

```boxlang
// Create multiple futures
future1 = futureNew( () => slowTask() )
future2 = futureNew( () => fastTask() )
future3 = futureNew( () => mediumTask() )

// Wait for any to complete
firstComplete = BoxFuture.anyOf( future1, future2, future3 ).get()

// firstComplete is the result from the fastest task
println( "First result: #firstComplete#" )
```

### Complex Parallel + Sequential Pipeline

```boxlang
/**
 * Fetch data from multiple sources, aggregate, then process
 */
function complexDataPipeline( userId ) {
    return asyncAll( [
        // Phase 1: Parallel data fetching
        futureNew( () => database.getUserData( userId ) ),
        futureNew( () => api.getUserActivity( userId ) ),
        futureNew( () => cache.getUserPreferences( userId ) )
    ] )
    .then( results => {
        // Phase 2: Aggregate results
        return {
            user: results[1],
            activity: results[2],
            preferences: results[3]
        }
    } )
    .thenCompose( aggregated => {
        // Phase 3: Process aggregated data (async)
        return futureNew( () => enrichUserProfile( aggregated ) )
    } )
    .then( enriched => {
        // Phase 4: Apply business rules
        return applyBusinessRules( enriched )
    } )
    .thenRun( () => {
        // Phase 5: Side effects
        auditService.logProfileAccess( userId )
        analyticsService.trackProfileView( userId )
    } )
}
```

### Timeout Handling

```boxlang
// Wait with timeout
future = futureNew( () => slowOperation() )

try {
    // Wait up to 5 seconds
    result = future.get( 5, "seconds" )
} catch ( any e ) {
    if ( e.type == "TimeoutException" ) {
        logger.warn( "Operation timed out after 5 seconds" )
        // Handle timeout
        future.cancel( true ) // Cancel the operation
        result = getDefaultValue()
    }
}
```

### Retry Pattern

```boxlang
/**
 * Retry async operation with exponential backoff
 */
function retryAsync( operation, maxRetries = 3, initialDelay = 1000 ) {
    return futureNew( () => operation() )
        .exceptionally( exception => {
            if ( maxRetries > 0 ) {
                // Wait before retry (exponential backoff)
                sleep( initialDelay )

                // Retry
                return retryAsync(
                    operation,
                    maxRetries - 1,
                    initialDelay * 2
                ).get()
            }

            // No more retries, rethrow
            throw exception
        } )
}

// Usage
result = retryAsync(
    () => unreliableAPICall(),
    maxRetries = 3,
    initialDelay = 1000
).get()
```

## Parallel Collections

### Parallel Array Operations

```boxlang
// Process array items in parallel
users = [ 1, 2, 3, 4, 5 ]

// Parallel map
enrichedUsers = users
    .parallel()
    .map( userId => enrichUserData( userId ) )
    .get()

// Parallel filter
activeUsers = users
    .parallel()
    .filter( userId => isUserActive( userId ) )
    .get()

// Parallel each
users
    .parallel()
    .each( userId => {
        sendNotification( userId )
    } )
```

### Parallel Struct Operations

```boxlang
// Process struct values in parallel
config = {
    api1: { url: "...", enabled: true },
    api2: { url: "...", enabled: true },
    api3: { url: "...", enabled: false }
}

// Parallel map on struct
statuses = config
    .parallel()
    .map( ( name, cfg ) => {
        if ( !cfg.enabled ) return "disabled"
        return checkAPIStatus( cfg.url )
    } )
    .get()
```

### asyncAllApply() - Parallel Mapper

```boxlang
// Apply function to collection in parallel
users = [ 1, 2, 3, 4, 5 ]

enrichedUsers = asyncAllApply(
    users,
    userId => fetchAndEnrichUser( userId )
).get()

// With struct
apiConfigs = {
    primary: { url: "..." },
    backup: { url: "..." }
}

statuses = asyncAllApply(
    apiConfigs,
    ( name, config ) => checkEndpoint( config.url )
).get()
```

## Testing Async Code

### Testing Futures

```boxlang
/**
 * AsyncServiceSpec.bx
 */
component extends="testbox.system.BaseSpec" {

    function run() {
        describe( "Async Service", () => {

            it( "should fetch data async", () => {
                future = service.fetchDataAsync( 123 )

                // Future should not be done immediately
                expect( future.isDone() ).toBeFalse()

                // Wait for completion
                result = future.get()

                // Should be done now
                expect( future.isDone() ).toBeTrue()
                expect( result ).toHaveKey( "id" )
                expect( result.id ).toBe( 123 )
            } )

            it( "should handle errors in future", () => {
                future = service.failingOperation()

                expect( () => future.get() )
                    .toThrow( "ServiceException" )
            } )

            it( "should complete pipeline", () => {
                result = service.processAsync( 123 )
                    .then( data => data.value * 2 )
                    .then( doubled => doubled + 10 )
                    .get()

                expect( result ).toBeNumeric()
            } )

            it( "should execute parallel operations", () => {
                startTime = getTickCount()

                results = asyncAll( [
                    () => slowOperation( 100 ),
                    () => slowOperation( 100 ),
                    () => slowOperation( 100 )
                ] ).get()

                duration = getTickCount() - startTime

                // Should take ~100ms, not 300ms
                expect( duration ).toBeLT( 200 )
                expect( results ).toHaveLength( 3 )
            } )
        } )
    }
}
```

### Mocking Async Operations

```boxlang
/**
 * Mock async service calls
 */
component extends="testbox.system.BaseSpec" {

    function beforeAll() {
        mockAPIService = createMock( "APIService" )

        // Mock returns completed future
        mockAPIService
            .$( "fetchDataAsync" )
            .$results( futureNew( { id: 123, name: "Test" } ) )
    }

    function run() {
        describe( "Service with async dependencies", () => {

            it( "should handle async dependency", () => {
                service = new UserService()
                service.apiService = mockAPIService

                result = service.getUserData( 123 ).get()

                expect( result.name ).toBe( "Test" )
                expect( mockAPIService.$once( "fetchDataAsync" ) ).toBeTrue()
            } )
        } )
    }
}
```

## Best Practices

### Design Guidelines

1. **Non-Blocking**: Avoid blocking operations in async code
2. **Error Handling**: Always handle exceptions in async operations
3. **Timeouts**: Configure appropriate timeouts for all async operations
4. **Executor Choice**: Use correct executor (virtual for I/O, fixed for CPU)
5. **Resource Cleanup**: Always clean up resources (use `whenComplete()`)
6. **Logging**: Log async operation start, completion, and failure
7. **Cancellation**: Support cancellation for long-running operations
8. **Testing**: Test both success and failure scenarios

### Performance Optimization

```boxlang
// Use appropriate executor for workload
ioExecutor = executorNew( "virtual", "io-tasks" )
cpuExecutor = executorNew( "fixed", "cpu-tasks", 8 )

// I/O-bound operations on virtual threads
ioFuture = futureNew( () => fetchFromAPI(), ioExecutor )

// CPU-bound operations on fixed pool
cpuFuture = futureNew( () => complexCalculation(), cpuExecutor )

// Avoid excessive future creation in loops
// ❌ Bad: Creates many futures
for ( i = 1; i <= 1000; i++ ) {
    futureNew( () => process( i ) )
}

// ✅ Good: Batch operations
batchSize = 100
for ( batch in createBatches( items, batchSize ) ) {
    futureNew( () => processBatch( batch ) )
}
```

### Memory Management

```boxlang
// ✅ Clean up completed futures
completed = futureNew( () => operation() ).get()
completed = null // Allow GC

// ✅ Use whenComplete for cleanup
futureNew( () => processWithConnection() )
    .whenComplete( ( result, exception ) => {
        // Always close connection
        if ( !isNull( connection ) ) {
            connection.close()
        }
    } )

// ✅ Cancel unnecessary futures
future = futureNew( () => longOperation() )

if ( shouldCancel ) {
    future.cancel( true ) // Interrupt if running
}
```

## Common Pitfalls

### Pitfalls to Avoid

1. **Blocking in Async**: Don't block in async code (defeats purpose)
2. **Unhandled Exceptions**: Always use `exceptionally()` or `handle()`
3. **Forgetting .get()**: Future doesn't execute until terminal operation
4. **Deadlocks**: Avoid circular dependencies between futures
5. **Resource Leaks**: Always clean up in `whenComplete()`
6. **Exception Swallowing**: Don't silently catch and ignore exceptions
7. **Incorrect Executor**: Using wrong executor type hurts performance
8. **No Timeout**: Long operations should have timeouts
9. **Excessive Parallelism**: Too many parallel operations can overwhelm system
10. **Missing Cancellation**: Long operations should support cancellation

### Troubleshooting

```boxlang
// Debug future state
if ( future.isDone() ) {
    println( "Future completed" )
}

if ( future.isCancelled() ) {
    println( "Future was cancelled" )
}

if ( future.isCompletedExceptionally() ) {
    println( "Future completed with exception" )
}

// Get result without blocking
if ( future.getNow( null ) != null ) {
    result = future.getNow( null )
} else {
    println( "Future not complete yet" )
}

// Log async execution
futureNew( () => {
    logger.debug( "Starting async operation on thread: #getCurrentThread().getName()#" )
    result = operation()
    logger.debug( "Completed async operation" )
    return result
} )
```

## Related Skills

- [BoxLang Scheduled Tasks](boxlang-scheduled-tasks.md) - Task scheduling with scheduler framework
- [BoxLang Executors](boxlang-executors.md) - Thread pools and executor configuration
- [BoxLang Threading](boxlang-threading.md) - Traditional threading and concurrency
- [BoxLang HTTP Client](boxlang-http-client.md) - Async HTTP requests

## References

- [BoxLang Async Programming](https://boxlang.ortusbooks.com/boxlang-framework/asynchronous-programming)
- [BoxLang BoxFutures](https://boxlang.ortusbooks.com/boxlang-framework/asynchronous-programming/box-futures)
- [BoxLang Async Pipelines](https://boxlang.ortusbooks.com/boxlang-framework/asynchronous-programming/async-pipelines)
- [BoxLang Parallel Computations](https://boxlang.ortusbooks.com/boxlang-framework/asynchronous-programming/parallel-computations)
- [BoxFuture API Docs](https://s3.amazonaws.com/apidocs.ortussolutions.com/boxlang/1.0.0-beta6/ortus/boxlang/runtime/async/BoxFuture.html)
