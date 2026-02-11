---
name: API Authentication
description: Complete guide to REST API authentication with API keys, Bearer tokens, OAuth2, rate limiting, and API security patterns
category: security
priority: high
triggers:
  - api authentication
  - api security
  - api key
  - bearer token
  - api authorization
  - rate limiting
---

# API Authentication

## Overview

API authentication secures REST APIs using various strategies including API keys, Bearer tokens, OAuth2, and custom schemes. Proper API security prevents unauthorized access and abuse.

## Core Concepts

### API Authentication Strategies

- **API Keys**: Simple token-based auth
- **Bearer Tokens**: JWT or opaque tokens
- **OAuth2**: Delegated authorization
- **Basic Auth**: Username/password (deprecated)
- **HMAC Signatures**: Request signing
- **Rate Limiting**: Abuse prevention

## API Key Authentication

### API Key Service

```boxlang
/**
 * models/APIKeyService.cfc
 */
class singleton {

    property name="cache" inject="cachebox:default"

    /**
     * Generate API key
     */
    function generate( required userID, name = "", scopes = [] ) {
        var key = "sk_" & hash( createUUID() & now(), "SHA-256" ).left( 32 )

        queryExecute(
            "INSERT INTO api_keys (user_id, key_hash, name, scopes, created_at)
             VALUES (:userID, :hash, :name, :scopes, :now)",
            {
                userID: arguments.userID,
                hash: hash( key, "SHA-256" ),
                name: arguments.name,
                scopes: serializeJSON( arguments.scopes ),
                now: now()
            }
        )

        return key
    }

    /**
     * Validate API key
     */
    function validate( required key ) {
        // Check cache first
        var cacheKey = "api_key_#hash( arguments.key, "SHA-256" )#"

        if ( cache.lookup( cacheKey ) ) {
            return cache.get( cacheKey )
        }

        // Query database
        var result = queryExecute(
            "SELECT * FROM api_keys WHERE key_hash = :hash AND active = 1",
            { hash: hash( arguments.key, "SHA-256" ) }
        )

        if ( result.recordCount == 0 ) {
            return
        }

        var apiKey = {
            id: result.id,
            userID: result.user_id,
            scopes: deserializeJSON( result.scopes ),
            name: result.name
        }

        // Cache for 5 minutes
        cache.set( cacheKey, apiKey, 5 )

        // Update last used
        queryExecute(
            "UPDATE api_keys SET last_used_at = :now WHERE id = :id",
            { id: result.id, now: now() }
        )

        return apiKey
    }

    /**
     * Check if key has scope
     */
    function hasScope( required apiKey, required scope ) {
        return apiKey.scopes.contains( arguments.scope )
    }

    /**
     * Revoke API key
     */
    function revoke( required id, required userID ) {
        queryExecute(
            "UPDATE api_keys SET active = 0 WHERE id = :id AND user_id = :userID",
            {
                id: arguments.id,
                userID: arguments.userID
            }
        )

        // Clear cache
        cache.clearByKeySnippet( "api_key_" )
    }
}
```

### API Key Handler

```boxlang
/**
 * handlers/api/v1/Base.cfc
 */
class extends="coldbox.system.RestHandler" {

    property name="apiKeyService" inject="APIKeyService"

    function preHandler( event, rc, prc ) {
        // Extract API key
        var apiKey = event.getHTTPHeader( "X-API-Key", "" )

        if ( apiKey == "" ) {
            apiKey = rc["api_key"] ?: ""
        }

        // Validate key
        var keyData = apiKeyService.validate( apiKey )

        if ( isNull( keyData ) ) {
            return event.renderData(
                type: "json",
                data: {
                    error: "Invalid API key"
                },
                statusCode: 401
            )
        }

        // Store in request
        prc.apiKey = keyData
        prc.apiUserID = keyData.userID
    }
}
```

## Bearer Token Authentication

### JWT Bearer Tokens

```boxlang
/**
 * handlers/api/v1/Auth.cfc
 */
class extends="coldbox.system.RestHandler" {

    property name="jwtService" inject="JWTService"
    property name="userService" inject="UserService"

    /**
     * POST /api/v1/auth/login
     */
    function login( event, rc, prc ) {
        // Validate credentials
        if ( !userService.isValidCredentials( rc.email, rc.password ) ) {
            return event.renderData(
                type: "json",
                data: {
                    error: "Invalid credentials"
                },
                statusCode: 401
            )
        }

        // Generate JWT
        var user = userService.findByEmail( rc.email )
        var token = jwtService.generateToken( user )

        return event.renderData(
            type: "json",
            data: {
                access_token: token,
                token_type: "Bearer",
                expires_in: 3600
            }
        )
    }
}

/**
 * handlers/api/v1/Base.cfc
 */
class extends="coldbox.system.RestHandler" {

    property name="jwtService" inject="JWTService"

    function preHandler( event, rc, prc ) {
        // Extract Bearer token
        var auth = event.getHTTPHeader( "Authorization", "" )

        if ( auth.left( 7 ) != "Bearer " ) {
            return event.renderData(
                type: "json",
                data: {
                    error: "Missing Bearer token"
                },
                statusCode: 401
            )
        }

        var token = auth.mid( 8 )

        // Validate JWT
        try {
            var payload = jwtService.validateToken( token )

            prc.userID = payload.sub
            prc.user = userService.find( payload.sub )

        } catch ( any e ) {
            return event.renderData(
                type: "json",
                data: {
                    error: "Invalid token"
                },
                statusCode: 401
            )
        }
    }
}
```

## Scoped API Access

### Scope-Based Authorization

```boxlang
/**
 * Check API scopes
 */
class extends="coldbox.system.RestHandler" {

    property name="apiKeyService" inject="APIKeyService"

    /**
     * POST /api/v1/users
     * Requires users:write scope
     */
    function create( event, rc, prc ) {
        // Check scope
        if ( !apiKeyService.hasScope( prc.apiKey, "users:write" ) ) {
            return event.renderData(
                type: "json",
                data: {
                    error: "Insufficient scope",
                    required: "users:write"
                },
                statusCode: 403
            )
        }

        var user = userService.create( rc )

        return event.renderData(
            type: "json",
            data: user,
            statusCode: 201
        )
    }

    /**
     * GET /api/v1/users
     * Requires users:read scope
     */
    function index( event, rc, prc ) {
        if ( !apiKeyService.hasScope( prc.apiKey, "users:read" ) ) {
            return event.renderData(
                type: "json",
                data: {
                    error: "Insufficient scope"
                },
                statusCode: 403
            )
        }

        var users = userService.list()

        return event.renderData(
            type: "json",
            data: users
        )
    }
}
```

## Rate Limiting

### Rate Limiter Service

```boxlang
/**
 * models/RateLimiter.cfc
 */
class singleton {

    property name="cache" inject="cachebox:default"

    /**
     * Check rate limit
     */
    function check(
        required key,
        maxAttempts = 60,
        decayMinutes = 1
    ) {
        var cacheKey = "rate_limit_#arguments.key#"
        var attempts = cache.get( cacheKey, 0 )

        if ( attempts >= maxAttempts ) {
            return {
                allowed: false,
                remaining: 0,
                retryAfter: getRetryAfter( cacheKey )
            }
        }

        // Increment attempts
        cache.set(
            cacheKey,
            attempts + 1,
            arguments.decayMinutes
        )

        return {
            allowed: true,
            remaining: maxAttempts - attempts - 1,
            retryAfter: 0
        }
    }

    /**
     * Clear rate limit
     */
    function clear( required key ) {
        cache.clear( "rate_limit_#arguments.key#" )
    }

    private function getRetryAfter( cacheKey ) {
        var metadata = cache.getCachedObjectMetadata( cacheKey )

        if ( isNull( metadata ) ) {
            return 0
        }

        return dateDiff( "s", now(), metadata.timeout )
    }
}
```

### Rate Limiting Interceptor

```boxlang
/**
 * interceptors/APIRateLimiter.cfc
 */
class extends="coldbox.system.Interceptor" {

    property name="rateLimiter" inject="RateLimiter"

    function preProcess( event, interceptData ) {
        // Skip non-API routes
        if ( !event.getCurrentEvent().startsWith( "api." ) ) {
            return
        }

        // Get identifier (API key or IP)
        var identifier = event.getValue( "apiKey", "", true ) ?:
                        event.getHTTPHeader( "REMOTE_ADDR" )

        // Check rate limit
        var result = rateLimiter.check(
            key: identifier,
            maxAttempts: 60,
            decayMinutes: 1
        )

        // Add rate limit headers
        event.setHTTPHeader(
            name: "X-RateLimit-Limit",
            value: 60
        )
        event.setHTTPHeader(
            name: "X-RateLimit-Remaining",
            value: result.remaining
        )

        // Block if exceeded
        if ( !result.allowed ) {
            event.setHTTPHeader(
                name: "Retry-After",
                value: result.retryAfter
            )

            event.renderData(
                type: "json",
                data: {
                    error: "Rate limit exceeded",
                    retry_after: result.retryAfter
                },
                statusCode: 429
            )

            event.noExecution()
        }
    }
}
```

## API Versioning

### Version-Specific Auth

```boxlang
/**
 * handlers/api/v1/Base.cfc
 */
class extends="coldbox.system.RestHandler" {

    // v1 uses API keys
    property name="apiKeyService" inject="APIKeyService"

    function preHandler( event, rc, prc ) {
        var apiKey = event.getHTTPHeader( "X-API-Key", "" )

        var keyData = apiKeyService.validate( apiKey )

        if ( isNull( keyData ) ) {
            return unauthorizedResponse( event )
        }

        prc.apiKey = keyData
    }
}

/**
 * handlers/api/v2/Base.cfc
 */
class extends="coldbox.system.RestHandler" {

    // v2 uses JWT
    property name="jwtService" inject="JWTService"

    function preHandler( event, rc, prc ) {
        var token = extractBearerToken( event )

        try {
            var payload = jwtService.validateToken( token )
            prc.userID = payload.sub

        } catch ( any e ) {
            return unauthorizedResponse( event )
        }
    }
}
```

## Advanced Patterns

### HMAC Request Signing

```boxlang
/**
 * HMAC signature validation
 */
class extends="coldbox.system.RestHandler" {

    property name="apiKeyService" inject="APIKeyService"

    function preHandler( event, rc, prc ) {
        var apiKey = event.getHTTPHeader( "X-API-Key", "" )
        var signature = event.getHTTPHeader( "X-Signature", "" )
        var timestamp = event.getHTTPHeader( "X-Timestamp", "" )

        // Validate API key exists
        var keyData = apiKeyService.validate( apiKey )

        if ( isNull( keyData ) ) {
            return unauthorizedResponse( event )
        }

        // Check timestamp (prevent replay)
        if ( abs( dateDiff( "s", timestamp, now() ) ) > 300 ) {
            return event.renderData(
                type: "json",
                data: {
                    error: "Request expired"
                },
                statusCode: 401
            )
        }

        // Build signature string
        var method = event.getHTTPMethod()
        var path = event.getCurrentRoutedURL()
        var body = event.getHTTPContent()

        var signatureString = "#method##chr(10)##path##chr(10)##timestamp##chr(10)##body#"

        // Calculate HMAC
        var expectedSignature = hmac(
            signatureString,
            keyData.secret,
            "HmacSHA256"
        )

        // Validate signature
        if ( signature != expectedSignature ) {
            return event.renderData(
                type: "json",
                data: {
                    error: "Invalid signature"
                },
                statusCode: 401
            )
        }

        prc.apiKey = keyData
    }
}
```

### Multi-Tenant API Keys

```boxlang
/**
 * Tenant-scoped API keys
 */
function validate( required key ) {
    var keyData = super.validate( arguments.key )

    if ( isNull( keyData ) ) {
        return
    }

    // Add tenant context
    keyData.tenantID = getTenantForAPIKey( keyData.id )

    return keyData
}

function checkTenantAccess( apiKey, resourceID ) {
    var resource = resourceService.find( resourceID )

    return resource.tenantID == apiKey.tenantID
}
```

## Best Practices

### Design Guidelines

1. **HTTPS Only**: Always use HTTPS
2. **Rate Limiting**: Prevent abuse
3. **Token Expiration**: Short-lived tokens
4. **Scope Limitation**: Minimal required scopes
5. **Audit Trail**: Log API usage
6. **Versioning**: Version your API
7. **Error Responses**: Clear, consistent errors
8. **Documentation**: Document authentication
9. **Token Rotation**: Support token rotation
10. **Monitoring**: Monitor for abuse

### Common Patterns

```boxlang
// ✅ Good: Check authorization header
var auth = event.getHTTPHeader( "Authorization", "" )

// ✅ Good: Validate token
if ( !jwtService.validateToken( token ) ) {
    return unauthorizedResponse()
}

// ✅ Good: Rate limiting
if ( !rateLimiter.check( apiKey ) ) {
    return tooManyRequestsResponse()
}

// ✅ Good: Scope validation
if ( !hasScope( "users:write" ) ) {
    return forbiddenResponse()
}
```

## Common Pitfalls

### Pitfalls to Avoid

1. **No HTTPS**: API keys over HTTP
2. **No Rate Limiting**: Unlimited requests
3. **Weak Keys**: Short or predictable keys
4. **No Expiration**: Permanent tokens
5. **Overly Broad Scopes**: All-access keys
6. **No Audit Trail**: Not logging usage
7. **Keys in URLs**: Exposing keys in query strings
8. **No Revocation**: Cannot revoke keys
9. **Detailed Errors**: Leaking information
10. **No Monitoring**: Missing abuse detection

### Anti-Patterns

```boxlang
// ❌ Bad: API key in URL
GET /api/users?api_key=abc123

// ✅ Good: API key in header
Authorization: Bearer abc123

// ❌ Bad: No rate limiting
// Unlimited requests allowed

// ✅ Good: Rate limit
if ( !rateLimiter.check( key, 60, 1 ) ) {
    return tooManyRequests()
}

// ❌ Bad: Detailed error
return { error: "API key abc123 not found in database" }

// ✅ Good: Generic error
return { error: "Invalid API key" }
```

## Related Skills

- [JWT Development](jwt-development.md) - JWT authentication
- [Authorization Patterns](authorization.md) - Authorization rules
- [CBSecurity Implementation](security-implementation.md) - Security framework

## References

- [REST API Security](https://restfulapi.net/security-essentials/)
- [API Key Best Practices](https://cloud.google.com/endpoints/docs/openapi/when-why-api-key)
- [OWASP API Security](https://owasp.org/www-project-api-security/)
