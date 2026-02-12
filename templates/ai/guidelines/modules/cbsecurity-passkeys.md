---
title: CBSecurity Passkeys Module Guideline
description: Passwordless authentication using WebAuthn and FIDO2 passkeys
---

# CBSecurity Passkeys Module Guideline

## Overview

CBSecurity Passkeys adds passwordless authentication to ColdBox applications using WebAuthn (Web Authentication API) standard. It enables users to authenticate using biometrics (fingerprint, Face ID), security keys (YubiKey), or platform authenticators instead of passwords - providing better security and user experience.

**Benefits:**
- Passwordless authentication - no passwords to remember or steal
- Biometric support - fingerprint, Face ID, Windows Hello
- Security key support - YubiKey, Google Titan
- Phishing resistant - cryptographic authentication
- Standards-based - WebAuthn/FIDO2 specification
- Seamless integration - works with cbSecurity authentication

## Installation

### Step 1: Install Module

```bash
box install cbsecurity-passkeys
```

### Step 2: Configure Java Libraries

In your `Application.cfc`:

```javascript
this.javaSettings = {
    loadPaths = [ "./modules/cbsecurity-passkeys/lib" ],
    loadColdFusionClassPath = true,
    reloadOnChange = true
}
```

### Step 3: Implement Credential Repository

Create a model implementing `ICredentialRepository` interface:

```javascript
// models/Passkey.cfc
component implements="cbsecurity-passkeys.models.ICredentialRepository" {

    property name="userService" inject

    /**
     * Find credential by credential ID
     * @credentialId The credential ID bytes
     * @return Optional containing credential or empty
     */
    function getCredentialById( required binary credentialId ) {
        var credential = queryExecute(
            "SELECT * FROM passkeys WHERE credentialId = ?",
            [ { value: arguments.credentialId, cfsqltype: "binary" } ],
            { returntype: "array" }
        )

        if ( !credential.len() ) {
            return createObject( "java", "java.util.Optional" ).empty()
        }

        return createObject( "java", "java.util.Optional" ).of(
            buildCredential( credential[ 1 ] )
        )
    }

    /**
     * Get all credentials for a user
     * @userHandle The user handle bytes
     * @return Set of credentials
     */
    function getCredentialsByUserHandle( required binary userHandle ) {
        var credentials = queryExecute(
            "SELECT * FROM passkeys WHERE userHandle = ?",
            [ { value: arguments.userHandle, cfsqltype: "binary" } ],
            { returntype: "array" }
        )

        return credentials.map( function( cred ) {
            return buildCredential( cred )
        } )
    }

    /**
     * Get user handle for a given username
     * @username The username
     * @return Optional containing user handle or empty
     */
    function getUserHandleForUsername( required string username ) {
        var user = userService.findByUsername( arguments.username )

        if ( isNull( user ) ) {
            return createObject( "java", "java.util.Optional" ).empty()
        }

        return createObject( "java", "java.util.Optional" ).of(
            charsetDecode( user.getId(), "utf-8" )
        )
    }

    /**
     * Lookup username by user handle
     * @userHandle The user handle bytes
     * @return Optional containing username or empty
     */
    function getUsernameForUserHandle( required binary userHandle ) {
        var userId = charsetEncode( arguments.userHandle, "utf-8" )
        var user = userService.get( userId )

        if ( isNull( user ) ) {
            return createObject( "java", "java.util.Optional" ).empty()
        }

        return createObject( "java", "java.util.Optional" ).of(
            user.getUsername()
        )
    }

    /**
     * Check if username exists
     * @username The username
     * @return Boolean
     */
    function usernameExists( required string username ) {
        return !isNull( userService.findByUsername( arguments.username ) )
    }

    /**
     * Save a new credential
     * @credential The credential to save
     */
    function saveCredential( required any credential ) {
        queryExecute(
            "INSERT INTO passkeys (credentialId, userHandle, publicKey, signCount, createdDate)
             VALUES (?, ?, ?, ?, ?)",
            [
                { value: credential.getCredentialId(), cfsqltype: "binary" },
                { value: credential.getUserHandle(), cfsqltype: "binary" },
                { value: credential.getPublicKey(), cfsqltype: "binary" },
                { value: credential.getSignCount(), cfsqltype: "bigint" },
                { value: now(), cfsqltype: "timestamp" }
            ]
        )
    }

    /**
     * Update credential signature count
     * @credential The credential
     * @signCount The new signcount
     */
    function updateSignCount( required any credential, required numeric signCount ) {
        queryExecute(
            "UPDATE passkeys SET signCount = ?, lastUsed = ? WHERE credentialId = ?",
            [
                { value: arguments.signCount, cfsqltype: "bigint" },
                { value: now(), cfsqltype: "timestamp" },
                { value: credential.getCredentialId(), cfsqltype: "binary" }
            ]
        )
    }

    private function buildCredential( required struct data ) {
        // Build WebAuthn credential object from database data
        var credential = createObject( "java", "com.yubico.webauthn.RegisteredCredential" )
            .builder()
            .credentialId( data.credentialId )
            .userHandle( data.userHandle )
            .publicKeyCose( data.publicKey )
            .signatureCount( data.signCount )
            .build()

        return credential
    }
}
```

### Step 4: Configure Module

In `config/ColdBox.cfc`:

```javascript
moduleSettings = {
    "cbsecurity-passkeys" = {
        // Your credential repository
        credentialRepositoryMapping = "Passkey",
        // Allowed origins (your domain)
        allowedOrigins = [ "localhost:8080", "example.com" ],
        // Display name for your app
        displayName = "My Application"
    }
}
```

## Database Schema

Create a table to store passkeys:

```sql
CREATE TABLE passkeys (
    id VARCHAR(36) PRIMARY KEY,
    credentialId BLOB NOT NULL UNIQUE,
    userHandle BLOB NOT NULL,
    publicKey BLOB NOT NULL,
    signCount BIGINT DEFAULT 0,
    createdDate DATETIME NOT NULL,
    lastUsed DATETIME NULL,
    INDEX idx_userHandle (userHandle(255)),
    INDEX idx_credentialId (credentialId(255))
)
```

## Frontend Integration

### Include Passkeys JavaScript

```html
<script src="/modules/cbsecurity-passkeys/includes/passkeys.js"></script>
```

### Registration Flow

```html
<script type="module">
// Check if passkeys are supported
if ( await window.cbSecurity.passkeys.isSupported() ) {

    // Show passkey registration button
    document.getElementById( 'passkeyRegisterBtn' ).style.display = 'block'

    // Register passkey
    document.getElementById( 'passkeyRegisterBtn' ).addEventListener( 'click', async () => {
        try {
            await window.cbSecurity.passkeys.register( '/' ) // Redirect after success
        } catch ( error ) {
            console.error( 'Passkey registration failed:', error )
            alert( 'Failed to register passkey' )
        }
    } )
}
</script>
```

### Login Flow

```html
<script type="module">
if ( await window.cbSecurity.passkeys.isSupported() ) {

    // Login with passkey
    document.getElementById( 'passkeyLoginBtn' ).addEventListener( 'click', async () => {
        try {
            await window.cbSecurity.passkeys.login(
                'john@example.com', // username (optional for discoverable credentials)
                '/', // redirect location
                {} // additional params
            )
        } catch ( error ) {
            console.error( 'Passkey login failed:', error )
            alert( 'Authentication failed' )
        }
    } )
}
</script>
```

### Autocomplete/Conditional UI

For seamless login using browser autofill:

```html
<input
    type="text"
    name="username"
    autocomplete="username webauthn"
/>

<script>
// Trigger passkey autofill
window.cbSecurity.passkeys.autocomplete(
    '/', // redirect location
    {} // additional params
)
</script>
```

## Backend Handlers

### Registration Handler

```javascript
// handlers/Auth.cfc
component {

    property name="passkeyService" inject="PasskeyService@cbsecurity-passkeys"
    property name="userService" inject

    /**
     * Initialize passkey registration
     */
    function startRegistration( event, rc, prc ) {
        // User must be authenticated to register a passkey
        if ( !auth().check() ) {
            relocate( "login" )
        }

        var user = auth().user()

        // Start registration process
        var options = passkeyService.startRegistration(
            username = user.getUsername(),
            userHandle = user.getId()
        )

        event.getResponse()
            .setData( options )
            .setStatusCode( 200 )
    }

    /**
     * Complete passkey registration
     */
    function finishRegistration( event, rc, prc ) {
        try {
            passkeyService.finishRegistration( rc )

            event.getResponse()
                .setData( { success: true, message: "Passkey registered successfully" } )
                .setStatusCode( 201 )
        } catch ( any e ) {
            event.getResponse()
                .setError( true )
                .setMessages( [ e.message ] )
                .setStatusCode( 400 )
        }
    }
}
```

### Login Handler

```javascript
/**
 * Start passkey authentication
 */
function startLogin( event, rc, prc ) {
    var username = rc.username ?: ""

    var options = passkeyService.startAuthentication( username )

    event.getResponse()
        .setData( options )
        .setStatusCode( 200 )
}

/**
 * Complete passkey authentication
 */
function finishLogin( event, rc, prc ) {
    try {
        var authResult = passkeyService.finishAuthentication( rc )

        if ( authResult.success ) {
            // Authenticate user with cbSecurity/cbAuth
            auth().login( authResult.user )

            event.getResponse()
                .setData( {
                    success: true,
                    redirect: rc.redirect ?: "/"
                } )
                .setStatusCode( 200 )
        } else {
            event.getResponse()
                .setError( true )
                .setMessages( [ "Authentication failed" ] )
                .setStatusCode( 401 )
        }
    } catch ( any e ) {
        event.getResponse()
            .setError( true )
            .setMessages( [ e.message ] )
            .setStatusCode( 400 )
    }
}
```

## Configuration Options

```javascript
moduleSettings = {
    "cbsecurity-passkeys" = {
        // Required: Your credential repository
        credentialRepositoryMapping = "Passkey",

        // Required: Allowed origins (domains)
        allowedOrigins = [ "localhost:8080", "example.com", "www.example.com" ],

        // Optional: Display name shown to users
        displayName = "My App",

        // Optional: Timeout for registration (milliseconds)
        registrationTimeout = 60000,

        // Optional: Timeout for authentication (milliseconds)
        authenticationTimeout = 60000,

        // Optional: Require user verification (biometrics/PIN)
        userVerification = "preferred", // required, preferred, discouraged

        // Optional: Attestation conveyance preference
        attestation = "none", // none, indirect, direct

        // Optional: Authenticator attachment
        authenticatorAttachment = "", // empty, platform, cross-platform

        // Optional: Require resident key (discoverable credential)
        residentKey = "preferred" // required, preferred, discouraged
    }
}
```

## User Experience Patterns

### Progressive Enhancement

```html
<!-- Traditional password login -->
<form id="loginForm">
    <input type="email" name="username" autocomplete="username" required />
    <input type="password" name="password" autocomplete="current-password" required />
    <button type="submit">Sign In</button>
</form>

<!-- Passkey login (if supported) -->
<div id="passkeyLogin" style="display:none;">
    <button id="passkeyBtn">Sign in with Passkey</button>
</div>

<script type="module">
if ( await window.cbSecurity.passkeys.isSupported() ) {
    document.getElementById( 'passkeyLogin' ).style.display = 'block'
    // Optionally hide password field for passkey-only mode
}
</script>
```

### Conditional UI

Show passkey option only to users who have registered one:

```javascript
// Backend: Check if user has passkeys
function hasPasskeys( required string username ) {
    return passkeyService.getUserPasskeys( username ).len() > 0
}

// Frontend: Show appropriate UI
if ( userHasPasskeys && await window.cbSecurity.passkeys.isSupported() ) {
    showPasskeyLogin()
} else {
    showPasswordLogin()
}
```

### Multi-Factor Enhancement

Use passkeys as second factor:

```javascript
// After password authentication
if ( user.hasMFAEnabled() && user.hasPasskeys() ) {
    // Require passkey as second factor
    await window.cbSecurity.passkeys.login( user.getUsername() )
}
```

## Security Best Practices

### Origin Configuration

```javascript
allowedOrigins = [
    "localhost:8080", // Development
    "staging.example.com", // Staging
    "example.com", // Production
    "www.example.com" // Production www
]
// Include ALL domains where your app is accessed
```

### User Verification

```javascript
// Require biometrics/PIN for sensitive operations
userVerification = "required"
```

### Credential Management

```javascript
// Allow users to manage their passkeys
function listPasskeys( event, rc, prc ) {
    var user = auth().user()
    prc.passkeys = passkeyService.getUserPasskeys( user.getUsername() )
}

function deletePasskey( event, rc, prc ) {
    passkeyService.deleteCredential( rc.credentialId )
    setNextEvent( "account.security" )
}
```

## Testing

### Manual Testing

1. Register a user account
2. Navigate to passkey registration
3. Click "Register Passkey"
4. Complete platform authenticator flow
5. Logout
6. Click "Sign in with Passkey"
7. Complete authentication flow

### Automated Testing

```javascript
// Test credential repository
component extends="tests.resources.BaseIntegrationTest" {

    function run() {
        describe( "Passkey Service", function() {

            it( "can register a passkey", function() {
                var user = createUser()

                var options = passkeyService.startRegistration(
                    username = user.getUsername(),
                    userHandle = user.getId()
                )

                expect( options ).toHaveKey( "challenge" )
            } )

            it( "can authenticate with passkey", function() {
                // Test authentication flow
            } )
        } )
    }
}
```

## Troubleshooting

### Passkeys Not Supported

**Browser Requirements:**
- Chrome/Edge 109+
- Firefox 119+
- Safari 16+

**Check support:**
```javascript
if ( !await window.cbSecurity.passkeys.isSupported() ) {
    console.log( "WebAuthn not supported" )
}
```

### Registration Fails

**Common causes:**
- Origin not in `allowedOrigins`
- User already has max passkeys
- Java libraries not loaded correctly
- Invalid user handle

### Authentication Fails

**Debug steps:**
1. Check browser console for errors
2. Verify credential exists in database
3. Check signature count hasn't decreased
4. Validate origin matches allowed list

## Module Information

- **Repository:** github.com/coldbox-modules/cbsecurity-passkeys
- **Requirements:** ColdBox 6+, cbSecurity 3+
- **Standards:** WebAuthn/FIDO2
- **Java Libraries:** Yubico WebAuthn Server
- **Browser Support:** Modern browsers with WebAuthn API
