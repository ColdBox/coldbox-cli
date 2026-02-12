---
title: CBStorages - Storage Provider Abstraction
description: Storage abstraction guidance for sessions, cache, and app state using pluggable providers, including provider selection, consistency, and failover considerations.
---

# CBStorages - Storage Provider Abstraction

> **Module**: cbstorages
> **Category**: Utility / Storage
> **Purpose**: Unified API for session, cookie, and application storage with encryption and expiration

## Overview

CBStorages provides an abstract, unified interface for working with various storage scopes (session, cookie, application, cache) with built-in encryption, expiration, and type safety.

## Core Features

- Unified storage API across scopes
- Automatic encryption/decryption
- TTL and expiration management
- Type-safe data retrieval
- Flash storage support
- Storage events and listeners
- JSON serialization
- Multiple storage providers

## Installation

```bash
box install cbstorages
```

## Configuration

```javascript
// config/ColdBox.cfc - moduleSettings
moduleSettings = {
    cbstorages: {
        // Default storage provider
        defaultProvider: "session",

        // Enable encryption
        encryption: {
            enabled: true,
            key: getSystemSetting( "STORAGE_KEY" ),
            algorithm: "AES",
            encoding: "Base64"
        },

        // Default TTL in minutes
        defaultTTL: 60
    }
};
```

## Usage Patterns

### Basic Storage Operations

```javascript
component {
    property name="storages" inject="StorageService@cbstorages";

    function savePreferences( event, rc, prc ) {
        // Store in session
        storages.session()
            .set( "userPreferences", {
                theme: "dark",
                language: "en"
            } );

        // Store in cookie
        storages.cookie()
            .set( "lastVisit", now() )
            .withExpiration( 30 ); // days

        // Store in cache
        storages.cache()
            .set( "recentSearches", searches )
            .withTTL( 60 ); // minutes
    }

    function getPreferences( event, rc, prc ) {
        var prefs = storages.session()
            .get( "userPreferences", {} );

        return prefs;
    }
}
```

### Flash Storage

```javascript
// Set flash message
storages.flash()
    .put( "message", "Successfully saved!" )
    .put( "type", "success" );

// In next request
var message = storages.flash().get( "message" );
var type = storages.flash().get( "type" );
```

### Encrypted Storage

```javascript
// Automatically encrypted
storages.session()
    .encrypted( true )
    .set( "sensitiveData", {
        ssn: "123-45-6789",
        creditCard: "4111111111111111"
    } );

// Automatically decrypted on retrieval
var data = storages.session()
    .encrypted( true )
    .get( "sensitiveData" );
```

### Type-Safe Retrieval

```javascript
// Get with type casting
var count = storages.session()
    .getAsInteger( "loginAttempts", 0 );

var isAdmin = storages.session()
    .getAsBoolean( "isAdmin", false );

var timestamp = storages.session()
    .getAsDate( "lastLogin" );

var tags = storages.session()
    .getAsArray( "tags", [] );
```

### Storage Providers

```javascript
// Session storage
storages.session().set( "key", "value" );

// Cookie storage
storages.cookie().set( "key", "value" );

// Application storage
storages.application().set( "key", "value" );

// Cache storage
storages.cache().set( "key", "value" );

// Request storage
storages.request().set( "key", "value" );
```

## Best Practices

1. **Use Appropriate Scope**: Choose storage based on data lifecycle
2. **Encrypt Sensitive Data**: Always encrypt PII and credentials
3. **Set Expiration**: Implement TTL for all cached data
4. **Validate Retrieved Data**: Always provide defaults
5. **Clear Unused Data**: Clean up storage periodically
6. **Monitor Storage Size**: Avoid storing large objects in cookies/session

## Common Patterns

### User Cart Storage

```javascript
storages.session()
    .set( "cart", cartItems )
    .withTTL( 120 ); // 2 hours
```

### Remember Me Cookie

```javascript
storages.cookie()
    .encrypted( true )
    .set( "rememberToken", token )
    .withExpiration( 30 ); // 30 days
```

## Additional Resources

- [ColdBox Storage Documentation](https://coldbox.ortusbooks.com)
- [Session Management Best Practices](https://owasp.org/www-project-top-ten/)
