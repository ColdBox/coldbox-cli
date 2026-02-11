---
name: BoxLang Scheduled Tasks
description: Comprehensive guide to scheduling tasks in BoxLang using the scheduler framework, including cron patterns, task configuration, lifecycle callbacks, and distributed scheduling
category: boxlang
priority: medium
triggers:
  - schedule
  - scheduled task
  - cron
  - task scheduler
  - periodic task
  - background job
  - recurring task
  - job scheduling
  - BaseScheduler
---

# BoxLang Scheduled Tasks

## Overview

BoxLang provides a powerful async framework for scheduling tasks with a human-readable DSL. The scheduler supports both one-off and periodic tasks with flexible configuration options including cron patterns, frequency-based scheduling, task registration, and lifecycle callbacks.

## Core Concepts

### Three Scheduling Approaches

1. **Scheduler Class Approach**: Create self-contained scheduler classes that inherit from BaseScheduler
2. **Scheduled Executor Approach**: Send task objects directly to ScheduledExecutor instances
3. **CLI Runner Approach**: Run schedulers from command line using `boxlang schedule {path.to.Scheduler.bx}`

### Task Types

- **One-off Tasks**: Execute once at a specific time or after a delay
- **Periodic Tasks**: Execute repeatedly at fixed intervals or cron schedules
- **Lambda Tasks**: Inline closures for quick task definitions
- **Component Tasks**: Full-featured task classes with lifecycle methods

## Scheduler Class Structure

### Basic Scheduler Template

```boxlang
/**
 * MyScheduler.bx - Application scheduler
 * Defines all scheduled tasks for the application
 */
class {
    // Automatic property injections from BoxLang runtime
    property name="scheduler"           // BaseScheduler instance
    property name="runtime"            // BoxRuntime instance
    property name="logger"             // Logger for this scheduler
    property name="asyncService"       // AsyncService for executors
    property name="cacheService"       // CacheService for distribution
    property name="interceptorService" // InterceptorService for events

    /**
     * Configure scheduler and register tasks
     * Called by BoxLang runtime during initialization
     */
    function configure() {
        // Setup scheduler properties
        scheduler
            .setSchedulerName( "MyApp-Scheduler" )
            .setTimezone( "America/New_York" )
            .setExecutor( "scheduled-tasks" ) // Use specific executor

        // Register tasks
        registerCleanupTasks()
        registerReportTasks()
        registerMonitoringTasks()
    }

    /**
     * Register cleanup tasks
     */
    private function registerCleanupTasks() {
        // Clean temp files daily at midnight
        scheduler.task( "cleanup-temp-files" )
            .call( () => cleanTempFiles() )
            .everyDayAt( "00:00" )

        // Cleanup old sessions every 15 minutes
        scheduler.task( "cleanup-sessions" )
            .call( () => cleanExpiredSessions() )
            .every( 15, "minutes" )
    }

    /**
     * Register reporting tasks
     */
    private function registerReportTasks() {
        // Generate daily report at 6 AM
        scheduler.task( "daily-report" )
            .call( () => generateDailyReport() )
            .everyDayAt( "06:00" )
            .onFailure( ( task, exception ) => {
                logger.error( "Daily report failed: #exception.message#" )
                notifyAdmins( "Daily report generation failed" )
            } )

        // Weekly summary every Monday at 8 AM
        scheduler.task( "weekly-summary" )
            .call( () => generateWeeklySummary() )
            .onWeekdays( "Monday" )
            .at( "08:00" )
    }

    /**
     * Register monitoring tasks
     */
    private function registerMonitoringTasks() {
        // Health check every 5 minutes
        scheduler.task( "health-check" )
            .call( () => performHealthCheck() )
            .every( 5, "minutes" )

        // Monitor disk space every hour
        scheduler.task( "disk-monitor" )
            .call( () => checkDiskSpace() )
            .everyHourAt( 0 ) // At minute 0 of every hour
    }

    // Lifecycle Callbacks

    void function onStartup() {
        logger.info( "Scheduler started: #scheduler.getSchedulerName()#" )
    }

    void function onShutdown() {
        logger.info( "Scheduler shutdown: #scheduler.getSchedulerName()#" )
    }

    function onAnyTaskError( task, exception ) {
        logger.error(
            "Task [#task.getName()#] failed: #exception.message#",
            { task: task.getName(), error: exception }
        )
    }

    function onAnyTaskSuccess( task, result ) {
        logger.debug( "Task [#task.getName()#] completed successfully" )
    }

    function beforeAnyTask( task ) {
        logger.trace( "Starting task: #task.getName()#" )
    }

    function afterAnyTask( task, result ) {
        logger.trace( "Completed task: #task.getName()#" )
    }

    // Helper Methods

    private function cleanTempFiles() {
        // Implementation
    }

    private function cleanExpiredSessions() {
        // Implementation
    }

    private function generateDailyReport() {
        // Implementation
    }

    private function generateWeeklySummary() {
        // Implementation
    }

    private function performHealthCheck() {
        // Implementation
    }

    private function checkDiskSpace() {
        // Implementation
    }

    private function notifyAdmins( message ) {
        // Implementation
    }
}
```

## Task Configuration DSL

### Frequency-Based Scheduling

```boxlang
// Every X time units
scheduler.task( "frequent-task" )
    .call( () => doWork() )
    .every( 5, "seconds" )

scheduler.task( "hourly-task" )
    .call( () => doWork() )
    .every( 1, "hour" )

scheduler.task( "daily-task" )
    .call( () => doWork() )
    .every( 1, "day" )

// Time unit options: second/seconds, minute/minutes, hour/hours, day/days, week/weeks
```

### Time-Based Scheduling

```boxlang
// Daily at specific time
scheduler.task( "morning-task" )
    .call( () => runMorningRoutine() )
    .everyDayAt( "08:00" )

// Hourly at specific minute
scheduler.task( "hourly-report" )
    .call( () => generateHourlyReport() )
    .everyHourAt( 15 ) // At minute 15

// Weekday scheduling
scheduler.task( "weekday-task" )
    .call( () => weekdayWork() )
    .onWeekdays( "Monday" )
    .at( "09:00" )

// Multiple weekdays
scheduler.task( "business-days" )
    .call( () => businessDayTask() )
    .onWeekdays( [ "Monday", "Tuesday", "Wednesday", "Thursday", "Friday" ] )
    .at( "08:00" )
```

### Cron Expression Scheduling

```boxlang
// Using cron expressions for complex patterns
scheduler.task( "complex-schedule" )
    .call( () => complexTask() )
    .cron( "0 15 10 * * ?" ) // 10:15 AM every day

// Cron format: second minute hour day month weekday
scheduler.task( "business-hours" )
    .call( () => businessHoursTask() )
    .cron( "0 0 9-17 * * MON-FRI" ) // Every hour 9-5, Mon-Fri

// Last day of month at midnight
scheduler.task( "month-end" )
    .call( () => monthEndProcessing() )
    .cron( "0 0 0 L * ?" )
```

### One-Time Delayed Tasks

```boxlang
// Run once after delay
scheduler.task( "delayed-task" )
    .call( () => startupTask() )
    .delay( 30, "seconds" )
    .onlyOnce()

// Run once at specific time
scheduler.task( "scheduled-maintenance" )
    .call( () => performMaintenance() )
    .runAt( dateAdd( "h", 2, now() ) )
    .onlyOnce()
```

## Task Configuration Options

### Constraints and Conditions

```boxlang
// Run only when condition is true
scheduler.task( "conditional-task" )
    .call( () => conditionalWork() )
    .every( 1, "hour" )
    .when( () => isMaintenanceWindow() )

// Skip when condition is true
scheduler.task( "skip-task" )
    .call( () => normalWork() )
    .every( 30, "minutes" )
    .skip( () => isHighTraffic() )

// Limit days
scheduler.task( "weekend-task" )
    .call( () => weekendWork() )
    .every( 1, "hour" )
    .onWeekends()

// Exclude specific dates
scheduler.task( "business-task" )
    .call( () => businessTask() )
    .everyDayAt( "09:00" )
    .exclude( [ "2024-12-25", "2024-01-01" ] ) // Skip holidays
```

### Task Metadata and Grouping

```boxlang
// Add metadata to tasks
scheduler.task( "tagged-task" )
    .call( () => work() )
    .every( 10, "minutes" )
    .group( "maintenance" )
    .withMetadata( {
        priority: "high",
        owner: "ops-team",
        alertOnFailure: true
    } )

// Group related tasks
scheduler.task( "cleanup-logs" )
    .call( () => cleanLogs() )
    .everyDayAt( "01:00" )
    .group( "cleanup" )

scheduler.task( "cleanup-cache" )
    .call( () => cleanCache() )
    .everyDayAt( "02:00" )
    .group( "cleanup" )
```

### Error Handling and Retries

```boxlang
// Configure retry behavior
scheduler.task( "resilient-task" )
    .call( () => unreliableOperation() )
    .every( 5, "minutes" )
    .retry( 3 ) // Retry 3 times on failure
    .retryDelay( 10, "seconds" ) // Wait 10 seconds between retries
    .onFailure( ( task, exception ) => {
        logger.error( "Task failed after retries: #exception.message#" )
        notifyOps( task, exception )
    } )
    .onSuccess( ( task, result ) => {
        logger.info( "Task succeeded: #task.getName()#" )
    } )
```

## Component-Based Tasks

### Creating Task Components

```boxlang
/**
 * DatabaseBackupTask.bx
 * Component-based task with full lifecycle
 */
class {
    property name="databaseService" inject="DatabaseService"
    property name="storageService" inject="StorageService"
    property name="logger" inject="logbox:logger:{this}"

    /**
     * Main task execution
     * Called by scheduler when task runs
     */
    function run() {
        logger.info( "Starting database backup" )

        try {
            // Perform backup
            backupFile = databaseService.createBackup()

            // Upload to storage
            storageService.upload( backupFile, "backups/" )

            // Cleanup local file
            fileDelete( backupFile )

            logger.info( "Database backup completed successfully" )

            return {
                success: true,
                file: backupFile,
                timestamp: now()
            }
        } catch ( any e ) {
            logger.error( "Backup failed: #e.message#", e )
            throw e
        }
    }

    /**
     * Called before task executes
     */
    function before() {
        logger.debug( "Preparing backup environment" )
        // Pre-execution setup
    }

    /**
     * Called after task executes (success or failure)
     */
    function after() {
        logger.debug( "Cleanup after backup" )
        // Post-execution cleanup
    }

    /**
     * Called only on successful execution
     */
    function onSuccess( result ) {
        logger.info( "Backup successful: #result.file#" )
        // Success handling
    }

    /**
     * Called only on task failure
     */
    function onError( exception ) {
        logger.error( "Backup failed: #exception.message#" )
        // Error handling, notifications
    }
}
```

### Registering Component Tasks

```boxlang
// In scheduler configure()
function configure() {
    // Register component task
    scheduler.task( "database-backup" )
        .call( new DatabaseBackupTask() )
        .everyDayAt( "02:00" )
        .timezone( "UTC" )

    // Alternative: Register by path
    scheduler.task( "email-queue-processor" )
        .call( "tasks.EmailQueueProcessor" )
        .every( 1, "minute" )
}
```

## Advanced Scheduling Patterns

### Dynamic Task Registration

```boxlang
/**
 * Dynamically register tasks based on configuration
 */
function configure() {
    // Load task configuration
    taskConfig = getTaskConfiguration()

    // Register tasks dynamically
    taskConfig.each( ( config ) => {
        scheduler.task( config.name )
            .call( () => executeConfiguredTask( config ) )
            .cron( config.schedule )
            .when( () => config.enabled )
    } )
}

private function executeConfiguredTask( config ) {
    // Dynamic task execution based on config
    switch ( config.type ) {
        case "cleanup":
            cleanupService.execute( config.params )
            break
        case "report":
            reportService.generate( config.params )
            break
        case "sync":
            syncService.sync( config.params )
            break
    }
}
```

### Distributed Task Coordination

```boxlang
/**
 * Prevent duplicate execution across server cluster
 */
function configure() {
    // Task runs on only one server in cluster
    scheduler.task( "singleton-task" )
        .call( () => criticalTask() )
        .every( 5, "minutes" )
        .distributedExecution() // Ensure only one instance runs
        .withLock( "singleton-task-lock" )
}

/**
 * Use cache service for distributed locking
 */
scheduler.task( "distributed-cleanup" )
    .call( () => {
        // Acquire distributed lock
        if ( cacheService.tryLock( "cleanup-lock", 300 ) ) {
            try {
                performCleanup()
            } finally {
                cacheService.unlock( "cleanup-lock" )
            }
        }
    } )
    .everyHourAt( 0 )
```

### Task Chains and Dependencies

```boxlang
/**
 * Execute tasks in sequence with dependencies
 */
function configure() {
    // Step 1: Data extraction
    scheduler.task( "extract-data" )
        .call( () => extractData() )
        .everyDayAt( "02:00" )
        .onSuccess( ( task, result ) => {
            // Trigger next task in chain
            scheduler.run( "transform-data" )
        } )

    // Step 2: Data transformation (manual trigger only)
    scheduler.task( "transform-data" )
        .call( () => transformData() )
        .manual() // Only runs when explicitly triggered
        .onSuccess( ( task, result ) => {
            // Trigger final task
            scheduler.run( "load-data" )
        } )

    // Step 3: Data loading (manual trigger only)
    scheduler.task( "load-data" )
        .call( () => loadData() )
        .manual()
}
```

## Configuration and Deployment

### BoxLang Configuration

```json
// boxlang.json
{
    "scheduler": {
        // Default executor for all schedulers
        "executor": "scheduled-tasks",

        // Cache for distributed scheduling
        "cacheName": "default",

        // Auto-register scheduler files
        "schedulers": [
            "${user-dir}/schedulers/MainScheduler.bx",
            "${user-dir}/schedulers/MaintenanceScheduler.bx"
        ],

        // Manual task definitions (alternative to scheduler classes)
        "tasks": {
            "system-health": {
                "crontime": "*/5 * * * *",
                "eventhandler": "${user-dir}/tasks/SystemHealthTask.bx",
                "group": "monitoring",
                "file": "health-check"
            }
        }
    },

    // Executor configuration
    "executors": {
        "scheduled-tasks": {
            "type": "scheduled",
            "threads": 20
        },
        "background-jobs": {
            "type": "virtual"
        }
    }
}
```

### CLI Task Execution

```bash
# Run scheduler from command line
boxlang schedule /path/to/MyScheduler.bx

# With environment variables
BOXLANG_ENV=production boxlang schedule /app/schedulers/MainScheduler.bx

# Run specific task
boxlang run-task MainScheduler daily-report

# Force task execution (ignoring constraints)
boxlang run-task MainScheduler daily-report --force
```

## Monitoring and Introspection

### Task Statistics and Status

```boxlang
/**
 * Monitor scheduler and task status
 */
class MonitoringScheduler {
    property name="scheduler"

    function configure() {
        // Stats monitoring task
        scheduler.task( "report-stats" )
            .call( () => reportSchedulerStats() )
            .every( 5, "minutes" )
    }

    private function reportSchedulerStats() {
        // Get scheduler statistics
        stats = scheduler.getStatistics()

        logger.info( "Scheduler Stats", {
            totalTasks: stats.totalTasks,
            runningTasks: stats.runningTasks,
            completedTasks: stats.completedTasks,
            failedTasks: stats.failedTasks,
            successRate: stats.successRate
        } )

        // Get individual task stats
        scheduler.getTasks().each( ( taskName, task ) => {
            taskStats = task.getStatistics()

            logger.debug( "Task: #taskName#", {
                executions: taskStats.executions,
                failures: taskStats.failures,
                lastRun: taskStats.lastRun,
                nextRun: taskStats.nextRun,
                avgDuration: taskStats.avgDuration
            } )
        } )
    }
}
```

### Task State Management

```boxlang
// Check task status
taskStatus = scheduler.getTaskStatus( "my-task" )
if ( taskStatus.isRunning() ) {
    println( "Task is currently running" )
}

// Get task history
history = scheduler.getTaskHistory( "my-task", limit = 10 )
history.each( ( execution ) => {
    println( "Run: #execution.timestamp# - Status: #execution.status#" )
} )

// Pause/Resume tasks
scheduler.pauseTask( "maintenance-task" )
scheduler.resumeTask( "maintenance-task" )

// Cancel running task
scheduler.cancelTask( "long-running-task" )

// Remove task from scheduler
scheduler.removeTask( "obsolete-task" )
```

## Time Zone Handling

### Time Zone Configuration

```boxlang
// Set scheduler timezone
scheduler.setTimezone( "America/Los_Angeles" )

// Per-task timezone
scheduler.task( "tokyo-report" )
    .call( () => generateReport() )
    .everyDayAt( "09:00" )
    .timezone( "Asia/Tokyo" )

// UTC for consistency
scheduler.task( "global-sync" )
    .call( () => syncData() )
    .everyHourAt( 0 )
    .timezone( "UTC" )
```

### Time Unit Formats

```boxlang
// BoxLang accepts multiple time unit formats
scheduler.task( "flexible-timing" )
    .call( () => work() )
    .every( 5, "seconds" ) // or "second", "s", "sec"
    .delay( 10, "minutes" ) // or "minute", "m", "min"
    .timeout( 1, "hour" )   // or "hours", "h", "hr"
```

## Testing Strategies

### Testing Scheduler Configuration

```boxlang
/**
 * SchedulerSpec.bx - TestBox spec for scheduler
 */
component extends="testbox.system.BaseSpec" {

    function beforeAll() {
        scheduler = new MyScheduler()
        scheduler.configure()
    }

    function run() {
        describe( "MyScheduler", () => {

            it( "should register all required tasks", () => {
                tasks = scheduler.scheduler.getTasks()

                expect( tasks ).toHaveKey( "cleanup-temp-files" )
                expect( tasks ).toHaveKey( "daily-report" )
                expect( tasks ).toHaveKey( "health-check" )
            } )

            it( "should configure daily report correctly", () => {
                task = scheduler.scheduler.getTask( "daily-report" )

                expect( task.getSchedule() ).toBe( "0 0 6 * * ?" )
                expect( task.getGroup() ).toBe( "reports" )
            } )

            it( "should execute cleanup task successfully", () => {
                task = scheduler.scheduler.getTask( "cleanup-temp-files" )

                // Execute task synchronously for testing
                result = task.run()

                expect( result.success ).toBeTrue()
            } )
        } )
    }
}
```

### Testing Task Components

```boxlang
/**
 * DatabaseBackupTaskSpec.bx
 */
component extends="testbox.system.BaseSpec" {

    function beforeAll() {
        task = new DatabaseBackupTask()
        mockDatabaseService = createMock( "DatabaseService" )
        mockStorageService = createMock( "StorageService" )

        task.databaseService = mockDatabaseService
        task.storageService = mockStorageService
    }

    function run() {
        describe( "DatabaseBackupTask", () => {

            it( "should create and upload backup successfully", () => {
                mockDatabaseService
                    .$( "createBackup" )
                    .$results( "/tmp/backup-123.sql" )

                mockStorageService
                    .$( "upload" )
                    .$args( "/tmp/backup-123.sql", "backups/" )

                result = task.run()

                expect( result.success ).toBeTrue()
                expect( mockDatabaseService.$once( "createBackup" ) ).toBeTrue()
                expect( mockStorageService.$once( "upload" ) ).toBeTrue()
            } )

            it( "should handle backup failures gracefully", () => {
                mockDatabaseService
                    .$( "createBackup" )
                    .$throws( type = "DatabaseException", message = "Connection failed" )

                expect( () => task.run() ).toThrow( "DatabaseException" )
            } )
        } )
    }
}
```

## Best Practices

### Design Guidelines

1. **Single Responsibility**: Each task should have one clear purpose
2. **Idempotency**: Tasks should handle re-execution safely
3. **Timeout Protection**: Always configure appropriate timeouts
4. **Error Handling**: Implement comprehensive error handling and logging
5. **Resource Cleanup**: Ensure resources are released even on failure
6. **Monitoring**: Log execution start, completion, and failures
7. **Graceful Degradation**: Handle external service failures gracefully

### Performance Optimization

```boxlang
// Use appropriate executors
scheduler
    .setExecutor( "io-tasks" ) // For I/O-bound tasks
    // or
    .setExecutor( "cpu-tasks" ) // For CPU-intensive tasks

// Avoid overlapping executions
scheduler.task( "long-task" )
    .call( () => longRunningTask() )
    .every( 5, "minutes" )
    .skipIfRunning() // Don't start new execution if still running

// Limit concurrent task executions
scheduler.task( "concurrent-task" )
    .call( () => concurrentWork() )
    .every( 1, "minute" )
    .maxConcurrent( 3 ) // Allow max 3 concurrent executions
```

### Security Considerations

```boxlang
// Secure sensitive data in tasks
scheduler.task( "api-sync" )
    .call( () => {
        // Load credentials from secure source
        apiKey = getApplicationSetting( "secure:apiKey" )

        // Don't log sensitive data
        logger.info( "Starting API sync" ) // Good
        logger.info( "API Key: #apiKey#" ) // NEVER DO THIS

        syncWithAPI( apiKey )
    } )
    .everyHourAt( 0 )

// Validate task inputs
scheduler.task( "process-files" )
    .call( () => {
        files = getFilesToProcess()

        // Validate before processing
        files.each( ( file ) => {
            if ( !isValidFilePath( file ) ) {
                logger.warn( "Invalid file path detected: #file#" )
                return
            }
            processFile( file )
        } )
    } )
    .every( 10, "minutes" )
```

## Common Patterns

### Batch Processing

```boxlang
scheduler.task( "batch-processor" )
    .call( () => {
        totalRecords = getRecordCount()
        batchSize = 1000
        batches = ceiling( totalRecords / batchSize )

        for ( batchNum = 1; batchNum <= batches; batchNum++ ) {
            offset = ( batchNum - 1 ) * batchSize

            records = getRecords( limit = batchSize, offset = offset )
            processRecords( records )

            logger.info( "Processed batch #batchNum# of #batches#" )
        }
    } )
    .everyDayAt( "03:00" )
```

### Queue Processing

```boxlang
scheduler.task( "queue-processor" )
    .call( () => {
        while ( queueService.hasMessages() ) {
            message = queueService.getMessage()

            try {
                processMessage( message )
                queueService.acknowledge( message )
            } catch ( any e ) {
                logger.error( "Failed to process message: #e.message#" )
                queueService.requeue( message )
            }
        }
    } )
    .every( 30, "seconds" )
```

### Health Monitoring

```boxlang
scheduler.task( "health-monitor" )
    .call( () => {
        checks = {
            database: checkDatabaseHealth(),
            cache: checkCacheHealth(),
            api: checkAPIHealth(),
            disk: checkDiskSpace()
        }

        failedChecks = checks.filter( ( name, status ) => !status.healthy )

        if ( !failedChecks.isEmpty() ) {
            logger.warn( "Health check failures", failedChecks )
            alertOps( failedChecks )
        }

        return checks
    } )
    .every( 5, "minutes" )
```

## Common Pitfalls

### Pitfalls to Avoid

1. **Long-Running Tasks**: Break into smaller chunks or use background jobs
2. **Overlapping Executions**: Use `skipIfRunning()` to prevent conflicts
3. **Missing Error Handling**: Always wrap task logic in try-catch blocks
4. **Hardcoded Schedules**: Use configuration for schedule flexibility
5. **No Logging**: Always log task execution for debugging
6. **Memory Leaks**: Clean up resources, close connections
7. **Time Zone Confusion**: Be explicit about time zones
8. **Blocking Operations**: Use async operations for I/O-bound tasks
9. **No Retry Logic**: Implement retries for transient failures
10. **Missing Monitoring**: Track task success/failure rates

### Troubleshooting

```boxlang
// Debug task scheduling
logger.debug( "Task next run: #task.getNextRunTime()#" )
logger.debug( "Task schedule: #task.getScheduleExpression()#" )

// Check for scheduling conflicts
tasks = scheduler.getTasks()
tasks.each( ( name, task ) => {
    if ( task.isRunning() && task.getDuration() > 60000 ) {
        logger.warn( "Long-running task: #name# (#task.getDuration()#ms)" )
    }
} )

// Monitor executor health
executorStats = scheduler.getExecutor().getStatistics()
logger.info( "Executor Stats", executorStats )
```

## Related Skills

- [BoxLang Futures](boxlang-futures.md) - Async programming and BoxFutures
- [BoxLang Executors](boxlang-executors.md) - Thread pools and executor services
- [BoxLang Threading](boxlang-threading.md) - Threading and concurrency
- [BoxLang Modules](boxlang-modules.md) - Module creation and integration

## References

- [BoxLang Async Programming](https://boxlang.ortusbooks.com/boxlang-framework/asynchronous-programming)
- [BoxLang Scheduled Tasks](https://boxlang.ortusbooks.com/boxlang-framework/asynchronous-programming/scheduled-tasks)
- [BaseScheduler API Docs](https://s3.amazonaws.com/apidocs.ortussolutions.com/boxlang/1.3.0/ortus/boxlang/runtime/async/tasks/BaseScheduler.html)
