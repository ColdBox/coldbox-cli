# CBCSRF - Cross-Site Request Forgery Protection

> **Module**: cbcsrf
> **Category**: Security
> **Purpose**: Provides CSRF token generation and validation for protecting against CSRF attacks

## Overview

CBCSRF provides comprehensive Cross-Site Request Forgery protection for ColdBox applications through automatic token generation, validation, and management. It protects against CSRF attacks by requiring valid tokens for state-changing operations.

## Core Features

- Automatic CSRF token generation
- Token validation middleware
- Session and cookie-based token storage
- Automatic form token injection
- JavaScript/AJAX token support
- Token rotation and expiration
- Exemption patterns for specific routes
- Multiple token storage strategies

## Installation

```bash
box install cbcsrf
```

## Configuration

```javascript
// config/ColdBox.cfc - moduleSettings
moduleSettings = {
    cbcsrf: {
        // Enable/disable CSRF protection
        enabled: true,

        // Token key name in forms/headers
        tokenKey: "_token",

        // Token rotation on each request
        rotateTokens: false,

        // Token expiration in minutes (0 = session lifetime)
        tokenExpiration: 0,

        // Verify referer header
        verifyReferer: true,

        // Exempted routes (regex patterns)
        exemptions: [
            "^api/webhook"
        ],

        // HTTP methods to protect (state-changing only)
        protectedMethods: [ "POST", "PUT", "PATCH", "DELETE" ],

        // Token storage strategy: session, cookie
        storageStrategy: "session",

        // Error handler when validation fails
        onInvalidToken: function( event, rc, prc ) {
            throw(
                type = "InvalidCSRFToken",
                message = "Invalid or missing CSRF token"
            );
        }
    }
};
```

## Usage Patterns

### Form Protection

```html
<!-- Automatic token injection with cbcsrf form helper -->
<form method="POST" action="#event.buildLink('user.update')#">
    #csrf()#
    <input type="text" name="username">
    <button type="submit">Update</button>
</form>

<!-- Manual token injection -->
<form method="POST" action="#event.buildLink('user.update')#">
    <input type="hidden" name="_token" value="#csrfToken()#">
    <input type="text" name="username">
    <button type="submit">Update</button>
</form>
```

### AJAX Requests

```javascript
// Include token in AJAX headers
fetch('/api/user/update', {
    method: 'POST',
    headers: {
        'X-CSRF-TOKEN': document.querySelector('meta[name="csrf-token"]').content,
        'Content-Type': 'application/json'
    },
    body: JSON.stringify(data)
});

// jQuery example
$.ajax({
    url: '/api/user/update',
    method: 'POST',
    headers: {
        'X-CSRF-TOKEN': $('meta[name="csrf-token"]').attr('content')
    },
    data: data
});
```

### Meta Tag for JavaScript

```html
<!-- In your layout head -->
<meta name="csrf-token" content="#csrfToken()#">
```

### Handler Token Validation

```javascript
// Validate CSRF token manually in handler
component {
    property name="csrfService" inject="CSRFService@cbcsrf";

    function update( event, rc, prc ) {
        // Manual validation (usually automatic via interceptor)
        if ( !csrfService.verify( rc._token ?: "" ) ) {
            throw(
                type = "InvalidCSRFToken",
                message = "CSRF token validation failed"
            );
        }

        // Process request
    }

    // Exempt specific action from CSRF protection
    function webhook( event, rc, prc ) exemptFromCSRF {
        // Process webhook without CSRF validation
    }
}
```

### Token Management

```javascript
// Get current token
var token = csrfToken();

// Get token in handler
var token = csrfService.getToken();

// Generate new token
var newToken = csrfService.generateToken();

// Verify token
var isValid = csrfService.verify( incomingToken );

// Rotate token (generate new one)
csrfService.rotateToken();
```

### Route Exemptions

```javascript
// config/Router.cfc
function configure() {
    // Exempt specific routes
    route( "/webhooks/github" )
        .withHandler( "webhooks.github" )
        .withAction( { POST: "process" } )
        .exemptFromCSRF();

    // Exempt route group
    group( { pattern: "/api/public" }, function() {
        // All routes in this group exempt from CSRF
        route( "/webhook" ).to( "api.webhook" );
    }).exemptFromCSRF();
}
```

### SPA / API Token Headers

```javascript
// For SPAs, send token in custom header
// Client-side setup
const csrfToken = document.querySelector('meta[name="csrf-token"]').content;

// Add to all requests
axios.defaults.headers.common['X-CSRF-TOKEN'] = csrfToken;

// Or per-request
axios.post('/api/user', data, {
    headers: { 'X-CSRF-TOKEN': csrfToken }
});
```

## Interceptor Integration

```javascript
// Automatic validation via interceptor (default behavior)
// config/Coldbox.cfc
interceptors = [
    {
        class: "cbcsrf.interceptors.CSRFInterceptor",
        properties: {}
    }
];
```

## Custom Token Storage

```javascript
// Implement custom storage strategy
component implements="cbcsrf.interfaces.ITokenStorage" {

    function store( required string token ) {
        // Store token (e.g., in cache, database)
    }

    function retrieve() {
        // Retrieve stored token
    }

    function clear() {
        // Clear stored token
    }

    function exists() {
        // Check if token exists
    }
}

// Configure custom storage
moduleSettings = {
    cbcsrf: {
        storageStrategy: wirebox.getInstance( "MyCustomTokenStorage" )
    }
};
```

## Testing

```javascript
// Test with CSRF protection
describe( "User Updates", function() {

    beforeEach( function() {
        // Get valid CSRF token
        variables.csrfToken = getInstance( "CSRFService@cbcsrf" ).getToken();
    });

    it( "can update user with valid token", function() {
        var event = execute(
            event = "user.update",
            renderResults = true,
            eventArguments = {
                _token: variables.csrfToken,
                username: "testuser"
            }
        );

        expect( event.getStatusCode() ).toBe( 200 );
    });

    it( "rejects update with invalid token", function() {
        expect( function() {
            execute(
                event = "user.update",
                renderResults = true,
                eventArguments = {
                    _token: "invalid-token",
                    username: "testuser"
                }
            );
        }).toThrow( "InvalidCSRFToken" );
    });

    it( "bypasses CSRF for exempted routes", function() {
        var event = execute(
            event = "webhooks.github",
            renderResults = true,
            eventArguments = {
                payload: "webhook-data"
            }
        );

        expect( event.getStatusCode() ).toBe( 200 );
    });
});
```

## Best Practices

1. **Always Protect State-Changing Operations**: Apply CSRF protection to POST, PUT, PATCH, DELETE
2. **Use Automatic Token Injection**: Leverage csrf() helper in forms
3. **Include Meta Tag for SPAs**: Add CSRF meta tag for JavaScript applications
4. **Exempt Public APIs Carefully**: Only exempt truly public endpoints
5. **Rotate Tokens Appropriately**: Enable rotation for high-security applications
6. **Verify Referer Headers**: Enable referer verification for additional security
7. **Use HTTPS**: CSRF protection is most effective over HTTPS
8. **Set Appropriate Token Expiration**: Balance security and user experience

## Common Patterns

### Form Builder Integration

```html
<!-- Using HTML helper with automatic CSRF -->
#html.startForm(
    action = "user.update",
    method = "POST",
    csrfProtection = true
)#
    #html.textField( name="username" )#
    #html.submitButton( value="Update" )#
#html.endForm()#
```

### RESTful API with Token Exchange

```javascript
// Login endpoint returns CSRF token
function login( event, rc, prc ) {
    // Authenticate user
    auth().attempt( rc.username ?: "", rc.password ?: "" );

    // Return token for subsequent requests
    prc.response = {
        token: jwt().attempt( auth().user() ),
        csrf_token: csrfToken()
    };
}

// Subsequent API calls include CSRF token
function updateProfile( event, rc, prc ) validateCSRF {
    // CSRF automatically validated by annotation
    // Update user profile
}
```

### Double-Submit Cookie Pattern

```javascript
// Alternative pattern using cookie
moduleSettings = {
    cbcsrf: {
        storageStrategy: "cookie",
        cookieName: "XSRF-TOKEN",
        cookieHttpOnly: false // Allow JavaScript access
    }
};

// Client reads cookie and sends in header
const token = getCookie('XSRF-TOKEN');
fetch('/api/update', {
    headers: { 'X-XSRF-TOKEN': token }
});
```

## Security Considerations

- CSRF tokens should be unpredictable and cryptographically secure
- Tokens should be tied to user sessions
- Use HTTPS to prevent token interception
- Implement token expiration for sensitive operations
- Consider token rotation for high-security scenarios
- Validate referer headers as additional check
- Don't include tokens in URLs (use forms/headers only)
- Exempt only truly public, stateless endpoints

## Framework Integration

- Works seamlessly with ColdBox routing
- Integrates with CBSecurity for comprehensive security
- Compatible with JWT/session-based authentication
- Supports both server-rendered and SPA applications
- Automatic integration with ColdBox interceptors

## Additional Resources

- [OWASP CSRF Prevention Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Cross-Site_Request_Forgery_Prevention_Cheat_Sheet.html)
- [ColdBox Security Best Practices](https://coldbox.ortusbooks.com/digging-deeper/recipes/security)
