---
title: BCrypt Module Guidelines
description: Secure password hashing guidance with BCrypt, including cost-factor tuning, hash verification workflows, migration strategy, and credential-handling best practices.
---

# BCrypt Module Guidelines

## Overview

BCrypt is a ColdBox module that provides secure password hashing using the BCrypt algorithm. It uses a work factor to make password hashing computationally expensive, protecting against brute-force attacks.

## Installation

```bash
box install bcrypt
```

## Configuration

In `config/ColdBox.cfc` (optional):

```boxlang
moduleSettings = {
    bcrypt = {
        // Work factor (4-31, default: 12)
        // Higher = more secure but slower
        workFactor = 12
    }
}
```

## Basic Usage

### Injection

```boxlang
// In your component
property name="bcrypt" inject="@bcrypt";

// Or use the mixin helpers in handlers/views/interceptors
var hashed = bcryptHash( password )
var isValid = bcryptCheck( password, hash )
```

### Hashing Passwords

```boxlang
// Hash a password
var hashedPassword = bcrypt.hashPassword( "MySecurePass123!" )

// Returns: $2a$12$abc...xyz (60 characters)

// Hash with custom work factor
var hashedPassword = bcrypt.hashPassword(
    password = "MySecurePass123!",
    workFactor = 14
)

// Hash with custom salt
var salt = bcrypt.generateSalt( 12 )
var hashedPassword = bcrypt.hashPassword(
    password = "MySecurePass123!",
    salt = salt
)
```

### Checking Passwords

```boxlang
// Verify password against hash
var isValid = bcrypt.checkPassword(
    candidate = plaintextPassword,
    bCryptHash = storedHash
)

if ( isValid ) {
    // Passwords match - authenticate user
} else {
    // Passwords don't match - reject login
}
```

### Generating Salt

```boxlang
// Generate salt with default work factor
var salt = bcrypt.generateSalt()

// Generate salt with custom work factor
var salt = bcrypt.generateSalt( 14 )
```

## Mixin Helpers

Available in handlers, interceptors, layouts, and views:

```boxlang
// Hash password
var hashed = bcryptHash( "password123" )

// Hash with work factor
var hashed = bcryptHash( "password123", 14 )

// Check password
var isValid = bcryptCheck( "password123", hashedPassword )

// Generate salt
var salt = bcryptSalt( 12 )
```

## Common Patterns

### User Registration

```boxlang
component singleton {
    property name="userDAO" inject;
    property name="bcrypt" inject="@bcrypt";

    function register( required struct data ) {
        // Hash password before storing
        data.password = bcrypt.hashPassword( data.password )

        // Create user
        var user = userDAO.create( data )

        return user
    }
}
```

### User Authentication

```boxlang
component singleton {
    property name="userDAO" inject;
    property name="bcrypt" inject="@bcrypt";

    function authenticate( required string username, required string password ) {
        // Get user
        var user = userDAO.findByUsername( arguments.username )

        if ( isNull( user ) ) {
            throw(
                type = "InvalidCredentials",
                message = "Invalid username or password"
            )
        }

        // Check password
        if ( !bcrypt.checkPassword( arguments.password, user.getPassword() ) ) {
            throw(
                type = "InvalidCredentials",
                message = "Invalid username or password"
            )
        }

        return user
    }
}
```

### Password Change

```boxlang
component singleton {
    property name="userDAO" inject;
    property name="bcrypt" inject="@bcrypt";

    function changePassword(
        required numeric userId,
        required string currentPassword,
        required string newPassword
    ) {
        var user = userDAO.find( arguments.userId )

        // Verify current password
        if ( !bcrypt.checkPassword( arguments.currentPassword, user.getPassword() ) ) {
            throw(
                type = "InvalidPassword",
                message = "Current password is incorrect"
            )
        }

        // Hash and save new password
        user.setPassword( bcrypt.hashPassword( arguments.newPassword ) )
        user.save()

        return true
    }
}
```

### Password Reset

```boxlang
component singleton {
    property name="userDAO" inject;
    property name="bcrypt" inject="@bcrypt";

    function resetPassword( required string token, required string newPassword ) {
        // Validate reset token
        var user = userDAO.findByResetToken( arguments.token )

        if ( isNull( user ) || user.isResetTokenExpired() ) {
            throw(
                type = "InvalidToken",
                message = "Password reset token is invalid or expired"
            )
        }

        // Hash new password
        user.setPassword( bcrypt.hashPassword( arguments.newPassword ) )
        user.clearResetToken()
        user.save()

        return user
    }
}
```

### Migration from MD5/SHA

Upgrade existing password hashes during login:

```boxlang
component singleton {
    property name="userDAO" inject;
    property name="bcrypt" inject="@bcrypt";

    function authenticateAndUpgrade(
        required string username,
        required string password
    ) {
        var user = userDAO.findByUsername( arguments.username )

        if ( isNull( user ) ) {
            throw( type="InvalidCredentials" )
        }

        // Check if already using bcrypt
        if ( left( user.getPassword(), 4 ) == "$2a$" || left( user.getPassword(), 4 ) == "$2b$" ) {
            // BCrypt hash - check normally
            if ( !bcrypt.checkPassword( arguments.password, user.getPassword() ) ) {
                throw( type="InvalidCredentials" )
            }
        } else {
            // Legacy hash (MD5/SHA) - check and upgrade
            var legacyHash = hash( arguments.password, "SHA-512" )

            if ( legacyHash != user.getPassword() ) {
                throw( type="InvalidCredentials" )
            }

            // Upgrade to bcrypt
            user.setPassword( bcrypt.hashPassword( arguments.password ) )
            user.save()
        }

        return user
    }
}
```

## Work Factor Guidelines

The work factor controls computational cost:

- **Work Factor 10** - ~100ms (minimum recommended)
- **Work Factor 12** - ~250ms (default, good balance)
- **Work Factor 14** - ~1 second (high security)
- **Work Factor 16** - ~4 seconds (very high security)

**Recommendation:** Use work factor 12 for most applications. Increase to 14 for high-security applications. Target ~250ms-1s for hash generation.

```boxlang
// Test work factor performance
var start = getTickCount()
var hash = bcrypt.hashPassword( "test", 12 )
var duration = getTickCount() - start
// Should be ~250ms for work factor 12
```

## Security Best Practices

- **Never store plain text passwords** - Always hash before storing
- **Use BCrypt for passwords** - Don't use MD5, SHA1, or reversible encryption
- **Use default work factor (12) minimum** - Or higher for sensitive data
- **Don't implement your own crypto** - Use BCrypt module
- **Use timing-safe comparison** - BCrypt handles this for you
- **Pepper optional** - Can add application-wide secret in addition to salt
- **Migrate old hashes** - Upgrade legacy MD5/SHA hashes to BCrypt
- **Re-hash on password change** - Don't reuse old hashes
- **Rate limit login attempts** - Prevent brute-force even with BCrypt

## Documentation

For complete BCrypt documentation and security considerations, visit:
https://github.com/coldbox-modules/bcrypt
