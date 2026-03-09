---
name: Authorization Patterns
description: Complete guide to security rules, role-based access control, permission systems, and authorization patterns in ColdBox
category: security
priority: high
triggers:
  - authorization
  - security rules
  - roles
  - permissions
  - access control
  - rbac
---

# Authorization Patterns

## Overview

Authorization determines what authenticated users can access. CBSecurity provides flexible authorization through security rules, roles, permissions, and custom validators. Proper authorization ensures users only access permitted resources.

## Core Concepts

### Authorization Components

- **Security Rules**: Route-based access control
- **Roles**: User groups (admin, user, guest)
- **Permissions**: Granular capabilities (users.create, posts.delete)
- **Validators**: Custom authorization logic
- **Context**: Resource and operation-based access

## Security Rules

### Event-Based Rules

```boxlang
/**
 * config/ColdBox.cfc
 */
moduleSettings = {
    cbsecurity: {
        rules: [
            // Exact match
            {
                secureList: "admin.index",
                match: "event",
                roles: "admin",
                action: "redirect"
            },

            // Multiple events
            {
                secureList: "users.edit,users.delete",
                match: "event",
                roles: "admin",
                action: "block"
            },

            // Regex pattern
            {
                secureList: "^admin\\.",
                match: "event",
                roles: "admin,superadmin",
                action: "redirect",
                redirect: "/login"
            },

            // Public whitelist
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
    // URL path
    {
        secureList: "/admin",
        match: "url",
        roles: "admin",
        action: "redirect"
    },

    // URL pattern
    {
        secureList: "^/api/.*",
        match: "url",
        roles: "api_user",
        action: "block",
        statusCode: 401
    },

    // Multiple paths
    {
        secureList: "/reports,/analytics",
        match: "url",
        roles: "admin,manager",
        action: "redirect"
    }
]
```

## Role-Based Authorization

### Checking Roles

```boxlang
class extends="coldbox.system.EventHandler" {

    property name="cbsecurity" inject="@cbsecurity"

    function edit( event, rc, prc ) {
        // Single role
        if ( !cbsecurity.has( "admin" ) ) {
            cbsecurity.block( "Admin access required" )
        }

        // Multiple roles (OR logic)
        if ( !cbsecurity.has( "admin,manager" ) ) {
            cbsecurity.block( "Insufficient privileges" )
        }

        // Multiple roles (AND logic)
        if ( !cbsecurity.all( "admin,moderator" ) ) {
            cbsecurity.block( "Need admin AND moderator roles" )
        }

        prc.user = userService.find( rc.id )
        event.setView( "users/edit" )
    }
}
```

### Handler-Level Roles

```boxlang
/**
 * Admin handlers - requires admin role
 */
class extends="coldbox.system.EventHandler" secured="admin" {

    function index( event, rc, prc ) {
        // Admin role enforced
    }

    // Override for specific action
    function reports( event, rc, prc ) secured="admin,manager" {
        // Admin OR manager
    }
}
```

## Permission-Based Authorization

### Permission Rules

```boxlang
/**
 * config/ColdBox.cfc
 */
rules: [
    // Single permission
    {
        secureList: "users.create",
        match: "event",
        permissions: "users.manage",
        action: "redirect"
    },

    // Multiple permissions (AND)
    {
        secureList: "reports.financial",
        match: "event",
        permissions: "reports.view,reports.financial",
        action: "block"
    },

    // Permissions with roles
    {
        secureList: "admin.settings",
        match: "event",
        roles: "admin",
        permissions: "settings.edit",
        action: "redirect"
    }
]
```

### Checking Permissions

```boxlang
class extends="coldbox.system.EventHandler" {

    property name="cbsecurity" inject="@cbsecurity"

    function delete( event, rc, prc ) {
        // Single permission
        if ( !cbsecurity.hasPermission( "users.delete" ) ) {
            cbsecurity.block( "Permission denied" )
        }

        userService.delete( rc.id )
        relocate( "users.index" )
    }

    function bulkActions( event, rc, prc ) {
        // Multiple permissions (AND)
        if ( !cbsecurity.all( "users.delete,users.bulk" ) ) {
            cbsecurity.block()
        }

        userService.bulkDelete( rc.ids )
    }
}
```

## Custom Validators

### Resource Ownership Validator

```boxlang
/**
 * models/security/OwnershipValidator.cfc
 */
class singleton {

    property name="authService" inject="AuthenticationService@cbauth"

    /**
     * Validate if user owns resource
     */
    function validateOwnership( rule, controller ) {
        var user = authService.getUser()
        var resourceID = controller.getRequestContext().getValue( "id" )

        // Get service from rule
        var service = controller.getInstance( rule.service )

        // Load resource
        var resource = service.find( resourceID )

        // Check ownership
        return resource.userID == user.getId()
    }

    /**
     * Validate if user is owner or admin
     */
    function validateOwnerOrAdmin( rule, controller ) {
        var user = authService.getUser()

        // Admin bypass
        if ( user.hasRole( "admin" ) ) {
            return true
        }

        // Check ownership
        return validateOwnership( rule, controller )
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
        validator: "OwnershipValidator@models.security",

        rules: [
            {
                secureList: "posts\\.edit,posts\\.update,posts\\.delete",
                match: "event",
                validator: "validateOwnerOrAdmin",
                service: "PostService",
                action: "redirect"
            }
        ]
    }
}
```

## Context-Based Authorization

### Business Rules Authorization

```boxlang
/**
 * Order cancellation with business rules
 */
class extends="coldbox.system.EventHandler" {

    property name="cbsecurity" inject="@cbsecurity"
    property name="orderService" inject="OrderService"

    function cancel( event, rc, prc ) {
        var order = orderService.find( rc.id )
        var user = cbsecurity.getUser()

        // Authorization rules
        if ( !canCancelOrder( order, user ) ) {
            cbsecurity.block( "Cannot cancel this order" )
        }

        orderService.cancel( rc.id )
        relocate( "orders.index" )
    }

    private function canCancelOrder( order, user ) {
        // Must be order owner
        if ( order.userID != user.getId() ) {
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

### Time-Based Authorization

```boxlang
/**
 * Time-restricted access
 */
class extends="coldbox.system.EventHandler" {

    property name="cbsecurity" inject="@cbsecurity"

    function maintenance( event, rc, prc ) {
        var user = cbsecurity.getUser()

        // Allow during business hours or for admins
        if ( !isBusinessHours() && !user.hasRole( "admin" ) ) {
            cbsecurity.block( "Access restricted to business hours" )
        }

        prc.data = maintenanceService.getData()
        event.setView( "maintenance/index" )
    }

    private function isBusinessHours() {
        var hour = hour( now() )
        var day = dayOfWeek( now() )

        // Monday-Friday, 9am-5pm
        return day >= 2 && day <= 6 && hour >= 9 && hour < 17
    }
}
```

## Hierarchical Permissions

### Permission Hierarchy

```boxlang
/**
 * models/security/PermissionService.cfc
 */
class singleton {

    /**
     * Check if user has permission (with hierarchy)
     */
    function hasPermission( required user, required permission ) {
        // Direct permission
        if ( user.permissions.contains( arguments.permission ) ) {
            return true
        }

        // Check parent permissions
        var parentPermission = getParentPermission( arguments.permission )

        while ( !isNull( parentPermission ) ) {
            if ( user.permissions.contains( parentPermission ) ) {
                return true
            }

            parentPermission = getParentPermission( parentPermission )
        }

        return false
    }

    /**
     * Get parent permission
     * Example: users.edit.profile -> users.edit -> users
     */
    private function getParentPermission( permission ) {
        var parts = permission.listToArray( "." )

        if ( parts.len() <= 1 ) {
            return
        }

        parts.deleteAt( parts.len() )
        return parts.toList( "." )
    }
}
```

### Using Permission Hierarchy

```boxlang
class extends="coldbox.system.EventHandler" {

    property name="permissionService" inject="PermissionService"
    property name="cbsecurity" inject="@cbsecurity"

    function edit( event, rc, prc ) {
        var user = cbsecurity.getUser()

        // Check with hierarchy
        // Having "users" gives access to "users.edit"
        if ( !permissionService.hasPermission( user, "users.edit" ) ) {
            cbsecurity.block()
        }

        prc.user = userService.find( rc.id )
        event.setView( "users/edit" )
    }
}
```

## View Layer Authorization

### Conditional Display

```html
<!-- views/users/show.cfm -->
<h1>#prc.user.name#</h1>

<!-- Check authentication -->
<cfif cbsecurity().isLoggedIn()>
    <a href="/users/#prc.user.id#/edit">Edit</a>
</cfif>

<!-- Check role -->
<cfif cbsecurity().has( "admin" )>
    <a href="/users/#prc.user.id#/delete" class="danger">Delete</a>
</cfif>

<!-- Check permission -->
<cfif cbsecurity().hasPermission( "users.impersonate" )>
    <a href="/admin/impersonate/#prc.user.id#">Impersonate</a>
</cfif>

<!-- Check multiple conditions -->
<cfif cbsecurity().isLoggedIn() AND cbsecurity().has( "admin,moderator" )>
    <button>Moderate</button>
</cfif>
```

### Helper Methods

```boxlang
/**
 * BaseHandler.cfc
 */
class extends="coldbox.system.EventHandler" {

    property name="cbsecurity" inject="@cbsecurity"

    function preHandler( event, rc, prc ) {
        // Make helpers available to views
        prc.auth = cbsecurity
        prc.can = (permission) => cbsecurity.hasPermission( permission )
        prc.hasRole = (role) => cbsecurity.has( role )
    }
}
```

```html
<!-- views/dashboard.cfm -->
<cfif prc.can( "reports.view" )>
    <a href="/reports">View Reports</a>
</cfif>

<cfif prc.hasRole( "admin" )>
    <a href="/admin">Admin Panel</a>
</cfif>
```

## Advanced Patterns

### Multi-Tenant Authorization

```boxlang
/**
 * Tenant-specific authorization
 */
class extends="coldbox.system.EventHandler" {

    property name="cbsecurity" inject="@cbsecurity"
    property name="tenantService" inject="TenantService"

    function edit( event, rc, prc ) {
        var user = cbsecurity.getUser()
        var resource = resourceService.find( rc.id )

        // Check tenant access
        if ( !userBelongsToTenant( user, resource.tenantID ) ) {
            cbsecurity.block( "Access denied" )
        }

        prc.resource = resource
        event.setView( "resources/edit" )
    }

    private function userBelongsToTenant( user, tenantID ) {
        return user.tenants.contains( tenantID )
    }
}
```

### Delegation

```boxlang
/**
 * Delegated permissions
 */
class extends="coldbox.system.EventHandler" {

    property name="delegationService" inject="DelegationService"
    property name="cbsecurity" inject="@cbsecurity"

    function approve( event, rc, prc ) {
        var user = cbsecurity.getUser()

        // Check direct permission or delegation
        if ( !canApprove( user, rc.documentID ) ) {
            cbsecurity.block( "Cannot approve this document" )
        }

        documentService.approve( rc.documentID )
        relocate( "documents.index" )
    }

    private function canApprove( user, documentID ) {
        // Direct permission
        if ( cbsecurity.hasPermission( "documents.approve" ) ) {
            return true
        }

        // Delegated permission
        return delegationService.hasDelegatedPermission(
            user.getId(),
            "documents.approve",
            documentID
        )
    }
}
```

### Feature Flags

```boxlang
/**
 * Feature-based authorization
 */
class extends="coldbox.system.EventHandler" {

    property name="featureService" inject="FeatureService"
    property name="cbsecurity" inject="@cbsecurity"

    function betaFeature( event, rc, prc ) {
        var user = cbsecurity.getUser()

        // Check if feature enabled for user
        if ( !featureService.isEnabled( "beta_dashboard", user ) ) {
            cbsecurity.block( "Feature not available" )
        }

        prc.data = betaService.getData()
        event.setView( "beta/dashboard" )
    }
}
```

## Best Practices

### Design Guidelines

1. **Principle of Least Privilege**: Minimum required access
2. **Deny by Default**: Explicitly allow access
3. **Separation of Duties**: No single user has complete control
4. **Defense in Depth**: Multiple authorization layers
5. **Explicit Authorization**: Clear permission checks
6. **Consistent Enforcement**: Same rules everywhere
7. **Audit Trail**: Log authorization decisions
8. **Regular Review**: Audit permissions regularly
9. **Role Hierarchy**: Organize roles logically
10. **Permission Granularity**: Right level of permissions

### Common Patterns

```boxlang
// ✅ Good: Explicit authorization
if ( !cbsecurity.hasPermission( "users.delete" ) ) {
    cbsecurity.block()
}

// ✅ Good: Resource ownership
if ( resource.userID != user.getId() && !cbsecurity.has( "admin" ) ) {
    cbsecurity.block()
}

// ✅ Good: Business rules
if ( !canPerformAction( user, resource ) ) {
    cbsecurity.block()
}
```

## Common Pitfalls

### Pitfalls to Avoid

1. **Client-Side Only**: Authorization only in views
2. **No Default Deny**: Open by default
3. **Inconsistent Rules**: Different rules in different places
4. **Overly Broad Roles**: God admin role
5. **No Ownership**: Missing resource ownership checks
6. **Implicit Trust**: Trusting client data
7. **No Audit**: Not logging authorization
8. **Stale Permissions**: Not updating permissions
9. **Hard-Coded Roles**: Roles in code
10. **No Testing**: Not testing authorization

### Anti-Patterns

```boxlang
// ❌ Bad: View-only authorization
<cfif user.isAdmin>
    <button>Delete</button>  <!-- Backend not protected -->
</cfif>

// ✅ Good: Handler authorization
function delete( event, rc, prc ) secured="admin" {
    service.delete( rc.id )
}

// ❌ Bad: Trusting client data
function setRole( event, rc, prc ) {
    user.role = rc.role  <!-- User sets own role! -->
}

// ✅ Good: Validate authorization
function setRole( event, rc, prc ) secured="admin" {
    if ( !isValidRole( rc.role ) ) {
        throw( "Invalid role" )
    }
    user.role = rc.role
}

// ❌ Bad: No resource ownership
function delete( event, rc, prc ) {
    service.delete( rc.id )  <!-- Anyone can delete -->
}

// ✅ Good: Check ownership
function delete( event, rc, prc ) {
    var resource = service.find( rc.id )

    if ( resource.userID != user.getId() && !cbsecurity.has( "admin" ) ) {
        cbsecurity.block()
    }

    service.delete( rc.id )
}
```

## Related Skills

- [CBSecurity Implementation](security-implementation.md) - Security framework
- [Authentication Patterns](authentication.md) - User authentication
- [RBAC Patterns](rbac-patterns.md) - Role-based access control
- [API Authentication](api-authentication.md) - API authorization

## References

- [CBSecurity Documentation](https://coldbox-security.ortusbooks.com/)
- [Authorization Rules](https://coldbox-security.ortusbooks.com/usage/security-rules)
- [OWASP Authorization](https://cheatsheetseries.owasp.org/cheatsheets/Authorization_Cheat_Sheet.html)
