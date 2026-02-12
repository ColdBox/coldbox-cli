---
title: CBQ Job Queues Module Guidelines
description: Design guidance for asynchronous job processing with cbq, including queue topology, worker concurrency, retries/backoff, idempotency, and failure monitoring.
---

# CBQ Job Queues Module Guidelines

## Overview

CBQ provides asynchronous job queues for ColdBox applications. Push work to background, schedule tasks, and process jobs on multiple workers with support for various queue providers (Database, Redis, etc).

## Installation

```bash
box install cbq
```

## Configuration

In `config/ColdBox.cfc`:

```boxlang
moduleSettings = {
    cbq = {
        // Default connection
        defaultConnection = "default",
        
        // Connections
        connections = {
            default = {
                provider = "DatabaseProvider@cbq",
                properties = {
                    table = "cbq_jobs",
                    datasource = "myDatasource"
                }
            }
        },
        
        // Worker pools
        workerPools = {
            default = {
                connection = "default",
                queue = "default",
                workers = 1,
                backoff = 0,
                maxAttempts = 1,
                timeout = 60
            }
        }
    }
}
```

## Creating Jobs

```boxlang
// models/jobs/SendEmailJob.cfc
component extends="cbq.models.Jobs.AbstractJob" {
    property name="to";
    property name="subject";
    property name="body";
    
    function handle() {
        mailService.send(
            to = getTo(),
            subject = getSubject(),
            body = getBody()
        )
    }
}
```

## Dispatching Jobs

```boxlang
// Dispatch job
getInstance( "SendEmailJob" )
    .setTo( "[email protected]" )
    .setSubject( "Welcome!" )
    .setBody( "Thanks for signing up" )
    .dispatch()

// Dispatch with delay
getInstance( "SendEmailJob" )
    .setProperties( { to: email, subject: "Reminder" } )
    .delay( 60 ) // seconds
    .dispatch()

// Dispatch to specific queue
getInstance( "ProcessOrderJob" )
    .setOrderId( order.getId() )
    .onQueue( "high-priority" )
    .dispatch()
```

## Running Workers

```bash
# Start default worker pool
task run workers:up

# Start specific pool
task run workers:up pool=emails

# Stop workers
task run workers:down
```

## Best Practices

- **Keep jobs small** - Single responsibility per job
- **Make jobs idempotent** - Safe to retry
- **Use appropriate queues** - Separate high/low priority
- **Monitor failed jobs** - Implement error handling
- **Set max attempts** - Prevent infinite retries

## Documentation

For complete CBQ documentation, providers, and worker configuration, visit:
https://cbq.ortusbooks.com
