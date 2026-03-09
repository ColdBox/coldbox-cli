---
name: Passkeys Integration
description: Complete guide to WebAuthn/Passkeys authentication, biometric login, passwordless auth, and FIDO2 security with cbsecurity-passkeys
category: security
priority: high
triggers:
  - passkeys
  - webauthn
  - passwordless
  - biometric
  - fido2
  - security key
---

# Passkeys Integration

## Overview

Passkeys (WebAuthn/FIDO2) provide passwordless authentication using biometrics, security keys, or device authentication. CBSecurity-Passkeys module enables secure, phishing-resistant authentication without passwords.

## Core Concepts

### Passkeys Architecture

- **WebAuthn**: Web Authentication API standard
- **FIDO2**: Authentication protocol
- **Authenticator**: Biometric sensor, security key, or platform authenticator
- **Public Key Cryptography**: Asymmetric key pairs
- **Challenge-Response**: Cryptographic verification
- **Attestation**: Device authenticity verification

## Installation & Setup

### Install CBSecurity-Passkeys

```bash
box install cbsecurity-passkeys
```

### Configuration

```boxlang
/**
 * config/ColdBox.cfc
 */
class {

    function configure() {
        moduleSettings = {
            "cbsecurity-passkeys": {
                // Relying Party settings
                rpName: "My Application",
                rpID: "myapp.com",
                rpOrigin: "https://myapp.com",

                // Attestation preference
                attestation: "none",  // none, indirect, direct

                // Authenticator attachment
                authenticatorAttachment: "platform",  // platform, cross-platform

                // User verification
                userVerification: "preferred",  // required, preferred, discouraged

                // Timeout (milliseconds)
                timeout: 60000,

                // Storage service
                storageService: "PasskeyStorageService@models"
            }
        }
    }
}
```

## Registration Flow

### Registration Handler

```boxlang
/**
 * handlers/Passkeys.cfc
 */
class extends="coldbox.system.EventHandler" {

    property name="passkeyService" inject="PasskeyService@cbsecurity-passkeys"
    property name="auth" inject="authenticationService@cbauth"
    property name="userService" inject="UserService"

    /**
     * GET /passkeys/register
     * Show passkey registration form
     */
    function register( event, rc, prc ) {
        var user = auth.getUser()

        prc.user = user
        prc.hasPasskeys = passkeyService.hasPasskeys( user.id )

        event.setView( "passkeys/register" )
    }

    /**
     * POST /passkeys/register/options
     * Generate registration options
     */
    function registerOptions( event, rc, prc ) {
        var user = auth.getUser()

        // Generate challenge and options
        var options = passkeyService.generateRegistrationOptions(
            userID: user.id,
            username: user.email,
            displayName: user.name
        )

        // Store challenge in session
        session.passkeyChallenge = options.challenge

        return event.renderData(
            type: "json",
            data: options
        )
    }

    /**
     * POST /passkeys/register/verify
     * Verify and store credential
     */
    function registerVerify( event, rc, prc ) {
        var user = auth.getUser()

        // Verify response
        var verification = passkeyService.verifyRegistrationResponse(
            response: rc,
            expectedChallenge: session.passkeyChallenge,
            expectedOrigin: getSystemSetting( "APP_URL" ),
            expectedRPID: "myapp.com"
        )

        if ( !verification.verified ) {
            return event.renderData(
                type: "json",
                data: {
                    error: "Verification failed"
                },
                statusCode: 400
            )
        }

        // Store credential
        passkeyService.storeCredential(
            userID: user.id,
            credentialID: verification.credentialID,
            credentialPublicKey: verification.publicKey,
            counter: verification.counter,
            transports: rc.transports ?: []
        )

        // Clear challenge
        structDelete( session, "passkeyChallenge" )

        return event.renderData(
            type: "json",
            data: {
                success: true,
                message: "Passkey registered successfully"
            }
        )
    }
}
```

### Registration View

```html
<!-- views/passkeys/register.cfm -->
<h2>Register Passkey</h2>

<cfif prc.hasPasskeys>
    <p>You have already registered a passkey.</p>
    <button id="addAnotherPasskey">Add Another Passkey</button>
<cfelse>
    <p>Register a passkey for passwordless login.</p>
    <button id="registerPasskey">Register Passkey</button>
</cfif>

<script>
document.getElementById('registerPasskey').addEventListener('click', async () => {
    try {
        // Get registration options from server
        const optionsResponse = await fetch('/passkeys/register/options', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' }
        })

        const options = await optionsResponse.json()

        // Convert challenge and user ID from base64
        options.challenge = base64ToArrayBuffer(options.challenge)
        options.user.id = base64ToArrayBuffer(options.user.id)

        // Create credential
        const credential = await navigator.credentials.create({ publicKey: options })

        // Prepare response for server
        const response = {
            id: credential.id,
            rawId: arrayBufferToBase64(credential.rawId),
            type: credential.type,
            response: {
                attestationObject: arrayBufferToBase64(credential.response.attestationObject),
                clientDataJSON: arrayBufferToBase64(credential.response.clientDataJSON)
            }
        }

        // Send to server for verification
        const verifyResponse = await fetch('/passkeys/register/verify', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(response)
        })

        const result = await verifyResponse.json()

        if (result.success) {
            alert('Passkey registered successfully!')
            location.reload()
        }

    } catch (error) {
        console.error('Registration failed:', error)
        alert('Passkey registration failed')
    }
})

// Helper functions
function base64ToArrayBuffer(base64) {
    const binaryString = atob(base64)
    const bytes = new Uint8Array(binaryString.length)
    for (let i = 0; i < binaryString.length; i++) {
        bytes[i] = binaryString.charCodeAt(i)
    }
    return bytes.buffer
}

function arrayBufferToBase64(buffer) {
    const bytes = new Uint8Array(buffer)
    let binary = ''
    for (let i = 0; i < bytes.byteLength; i++) {
        binary += String.fromCharCode(bytes[i])
    }
    return btoa(binary)
}
</script>
```

## Authentication Flow

### Authentication Handler

```boxlang
/**
 * Passkey authentication
 */
class extends="coldbox.system.EventHandler" {

    property name="passkeyService" inject="PasskeyService@cbsecurity-passkeys"
    property name="auth" inject="authenticationService@cbauth"

    /**
     * POST /passkeys/auth/options
     * Generate authentication options
     */
    function authOptions( event, rc, prc ) secured="none" {
        // Generate challenge
        var options = passkeyService.generateAuthenticationOptions()

        // Store challenge
        session.passkeyChallenge = options.challenge

        return event.renderData(
            type: "json",
            data: options
        )
    }

    /**
     * POST /passkeys/auth/verify
     * Verify authentication response
     */
    function authVerify( event, rc, prc ) secured="none" {
        // Get stored credential
        var credential = passkeyService.getCredential( rc.id )

        if ( isNull( credential ) ) {
            return event.renderData(
                type: "json",
                data: {
                    error: "Invalid credential"
                },
                statusCode: 400
            )
        }

        // Verify response
        var verification = passkeyService.verifyAuthenticationResponse(
            response: rc,
            expectedChallenge: session.passkeyChallenge,
            credentialPublicKey: credential.publicKey,
            storedCounter: credential.counter
        )

        if ( !verification.verified ) {
            return event.renderData(
                type: "json",
                data: {
                    error: "Authentication failed"
                },
                statusCode: 401
            )
        }

        // Update counter
        passkeyService.updateCounter(
            credentialID: rc.id,
            counter: verification.counter
        )

        // Login user
        var user = userService.find( credential.userID )
        auth.login( user )

        // Clear challenge
        structDelete( session, "passkeyChallenge" )

        return event.renderData(
            type: "json",
            data: {
                success: true,
                message: "Authentication successful"
            }
        )
    }
}
```

## Credential Management

### Passkey Storage Service

```boxlang
/**
 * models/PasskeyStorageService.cfc
 */
class singleton {

    /**
     * Store passkey credential
     */
    function storeCredential(
        required userID,
        required credentialID,
        required credentialPublicKey,
        required counter,
        transports = []
    ) {
        queryExecute(
            "INSERT INTO passkeys (user_id, credential_id, public_key, counter, transports, created_at)
             VALUES (:userID, :credentialID, :publicKey, :counter, :transports, :now)",
            {
                userID: arguments.userID,
                credentialID: arguments.credentialID,
                publicKey: arguments.credentialPublicKey,
                counter: arguments.counter,
                transports: serializeJSON( arguments.transports ),
                now: now()
            }
        )
    }

    /**
     * Get credential by ID
     */
    function getCredential( required credentialID ) {
        var result = queryExecute(
            "SELECT * FROM passkeys WHERE credential_id = :id",
            { id: arguments.credentialID }
        )

        if ( result.recordCount == 0 ) {
            return
        }

        return {
            id: result.id,
            userID: result.user_id,
            credentialID: result.credential_id,
            publicKey: result.public_key,
            counter: result.counter,
            transports: deserializeJSON( result.transports )
        }
    }

    /**
     * Get user's passkeys
     */
    function getUserPasskeys( required userID ) {
        return queryExecute(
            "SELECT * FROM passkeys WHERE user_id = :userID ORDER BY created_at DESC",
            { userID: arguments.userID }
        )
    }

    /**
     * Delete passkey
     */
    function deletePasskey( required id, required userID ) {
        queryExecute(
            "DELETE FROM passkeys WHERE id = :id AND user_id = :userID",
            {
                id: arguments.id,
                userID: arguments.userID
            }
        )
    }

    /**
     * Update counter (prevents replay attacks)
     */
    function updateCounter( required credentialID, required counter ) {
        queryExecute(
            "UPDATE passkeys SET counter = :counter, last_used = :now
             WHERE credential_id = :id",
            {
                id: arguments.credentialID,
                counter: arguments.counter,
                now: now()
            }
        )
    }
}
```

## Advanced Patterns

### Conditional UI

```boxlang
/**
 * Show passkey option if available
 */
function loginOptions( event, rc, prc ) secured="none" {
    // Check if browser supports WebAuthn
    prc.supportsPasskeys = true  // Detect on client

    // Check if user has registered passkeys
    if ( rc.keyExists( "email" ) ) {
        var user = userService.findByEmail( rc.email )

        if ( !isNull( user ) ) {
            prc.hasPasskeys = passkeyService.hasPasskeys( user.id )
        }
    }

    event.setView( "sessions/new" )
}
```

### Passkey + Password Fallback

```boxlang
/**
 * Hybrid authentication
 */
function login( event, rc, prc ) secured="none" {
    // Passkey authentication
    if ( rc.keyExists( "passkeyResponse" ) ) {
        return passkeyAuthentication( event, rc, prc )
    }

    // Password authentication
    try {
        auth.authenticate( rc.email, rc.password )
        relocate( "main.dashboard" )

    } catch ( InvalidCredentials e ) {
        messagebox.error( "Invalid credentials" )
        relocate( "sessions.new" )
    }
}
```

### Step-Up Authentication

```boxlang
/**
 * Require passkey for sensitive operations
 */
function sensitiveAction( event, rc, prc ) {
    // Check if recently authenticated with passkey
    if ( !session.keyExists( "passkeyVerified" ) ||
         dateDiff( "n", session.passkeyVerifiedAt, now() ) > 5 ) {

        session.returnTo = event.getCurrentEvent()
        relocate( "passkeys.verify" )
    }

    // Proceed with sensitive action
    performSensitiveAction()
}
```

## Best Practices

### Design Guidelines

1. **HTTPS Required**: WebAuthn requires secure context
2. **Progressive Enhancement**: Fallback to passwords
3. **Clear UI**: Explain passkey benefits
4. **Multiple Passkeys**: Allow multiple devices
5. **Credential Management**: Let users manage passkeys
6. **Counter Validation**: Prevent replay attacks
7. **Error Handling**: Clear error messages
8. **Browser Support**: Check WebAuthn availability
9. **Audit Trail**: Log passkey usage
10. **Recovery Options**: Provide alternatives

### Common Patterns

```boxlang
// ✅ Good: Check counter to prevent replay
if ( verification.counter <= storedCounter ) {
    throw( "Counter mismatch - possible replay attack" )
}

// ✅ Good: Validate origin
if ( origin != expectedOrigin ) {
    throw( "Origin mismatch" )
}

// ✅ Good: Store challenge in session
session.passkeyChallenge = options.challenge
```

## Common Pitfalls

### Pitfalls to Avoid

1. **No HTTPS**: WebAuthn requires SSL
2. **Ignoring Counter**: Not validating counter
3. **No Fallback**: Only passkeys, no alternative
4. **Poor UX**: Confusing passkey flow
5. **Missing Browser Check**: Not checking support
6. **No Recovery**: Users locked out
7. **Weak Challenge**: Predictable challenges
8. **Origin Mismatch**: Wrong origin validation
9. **No Rate Limiting**: Brute force attempts
10. **No Audit Trail**: Not logging attempts

### Anti-Patterns

```boxlang
// ❌ Bad: HTTP endpoint
// passkeys.register - WebAuthn requires HTTPS!

// ✅ Good: HTTPS only
// https://myapp.com/passkeys/register

// ❌ Bad: Not checking counter
passkeyService.verify( response )

// ✅ Good: Validate counter
if ( verification.counter <= storedCounter ) {
    throw( "Replay attack detected" )
}

// ❌ Bad: No fallback
// Only passkeys - users can't login if device lost

// ✅ Good: Multiple options
// Passkeys + Password + Recovery codes
```

## Related Skills

- [Authentication Patterns](authentication.md) - User authentication
- [CBSecurity Implementation](security-implementation.md) - Security framework
- [JWT Development](jwt-development.md) - Token authentication

## References

- [WebAuthn Guide](https://webauthn.guide/)
- [WebAuthn Spec](https://www.w3.org/TR/webauthn/)
- [FIDO Alliance](https://fidoalliance.org/)
- [CBSecurity Passkeys](https://forgebox.io/view/cbsecurity-passkeys)
