---
name: JWT Development
description: Complete guide to JSON Web Tokens (JWT) for stateless authentication, token generation, validation, refresh tokens, and API security
category: security
priority: high
triggers:
  - jwt
  - json web token
  - token authentication
  - bearer token
  - refresh token
  - stateless auth
---

# JWT Development

## Overview

JSON Web Tokens (JWT) provide stateless authentication for APIs and modern applications. CBSecurity integrates JWT authentication with token generation, validation, refresh tokens, and comprehensive security features.

## Core Concepts

### JWT Architecture

- **Token Structure**: Header.Payload.Signature
- **Stateless**: No server-side session storage
- **Claims**: User data and metadata in payload
- **Signing**: HMAC or RSA signature verification
- **Expiration**: Time-limited tokens
- **Refresh Tokens**: Long-lived token renewal

## Installation & Setup

### Install CBSecurity with JWT

```bash
box install cbsecurity
box install jwtcfml
```

### JWT Configuration

```boxlang
/**
 * config/ColdBox.cfc
 */
class {

    function configure() {
        moduleSettings = {
            cbsecurity: {
                // Authentication service
                authenticationService: "JWTService@models",

                // JWT settings
                jwt: {
                    // Token settings
                    issuer: "myapp",
                    audience: "myapp-users",
                    secretKey: getSystemSetting( "JWT_SECRET" ),
                    expiration: 60, // minutes

                    // Refresh token
                    refreshToken: {
                        enabled: true,
                        expiration: 10080 // 7 days in minutes
                    },

                    // Token storage (for refresh tokens)
                    tokenStorage: {
                        enabled: true,
                        keyPrefix: "jwt_",
                        provider: "CacheBox"
                    }
                },

                // Firewall rules
                firewall: {
                    enabled: true,
                    defaultAction: "block",
                    statusCode: 401
                },

                // Secure API routes
                rules: [
                    {
                        whitelist: "api.auth.login,api.auth.register",
                        match: "event"
                    },
                    {
                        secureList: "^api\\.",
                        match: "event",
                        action: "block"
                    }
                ]
            }
        }
    }
}
```

## JWT Service

### Creating JWT Service

```boxlang
/**
 * models/JWTService.cfc
 */
class singleton {

    property name="jwtService" inject="JWTService@cbsecurity"
    property name="userService" inject="UserService"
    property name="bcrypt" inject="@BCrypt"

    /**
     * Generate access token
     */
    function generateToken( required user ) {
        return jwtService.encode( {
            sub: user.id,
            email: user.email,
            name: user.name,
            roles: user.roles,
            permissions: user.permissions,
            iat: now(),
            exp: dateAdd( "n", 60, now() )
        } )
    }

    /**
     * Generate refresh token
     */
    function generateRefreshToken( required user ) {
        return jwtService.encode( {
            sub: user.id,
            type: "refresh",
            iat: now(),
            exp: dateAdd( "d", 7, now() )
        } )
    }

    /**
     * Authenticate and return tokens
     */
    function authenticate( required username, required password ) {
        // Validate credentials
        var user = userService.findByUsername( arguments.username )

        if ( !bcrypt.checkPassword( arguments.password, user.password ) ) {
            throw( type: "InvalidCredentials", message: "Invalid credentials" )
        }

        // Generate tokens
        return {
            access_token: generateToken( user ),
            refresh_token: generateRefreshToken( user ),
            token_type: "Bearer",
            expires_in: 3600
        }
    }

    /**
     * Validate token
     */
    function validateToken( required token ) {
        try {
            var payload = jwtService.decode( arguments.token )

            // Check expiration
            if ( payload.exp < now() ) {
                throw( "Token expired" )
            }

            return payload

        } catch ( any e ) {
            throw( type: "InvalidToken", message: "Invalid or expired token" )
        }
    }

    /**
     * Refresh access token
     */
    function refresh( required refreshToken ) {
        // Validate refresh token
        var payload = jwtService.decode( arguments.refreshToken )

        if ( payload.type != "refresh" ) {
            throw( "Invalid refresh token" )
        }


        if ( payload.exp < now() ) {
            throw( "Refresh token expired" )
        }

        // Get user
        var user = userService.find( payload.sub )

        // Generate new access token
        return {
            access_token: generateToken( user ),
            token_type: "Bearer",
            expires_in: 3600
        }
    }

    /**
     * Get authenticated user from token
     */
    function getUser() {
        var token = getRequestToken()

        if ( isNull( token ) ) {
            return {}
        }

        var payload = validateToken( token )

        return userService.find( payload.sub )
    }

    /**
     * Check if user is logged in
     */
    function isLoggedIn() {
        try {
            var token = getRequestToken()

            if ( isNull( token ) ) {
                return false
            }

            validateToken( token )

            return true

        } catch ( any e ) {
            return false
        }
    }

    /**
     * Extract token from request
     */
    private function getRequestToken() {
        var header = getHTTPRequestData().headers[ "Authorization" ] ?: ""

        if ( header.left( 7 ) == "Bearer " ) {
            return header.mid( 8 )
        }

        return
    }
}
```

## Authentication Endpoint

### Login Handler

```boxlang
/**
 * handlers/api/Auth.cfc
 */
class extends="coldbox.system.RestHandler" {

    property name="jwtService" inject="JWTService"
    property name="validator" inject="ValidationManager@cbvalidation"

    /**
     * POST /api/auth/login
     */
    function login( event, rc, prc ) {
        // Validate input
        var validationResult = validator.validate(
            target: rc,
            constraints: {
                email: { required: true, type: "email" },
                password: { required: true }
            }
        )

        if ( validationResult.hasErrors() ) {
            return event.renderData(
                type: "json",
                data: {
                    error: "Validation failed",
                    messages: validationResult.getAllErrors()
                },
                statusCode: 400
            )
        }

        try {
            // Authenticate
            var tokens = jwtService.authenticate( rc.email, rc.password )

            return event.renderData(
                type: "json",
                data: tokens,
                statusCode: 200
            )

        } catch ( InvalidCredentials e ) {
            return event.renderData(
                type: "json",
                data: {
                    error: "Invalid credentials"
                },
                statusCode: 401
            )
        }
    }

    /**
     * POST /api/auth/refresh
     */
    function refresh( event, rc, prc ) {
        if ( !rc.keyExists( "refresh_token" ) ) {
            return event.renderData(
                type: "json",
                data: {
                    error: "Refresh token required"
                },
                statusCode: 400
            )
        }

        try {
            var tokens = jwtService.refresh( rc.refresh_token )

            return event.renderData(
                type: "json",
                data: tokens,
                statusCode: 200
            )

        } catch ( any e ) {
            return event.renderData(
                type: "json",
                data: {
                    error: "Invalid or expired refresh token"
                },
                statusCode: 401
            )
        }
    }

    /**
     * POST /api/auth/logout
     */
    function logout( event, rc, prc ) {
        // Invalidate tokens in storage if using token storage

        return event.renderData(
            type: "json",
            data: {
                message: "Logged out successfully"
            },
            statusCode: 200
        )
    }

    /**
     * GET /api/auth/me
     */
    function me( event, rc, prc ) {
        var user = jwtService.getUser()

        return event.renderData(
            type: "json",
            data: {
                id: user.id,
                email: user.email,
                name: user.name,
                roles: user.roles
            },
            statusCode: 200
        )
    }
}
```

## API Authentication

### Securing API Endpoints

```boxlang
/**
 * handlers/api/Users.cfc
 */
class extends="coldbox.system.RestHandler" {

    property name="userService" inject="UserService"
    property name="jwtService" inject="JWTService"

    /**
     * GET /api/users
     */
    function index( event, rc, prc ) {
        // JWT automatically validated by firewall rules

        var users = userService.list()

        return event.renderData(
            type: "json",
            data: users,
            statusCode: 200
        )
    }

    /**
     * GET /api/users/:id
     */
    function show( event, rc, prc ) {
        var user = userService.find( rc.id )

        return event.renderData(
            type: "json",
            data: user,
            statusCode: 200
        )
    }

    /**
     * POST /api/users
     */
    function create( event, rc, prc ) {
        // Check permissions
        var currentUser = jwtService.getUser()

        if ( !currentUser.hasPermission( "users.create" ) ) {
            return event.renderData(
                type: "json",
                data: {
                    error: "Insufficient permissions"
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
}
```

## JWT Interceptor

### Custom JWT Interceptor

```boxlang
/**
 * interceptors/JWTInterceptor.cfc
 */
class extends="coldbox.system.Interceptor" {

    property name="jwtService" inject="JWTService"
    property name="log" inject="logbox:logger:{this}"

    function preProcess( event, interceptData ) {
        // Skip public routes
        if ( isPublicRoute( event.getCurrentEvent() ) ) {
            return
        }

        // Validate JWT
        try {
            var token = extractToken( event )

            if ( isNull( token ) ) {
                throw( "Missing token" )
            }

            var payload = jwtService.validateToken( token )

            // Store user in request
            event.setValue( "jwtPayload", payload )
            event.setValue( "userId", payload.sub )

        } catch ( any e ) {
            log.warn( "JWT validation failed: #e.message#" )

            event.renderData(
                type: "json",
                data: {
                    error: "Unauthorized",
                    message: e.message
                },
                statusCode: 401
            )

            event.noExecution()
        }
    }

    private function extractToken( event ) {
        var header = event.getHTTPHeader( "Authorization", "" )

        if ( header.left( 7 ) == "Bearer " ) {
            return header.mid( 8 )
        }

        return
    }

    private function isPublicRoute( eventName ) {
        var publicRoutes = [
            "api.auth.login",
            "api.auth.register",
            "api.auth.refresh"
        ]

        return publicRoutes.contains( eventName )
    }
}
```

## Token Blacklisting

### Blacklist Service

```boxlang
/**
 * models/TokenBlacklistService.cfc
 */
class singleton {

    property name="cache" inject="cachebox:default"

    /**
     * Blacklist token
     */
    function blacklist( required token, expiration ) {
        cache.set(
            "blacklist_#arguments.token#",
            true,
            arguments.expiration ?: 60
        )
    }

    /**
     * Check if token is blacklisted
     */
    function isBlacklisted( required token ) {
        return cache.lookup( "blacklist_#arguments.token#" )
    }

    /**
     * Clear blacklist
     */
    function clear() {
        cache.clearByKeySnippet( "blacklist_" )
    }
}
```

### Using Token Blacklist

```boxlang
function logout( event, rc, prc ) {
    var token = getRequestToken()

    if ( !isNull( token ) ) {
        var payload = jwtService.decode( token )

        // Calculate remaining time
        var remainingMinutes = dateDiff( "n", now(), payload.exp )

        // Blacklist token
        tokenBlacklistService.blacklist( token, remainingMinutes )
    }

    return event.renderData(
        type: "json",
        data: {
            message: "Logged out successfully"
        }
    )
}
```

## Advanced Patterns

### Token Refresh Strategy

```boxlang
/**
 * Automatic token refresh
 */
class extends="coldbox.system.Interceptor" {

    property name="jwtService" inject="JWTService"

    function preProcess( event, interceptData ) {
        var token = extractToken( event )

        if ( isNull( token ) ) {
            return
        }

        var payload = jwtService.decode( token )

        // Check if token expires soon (within 5 minutes)
        var minutesUntilExpiry = dateDiff( "n", now(), payload.exp )

        if ( minutesUntilExpiry <= 5 ) {
            // Attach new token in response header
            var newToken = jwtService.generateToken( payload.sub )

            event.setHTTPHeader(
                name: "X-New-Token",
                value: newToken
            )
        }
    }
}
```

### Role-Based Tokens

```boxlang
function generateToken( required user ) {
    return jwtService.encode( {
        sub: user.id,
        email: user.email,
        roles: user.roles,
        permissions: user.permissions,

        // Custom claims
        tenant: user.tenantID,
        subscription: user.subscription.level,

        iat: now(),
        exp: dateAdd( "n", 60, now() )
    } )
}
```

### API Key + JWT

```boxlang
/**
 * Hybrid authentication
 */
class extends="coldbox.system.RestHandler" {

    property name="jwtService" inject="JWTService"
    property name="apiKeyService" inject="APIKeyService"

    function preHandler( event, rc, prc ) {
        // Try JWT first
        var token = extractJWT( event )

        if ( !isNull( token ) ) {
            prc.user = jwtService.getUser( token )
            return
        }

        // Fall back to API key
        var apiKey = event.getHTTPHeader( "X-API-Key", "" )

        if ( !apiKeyService.validate( apiKey ) ) {
            return event.renderData(
                type: "json",
                data: { error: "Unauthorized" },
                statusCode: 401
            )
        }

        prc.user = apiKeyService.getUser( apiKey )
    }
}
```

## Best Practices

### Design Guidelines

1. **Short-Lived Tokens**: Keep access tokens short (15-60 min)
2. **Secure Secret**: Use strong, random secret keys
3. **HTTPS Only**: Always use HTTPS
4. **Token Validation**: Validate on every request
5. **Refresh Tokens**: Use for token renewal
6. **Minimal Claims**: Only include necessary data
7. **Token Revocation**: Implement blacklisting
8. **Error Handling**: Clear, secure error messages
9. **Rate Limiting**: Prevent brute force
10. **Audit Logging**: Log authentication events

### Common Patterns

```boxlang
// ✅ Good: Short-lived access token
expiration: 60  // 60 minutes

// ✅ Good: Validate token
var payload = jwtService.validateToken( token )

// ✅ Good: Extract from Authorization header
var bearer = event.getHTTPHeader( "Authorization" )
var token = bearer.mid( 8 )

// ✅ Good: Return clear errors
return event.renderData(
    data: { error: "Unauthorized" },
    statusCode: 401
)
```

## Common Pitfalls

### Pitfalls to Avoid

1. **Long-Lived Tokens**: Tokens that never expire
2. **Weak Secrets**: Short or predictable secrets
3. **Sensitive Data**: PII in tokens
4. **No Validation**: Not validating signatures
5. **Client Storage**: Storing in localStorage
6. **No HTTPS**: Transmitting over HTTP
7. **No Revocation**: Cannot invalidate tokens
8. **Algorithm Confusion**: Not specifying algorithm
9. **No Expiration Check**: Accepting expired tokens
10. **Information Leakage**: Detailed error messages

### Anti-Patterns

```boxlang
// ❌ Bad: Long-lived token
expiration: 525600  // 1 year!

// ✅ Good: Short-lived
expiration: 60  // 1 hour

// ❌ Bad: Sensitive data in token
{ ssn: "123-45-6789", password: "..." }

// ✅ Good: Minimal claims
{ sub: userId, roles: ["user"] }

// ❌ Bad: Not validating signature
var payload = deserializeJSON( base64Decode( token ) )

// ✅ Good: Proper validation
var payload = jwtService.validateToken( token )

// ❌ Bad: Detailed error
throw( "Token signature invalid: #details#" )

// ✅ Good: Generic error
throw( "Invalid token" )
```

## Related Skills

- [API Authentication](api-authentication.md) - API security patterns
- [Authentication Patterns](authentication.md) - User authentication
- [CBSecurity Implementation](security-implementation.md) - Security framework

## References

- [JWT.io](https://jwt.io/)
- [RFC 7519](https://tools.ietf.org/html/rfc7519)
- [CBSecurity JWT](https://coldbox-security.ortusbooks.com/usage/jwt)
