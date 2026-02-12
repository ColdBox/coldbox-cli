---
name: CacheBox Caching Patterns
description: Complete guide to CacheBox caching strategies, cache providers, event caching, query caching, and cache management patterns
category: cachebox
priority: high
triggers:
  - cachebox
  - caching
  - cache provider
  - cache management
  - query caching
  - event caching
  - cache invalidation
---

# CacheBox Caching Patterns

## Overview

CacheBox is ColdBox's enterprise caching engine providing in-memory and distributed caching. It supports multiple providers, event-driven cache invalidation, query caching, and comprehensive cache management. Proper caching dramatically improves application performance.

## Core Concepts

### CacheBox Architecture

- **Cache Factory**: Manages multiple cache instances
- **Cache Providers**: Different storage mechanisms (RAM, disk, distributed)
- **Cache Listeners**: React to cache events
- **Object Stores**: Actual storage mechanisms
- **Reaping**: Automatic cleanup of expired entries

## Basic Caching

### Accessing CacheBox

```boxlang
class extends="coldbox.system.EventHandler" {

    property name="cachebox" inject="cachebox"

    function index( event, rc, prc ) {
        // Get default cache
        var cache = cachebox.getCache( "default" )

        // Store value
        cache.set( "userCount", 1000 )

        // Get value
        var count = cache.get( "userCount" )

        // Get with default
        var count = cache.get( "userCount", 0 )
    }
}
```

### Cache Operations

```boxlang
function cacheOperations( event, rc, prc ) {
    var cache = cachebox.getCache( "default" )

    // Set with timeout (minutes)
    cache.set( "key", "value", 60 )

    // Set with last access timeout
    cache.set(
        objectKey: "key",
        object: "value",
        timeout: 30,
        lastAccessTimeout: 15
    )

    // Get
    var value = cache.get( "key" )

    // Get with default
    var value = cache.get( "key", "defaultValue" )

    // Get or set (lazy loading)
    var data = cache.getOrSet( "expensiveData", () => {
        return computeExpensiveData()
    }, 60 )

    // Check existence
    if ( cache.lookup( "key" ) ) {
        var value = cache.get( "key" )
    }

    // Delete
    cache.clear( "key" )

    // Clear all
    cache.clearAll()

    // Get multiple keys
    var values = cache.getMulti( [ "key1", "key2", "key3" ] )

    // Set multiple keys
    cache.setMulti( {
        "key1": "value1",
        "key2": "value2"
    } )
}
```

## Cache Configuration

### CacheBox.cfc

```boxlang
/**
 * config/CacheBox.cfc
 */
class {

    function configure() {
        cacheBox = {
            // Log debug messages
            logBoxConfig: "logbox",

            // Scope registration
            scopeRegistration: {
                enabled: true,
                scope: "application",
                key: "cacheBox"
            },

            // Default cache
            defaultCache: {
                provider: "coldbox.system.cache.providers.CacheBoxColdBoxProvider",
                properties: {
                    objectDefaultTimeout: 60,
                    objectDefaultLastAccessTimeout: 30,
                    useLastAccessTimeouts: true,
                    reapFrequency: 5,
                    freeMemoryPercentageThreshold: 0,
                    evictionPolicy: "LRU",
                    evictCount: 5,
                    maxObjects: 500,
                    objectStore: "ConcurrentSoftReferenceStore"
                }
            },

            // Named caches
            caches: {
                // Query cache
                query: {
                    provider: "coldbox.system.cache.providers.CacheBoxColdBoxProvider",
                    properties: {
                        objectDefaultTimeout: 30,
                        maxObjects: 200,
                        evictionPolicy: "LFU"
                    }
                },

                // Template cache
                template: {
                    provider: "coldbox.system.cache.providers.CacheBoxColdBoxProvider",
                    properties: {
                        objectDefaultTimeout: 120,
                        maxObjects: 100
                    }
                }
            },

            // Cache listeners
            listeners: [
                {
                    class: "coldbox.system.cache.listeners.LogListener",
                    properties: {}
                }
            ]
        }
    }
}
```

### Configuring via ColdBox.cfc

```boxlang
// config/ColdBox.cfc
class {

    function configure() {
        coldbox = {
            // Event caching
            eventCaching: true,
            eventCacheStorage: "default",

            // View caching
            viewCaching: true
        }

        // CacheBox inline configuration
        cacheBox = {
            defaultCache: {
                provider: "coldbox.system.cache.providers.CacheBoxColdBoxProvider",
                properties: {
                    objectDefaultTimeout: 60,
                    maxObjects: 500
                }
            }
        }
    }
}
```

## Service Layer Caching

### Caching Service Methods

```boxlang
/**
 * UserService.cfc
 */
class singleton {

    property name="cachebox" inject="cachebox"
    property name="userDAO" inject="UserDAO"

    function list() {
        var cache = cachebox.getCache( "default" )

        return cache.getOrSet( "userList", () => {
            return userDAO.list()
        }, 30 )
    }

    function find( required numeric id ) {
        var cache = cachebox.getCache( "default" )
        var cacheKey = "user_#arguments.id#"

        return cache.getOrSet( cacheKey, () => {
            return userDAO.find( arguments.id )
        }, 60 )
    }

    function create( required struct data ) {
        var user = userDAO.create( arguments.data )

        // Invalidate list cache
        var cache = cachebox.getCache( "default" )
        cache.clear( "userList" )

        return user
    }

    function update( required numeric id, required struct data ) {
        var user = userDAO.update( arguments.id, arguments.data )

        // Invalidate specific and list caches
        var cache = cachebox.getCache( "default" )
        cache.clearQuiet( [ "user_#arguments.id#", "userList" ] )

        return user
    }
}
```

### Cache Patterns

```boxlang
class singleton {

    property name="cachebox" inject="cachebox"

    /**
     * Cache-aside pattern
     */
    function getData( id ) {
        var cache = cachebox.getCache( "default" )
        var cacheKey = "data_#id#"

        // Check cache first
        if ( cache.lookup( cacheKey ) ) {
            return cache.get( cacheKey )
        }

        // Load from source
        var data = loadFromDatabase( id )

        // Store in cache
        cache.set( cacheKey, data, 30 )

        return data
    }

    /**
     * Write-through cache
     */
    function saveData( id, data ) {
        // Save to database
        var result = saveToDatabase( id, data )

        // Update cache
        var cache = cachebox.getCache( "default" )
        cache.set( "data_#id#", result, 30 )

        return result
    }

    /**
     * Cache warming
     */
    function warmCache() {
        var cache = cachebox.getCache( "default" )
        var popularItems = getPopularItems()

        for ( var item in popularItems ) {
            cache.set(
                "item_#item.id#",
                item,
                120
            )
        }
    }
}
```

## Query Caching

### Caching Database Queries

```boxlang
class singleton {

    property name="cachebox" inject="cachebox"

    function listUsers() {
        var cache = cachebox.getCache( "query" )

        return cache.getOrSet( "users_list", () => {
            return queryExecute( "
                SELECT id, name, email
                FROM users
                WHERE active = 1
                ORDER BY name
            " )
        }, 15 )
    }

    function searchUsers( term ) {
        var cache = cachebox.getCache( "query" )
        var cacheKey = "users_search_#hash( term )#"

        return cache.getOrSet( cacheKey, () => {
            return queryExecute( "
                SELECT id, name, email
                FROM users
                WHERE name LIKE :term
            ", { term: "%#term#%" } )
        }, 5 )
    }
}
```

### Cache Invalidation

```boxlang
/**
 * UserService.cfc
 */
class singleton {

    property name="cachebox" inject="cachebox"

    function create( data ) {
        var user = queryExecute( "
            INSERT INTO users (name, email)
            VALUES (:name, :email)
        ", data )

        // Invalidate related caches
        invalidateUserCaches()

        return user
    }

    private function invalidateUserCaches() {
        var cache = cachebox.getCache( "query" )

        // Clear specific keys
        cache.clearQuiet( [
            "users_list",
            "users_count"
        ] )

        // Or clear by pattern
        cache.clearByKeySnippet( "users_" )
    }
}
```

## Event Caching

### Handler Event Caching

```boxlang
class extends="coldbox.system.EventHandler" {

    // Cache entire event output
    function index( event, rc, prc ) cache="true" cacheTimeout="30" {
        prc.users = getInstance( "UserService" ).list()
        event.setView( "users/index" )
    }

    // Cache with provider
    function list( event, rc, prc ) cache="true" cacheProvider="template" cacheTimeout="60" {
        prc.data = getData()
    }

    // Cache with suffix (for multiple variations)
    function search( event, rc, prc )
        cache="true"
        cacheTimeout="15"
        cacheSuffix="#rc.term#"
    {
        prc.results = searchService.search( rc.term )
    }
}
```

### Manual Event Cache Control

```boxlang
class extends="coldbox.system.EventHandler" {

    function index( event, rc, prc ) {
        var cache = getCache( "default" )
        var cacheKey = "event_users_index"

        // Check cache
        if ( cache.lookup( cacheKey ) ) {
            return cache.get( cacheKey )
        }

        // Build response
        prc.users = getInstance( "UserService" ).list()
        event.setView( "users/index" )
        var output = event.renderView()

        // Store in cache
        cache.set( cacheKey, output, 30 )

        return output
    }

    function clearCache( event, rc, prc ) {
        var cache = getCache( "default" )
        cache.clearByKeySnippet( "event_users_" )

        messagebox.success( "Cache cleared" )
        relocate( "users.index" )
    }
}
```

## View Caching

### Caching View Fragments

```html
<!-- views/users/index.bxm -->
<bx:output>
    <h1>Users</h1>

    <!-- Cache this section -->
    <bx:cache name="userList" timeout="30">
        <ul>
            <bx:loop array="#prc.users#" index="user">
                <li>#user.name#</li>
            </bx:loop>
        </ul>
    </bx:cache>
</bx:output>
```

### Programmatic View Caching

```boxlang
function index( event, rc, prc ) {
    var cache = getCache( "template" )
    var cacheKey = "view_users_sidebar"

    prc.sidebar = cache.getOrSet( cacheKey, () => {
        return event.renderView(
            view: "users/_sidebar",
            noLayout: true
        )
    }, 60 )
}
```

## Object Stores

CacheBox supports multiple object stores for different performance and persistence needs.

### ConcurrentStore

High-performance concurrent hash maps (default). Best for in-memory caching.

```boxlang
properties: {
    objectStore: "ConcurrentStore"
}
```

### ConcurrentSoftReferenceStore

Memory-sensitive caching using Java soft references. JVM can reclaim memory when needed. Best for large datasets that can be regenerated.

```boxlang
properties: {
    objectStore: "ConcurrentSoftReferenceStore"
}
```

### DiskStore

Persist cache to disk using Java serialization.

```boxlang
properties: {
    objectStore: "coldbox.system.cache.store.DiskStore",
    diskPath: "/cachePath",
    autoExpandPath: true,
    directoryPath: "/app/cache"
}
```

### JDBCStore

Persist cache to database using Java serialization.

```boxlang
properties: {
    objectStore: "coldbox.system.cache.store.JDBCStore",
    dsn: "myDatasource",
    table: "cacheStore"
}
```

## Cache Providers

### CacheBoxProvider

Standalone CacheBox provider for any CFML application.

```boxlang
defaultCache: {
    provider: "coldbox.system.cache.providers.CacheBoxProvider",
    properties: {
        objectDefaultTimeout: 60,
        maxObjects: 500,
        evictionPolicy: "LRU"
    }
}
```

### CacheBoxColdBoxProvider

ColdBox-enhanced provider with event caching and view fragment caching support.

```boxlang
defaultCache: {
    provider: "coldbox.system.cache.providers.CacheBoxColdBoxProvider",
    properties: {
        objectDefaultTimeout: 60,
        objectDefaultLastAccessTimeout: 30,
        maxObjects: 500,
        evictionPolicy: "LRU",
        objectStore: "ConcurrentSoftReferenceStore"
    }
}
```

### CFProvider / CFColdBoxProvider

Leverage native ColdFusion (EHCache) caching engine.

```boxlang
cfCache: {
    provider: "coldbox.system.cache.providers.CFColdBoxProvider",
    properties: {
        cacheName: "object",  // CF cache name
        clearOnFlush: true,
        maxElementsInMemory: 10000
    }
}
```

### LuceeProvider / LuceeColdBoxProvider

Leverage native Lucee caching engine.

```boxlang
luceeCache: {
    provider: "coldbox.system.cache.providers.LuceeColdBoxProvider",
    properties: {
        cacheName: "object"
    }
}
```

## Eviction Policies

- **LRU (Least Recently Used)** - Default, evicts least recently accessed items
- **LFU (Least Frequently Used)** - Evicts least frequently accessed items
- **FIFO (First In First Out)** - Evicts oldest items first
- **LIFO (Last In First Out)** - Evicts newest items first

### Custom Provider

```boxlang
/**
 * RedisCacheProvider.cfc
 */
class extends="coldbox.system.cache.AbstractCacheProvider" {

    function init() {
        super.init()

        // Connect to Redis
        variables.redis = createObject( "java", "redis.clients.jedis.Jedis" ).init(
            getProperty( "host", "localhost" ),
            getProperty( "port", 6379 )
        )

        return this
    }

    function get( required objectKey ) {
        var value = variables.redis.get( arguments.objectKey )
        return isNull( value ) ? "" : deserializeJSON( value )
    }

    function set(
        required objectKey,
        required object,
        timeout = 0,
        lastAccessTimeout = 0
    ) {
        var value = serializeJSON( arguments.object )

        if ( arguments.timeout > 0 ) {
            variables.redis.setex(
                arguments.objectKey,
                arguments.timeout * 60,  // Convert to seconds
                value
            )
        } else {
            variables.redis.set( arguments.objectKey, value )
        }

        return true
    }

    function clear( required objectKey ) {
        variables.redis.del( arguments.objectKey )
        return true
    }

    function clearAll() {
        variables.redis.flushDB()
        return this
    }
}
```

## Cache Statistics

### Monitoring Cache Performance

```boxlang
function cacheStats( event, rc, prc ) {
    var cache = cachebox.getCache( "default" )

    // Get statistics
    var stats = cache.getStats()

    prc.stats = {
        hits: stats.hits,
        misses: stats.misses,
        evictions: stats.evictionCount,
        objectCount: stats.objectCount,
        size: stats.size,
        hitRate: stats.hits / ( stats.hits + stats.misses ) * 100
    }

    // Get cache metadata
    prc.metadata = cache.getCacheInformation()
}
```

## Cache Events

### Cache Listeners

```boxlang
/**
 * MyCacheListener.cfc
 */
class extends="coldbox.system.cache.AbstractCacheListener" {

    function afterCacheElementInsert( required struct data ) {
        // Log cache insertion
        log.info( "Cache set: #data.objectKey#" )
    }

    function afterCacheElementRemoved( required struct data ) {
        // Log cache removal
        log.info( "Cache cleared: #data.objectKey#" )
    }

    function afterCacheElementExpired( required struct data ) {
        // Log cache expiration
        log.info( "Cache expired: #data.objectKey#" )
    }

    function afterCacheClearAll( required struct data ) {
        // Log cache flush
        log.warn( "Cache flushed: #data.cache.getName()#" )
    }
}
```

## Best Practices

### Design Guidelines

1. **Cache Appropriate Data**: Read-heavy, expensive computations
2. **Use Timeouts**: Set reasonable expiration times
3. **Cache Invalidation**: Clear stale data proactively
4. **Named Caches**: Separate caches by concern
5. **Monitor Performance**: Track hit/miss rates
6. **Graceful Degradation**: Handle cache failures
7. **Avoid Cache Stampede**: Use locking for expensive operations
8. **Key Naming**: Use consistent, descriptive keys
9. **Size Limits**: Set maxObjects appropriately
10. **Testing**: Test with cache enabled and disabled

### Common Patterns

```boxlang
// ✅ Good: Cache with timeout
cache.set( "data", computedValue, 30 )

// ✅ Good: Lazy loading
var data = cache.getOrSet( "key", () => {
    return expensiveOperation()
}, 60 )

// ✅ Good: Invalidate on update
function update( id, data ) {
    var result = dao.update( id, data )
    cache.clear( "item_#id#" )
    cache.clear( "list" )
    return result
}

// ✅ Good: Namespace cache keys
cache.set( "users:list", data )
cache.set( "posts:user:#userId#", data )
```

## Common Pitfalls

### Pitfalls to Avoid

1. **Over-Caching**: Caching everything
2. **No Timeouts**: Infinite cache expiration
3. **No Invalidation**: Stale data persisting
4. **Cache Stampede**: Multiple threads computing same data
5. **Large Objects**: Caching huge datasets
6. **No Monitoring**: Ignoring cache performance
7. **Wrong Provider**: Using inappropriate cache type
8. **No Fallback**: Not handling cache failures
9. **Premature Optimization**: Caching before profiling
10. **Session Caching**: Using cache as session storage

### Anti-Patterns

```boxlang
// ❌ Bad: No timeout
cache.set( "data", value )  // Never expires

// ✅ Good: With timeout
cache.set( "data", value, 30 )

// ❌ Bad: Caching user-specific data in shared cache
cache.set( "userData", userData )  // Shared across users!

// ✅ Good: User-specific key
cache.set( "user_#userId#_data", userData )

// ❌ Bad: No invalidation
function update( id, data ) {
    return dao.update( id, data )  // Stale cache
}

// ✅ Good: Clear cache
function update( id, data ) {
    var result = dao.update( id, data )
    cache.clear( "item_#id#" )
    return result
}
```

## Related Skills

- [Cache Integration](cache-integration.md) - ColdBox cache integration
- [Handler Development](handler-development.md) - Handler patterns
- [WireBox DI Patterns](wirebox-di-patterns.md) - Dependency injection

## References

- [CacheBox Documentation](https://cachebox.ortusbooks.com/)
- [Cache Providers](https://cachebox.ortusbooks.com/cache-providers)
- [Cache Events](https://cachebox.ortusbooks.com/cache-listeners-and-reporting)
