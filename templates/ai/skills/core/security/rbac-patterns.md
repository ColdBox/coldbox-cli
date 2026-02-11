---
name: RBAC Patterns
description: Complete guide to Role-Based Access Control (RBAC) with role hierarchy, permission management, dynamic roles, and group-based access control
category: security
priority: high
triggers:
  - rbac
  - role based access control
  - role management
  - permission management
  - role hierarchy
  - group permissions
---

# RBAC Patterns

## Overview

Role-Based Access Control (RBAC) assigns system access based on user roles. It simplifies permission management by grouping permissions into roles and assigning roles to users.

## Core Concepts

### RBAC Components

- **Roles**: Named collections of permissions
- **Permissions**: Specific actions on resources
- **Users**: Assigned one or more roles
- **Groups**: Collections of users
- **Hierarchy**: Parent-child role relationships

### RBAC Models

- **Flat RBAC**: Simple role assignment
- **Hierarchical RBAC**: Role inheritance
- **Constrained RBAC**: Role constraints (mutual exclusion)
- **Symmetric RBAC**: Permission inheritance

## Role Management

### Role Service

```boxlang
/**
 * models/RoleService.cfc
 */
class singleton {

    /**
     * Create role
     */
    function create(
        required name,
        description = "",
        permissions = [],
        parentID = ""
    ) {
        var roleID = createUUID()

        queryExecute(
            "INSERT INTO roles (id, name, description, parent_id, created_at)
             VALUES (:id, :name, :desc, :parent, :now)",
            {
                id: roleID,
                name: arguments.name,
                desc: arguments.description,
                parent: arguments.parentID,
                now: now()
            }
        )

        // Assign permissions
        if ( permissions.len() > 0 ) {
            assignPermissions( roleID, permissions )
        }

        return roleID
    }

    /**
     * Get role by name
     */
    function findByName( required name ) {
        var result = queryExecute(
            "SELECT * FROM roles WHERE name = :name",
            { name: arguments.name }
        )

        if ( result.recordCount == 0 ) {
            return
        }

        return {
            id: result.id,
            name: result.name,
            description: result.description,
            parentID: result.parent_id,
            permissions: getPermissions( result.id )
        }
    }

    /**
     * Assign permissions to role
     */
    function assignPermissions( required roleID, required permissions ) {
        // Clear existing
        queryExecute(
            "DELETE FROM role_permissions WHERE role_id = :roleID",
            { roleID: arguments.roleID }
        )

        // Insert new permissions
        permissions.each( ( permission ) => {
            queryExecute(
                "INSERT INTO role_permissions (role_id, permission)
                 VALUES (:roleID, :permission)",
                {
                    roleID: roleID,
                    permission: permission
                }
            )
        } )
    }

    /**
     * Get permissions for role
     */
    function getPermissions( required roleID ) {
        var result = queryExecute(
            "SELECT permission FROM role_permissions WHERE role_id = :roleID",
            { roleID: arguments.roleID }
        )

        var permissions = []

        for ( var row in result ) {
            permissions.append( row.permission )
        }

        return permissions
    }

    /**
     * Delete role
     */
    function delete( required id ) {
        // Check if role is assigned to users
        var userCount = queryExecute(
            "SELECT COUNT(*) as count FROM user_roles WHERE role_id = :id",
            { id: arguments.id }
        )

        if ( userCount.count > 0 ) {
            throw( "Cannot delete role assigned to users" )
        }

        // Delete permissions
        queryExecute(
            "DELETE FROM role_permissions WHERE role_id = :id",
            { id: arguments.id }
        )

        // Delete role
        queryExecute(
            "DELETE FROM roles WHERE id = :id",
            { id: arguments.id }
        )
    }
}
```

## Role Assignment

### User Role Management

```boxlang
/**
 * models/UserService.cfc
 */
class singleton {

    property name="roleService" inject="RoleService"

    /**
     * Assign role to user
     */
    function assignRole( required userID, required roleName ) {
        var role = roleService.findByName( roleName )

        if ( isNull( role ) ) {
            throw( "Role not found: #roleName#" )
        }

        // Check if already assigned
        var existing = queryExecute(
            "SELECT id FROM user_roles
             WHERE user_id = :userID AND role_id = :roleID",
            {
                userID: arguments.userID,
                roleID: role.id
            }
        )

        if ( existing.recordCount > 0 ) {
            return
        }

        // Assign role
        queryExecute(
            "INSERT INTO user_roles (user_id, role_id, assigned_at)
             VALUES (:userID, :roleID, :now)",
            {
                userID: arguments.userID,
                roleID: role.id,
                now: now()
            }
        )
    }

    /**
     * Remove role from user
     */
    function removeRole( required userID, required roleName ) {
        var role = roleService.findByName( roleName )

        if ( isNull( role ) ) {
            return
        }

        queryExecute(
            "DELETE FROM user_roles
             WHERE user_id = :userID AND role_id = :roleID",
            {
                userID: arguments.userID,
                roleID: role.id
            }
        )
    }

    /**
     * Get user roles
     */
    function getRoles( required userID ) {
        var result = queryExecute(
            "SELECT r.* FROM roles r
             INNER JOIN user_roles ur ON r.id = ur.role_id
             WHERE ur.user_id = :userID",
            { userID: arguments.userID }
        )

        var roles = []

        for ( var row in result ) {
            roles.append( {
                id: row.id,
                name: row.name,
                description: row.description
            } )
        }

        return roles
    }

    /**
     * Check if user has role
     */
    function hasRole( required userID, required roleName ) {
        var roles = getRoles( userID )

        return roles.some( ( r ) => r.name == roleName )
    }
}
```

## Permission Checking

### Permission Service

```boxlang
/**
 * models/PermissionService.cfc
 */
class singleton {

    property name="cache" inject="cachebox:default"

    /**
     * Get all permissions for user
     */
    function getUserPermissions( required userID ) {
        // Check cache
        var cacheKey = "user_permissions_#arguments.userID#"

        if ( cache.lookup( cacheKey ) ) {
            return cache.get( cacheKey )
        }

        // Get from database
        var result = queryExecute(
            "SELECT DISTINCT rp.permission
             FROM role_permissions rp
             INNER JOIN user_roles ur ON rp.role_id = ur.role_id
             WHERE ur.user_id = :userID",
            { userID: arguments.userID }
        )

        var permissions = []

        for ( var row in result ) {
            permissions.append( row.permission )
        }

        // Cache for 10 minutes
        cache.set( cacheKey, permissions, 10 )

        return permissions
    }

    /**
     * Check if user has permission
     */
    function hasPermission( required userID, required permission ) {
        var permissions = getUserPermissions( userID )

        return permissions.contains( permission )
    }

    /**
     * Check if user has any of these permissions
     */
    function hasAnyPermission( required userID, required permissions ) {
        var userPerms = getUserPermissions( userID )

        return permissions.some( ( p ) => userPerms.contains( p ) )
    }

    /**
     * Check if user has all these permissions
     */
    function hasAllPermissions( required userID, required permissions ) {
        var userPerms = getUserPermissions( userID )

        return permissions.every( ( p ) => userPerms.contains( p ) )
    }

    /**
     * Clear permission cache
     */
    function clearCache( required userID ) {
        cache.clear( "user_permissions_#arguments.userID#" )
    }
}
```

## Role Hierarchy

### Hierarchical Roles

```boxlang
/**
 * Role inheritance
 */
class singleton {

    /**
     * Get all permissions (including inherited)
     */
    function getAllPermissions( required roleID ) {
        var permissions = getPermissions( roleID )

        // Get parent permissions recursively
        var role = find( roleID )

        if ( !isNull( role ) && role.parentID != "" ) {
            var parentPerms = getAllPermissions( role.parentID )
            permissions.append( parentPerms, true )
        }

        return permissions.unique()
    }

    /**
     * Check permission with hierarchy
     */
    function hasPermission( required userID, required permission ) {
        var roles = userService.getRoles( userID )

        // Check each role and its parents
        for ( var role in roles ) {
            var permissions = getAllPermissions( role.id )

            if ( permissions.contains( permission ) ) {
                return true
            }
        }

        return false
    }
}

/**
 * Example hierarchy:
 *
 * SuperAdmin
 *   └─ Admin
 *       ├─ Manager
 *       │   └─ User
 *       └─ Support
 */
function createRoleHierarchy() {
    // Create roles
    var superAdminID = roleService.create(
        name: "SuperAdmin",
        description: "Full system access",
        permissions: [ "*" ]
    )

    var adminID = roleService.create(
        name: "Admin",
        description: "Administrative access",
        parentID: superAdminID,
        permissions: [ "users:*", "roles:*" ]
    )

    var managerID = roleService.create(
        name: "Manager",
        description: "Management access",
        parentID: adminID,
        permissions: [ "reports:read" ]
    )

    var userID = roleService.create(
        name: "User",
        description: "Basic user access",
        parentID: managerID,
        permissions: [ "profile:read", "profile:update" ]
    )
}
```

## Dynamic Roles

### Context-Based Roles

```boxlang
/**
 * Dynamic role assignment
 */
class singleton {

    /**
     * Get user's current roles in context
     */
    function getContextualRoles( required userID, context = {} ) {
        var baseRoles = userService.getRoles( userID )
        var contextRoles = []

        // Check project context
        if ( context.keyExists( "projectID" ) ) {
            var projectRoles = getProjectRoles( userID, context.projectID )
            contextRoles.append( projectRoles, true )
        }

        // Check organization context
        if ( context.keyExists( "orgID" ) ) {
            var orgRoles = getOrganizationRoles( userID, context.orgID )
            contextRoles.append( orgRoles, true )
        }

        return baseRoles.append( contextRoles, true )
    }

    /**
     * Project-specific roles
     */
    function getProjectRoles( required userID, required projectID ) {
        var result = queryExecute(
            "SELECT r.* FROM roles r
             INNER JOIN project_roles pr ON r.id = pr.role_id
             WHERE pr.user_id = :userID AND pr.project_id = :projectID",
            {
                userID: arguments.userID,
                projectID: arguments.projectID
            }
        )

        var roles = []

        for ( var row in result ) {
            roles.append( {
                id: row.id,
                name: row.name,
                scope: "project"
            } )
        }

        return roles
    }
}
```

## Group-Based Access

### Group Management

```boxlang
/**
 * models/GroupService.cfc
 */
class singleton {

    /**
     * Create group
     */
    function create( required name, description = "" ) {
        var groupID = createUUID()

        queryExecute(
            "INSERT INTO groups (id, name, description, created_at)
             VALUES (:id, :name, :desc, :now)",
            {
                id: groupID,
                name: arguments.name,
                desc: arguments.description,
                now: now()
            }
        )

        return groupID
    }

    /**
     * Add user to group
     */
    function addUser( required groupID, required userID ) {
        queryExecute(
            "INSERT INTO group_members (group_id, user_id, joined_at)
             VALUES (:groupID, :userID, :now)",
            {
                groupID: arguments.groupID,
                userID: arguments.userID,
                now: now()
            }
        )
    }

    /**
     * Assign role to group
     */
    function assignRole( required groupID, required roleID ) {
        queryExecute(
            "INSERT INTO group_roles (group_id, role_id)
             VALUES (:groupID, :roleID)",
            {
                groupID: arguments.groupID,
                roleID: arguments.roleID
            }
        )
    }

    /**
     * Get user's groups
     */
    function getUserGroups( required userID ) {
        var result = queryExecute(
            "SELECT g.* FROM groups g
             INNER JOIN group_members gm ON g.id = gm.group_id
             WHERE gm.user_id = :userID",
            { userID: arguments.userID }
        )

        var groups = []

        for ( var row in result ) {
            groups.append( {
                id: row.id,
                name: row.name
            } )
        }

        return groups
    }

    /**
     * Get roles from user's groups
     */
    function getGroupRoles( required userID ) {
        var result = queryExecute(
            "SELECT DISTINCT r.* FROM roles r
             INNER JOIN group_roles gr ON r.id = gr.role_id
             INNER JOIN group_members gm ON gr.group_id = gm.group_id
             WHERE gm.user_id = :userID",
            { userID: arguments.userID }
        )

        var roles = []

        for ( var row in result ) {
            roles.append( {
                id: row.id,
                name: row.name
            } )
        }

        return roles
    }
}
```

## Handler Security

### RBAC in Handlers

```boxlang
/**
 * handlers/admin/Users.cfc
 */
class {

    property name="permissionService" inject="PermissionService"

    /**
     * Require permission
     */
    function preHandler( event, rc, prc ) {
        if ( !permissionService.hasPermission(
            auth().user().id,
            "users:manage"
        ) ) {
            relocate( "error.unauthorized" )
        }
    }

    /**
     * List users
     * Requires: users:read
     */
    function index( event, rc, prc ) {
        if ( !permissionService.hasPermission(
            auth().user().id,
            "users:read"
        ) ) {
            flash.put( "error", "Insufficient permissions" )
            relocate( "dashboard" )
        }

        prc.users = userService.list()
    }

    /**
     * Delete user
     * Requires: users:delete
     */
    function delete( event, rc, prc ) {
        if ( !permissionService.hasPermission(
            auth().user().id,
            "users:delete"
        ) ) {
            return event.renderData(
                type: "json",
                data: {
                    success: false,
                    message: "Insufficient permissions"
                },
                statusCode: 403
            )
        }

        userService.delete( rc.id )

        return event.renderData(
            type: "json",
            data: {
                success: true
            }
        )
    }
}
```

## Advanced Patterns

### Temporary Role Elevation

```boxlang
/**
 * Grant temporary elevated access
 */
class singleton {

    property name="cache" inject="cachebox:default"

    /**
     * Grant temporary role
     */
    function grantTemporary(
        required userID,
        required roleName,
        durationMinutes = 30
    ) {
        var cacheKey = "temp_role_#userID#_#roleName#"

        cache.set(
            cacheKey,
            {
                roleName: roleName,
                grantedAt: now(),
                expiresAt: dateAdd( "n", durationMinutes, now() )
            },
            durationMinutes
        )
    }

    /**
     * Check temp role
     */
    function hasTemporaryRole( required userID, required roleName ) {
        var cacheKey = "temp_role_#userID#_#roleName#"

        return cache.lookup( cacheKey )
    }

    /**
     * Get all roles (including temporary)
     */
    function getAllRoles( required userID ) {
        var roles = userService.getRoles( userID )

        // Add temporary roles
        var tempRoles = getTemporaryRoles( userID )

        return roles.append( tempRoles, true )
    }
}
```

### Resource-Specific Permissions

```boxlang
/**
 * Fine-grained resource permissions
 */
class singleton {

    /**
     * Grant permission on specific resource
     */
    function grantResourcePermission(
        required userID,
        required resourceType,
        required resourceID,
        required permission
    ) {
        queryExecute(
            "INSERT INTO resource_permissions
             (user_id, resource_type, resource_id, permission, granted_at)
             VALUES (:userID, :type, :resourceID, :permission, :now)",
            {
                userID: arguments.userID,
                type: arguments.resourceType,
                resourceID: arguments.resourceID,
                permission: arguments.permission,
                now: now()
            }
        )
    }

    /**
     * Check resource permission
     */
    function hasResourcePermission(
        required userID,
        required resourceType,
        required resourceID,
        required permission
    ) {
        var result = queryExecute(
            "SELECT id FROM resource_permissions
             WHERE user_id = :userID
             AND resource_type = :type
             AND resource_id = :resourceID
             AND permission = :permission",
            {
                userID: arguments.userID,
                type: arguments.resourceType,
                resourceID: arguments.resourceID,
                permission: arguments.permission
            }
        )

        return result.recordCount > 0
    }
}

/**
 * Usage in handler
 */
function edit( event, rc, prc ) {
    if ( !permissionService.hasResourcePermission(
        auth().user().id,
        "project",
        rc.projectID,
        "edit"
    ) ) {
        relocate( "error.unauthorized" )
    }

    prc.project = projectService.find( rc.projectID )
}
```

## Best Practices

### Design Guidelines

1. **Minimal Roles**: Few, well-defined roles
2. **Least Privilege**: Minimum required permissions
3. **Role Separation**: No overlapping responsibilities
4. **Clear Naming**: Descriptive role names
5. **Permission Caching**: Cache permission checks
6. **Audit Trail**: Log role changes
7. **Regular Review**: Audit role assignments
8. **Default Deny**: Deny by default
9. **Hierarchical**: Use role inheritance
10. **Testable**: Unit test permissions

### Common Patterns

```boxlang
// ✅ Good: Check permission
if ( permissionService.hasPermission( userID, "users:delete" ) ) {
    userService.delete( id )
}

// ✅ Good: Role hierarchy
var adminID = roleService.create(
    name: "Admin",
    parentID: superAdminID
)

// ✅ Good: Cache permissions
var permissions = cache.getOrSet(
    "user_perms_#userID#",
    () => permissionService.getUserPermissions( userID ),
    10
)

// ✅ Good: Clear cache on change
function assignRole( userID, roleID ) {
    // Assign role
    cache.clear( "user_perms_#userID#" )
}
```

## Common Pitfalls

### Pitfalls to Avoid

1. **Too Many Roles**: Role explosion
2. **Too Granular**: Micro-permissions
3. **Too Broad**: God roles with all permissions
4. **No Hierarchy**: Duplicate permissions
5. **No Caching**: Slow permission checks
6. **Direct Permissions**: Bypassing roles
7. **No Audit**: Not tracking changes
8. **Static Only**: No dynamic roles
9. **No Cleanup**: Orphaned role assignments
10. **Hardcoded**: Hardcoded permission checks

### Anti-Patterns

```boxlang
// ❌ Bad: Hardcoded role check
if ( user.role == "Admin" ) {
    // Allow access
}

// ✅ Good: Permission check
if ( permissionService.hasPermission( user.id, "admin:access" ) ) {
    // Allow access
}

// ❌ Bad: Too granular
"users:view:firstname"
"users:view:lastname"
"users:view:email"

// ✅ Good: Reasonable granularity
"users:read"
"users:write"

// ❌ Bad: No caching
function hasPermission( userID, permission ) {
    // Query database every time
    var result = queryExecute( "SELECT..." )
}

// ✅ Good: Caching
function hasPermission( userID, permission ) {
    var permissions = cache.getOrSet(
        "user_perms_#userID#",
        () => fetchPermissions( userID )
    )
    return permissions.contains( permission )
}
```

## Related Skills

- [Security Implementation](security-implementation.md) - CBSecurity framework
- [Authorization Patterns](authorization.md) - Authorization rules
- [Authentication](authentication.md) - User authentication

## References

- [RBAC Wikipedia](https://en.wikipedia.org/wiki/Role-based_access_control)
- [NIST RBAC](https://csrc.nist.gov/projects/role-based-access-control)
- [RBAC Best Practices](https://www.imperva.com/learn/data-security/role-based-access-control-rbac/)
