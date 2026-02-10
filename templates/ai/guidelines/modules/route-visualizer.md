# Route Visualizer Module Guideline

## Overview

Route Visualizer is a ColdBox development module that provides an interactive visual interface for viewing,testing, and debugging your application's routing tables. It displays all routes in the order they are evaluated, making it easy to understand route precedence, identify conflicts, and test route patterns.

**Benefits:**
- Visual route inspection - see all routes at a glance
- Route testing - test patterns and see matches in real-time
- Debugging tool - identify route conflicts and ordering issues
- Named route visualization - see route names and their patterns
- Development-only - automatically disabled in production

## Installation

```bash
box install route-visualizer --saveDev
```

**Important:** Install as a dev dependency (`--saveDev`) since this is a development tool that should not be deployed to production.

## Usage

Once installed, access the visualizer at:

```
http://localhost:{port}/route-visualizer
```

The interface shows:
- All registered routes in evaluation order
- Route patterns and HTTP methods
- Route names (if named)
- Route metadata (module, handler, action)
- Test form to try routes with different URLs

## Route Visualization Features

### Route Display

The visualizer shows each route with:
- **HTTP Method** - GET, POST, PUT, DELETE, PATCH, etc.
- **Pattern** - The URL pattern (e.g., `/api/users/:id`)
- **Handler** - The handler that processes the route
- **Action** - The action method called
- **Name** - Named route identifier (if set)
- **Module** - Module name (for module routes)

### Route Testing

Enter a URL path in the test form to:
- See which route matches
- View extracted route parameters
- Identify why a route doesn't match
- Test route precedence

**Example Test:**
```
Test URL: /api/users/123
Matches: GET /api/users/:id
Parameters: { id: "123" }
```

### Named Routes

Named routes are highlighted and show:
- Route name
- Full pattern
- How to build URLs: `event.buildLink( "users.show" )`

## Integration with ColdBox Router

### Basic Routes

```javascript
// config/Router.cfc
function configure() {
    route( "/users" ).to( "users.index" )
    route( "/users/:id" ).to( "users.show" )
    route( "/api/users" ).to( "api.users.index" )
}
```

**Visualizer shows:**
- All routes in registration order
- Pattern precedence
- Any conflicts or overlaps

### Named Routes

```javascript
route( "/users/:id" )
    .as( "users.show" )
    .to( "users.show" )

route( "/users/:id/edit" )
    .as( "users.edit" )
    .to( "users.edit" )
```

**Visualizer displays:**
- Route name prominently
- Makes it easy to find routes by name
- Shows all named routes together

### RESTful Resources

```javascript
resources( "users" )
// Creates: index, show, new, create, edit, update, delete
```

**Visualizer expands:**
- All 7 RESTful routes
- Shows method + pattern for each
- Displays generated route names

### Module Routes

```javascript
// Module routes are automatically detected
route( "/admin" )
    .toModuleRouting( "admin-module" )
```

**Visualizer shows:**
- Module name for each route
- Module-specific routes grouped
- Clear distinction between app and module routes

## Best Practices

### Development Workflow

```javascript
// 1. Add routes in Router.cfc
route( "/api/products/:id" ).to( "api.products.show" )

// 2. Open route visualizer
// http://localhost:50000/route-visualizer

// 3. Verify route appears correctly
// 4. Test with sample URLs
// 5. Check for conflicts with existing routes
```

### Route Ordering

The visualizer helps understand route precedence:

```javascript
// ❌ WRONG ORDER - specific route after catch-all
route( "/:handler/:action" )  // Matches everything
route( "/api/users/:id" )     // Never reached!

// ✅ CORRECT ORDER - specific routes first
route( "/api/users/:id" )     // Matches first
route( "/:handler/:action" )  // Fallback
```

**Visualizer shows:**
- Exact evaluation order
- Helps identify unreachable routes
- Makes ordering issues obvious

### Testing Routes

Use the test form to:

```javascript
// Test parameterized routes
Test: /users/123
Matches: /users/:id → { id: "123" }

// Test wildcard routes
Test: /blog/2024/01/my-post
Matches: /blog/:year/:month/:slug → { year: "2024", month: "01", slug: "my-post" }

// Test conflicting patterns
Test: /api/users
Shows: Which route matched and why
```

### Named Route Verification

```javascript
// In Router.cfc
route( "/products/:id" )
    .as( "products.show" )

// Verify in visualizer:
// - Name: products.show
// - Pattern: /products/:id
    
// Use in handlers:
var url = event.buildLink( "products.show", { id: product.getId() } )
```

## Production Safety

Route Visualizer automatically detects environment:

```javascript
// config/ColdBox.cfc
moduleSettings = {
    "route-visualizer" : {
        // Module respects ColdBox environment
        // Only active in development
    }
}
```

**Security Notes:**
- Install as dev dependency only
- Module is disabled in production environment
- No production overhead
- Can be explicitly disabled if needed

## Troubleshooting

### Routes Not Showing

**Check:**
- Module is installed: `box list --dev`
- Routes defined in `config/Router.cfc`
- Framework reinit: `?fwreinit=1`

### Route Not Matching

**Debug:**
1. Check route order in visualizer
2. Test URL in test form
3. Look for more specific routes above
4. Verify HTTP method matches

### Module Routes Missing

**Verify:**
- Module is loaded
- Module has routing configured
- Module is in development mode

## Common Patterns

### API Route Organization

```javascript
// Group API routes
route( "/api" )
    .toNamespaceRouting( "api" )

resources( "api:users" )
resources( "api:products" )

// Visualizer shows:
// - All API routes grouped
// - Clear namespace organization
// - RESTful route expansion
```

### Versioned APIs

```javascript
route( "/api/v1" )
    .toNamespaceRouting( "api.v1" )
    
route( "/api/v2" )
    .toNamespaceRouting( "api.v2" )

// Visualizer displays:
// - Version-specific routes
// - Easy comparison between versions
```

### Catch-All Routes

```javascript
// Specific routes first
route( "/admin/dashboard" ).to( "admin.dashboard" )
route( "/admin/users" ).to( "admin.users.index" )

// Catch-all last
route( "/admin/:page" ).to( "admin.show" )

// Visualizer confirms:
// - Specific routes evaluated first
// - Catch-all at bottom
```

## Integration Tips

**With ColdBox Development:**
- Keep visualizer open during development
- Check after adding new routes
- Test routes before writing handlers
- Verify named routes build correctly

**With RESTful APIs:**
- Visualize all resource routes
- Verify HTTP methods are correct
- Test parameterized API endpoints
- Check API versioning routes

**With Modules:**
- See module route isolation
- Verify module routing patterns
- Check cross-module route conflicts

**Route Documentation:**
- Use visualizer as documentation
- Screenshot for team reference
- Validate route naming conventions

## Tips & Tricks

### Find Route by Name

Use browser search (Cmd+F / Ctrl+F) to find named routes quickly

### Test Complex Patterns

Test wildcards and regex patterns:
```
Pattern: /blog/:yyyy/:mm/:slug
Test: /blog/2024/01/my-post
Result: { yyyy: "2024", mm: "01", slug: "my-post" }
```

### Route Conflict Detection

If routes seem to conflict:
1. Note the order in visualizer
2. Test both URLs
3. Move more specific route up
4. Reinit and verify

### Quick Route Testing

Keep visualizer open in separate tab during development for instant route testing

## Module Information

- **Repository:** github.com/coldbox-modules/route-visualizer
- **ForgeBox:** forgebox.io/view/route-visualizer
- **Issues:** github.com/coldbox-modules/route-visualizer/issues
- **Requirements:** BoxLang 1+, Lucee 5+, Adobe ColdFusion 2021+
