---
name: BoxLang Caching
description: Complete guide to caching in BoxLang with cache regions, providers, and strategies for improving application performance
category: boxlang
priority: high
triggers:
  - boxlang cache
  - cache get
  - cache set
  - cache region
  - caching strategy
---

# BoxLang Caching

## Overview

BoxLang provides built-in caching capabilities for storing frequently accessed data in memory, reducing database queries and improving performance. Supports multiple cache providers and regions.

## Core Concepts

### Caching Benefits

- **Performance**: Reduce database queries
- **Scalability**: Handle more traffic
- **Cost Savings**: Less resource usage
- **User Experience**: Faster page loads
- **Flexibility**: Multiple cache providers

### Cache Types

- **Object Cache**: Store any data type
- **Query Cache**: Cache database queries
- **Template Cache**: Cache compiled templates
- **Function Cache**: Memoize function results

## Basic Caching

### Cache Functions

```boxlang
// Set cache value
cacheSet( "userName", user.name, 60 )  // Cache for 60 minutes

// Get cache value
var userName = cacheGet( "userName" )

// Get with default
var settings = cacheGetOrSet(
    "appSettings",
    () => {
        return settingService.getAll()
    },
    60
)

// Check if cached
if ( cacheKeyExists( "userData" ) ) {
    var user = cacheGet( "userData" )
}

// Remove from cache
cacheRemove( "userName" )

// Clear all cache
cacheClear()
```

### Cache Patterns

```boxlang
/**
 * Cache user data
 */
function getUser( required id ) {
    var cacheKey = "user_#id#"

    // Try to get from cache
    if ( cacheKeyExists( cacheKey ) ) {
        return cacheGet( cacheKey )
    }

    // Load from database
    var user = queryExecute(
        "SELECT * FROM users WHERE id = :id",
        { id: id }
    )

    // Store in cache for 30 minutes
    if ( user.recordCount > 0 ) {
        cacheSet( cacheKey, user, 30 )
    }

    return user
}

/**
 * Cache expensive calculation
 */
function calculateStats( required month ) {
    return cacheGetOrSet(
        "stats_#month#",
        () => {
            // Expensive calculation
            return performComplexCalculation( month )
        },
        1440  // 24 hours
    )
}
```

## Query Caching

### Cached Queries

```boxlang
// Cache query result
var users = queryExecute(
    "SELECT * FROM users WHERE isActive = 1",
    {},
    {
        cachedWithin: createTimeSpan( 0, 1, 0, 0 )  // 1 hour
    }
)

// Cache with name
var products = queryExecute(
    "SELECT * FROM products ORDER BY name",
    {},
    {
        cacheName: "productList",
        cachedWithin: createTimeSpan( 0, 0, 30, 0 )  // 30 minutes
    }
)

// Clear specific query cache
cacheRemove( "productList" )
```

### Smart Query Caching

```boxlang
/**
 * Cache query with dependency
 */
function getProducts( category = "" ) {
    var cacheKey = "products_#category#"

    // Check cache
    var cached = cacheGet( cacheKey )
    if ( !isNull( cached ) ) {
        return cached
    }

    // Query database
    var sql = "SELECT * FROM products WHERE 1=1"
    var params = {}

    if ( category.len() > 0 ) {
        sql &= " AND category = :category"
        params.category = category
    }

    var products = queryExecute( sql, params )

    // Cache for 1 hour
    cacheSet( cacheKey, products, 60 )

    return products
}

/**
 * Invalidate on update
 */
function updateProduct( required id, required data ) {
    // Update product
    queryExecute(
        "UPDATE products SET name = :name WHERE id = :id",
        { name: data.name, id: id }
    )

    // Clear related cache
    cacheClear( "products_" )  // Clear all product caches
}
```

## Cache Regions

### Using Regions

```boxlang
// Set in specific region
cacheSetInRegion( "users", "user_1", userData, 60 )

// Get from region
var user = cacheGetFromRegion( "users", "user_1" )

// Remove from region
cacheRemoveFromRegion( "users", "user_1" )

// Clear entire region
cacheClearRegion( "users" )

// Get region metadata
var stats = cacheGetRegionMetadata( "users" )
```

### Region Configuration

```boxlang
/**
 * Application.bx
 */
class {

    this.name = "MyApp"

    // Configure cache regions
    this.cache = {
        regions: {
            users: {
                provider: "CacheBox",
                maxObjects: 1000,
                timeout: 60,
                evictionPolicy: "LRU"
            },
            products: {
                provider: "CacheBox",
                maxObjects: 500,
                timeout: 120
            },
            sessions: {
                provider: "Redis",
                properties: {
                    server: "localhost",
                    port: 6379
                }
            }
        }
    }
}
```

## Advanced Caching

### Cache Service Pattern

```boxlang
/**
 * models/CacheService.cfc
 */
class {

    /**
     * Remember value (get or set)
     */
    function remember(
        required key,
        required valueFunction,
        timeout = 60
    ) {
        // Check cache
        if ( cacheKeyExists( key ) ) {
            return cacheGet( key )
        }

        // Generate value
        var value = valueFunction()

        // Store in cache
        cacheSet( key, value, timeout )

        return value
    }

    /**
     * Cache with tags
     */
    function setWithTags(
        required key,
        required value,
        required tags,
        timeout = 60
    ) {
        // Store value
        cacheSet( key, value, timeout )

        // Store tag associations
        tags.each( ( tag ) => {
            var tagKey = "tag_#tag#"
            var keys = cacheGet( tagKey, [] )

            if ( !keys.contains( key ) ) {
                keys.append( key )
                cacheSet( tagKey, keys, timeout )
            }
        } )
    }

    /**
     * Flush by tag
     */
    function flushByTag( required tag ) {
        var tagKey = "tag_#tag#"
        var keys = cacheGet( tagKey, [] )

        // Remove all keys with this tag
        keys.each( ( key ) => {
            cacheRemove( key )
        } )

        // Remove tag
        cacheRemove( tagKey )
    }
}
```

### Distributed Caching

```boxlang
/**
 * Redis cache provider
 */
class {

    property name="redis" inject="RedisClient"

    function set( required key, required value, timeout = 0 ) {
        var serialized = serializeJSON( value )

        if ( timeout > 0 ) {
            redis.setex( key, timeout * 60, serialized )
        } else {
            redis.set( key, serialized )
        }
    }

    function get( required key ) {
        var value = redis.get( key )

        if ( isNull( value ) ) {
            return
        }

        return deserializeJSON( value )
    }

    function remove( required key ) {
        redis.del( key )
    }

    function exists( required key ) {
        return redis.exists( key ) > 0
    }
}
```

## Function Memoization

### Cached Functions

```boxlang
/**
 * Cache function results
 */
function fibonacci( required n ) cachedWithin=createTimeSpan( 0, 1, 0, 0 ) {
    if ( n <= 1 ) {
        return n
    }

    return fibonacci( n - 1 ) + fibonacci( n - 2 )
}

/**
 * Manual memoization
 */
class {

    variables.cache = {}

    function expensiveOperation( required id ) {
        var cacheKey = "operation_#id#"

        if ( cache.keyExists( cacheKey ) ) {
            return cache[cacheKey]
        }

        var result = performExpensiveCalculation( id )
        cache[cacheKey] = result

        return result
    }
}
```

## Cache Strategies

### Cache-Aside Pattern

```boxlang
/**
 * Load data from cache or database
 */
function getProduct( required id ) {
    var cacheKey = "product_#id#"

    // 1. Try cache
    var product = cacheGet( cacheKey )

    if ( !isNull( product ) ) {
        return product
    }

    // 2. Load from database
    product = queryExecute(
        "SELECT * FROM products WHERE id = :id",
        { id: id }
    )

    // 3. Store in cache
    if ( product.recordCount > 0 ) {
        cacheSet( cacheKey, product, 60 )
    }

    return product
}
```

### Write-Through Pattern

```boxlang
/**
 * Update cache and database together
 */
function updateProduct( required id, required data ) {
    // 1. Update database
    queryExecute(
        "UPDATE products SET name = :name, price = :price WHERE id = :id",
        {
            name: data.name,
            price: data.price,
            id: id
        }
    )

    // 2. Update cache
    var product = getProduct( id )
    cacheSet( "product_#id#", product, 60 )

    // 3. Invalidate related caches
    cacheClearPattern( "products_list_*" )
}
```

### Cache Warming

```boxlang
/**
 * Pre-load cache on startup
 */
function warmCache() {
    // Load frequently accessed data
    var products = queryExecute( "SELECT * FROM products WHERE featured = 1" )
    cacheSet( "featured_products", products, 1440 )

    // Load categories
    var categories = queryExecute( "SELECT * FROM categories" )
    cacheSet( "categories", categories, 1440 )

    // Load settings
    var settings = queryExecute( "SELECT * FROM settings" )
    cacheSet( "app_settings", settings, 1440 )
}
```

## Best Practices

### Design Guidelines

1. **Cache High-Traffic**: Focus on frequently accessed data
2. **Short TTL**: Start with shorter timeouts
3. **Invalidation**: Clear cache when data changes
4. **Keys**: Use descriptive cache keys
5. **Serialization**: Ensure data is serializable
6. **Monitoring**: Track cache hit/miss rates
7. **Regions**: Organize related data
8. **Error Handling**: Handle cache failures
9. **Memory Limits**: Set appropriate limits
10. **Testing**: Test cache behavior

### Common Patterns

```boxlang
// ✅ Good: Descriptive key
cacheSet( "user_profile_#userID#", userData, 60 )

// ✅ Good: Cache expensive operations
function getMonthlyReport( month ) {
    return cacheGetOrSet(
        "report_#month#",
        () => generateReport( month ),
        1440  // 24 hours
    )
}

// ✅ Good: Invalidate on update
function updateUser( id, data ) {
    userService.update( id, data )
    cacheRemove( "user_#id#" )
}
```

## Common Pitfalls

### Pitfalls to Avoid

1. **Cache Everything**: Caching too much
2. **Long TTL**: Stale data
3. **No Invalidation**: Outdated cache
4. **Poor Keys**: Key collisions
5. **Large Objects**: Memory issues
6. **No Monitoring**: Unknown performance
7. **Premature**: Cache before profiling
8. **Shared Keys**: Namespace collisions
9. **No Limits**: Memory exhaustion
10. **Missing Fallback**: Cache-only access

### Anti-Patterns

```boxlang
// ❌ Bad: Cache everything
cacheSet( "data", allData, 9999999 )

// ✅ Good: Cache strategically
cacheSet( "featured_products", featuredProducts, 60 )

// ❌ Bad: No invalidation
function updateProduct( id, data ) {
    // Update database only
    queryExecute( "UPDATE products ..." )
    // ❌ Cache is now stale
}

// ✅ Good: Invalidate on update
function updateProduct( id, data ) {
    queryExecute( "UPDATE products ..." )
    cacheRemove( "product_#id#" )
}

// ❌ Bad: Generic key
cacheSet( "data", userData, 60 )

// ✅ Good: Specific key
cacheSet( "user_profile_#userID#", userData, 60 )
```

## Related Skills

- [CacheBox Caching Patterns](../cachebox/cachebox-caching-patterns.md) - CacheBox integration
- [BoxLang Performance](boxlang-syntax.md) - Performance optimization
- [ColdBox Cache Integration](../coldbox/cache-integration.md) - ColdBox caching

## References

- [BoxLang Caching Documentation](https://boxlang.ortusbooks.com/)
- [Caching Strategies](https://aws.amazon.com/caching/best-practices/)
- [Redis Caching](https://redis.io/topics/lru-cache)
