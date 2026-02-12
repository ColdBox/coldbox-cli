---
title: CBMailServices Module Guidelines
description: Email delivery architecture guidance for cbMailServices, covering provider abstraction, template rendering, transport configuration, queuing/retries, and observability.
---

# CBMailServices Module Guidelines

## Overview

CBMailServices provides object-oriented email services for ColdBox with support for multiple protocols (SMTP, Postmark, SendGrid) and email templating.

## Installation

```bash
box install cbmailservices
```

## Configuration

In `config/ColdBox.cfc`:

```boxlang
moduleSettings = {
    cbmailservices = {
        // Default protocol
        defaultProtocol = "smtp",

        // Token replacements
        tokenMarker = "@",

        // Protocols
        protocols = {
            smtp = {
                class = "cbmailservices.models.protocols.SMTPProtocol",
                properties = {
                    server = "smtp.gmail.com",
                    port = 587,
                    username = getSystemSetting( "SMTP_USER" ),
                    password = getSystemSetting( "SMTP_PASS" ),
                    useTLS = true
                }
            },
            postmark = {
                class = "cbmailservices.models.protocols.PostmarkProtocol",
                properties = {
                    apiKey = getSystemSetting( "POSTMARK_API_KEY" )
                }
            }
        }
    }
}
```

## Basic Usage

```boxlang
// Inject mail service
property name="mailService" inject="MailService@cbmailservices";

// Send email
mailService.newMail(
    to = "[email protected]",
    from = "[email protected]",
    subject = "Welcome!",
    body = "Thanks for signing up",
    type = "html"
).send()

// With attachments
mailService.newMail()
    .setTo( "[email protected]" )
    .setFrom( "[email protected]" )
    .setSubject( "Invoice" )
    .setBody( "Please find attached" )
    .addAttachment( expandPath( "/invoices/invoice.pdf" ) )
    .send()

// Using templates
mailService.newMail()
    .setTo( user.getEmail() )
    .setFrom( "[email protected]" )
    .setSubject( "Welcome @firstName@!" )
    .setBodyTokens( { firstName: user.getFirstName() } )
    .setBodyTemplate( "/emails/welcome" )
    .send()
```

## Documentation

For complete CBMailServices documentation, protocols, and templating, visit:
https://github.com/coldbox-modules/cbmailservices
