---
name: layout-development
description: Create and manage ColdBox layouts and views with proper rendering, helpers, and dynamic content
category: coldbox
priority: medium
triggers:
  - create layout
  - build layout
  - view layout
  - master page
---

# Layout Development Implementation Pattern

## When to Use This Skill

Use this skill when creating application layouts, master pages, view templates, and organizing the visual structure of ColdBox applications.

## Core Concepts

ColdBox Layouts and Views:
- Layouts are master page templates that wrap views
- Views contain page-specific content
- Supports layout nesting and composition
- Views can render other views (partials/widgets)
- Both support helper functions and view conventions
- Can be module-specific or application-wide

## Basic Layout Structure (BoxLang)

```html
<!--
layouts/Main.cfm
Default application layout
-->
<cfoutput>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>#prc.pageTitle ?: "My Application"#</title>

    <!-- CSS -->
    <link rel="stylesheet" href="/css/app.css">
    <!-- addAsset with sendToHeader=true (default) injects <link>/<script> into <head> via cfhtmlhead -->
    #html.addAsset( "/css/custom.css" )#
    <!-- addAsset with sendToHeader=false outputs the tag inline at the call site instead -->
    #html.addAsset( asset="/css/inline.css", sendToHeader=false )#
</head>
<body>
    <!-- Header -->
    #renderView( "partials/header" )#

    <!-- Flash messages -->
    #renderView( "partials/messages" )#

    <!-- Main content area -->
    <main class="container">
        #renderView()#
    </main>

    <!-- Footer -->
    #renderView( "partials/footer" )#

    <!-- JavaScript -->
    <script src="/js/app.js"></script>
    #html.addAsset( "/js/custom.js" )#
</body>
</html>
</cfoutput>
```

## Admin Layout (BoxLang)

```html
<!--
layouts/Admin.cfm
Admin-specific layout
-->
<cfoutput>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>#prc.pageTitle ?: "Admin Dashboard"# - Admin</title>
    <link rel="stylesheet" href="/css/admin.css">
    <!-- addAsset injects <link> into <head> automatically via cfhtmlhead (sendToHeader=true by default) -->
    #html.addAsset( "/css/admin-extra.css" )#
</head>
<body class="admin-layout">
    <!-- Admin Header -->
    <header class="admin-header">
        <nav>
            <ul>
                <li><a href="#event.buildLink( 'admin.dashboard' )#">Dashboard</a></li>
                <li><a href="#event.buildLink( 'admin.users' )#">Users</a></li>
                <li><a href="#event.buildLink( 'admin.settings' )#">Settings</a></li>
                <li><a href="#event.buildLink( 'security.logout' )#">Logout</a></li>
            </ul>
        </nav>
        <div class="user-info">
            Logged in as: #prc.user.getName()#
        </div>
    </header>

    <!-- Sidebar -->
    <aside class="admin-sidebar">
        #renderView( "admin/partials/sidebar" )#
    </aside>

    <!-- Main Content -->
    <main class="admin-content">
        <!-- Breadcrumbs -->
        <nav class="breadcrumbs">
            #renderView( "partials/breadcrumbs" )#
        </nav>

        <!-- Flash Messages -->
        #renderView( "partials/messages" )#

        <!-- View Content -->
        <div class="content-wrapper">
            #renderView()#
        </div>
    </main>

    <script src="/js/admin.js"></script>
    #html.addAsset( "/js/admin-extra.js" )#
</body>
</html>
</cfoutput>
```

## Simple View (BoxLang)

```html
<!--
views/users/index.cfm
List users view
-->
<cfoutput>
<div class="users-list">
    <h1>#prc.pageTitle#</h1>

    <div class="actions">
        <a href="#event.buildLink( 'users.create' )#" class="btn btn-primary">
            Add New User
        </a>
    </div>

    <table class="table">
        <thead>
            <tr>
                <th>Name</th>
                <th>Email</th>
                <th>Created</th>
                <th>Actions</th>
            </tr>
        </thead>
        <tbody>
            <cfloop array="#prc.users#" index="user">
                <tr>
                    <td>#user.getFullName()#</td>
                    <td>#user.getEmail()#</td>
                    <td>#dateFormat( user.getCreatedDate(), "mm/dd/yyyy" )#</td>
                    <td>
                        <a href="#event.buildLink( 'users.edit' )#?id=#user.getId()#">Edit</a>
                        <a href="#event.buildLink( 'users.delete' )#?id=#user.getId()#" onclick="return confirm('Are you sure?')">Delete</a>
                    </td>
                </tr>
            </cfloop>
        </tbody>
    </table>
</div>
</cfoutput>
```

## View with Form (BoxLang)

```html
<!--
views/users/create.cfm
Create user form
-->
<cfoutput>
<div class="user-form">
    <h1>Create New User</h1>

    <!-- Display validation errors -->
    <cfif flash.exists( "errors" )>
        <div class="alert alert-danger">
            <ul>
                <cfloop array="#flash.get( 'errors' )#" index="error">
                    <li>#error.message#</li>
                </cfloop>
            </ul>
        </div>
    </cfif>

    <form method="POST" action="#event.buildLink( 'users.store' )#">
        <!-- CSRF token -->
        #csrf()#

        <div class="form-group">
            <label for="firstName">First Name</label>
            <input
                type="text"
                name="firstName"
                id="firstName"
                value="#flash.get( 'data.firstName', '' )#"
                class="form-control"
                required
            >
        </div>

        <div class="form-group">
            <label for="lastName">Last Name</label>
            <input
                type="text"
                name="lastName"
                id="lastName"
                value="#flash.get( 'data.lastName', '' )#"
                class="form-control"
                required
            >
        </div>

        <div class="form-group">
            <label for="email">Email</label>
            <input
                type="email"
                name="email"
                id="email"
                value="#flash.get( 'data.email', '' )#"
                class="form-control"
                required
            >
        </div>

        <div class="form-group">
            <label for="password">Password</label>
            <input
                type="password"
                name="password"
                id="password"
                class="form-control"
                required
            >
        </div>

        <div class="form-actions">
            <button type="submit" class="btn btn-primary">Create User</button>
            <a href="#event.buildLink( 'users.index' )#" class="btn btn-secondary">Cancel</a>
        </div>
    </form>
</div>
</cfoutput>
```

## Partial/Widget Views

```html
<!--
views/partials/header.cfm
Header partial
-->
<cfoutput>
<header class="site-header">
    <div class="container">
        <div class="logo">
            <a href="#event.buildLink( '/' )#">
                <img src="/images/logo.png" alt="Logo">
            </a>
        </div>

        <nav class="main-nav">
            <ul>
                <li><a href="#event.buildLink( 'home' )#">Home</a></li>
                <li><a href="#event.buildLink( 'products.index' )#">Products</a></li>
                <li><a href="#event.buildLink( 'about' )#">About</a></li>
                <li><a href="#event.buildLink( 'contact' )#">Contact</a></li>
                <cfif auth().check()>
                    <li><a href="#event.buildLink( 'account.profile' )#">My Account</a></li>
                    <li><a href="#event.buildLink( 'security.logout' )#">Logout</a></li>
                <cfelse>
                    <li><a href="#event.buildLink( 'security.login' )#">Login</a></li>
                </cfif>
            </ul>
        </nav>
    </div>
</header>
</cfoutput>
```

```html
<!--
views/partials/messages.cfm
Flash messages
-->
<cfoutput>
<cfif flash.exists( "success" )>
    <div class="alert alert-success">
        #flash.get( "success" )#
    </div>
</cfif>

<cfif flash.exists( "error" )>
    <div class="alert alert-danger">
        #flash.get( "error" )#
    </div>
</cfif>

<cfif flash.exists( "warning" )>
    <div class="alert alert-warning">
        #flash.get( "warning" )#
    </div>
</cfif>

<cfif flash.exists( "info" )>
    <div class="alert alert-info">
        #flash.get( "info" )#
    </div>
</cfif>
</cfoutput>
```

## Nested Layouts

```html
<!--
layouts/Print.cfm
Print layout that extends Main layout
-->
<cfset layout = "Main">

<cfoutput>
<style>
    @media print {
        .no-print { display: none; }
    }
</style>

<div class="print-wrapper">
    #renderView()#
</div>
</cfoutput>
```

## Dynamic Layout Selection

```boxlang
// In handler
class Main extends coldbox.system.EventHandler {

    function index( event, rc, prc ) {
        prc.users = userService.list()

        // Set layout dynamically
        if( event.isAjax() ){
            event.setLayout( "Ajax" )
        } else if( device.isMobile() ){
            event.setLayout( "Mobile" )
        } else {
            event.setLayout( "Main" )
        }

        event.setView( "users/index" )
    }
}
```

## Rendering Techniques

### Render View from Handler

```boxlang
class Users extends coldbox.system.EventHandler {

    function index( event, rc, prc ) {
        prc.users = userService.list()

        // Default view (users/index.cfm)
        event.setView( "users/index" )

        // Specific view with layout
        event.setView( view = "users/index", layout = "Admin" )

        // View without layout
        event.setView( view = "users/index", nolayout = true )

        // Module view
        event.setView( view = "main/index", module = "myModule" )
    }
}
```

### Render View from View

```html
<cfoutput>
<!-- Render partial -->
#renderView( "partials/header" )#

<!-- Render with args -->
#renderView(
    view = "widgets/userCard",
    args = { user: prc.user }
)#

<!-- Render module view -->
#renderView(
    view = "widgets/chart",
    module = "analytics"
)#

<!-- Render without cache -->
#renderView(
    view = "partials/live-data",
    cache = false
)#
</cfoutput>
```

### Render View from Service

```boxlang
class EmailService {

    @inject
    property name="renderer";

    @inject
    property name="mailService";

    function sendWelcomeEmail( required user ) {
        var emailBody = renderer.renderView(
            view = "emails/welcome",
            args = { user: arguments.user }
        )

        mailService.send(
            to = arguments.user.getEmail(),
            subject = "Welcome!",
            body = emailBody
        )
    }
}
```

## View Helpers

```html
<!--
views/users/index.cfm
Using view helpers
-->
<cfoutput>
<div class="users-list">
    <h1>#prc.pageTitle#</h1>

    <!-- Build links -->
    <a href="#event.buildLink( 'users.create' )#">Add User</a>

    <!-- Include assets -->
    #html.addAsset( "/css/users.css" )#
    #html.addAsset( "/js/users.js" )#

    <!-- Form helpers -->
    #html.startForm( action="users.search", method="GET" )#
        #html.textField( name="search", label="Search Users" )#
        #html.submitButton( "Search" )#
    #html.endForm()#

    <!-- Date formatting -->
    <p>Generated: #dateFormat( now(), "mm/dd/yyyy" )# at #timeFormat( now(), "h:mm tt" )#</p>

    <!-- Number formatting -->
    <p>Total Users: #numberFormat( prc.users.len() )#</p>

    <!-- Truncate text -->
    <p>#left( prc.description, 100 )#...</p>
</div>
</cfoutput>
```

## View Caching

```boxlang
// In handler
class Products extends coldbox.system.EventHandler {

    function featured( event, rc, prc ) {
        prc.products = productService.getFeatured()

        // Cache view for 60 minutes
        event.setView(
            view = "products/featured",
            cache = true,
            cacheTimeout = 60
        )
    }
}
```

```html
<!--
In view - cache partial
-->
<cfoutput>
#renderView(
    view = "widgets/sidebar",
    cache = true,
    cacheTimeout = 30,
    cacheKey = "sidebar-#prc.user.getId()#"
)#
</cfoutput>
```

## Module Layouts and Views

```
modules/shop/
├── layouts/
│   └── Shop.cfm              # Module-specific layout
└── views/
    ├── main/
    │   └── index.cfm
    └── products/
        ├── index.cfm
        └── show.cfm
```

```boxlang
// Module handler
class Main extends coldbox.system.EventHandler {

    function index( event, rc, prc ) {
        // Use module layout
        event.setLayout( name = "Shop", module = "shop" )

        // Use module view
        event.setView( view = "main/index", module = "shop" )
    }
}
```

## Best Practices

1. **Consistent Structure**: Maintain consistent layout structure
2. **Reusable Partials**: Extract common elements into partials
3. **Layout Hierarchy**: Use layout nesting appropriately
4. **View Caching**: Cache expensive views
5. **Mobile Responsive**: Create responsive layouts
6. **Performance**: Minimize database calls in views
7. **Security**: Always escape output
8. **Accessibility**: Follow WCAG guidelines
9. **SEO**: Proper meta tags and semantic HTML
10. **Asset Management**: Use HTML helper for assets

## Common Pitfalls

1. **Business Logic in Views**: Keep views presentation-only
2. **Not Escaping Output**: XSS vulnerabilities
3. **Heavy Processing**: Expensive operations in views
4. **Inline Styles**: Use CSS classes instead
5. **Duplicate Code**: Not using partials
6. **Poor Organization**: Messy view folder structure
7. **Wrong Layout**: Using inappropriate layout
8. **Missing Flash Handling**: Not displaying messages
9. **Broken Links**: Not using event.buildLink()
10. **No Mobile Support**: Desktop-only layouts

## Performance Tips

```html
<!--
Optimize view rendering
-->
<cfoutput>
<!-- Cache expensive partials -->
#renderView(
    view = "widgets/popularProducts",
    cache = true,
    cacheTimeout = 60
)#

<!-- Lazy load images -->
<img src="placeholder.jpg" data-src="real-image.jpg" class="lazy-load">

<!-- Defer JavaScript -->
<script src="/js/app.js" defer></script>

<!-- Minimize inline scripts -->
<script>
    // Minimal initialization only
    app.init()
</script>
</cfoutput>
```

## Testing Layouts and Views

```boxlang
class UsersViewTest extends coldbox.system.testing.BaseTestCase {

    function beforeAll() {
        super.beforeAll()
        setup()
    }

    function run() {
        describe( "Users View", function(){

            it( "should render users list", function(){
                var event = execute(
                    event = "users.index",
                    renderResults = true
                )

                var html = event.getRenderedContent()
                expect( html ).toInclude( "users-list" )
                expect( html ).toInclude( "Add New User" )
            })

            it( "should use correct layout", function(){
                var event = execute( event = "users.index" )
                expect( event.getCurrentLayout() ).toBe( "Main" )
            })

            it( "should render user form with errors", function(){
                flash.put( "errors", [{ message: "Email is required" }] )

                var event = execute(
                    event = "users.create",
                    renderResults = true
                )

                var html = event.getRenderedContent()
                expect( html ).toInclude( "Email is required" )
            })
        })
    }
}
```

## Related Skills

- `handler-development` - Handler patterns
- `view-rendering` - Advanced rendering techniques
- `event-model` - Event object usage
- `rest-api-development` - API responses
