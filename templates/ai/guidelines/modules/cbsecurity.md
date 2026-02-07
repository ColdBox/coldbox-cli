# CBSecurity Module Guidelines

## Overview

CBSecurity is a comprehensive enterprise-grade security framework for ColdBox applications, providing authentication, authorization, JWT token management, CSRF protection, and security headers.

## Installation

```bash
box install cbsecurity
```

## Core Capabilities

- **Security Firewall** - Rule-based request protection
- **Authentication Manager** - Pluggable authentication (cbauth integration)
- **Authorization Service** - Permission and role-based access control
- **JWT Services** - Complete JSON Web Token support with refresh tokens
- **CSRF Protection** - Cross-Site Request Forgery prevention
- **Security Headers** - Industry-standard HTTP security headers
- **Basic Authentication** - HTTP Basic Auth support
- **Security Visualizer** - GUI for monitoring and configuration

## Configuration

In `config/ColdBox.cfc`:

```boxlang
moduleSettings = {
    cbauth = {
        userServiceClass = "UserService"
    },
    
    cbsecurity = {
        // Authentication
        authentication = {
            provider = "authenticationService@cbauth"
        },
        
        // Firewall
        firewall = {
            autoLoadFirewall = true,
            validator = "CBAuthValidator@cbsecurity",
            handlerAnnotationSecurity = true,
            invalidAuthenticationEvent = "security.login",
            defaultAuthenticationAction = "redirect",
            invalidAuthorizationEvent = "security.unauthorized",
            defaultAuthorizationAction = "redirect",
            
            // Security Rules
            rules = [
                {
                    whitelist = "",
                    securelist = "^admin",
                    match = "event",
                    roles = "admin",
                    action = "redirect"
                }
            ]
        },
        
        // JWT Settings
        jwt = {
            secretKey = getSystemSetting( "JWT_SECRET", "" ),
            expiration = 60, // minutes
            enableRefreshTokens = true,
            refreshExpiration = 10080, // 7 days
            algorithm = "HS512",
            customAuthHeader = "x-auth-token",
            tokenStorage = {
                enabled = true,
                keyPrefix = "cbjwt_",
                driver = "cachebox",
                properties = { cacheName = "default" }
            }
        }
    }
}
```

## Authentication with CBAuth

### User Service

Create a user service implementing `IUserService`:

```boxlang
component singleton {
    property name="userDAO" inject;
    
    function isValidCredentials( required string username, required string password ) {
        var user = userDAO.findByUsername( arguments.username )
        if ( isNull( user ) ) return false
        return bcrypt.checkPassword( arguments.password, user.getPassword() )
    }
    
    function retrieveUserByUsername( required string username ) {
        return userDAO.findByUsername( arguments.username )
    }
    
    function retrieveUserById( required id ) {
        return userDAO.find( arguments.id )
    }
}
```

### User Object

Implement `IAuthUser`:

```boxlang
component accessors="true" {
    property name="id";
    property name="username";
    property name="email";
    property name="roles" type="array";
    property name="permissions" type="array";
    
    function getId() {
        return variables.id
    }
    
    function hasPermission( required permission ) {
        return variables.permissions.findNoCase( arguments.permission ) > 0
    }
    
    function hasRole( required role ) {
        return variables.roles.findNoCase( arguments.role ) > 0
    }
}
```

### Login/Logout

```boxlang
// In handler
class Security extends coldbox.system.EventHandler {
    property name="auth" inject="authenticationService@cbauth";
    
    function login( event, rc, prc ) {
        if ( event.isPOST() ) {
            try {
                var user = auth.authenticate( rc.username, rc.password )
                flash.put( "notice", "Welcome back!" )
                relocate( "admin.dashboard" )
            } catch ( InvalidCredentials e ) {
                flash.put( "error", "Invalid credentials" )
                relocate( "security.login" )
            }
        }
        event.setView( "security/login" )
    }
    
    function logout( event, rc, prc ) {
        auth.logout()
        flash.put( "notice", "You have been logged out" )
        relocate( "main.index" )
    }
}
```

## Security Rules

### Rule Structure

```boxlang
rules = [
    {
        // Pattern matching
        whitelist = "",
        securelist = "^admin",
        match = "event", // or "url"
        
        // Authorization
        roles = "admin,superadmin",
        permissions = "USER_ADMIN,CONTENT_ADMIN",
        
        // Actions
        action = "redirect", // or "override", "block"
        
        // Redirects
        redirect = "security.login",
        overrideEvent = "security.unauthorized",
        
        // HTTP restrictions
        httpMethods = "POST,PUT,DELETE",
        
        // IP restrictions
        allowedIPs = "127.0.0.1,192.168.1.*"
    }
]
```

### Rule Examples

```boxlang
rules = [
    // Secure admin area
    {
        securelist = "^admin",
        roles = "admin"
    },
    
    // API endpoints require authentication
    {
        securelist = "^api",
        match = "url",
        action = "block"
    },
    
    // Specific permissions required
    {
        securelist = "users\\.(create|update|delete)",
        permissions = "USER_ADMIN"
    },
    
    // HTTP method restrictions
    {
        securelist = "^api/users",
        httpMethods = "POST,PUT,DELETE",
        roles = "admin"
    }
]
```

## Handler Annotations

Secure handlers and actions using annotations:

```boxlang
class Admin extends coldbox.system.EventHandler {
    // Secure entire handler
    @secured
    function index( event, rc, prc ) {
        // Only accessible to logged-in users
    }
    
    // Specific roles
    @secured="admin,superadmin"
    function users( event, rc, prc ) {
        // Only admins
    }
    
    // Specific permissions
    @secured
    @securedPermissions="USER_ADMIN,CONTENT_ADMIN"
    function createUser( event, rc, prc ) {
        // Requires permissions
    }
    
    // Custom action
    @secured
    @securityAction="override"
    @securityOverrideEvent="security.unauthorized"
    function sensitiveAction( event, rc, prc ) {
        // Custom handling
    }
}
```

## CBSecurity Model

Use `cbsecure()` helper for programmatic security:

```boxlang
// In handlers, views, layouts
if ( cbsecure().isLoggedIn() ) {
    // User is authenticated
}

// Check permissions
if ( cbsecure().has( "USER_ADMIN" ) ) {
    // User has permission
}

// Authorization context
cbsecure()
    .when( "PUBLISH_CONTENT", () => {
        // User has permission
        contentService.publish( content )
    }, () => {
        // User lacks permission
        flash.put( "error", "Insufficient permissions" )
    } )

// Secure code block
cbsecure()
    .secure( "DELETE_CONTENT,ADMIN" )
    .run( () => {
        contentService.delete( id )
    } )

// Verify or throw exception
cbsecure()
    .whenAll( "USER_ADMIN,CONTENT_ADMIN" )
    .orFail( "You need admin permissions" )

// Authentication
var user = cbsecure().authenticate( username, password )
cbsecure().logout()
```

## JWT Authentication

### Configuration

```boxlang
jwt = {
    secretKey = getSystemSetting( "JWT_SECRET", "" ),
    issuer = "myapp.com",
    expiration = 60,
    customAuthHeader = "x-auth-token",
    algorithm = "HS512",
    enableRefreshTokens = true,
    refreshExpiration = 10080,
    tokenStorage = {
        enabled = true,
        driver = "cachebox"
    }
}
```

### JWT Service Usage

```boxlang
class API extends coldbox.system.EventHandler {
    property name="jwtService" inject="JWTService@cbsecurity";
    
    function login( event, rc, prc ) {
        try {
            var user = auth.authenticate( rc.username, rc.password )
            
            // Generate JWT token
            var token = jwtService.attempt( rc.username, rc.password )
            
            event.renderData(
                data = {
                    token = token.access_token,
                    refresh_token = token.refresh_token,
                    expires_in = token.expires_in
                }
            )
        } catch ( InvalidCredentials e ) {
            event.renderData(
                data = { error = "Invalid credentials" },
                statusCode = 401
            )
        }
    }
    
    function refresh( event, rc, prc ) {
        var newTokens = jwtService.refreshToken( rc.refresh_token )
        event.renderData( data = newTokens )
    }
}
```

### JWT Validator

Configure for API routes:

```boxlang
// Use JWT validator for API
firewall = {
    validator = "JWTAuthValidator@cbsecurity",
    rules = [
        {
            securelist = "^api",
            match = "url"
        }
    ]
}

// Or per-module in ModuleConfig.cfc
settings = {
    cbsecurity = {
        firewall = {
            validator = "JWTAuthValidator@cbsecurity"
        }
    }
}
```

## CSRF Protection

Enable CSRF protection:

```boxlang
csrf = {
    enabled = true,
    key = "csrf_token",
    tokenTimeout = 30,
    validateTokens = true,
    enableAutoVerifier = true
}
```

In forms:

```cfml
<form method="POST" action="#event.buildLink( 'users.save' )#">
    #csrfField()#
    <input type="text" name="name">
    <button type="submit">Save</button>
</form>
```

## Security Headers

Configure security headers:

```boxlang
securityHeaders = {
    enabled = true,
    
    // Content Security Policy
    contentSecurityPolicy = {
        enabled = true,
        policy = "default-src 'self'"
    },
    
    // XSS Protection
    xssProtection = {
        enabled = true,
        mode = "block"
    },
    
    // Clickjacking protection
    xFrameOptions = {
        enabled = true,
        value = "SAMEORIGIN"
    },
    
    // HTTPS Strict Transport Security
    strictTransportSecurity = {
        enabled = true,
        maxAge = 31536000,
        includeSubDomains = true
    }
}
```

## Security Visualizer

Enable the visualizer:

```boxlang
enableSecurityVisualizer = true
```

Access at: `/cbsecurity`

**Secure it:**

```boxlang
rules = [
    {
        securelist = "^cbsecurity",
        roles = "admin"
    }
]
```

## Common Patterns

### Protecting Admin Area

```boxlang
rules = [
    {
        securelist = "^admin",
        roles = "admin",
        action = "redirect",
        redirect = "security.login"
    }
]
```

### API with JWT

```boxlang
moduleSettings = {
    cbsecurity = {
        firewall = {
            validator = "JWTAuthValidator@cbsecurity",
            rules = [
                {
                    securelist = "^api/v1",
                    match = "url",
                    action = "block"
                }
            ]
        }
    }
}
```

### Permission-Based Authorization

```boxlang
class Users extends coldbox.system.EventHandler {
    @secured
    @securedPermissions="USER_READ"
    function index( event, rc, prc ) {}
    
    @secured
    @securedPermissions="USER_CREATE"
    function create( event, rc, prc ) {}
    
    @secured
    @securedPermissions="USER_DELETE"
    function delete( event, rc, prc ) {}
}
```

## Documentation

For complete CBSecurity documentation, visit:
https://coldbox-security.ortusbooks.com
