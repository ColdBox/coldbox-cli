# CacheBox Caching Guidelines

## Overview

CacheBox is ColdBox's enterprise caching engine and aggregator. It provides a unified API for multiple cache providers, object stores, and eviction policies.

## Getting a Cache

### Injection (Recommended)

```boxlang
// Inject default cache
property name="cache" inject="cachebox:default";

// Inject named cache
property name="cache" inject="cachebox:template";
property name="cache" inject="cachebox:myCustomCache";
```

### Manual Retrieval

```boxlang
var cache = cacheBox.getCache( "default" );
var cache = cacheBox.getCache( "template" );
```

## Basic Operations

### Set/Get/Clear

```boxlang
// Set a value (uses default timeout)
cache.set( "userList", users );

// Set with custom timeout (minutes)
cache.set( "userList", users, 60 );

// Set with last access timeout
cache.set( "userList", users, 60, 30 );

// Get a value
var users = cache.get( "userList" );

// Get with default if not found
var users = cache.get( "userList", [] );

// Get or set pattern
var users = cache.getOrSet( "userList", function() {
    return userService.getAll();
}, 60 );

// Clear specific entry
cache.clear( "userList" );

// Clear all entries
cache.clearAll();
```

### Checking Existence

```boxlang
// Check if key exists
if ( cache.lookup( "userList" ) ) {
    var users = cache.get( "userList" );
}

// Get multiple keys
var data = cache.getMulti( [ "users", "roles", "permissions" ] );
```

## Configuration

Configure CacheBox in `config/ColdBox.cfc`:

```boxlang
cacheBox = {
    // Default cache configuration
    defaultCache : {
        objectDefaultTimeout : 60, // minutes
        objectDefaultLastAccessTimeout : 30,
        useLastAccessTimeouts : true,
        reapFrequency : 5,
        freeMemoryPercentageThreshold : 0,
        evictionPolicy : "LRU",
        evictCount : 1,
        maxObjects : 200,
        objectStore : "ConcurrentStore",
        coldboxEnabled : true
    },

    // Named caches
    caches : {
        // Template cache for views/events
        template : {
            provider : "coldbox.system.cache.providers.CacheBoxColdBoxProvider",
            properties : {
                objectDefaultTimeout : 120,
                objectDefaultLastAccessTimeout : 30,
                useLastAccessTimeouts : true,
                reapFrequency : 5,
                evictionPolicy : "LRU",
                evictCount : 2,
                maxObjects : 300,
                objectStore : "ConcurrentSoftReferenceStore" // Memory sensitive
            }
        },

        // API response cache
        api : {
            provider : "coldbox.system.cache.providers.CacheBoxProvider",
            properties : {
                objectDefaultTimeout : 15,
                maxObjects : 1000,
                evictionPolicy : "LFU",
                objectStore : "ConcurrentStore"
            }
        }
    }
}
```

## Eviction Policies

- **LRU (Least Recently Used)** - Default, evicts least recently accessed items
- **LFU (Least Frequently Used)** - Evicts least frequently accessed items
- **FIFO (First In First Out)** - Evicts oldest items first
- **LIFO (Last In First Out)** - Evicts newest items first

## Object Stores

### ConcurrentStore
High-performance concurrent hash maps (default).

```boxlang
objectStore : "ConcurrentStore"
```

### ConcurrentSoftReferenceStore
Memory-sensitive caching using Java soft references. JVM can reclaim memory when needed.

```boxlang
objectStore : "ConcurrentSoftReferenceStore"
```

### DiskStore
Persist cache to disk (uses Java serialization).

```boxlang
objectStore : "coldbox.system.cache.store.DiskStore",
diskPath : "/cachePath",
autoExpandPath : true,
directoryPath : "/app/cache"
```

### JDBCStore
Persist cache to database (uses Java serialization).

```boxlang
objectStore : "coldbox.system.cache.store.JDBCStore",
dsn : "myDatasource",
table : "cacheStore"
```

## Cache Providers

### CacheBoxProvider
Standalone CacheBox provider for any CFML application.

### CacheBoxColdBoxProvider
ColdBox-enhanced provider with event caching and view fragment caching support.

### CFProvider / CFColdBoxProvider
Leverage native ColdFusion (EHCache) caching engine.

```boxlang
caches : {
    cfCache : {
        provider : "coldbox.system.cache.providers.CFColdBoxProvider",
        properties : {
            cacheName : "object", // CF cache name
            clearOnFlush : true,
            maxElementsInMemory : 10000
        }
    }
}
```

### LuceeProvider / LuceeColdBoxProvider
Leverage native Lucee caching engine.

```boxlang
caches : {
    luceeCache : {
        provider : "coldbox.system.cache.providers.LuceeColdBoxProvider",
        properties : {
            cacheName : "object"
        }
    }
}
```

## Practical Examples

### Service Layer Caching

```boxlang
class UserService {
    property name="cache" inject="cachebox:default";
    
    function getActiveUsers() {
        return cache.getOrSet( "activeUsers", function() {
            return queryExecute(
                "SELECT * FROM users WHERE active = 1",
                {},
                { returntype : "array" }
            );
        }, 60 );
    }
    
    function getUserById( required numeric id ) {
        var cacheKey = "user-#arguments.id#";
        return cache.getOrSet( cacheKey, function() {
            return queryExecute(
                "SELECT * FROM users WHERE id = :id",
                { id : arguments.id },
                { returntype : "array" }
            )[1];
        }, 30 );
    }
    
    function updateUser( required numeric id, required struct data ) {
        // Update database
        var result = userDAO.update( arguments.id, arguments.data );
        
        // Invalidate caches
        cache.clear( "user-#arguments.id#" );
        cache.clear( "activeUsers" );
        
        return result;
    }
}
```

### API Response Caching

```boxlang
class API extends coldbox.system.EventHandler {
    property name="cache" inject="cachebox:api";
    
    function listProducts( event, rc, prc ) {
        var cacheKey = "products-#rc.category ?: 'all'#";
        
        prc.response = cache.getOrSet( cacheKey, function() {
            return productService.getByCategory( rc.category ?: "" );
        }, 15 ); // 15 minute cache
        
        event.renderData( data = prc.response );
    }
}
```

### Fragment Caching (Views)

```cfml
<!--- In your view --->
<cfif cacheBox.getCache( "template" ).lookup( "header-navigation" )>
    #cacheBox.getCache( "template" ).get( "header-navigation" )#
<cfelse>
    <cfsavecontent variable="navContent">
        <!--- Complex navigation rendering --->
    </cfsavecontent>
    
    <cfset cacheBox.getCache( "template" ).set( "header-navigation", navContent, 60 )>
    #navContent#
</cfif>
```

### Event Caching

```boxlang
// In handler - cache entire event output
function index( event, rc, prc ) {
    event.setView( "dashboard/index" );
}

// In config/Router.cfc
route( "/dashboard" )
    .to( "dashboard.index" )
    .cache( true, 30 ); // Cache for 30 minutes
```

## Best Practices

### Use Appropriate Cache Names

```boxlang
// Separate caches by purpose
property name="queryCache" inject="cachebox:default";
property name="viewCache" inject="cachebox:template";
property name="apiCache" inject="cachebox:api";
```

### Clear Related Caches on Updates

```boxlang
function updateUser( id, data ) {
    userDAO.update( id, data );
    
    // Clear specific and related caches
    cache.clear( "user-#id#" );
    cache.clear( "userList" );
    cache.clearByKeySnippet( "user-", true ); // Clear all user-* keys
}
```

### Monitor Cache Performance

```boxlang
// Get cache statistics
var stats = cache.getStats();

// Cache metadata
var metadata = cache.getObjectMetadata( "userList" );
```

### Use Memory-Sensitive Stores for Large Data

```boxlang
// For caching that could grow large, use soft references
template : {
    properties : {
        objectStore : "ConcurrentSoftReferenceStore"
    }
}
```

## Documentation

For complete CacheBox documentation, cache providers, and advanced features, consult the CacheBox MCP server or visit:
https://cachebox.ortusbooks.com
