---
name: BoxLang Executors and Thread Pools
description: Comprehensive guide to managing thread pools and executors in BoxLang, including executor types, virtual threads, configuration, and best practices for concurrent programming
category: boxlang
priority: medium
triggers:
  - executor
  - thread pool
  - executorNew
  - virtual thread
  - executor service
  - concurrency
  - thread management
  - work stealing
  - fork join
  - scheduled executor
---

# BoxLang Executors and Thread Pools

## Overview

BoxLang provides powerful executor management through the `executorNew()` BIF and pre-configured runtime executors. Executors manage thread pools for concurrent task execution, supporting various strategies including virtual threads (Project Loom), fixed pools, cached pools, scheduled execution, and work-stealing patterns.

## Core Concepts

### Executor Types

BoxLang supports seven executor types:

1. **Virtual** - Lightweight virtual threads (Java 21+, Project Loom)
2. **Fixed** - Fixed-size thread pool for predictable concurrency
3. **Cached** - Dynamic thread pool that creates threads as needed
4. **Scheduled** - Executes tasks with delays or at fixed rates
5. **Single** - Single-threaded executor for sequential execution
6. **Fork-Join** - Recursive task decomposition (divide-and-conquer)
7. **Work-Stealing** - Efficient load balancing across threads

### Pre-Configured Runtime Executors

BoxLang runtime provides three pre-configured executors:

```boxlang
// Get pre-configured executors
ioExecutor = executorGet( "io-tasks" )        // Virtual threads for I/O
cpuExecutor = executorGet( "cpu-tasks" )      // Scheduled pool for CPU work
scheduledExecutor = executorGet( "scheduled-tasks" ) // For scheduled tasks
```

**Runtime Executor Configuration** (boxlang.json):
```json
{
    "executors": {
        "io-tasks": {
            "type": "virtual"
        },
        "cpu-tasks": {
            "type": "scheduled",
            "threads": 10
        },
        "scheduled-tasks": {
            "type": "scheduled",
            "threads": 10
        }
    }
}
```

## Creating Executors

### Virtual Thread Executor

```boxlang
// Create virtual thread executor (best for I/O-bound tasks)
executor = executorNew( "virtual", "my-io-executor" )

// Execute tasks on virtual threads
future1 = executor.submit( () => fetchFromAPI() )
future2 = executor.submit( () => queryDatabase() )
future3 = executor.submit( () => readLargeFile() )

// Wait for all
results = [ future1.get(), future2.get(), future3.get() ]
```

**When to Use Virtual Threads:**
- ✅ High concurrency scenarios (thousands of threads)
- ✅ I/O-bound operations (HTTP calls, database queries, file I/O)
- ✅ Blocking operations (network, disk)
- ✅ Scalable concurrent applications

**When NOT to Use Virtual Threads:**
- ❌ CPU-intensive computations
- ❌ Operations using synchronized blocks heavily
- ❌ Code requiring thread-local storage

### Fixed Thread Pool

```boxlang
// Create fixed-size thread pool (best for CPU-bound tasks)
executor = executorNew( 
    type = "fixed",
    name = "cpu-pool",
    threads = 8 // Number of threads
)

// Submit CPU-intensive tasks
futures = []
for ( i = 1; i <= 100; i++ ) {
    future = executor.submit( () => complexCalculation( i ) )
    futures.append( future )
}

// Collect results
results = futures.map( ( f ) => f.get() )
```

**Use Fixed Pool When:**
- ✅ CPU-bound tasks
- ✅ Predictable workload
- ✅ Want to limit resource usage
- ✅ Need deterministic thread count

### Cached Thread Pool

```boxlang
// Create cached thread pool (grows/shrinks dynamically)
executor = executorNew( "cached", "dynamic-pool" )

// Submits tasks - pool grows as needed
for ( task in tasks ) {
    executor.submit( () => processTask( task ) )
}

// Idle threads are removed after 60 seconds
```

**Use Cached Pool When:**
- ✅ Variable workload
- ✅ Short-lived tasks
- ✅ Bursty traffic patterns
- ✅ Need dynamic scaling

### Scheduled Executor

```boxlang
// Create scheduled executor for delayed/periodic tasks
executor = executorNew( 
    type = "scheduled",
    name = "scheduled-pool",
    threads = 5
)

// Schedule one-time delayed task
future = executor.scheduleOnce( 
    () => performMaintenance(),
    5,      // delay
    "seconds"
)

// Schedule recurring task
future = executor.scheduleAtFixedRate(
    () => healthCheck(),
    0,      // initial delay
    30,     // period
    "seconds"
)

// Schedule with fixed delay between executions
future = executor.scheduleWithFixedDelay(
    () => processQueue(),
    10,     // initial delay
    5,      // delay between executions
    "seconds"
)
```

**Use Scheduled Executor When:**
- ✅ Delayed task execution
- ✅ Periodic background jobs
- ✅ Health checks and monitoring
- ✅ Retry mechanisms

### Single Thread Executor

```boxlang
// Create single-threaded executor for sequential execution
executor = executorNew( "single", "sequential-processor" )

// All tasks execute sequentially in order
executor.submit( () => step1() )
executor.submit( () => step2() )
executor.submit( () => step3() )
// Guarantees execution order: step1 → step2 → step3
```

**Use Single Thread Executor When:**
- ✅ Tasks must execute sequentially
- ✅ Order preservation required
- ✅ Shared state without synchronization
- ✅ Event processing queues

### Fork-Join Executor

```boxlang
// Create fork-join pool for recursive divide-and-conquer
executor = executorNew( 
    type = "fork_join",
    name = "fork-join-pool",
    parallelism = 8 // Parallelism level
)

// Submit recursive task
result = executor.submit( () => {
    return recursiveFibonacci( 40 )
} ).get()
```

**Use Fork-Join When:**
- ✅ Recursive algorithms
- ✅ Divide-and-conquer problems
- ✅ Tree/graph traversal
- ✅ Parallel array processing

### Work-Stealing Executor

```boxlang
// Create work-stealing pool for balanced load distribution
executor = executorNew( 
    type = "work_stealing",
    name = "work-steal-pool",
    parallelism = 8
)

// Tasks are automatically load-balanced across threads
for ( i = 1; i <= 1000; i++ ) {
    executor.submit( () => processItem( i ) )
}
```

**Use Work-Stealing When:**
- ✅ Varying task durations
- ✅ Need automatic load balancing
- ✅ Many small tasks
- ✅ Optimal CPU utilization desired

## Executor Operations

### Submitting Tasks

```boxlang
executor = executorNew( "fixed", "my-pool", 4 )

// Submit callable (returns result)
future = executor.submit( () => {
    return calculateValue()
} )
result = future.get()

// Submit runnable (no result)
executor.submit( () => {
    logMessage( "Task executed" )
} )

// Submit multiple tasks
futures = []
for ( i = 1; i <= 10; i++ ) {
    futures.append( executor.submit( () => processItem( i ) ) )
}

// Wait for all completions
results = futures.map( ( f ) => f.get() )
```

### Executor Control

```boxlang
// Check executor status
if ( !executor.isShutdown() ) {
    println( "Executor is active" )
}

if ( executor.isTerminated() ) {
    println( "Executor has terminated" )
}

// Get pool statistics
stats = executor.getStatistics()
println( "Active threads: #stats.activeCount#" )
println( "Completed tasks: #stats.completedTaskCount#" )
println( "Pool size: #stats.poolSize#" )
```

### Executor Shutdown

```boxlang
// Graceful shutdown (waits for running tasks)
executor.shutdown()

// Wait for termination
executor.awaitTermination( 30, "seconds" )

// Force shutdown (interrupts running tasks)
executor.shutdownNow()

// Complete shutdown pattern
try {
    executor.shutdown()
    
    if ( !executor.awaitTermination( 30, "seconds" ) ) {
        // Timeout - force shutdown
        executor.shutdownNow()
        
        // Wait again for force shutdown
        if ( !executor.awaitTermination( 10, "seconds" ) ) {
            logger.error( "Executor did not terminate" )
        }
    }
} catch ( any e ) {
    executor.shutdownNow()
    throw e
}
```

## Real-World Patterns

### Parallel Data Processing

```boxlang
/**
 * ParallelProcessor.bx
 * Process large datasets in parallel
 */
class {
    property name="executor"
    property name="logger"
    
    function init( parallelism = 8 ) {
        variables.executor = executorNew( 
            type = "work_stealing",
            name = "parallel-processor",
            parallelism = parallelism
        )
        variables.logger = getLogger()
        return this
    }
    
    /**
     * Process items in parallel batches
     */
    function process( items, processorFunction ) {
        startTime = getTickCount()
        logger.info( "Processing #items.len()# items" )
        
        // Submit all items for parallel processing
        futures = items.map( ( item ) => {
            return executor.submit( () => processorFunction( item ) )
        } )
        
        // Collect results
        results = futures.map( ( future ) => {
            try {
                return { success: true, data: future.get() }
            } catch ( any e ) {
                logger.error( "Processing failed: #e.message#" )
                return { success: false, error: e.message }
            }
        } )
        
        duration = getTickCount() - startTime
        successCount = results.filter( ( r ) => r.success ).len()
        
        logger.info( "Processed #successCount# of #items.len()# items in #duration#ms" )
        
        return results
    }
    
    /**
     * Cleanup
     */
    function onDestroy() {
        executor.shutdown()
        executor.awaitTermination( 10, "seconds" )
    }
}

// Usage
processor = new ParallelProcessor( parallelism = 8 )

results = processor.process( 
    dataArray,
    ( item ) => {
        // Process each item
        return transformData( item )
    }
)
```

### Background Job Processor

```boxlang
/**
 * BackgroundJobService.bx
 * Process background jobs with virtual threads
 */
class {
    property name="ioExecutor"
    property name="cpuExecutor"
    property name="logger"
    
    function init() {
        // Use pre-configured executors
        variables.ioExecutor = executorGet( "io-tasks" )
        variables.cpuExecutor = executorGet( "cpu-tasks" )
        variables.logger = getLogger()
        return this
    }
    
    /**
     * Submit I/O-bound job (API calls, database, files)
     */
    function submitIOJob( jobFunction ) {
        return variables.ioExecutor.submit( () => {
            logger.debug( "Starting I/O job on virtual thread" )
            try {
                result = jobFunction()
                logger.debug( "I/O job completed successfully" )
                return result
            } catch ( any e ) {
                logger.error( "I/O job failed: #e.message#" )
                throw e
            }
        } )
    }
    
    /**
     * Submit CPU-bound job (calculations, transformations)
     */
    function submitCPUJob( jobFunction ) {
        return variables.cpuExecutor.submit( () => {
            logger.debug( "Starting CPU job on fixed thread pool" )
            try {
                result = jobFunction()
                logger.debug( "CPU job completed successfully" )
                return result
            } catch ( any e ) {
                logger.error( "CPU job failed: #e.message#" )
                throw e
            }
        } )
    }
    
    /**
     * Process mixed workload optimally
     */
    function processMixedWorkload( ioTasks, cpuTasks ) {
        // Submit I/O tasks to virtual thread executor
        ioFutures = ioTasks.map( ( task ) => submitIOJob( task ) )
        
        // Submit CPU tasks to fixed thread pool
        cpuFutures = cpuTasks.map( ( task ) => submitCPUJob( task ) )
        
        // Wait for all completions
        return {
            ioResults: ioFutures.map( ( f ) => f.get() ),
            cpuResults: cpuFutures.map( ( f ) => f.get() )
        }
    }
}

// Usage
jobService = new BackgroundJobService()

// Submit I/O-bound jobs (thousands possible with virtual threads)
apiResults = jobService.submitIOJob( () => fetchFromAPI() ).get()
dbResults = jobService.submitIOJob( () => queryDatabase() ).get()

// Submit CPU-bound jobs (limited by pool size)
calcResult = jobService.submitCPUJob( () => complexCalculation() ).get()
```

### Scheduled Task Manager

```boxlang
/**
 * ScheduledTaskManager.bx
 * Manage scheduled background tasks
 */
class {
    property name="executor"
    property name="tasks" type="struct"
    property name="logger"
    
    function init() {
        variables.executor = executorNew( 
            type = "scheduled",
            name = "task-scheduler",
            threads = 10
        )
        variables.tasks = {}
        variables.logger = getLogger()
        return this
    }
    
    /**
     * Schedule recurring task
     */
    function scheduleRecurring( name, taskFunction, interval, unit = "seconds" ) {
        logger.info( "Scheduling recurring task: #name#" )
        
        future = executor.scheduleAtFixedRate(
            () => {
                try {
                    logger.debug( "Executing task: #name#" )
                    taskFunction()
                } catch ( any e ) {
                    logger.error( "Task #name# failed: #e.message#" )
                }
            },
            0,          // initial delay
            interval,   // period
            unit
        )
        
        variables.tasks[ name ] = {
            future: future,
            type: "recurring",
            interval: interval,
            unit: unit
        }
        
        return this
    }
    
    /**
     * Schedule one-time delayed task
     */
    function scheduleOnce( name, taskFunction, delay, unit = "seconds" ) {
        logger.info( "Scheduling one-time task: #name# (delay: #delay# #unit#)" )
        
        future = executor.scheduleOnce(
            () => {
                try {
                    logger.debug( "Executing one-time task: #name#" )
                    taskFunction()
                } catch ( any e ) {
                    logger.error( "Task #name# failed: #e.message#" )
                } finally {
                    // Remove from tracking
                    structDelete( variables.tasks, name )
                }
            },
            delay,
            unit
        )
        
        variables.tasks[ name ] = {
            future: future,
            type: "once",
            delay: delay,
            unit: unit
        }
        
        return this
    }
    
    /**
     * Cancel task
     */
    function cancelTask( name ) {
        if ( structKeyExists( variables.tasks, name ) ) {
            task = variables.tasks[ name ]
            task.future.cancel( true )
            structDelete( variables.tasks, name )
            logger.info( "Cancelled task: #name#" )
        }
    }
    
    /**
     * Get task status
     */
    function getTaskStatus( name ) {
        if ( !structKeyExists( variables.tasks, name ) ) {
            return { exists: false }
        }
        
        task = variables.tasks[ name ]
        return {
            exists: true,
            type: task.type,
            cancelled: task.future.isCancelled(),
            done: task.future.isDone()
        }
    }
    
    /**
     * Shutdown
     */
    function shutdown() {
        logger.info( "Shutting down task manager" )
        executor.shutdown()
        executor.awaitTermination( 30, "seconds" )
    }
}

// Usage
taskManager = new ScheduledTaskManager()

// Schedule recurring health check every 30 seconds
taskManager.scheduleRecurring( 
    "health-check",
    () => performHealthCheck(),
    30,
    "seconds"
)

// Schedule cleanup task every hour
taskManager.scheduleRecurring(
    "cleanup",
    () => cleanupTempFiles(),
    1,
    "hours"
)

// Schedule one-time task in 5 minutes
taskManager.scheduleOnce(
    "delayed-report",
    () => generateReport(),
    5,
    "minutes"
)
```

## Configuration and Tuning

### Choosing Thread Pool Size

```boxlang
// CPU-bound tasks: cores or cores + 1
cpuCores = getAvailableProcessors()
cpuExecutor = executorNew( 
    type = "fixed",
    name = "cpu-pool",
    threads = cpuCores
)

// I/O-bound tasks: much larger or use virtual threads
ioExecutor = executorNew( "virtual", "io-pool" ) // Unlimited

// Mixed workload: 2 * cores
mixedExecutor = executorNew(
    type = "fixed",
    name = "mixed-pool",
    threads = cpuCores * 2
)
```

### Executor Pool Sizing Guidelines

**CPU-Bound Tasks:**
- Pool size = Number of CPU cores
- Goal: Keep all cores busy without context switching

**I/O-Bound Tasks:**
- Traditional: Pool size = cores * (1 + wait time / compute time)
- Modern: Use virtual threads (unlimited)

**Mixed Workload:**
- Pool size = 2 * cores
- Or use separate pools for I/O and CPU

## Best Practices

### Design Guidelines

1. **Choose Right Executor**: Match executor type to workload
2. **Virtual for I/O**: Use virtual threads for I/O-bound operations
3. **Fixed for CPU**: Use fixed pools for CPU-intensive tasks
4. **Reuse Executors**: Don't create new executors for each operation
5. **Proper Shutdown**: Always shutdown executors gracefully
6. **Error Handling**: Handle exceptions in submitted tasks
7. **Monitor Statistics**: Track executor performance
8. **Avoid Blocking**: Don't block in executor threads
9. **Task Sizing**: Balance task granularity (not too small/large)
10. **Resource Limits**: Set appropriate pool sizes

### Common Patterns

```boxlang
// ✅ Good: Reuse executor
executor = executorNew( "fixed", "shared-pool", 8 )
for ( i = 1; i <= 100; i++ ) {
    executor.submit( () => process( i ) )
}
executor.shutdown()

// ❌ Bad: Create executor per task
for ( i = 1; i <= 100; i++ ) {
    executor = executorNew( "fixed", "pool-#i#", 8 ) // Wasteful!
    executor.submit( () => process( i ) )
    executor.shutdown()
}

// ✅ Good: Handle errors in tasks
executor.submit( () => {
    try {
        riskyOperation()
    } catch ( any e ) {
        logger.error( "Task failed: #e.message#" )
    }
} )

// ✅ Good: Use appropriate executor
ioExecutor = executorGet( "io-tasks" )        // I/O work
cpuExecutor = executorGet( "cpu-tasks" )      // CPU work
```

## Common Pitfalls

### Pitfalls to Avoid

1. **Wrong Executor Type**: Using fixed pool for I/O or virtual threads for CPU
2. **Too Many Threads**: Over-sized fixed pools cause context switching
3. **No Shutdown**: Executors prevent JVM shutdown if not terminated
4. **Blocking Virtual Threads**: Using synchronized blocks with virtual threads
5. **Task Exceptions**: Unhandled exceptions silently fail tasks
6. **No Timeouts**: Tasks can hang indefinitely
7. **Resource Leaks**: Not closing executor on application shutdown
8. **Shared State**: Concurrent access without synchronization
9. **Deadlocks**: Improper locking or task dependencies
10. **Memory Leaks**: Holding references to completed futures

### Troubleshooting

```boxlang
// Debug executor state
stats = executor.getStatistics()
logger.debug( "Active threads: #stats.activeCount#" )
logger.debug( "Pool size: #stats.poolSize#" )
logger.debug( "Completed tasks: #stats.completedTaskCount#" )
logger.debug( "Queue size: #stats.queueSize#" )

// Check for shutdown issues
if ( !executor.isShutdown() ) {
    logger.warn( "Executor not shutdown - forcing shutdown" )
    executor.shutdownNow()
}

// Monitor task completion
future = executor.submit( () => longTask() )
if ( !future.isDone() ) {
    logger.warn( "Task still running after expected completion" )
}
```

## Related Skills

- [BoxLang Futures](boxlang-futures.md) - Async programming and BoxFutures
- [BoxLang Scheduled Tasks](boxlang-scheduled-tasks.md) - Scheduling framework
- [BoxLang Threading](boxlang-syntax.md#threading) - Threading basics

## References

- [BoxLang Async Programming](https://boxlang.ortusbooks.com/boxlang-framework/asynchronous-programming)
- [BoxLang Threading](https://boxlang.ortusbooks.com/boxlang-language/syntax/threading)
- [ExecutorNew BIF](https://boxlang.ortusbooks.com/boxlang-language/reference/built-in-functions/async/executornew)
- [BoxLang 1.0.0-RC.3](https://boxlang.ortusbooks.com/readme/release-history/rc-stage/1.0.0-rc.3)
