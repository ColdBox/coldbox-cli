---
title: CBProxies - Proxy Pattern Implementation
description: Java proxy objects and futures for async operations and concurrent programming
---

# CBProxies - Proxy Pattern Implementation

> **Module**: cbproxies
> **Category**: Utility / Architecture
> **Purpose**: Implements proxy patterns for method interception, lazy loading, and aspect-oriented programming

## Overview

CBProxies provides dynamic proxy generation capabilities for ColdBox applications, enabling method interception, lazy loading, and AOP-style programming patterns without manual wrapper code.

## Core Features

- Dynamic proxy generation
- Method interception and decoration
- Lazy loading proxies
- Virtual proxies for expensive objects
- Protection proxies for access control
- Logging and auditing decorators
- Performance monitoring
- Transaction management

## Installation

```bash
box install cbproxies
```

## Configuration

```javascript
// config/ColdBox.cfc - moduleSettings
moduleSettings = {
    cbproxies: {
        // Enable proxy caching
        cacheProxies: true,

        // Proxy class generation path
        proxyPath: "/coldbox/system/proxies/",

        // Enable method timing
        enableTiming: true
    }
};
```

## Usage Patterns

### Basic Proxy Creation

```javascript
component {
    property name="proxyFactory" inject="ProxyFactory@cbproxies";

    function init() {
        // Create proxy with interceptor
        var userService = proxyFactory.createProxy(
            target = getInstance( "UserService" ),
            interceptor = getInstance( "LoggingInterceptor" )
        );

        return this;
    }
}
```

### Lazy Loading Proxy

```javascript
// Defer expensive object creation
var reportProxy = proxyFactory.createLazyProxy(
    provider = function() {
        return getInstance( "ExpensiveReportService" );
    }
);

// Service only instantiated when first method called
var report = reportProxy.generateReport();
```

### Method Logging Interceptor

```javascript
component implements="cbproxies.interfaces.IMethodInterceptor" {
    property name="log" inject="logbox:logger:{this}";

    function intercept(
        required any target,
        required string method,
        required struct args
    ) {
        var startTime = getTickCount();
        log.info( "Calling #arguments.method#" );

        try {
            var result = invoke( arguments.target, arguments.method, arguments.args );
            var duration = getTickCount() - startTime;

            log.info( "#arguments.method# completed in #duration#ms" );

            return result;
        } catch ( any e ) {
            log.error( "#arguments.method# failed: #e.message#", e );
            rethrow;
        }
    }
}
```

### Transaction Proxy

```javascript
component {
    property name="proxyFactory" inject="ProxyFactory@cbproxies";
    property name="transactionInterceptor" inject="TransactionInterceptor@cbproxies";

    function onDIComplete() {
        // Wrap service with transaction management
        variables.userService = proxyFactory.createProxy(
            target = getInstance( "UserService" ),
            interceptor = transactionInterceptor
        );
    }
}
```

### Caching Proxy

```javascript
component implements="cbproxies.interfaces.IMethodInterceptor" {
    property name="cacheBox" inject="cachebox";

    function intercept( required target, required method, required args ) {
        var cacheKey = "#getMetadata( arguments.target ).name#.#arguments.method#.#hash( serializeJSON( arguments.args ) )#";

        return cacheBox.getOrSet(
            key = cacheKey,
            produce = function() {
                return invoke( arguments.target, arguments.method, arguments.args );
            },
            timeout = 60
        );
    }
}
```

### Access Control Proxy

```javascript
component implements="cbproxies.interfaces.IMethodInterceptor" {
    property name="auth" inject="authenticationService@cbauth";

    function intercept( required target, required method, required args ) {
        // Check if method requires authorization
        var metadata = getMetadata( arguments.target[ arguments.method ] );

        if ( structKeyExists( metadata, "secured" ) ) {
            if ( !auth.isLoggedIn() ) {
                throw( type="Unauthorized", message="Authentication required" );
            }

            if ( structKeyExists( metadata, "permissions" ) ) {
                if ( !auth.can( metadata.permissions ) ) {
                    throw( type="Forbidden", message="Insufficient permissions" );
                }
            }
        }

        return invoke( arguments.target, arguments.method, arguments.args );
    }
}
```

## Best Practices

1. **Use for Cross-Cutting Concerns**: Logging, security, transactions, caching
2. **Keep Interceptors Lightweight**: Avoid heavy logic in interception
3. **Cache Proxies**: Reuse proxy instances when possible
4. **Document Proxy Behavior**: Make proxy usage clear to consumers
5. **Test Proxy Logic**: Ensure interceptors don't break functionality
6. **Consider Performance**: Proxies add overhead to method calls

## Common Patterns

### Audit Trail Proxy

```javascript
// Track all service calls
var auditedService = proxyFactory.createProxy(
    target = userService,
    interceptor = getInstance( "AuditInterceptor" )
);
```

### Retry Proxy

```javascript
component implements="cbproxies.interfaces.IMethodInterceptor" {
    function intercept( required target, required method, required args ) {
        var maxRetries = 3;
        var attempt = 1;

        while ( attempt <= maxRetries ) {
            try {
                return invoke( arguments.target, arguments.method, arguments.args );
            } catch ( any e ) {
                if ( attempt == maxRetries ) rethrow;
                sleep( 1000 * attempt );
                attempt++;
            }
        }
    }
}
```

## Additional Resources

- [Proxy Pattern (GoF)](https://en.wikipedia.org/wiki/Proxy_pattern)
- [Aspect-Oriented Programming](https://en.wikipedia.org/wiki/Aspect-oriented_programming)
- [ColdBox AOP](https://coldbox.ortusbooks.com/digging-deeper/aspect-oriented-programming)
