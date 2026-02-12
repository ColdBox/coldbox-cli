---
title: CBSSO Single Sign-On Module Guidelines
description: Enterprise SSO integration patterns with CBSSO, including provider setup, token/claim handling, user mapping, and federated authentication workflows.
---

# CBSSO Single Sign-On Module Guidelines

## Overview

CBSSO provides Single Sign-On (SSO) capabilities for ColdBox applications with support for SAML 2.0, OAuth2, and custom SSO providers.

## Installation

```bash
box install cbsso
```

## Configuration

In `config/ColdBox.cfc`:

```boxlang
moduleSettings = {
    cbsso = {
        // SSO Provider
        provider = "SAML@cbsso",
        
        // Provider properties
        properties = {
            entityId = "https://myapp.com",
            ssoUrl = "https://sso.example.com/saml/sso",
            certificate = expandPath( "/config/certs/sso.crt" )
        }
    }
}
```

## Basic Usage

```boxlang
// Inject SSO service
property name="sso" inject="SSOService@cbsso";

// Initiate SSO login
function ssoLogin( event, rc, prc ) {
    sso.redirectToProvider()
}

// Handle SSO callback
function ssoCallback( event, rc, prc ) {
    var user = sso.processCallback( rc )
    auth.login( user )
    relocate( "dashboard" )
}
```

## Documentation

For complete CBSSO documentation, SAML configuration, and OAuth2 setup, visit:
https://github.com/coldbox-modules/cbsso
