---
name: routing-development
description: Configure ColdBox routes, RESTful resources, route groups, and advanced routing patterns
category: coldbox
priority: high
triggers:
  - create routes
  - configure routing
  - route configuration
  - url routing
---

# Routing Development Implementation Pattern

## When to Use This Skill

Use this skill when configuring application routes, setting up RESTful APIs, creating custom URL patterns, or organizing route structures in ColdBox applications.

## Core Concepts

ColdBox Routing:
- Centralized route configuration in config/Router.cfc
- Support for RESTful resource routes
- Route groups for organization
- URL parameters and pattern matching
- Route constraints and validation
- Subdomain routing
- Module-specific routes

## Basic Router Configuration (BoxLang)

```boxlang
/**
 * Router.cfc
 * Application route configuration
 */
class Router extends coldbox.system.web.routing.Router {

    function configure() {
        // Enable full URL rewrites
        setFullRewrites( true )

        // Set base URL (optional)
        setBaseURL( "http://localhost" )

        // Home page
        route( "/" ).to( "Main.index" )

        // Simple routes
        route( "/about" ).to( "Main.about" )
        route( "/contact" ).to( "Main.contact" )
        route( "/pricing" ).to( "Main.pricing" )

        // Route with default action
        route( "/:handler/:action?" ).to( "handler:action" )
    }
}
```

## RESTful Resource Routes (BoxLang)

```boxlang
class Router extends coldbox.system.web.routing.Router {

    function configure() {
        setFullRewrites( true )

        route( "/" ).to( "Main.index" )

        // Full RESTful resource
        // Creates all 7 RESTful routes
        resources( "users" )
        /*
        Generated routes:
        GET     /users          -> users.index
        GET     /users/:id      -> users.show
        GET     /users/new      -> users.new
        POST    /users          -> users.create
        GET     /users/:id/edit -> users.edit
        PUT     /users/:id      -> users.update
        PATCH   /users/:id      -> users.update
        DELETE  /users/:id      -> users.delete
        */

        // Resource with only specific actions
        resources(
            resource = "products",
            only = [ "index", "show" ]
        )

        // Resource excluding actions
        resources(
            resource = "categories",
            except = [ "new", "edit" ]
        )

        // Nested resources
        resources( resource = "posts", handler = "Posts" )
            .resources( resource = "comments", handler = "Posts.Comments" )
        /*
        GET     /posts/:postId/comments          -> posts.comments.index
        POST    /posts/:postId/comments          -> posts.comments.create
        GET     /posts/:postId/comments/:id      -> posts.comments.show
        */

        // API resources (no new/edit forms)
        resources(
            resource = "api/users",
            handler = "api.Users",
            only = [ "index", "show", "create", "update", "delete" ]
        )
    }
}
```

## Route Groups (BoxLang)

```boxlang
class Router extends coldbox.system.web.routing.Router {

    function configure() {
        setFullRewrites( true )

        // Admin routes group
        group( {
            prefix: "/admin",
            handler: "admin"
        }, function( options ){
            route( "/" ).to( "Dashboard.index" )
            route( "/dashboard" ).to( "Dashboard.index" )
            resources( "users" )
            resources( "products" )
            resources( "orders" )
        })

        // API v1 routes group
        group( {
            prefix: "/api/v1",
            handler: "api.v1"
        }, function( options ){
            // Authentication routes
            route( "/login" ).withHandler( "Auth" ).toAction( { POST: "login" } )
            route( "/logout" ).withHandler( "Auth" ).toAction( { POST: "logout" } )
            route( "/refresh" ).withHandler( "Auth" ).toAction( { POST: "refresh" } )

            // Protected resources
            resources( "users" )
            resources( "products" )
            resources( "orders" )
        })

        // API v2 routes group
        group( {
            prefix: "/api/v2",
            handler: "api.v2"
        }, function( options ){
            resources( "users" )
            resources( "products" )
        })

        // Nested groups
        group( { prefix: "/portal" }, function(){
            group( { prefix: "/admin" }, function(){
                route( "/dashboard" ).to( "portal.admin.Dashboard.index" )
            })
        })
    }
}
```

## Routes with Constraints (BoxLang)

```boxlang
class Router extends coldbox.system.web.routing.Router {

    function configure() {
        setFullRewrites( true )

        // Numeric ID constraint
        route( "/users/:id" )
            .withHandler( "Users" )
            .toAction( { GET: "show" } )
            .constraints( { id: "[0-9]+" } )

        // UUID constraint
        route( "/orders/:uuid" )
            .to( "Orders.show" )
            .constraints( { uuid: "[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}" } )

        // Slug constraint
        route( "/blog/:slug" )
            .to( "Blog.show" )
            .constraints( { slug: "[a-z0-9-]+" } )

        // Multiple constraints
        route( "/archive/:year/:month/:day" )
            .to( "Archive.show" )
            .constraints({
                year: "[0-9]{4}",
                month: "[0-9]{2}",
                day: "[0-9]{2}"
            })

        // Year must be between 2000-2099
        route( "/posts/:year" )
            .to( "Posts.byYear" )
            .constraints({ year: "20[0-9]{2}" })
    }
}
```

## HTTP Method-Specific Routes (BoxLang)

```boxlang
class Router extends coldbox.system.web.routing.Router {

    function configure() {
        setFullRewrites( true )

        // GET only
        route( pattern = "/users", target = "Users.index" )
            .withVerbs( "GET" )

        // POST only
        route( pattern = "/users", target = "Users.create" )
            .withVerbs( "POST" )

        // Multiple HTTP methods
        route( pattern = "/users/:id", target = "Users.update" )
            .withVerbs( "PUT,PATCH" )

        // Map different methods to different actions
        route( "/api/products" )
            .withHandler( "api.Products" )
            .toAction({
                GET: "index",
                POST: "create"
            })

        route( "/api/products/:id" )
            .withHandler( "api.Products" )
            .toAction({
                GET: "show",
                PUT: "update",
                PATCH: "update",
                DELETE: "delete"
            })
    }
}
```

## Named Routes (BoxLang)

```boxlang
class Router extends coldbox.system.web.routing.Router {

    function configure() {
        setFullRewrites( true )

        // Named route
        route( "/" )
            .to( "Main.index" )
            .as( "home" )

        route( "/users/:id" )
            .to( "Users.show" )
            .as( "user.show" )

        route( "/blog/:year/:month/:slug" )
            .to( "Blog.show" )
            .as( "blog.post" )
    }
}
```

```html
<!-- Use named routes in views -->
<cfoutput>
<!-- Build link using route name -->
<a href="#event.route( 'home' )#">Home</a>

<!-- Build link with parameters -->
<a href="#event.route( name='user.show', params={ id: 5 } )#">View User</a>

<!-- Build link with multiple parameters -->
<a href="#event.route(
    name = 'blog.post',
    params = {
        year: '2024',
        month: '02',
        slug: 'my-post'
    }
)#">Read Post</a>
</cfoutput>
```

## Optional Route Parameters (BoxLang)

```boxlang
class Router extends coldbox.system.web.routing.Router {

    function configure() {
        setFullRewrites( true )

        // Optional action parameter
        route( "/:handler/:action?" ).to( "handler:action" )

        // Optional page parameter for pagination
        route( "/products/page/:page?" )
            .to( "Products.index" )

        // Multiple optional parameters
        route( "/search/:category?/:tags?" )
            .to( "Search.index" )

        // With defaults
        route( "/api/:version?/:resource" )
            .to( "api.Router.dispatch" )
            .defaults({ version: "v1" })
    }
}
```

## Domain/Subdomain Routing (BoxLang)

```boxlang
class Router extends coldbox.system.web.routing.Router {

    function configure() {
        setFullRewrites( true )

        // Routes for specific domain
        group({
            domain: "api.mysite.com"
        }, function(){
            resources( "users" )
            resources( "products" )
        })

        // Routes with subdomain capture
        group({
            domain: ":account.mysite.com"
        }, function(){
            route( "/" ).to( "Tenant.dashboard" )
            route( "/settings" ).to( "Tenant.settings" )
        })

        // Multiple subdomains
        group({
            domain: ":tenant.:region.mysite.com"
        }, function(){
            route( "/" ).to( "MultiTenant.index" )
        })
    }
}
```

## Route Conditions (BoxLang)

```boxlang
class Router extends coldbox.system.web.routing.Router {

    function configure() {
        setFullRewrites( true )

        // Conditional routing based on environment
        if( getSetting( "environment" ) == "production" ){
            route( "/debug" ).to( "Main.notFound" )
        } else {
            route( "/debug" ).to( "Debug.index" )
        }

        // Feature flag routing
        if( getSetting( "features" ).newDashboard ){
            route( "/dashboard" ).to( "DashboardV2.index" )
        } else {
            route( "/dashboard" ).to( "Dashboard.index" )
        }

        // Mobile routes
        if( rc.isMobile ){
            route( "/" ).to( "Mobile.index" )
        }
    }
}
```

## Module Routes (BoxLang)

```boxlang
// modules/blog/config/Router.cfc
class Router extends coldbox.system.web.routing.Router {

    function configure() {
        // Module routes are automatically prefixed with /blog

        route( "/" ).to( "Main.index" )              // /blog
        route( "/post/:slug" ).to( "Posts.show" )    // /blog/post/:slug
        route( "/category/:name" ).to( "Categories.show" )  // /blog/category/:name

        resources( "posts" )  // /blog/posts/*

        // API routes within module
        group({ prefix: "/api" }, function(){
            resources( "posts" )  // /blog/api/posts/*
        })
    }
}
```

## URL Redirects (BoxLang)

```boxlang
class Router extends coldbox.system.web.routing.Router {

    function configure() {
        setFullRewrites( true )

        // Permanent redirect (301)
        route( "/old-url" )
            .redirect( target="/new-url", statusCode=301 )

        // Temporary redirect (302)
        route( "/temp" )
            .redirect( target="/temporary-location" )

        // Redirect to named route
        route( "/old-home" )
            .redirect( routeName="home", statusCode=301 )

        // Redirect with parameters
        route( "/old-users/:id" )
            .redirect( target="/users/:id", statusCode=301 )

        // Redirect to external URL
        route( "/docs" )
            .redirect( target="https://docs.example.com", statusCode=302 )
    }
}
```

## Route Namespacing (BoxLang)

```boxlang
class Router extends coldbox.system.web.routing.Router {

    function configure() {
        setFullRewrites( true )

        // Admin namespace
        group({
            prefix: "/admin",
            handler: "admin",
            namespace: "admin"
        }, function(){
            resources( "users" )      // maps to admin.Users handler
            resources( "products" )   // maps to admin.Products handler
        })

        // API versioning with namespace
        group({
            prefix: "/api/v1",
            namespace: "api.v1"
        }, function(){
            resources( "users" )      // maps to api.v1.Users handler
        })
    }
}
```

## Advanced Routing Patterns

### Catch-All Routes

```boxlang
class Router extends coldbox.system.web.routing.Router {

    function configure() {
        setFullRewrites( true )

        // Define specific routes first
        route( "/" ).to( "Main.index" )
        resources( "users" )
        resources( "products" )

        // Catch-all route (must be last)
        route( "/:slug*" ).to( "Pages.show" )
    }
}
```

### Custom Route Handlers

```boxlang
class Router extends coldbox.system.web.routing.Router {

    function configure() {
        setFullRewrites( true )

        // Custom route handler function
        route( "/custom/:pattern" ).to( customHandler )
    }

    function customHandler( event, rc, prc ) {
        // Custom logic
        return "Pages.dynamicPage"
    }
}
```

## Testing Routes

```boxlang
class RouterTest extends coldbox.system.testing.BaseTestCase {

    function beforeAll() {
        super.beforeAll()
        setup()
    }

    function run() {
        describe( "Application Routes", function(){

            it( "should route home page", function(){
                var event = execute( route = "/" )
                expect( event.getCurrentHandler() ).toBe( "Main" )
                expect( event.getCurrentAction() ).toBe( "index" )
            })

            it( "should route with parameters", function(){
                var event = execute( route = "/users/5" )
                expect( event.getCurrentHandler() ).toBe( "Users" )
                expect( event.getCurrentAction() ).toBe( "show" )
                expect( event.getValue( "id" ) ).toBe( "5" )
            })

            it( "should handle REST resource routes", function(){
                var event = POST( "/users", { name: "John" } )
                expect( event.getCurrentHandler() ).toBe( "Users" )
                expect( event.getCurrentAction() ).toBe( "create" )
            })

            it( "should redirect old URLs", function(){
                var event = execute( route = "/old-url" )
                expect( event.getValue( "relocate_URI" ) ).toBe( "/new-url" )
            })

            it( "should build named routes", function(){
                var url = event.route( name="user.show", params={ id: 5 } )
                expect( url ).toBe( "/users/5" )
            })
        })
    }
}
```

## Best Practices

1. **Resource Routes First**: Use resource routes for RESTful patterns
2. **Group Related Routes**: Use groups for organization
3. **Name Important Routes**: Name routes for easy URL building
4. **Specific Before General**: Define specific routes before catch-alls
5. **Use Constraints**: Validate route parameters
6. **RESTful Conventions**: Follow REST principles for APIs
7. **Versioning**: Version your APIs from the start
8. **Redirects**: Use 301 for permanent, 302 for temporary
9. **Module Routes**: Keep module routes in module Router.cfc
10. **Test Routes**: Write tests for routing logic

## Common Pitfalls

1. **Wrong Order**: Catch-all routes before specific routes
2. **Missing Verbs**: Not restricting HTTP methods
3. **No Constraints**: Accepting any parameter format
4. **Deep Nesting**: Too many nested groups
5. **Hardcoded URLs**: Not using route names
6. **Missing Redirects**: Old URLs causing 404s
7. **Inconsistent Patterns**: Mixing different URL styles
8. **No API Versioning**: Breaking changes affect all clients
9. **Complex Regex**: Overly complex constraints
10. **Poor Organization**: Unorganized route configuration

## Debugging Routes

```boxlang
// In handler or interceptor
class DebugInterceptor {

    function preProcess( event, interceptData, rc, prc ) {
        writeDump({
            route: event.getCurrentRoute(),
            handler: event.getCurrentHandler(),
            action: event.getCurrentAction(),
            routedURL: event.getCurrentRoutedURL(),
            params: rc
        })
    }
}
```

```bash
# CommandBox route inspector
coldbox route inspect

# List all routes
coldbox route list

# Test a route pattern
coldbox route test /users/5
```

## Related Skills

- `handler-development` - Handler patterns
- `rest-api-development` - RESTful API design
- `module-development` - Module routes
- `event-model` - Event object usage
