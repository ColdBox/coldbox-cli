---
name: SSO Integration
description: Complete guide to Single Sign-On (SSO) with CBSSO, OAuth2, SAML, OpenID Connect, and social authentication providers
category: security
priority: high
triggers:
  - sso
  - single sign-on
  - oauth
  - oauth2
  - saml
  - openid connect
  - social login
---

# SSO Integration

## Overview

CBSingle Sign-On (CBSSO) provides OAuth2, SAML, and OpenID Connect integration for enterprise SSO and social authentication. SSO enables users to authenticate once and access multiple applications.

## Core Concepts

### SSO Architecture

- **Identity Provider (IdP)**: Authentication service (Google, Azure AD, Okta)
- **Service Provider (SP)**: Your ColdBox application
- **OAuth2**: Authorization framework
- **SAML**: XML-based SSO protocol
- **OpenID Connect**: Identity layer on OAuth2
- **Social Providers**: Google, Facebook, GitHub, etc.

## Installation & Setup

### Install CBSSO

```bash
box install cbsso
```

### Configuration

```boxlang
/**
 * config/ColdBox.cfc
 */
class {

    function configure() {
        moduleSettings = {
            cbsso: {
                // Providers
                providers: {
                    // Google OAuth2
                    google: {
                        clientID: getSystemSetting( "GOOGLE_CLIENT_ID" ),
                        clientSecret: getSystemSetting( "GOOGLE_CLIENT_SECRET" ),
                        redirectURI: "https://myapp.com/sso/google/callback",
                        scope: "email profile"
                    },

                    // Azure AD / Microsoft
                    azure: {
                        clientID: getSystemSetting( "AZURE_CLIENT_ID" ),
                        clientSecret: getSystemSetting( "AZURE_CLIENT_SECRET" ),
                        tenant: getSystemSetting( "AZURE_TENANT_ID" ),
                        redirectURI: "https://myapp.com/sso/azure/callback"
                    },

                    // Okta
                    okta: {
                        domain: getSystemSetting( "OKTA_DOMAIN" ),
                        clientID: getSystemSetting( "OKTA_CLIENT_ID" ),
                        clientSecret: getSystemSetting( "OKTA_CLIENT_SECRET" ),
                        redirectURI: "https://myapp.com/sso/okta/callback"
                    }
                },

                // User provider service
                userProvider: "SSOUserProvider@models"
            }
        }
    }
}
```

## OAuth2 Integration

### OAuth2 Handler

```boxlang
/**
 * handlers/SSO.cfc
 */
class extends="coldbox.system.EventHandler" {

    property name="ssoService" inject="SSOService@cbsso"
    property name="auth" inject="authenticationService@cbauth"
    property name="userService" inject="UserService"

    /**
     * GET /sso/google
     * Redirect to Google OAuth
     */
    function google( event, rc, prc ) secured="none" {
        var authURL = ssoService.getAuthorizationURL( "google" )

        relocate( url: authURL, ssl: true )
    }

    /**
     * GET /sso/google/callback
     * Handle OAuth callback
     */
    function googleCallback( event, rc, prc ) secured="none" {
        // Exchange code for tokens
        var tokenResponse = ssoService.exchangeCode(
            provider: "google",
            code: rc.code
        )

        // Get user profile
        var profile = ssoService.getUserProfile(
            provider: "google",
            accessToken: tokenResponse.access_token
        )

        // Find or create user
        var user = findOrCreateUser( "google", profile )

        // Login user
        auth.login( user )

        relocate( "main.dashboard" )
    }

    /**
     * Find or create user from SSO profile
     */
    private function findOrCreateUser( provider, profile ) {
        var user = userService.findByProvider( provider, profile.id )

        if ( !isNull( user ) ) {
            return user
        }

        // Create new user
        return userService.createFromSSO( provider, profile )
    }
}
```

## Social Authentication

### Multiple Providers

```boxlang
/**
 * Social login with multiple providers
 */
class extends="coldbox.system.EventHandler" {

    property name="ssoService" inject="SSOService@cbsso"
    property name="auth" inject="authenticationService@cbauth"

    /**
     * POST /sso/:provider
     * Generic SSO redirect
     */
    function redirect( event, rc, prc ) secured="none" {
        var provider = rc.provider

        // Validate provider
        if ( !isValidProvider( provider ) ) {
            throw( "Invalid SSO provider" )
        }

        var authURL = ssoService.getAuthorizationURL( provider )

        relocate( url: authURL, ssl: true )
    }

    /**
     * GET /sso/:provider/callback
     * Generic OAuth callback
     */
    function callback( event, rc, prc ) secured="none" {
        var provider = rc.provider

        try {
            // Exchange code
            var tokenResponse = ssoService.exchangeCode(
                provider: provider,
                code: rc.code
            )

            // Get profile
            var profile = ssoService.getUserProfile(
                provider: provider,
                accessToken: tokenResponse.access_token
            )

            // Find or create user
            var user = userService.findOrCreateSSOUser(
                provider: provider,
                profile: profile
            )

            // Login
            auth.login( user )

            relocate( rc._returnTo ?: "main.dashboard" )

        } catch ( any e ) {
            log.error( "SSO failed: #e.message#", e )

            messagebox.error( "SSO authentication failed" )
            relocate( "sessions.new" )
        }
    }

    private function isValidProvider( provider ) {
        return [ "google", "github", "azure", "okta" ].contains( provider )
    }
}
```

## User Provider Service

### SSO User Management

```boxlang
/**
 * models/SSOUserProvider.cfc
 */
class singleton {

    property name="userService" inject="UserService"

    /**
     * Find user by SSO provider
     */
    function findByProvider( required provider, required providerID ) {
        return queryExecute(
            "SELECT * FROM users WHERE sso_provider = :provider AND sso_provider_id = :id",
            {
                provider: arguments.provider,
                id: arguments.providerID
            }
        ).reduce( convertToUser )
    }

    /**
     * Create user from SSO profile
     */
    function createFromSSO( required provider, required profile ) {
        queryExecute(
            "INSERT INTO users (email, name, sso_provider, sso_provider_id)
             VALUES (:email, :name, :provider, :providerID)",
            {
                email: profile.email,
                name: profile.name,
                provider: arguments.provider,
                providerID: profile.id
            }
        )

        return findByProvider( arguments.provider, profile.id )
    }

    /**
     * Link SSO provider to existing user
     */
    function linkProvider( required userID, required provider, required providerID ) {
        queryExecute(
            "UPDATE users SET sso_provider = :provider, sso_provider_id = :providerID
             WHERE id = :userID",
            {
                userID: arguments.userID,
                provider: arguments.provider,
                providerID: arguments.providerID
            }
        )
    }
}
```

## SAML Integration

### SAML Configuration

```boxlang
moduleSettings = {
    cbsso: {
        saml: {
            // Service provider settings
            sp: {
                entityID: "https://myapp.com",
                assertionConsumerService: "https://myapp.com/sso/saml/acs",
                singleLogoutService: "https://myapp.com/sso/saml/sls"
            },

            // Identity provider settings
            idp: {
                entityID: getSystemSetting( "SAML_IDP_ENTITY_ID" ),
                singleSignOnService: getSystemSetting( "SAML_IDP_SSO_URL" ),
                singleLogoutService: getSystemSetting( "SAML_IDP_SLO_URL" ),
                x509cert: getSystemSetting( "SAML_IDP_CERT" )
            },

            // Security settings
            security: {
                signMetadata: true,
                signAuthRequests: true,
                signLogoutRequest: true,
                wantAssertionsSigned: true
            }
        }
    }
}
```

## Advanced Patterns

### Account Linking

```boxlang
/**
 * Link SSO provider to existing account
 */
class extends="coldbox.system.EventHandler" {

    property name="auth" inject="authenticationService@cbauth"
    property name="ssoService" inject="SSOService@cbsso"

    function linkProvider( event, rc, prc ) {
        var provider = rc.provider

        // Redirect to OAuth
        var authURL = ssoService.getAuthorizationURL( provider )

        // Store intent in session
        session.linkingProvider = provider

        relocate( url: authURL, ssl: true )
    }

    function linkCallback( event, rc, prc ) {
        if ( !session.keyExists( "linkingProvider" ) ) {
            throw( "Invalid state" )
        }

        var provider = session.linkingProvider

        // Exchange code
        var tokenResponse = ssoService.exchangeCode( provider, rc.code )

        // Get profile
        var profile = ssoService.getUserProfile( provider, tokenResponse.access_token )

        // Link to current user
        var user = auth.getUser()
        userService.linkProvider( user.id, provider, profile.id )

        structDelete( session, "linkingProvider" )

        messagebox.success( "#provider# account linked successfully" )
        relocate( "users.settings" )
    }
}
```

### SSO + Local Authentication

```boxlang
/**
 * Hybrid authentication (SSO or local)
 */
function login( event, rc, prc ) secured="none" {
    // SSO login
    if ( rc.keyExists( "provider" ) ) {
        var authURL = ssoService.getAuthorizationURL( rc.provider )
        relocate( url: authURL, ssl: true )
    }

    // Local login
    try {
        auth.authenticate( rc.email, rc.password )
        relocate( "main.dashboard" )

    } catch ( InvalidCredentials e ) {
        messagebox.error( "Invalid credentials" )
        relocate( "sessions.new" )
    }
}
```

## Best Practices

### Design Guidelines

1. **HTTPS Only**: Always use HTTPS
2. **State Parameter**: Prevent CSRF attacks
3. **Token Security**: Store tokens securely
4. **Email Verification**: Verify email from SSO
5. **Account Linking**: Allow linking multiple providers
6. **Graceful Degradation**: Fall back to local auth
7. **Error Handling**: Clear error messages
8. **Audit Trail**: Log SSO events
9. **Token Refresh**: Handle expired tokens
10. **Provider Validation**: Validate SSO providers

### Common Patterns

```boxlang
// ✅ Good: Validate provider
if ( !isValidProvider( provider ) ) {
    throw( "Invalid provider" )
}

// ✅ Good: Handle errors
try {
    var profile = ssoService.getUserProfile( provider, token )
} catch ( any e ) {
    log.error( "SSO failed", e )
    relocate( "sessions.new" )
}

// ✅ Good: Store state
session.ssoState = createUUID()
```

## Common Pitfalls

### Pitfalls to Avoid

1. **No State Validation**: CSRF vulnerabilities
2. **Insecure Storage**: Storing tokens insecurely
3. **No Error Handling**: Exposing SSO errors
4. **No Email Verification**: Trusting SSO emails
5. **Account Hijacking**: Not preventing account takeover
6. **No HTTPS**: HTTP connections
7. **Hardcoded Secrets**: Secrets in code
8. **No Timeout**: Tokens never expire
9. **Missing Scopes**: Not requesting needed data
10. **No Audit Trail**: Not logging SSO events

### Anti-Patterns

```boxlang
// ❌ Bad: No state validation
var profile = ssoService.getUserProfile( provider, rc.code )

// ✅ Good: Validate state
if ( rc.state != session.ssoState ) {
    throw( "Invalid state" )
}

// ❌ Bad: Trusting email without verification
user.emailVerified = true

// ✅ Good: Check verification from provider
user.emailVerified = profile.email_verified
```

## Related Skills

- [Authentication Patterns](authentication.md) - User authentication
- [CBSecurity Implementation](security-implementation.md) - Security framework
- [JWT Development](jwt-development.md) - JWT tokens

## References

- [CBSSO Documentation](https://forgebox.io/view/cbsso)
- [OAuth 2.0](https://oauth.net/2/)
- [OpenID Connect](https://openid.net/connect/)
- [SAML](http://docs.oasis-open.org/security/saml/)
