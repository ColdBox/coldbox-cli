---
title: CORS Module Guidelines
description: CORS (Cross-Origin Resource Sharing) middleware for API access control
---

# CORS Module Guidelines

## Overview

The CORS module automatically handles Cross-Origin Resource Sharing (CORS) for ColdBox applications. It detects CORS requests, validates them against configured origins, and handles preflight OPTIONS requests.

## Installation

```bash
box install cors
```

## Configuration

In `config/ColdBox.cfc`:

```boxlang
moduleSettings = {
    cors = {
        // Auto-register interceptor (default: true)
        autoRegisterInterceptor = true,
        
        // Allowed origins (function or string/array)
        allowOrigins = "*",
        
        // Allowed HTTP methods
        allowMethods = "GET,POST,PUT,PATCH,DELETE,OPTIONS",
        
        // Allowed headers
        allowHeaders = "Content-Type,Authorization,X-Requested-With",
        
        // Max age for preflight cache (in seconds)
        maxAge = 86400, // 24 hours
        
        // Allow credentials
        allowCredentials = true,
        
        // Event pattern to apply CORS
        eventPattern = ".*"
    }
}
```

## Basic Configurations

### Allow All Origins (Development)

```boxlang
cors = {
    allowOrigins = "*",
    allowMethods = "*",
    allowHeaders = "*"
}
```

### Specific Origins (Production)

```boxlang
cors = {
    allowOrigins = [
        "https://myapp.com",
        "https://www.myapp.com",
        "https://admin.myapp.com"
    ],
    allowMethods = "GET,POST,PUT,PATCH,DELETE,OPTIONS",
    allowHeaders = "Content-Type,Authorization,X-API-Key",
    allowCredentials = true
}
```

### Dynamic Origins

```boxlang
cors = {
    // Function to determine allowed origin
    allowOrigins = ( event ) => {
        var origin = event.getHTTPHeader( "Origin", "" )
        var allowedDomains = [ "myapp.com", "staging.myapp.com" ]
        
        // Check if origin ends with allowed domain
        for ( var domain in allowedDomains ) {
            if ( origin.endsWith( domain ) ) {
                return origin
            }
        }
        
        return ""
    },
    
    allowMethods = ( event ) => {
        // Allow different methods for different routes
        if ( event.getCurrentEvent().findNoCase( "api.admin" ) ) {
            return "GET,POST,PUT,DELETE"
        }
        return "GET,POST"
    },
    
    allowHeaders = ( event ) => {
        var requestHeaders = event.getHTTPHeader( 
            "Access-Control-Request-Headers", 
            "" 
        )
        return requestHeaders
    }
}
```

## Understanding CORS

### What is CORS?

CORS (Cross-Origin Resource Sharing) allows web applications running at one origin to access resources from a different origin. By default, browsers block cross-origin requests for security reasons (Same-Origin Policy).

**Origins are different if they differ in:**
- Protocol (http vs https)
- Domain (example.com vs api.example.com)
- Port (localhost:8080 vs localhost:3000)

### Simple vs Preflight Requests

**Simple Requests** (no preflight needed):
- Methods: GET, HEAD, POST
- Headers: Accept, Accept-Language, Content-Language, Content-Type
- Content-Type: application/x-www-form-urlencoded, multipart/form-data, text/plain

**Preflight Requests** (OPTIONS sent first):
- Methods: PUT, PATCH, DELETE, CONNECT, TRACE
- Custom headers (Authorization, X-API-Key, etc.)
- Content-Type: application/json, application/xml

### Preflight Flow

```
1. Browser sends OPTIONS request with:
   - Origin: https://myapp.com
   - Access-Control-Request-Method: PUT
   - Access-Control-Request-Headers: Content-Type,Authorization

2. Server responds with:
   - Access-Control-Allow-Origin: https://myapp.com
   - Access-Control-Allow-Methods: PUT,POST,GET,DELETE
   - Access-Control-Allow-Headers: Content-Type,Authorization
   - Access-Control-Max-Age: 86400

3. If allowed, browser sends actual PUT request
```

## Common Patterns

### API with CORS

```boxlang
// config/ColdBox.cfc
moduleSettings = {
    cors = {
        allowOrigins = [
            "https://app.example.com",
            "https://admin.example.com"
        ],
        allowMethods = "GET,POST,PUT,PATCH,DELETE,OPTIONS",
        allowHeaders = "Content-Type,Authorization,X-API-Key",
        allowCredentials = true,
        maxAge = 86400
    }
}
```

### Development vs Production

```boxlang
moduleSettings = {
    cors = {
        allowOrigins = getSetting( "environment" ) == "development" 
            ? "*" 
            : getSetting( "allowedOrigins" ),
        allowMethods = "*",
        allowHeaders = "*",
        allowCredentials = true
    }
}
```

### Per-Route CORS

```boxlang
// Apply CORS only to API routes
cors = {
    eventPattern = "^api\\.",
    allowOrigins = "*"
}
```

## Troubleshooting

### CORS Error in Browser Console

```
Access to fetch at 'https://api.example.com/users' from origin 
'https://app.example.com' has been blocked by CORS policy: 
No 'Access-Control-Allow-Origin' header is present.
```

**Solution:** Add origin to `allowOrigins`:

```boxlang
allowOrigins = [ "https://app.example.com" ]
```

### Preflight Request Failing

```
Access-Control-Request-Method: PUT not allowed
```

**Solution:** Add PUT to `allowMethods`:

```boxlang
allowMethods = "GET,POST,PUT,PATCH,DELETE,OPTIONS"
```

### Custom Headers Blocked

```
Request header 'X-API-Key' not allowed
```

**Solution:** Add header to `allowHeaders`:

```boxlang
allowHeaders = "Content-Type,Authorization,X-API-Key"
```

## Best Practices

- **Use specific origins in production** - Never use "*" in production
- **Minimize allowed methods** - Only allow needed HTTP methods
- **List required headers explicitly** - Don't allow all headers
- **Set appropriate maxAge** - Cache preflight responses (86400 = 24hrs)
- **Use HTTPS** - Always use secure protocols
- **Validate credentials** - Be careful with allowCredentials + wildcard origins
- **Apply to API routes only** - Use eventPattern to scope CORS
- **Test with actual clients** - Test CORS from browser

## Documentation

For complete CORS module documentation and advanced configurations, visit:
https://github.com/coldbox-modules/cors
