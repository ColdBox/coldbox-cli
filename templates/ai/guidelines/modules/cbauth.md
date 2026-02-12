---
title: CBAuth Authentication Module Guidelines
description: Simple authentication module for user login, session management, and identity verification
---

# CBAuth Authentication Module Guidelines

## Overview

CBAuth is a lightweight authentication module for ColdBox applications. It provides session management, user authentication, and integrates seamlessly with CBSecurity for authorization.

## Installation

```bash
box install cbauth
```

## Configuration

In `config/ColdBox.cfc`:

```boxlang
moduleSettings = {
    cbauth = {
        // User service component (required)
        userServiceClass = "UserService",
        
        // Storage settings
        sessionStorage = "SessionStorage@cbstorages",
        requestStorage = "RequestStorage@cbstorages"
    }
}
```

## User Service Interface

Implement `IUserService` interface:

```boxlang
component singleton {
    property name="userDAO" inject;
    property name="bcrypt" inject="@bcrypt";
    
    /**
     * Verify if the incoming username/password are valid credentials
     */
    function isValidCredentials( required string username, required string password ) {
        var user = userDAO.findByUsername( arguments.username )
        
        if ( isNull( user ) ) {
            return false
        }
        
        return bcrypt.checkPassword( arguments.password, user.getPassword() )
    }
    
    /**
     * Retrieve a user by username
     */
    function retrieveUserByUsername( required string username ) {
        var user = userDAO.findByUsername( arguments.username )
        
        if ( isNull( user ) ) {
            throw( type="UserNotFoundException", message="User not found" )
        }
        
        return user
    }
    
    /**
     * Retrieve a user by unique identifier
     */
    function retrieveUserById( required id ) {
        var user = userDAO.find( arguments.id )
        
        if ( isNull( user ) ) {
            throw( type="UserNotFoundException", message="User not found" )
        }
        
        return user
    }
}
```

## User Object Interface

Implement `IAuthUser` interface:

```boxlang
component accessors="true" {
    property name="id";
    property name="username";
    property name="email";
    property name="password";
    property name="roles" type="array";
    property name="permissions" type="array";
    
    function getId() {
        return variables.id
    }
    
    function hasPermission( required permission ) {
        if ( isSimpleValue( arguments.permission ) ) {
            return variables.permissions.findNoCase( arguments.permission ) > 0
        }
        
        // Check array of permissions
        return arguments.permission.filter( ( p ) => {
            return variables.permissions.findNoCase( p ) > 0
        } ).len() > 0
    }
    
    function hasRole( required role ) {
        if ( isSimpleValue( arguments.role ) ) {
            return variables.roles.findNoCase( arguments.role ) > 0
        }
        
        // Check array of roles
        return arguments.role.filter( ( r ) => {
            return variables.roles.findNoCase( r ) > 0
        } ).len() > 0
    }
}
```

## Authentication Methods

### Injection

```boxlang
// In handlers/interceptors/views/layouts
property name="auth" inject="authenticationService@cbauth";

// Or use the auth() helper
var user = auth().getUser()
```

### Login

```boxlang
function login( event, rc, prc ) {
    if ( event.isPOST() ) {
        try {
            // Authenticate user
            var user = auth.authenticate( rc.username ?: "", rc.password ?: "" )
            
            flash.put( "notice", "Welcome back, #user.getUsername()#!" )
            relocate( "dashboard" )
        } catch ( InvalidCredentials e ) {
            flash.put( "error", "Invalid username or password" )
            flash.put( "username", rc.username )
            relocate( "security.login" )
        }
    }
    
    event.setView( "security/login" )
}
```

### Logout

```boxlang
function logout( event, rc, prc ) {
    auth.logout()
    flash.put( "notice", "You have been logged out" )
    relocate( "main.index" )
}
```

### Manual Login

```boxlang
// Bypass credential checking and log user in directly
var user = getInstance( "User" ).find( userId )
auth.login( user )
```

### Check Authentication

```boxlang
// Check if logged in
if ( auth.isLoggedIn() ) {
    // User is authenticated
}

// Check if guest (not logged in)
if ( auth.guest() ) {
    // User is NOT authenticated
}

// Alias for isLoggedIn()
if ( auth.check() ) {
    // User is authenticated
}
```

### Get Current User

```boxlang
// Get current user (throws exception if not logged in)
var user = auth.getUser()

// Access user properties
var userId = auth.getUser().getId()
var email = auth.getUser().getEmail()

// In views using helper
<cfif auth().isLoggedIn()>
    Welcome, #auth().getUser().getUsername()#!
</cfif>
```

## Interception Points

Listen to authentication events:

### preAuthentication

```boxlang
// In interceptor
function preAuthentication( event, interceptData ) {
    // interceptData.username
    // interceptData.password
    // interceptData.sessionStorage
    // interceptData.requestStorage
    
    // Log authentication attempt
    log.info( "Login attempt: #interceptData.username#" )
}
```

### postAuthentication

```boxlang
function postAuthentication( event, interceptData ) {
    // interceptData.user
    // interceptData.sessionStorage
    // interceptData.requestStorage
    
    var user = interceptData.user
    
    // Update last login
    userService.updateLastLogin( user.getId() )
    
    // Track login event
    analyticsService.track( "user_login", {
        userId: user.getId(),
        timestamp: now()
    } )
}
```

### preLogin

```boxlang
function preLogin( event, interceptData ) {
    // interceptData.user
    // interceptData.sessionStorage
    // interceptData.requestStorage
}
```

### postLogin

```boxlang
function postLogin( event, interceptData ) {
    // interceptData.user
    // interceptData.sessionStorage
    // interceptData.requestStorage
    
    // Store additional session data
    interceptData.sessionStorage.setVar( 
        "loginTime", 
        now() 
    )
}
```

### preLogout

```boxlang
function preLogout( event, interceptData ) {
    // interceptData.sessionStorage
    // interceptData.requestStorage
    
    // Cleanup before logout
}
```

### postLogout

```boxlang
function postLogout( event, interceptData ) {
    // interceptData.user (if logged in, else null)
    // interceptData.sessionStorage
    // interceptData.requestStorage
    
    // Track logout event
    log.info( "User logged out" )
}
```

## Common Patterns

### Login Handler

```boxlang
class Security extends coldbox.system.EventHandler {
    property name="auth" inject="authenticationService@cbauth";
    
    function login( event, rc, prc ) {
        if ( event.isPOST() ) {
            try {
                var user = auth.authenticate( rc.username ?: "", rc.password ?: "" )
                
                // Store intended URL from before login
                var intendedUrl = flash.get( "_intendedUrl", "" )
                
                if ( len( intendedUrl ) ) {
                    flash.discard( "_intendedUrl" )
                    relocate( url=intendedUrl )
                }
                
                relocate( "dashboard" )
            } catch ( InvalidCredentials e ) {
                flash.put( "error", "Invalid credentials" )
                flash.put( "username", rc.username )
                relocate( "security.login" )
            }
        }
        
        event.setView( "security/login" )
    }
    
    function logout( event, rc, prc ) {
        auth.logout()
        relocate( "main.index" )
    }
}
```

### Require Authentication Interceptor

```boxlang
component extends="coldbox.system.Interceptor" {
    property name="auth" inject="authenticationService@cbauth";
    
    function preProcess( event, interceptData ) {
        // Skip login/public pages
        var currentEvent = event.getCurrentEvent()
        var publicEvents = [ "security.login", "main.index", "api.health" ]
        
        if ( publicEvents.findNoCase( currentEvent ) ) {
            return
        }
        
        // Require authentication
        if ( !auth.isLoggedIn() ) {
            flash.put( "_intendedUrl", event.getCurrentRoutedUrl() )
            flash.put( "error", "Please log in to continue" )
            relocate( "security.login" )
        }
    }
}
```

### Remember Me Functionality

```boxlang
function login( event, rc, prc ) {
    if ( event.isPOST() ) {
        try {
            var user = auth.authenticate( rc.username ?: "", rc.password ?: "" )
            
            // Remember me
            if ( rc.rememberMe ?: false ) {
                var token = createRememberToken( user )
                cookie.set(
                    name = "remember_token",
                    value = token,
                    expires = 30, // days
                    httpOnly = true,
                    secure = true
                )
            }
            
            relocate( "dashboard" )
        } catch ( InvalidCredentials e ) {
            flash.put( "error", "Invalid credentials" )
            relocate( "security.login" )
        }
    }
    
    event.setView( "security/login" )
}
```

### API Token Authentication

```boxlang
class APIAuthInterceptor extends coldbox.system.Interceptor {
    property name="auth" inject="authenticationService@cbauth";
    property name="userService" inject;
    
    function preProcess( event, interceptData ) {
        var currentEvent = event.getCurrentEvent()
        
        // Only apply to API routes
        if ( !currentEvent.findNoCase( "api." ) ) {
            return
        }
        
        // Get token from header
        var token = event.getHTTPHeader( "X-API-Token", "" )
        
        if ( !len( token ) ) {
            event.renderData(
                data = { error: "API token required" },
                statusCode = 401
            )
            event.noExecution()
            return
        }
        
        // Validate token and log in user
        try {
            var user = userService.getUserByApiToken( token )
            auth.login( user )
        } catch ( any e ) {
            event.renderData(
                data = { error: "Invalid API token" },
                statusCode = 401
            )
            event.noExecution()
        }
    }
}
```

## Best Practices

- **Implement IUserService** - Follow the interface contract
- **Implement IAuthUser** - Ensure user object has required methods
- **Hash passwords** - Use bcrypt module for password hashing
- **Use interceptors** - Listen to auth events for logging/tracking
- **Secure sessions** - Use secure, httpOnly cookies
- **Implement remember me** - Provide persistent login option
- **Rate limit logins** - Prevent brute force attacks
- **Validate credentials properly** - Use timing-safe comparison
- **Clear sessions on logout** - Ensure complete logout
- **Use HTTPS** - Always encrypt authentication data in transit

## Documentation

For complete CBAuth documentation, custom storage providers, and advanced features, visit:
https://cbauth.ortusbooks.com
