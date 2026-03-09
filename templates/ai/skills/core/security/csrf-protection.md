---
name: CSRF Protection
description: Complete guide to Cross-Site Request Forgery (CSRF) protection with cbcsrf, token validation, and secure form submissions
category: security
priority: high
triggers:
  - csrf
  - cross site request forgery
  - csrf token
  - form security
  - token validation
---

# CSRF Protection

## Overview

Cross-Site Request Forgery (CSRF) attacks trick users into executing unwanted actions. CBCSRF provides automatic CSRF token generation, validation, and protection for all state-changing operations.

## Core Concepts

### CSRF Attack Vector

- **Attack**: Malicious site triggers action on trusted site
- **Vulnerability**: Forms without token validation
- **Protection**: Unique tokens per session/request
- **Validation**: Server-side token verification
- **Double Submit**: Cookie and form token comparison

## Installation & Setup

### Install CBCSRF

```bash
box install cbcsrf
```

### Configuration

```boxlang
/**
 * config/ColdBox.cfc
 */
class {

    function configure() {
        moduleSettings = {
            cbcsrf: {
                // Enable CSRF protection
                enabled: true,

                // Token key name
                tokenKey: "_csrftoken",

                // Rotate token per request
                rotateTokens: false,

                // Verify method
                verifyMethod: "all",  // all, post, delete, put, patch

                // Token expiration (minutes)
                tokenExpiration: 30,

                // Excluded routes (public APIs)
                exclude: [
                    "^api\\.public\\."
                ]
            }
        }
    }
}
```

## Form Protection

### Adding CSRF Tokens to Forms

```html
<!-- views/users/create.cfm -->
<form action="#event.buildLink( 'users.store' )#" method="post">

    <!-- CSRF token (automatically included by cbcsrf) -->
    #csrf()#

    <div>
        <label for="name">Name:</label>
        <input type="text" name="name" id="name" required>
    </div>

    <div>
        <label for="email">Email:</label>
        <input type="email" name="email" id="email" required>
    </div>

    <button type="submit">Create User</button>
</form>
```

### Manual Token Generation

```html
<!-- Manual token insertion -->
<form method="post">
    <input type="hidden"
           name="#csrfKey()#"
           value="#csrfToken()#">

    <!-- Form fields -->
</form>
```

## Handler Validation

### Automatic Validation

```boxlang
/**
 * Automatic CSRF validation via interceptor
 */
class extends="coldbox.system.EventHandler" {

    property name="userService" inject="UserService"

    /**
     * POST /users
     * CSRF automatically validated before action
     */
    function store( event, rc, prc ) {
        // Token already validated by cbcsrf

        var user = userService.create( rc )

        relocate( "users.show" ).addQueryString( "id", user.id )
    }

    /**
     * DELETE /users/:id
     * CSRF validated for all state-changing methods
     */
    function delete( event, rc, prc ) {
        userService.delete( rc.id )

        relocate( "users.index" )
    }
}
```

### Manual Validation

```boxlang
/**
 * Manual CSRF validation
 */
class extends="coldbox.system.EventHandler" {

    property name="csrf" inject="CSRFService@cbcsrf"

    function sensitiveAction( event, rc, prc ) {
        // Manual validation
        if ( !csrf.verify( rc._csrftoken ) ) {
            throw(
                type: "InvalidCSRFToken",
                message: "CSRF token validation failed"
            )
        }

        // Process action
        performSensitiveAction()
    }
}
```

## AJAX Protection

### Adding Tokens to AJAX Requests

```html
<script>
// Store CSRF token in meta tag
document.addEventListener('DOMContentLoaded', function() {
    const token = document.querySelector('meta[name="csrf-token"]').content
    const tokenKey = document.querySelector('meta[name="csrf-key"]').content

    // Add to all AJAX requests
    fetch('/api/users', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
            'X-CSRF-TOKEN': token
        },
        body: JSON.stringify(userData)
    })
})
</script>

<!-- In layout -->
<meta name="csrf-token" content="#csrfToken()#">
<meta name="csrf-key" content="#csrfKey()#">
```

### Global AJAX Setup

```javascript
// Set up global AJAX defaults
document.addEventListener('DOMContentLoaded', function() {
    const token = document.querySelector('meta[name="csrf-token"]').content

    // jQuery setup
    $.ajaxSetup({
        headers: {
            'X-CSRF-TOKEN': token
        }
    })

    // Fetch wrapper
    const originalFetch = window.fetch
    window.fetch = function(url, options = {}) {
        if (!options.headers) {
            options.headers = {}
        }

        // Add CSRF token to POST, PUT, DELETE, PATCH
        const method = (options.method || 'GET').toUpperCase()
        if (['POST', 'PUT', 'DELETE', 'PATCH'].includes(method)) {
            options.headers['X-CSRF-TOKEN'] = token
        }

        return originalFetch(url, options)
    }
})
```

## API Protection

### API with CSRF

```boxlang
/**
 * REST API with CSRF protection
 */
class extends="coldbox.system.RestHandler" {

    property name="csrf" inject="CSRFService@cbcsrf"

    function preHandler( event, rc, prc ) {
        // Skip CSRF for GET requests
        if ( event.getHTTPMethod() == "GET" ) {
            return
        }

        // Verify CSRF token
        var token = event.getHTTPHeader( "X-CSRF-TOKEN", "" )

        if ( !csrf.verify( token ) ) {
            return event.renderData(
                type: "json",
                data: {
                    error: "CSRF token validation failed"
                },
                statusCode: 403
            )
        }
    }

    function create( event, rc, prc ) {
        // Token validated in preHandler

        var resource = resourceService.create( rc )

        return event.renderData(
            type: "json",
            data: resource,
            statusCode: 201
        )
    }
}
```

### Token API Endpoint

```boxlang
/**
 * Provide CSRF token to SPAs
 */
class extends="coldbox.system.RestHandler" {

    property name="csrf" inject="CSRFService@cbcsrf"

    /**
     * GET /api/csrf-token
     */
    function token( event, rc, prc ) {
        return event.renderData(
            type: "json",
            data: {
                token: csrf.generate(),
                key: csrf.getKey()
            }
        )
    }
}
```

## Custom CSRF Service

### Extended CSRF Service

```boxlang
/**
 * models/CustomCSRFService.cfc
 */
class singleton extends="cbcsrf.models.CSRFService" {

    /**
     * Verify token with additional checks
     */
    function verify( required token ) {
        // Call parent verification
        if ( !super.verify( arguments.token ) ) {
            return false
        }

        // Additional custom validation
        if ( !isValidOrigin() ) {
            log.warn( "CSRF: Invalid origin" )
            return false
        }

        if ( isRateLimited() ) {
            log.warn( "CSRF: Rate limit exceeded" )
            return false
        }

        return true
    }

    /**
     * Validate origin header
     */
    private function isValidOrigin() {
        var origin = getHTTPRequestData().headers[ "Origin" ] ?: ""
        var allowedOrigins = [ "https://myapp.com", "https://www.myapp.com" ]

        return allowedOrigins.contains( origin ) || origin == ""
    }

    /**
     * Check rate limiting
     */
    private function isRateLimited() {
        var ip = getHTTPRequestData().headers[ "REMOTE_ADDR" ]
        var key = "csrf_attempts_#ip#"

        var attempts = cache.get( key, 0 )

        if ( attempts > 10 ) {
            return true
        }

        cache.set( key, attempts + 1, 1 )  // 1 minute

        return false
    }
}
```

## Token Management

### Token Rotation

```boxlang
/**
 * Rotate tokens per request
 */
moduleSettings = {
    cbcsrf: {
        rotateTokens: true  // New token per request
    }
}
```

### Token Storage

```boxlang
/**
 * Custom token storage
 */
class singleton {

    property name="cache" inject="cachebox:default"

    function generate( sessionId ) {
        var token = createUUID()

        // Store in cache with session key
        cache.set(
            "csrf_#sessionId#",
            token,
            30  // 30 minutes
        )

        return token
    }

    function verify( token, sessionId ) {
        var storedToken = cache.get( "csrf_#sessionId#", "" )

        return token == storedToken
    }

    function invalidate( sessionId ) {
        cache.clear( "csrf_#sessionId#" )
    }
}
```

## Advanced Patterns

### Double Submit Cookie

```boxlang
/**
 * Double submit cookie pattern
 */
class extends="coldbox.system.EventHandler" {

    function preHandler( event, rc, prc ) {
        if ( event.getHTTPMethod() == "GET" ) {
            return
        }

        // Get token from cookie
        var cookieToken = cookie.get( "csrf_token", "" )

        // Get token from form/header
        var formToken = rc._csrftoken ?: event.getHTTPHeader( "X-CSRF-TOKEN", "" )

        // Compare tokens
        if ( cookieToken != formToken || cookieToken == "" ) {
            throw( "CSRF validation failed" )
        }
    }

    function setCSRFCookie( event, rc, prc ) {
        var token = csrf.generate()

        cookie.set(
            name: "csrf_token",
            value: token,
            httpOnly: true,
            secure: true,
            sameSite: "Strict"
        )
    }
}
```

### Per-Form Tokens

```boxlang
/**
 * Unique token per form
 */
class extends="coldbox.system.EventHandler" {

    property name="csrf" inject="CSRFService@cbcsrf"

    function create( event, rc, prc ) {
        // Generate form-specific token
        prc.formToken = csrf.generateFormToken(
            formName: "user_create",
            userID: prc.user.id
        )

        event.setView( "users/create" )
    }

    function store( event, rc, prc ) {
        // Verify form-specific token
        if ( !csrf.verifyFormToken( rc._csrftoken, "user_create" ) ) {
            throw( "Invalid form token" )
        }

        userService.create( rc )
    }
}
```

## Best Practices

### Design Guidelines

1. **All State Changes**: Protect POST, PUT, DELETE, PATCH
2. **Token in Forms**: Include token in all forms
3. **AJAX Protection**: Add tokens to AJAX requests
4. **Token Rotation**: Rotate tokens regularly
5. **SameSite Cookies**: Use SameSite=Strict/Lax
6. **HTTPS Only**: Always use HTTPS
7. **Origin Validation**: Check Origin/Referer headers
8. **Short Expiration**: Short token lifetimes
9. **Audit Trail**: Log CSRF failures
10. **User Education**: Clear error messages

### Common Patterns

```boxlang
// ✅ Good: Include in all forms
#csrf()#

// ✅ Good: Verify in handlers
if ( !csrf.verify( rc._csrftoken ) ) {
    throw( "CSRF validation failed" )
}

// ✅ Good: Add to AJAX
headers: {
    'X-CSRF-TOKEN': token
}
```

## Common Pitfalls

### Pitfalls to Avoid

1. **GET State Changes**: Changing state with GET
2. **Missing Tokens**: Forms without tokens
3. **No AJAX Protection**: AJAX without tokens
4. **Token in URL**: Exposing tokens in URLs
5. **No Expiration**: Tokens never expire
6. **Weak Tokens**: Predictable tokens
7. **No Origin Check**: Not validating origin
8. **Client-Only**: JavaScript-only validation
9. **Ignoring Failures**: Not logging failures
10. **Reusing Tokens**: Same token everywhere

### Anti-Patterns

```boxlang
// ❌ Bad: State change with GET
function delete( event, rc, prc ) {
    // DELETE via GET is vulnerable!
    userService.delete( rc.id )
}

// ✅ Good: Use POST/DELETE
function delete( event, rc, prc ) {
    // POST/DELETE with CSRF token
}

// ❌ Bad: No CSRF token
<form method="post">
    <!-- Missing token! -->
</form>

// ✅ Good: With token
<form method="post">
    #csrf()#
</form>

// ❌ Bad: Token in URL
<a href="/delete?id=1&_csrftoken=#token#">Delete</a>

// ✅ Good: Form with token
<form method="post" action="/delete">
    #csrf()#
    <input type="hidden" name="id" value="1">
    <button>Delete</button>
</form>
```

## Related Skills

- [CBSecurity Implementation](security-implementation.md) - Security framework
- [Authentication Patterns](authentication.md) - User authentication
- [API Authentication](api-authentication.md) - API security

## References

- [CBCSRF Documentation](https://forgebox.io/view/cbcsrf)
- [OWASP CSRF](https://owasp.org/www-community/attacks/csrf)
- [CSRF Prevention Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Cross-Site_Request_Forgery_Prevention_Cheat_Sheet.html)
