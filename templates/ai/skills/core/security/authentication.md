---
name: Authentication Patterns
description: Complete guide to CBAuth authentication, user management, login/logout, password hashing, session management, and remember me functionality
category: security
priority: high
triggers:
  - cbauth
  - authentication
  - login
  - logout
  - user authentication
  - password
  - session management
---

# Authentication Patterns

## Overview

CBAuth provides user authentication for ColdBox applications with session management, password hashing, remember me functionality, and user retrieval. Proper authentication ensures only verified users access protected resources.

## Core Concepts

### CBAuth Architecture

- **AuthenticationService**: User authentication and session management
- **User Entity**: Authenticated user model
- **Session Storage**: User session persistence
- **Password Hashing**: BCrypt password security
- **Remember Me**: Persistent login tokens

## Installation & Setup

### Install CBAuth

```bash
box install cbauth
```

### Configuration

```boxlang
/**
 * config/ColdBox.cfc
 */
class {

    function configure() {
        moduleSettings = {
            cbauth: {
                // User service
                userServiceClass: "UserService@models",

                // User entity
                userModel: "User@models",

                // Remember me
                rememberMe: {
                    enabled: true,
                    cookieName: "remember_me",
                    days: 30
                }
            }
        }
    }
}
```

## User Service

### Creating User Service

```boxlang
/**
 * models/UserService.cfc
 */
class singleton {

    property name="bcrypt" inject="@BCrypt"

    /**
     * Retrieve user by identifier
     * Required by CBAuth
     */
    function retrieveUserById( required id ) {
        return queryExecute(
            "SELECT * FROM users WHERE id = :id",
            { id: arguments.id }
        ).reduce( convertToUser )
    }

    /**
     * Retrieve user by username
     * Required by CBAuth
     */
    function retrieveUserByUsername( required username ) {
        return queryExecute(
            "SELECT * FROM users WHERE email = :email",
            { email: arguments.username }
        ).reduce( convertToUser )
    }

    /**
     * Check user credentials
     * Required by CBAuth
     */
    function isValidCredentials( required username, required password ) {
        try {
            var user = retrieveUserByUsername( arguments.username )

            return bcrypt.checkPassword( arguments.password, user.password )

        } catch ( any e ) {
            return false
        }
    }

    /**
     * Create new user
     */
    function create( required data ) {
        var hashedPassword = bcrypt.hashPassword( arguments.data.password )

        queryExecute(
            "INSERT INTO users (email, password, name) VALUES (:email, :password, :name)",
            {
                email: arguments.data.email,
                password: hashedPassword,
                name: arguments.data.name
            }
        )

        return retrieveUserByUsername( arguments.data.email )
    }

    /**
     * Update user
     */
    function update( required id, required data ) {
        queryExecute(
            "UPDATE users SET name = :name WHERE id = :id",
            {
                id: arguments.id,
                name: arguments.data.name
            }
        )

        return retrieveUserById( arguments.id )
    }

    /**
     * Change password
     */
    function changePassword( required id, required newPassword ) {
        var hashedPassword = bcrypt.hashPassword( arguments.newPassword )

        queryExecute(
            "UPDATE users SET password = :password WHERE id = :id",
            {
                id: arguments.id,
                password: hashedPassword
            }
        )

        return true
    }

    private function convertToUser( result, row ) {
        return {
            id: row.id,
            email: row.email,
            name: row.name,
            password: row.password
        }
    }
}
```

## User Entity

### User Model

```boxlang
/**
 * models/User.cfc
 */
class accessors="true" {

    property name="id"
    property name="email"
    property name="name"
    property name="password"
    property name="roles" type="array"
    property name="permissions" type="array"

    function init() {
        variables.roles = []
        variables.permissions = []
        return this
    }

    /**
     * Check if user has role
     */
    function hasRole( required role ) {
        return variables.roles.contains( arguments.role )
    }

    /**
     * Check if user has permission
     */
    function hasPermission( required permission ) {
        return variables.permissions.contains( arguments.permission )
    }

    /**
     * Get user identifier for CBAuth
     */
    function getId() {
        return variables.id
    }
}
```

## Authentication

### Login Handler

```boxlang
/**
 * handlers/Sessions.cfc
 */
class extends="coldbox.system.EventHandler" {

    property name="auth" inject="authenticationService@cbauth"
    property name="messagebox" inject="@cbmessagebox"

    function new( event, rc, prc ) secured="none" {
        event.setView( "sessions/new" )
    }

    function create( event, rc, prc ) secured="none" {
        try {
            // Attempt login
            auth.authenticate( rc.email, rc.password )

            // Remember me
            if ( rc.keyExists( "remember" ) && rc.remember ) {
                auth.rememberUser( auth.getUser() )
            }

            messagebox.success( "Welcome back!" )

            // Redirect to intended or home
            relocate( rc._securedURL ?: "main.index" )

        } catch ( InvalidCredentials e ) {
            messagebox.error( "Invalid email or password" )
            relocate( "sessions.new" )
        }
    }

    function delete( event, rc, prc ) {
        auth.logout()

        messagebox.info( "You have been logged out" )
        relocate( "main.index" )
    }
}
```

### Login View

```html
<!-- views/sessions/new.cfm -->
<h2>Login</h2>

<form action="#event.buildLink( "sessions.create" )#" method="post">
    <div>
        <label for="email">Email:</label>
        <input type="email" name="email" id="email" required>
    </div>

    <div>
        <label for="password">Password:</label>
        <input type="password" name="password" id="password" required>
    </div>

    <div>
        <label>
            <input type="checkbox" name="remember" value="1">
            Remember me
        </label>
    </div>

    <button type="submit">Login</button>
</form>

<p>
    <a href="#event.buildLink( 'passwords.forgot' )#">Forgot password?</a>
</p>
```

## Registration

### Registration Handler

```boxlang
/**
 * handlers/Registrations.cfc
 */
class extends="coldbox.system.EventHandler" {

    property name="userService" inject="UserService"
    property name="auth" inject="authenticationService@cbauth"
    property name="validator" inject="ValidationManager@cbvalidation"
    property name="messagebox" inject="@cbmessagebox"

    function new( event, rc, prc ) secured="none" {
        event.setView( "registrations/new" )
    }

    function create( event, rc, prc ) secured="none" {
        // Validate input
        var validationResult = validator.validate(
            target: rc,
            constraints: {
                name: { required: true },
                email: {
                    required: true,
                    type: "email",
                    udf: ( value ) => {
                        return !userService.emailExists( value )
                    }
                },
                password: {
                    required: true,
                    min: 8
                },
                passwordConfirmation: {
                    required: true,
                    sameAs: "password"
                }
            }
        )

        if ( validationResult.hasErrors() ) {
            messagebox.error( validationResult.getAllErrorsAsString() )
            relocate( "registrations.new" )
        }

        // Create user
        var user = userService.create( rc )

        // Auto-login
        auth.login( user )

        messagebox.success( "Welcome to our app!" )
        relocate( "main.index" )
    }
}
```

## Password Management

### Password Reset Handler

```boxlang
/**
 * handlers/Passwords.cfc
 */
class extends="coldbox.system.EventHandler" {

    property name="userService" inject="UserService"
    property name="tokenService" inject="TokenService"
    property name="mailService" inject="MailService"
    property name="messagebox" inject="@cbmessagebox"

    function forgot( event, rc, prc ) secured="none" {
        event.setView( "passwords/forgot" )
    }

    function sendReset( event, rc, prc ) secured="none" {
        try {
            var user = userService.retrieveUserByUsername( rc.email )

            // Generate reset token
            var token = tokenService.create( user.id, "password_reset", 60 )

            // Send email
            mailService.send( {
                to: user.email,
                subject: "Password Reset",
                view: "emails/password_reset",
                viewArgs: {
                    user: user,
                    token: token,
                    resetURL: event.buildLink( "passwords.reset" ) & "?token=" & token
                }
            } )

            messagebox.info( "Check your email for reset instructions" )

        } catch ( any e ) {
            // Don't reveal if email exists
            messagebox.info( "If that email exists, you will receive reset instructions" )
        }

        relocate( "sessions.new" )
    }

    function reset( event, rc, prc ) secured="none" {
        // Verify token
        if ( !tokenService.verify( rc.token, "password_reset" ) ) {
            messagebox.error( "Invalid or expired reset link" )
            relocate( "passwords.forgot" )
        }

        prc.token = rc.token
        event.setView( "passwords/reset" )
    }

    function update( event, rc, prc ) secured="none" {
        // Verify token
        var tokenData = tokenService.verify( rc.token, "password_reset" )

        if ( !tokenData ) {
            messagebox.error( "Invalid or expired reset link" )
            relocate( "passwords.forgot" )
        }

        // Validate password
        var validationResult = validator.validate(
            target: rc,
            constraints: {
                password: { required: true, min: 8 },
                passwordConfirmation: { required: true, sameAs: "password" }
            }
        )

        if ( validationResult.hasErrors() ) {
            messagebox.error( validationResult.getAllErrorsAsString() )
            relocate( "passwords.reset" ).addQueryString( "token", rc.token )
        }

        // Update password
        userService.changePassword( tokenData.userID, rc.password )

        // Invalidate token
        tokenService.invalidate( rc.token )

        messagebox.success( "Password updated successfully" )
        relocate( "sessions.new" )
    }
}
```

## Auth Helpers

### Using Auth Service

```boxlang
class extends="coldbox.system.EventHandler" {

    property name="auth" inject="authenticationService@cbauth"

    function dashboard( event, rc, prc ) {
        // Check authentication
        if ( !auth.isLoggedIn() ) {
            relocate( "sessions.new" )
        }

        // Get current user
        prc.user = auth.getUser()

        // Check authentication
        if ( auth.check() ) {
            prc.greeting = "Welcome, #prc.user.name#"
        }

        event.setView( "main/dashboard" )
    }

    function profile( event, rc, prc ) {
        // Get authenticated user
        var user = auth.user()

        prc.user = user
        event.setView( "users/profile" )
    }
}
```

### View Layer Auth

```html
<!-- views/layouts/Main.cfm -->
<nav>
    <cfif auth().check()>
        <span>Hello, #auth().user().getName()#</span>
        <a href="#buildLink( 'sessions.delete' )#">Logout</a>
    <cfelse>
        <a href="#buildLink( 'sessions.new' )#">Login</a>
        <a href="#buildLink( 'registrations.new' )#">Register</a>
    </cfif>
</nav>
```

## Advanced Patterns

### Remember Me

```boxlang
function create( event, rc, prc ) secured="none" {
    // Login
    auth.authenticate( rc.email, rc.password )

    // Remember user
    if ( rc.remember ) {
        auth.rememberUser(
            user: auth.getUser(),
            days: 30
        )
    }

    relocate( "main.index" )
}
```

### Guest-Only Pages

```boxlang
class extends="coldbox.system.EventHandler" {

    property name="auth" inject="authenticationService@cbauth"

    function new( event, rc, prc ) secured="none" {
        // Redirect if already logged in
        if ( auth.isLoggedIn() ) {
            relocate( "main.dashboard" )
        }

        event.setView( "sessions/new" )
    }
}
```

### Impersonation

```boxlang
/**
 * Admin impersonation
 */
class extends="coldbox.system.EventHandler" {

    property name="auth" inject="authenticationService@cbauth"
    property name="userService" inject="UserService"

    function impersonate( event, rc, prc ) secured="admin" {
        // Store original user
        var originalUser = auth.getUser()
        session.originalUserID = originalUser.getId()

        // Login as target user
        var targetUser = userService.retrieveUserById( rc.userID )
        auth.login( targetUser )

        messagebox.info( "Now impersonating #targetUser.name#" )
        relocate( "main.dashboard" )
    }

    function stopImpersonating( event, rc, prc ) {
        if ( session.keyExists( "originalUserID" ) ) {
            // Restore original user
            var originalUser = userService.retrieveUserById( session.originalUserID )
            auth.login( originalUser )

            structDelete( session, "originalUserID" )

            messagebox.info( "Stopped impersonating" )
        }

        relocate( "admin.users" )
    }
}
```

### Multi-Factor Authentication

```boxlang
/**
 * Two-factor authentication
 */
class extends="coldbox.system.EventHandler" {

    property name="auth" inject="authenticationService@cbauth"
    property name="totpService" inject="TOTPService"

    function create( event, rc, prc ) secured="none" {
        // First factor: password
        var validCredentials = userService.isValidCredentials(
            rc.email,
            rc.password
        )

        if ( !validCredentials ) {
            messagebox.error( "Invalid credentials" )
            relocate( "sessions.new" )
        }

        // Check if 2FA enabled
        var user = userService.retrieveUserByUsername( rc.email )

        if ( user.twoFactorEnabled ) {
            // Store pending user
            session.pendingUserID = user.id

            relocate( "sessions.verify2fa" )
        }

        // Login normally
        auth.login( user )
        relocate( "main.index" )
    }

    function verify2fa( event, rc, prc ) secured="none" {
        if ( !session.keyExists( "pendingUserID" ) ) {
            relocate( "sessions.new" )
        }

        event.setView( "sessions/verify2fa" )
    }

    function verify2faCode( event, rc, prc ) secured="none" {
        var userID = session.pendingUserID
        var user = userService.retrieveUserById( userID )

        // Verify TOTP code
        if ( !totpService.verify( user.totpSecret, rc.code ) ) {
            messagebox.error( "Invalid code" )
            relocate( "sessions.verify2fa" )
        }

        // Complete login
        structDelete( session, "pendingUserID" )
        auth.login( user )

        relocate( "main.index" )
    }
}
```

## Best Practices

### Design Guidelines

1. **BCrypt Passwords**: Always hash with BCrypt
2. **Secure Sessions**: Use secure session storage
3. **Password Strength**: Enforce strong passwords
4. **Rate Limiting**: Prevent brute force attacks
5. **Account Lockout**: Lock after failed attempts
6. **Secure Transport**: Always use HTTPS
7. **Token Expiration**: Short-lived reset tokens
8. **Input Validation**: Validate all user input
9. **Audit Trail**: Log authentication events
10. **Regular Testing**: Test authentication flows

### Common Patterns

```boxlang
// ✅ Good: Check authentication
if ( !auth.isLoggedIn() ) {
    relocate( "sessions.new" )
}

// ✅ Good: Hash password
var hashedPassword = bcrypt.hashPassword( password )

// ✅ Good: Validate credentials
if ( !userService.isValidCredentials( email, password ) ) {
    throw( "Invalid credentials" )
}

// ✅ Good: Auto-login after registration
auth.login( newUser )
```

## Common Pitfalls

### Pitfalls to Avoid

1. **Plain Text Passwords**: Not hashing passwords
2. **Weak Hashing**: Using MD5/SHA1
3. **No Validation**: Accepting weak passwords
4. **Session Fixation**: Not regenerating session IDs
5. **No HTTPS**: Sending credentials over HTTP
6. **Token Reuse**: Allowing token reuse
7. **Information Disclosure**: Revealing if user exists
8. **No Rate Limiting**: Allowing brute force
9. **Long Sessions**: Sessions never expire
10. **Predictable Tokens**: Weak reset tokens

### Anti-Patterns

```boxlang
// ❌ Bad: Plain text password
user.password = rc.password

// ✅ Good: Hashed password
user.password = bcrypt.hashPassword( rc.password )

// ❌ Bad: Revealing user existence
if ( !userExists( email ) ) {
    throw( "User not found" )
}

// ✅ Good: Generic message
messagebox.info( "If that email exists, you will receive instructions" )

// ❌ Bad: No session regeneration
auth.login( user )

// ✅ Good: Regenerate session
sessionRotate()
auth.login( user )
```

## Related Skills

- [CBSecurity Implementation](security-implementation.md) - Security framework
- [Authorization Patterns](authorization.md) - Security rules
- [JWT Development](jwt-development.md) - JWT authentication
- [Passkeys Integration](passkeys-integration.md) - WebAuthn

## References

- [CBAuth Documentation](https://forgebox.io/view/cbauth)
- [BCrypt Documentation](https://www.npmjs.com/package/bcrypt)
- [OWASP Authentication](https://cheatsheetseries.owasp.org/cheatsheets/Authentication_Cheat_Sheet.html)
