---
name: cache-integration
description: Implement caching strategies using CacheBox for improved application performance and scalability
category: coldbox
priority: medium
triggers:
  - cache implementation
  - cachebox integration
  - caching strategies
  - cache patterns
---

# Cache Integration Implementation Pattern

## When to Use This Skill

Use this skill when implementing caching to improve application performance, reduce database load, cache expensive operations, or store temporary data in ColdBox applications.

## Core Concepts

Cache Box Caching:
- CacheBox is ColdBox's enterprise caching engine
- Supports multiple cache providers (RAM, Redis, Memcached, etc.)
- Named caches for different use cases
- Event-driven cache lifecycle
- Support for cache reaping and eviction policies
- Distributed caching support

## Basic Cache Usage (BoxLang)

```boxlang
class ProductService {

    @inject
    property name="cachebox";

    /**
     * Get products with caching
     */
    function getAll() {
        var cache = cachebox.getCache( "default" )
        var cacheKey = "products-all-list"

        // Check if cached
        if( cache.lookup( cacheKey ) ){
            return cache.get( cacheKey )
        }

        // Not cached, fetch from database
        var products = queryExecute( "SELECT * FROM products" )

        // Store in cache for 60 minutes
        cache.set( cacheKey, products, 60 )

        return products
    }

    /**
     * Get single product with caching
     */
    function getById( required numeric id ) {
        var cache = cachebox.getCache( "default" )
        var cacheKey = "product-#arguments.id#"

        return cache.getOrSet(
            objectKey = cacheKey,
            produce = function(){
                return queryExecute(
                    "SELECT * FROM products WHERE id = :id",
                    { id: id }
                )
            },
            timeout = 30,
            lastAccessTimeout = 15
        )
    }
}
```

## CacheBox Configuration

```boxlang
// config/ColdBox.cfc
class ColdBox {

    function configure() {
        coldbox = {
            // ... coldbox settings
        }

        // CacheBox configuration
        cacheBox = {
            // Default cache
            defaultCache = {
                provider = "coldbox.system.cache.providers.CacheBoxProvider",
                properties = {
                    objectDefaultTimeout = 60,
                    objectDefaultLastAccessTimeout = 30,
                    useLastAccessTimeouts = true,
                    reapFrequency = 5,
                    freeMemoryPercentageThreshold = 0,
                    evictionPolicy = "LRU",
                    evictCount = 5,
                    maxObjects = 500,
                    objectStore = "ConcurrentStore"
                }
            },

            // Named caches
            caches = {
                // Short-term cache
                "shortTerm": {
                    provider = "coldbox.system.cache.providers.CacheBoxProvider",
                    properties = {
                        objectDefaultTimeout = 5,
                        objectDefaultLastAccessTimeout = 2,
                        maxObjects = 100
                    }
                },

                // Long-term cache
                "longTerm": {
                    provider = "coldbox.system.cache.providers.CacheBoxProvider",
                    properties = {
                        objectDefaultTimeout = 1440,  // 24 hours
                        objectDefaultLastAccessTimeout = 720,  // 12 hours
                        maxObjects = 1000
                    }
                },

                // Template cache
                "template": {
                    provider = "coldbox.system.cache.providers.CacheBoxProvider",
                    properties = {
                        objectDefaultTimeout = 120,
                        objectDefaultLastAccessTimeout = 60,
                        maxObjects = 200
                    }
                },

                // Session cache (distributed)
                "sessions": {
                    provider = "coldbox.system.cache.providers.CacheBoxColdBoxProvider",
                    properties = {
                        objectDefaultTimeout = 30,
                        maxObjects = 1000
                    }
                }
            }
        }
    }
}
```

## Redis Cache Provider

```boxlang
// config/ColdBox.cfc with Redis
function configure() {
    cacheBox = {
        defaultCache = {
            provider = "coldbox.system.cache.providers.CacheBoxProvider",
            properties = {
                objectDefaultTimeout = 60,
                maxObjects = 500
            }
        },

        caches = {
            "redis": {
                provider = "coldbox.system.cache.providers.RedisCacheProvider",
                properties = {
                    host = "localhost",
                    port = 6379,
                    password = "",
                    database = 0,
                    timeout = 5,
                    objectDefaultTimeout = 60,
                    ssl = false
                }
            }
        }
    }
}
```

## Cache Operations

```boxlang
class CacheService {

    @inject
    property name="cachebox";

    /**
     * Set cache entry
     */
    function set( required string key, required any value, numeric timeout = 60 ) {
        var cache = cachebox.getCache( "default" )

        cache.set(
            objectKey = arguments.key,
            object = arguments.value,
            timeout = arguments.timeout
        )
    }

    /**
     * Get cache entry
     */
    function get( required string key, any defaultValue ) {
        var cache = cachebox.getCache( "default" )

        if( cache.lookup( arguments.key ) ){
            return cache.get( arguments.key )
        }

        return structKeyExists( arguments, "defaultValue" ) ? arguments.defaultValue : javacast( "null", "" )
    }

    /**
     * Get or set (lazy loading)
     */
    function getOrSet(
        required string key,
        required any provider,
        numeric timeout = 60
    ){
        var cache = cachebox.getCache( "default" )

        return cache.getOrSet(
            objectKey = arguments.key,
            produce = arguments.provider,
            timeout = arguments.timeout
        )
    }

    /**
     * Check if key exists
     */
    function has( required string key ) {
        return cachebox.getCache( "default" ).lookup( arguments.key )
    }

    /**
     * Remove cache entry
     */
    function clear( required string key ) {
        cachebox.getCache( "default" ).clear( arguments.key )
    }

    /**
     * Clear cache by pattern
     */
    function clearByPattern( required string pattern ) {
        var cache = cachebox.getCache( "default" )
        var keys = cache.getKeys()

        keys.each( function( key ){
            if( key.findNoCase( pattern ) ){
                cache.clear( key )
            }
        })
    }

    /**
     * Clear entire cache
     */
    function clearAll() {
        cachebox.getCache( "default" ).clearAll()
    }

    /**
     * Get cache stats
     */
    function getStats() {
        var cache = cachebox.getCache( "default" )

        return {
            hits: cache.getStats().getHits(),
            misses: cache.getStats().getMisses(),
            evictions: cache.getStats().getEvictionCount(),
            objectCount: cache.getSize(),
            performance: cache.getStats().getCachePerformanceRatio()
        }
    }
}
```

## Query Caching

```boxlang
class UserService {

    @inject
    property name="cachebox";

    /**
     * Get all users with query caching
     */
    function list() {
        var cache = cachebox.getCache( "default" )
        var cacheKey = "users-list"

        return cache.getOrSet(
            objectKey = cacheKey,
            produce = function(){
                return queryExecute(
                    "SELECT * FROM users ORDER BY lastName, firstName",
                    {},
                    { returntype: "array" }
                )
            },
            timeout = 30
        )
    }

    /**
     * Search with cached results
     */
    function search( required string term ) {
        var cache = cachebox.getCache( "default" )
        var cacheKey = "users-search-#hash( arguments.term )#"

        return cache.getOrSet(
            objectKey = cacheKey,
            produce = function(){
                return queryExecute(
                    "SELECT * FROM users WHERE firstName LIKE :term OR lastName LIKE :term",
                    { term: "%#term#%" },
                    { returntype: "array" }
                )
            },
            timeout = 15
        )
    }

    /**
     * Clear user cache after update
     */
    function update( required numeric id, required struct data ) {
        // Update user
        queryExecute(
            "UPDATE users SET firstName = :firstName, lastName = :lastName WHERE id = :id",
            data
        )

        // Clear relevant caches
        var cache = cachebox.getCache( "default" )
        cache.clear( "users-list" )
        cache.clear( "user-#arguments.id#" )

        // Clear all search caches
        clearSearchCache()
    }

    private function clearSearchCache() {
        var cache = cachebox.getCache( "default" )
        var keys = cache.getKeys()

        keys.each( function( key ){
            if( key.startsWith( "users-search-" ) ){
                cache.clear( key )
            }
        })
    }
}
```

## View Caching

```boxlang
class Dashboard extends coldbox.system.EventHandler {

    @inject
    property name="dashboardService";

    /**
     * Cache entire event output
     */
    function index( event, rc, prc ) {
        // Enable event caching
        event.setEventCacheable( true )
        event.setEventCacheTimeout( 30 )
        event.setEventCacheKey( "dashboard-index-user-#auth().userId()#" )

        prc.stats = dashboardService.getStats()
        event.setView( "dashboard/index" )
    }

    /**
     * Cache specific view fragment
     */
    function reports( event, rc, prc ) {
        prc.reportData = dashboardService.getReportData()
        event.setView( "dashboard/reports" )
    }
}
```

```html
<!--
views/dashboard/reports.cfm
Cache view partial
-->
<cfoutput>
<div class="dashboard">
    <!-- Cached widget -->
    #renderView(
        view = "dashboard/widgets/stats",
        args = { data: prc.reportData },
        cache = true,
        cacheTimeout = 15,
        cacheKey = "dashboard-stats-#auth().userId()#"
    )#

    <!-- Non-cached real-time widget -->
    #renderView(
        view = "dashboard/widgets/liveActivity",
        cache = false
    )#
</div>
</cfoutput>
```

## API Response Caching

```boxlang
class api_Products extends coldbox.system.RestHandler {

    @inject
    property name="productService";

    @inject
    property name="cachebox";

    /**
     * Cache API responses
     */
    function index( event, rc, prc ) {
        var cache = cachebox.getCache( "default" )
        var cacheKey = "api-products-page-#rc.page ?: 1#"

        var products = cache.getOrSet(
            objectKey = cacheKey,
            produce = function(){
                return productService.list(
                    page = rc.page ?: 1,
                    limit = rc.limit ?: 25
                )
            },
            timeout = 10
        )

        // Set cache headers
        event.setHTTPHeader( name = "Cache-Control", value = "public, max-age=600" )
        event.setHTTPHeader( name = "ETag", value = hash( serializeJSON( products ) ) )

        event.renderData(
            type = "json",
            data = products,
            statusCode = 200
        )
    }

    /**
     * Invalidate cache on create
     */
    function create( event, rc, prc ) {
        var product = productService.create( rc )

        // Clear product caches
        clearProductCaches()

        event.renderData(
            type = "json",
            data = product,
            statusCode = 201
        )
    }

    private function clearProductCaches() {
        var cache = cachebox.getCache( "default" )
        var keys = cache.getKeys()

        keys.each( function( key ){
            if( key.startsWith( "api-products-" ) ){
                cache.clear( key )
            }
        })
    }
}
```

## Cache Interceptor

```boxlang
/**
 * Cache Interceptor
 * Automatic cache invalidation
 */
class CacheInterceptor {

    @inject
    property name="cachebox";

    @inject
    property name="log";

    /**
     * Clear cache after data modifications
     */
    function postHandler( event, interceptData, rc, prc ) {
        var currentEvent = event.getCurrentEvent()
        var method = event.getHTTPMethod()

        // Clear cache on POST, PUT, DELETE
        if( listFindNoCase( "POST,PUT,DELETE", method ) ){
            clearRelatedCaches( currentEvent )
        }
    }

    /**
     * Clear caches related to the event
     */
    private function clearRelatedCaches( required string eventName ) {
        var cache = cachebox.getCache( "default" )

        // Determine cache keys to clear based on event
        var clearKeys = []

        if( eventName.startsWith( "users." ) ){
            clearKeys.append( "users-list" )
            clearKeys.append( "users-search-*" )
        } else if( eventName.startsWith( "products." ) ){
            clearKeys.append( "products-list" )
            clearKeys.append( "api-products-*" )
        }

        // Clear caches
        clearKeys.each( function( pattern ){
            if( pattern.endsWith( "*" ) ){
                clearByPattern( pattern.replace( "*", "" ) )
            } else {
                cache.clear( pattern )
            }
        })

        log.debug( "Cleared caches related to: #eventName#" )
    }

    private function clearByPattern( required string pattern ) {
        var cache = cachebox.getCache( "default" )
        var keys = cache.getKeys()

        keys.each( function( key ){
            if( key.startsWith( pattern ) ){
                cache.clear( key )
            }
        })
    }
}
```

## Distributed Caching

```boxlang
/**
 * Session Service with distributed cache
 */
class SessionService {

    @inject
    property name="cachebox";

    /**
     * Store session data in distributed cache
     */
    function set( required string userId, required string key, required any value ) {
        var cache = cachebox.getCache( "sessions" )
        var cacheKey = "session-#arguments.userId#-#arguments.key#"

        cache.set(
            objectKey = cacheKey,
            object = arguments.value,
            timeout = 30  // 30 minutes
        )
    }

    /**
     * Get session data
     */
    function get( required string userId, required string key, any defaultValue ) {
        var cache = cachebox.getCache( "sessions" )
        var cacheKey = "session-#arguments.userId#-#arguments.key#"

        if( cache.lookup( cacheKey ) ){
            return cache.get( cacheKey )
        }

        return structKeyExists( arguments, "defaultValue" ) ? arguments.defaultValue : javacast( "null", "" )
    }

    /**
     * Clear user session
     */
    function clear( required string userId ) {
        var cache = cachebox.getCache( "sessions" )
        var keys = cache.getKeys()

        keys.each( function( key ){
            if( key.startsWith( "session-#userId#-" ) ){
                cache.clear( key )
            }
        })
    }
}
```

## Cache Warming

```boxlang
/**
 * Cache Warming Service
 * Pre-populate caches on application start
 */
class CacheWarmingService {

    @inject
    property name="cachebox";

    @inject
    property name="productService";

    @inject
    property name="categoryService";

    /**
     * Warm caches with commonly accessed data
     */
    function warmCaches() {
        log.info( "Starting cache warming..." )

        var cache = cachebox.getCache( "default" )

        // Warm product list cache
        cache.set(
            "products-list",
            productService.list(),
            60
        )

        // Warm category cache
        cache.set(
            "categories-all",
            categoryService.getAll(),
            120
        )

        // Warm featured products
        cache.set(
            "products-featured",
            productService.getFeatured(),
            60
        )

        log.info( "Cache warming completed" )
    }

    /**
     * Refresh stale caches
     */
    function refreshCaches() {
        cachebox.getCache( "default" ).reap()
        warmCaches()
    }
}
```

```boxlang
// In Application.cfc or Main handler
function onApplicationStart() {
    // Warm caches on application start
    getInstance( "CacheWarmingService" ).warmCaches()
}
```

## Cache Monitoring

```boxlang
class CacheMonitoringService {

    @inject
    property name="cachebox";

    /**
     * Get cache statistics
     */
    function getStats( string cacheName = "default" ) {
        var cache = cachebox.getCache( arguments.cacheName )
        var stats = cache.getStats()

        return {
            cacheName: arguments.cacheName,
            size: cache.getSize(),
            hits: stats.getHits(),
            misses: stats.getMisses(),
            evictions: stats.getEvictionCount(),
            performanceRatio: stats.getCachePerformanceRatio(),
            averageGetTime: stats.getAverageGetTime(),
            lastReap: stats.getLastReapTime()
        }
    }

    /**
     * Get all cache stats
     */
    function getAllStats() {
        var caches = cachebox.getCacheNames()
        var allStats = []

        caches.each( function( cacheName ){
            allStats.append( getStats( cacheName ) )
        })

        return allStats
    }

    /**
     * Check cache health
     */
    function checkHealth() {
        var stats = getStats()
        var health = {
            status: "healthy",
            warnings: []
        }

        // Check performance ratio
        if( stats.performanceRatio < 0.7 ){
            health.warnings.append( "Low cache hit ratio: #stats.performanceRatio#" )
            health.status = "warning"
        }

        // Check evictions
        if( stats.evictions > 1000 ){
            health.warnings.append( "High eviction count: #stats.evictions#" )
            health.status = "warning"
        }

        return health
    }
}
```

## Best Practices

1. **Use Named Caches**: Separate caches for different purposes
2. **Appropriate Timeouts**: Set realistic cache timeouts
3. **Cache Keys**: Use descriptive, unique cache keys
4. **Invalidation Strategy**: Clear caches when data changes
5. **Monitor Performance**: Track cache hit ratios
6. **Distributed Caching**: Use Redis for multi-server setups
7. **Cache Warming**: Pre-populate frequently accessed data
8. **Error Handling**: Handle cache failures gracefully
9. **Testing**: Test cache logic thoroughly
10. **Documentation**: Document caching strategies

## Common Pitfalls

1. **Over-caching**: Caching mutable data too long
2. **Stale Data**: Not invalidating caches on updates
3. **Wrong Keys**: Using non-unique cache keys
4. **Same Timeout**: Not varying timeouts by data type
5. **No Monitoring**: Not tracking cache performance
6. **Memory Issues**: Caching too much data
7. **Missing Eviction**: Not configuring eviction policies
8. **Security**: Caching sensitive data
9. **Testing Gaps**: Not testing cache invalidation
10. **Poor Documentation**: Not documenting cache strategy

## Testing Cache Implementation

```boxlang
class CacheServiceTest extends coldbox.system.testing.BaseTestCase {

    function beforeAll() {
        super.beforeAll()
        setup()
        cacheService = getInstance( "CacheService" )
    }

    function run() {
        describe( "Cache Service", function(){

            beforeEach( function(){
                // Clear cache before each test
                cacheService.clearAll()
            })

            it( "should set and get cache entry", function(){
                cacheService.set( "test-key", "test-value", 60 )
                expect( cacheService.get( "test-key" ) ).toBe( "test-value" )
            })

            it( "should return default value for missing key", function(){
                expect( cacheService.get( "missing-key", "default" ) ).toBe( "default" )
            })

            it( "should clear cache entry", function(){
                cacheService.set( "test-key", "test-value", 60 )
                cacheService.clear( "test-key" )
                expect( cacheService.has( "test-key" ) ).toBeFalse()
            })

            it( "should use lazy loading with getOrSet", function(){
                var callCount = 0

                var result1 = cacheService.getOrSet(
                    key = "lazy-key",
                    provider = function(){
                        callCount++
                        return "lazy-value"
                    }
                )

                var result2 = cacheService.get( "lazy-key" )

                expect( result1 ).toBe( "lazy-value" )
                expect( result2 ).toBe( "lazy-value" )
                expect( callCount ).toBe( 1 )  // Provider only called once
            })
        })
    }
}
```

## Related Skills

- `handler-development` - Handler patterns
- `rest-api-development` - API caching
- `view-rendering` - View caching
- `interceptor-development` - Cache interceptors
