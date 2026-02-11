---
name: CBSecurity Implementation
description: Complete guide to CBSecurity framework setup, security rules, authentication, authorization, and enterprise security patterns
category: security
priority: high
triggers:
  - cbsecurity
  - security
  - authentication
  - authorization
  - security rules
  - firewall
---

# CBSecurity Implementation

## Overview

CBSecurity is ColdBox's enterprise security framework providing authentication, authorization, firewall rules, security handlers, and comprehensive security event model. Proper security implementation protects applications from unauthorized access.

## Core Concepts

### CBSecurity Architecture

- **Security Service**: Central security orchestration
- **Firewall**: Rule-based access control
- **Authentication Services**: User authentication strategies
- **Authorization**: Permission-based access control
- **Security Events**: Interceptor-based security lifecycle
- **Security Validators**: Custom validation logic

## Installation & Setup

### Install CBSecurity

```bash
box install cbsecurity
```

### Basic Configuration

```boxlang
/**
 * config/ColdBox.cfc
 */
class {

    function configure() {
        // Module settings
        moduleSettings = {
            cbsecurity: {
                // Authentication service
                authenticationService: "SecurityService@models",

                // Firewall
                firewall: {
                    enabled: true,
                    defaultAction: "redirect",
                    defaultRedirect: "/login"
                },

                // Rules
                rules: [
                    {
                        secureList: "admin",
                        match: "event",
                        roles: "admin",
                        action: "redirect"
                    }
                ]
            }
        }
    }
}
```

## Authentication Service

### Creating Authentication Service

```boxlang
/**
 * models/SecurityService.cfc
 */
class singleton {

    property name="userService" inject="UserService"
    property name="bcrypt" inject="@BCrypt"
    property name="sessionStorage" inject="sessionStorage@cbstorages"

    /**
     * Authenticate user credentials
     */
    function authenticate( required username, required password ) {
        try {
            var user = userService.findByUsername( arguments.username )

            if ( !bcrypt.checkPassword( arguments.password, user.password ) ) {
                throw( "Invalid credentials" )
            }

            // Store in session
            sessionStorage.set( "user", user )

            return true

        } catch ( any e ) {
            return false
        }
    }

    /**
     * Get authenticated user
     */
    function getUser() {
        return sessionStorage.get( "user", {} )
    }

    /**
     * Check if user is logged in
     */
    function isLoggedIn() {
        return sessionStorage.exists( "user" )
    }

    /**
     * Logout user
     */
    function logout() {
        sessionStorage.delete( "user" )
        return this
    }

    /**
     * Check if user has role
     */
    function hasRole( required role ) {
        if ( !isLoggedIn() ) {
            return false
        }

        var user = getUser()
        return user.roles.contains( arguments.role )
    }

    /**
     * Check if user has permission
     */
    function hasPermission( required permission ) {
        if ( !isLoggedIn() ) {
            return false
        }

        var user = getUser()
        return user.permissions.contains( arguments.permission )
    }
}
```

## Security Rules

### Rule-Based Firewall

```boxlang
/**
 * config/ColdBox.cfc
 */
moduleSettings = {
    cbsecurity: {
        firewall: {
            enabled: true,
            defaultAction: "redirect",
            defaultRedirect: "/login"
        },

        rules: [
            // Admin section
            {
                secureList: "admin",
                match: "event",
                roles: "admin",
                action: "redirect",
                redirect: "/login"
            },

            // User profile
            {
                secureList: "users\\.profile",
                match: "event",
                roles: "user,admin",
                action: "redirect"
            },

            // API endpoints
            {
                secureList: "^api\\.",
                match: "event",
                roles: "api_user",
                action: "block",
                statusCode: 401
            },

            // Public routes (whitelist)
            {
                whitelist: "main\\.index,main\\.about,main\\.contact",
                match: "event"
            }
        ]
    }
}
```

### URL-Based Rules

```boxlang
rules: [
    // Secure URLs
    {
        secureList: "/admin",
        match: "url",
        roles: "admin",
        action: "redirect"
    },

    // Regex patterns
    {
        secureList: "^/api/.*",
        match: "url",
        roles: "api_user",
        action: "block"
    },

    // Multiple roles (OR logic)
    {
        secureList: "/reports",
        match: "url",
        roles: "admin,manager",
        action: "redirect"
    },

    // Permissions
    {
        secureList: "/admin/users",
        match: "url",
        permissions: "users.manage",
        action: "redirect"
    }
]
```

## Handler Security

### Securing Handlers

```boxlang
/**
 * Admin.cfc
 */
class extends="coldbox.system.EventHandler" secured {

    property name="userService" inject="UserService"

    // All actions require authentication
    function index( event, rc, prc ) {
        prc.users = userService.list()
    }

    // Specific role required
    function delete( event, rc, prc ) secured="admin" {
        userService.delete( rc.id )
        relocate( "admin.index" )
    }
}
```

### Action-Level Security

```boxlang
class extends="coldbox.system.EventHandler" {

    // Public action
    function index( event, rc, prc ) secured="none" {
        prc.posts = postService.list()
    }

    // Authenticated action
    function create( event, rc, prc ) secured {
        event.setView( "posts/create" )
    }

    // Role-based action
    function delete( event, rc, prc ) secured="admin,moderator" {
        postService.delete( rc.id )
        relocate( "posts.index" )
    }
}
```

## Authorization

### Role-Based Authorization

```boxlang
class extends="coldbox.system.EventHandler" {

    property name="cbsecurity" inject="@cbsecurity"

    function edit( event, rc, prc ) {
        // Check role
        if ( !cbsecurity.has( "admin" ) ) {
            cbsecurity.block( "Unauthorized" )
        }

        prc.user = userService.find( rc.id )
        event.setView( "users/edit" )
    }

    function update( event, rc, prc ) {
        // Check multiple roles (OR logic)
        if ( !cbsecurity.has( "admin,manager" ) ) {
            cbsecurity.block()
        }

        userService.update( rc.id, rc )
        relocate( "users.index" )
    }
}
```

### Permission-Based Authorization

```boxlang
class extends="coldbox.system.EventHandler" {

    property name="cbsecurity" inject="@cbsecurity"

    function delete( event, rc, prc ) {
        // Check permission
        if ( !cbsecurity.hasPermission( "users.delete" ) ) {
            cbsecurity.block( "Insufficient permissions" )
        }

        userService.delete( rc.id )
        relocate( "users.index" )
    }

    function bulkDelete( event, rc, prc ) {
        // Check multiple permissions (AND logic)
        if ( !cbsecurity.all( "users.delete,users.manage" ) ) {
            cbsecurity.block()
        }

        userService.bulkDelete( rc.ids )
    }
}
```

## Security Events

### Interceptor-Based Security

```boxlang
/**
 * interceptors/SecurityEvents.cfc
 */
class extends="coldbox.system.Interceptor" {

    property name="log" inject="logbox:logger:{this}"
    property name="mailService" inject="MailService"

    function preAuthentication( event, interceptData ) {
        log.info( "Authentication attempt: #interceptData.username#" )
    }

    function postAuthentication( event, interceptData ) {
        if ( interceptData.authenticated ) {
            log.info( "Successful login: #interceptData.user.email#" )
        } else {
            log.warn( "Failed login: #interceptData.username#" )
        }
    }

    function onInvalidAuthentication( event, interceptData ) {
        log.error( "Invalid authentication attempt" )

        // Track failed attempts
        trackFailedLogin( interceptData.username )

        // Email on repeated failures
        if ( getFailedAttempts( interceptData.username ) > 5 ) {
            mailService.sendAlert(
                subject: "Multiple failed login attempts",
                body: "User: #interceptData.username#"
            )
        }
    }

    function preAuthorization( event, interceptData ) {
        log.debug( "Authorization check: #interceptData.rule.secureList#" )
    }

    function onInvalidAuthorization( event, interceptData ) {
        log.warn( "Authorization denied: #interceptData.rule.secureList#" )

        // Log security violation
        logSecurityViolation(
            user: interceptData.user,
            resource: interceptData.rule.secureList,
            ip: event.getHTTPHeader( "REMOTE_ADDR" )
        )
    }
}
```

## Security Validators

### Custom Validators

```boxlang
/**
 * models/security/UserValidator.cfc
 */
class singleton {

    property name="securityService" inject="SecurityService"

    /**
     * Validate if user owns resource
     */
    function validateOwner( rule, controller ) {
        var user = securityService.getUser()
        var resourceID = controller.getRequestContext().getValue( "id" )

        // Load resource and check ownership
        var resource = controller.getInstance( rule.resource ).find( resourceID )

        return resource.userID == user.id
    }

    /**
     * Validate IP whitelist
     */
    function validateIP( rule, controller ) {
        var ip = controller.getRequestContext().getHTTPHeader( "REMOTE_ADDR" )

        return rule.whitelist.contains( ip )
    }

    /**
     * Validate subscription level
     */
    function validateSubscription( rule, controller ) {
        var user = securityService.getUser()

        return user.subscription.level >= rule.requiredLevel
    }
}
```

### Using Custom Validators

```boxlang
/**
 * config/ColdBox.cfc
 */
moduleSettings = {
    cbsecurity: {
        validator: "UserValidator@models.security",

        rules: [
            {
                secureList: "posts\\.edit,posts\\.update",
                match: "event",
                validator: "validateOwner",
                resource: "PostService",
                action: "redirect"
            },

            {
                secureList: "^admin",
                match: "event",
                validator: "validateIP",
                whitelist: [ "192.168.1.1", "10.0.0.1" ],
                action: "block"
            }
        ]
    }
}
```

## Security Helpers

### View Layer Security

```html
<!-- views/posts/show.bxm -->
<bx:output>
    <h1>#prc.post.title#</h1>

    <!-- Check authentication -->
    <bx:if cbsecurity().isLoggedIn()>
        <a href="/posts/#prc.post.id#/edit">Edit</a>
    </bx:if>

    <!-- Check role -->
    <bx:if cbsecurity().has( "admin" )>
        <a href="/posts/#prc.post.id#/delete" class="danger">Delete</a>
    </bx:if>

    <!-- Check permission -->
    <bx:if cbsecurity().hasPermission( "posts.moderate" )>
        <button>Moderate</button>
    </bx:if>
</bx:output>
```

### Security Context

```boxlang
class extends="coldbox.system.EventHandler" {

    property name="cbsecurity" inject="@cbsecurity"

    function dashboard( event, rc, prc ) {
        // Get authenticated user
        prc.user = cbsecurity.getUser()

        // Check authentication
        if ( cbsecurity.isLoggedIn() ) {
            prc.greeting = "Welcome, #prc.user.name#"
        }

        // Get user roles
        prc.roles = cbsecurity.getUserRoles()

        // Get user permissions
        prc.permissions = cbsecurity.getUserPermissions()

        event.setView( "main/dashboard" )
    }
}
```

## Advanced Patterns

### Multi-Tenant Security

```boxlang
/**
 * models/security/TenantSecurityService.cfc
 */
class singleton {

    property name="securityService" inject="SecurityService"
    property name="tenantService" inject="TenantService"

    function getUser() {
        return securityService.getUser()
    }

    function isLoggedIn() {
        return securityService.isLoggedIn()
    }

    function hasRole( required role ) {
        return securityService.hasRole( arguments.role )
    }

    /**
     * Check if user has access to tenant
     */
    function hasAccessToTenant( required tenantID ) {
        if ( !isLoggedIn() ) {
            return false
        }

        var user = getUser()

        // Check if user belongs to tenant
        return user.tenants.contains( arguments.tenantID )
    }

    /**
     * Get current tenant
     */
    function getCurrentTenant() {
        if ( !isLoggedIn() ) {
            return {}
        }

        var user = getUser()
        return tenantService.find( user.currentTenantID )
    }
}
```

### Resource-Based Security

```boxlang
/**
 * Secure resources based on ownership
 */
class extends="coldbox.system.EventHandler" {

    property name="cbsecurity" inject="@cbsecurity"
    property name="postService" inject="PostService"

    function edit( event, rc, prc ) {
        var post = postService.find( rc.id )

        // Check if user owns post or is admin
        if ( !canModify( post ) ) {
            cbsecurity.block( "You cannot edit this post" )
        }

        prc.post = post
        event.setView( "posts/edit" )
    }

    private function canModify( post ) {
        var user = cbsecurity.getUser()

        // Owner can modify
        if ( post.userID == user.id ) {
            return true
        }

        // Admin can modify
        if ( cbsecurity.has( "admin" ) ) {
            return true
        }

        return false
    }
}
```

### Context-Based Security

```boxlang
/**
 * Security based on context and business rules
 */
class extends="coldbox.system.EventHandler" {

    property name="cbsecurity" inject="@cbsecurity"
    property name="orderService" inject="OrderService"

    function cancel( event, rc, prc ) {
        var order = orderService.find( rc.id )

        // Check if order can be cancelled
        if ( !canCancel( order ) ) {
            cbsecurity.block( "Cannot cancel this order" )
        }

        orderService.cancel( rc.id )
        relocate( "orders.index" )
    }

    private function canCancel( order ) {
        var user = cbsecurity.getUser()

        // Must be order owner
        if ( order.userID != user.id ) {
            return false
        }

        // Order must be pending
        if ( order.status != "pending" ) {
            return false
        }

        // Cannot cancel after 24 hours
        if ( dateDiff( "h", order.createdAt, now() ) > 24 ) {
            return false
        }

        return true
    }
}
```

## Best Practices

### Design Guidelines

1. **Defense in Depth**: Multiple security layers
2. **Least Privilege**: Minimum required permissions
3. **Secure by Default**: Deny access unless explicitly allowed
4. **Fail Secure**: Block on errors
5. **Centralized Auth**: Single authentication service
6. **Audit Trail**: Log security events
7. **Input Validation**: Validate all user input
8. **Strong Passwords**: Enforce password policies
9. **Session Security**: Secure session management
10. **Regular Updates**: Keep security modules updated

### Common Patterns

```boxlang
// ✅ Good: Secure by default
class extends="coldbox.system.EventHandler" secured {
    // All actions require authentication
}

// ✅ Good: Explicit public access
function index( event, rc, prc ) secured="none" {
    // Public action
}

// ✅ Good: Role-based security
if ( !cbsecurity.has( "admin" ) ) {
    cbsecurity.block()
}

// ✅ Good: Resource ownership
if ( resource.userID != user.id && !cbsecurity.has( "admin" ) ) {
    cbsecurity.block()
}
```

## Common Pitfalls

### Pitfalls to Avoid

1. **No Security**: Forgetting to secure handlers
2. **Client-Side Only**: Security only in views
3. **Weak Rules**: Overly permissive rules
4. **No Validation**: Trusting user input
5. **Insecure Sessions**: Weak session management
6. **No Audit Log**: Not tracking security events
7. **Hardcoded Credentials**: Credentials in code
8. **No Rate Limiting**: Allowing brute force
9. **Missing HTTPS**: Not enforcing SSL
10. **Stale Sessions**: Sessions never expire

### Anti-Patterns

```boxlang
// ❌ Bad: No security
class extends="coldbox.system.EventHandler" {
    function delete( event, rc, prc ) {
        // Anyone can delete!
        service.delete( rc.id )
    }
}

// ✅ Good: Secured
class extends="coldbox.system.EventHandler" {
    function delete( event, rc, prc ) secured="admin" {
        service.delete( rc.id )
    }
}

// ❌ Bad: View-only security
<bx:if user.isAdmin>
    <button>Delete</button>  <!-- Hidden but endpoint exposed -->
</bx:if>

// ✅ Good: Handler security
function delete( event, rc, prc ) secured="admin" {
    // Backend enforces security
}

// ❌ Bad: Trusting client data
function updateRole( event, rc, prc ) {
    user.role = rc.role  // User can set own role!
}

// ✅ Good: Validating changes
function updateRole( event, rc, prc ) secured="admin" {
    if ( !isValidRole( rc.role ) ) {
        throw( "Invalid role" )
    }
    user.role = rc.role
}
```

## Related Skills

- [Authentication Patterns](authentication.md) - CBAuth patterns
- [Authorization Patterns](authorization.md) - Security rules
- [JWT Development](jwt-development.md) - JWT authentication
- [API Authentication](api-authentication.md) - API security

## References

- [CBSecurity Documentation](https://coldbox-security.ortusbooks.com/)
- [Security Rules](https://coldbox-security.ortusbooks.com/usage/security-rules)
- [Authentication Service](https://coldbox-security.ortusbooks.com/usage/authentication-services)
