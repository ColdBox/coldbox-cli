---
name: BoxLang SSE Support
description: Complete guide to Server-Sent Events (SSE) for real-time server-to-client streaming, push notifications, and live updates
category: boxlang
priority: high
triggers:
  - server sent events
  - sse
  - event stream
  - push notifications
  - real-time updates
---

# BoxLang SSE Support

## Overview

Server-Sent Events (SSE) provide unidirectional real-time communication from server to client over HTTP. Unlike WebSockets, SSE uses standard HTTP and automatically reconnects.

## Core Concepts

### SSE Fundamentals

- **Event Stream**: Continuous HTTP connection
- **Text Protocol**: UTF-8 text with specific format
- **Auto-Reconnect**: Browser handles reconnection
- **Named Events**: Custom event types
- **Last-Event-ID**: Resume from failure
- **Unidirectional**: Server → Client only

## Basic SSE

### Simple Event Stream

```boxlang
/**
 * handlers/Stream.cfc
 */
class {

    /**
     * Basic SSE endpoint
     */
    function events( event, rc, prc ) {
        // Set SSE headers
        getPageContext().getResponse().setHeader( "Content-Type", "text/event-stream" )
        getPageContext().getResponse().setHeader( "Cache-Control", "no-cache" )
        getPageContext().getResponse().setHeader( "Connection", "keep-alive" )

        // Send events
        for ( var i = 1; i <= 5; i++ ) {
            writeOutput( "data: Message #i##chr(10)##chr(10)#" )
            getPageContext().getOut().flush()

            sleep( 1000 )  // Wait 1 second
        }

        // Important: abort to prevent template processing
        abort
    }
}
```

### Client Connection

```html
<!DOCTYPE html>
<html>
<head>
    <title>SSE Example</title>
</head>
<body>
    <div id="messages"></div>

    <script>
        const eventSource = new EventSource('/stream/events');

        eventSource.onmessage = function(event) {
            const div = document.getElementById('messages');
            div.innerHTML += '<p>' + event.data + '</p>';
        };

        eventSource.onerror = function(error) {
            console.error('SSE error:', error);
        };
    </script>
</body>
</html>
```

## SSE Service

### Dedicated SSE Service

```boxlang
/**
 * models/SSEService.cfc
 */
class {

    /**
     * Initialize SSE response
     */
    function initStream() {
        var response = getPageContext().getResponse()

        response.setHeader( "Content-Type", "text/event-stream" )
        response.setHeader( "Cache-Control", "no-cache" )
        response.setHeader( "Connection", "keep-alive" )
        response.setHeader( "X-Accel-Buffering", "no" )

        return this
    }

    /**
     * Send event
     */
    function sendEvent(
        required string data,
        string event = "",
        string id = "",
        numeric retry = 0
    ) {
        var output = ""

        // Event ID
        if ( len( id ) ) {
            output &= "id: #id##chr(10)#"
        }

        // Event type
        if ( len( event ) ) {
            output &= "event: #event##chr(10)#"
        }

        // Retry interval
        if ( retry > 0 ) {
            output &= "retry: #retry##chr(10)#"
        }

        // Data (can be multiline)
        if ( isJSON( data ) ) {
            output &= "data: #data##chr(10)#"
        } else {
            listToArray( data, chr(10) ).each( ( line ) => {
                output &= "data: #line##chr(10)#"
            } )
        }

        // End event
        output &= chr(10)

        // Send to client
        writeOutput( output )
        getPageContext().getOut().flush()

        return this
    }

    /**
     * Send comment (keeps connection alive)
     */
    function sendComment( required string text ) {
        writeOutput( ": #text##chr(10)##chr(10)#" )
        getPageContext().getOut().flush()

        return this
    }

    /**
     * Close stream
     */
    function close() {
        abort
    }
}
```

### Using SSE Service

```boxlang
/**
 * handlers/Notifications.cfc
 */
class {

    property name="sseService" inject="SSEService"
    property name="userService" inject="UserService"

    /**
     * User notification stream
     */
    function stream( event, rc, prc ) {
        sseService.initStream()

        var userID = auth().user().id
        var lastCheck = now()

        // Stream notifications for 5 minutes
        var endTime = dateAdd( "n", 5, now() )

        while ( now() < endTime ) {
            // Get new notifications
            var notifications = userService.getNotifications(
                userID,
                lastCheck
            )

            // Send each notification
            notifications.each( ( notification ) => {
                sseService.sendEvent(
                    data: serializeJSON( notification ),
                    event: "notification",
                    id: notification.id
                )
            } )

            // Send heartbeat comment
            if ( notifications.recordCount == 0 ) {
                sseService.sendComment( "heartbeat" )
            }

            lastCheck = now()
            sleep( 2000 )  // Check every 2 seconds
        }

        sseService.close()
    }
}
```

## Advanced Patterns

### Named Events

```boxlang
/**
 * Different event types
 */
function stream( event, rc, prc ) {
    sseService.initStream()

    // User update event
    sseService.sendEvent(
        data: serializeJSON( { name: "John", status: "online" } ),
        event: "userUpdate"
    )

    // Message event
    sseService.sendEvent(
        data: serializeJSON( { text: "Hello", from: "Jane" } ),
        event: "message"
    )

    // System event
    sseService.sendEvent(
        data: serializeJSON( { type: "maintenance", minutes: 10 } ),
        event: "system"
    )

    sseService.close()
}
```

### Client Event Handling

```html
<script>
const eventSource = new EventSource('/notifications/stream');

// Handle specific event types
eventSource.addEventListener('userUpdate', function(e) {
    const data = JSON.parse(e.data);
    console.log('User update:', data);
    updateUserStatus(data);
});

eventSource.addEventListener('message', function(e) {
    const data = JSON.parse(e.data);
    console.log('New message:', data);
    displayMessage(data);
});

eventSource.addEventListener('system', function(e) {
    const data = JSON.parse(e.data);
    console.log('System event:', data);
    showAlert(data);
});

// Default message handler
eventSource.onmessage = function(e) {
    console.log('Default message:', e.data);
};

// Error handler
eventSource.onerror = function(err) {
    console.error('SSE error', err);
};

// Close connection
function cleanup() {
    eventSource.close();
}
</script>
```

### Progress Updates

```boxlang
/**
 * Long-running task with progress
 */
function processData( event, rc, prc ) {
    sseService.initStream()

    var items = getDataToProcess()
    var total = items.len()

    sseService.sendEvent(
        data: serializeJSON( { status: "started", total: total } ),
        event: "progress"
    )

    items.each( ( item, index ) => {
        // Process item
        processItem( item )

        // Send progress
        var percent = round( (index / total) * 100 )
        sseService.sendEvent(
            data: serializeJSON( {
                current: index,
                total: total,
                percent: percent,
                item: item.name
            } ),
            event: "progress"
        )
    } )

    sseService.sendEvent(
        data: serializeJSON( { status: "completed" } ),
        event: "complete"
    )

    sseService.close()
}
```

### Last-Event-ID Recovery

```boxlang
/**
 * Resume from last event
 */
function stream( event, rc, prc ) {
    sseService.initStream()

    // Get last event ID from header
    var lastEventID = getHTTPRequestData().headers["Last-Event-ID"] ?: "0"

    // Get events after last ID
    var events = eventService.getEventsAfter( lastEventID )

    events.each( ( evt ) => {
        sseService.sendEvent(
            data: serializeJSON( evt.data ),
            event: evt.type,
            id: evt.id
        )
    } )

    sseService.close()
}
```

### Real-Time Dashboard

```boxlang
/**
 * handlers/Dashboard.cfc
 */
class {

    property name="sseService" inject="SSEService"
    property name="metricsService" inject="MetricsService"

    /**
     * Stream dashboard metrics
     */
    function metrics( event, rc, prc ) {
        sseService.initStream()

        // Stream for 1 hour
        var endTime = dateAdd( "h", 1, now() )

        while ( now() < endTime ) {
            var metrics = metricsService.getCurrent()

            sseService.sendEvent(
                data: serializeJSON( {
                    cpu: metrics.cpu,
                    memory: metrics.memory,
                    requests: metrics.requests,
                    timestamp: now()
                } ),
                event: "metrics"
            )

            sleep( 5000 )  // Update every 5 seconds
        }

        sseService.close()
    }
}
```

## Error Handling

### Connection Management

```boxlang
/**
 * Robust SSE with error handling
 */
function stream( event, rc, prc ) {
    try {
        sseService.initStream()

        var keepAlive = true
        var retryCount = 0
        var maxRetries = 3

        while ( keepAlive ) {
            try {
                var data = fetchData()

                sseService.sendEvent(
                    data: serializeJSON( data ),
                    retry: 5000  // Retry after 5 seconds
                )

                retryCount = 0  // Reset on success
                sleep( 1000 )

            } catch ( any e ) {
                retryCount++

                if ( retryCount >= maxRetries ) {
                    sseService.sendEvent(
                        data: serializeJSON( { error: "Max retries exceeded" } ),
                        event: "error"
                    )
                    keepAlive = false
                } else {
                    // Send error but continue
                    sseService.sendEvent(
                        data: serializeJSON( { error: e.message } ),
                        event: "error"
                    )
                    sleep( 2000 )
                }
            }
        }

    } finally {
        sseService.close()
    }
}
```

## Best Practices

### Design Guidelines

1. **Keep-Alive**: Send periodic comments
2. **Event IDs**: Enable recovery
3. **Retry Intervals**: Set appropriate timeouts
4. **Error Handling**: Graceful degradation
5. **Resource Limits**: Max connection time
6. **Compression**: Don't compress SSE
7. **Authentication**: Verify permissions
8. **Heartbeats**: Detect dead connections
9. **JSON Data**: Structured messages
10. **Close Properly**: Clean up resources

### Common Patterns

```boxlang
// ✅ Good: Heartbeat comments
while ( streaming ) {
    if ( hasNewData() ) {
        sseService.sendEvent( data: getData() )
    } else {
        sseService.sendComment( "heartbeat" )
    }
    sleep( 1000 )
}

// ✅ Good: Event IDs for recovery
sseService.sendEvent(
    data: serializeJSON( notification ),
    id: notification.id,
    event: "notification"
)

// ✅ Good: Timeout connections
var endTime = dateAdd( "n", 30, now() )
while ( now() < endTime ) {
    // Stream data
}
```

## Common Pitfalls

### Pitfalls to Avoid

1. **No Heartbeat**: Connection drops
2. **No Event IDs**: Can't recover
3. **No Timeout**: Infinite connections
4. **Buffering**: Enable flushing
5. **No Error Handling**: Silent failures
6. **Synchronous**: Blocking operations
7. **No Authentication**: Security issues
8. **Resource Leaks**: Not closing
9. **Large Messages**: Use chunking
10. **No Compression**: But SSE shouldn't compress

### Anti-Patterns

```boxlang
// ❌ Bad: No heartbeat
while ( true ) {
    if ( hasData() ) {
        sendEvent( data )
    }
    // No keep-alive sent
}

// ✅ Good: Send heartbeats
while ( streaming ) {
    if ( hasData() ) {
        sseService.sendEvent( data: getData() )
    } else {
        sseService.sendComment( "ping" )
    }
    sleep( 1000 )
}

// ❌ Bad: No timeout
while ( true ) {
    streamData()  // Runs forever
}

// ✅ Good: Set timeout
var endTime = dateAdd( "n", 30, now() )
while ( now() < endTime ) {
    streamData()
}

// ❌ Bad: No event ID
sseService.sendEvent( data: serializeJSON( data ) )

// ✅ Good: Include ID
sseService.sendEvent(
    data: serializeJSON( data ),
    id: data.id
)
```

## Related Skills

- [BoxLang REST APIs](boxlang-rest.md) - REST endpoints
- [BoxLang Async](boxlang-async.md) - Async processing
- [CBWire Development](../modern/cbwire-development.md) - Alternative reactivity

## References

- [Server-Sent Events Specification](https://html.spec.whatwg.org/multipage/server-sent-events.html)
- [MDN SSE Guide](https://developer.mozilla.org/en-US/docs/Web/API/Server-sent_events)
- [EventSource API](https://developer.mozilla.org/en-US/docs/Web/API/EventSource)
