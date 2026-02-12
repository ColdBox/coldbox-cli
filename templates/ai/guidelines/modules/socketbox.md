---
title: SocketBox - WebSocket Real-Time Communication
description: WebSocket server implementation for real-time bidirectional client-server communication
---

# SocketBox - WebSocket Real-Time Communication

> **Module**: socketbox
> **Category**: Real-Time / WebSockets
> **Purpose**: WebSocket server and client integration for real-time bidirectional communication

## Overview

SocketBox brings WebSocket capabilities to ColdBox applications, enabling real-time bidirectional communication for chat, notifications, live updates, and collaborative features.

## Core Features

- WebSocket server integration
- Room/channel management
- Broadcast messaging
- Private messaging
- Event-driven architecture
- Connection authentication
- Automatic reconnection
- Binary data support
- Redis adapter for scaling

## Installation

```bash
box install socketbox
```

## Configuration

```javascript
// config/ColdBox.cfc - moduleSettings
moduleSettings = {
    socketbox: {
        // WebSocket server port
        port: 8080,

        // SSL/TLS configuration
        ssl: {
            enabled: false,
            certPath: "",
            keyPath: ""
        },

        // Authentication
        requireAuth: true,

        // Redis for horizontal scaling
        redis: {
            enabled: false,
            host: "localhost",
            port: 6379
        },

        // CORS
        cors: {
            enabled: true,
            origins: [ "*" ]
        }
    }
};
```

## Usage Patterns

### Basic WebSocket Server

```javascript
component extends="socketbox.models.BaseEventHandler" {

    function onConnect( socket, data ) {
        log.info( "Client connected: #socket.getId()#" );

        // Authenticate
        if ( !validateToken( data.token ?: "" ) ) {
            socket.disconnect( "Unauthorized" );
            return;
        }

        // Join user-specific room
        socket.join( "user-#data.userId#" );

        // Broadcast to others
        broadcast.to( "lobby" ).emit( "userJoined", {
            userId: data.userId,
            username: data.username
        } );
    }

    function onDisconnect( socket, reason ) {
        log.info( "Client disconnected: #socket.getId()#" );
    }

    function onMessage( socket, event, data ) {
        switch ( arguments.event ) {
            case "chatMessage":
                handleChatMessage( socket, data );
                break;
            case "typing":
                handleTyping( socket, data );
                break;
        }
    }

    private function handleChatMessage( socket, data ) {
        var message = {
            userId: socket.getAttribute( "userId" ),
            username: socket.getAttribute( "username" ),
            message: data.message,
            timestamp: now()
        };

        // Broadcast to room
        broadcast.to( data.room ).emit( "newMessage", message );

        // Save to database
        messageService.save( message );
    }
}
```

### Client-Side JavaScript

```javascript
// Connect to WebSocket server
const socket = io( 'ws://localhost:8080', {
    auth: {
        token: '<jwt-token>',
        userId: 123,
        username: 'john.doe'
    }
} );

// Connection events
socket.on( 'connect', () => {
    console.log( 'Connected to server' );
} );

socket.on( 'disconnect', () => {
    console.log( 'Disconnected from server' );
} );

// Listen for messages
socket.on( 'newMessage', ( data ) => {
    displayMessage( data );
} );

socket.on( 'userJoined', ( data ) => {
    showNotification( `${data.username} joined` );
} );

// Send messages
function sendMessage( message ) {
    socket.emit( 'chatMessage', {
        room: 'general',
        message: message
    } );
}

// Join room
socket.emit( 'joinRoom', { room: 'general' } );
```

### Rooms and Channels

```javascript
component {
    property name="socketServer" inject="SocketServer@socketbox";

    function joinRoom( socket, data ) {
        socket.join( data.room );

        // Notify room members
        broadcast
            .to( data.room )
            .except( socket.getId() )
            .emit( "userJoinedRoom", {
                userId: socket.getAttribute( "userId" ),
                room: data.room
            } );
    }

    function leaveRoom( socket, data ) {
        socket.leave( data.room );

        broadcast
            .to( data.room )
            .emit( "userLeftRoom", {
                userId: socket.getAttribute( "userId" )
            } );
    }

    function broadcastToRoom( roomName, event, data ) {
        socketServer
            .to( roomName )
            .emit( event, data );
    }
}
```

### Private Messaging

```javascript
function sendPrivateMessage( socket, data ) {
    var recipientRoom = "user-#data.recipientId#";

    // Send to recipient
    broadcast.to( recipientRoom ).emit( "privateMessage", {
        from: socket.getAttribute( "userId" ),
        message: data.message,
        timestamp: now()
    } );

    // Confirm delivery to sender
    socket.emit( "messageSent", {
        messageId: createUUID(),
        status: "delivered"
    } );
}
```

### Real-Time Notifications

```javascript
component {
    property name="socketServer" inject="SocketServer@socketbox";

    function sendNotification( userId, notification ) {
        // Send to specific user
        socketServer
            .to( "user-#arguments.userId#" )
            .emit( "notification", {
                type: arguments.notification.type,
                message: arguments.notification.message,
                data: arguments.notification.data,
                timestamp: now()
            } );
    }

    function broadcastNotification( notification ) {
        // Send to all connected clients
        socketServer
            .emit( "notification", arguments.notification );
    }
}
```

### Live Dashboard Updates

```javascript
// Server-side: push metrics
function updateDashboardMetrics() {
    var metrics = metricsService.getCurrentMetrics();

    socketServer
        .to( "dashboard" )
        .emit( "metricsUpdate", metrics );
}

// Client-side: receive updates
socket.on( 'metricsUpdate', ( metrics ) => {
    updateCharts( metrics );
    updateCounters( metrics );
} );
```

## Best Practices

1. **Authenticate Connections**: Verify JWT tokens on connect
2. **Use Rooms Effectively**: Organize clients by concern
3. **Handle Reconnection**: Implement client-side reconnection logic
4. **Rate Limiting**: Prevent message flooding
5. **Error Handling**: Gracefully handle disconnections
6. **Scale with Redis**: Use Redis adapter for multiple servers
7. **Monitor Connections**: Track active connections and rooms
8. **Clean Up**: Remove socket on disconnect

## Common Use Cases

### Chat Application
### Live Notifications
### Collaborative Editing
### Real-Time Dashboard
### Live Sports Scores
### Stock Trading Updates
### Multiplayer Games
### Live Auction Bidding

## Additional Resources

- [Socket.IO Documentation](https://socket.io/docs/)
- [WebSocket Protocol](https://datatracker.ietf.org/doc/html/rfc6455)
- [Real-Time Web Best Practices](https://www.html5rocks.com/en/tutorials/websockets/basics/)
