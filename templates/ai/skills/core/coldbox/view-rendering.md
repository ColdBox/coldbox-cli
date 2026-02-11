---
name: view-rendering
description: Advanced view rendering techniques including partials, caching, helpers, and dynamic content generation
category: coldbox
priority: medium
triggers:
  - render view
  - view rendering
  - partial views
  - view helpers
---

# View Rendering Implementation Pattern

## When to Use This Skill

Use this skill when implementing complex view rendering, creating reusable view components, optimizing view performance, or building dynamic UI elements in ColdBox applications.

## Core Concepts

ColdBox View Rendering:
- Views are CFML/HTML templates
- Can render other views (partials/widgets)
- Support view arguments for data passing
- Can be cached for performance
- Have access to helper functions
- Support multiple rendering contexts (HTML, JSON, Email)

## Basic View Rendering (BoxLang)

```html
<!--
views/users/index.cfm
Basic view template
-->
<cfoutput>
<div class="users-container">
    <h1>#prc.pageTitle#</h1>

    <table class="table">
        <thead>
            <tr>
                <th>Name</th>
                <th>Email</th>
                <th>Actions</th>
            </tr>
        </thead>
        <tbody>
            <cfloop array="#prc.users#" index="user">
                <tr>
                    <td>#user.getFullName()#</td>
                    <td>#user.getEmail()#</td>
                    <td>
                        <a href="#event.buildLink( 'users.edit' )#?id=#user.getId()#">Edit</a>
                    </td>
                </tr>
            </cfloop>
        </tbody>
    </table>
</div>
</cfoutput>
```

## Rendering Partials/Widgets

```html
<!--
views/users/index.cfm
View with partials
-->
<cfoutput>
<div class="page-container">
    <!-- Render header partial -->
    #renderView( "partials/pageHeader" )#

    <!-- Render content with arguments -->
    #renderView(
        view = "users/partials/userTable",
        args = {
            users: prc.users,
            showActions: true
        }
    )#

    <!-- Render sidebar widget -->
    #renderView( "widgets/userStats" )#

    <!-- Render footer partial -->
    #renderView( "partials/pageFooter" )#
</div>
</cfoutput>
```

```html
<!--
views/users/partials/userTable.cfm
Reusable partial with arguments
-->
<cfparam name="args.users" type="array">
<cfparam name="args.showActions" type="boolean" default="false">

<cfoutput>
<table class="table">
    <thead>
        <tr>
            <th>Name</th>
            <th>Email</th>
            <cfif args.showActions>
                <th>Actions</th>
            </cfif>
        </tr>
    </thead>
    <tbody>
        <cfloop array="#args.users#" index="user">
            <tr>
                <td>#user.getFullName()#</td>
                <td>#user.getEmail()#</td>
                <cfif args.showActions>
                    <td>
                        <a href="#event.buildLink( 'users.edit' )#?id=#user.getId()#">Edit</a>
                        <a href="#event.buildLink( 'users.delete' )#?id=#user.getId()#">Delete</a>
                    </td>
                </cfif>
            </tr>
        </cfloop>
    </tbody>
</table>
</cfoutput>
```

## Rendering from Services/Models

```boxlang
/**
 * Email Service
 * Render email templates from service
 */
class EmailService {

    @inject
    property name="renderer";

    @inject
    property name="mailService";

    /**
     * Send welcome email with rendered template
     */
    function sendWelcomeEmail( required user ) {
        // Render email view
        var emailBody = renderer.renderView(
            view = "emails/welcome",
            args = {
                user: arguments.user,
                activationLink: getActivationLink( arguments.user )
            }
        )

        mailService.send(
            to = arguments.user.getEmail(),
            from = "noreply@example.com",
            subject = "Welcome to Our Platform!",
            body = emailBody
        )
    }

    /**
     * Generate PDF report with rendered view
     */
    function generateReport( required reportData ) {
        var reportHTML = renderer.renderView(
            view = "reports/sales",
            args = {
                data: arguments.reportData,
                generatedDate: now()
            }
        )

        // Convert to PDF
        return pdfService.htmlToPDF( reportHTML )
    }
}
```

## View Caching

```html
<!--
views/widgets/popularProducts.cfm
Cached partial
-->
<cfoutput>
<!-- Cache this widget for 30 minutes -->
#renderView(
    view = "widgets/popularProducts",
    cache = true,
    cacheTimeout = 30,
    cacheKey = "widget-popular-products"
)#
</cfoutput>
```

```boxlang
// In handler - cache event output
class Products extends coldbox.system.EventHandler {

    function featured( event, rc, prc ) {
        prc.products = productService.getFeatured()

        // Cache entire event output
        event.setView(
            view = "products/featured",
            cache = true,
            cacheTimeout = 60,
            cacheKey = "products-featured"
        )
    }

    function show( event, rc, prc ) {
        var productId = rc.id ?: 0
        prc.product = productService.getById( productId )

        // Cache per product
        event.setView(
            view = "products/show",
            cache = true,
            cacheTimeout = 30,
            cacheKey = "product-#productId#"
        )
    }
}
```

## Dynamic View Selection

```boxlang
class Dashboard extends coldbox.system.EventHandler {

    @inject
    property name="themeService";

    function index( event, rc, prc ) {
        prc.dashboardData = getDashboardData()

        // Select view based on user theme
        var theme = themeService.getUserTheme()
        var viewPath = "dashboard/#theme#/index"

        // Check if theme view exists, fallback to default
        if( !fileExists( expandPath( "/views/#viewPath#.cfm" ) ) ){
            viewPath = "dashboard/default/index"
        }

        event.setView( viewPath )
    }

    function mobile( event, rc, prc ) {
        // Different views for different devices
        if( device.isTablet() ){
            event.setView( "dashboard/tablet/index" )
        } else if( device.isPhone() ){
            event.setView( "dashboard/mobile/index" )
        } else {
            event.setView( "dashboard/index" )
        }
    }

    function ajaxWidget( event, rc, prc ) {
        prc.widgetData = getWidgetData()

        // Return partial without layout for AJAX
        if( event.isAjax() ){
            event.setView(
                view = "dashboard/widgets/stats",
                nolayout = true
            )
        } else {
            event.setView( "dashboard/index" )
        }
    }
}
```

## View Collections and Loops

```html
<!--
views/products/grid.cfm
Rendering collection with grid layout
-->
<cfoutput>
<div class="products-grid">
    <cfloop array="#prc.products#" index="product">
        <div class="product-card">
            #renderView(
                view = "products/partials/card",
                args = { product: product }
            )#
        </div>
    </cfloop>
</div>
</cfoutput>
```

```html
<!--
views/products/partials/card.cfm
Product card partial
-->
<cfparam name="args.product" type="any">

<cfoutput>
<article class="card">
    <img src="#args.product.getImageURL()#" alt="#args.product.getName()#">
    <h3>#args.product.getName()#</h3>
    <p class="price">#numberFormat( args.product.getPrice(), "$999,999.99" )#</p>
    <p class="description">#left( args.product.getDescription(), 100 )#...</p>
    <a href="#event.buildLink( 'products.show' )#?id=#args.product.getId()#" class="btn">
        View Details
    </a>
</article>
</cfoutput>
```

## Conditional Rendering

```html
<!--
views/users/show.cfm
Conditional view content
-->
<cfoutput>
<div class="user-profile">
    <h1>#prc.user.getFullName()#</h1>

    <!-- Show edit button only if user can edit -->
    <cfif auth().can( "users.edit" )>
        <a href="#event.buildLink( 'users.edit' )#?id=#prc.user.getId()#" class="btn">
            Edit Profile
        </a>
    </cfif>

    <!-- Show admin panel only for admins -->
    <cfif prc.user.hasRole( "admin" )>
        #renderView( "users/partials/adminPanel" )#
    </cfif>

    <!-- Different content for user's own profile -->
    <cfif prc.user.getId() == auth().userId()>
        #renderView( "users/partials/ownProfile" )#
    <cfelse>
        #renderView( "users/partials/publicProfile" )#
    </cfif>

    <!-- Render premium features if subscribed -->
    <cfif prc.user.hasSubscription()>
        #renderView( "users/partials/premiumFeatures" )#
    </cfif>
</div>
</cfoutput>
```

## View Helpers

```html
<!--
views/orders/index.cfm
Using view helpers
-->
<cfoutput>
<div class="orders-list">
    <h1>Orders</h1>

    <!-- Build links with helper -->
    <a href="#event.buildLink( 'orders.create' )#">New Order</a>

    <!-- Build link with query string -->
    <a href="#event.buildLink( event='orders.index', queryString='status=pending' )#">
        Pending Orders
    </a>

    <!-- Build route with parameters -->
    <a href="#event.route( name='order.show', params={ id: order.getId() } )#">
        View Order
    </a>

    <table class="table">
        <cfloop array="#prc.orders#" index="order">
            <tr>
                <td>###order.getId()#</td>
                <td>#order.getCustomerName()#</td>

                <!-- Format currency -->
                <td>#numberFormat( order.getTotal(), "$999,999.99" )#</td>

                <!-- Format date -->
                <td>#dateFormat( order.getCreatedDate(), "mm/dd/yyyy" )#</td>

                <!-- Format time -->
                <td>#timeFormat( order.getCreatedDate(), "h:mm tt" )#</td>

                <!-- Status badge -->
                <td>
                    <span class="badge badge-#order.getStatusClass()#">
                        #order.getStatus()#
                    </span>
                </td>
            </tr>
        </cfloop>
    </table>

    <!-- Pagination helper -->
    #renderView(
        view = "partials/pagination",
        args = {
            currentPage: prc.page,
            totalPages: prc.totalPages,
            baseURL: "/orders"
        }
    )#
</div>
</cfoutput>
```

## Module View Rendering

```html
<!--
Render view from module
-->
<cfoutput>
<!-- Render module view -->
#renderView(
    view = "dashboard/widget",
    module = "analytics"
)#

<!-- Render module view with args -->
#renderView(
    view = "charts/bar",
    module = "analytics",
    args = {
        data: prc.chartData,
        title: "Sales by Month"
    }
)#
</cfoutput>
```

```boxlang
// In handler - set module view
function index( event, rc, prc ) {
    event.setView(
        view = "main/index",
        module = "shop"
    )
}
```

## Email View Templates

```html
<!--
views/emails/welcome.cfm
Welcome email template
-->
<cfparam name="args.user" type="any">
<cfparam name="args.activationLink" type="string">

<cfoutput>
<!DOCTYPE html>
<html>
<head>
    <style>
        body { font-family: Arial, sans-serif; }
        .container { max-width: 600px; margin: 0 auto; }
        .button { background: ##007bff; color: white; padding: 10px 20px; text-decoration: none; }
    </style>
</head>
<body>
    <div class="container">
        <h1>Welcome, #args.user.getFirstName()#!</h1>

        <p>Thank you for joining our platform. We're excited to have you!</p>

        <p>To get started, please verify your email address:</p>

        <p>
            <a href="#args.activationLink#" class="button">Verify Email</a>
        </p>

        <p>
            Or copy this link:<br>
            #args.activationLink#
        </p>

        <p>Best regards,<br>The Team</p>
    </div>
</body>
</html>
</cfoutput>
```

## JSON View Responses

```boxlang
class api_Users extends coldbox.system.RestHandler {

    function index( event, rc, prc ) {
        var users = userService.list()

        // Render structured JSON response
        event.renderData(
            type = "json",
            data = {
                success: true,
                data: users,
                meta: {
                    page: rc.page ?: 1,
                    total: users.len(),
                    timestamp: now()
                }
            },
            statusCode = 200
        )
    }
}
```

## Error Views

```html
<!--
views/errors/404.cfm
Custom 404 error page
-->
<cfoutput>
<!DOCTYPE html>
<html>
<head>
    <title>Page Not Found</title>
</head>
<body>
    <div class="error-page">
        <h1>404 - Page Not Found</h1>
        <p>The page you're looking for doesn't exist.</p>
        <p>
            <a href="#event.buildLink( '/' )#">Go Home</a>
        </p>
    </div>
</body>
</html>
</cfoutput>
```

```boxlang
// In ColdBox.cfc - configure error views
configure() {
    coldbox = {
        // ... other settings
        customErrorTemplate = "/views/errors/error.cfm",
        invalidEventHandler = "Main.notFound",
        invalidHTTPMethodHandler = "Main.invalidMethod"
    }
}
```

## Performance Optimization

```html
<!--
Optimized view rendering
-->
<cfoutput>
<!-- Cache expensive widgets -->
#renderView(
    view = "widgets/recentActivity",
    cache = true,
    cacheTimeout = 15,
    cacheKey = "activity-user-#auth().userId()#"
)#

<!-- Lazy load images -->
<img
    src="data:image/gif;base64,R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7"
    data-src="/images/large-image.jpg"
    class="lazy-load"
    alt="Description"
>

<!-- Preload critical CSS -->
<link rel="preload" href="/css/critical.css" as="style">

<!-- Defer non-critical JavaScript -->
<script src="/js/analytics.js" defer></script>
</cfoutput>
```

## Testing View Rendering

```boxlang
class ViewRenderingTest extends coldbox.system.testing.BaseTestCase {

    function beforeAll() {
        super.beforeAll()
        setup()
    }

    function run() {
        describe( "View Rendering", function(){

            it( "should render user view with data", function(){
                var event = execute(
                    event = "users.index",
                    renderResults = true
                )

                var html = event.getRenderedContent()
                expect( html ).toInclude( "users-container" )
                expect( html ).toInclude( "table" )
            })

            it( "should render partial with arguments", function(){
                var html = getRenderer().renderView(
                    view = "users/partials/userCard",
                    args = {
                        user: getInstance( "User" ).new({
                            firstName: "John",
                            lastName: "Doe"
                        })
                    }
                )

                expect( html ).toInclude( "John Doe" )
            })

            it( "should cache view output", function(){
                var html1 = getRenderer().renderView(
                    view = "widgets/stats",
                    cache = true,
                    cacheTimeout = 60,
                    cacheKey = "test-stats"
                )

                var html2 = getRenderer().renderView(
                    view = "widgets/stats",
                    cache = true,
                    cacheKey = "test-stats"
                )

                expect( html1 ).toBe( html2 )
            })
        })
    }
}
```

## Best Practices

1. **Reusable Partials**: Extract common UI into partials
2. **Pass Data via Args**: Use args for partial data, not global variables
3. **Cache Expensive Views**: Cache views with heavy processing
4. **Escape Output**: Always escape user-generated content
5. **Semantic HTML**: Use proper HTML5 elements
6. **Responsive Design**: Make views mobile-friendly
7. **Performance**: Minimize database calls in views
8. **Accessibility**: Follow WCAG guidelines
9. **SEO**: Proper meta tags and structure
10. **Test Views**: Write tests for view rendering

## Common Pitfalls

1. **Business Logic in Views**: Keep views presentation-only
2. **Not Escaping Output**: XSS vulnerabilities
3. **Heavy Processing**: Database queries in loops
4. **Duplicate Code**: Not using partials
5. **Wrong Data Source**: Using rc instead of prc for view data
6. **Over-caching**: Caching user-specific content
7. **Missing Arguments**: Not defining cfparam for args
8. **Poor Organization**: Messy view folder structure
9. **Inline Styles**: Use CSS classes instead
10. **Not Testing**: No tests for view rendering

## Related Skills

- `layout-development` - Layout patterns
- `handler-development` - Handler patterns
- `event-model` - Event object usage
- `rest-api-development` - API responses
- `cache-integration` - Caching strategies
