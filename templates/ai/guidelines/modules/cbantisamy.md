---
title: CBAntiSamy - XSS Prevention Library
description: XSS prevention library with HTML sanitization and security policy enforcement
---

# CBAntiSamy - XSS Prevention Library

> **Module**: cbantisamy
> **Category**: Security
> **Purpose**: Provides HTML/XML sanitization to prevent Cross-Site Scripting (XSS) attacks using OWASP AntiSamy

## Overview

CBAntiSamy is a ColdBox module that wraps the OWASP AntiSamy library to provide robust HTML and XML sanitization. It filters malicious content while preserving safe markup, making it ideal for applications that accept user-generated HTML content.

## Core Features

- HTML/XML sanitization using OWASP AntiSamy
- Multiple pre-configured security policies
- Custom policy definition support
- Fluent API for easy sanitization
- Safe HTML fragment handling
- Whitelist-based filtering
- XSS attack prevention
- Integration with ColdBox validation

## Installation

```bash
box install cbantisamy
```

## Configuration

```javascript
// config/ColdBox.cfc - moduleSettings
moduleSettings = {
    cbantisamy: {
        // Default policy: strict, relaxed, slashdot, ebay, myspace
        defaultPolicy: "relaxed",

        // Path to custom policy files
        policyPath: "/config/antisamy/",

        // Enable validation integration
        validationIntegration: true
    }
};
```

## Usage Patterns

### Basic Sanitization

```javascript
component {
    property name="antiSamy" inject="AntiSamy@cbantisamy";

    function saveContent( event, rc, prc ) {
        // Sanitize user input
        var cleanHTML = antiSamy.clean( rc.content ?: "" );

        // Save sanitized content
        contentService.save( cleanHTML );
    }

    // Using different policy
    function saveComment( event, rc, prc ) {
        var cleanComment = antiSamy
            .withPolicy( "strict" )
            .clean( rc.comment ?: "" );

        commentService.save( cleanComment );
    }
}
```

### Available Policies

```javascript
// Strict - Very restrictive, minimal HTML
var clean = antiSamy.withPolicy( "strict" ).clean( dirtyHTML );

// Relaxed - Moderate restrictions, common HTML tags
var clean = antiSamy.withPolicy( "relaxed" ).clean( dirtyHTML );

// Slashdot - Similar to Slashdot.org content
var clean = antiSamy.withPolicy( "slashdot" ).clean( dirtyHTML );

// eBay - Similar to eBay listing descriptions
var clean = antiSamy.withPolicy( "ebay" ).clean( dirtyHTML );

// MySpace - Similar to MySpace profile content
var clean = antiSamy.withPolicy( "myspace" ).clean( dirtyHTML );
```

### Custom Policy

```xml
<!-- /config/antisamy/custom-policy.xml -->
<?xml version="1.0"?>
<anti-samy-rules xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">

    <!-- Directives -->
    <directives>
        <directive name="omitXmlDeclaration" value="true"/>
        <directive name="omitDoctypeDeclaration" value="true"/>
        <directive name="maxInputSize" value="200000"/>
    </directives>

    <!-- Common attributes allowed on all tags -->
    <common-attributes>
        <attribute name="id">
            <regexp-list>
                <regexp name="anything"/>
            </regexp-list>
        </attribute>
        <attribute name="class">
            <regexp-list>
                <regexp name="anything"/>
            </regexp-list>
        </attribute>
    </common-attributes>

    <!-- Allowed tags and their attributes -->
    <tag-rules>
        <tag name="p" action="validate"/>
        <tag name="div" action="validate"/>
        <tag name="span" action="validate"/>

        <tag name="a" action="validate">
            <attribute name="href">
                <regexp-list>
                    <regexp name="onsiteURL"/>
                    <regexp name="offsiteURL"/>
                </regexp-list>
            </attribute>
            <attribute name="target">
                <literal-list>
                    <literal value="_blank"/>
                    <literal value="_self"/>
                </literal-list>
            </attribute>
        </tag>

        <tag name="img" action="validate">
            <attribute name="src">
                <regexp-list>
                    <regexp name="onsiteURL"/>
                    <regexp name="offsiteURL"/>
                </regexp-list>
            </attribute>
            <attribute name="alt"/>
        </tag>
    </tag-rules>

    <!-- Regular expressions -->
    <common-regexps>
        <regexp name="anything" value=".*"/>
        <regexp name="onsiteURL" value="^/.*"/>
        <regexp name="offsiteURL" value="^https?://.*"/>
    </common-regexps>

</anti-samy-rules>
```

```javascript
// Use custom policy
var clean = antiSamy
    .withPolicy( "custom-policy" )
    .clean( dirtyHTML );
```

### Validation Integration

```javascript
// In model
component accessors="true" {
    property name="content" validates="antiSamy";
    property name="comment" validates="antiSamy:strict";

    // Or with custom message
    property name="bio"
        validates="antiSamy:relaxed"
        validationMessage="Bio contains unsafe HTML content";
}

// Programmatic validation
var result = validate(
    target = model,
    constraints = {
        content: { antiSamy: { policy: "relaxed" } }
    }
);
```

### Fluent API

```javascript
// Chain multiple operations
var result = antiSamy
    .withPolicy( "strict" )
    .withMaxInputSize( 100000 )
    .clean( dirtyHTML );

// Get detailed scan results
var scanResult = antiSamy
    .withPolicy( "relaxed" )
    .scan( dirtyHTML );

// Access scan details
if ( scanResult.hasErrors() ) {
    var errors = scanResult.getErrorMessages();
    // Log or handle errors
}

var cleanHTML = scanResult.getCleanHTML();
```

### Fragment vs Document Sanitization

```javascript
// Sanitize HTML fragment (default)
var cleanFragment = antiSamy.clean( "<p>Hello <script>alert('xss')</script></p>" );
// Result: "<p>Hello </p>"

// Sanitize complete HTML document
var cleanDoc = antiSamy
    .asDocument( true )
    .clean( fullHTMLDocument );
```

## Service Methods

```javascript
component {
    property name="antiSamy" inject="AntiSamy@cbantisamy";

    // Clean user-generated content
    function sanitizeUserContent( required string content, string policy = "relaxed" ) {
        return antiSamy
            .withPolicy( arguments.policy )
            .clean( arguments.content );
    }

    // Validate content is safe
    function isContentSafe( required string content ) {
        var result = antiSamy.scan( arguments.content );
        return !result.hasErrors() && result.getNumberOfErrors() == 0;
    }

    // Get detailed validation results
    function validateContent( required string content ) {
        var result = antiSamy.scan( arguments.content );

        return {
            isClean: !result.hasErrors(),
            cleanHTML: result.getCleanHTML(),
            errors: result.getErrorMessages(),
            errorCount: result.getNumberOfErrors()
        };
    }
}
```

## CMS / Rich Text Editor Integration

```javascript
// Sanitize rich text editor output
component {
    property name="antiSamy" inject="AntiSamy@cbantisamy";

    function saveArticle( event, rc, prc ) {
        // TinyMCE, CKEditor, or other WYSIWYG content
        var article = populateModel( "Article" );

        // Sanitize HTML content fields
        article.setContent(
            antiSamy
                .withPolicy( "relaxed" )
                .clean( article.getContent() )
        );

        article.setExcerpt(
            antiSamy
                .withPolicy( "strict" )
                .clean( article.getExcerpt() )
        );

        entitySave( article );
    }
}
```

## Comment System Integration

```javascript
// Sanitize user comments
component {
    property name="antiSamy" inject="AntiSamy@cbantisamy";

    function postComment( event, rc, prc ) {
        var comment = populateModel( "Comment" );

        // Very restrictive policy for comments
        comment.setBody(
            antiSamy
                .withPolicy( "strict" )
                .clean( comment.getBody() )
        );

        // Remove all HTML if in strict mode
        if ( getSetting( "comments" ).strictMode ) {
            comment.setBody(
                reReplace( comment.getBody(), "<[^>]*>", "", "all" )
            );
        }

        commentService.save( comment );
    }
}
```

## Testing

```javascript
describe( "AntiSamy Sanitization", function() {

    beforeEach( function() {
        antiSamy = getInstance( "AntiSamy@cbantisamy" );
    });

    it( "removes script tags", function() {
        var dirty = "<p>Hello</p><script>alert('xss')</script>";
        var clean = antiSamy.clean( dirty );

        expect( clean ).notToInclude( "<script>" );
        expect( clean ).toInclude( "<p>Hello</p>" );
    });

    it( "removes onclick attributes", function() {
        var dirty = '<a href="#" onclick="alert(\'xss\')">Click</a>';
        var clean = antiSamy.clean( dirty );

        expect( clean ).notToInclude( "onclick" );
    });

    it( "allows safe HTML with relaxed policy", function() {
        var safe = "<p>Hello <strong>World</strong></p>";
        var clean = antiSamy
            .withPolicy( "relaxed" )
            .clean( safe );

        expect( clean ).toBe( safe );
    });

    it( "returns scan results", function() {
        var dirty = "<p>Hello<script>bad()</script></p>";
        var result = antiSamy.scan( dirty );

        expect( result.hasErrors() ).toBeTrue();
        expect( result.getNumberOfErrors() ).toBeGT( 0 );
        expect( result.getCleanHTML() ).toInclude( "<p>" );
    });
});
```

## Best Practices

1. **Choose Appropriate Policy**: Use strict policies for untrusted content, relaxed for trusted users
2. **Sanitize at Input**: Clean content when it enters your system, not on output
3. **Store Clean HTML**: Save sanitized content to database
4. **Layer Security**: Combine with other XSS prevention (CSP headers, output encoding)
5. **Validate File Size**: Set maxInputSize to prevent DoS attacks
6. **Custom Policies for Specific Needs**: Create targeted policies for different content types
7. **Test Edge Cases**: Verify sanitization with various XSS attack vectors
8. **Monitor Performance**: AntiSamy can be CPU-intensive on large documents

## Common XSS Vectors Prevented

```javascript
// Script injection
"<script>alert('XSS')</script>"
// Result: ""

// Event handlers
"<img src=x onerror=alert('XSS')>"
// Result: "<img src=\"x\">"

// JavaScript protocol
"<a href='javascript:alert(\"XSS\")'>Click</a>"
// Result: "<a>Click</a>"

// Data URIs
"<img src='data:text/html,<script>alert(\"XSS\")</script>'>"
// Result: ""

// CSS injection
"<div style='background:url(javascript:alert(\"XSS\"))'>content</div>"
// Result: "<div>content</div>"

// Meta refresh
"<meta http-equiv='refresh' content='0;url=javascript:alert(\"XSS\")'>"
// Result: ""
```

## Policy Selection Guide

- **Strict**: Blog comments, user bios, untrusted sources
- **Relaxed**: CMS articles, trusted user content, rich text
- **Slashdot**: Forum posts, discussion boards
- **eBay**: Product descriptions, listings
- **MySpace**: User profiles, social content
- **Custom**: Application-specific requirements

## Performance Considerations

- Sanitization is CPU-intensive for large documents
- Cache sanitized content when possible
- Use async processing for bulk sanitization
- Set appropriate maxInputSize limits
- Consider lazy sanitization for rarely viewed content

## Additional Resources

- [OWASP AntiSamy Project](https://owasp.org/www-project-antisamy/)
- [XSS Prevention Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Cross_Site_Scripting_Prevention_Cheat_Sheet.html)
- [ColdBox Security Guide](https://coldbox.ortusbooks.com)
