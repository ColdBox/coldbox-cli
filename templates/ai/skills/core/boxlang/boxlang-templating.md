---
name: BoxLang Templating Language
description: Complete guide to BoxLang templating with BXCFM syntax, output expressions, control structures, and template includes
category: boxlang
priority: high
triggers:
  - boxlang template
  - bxcfm
  - template syntax
  - output expression
  - cfoutput
---

# BoxLang Templating Language

## Overview

BoxLang provides a powerful templating language (BXCFM) for mixing HTML and BoxLang code. It offers clean syntax for dynamic content generation with output expressions and control structures.

## Core Concepts

### Template Features

- **Output Expressions**: `#variable#` syntax
- **Control Structures**: Loops, conditions
- **Script Blocks**: Embedded BoxLang code
- **Template Includes**: Reuse templates
- **Custom Tags**: Extensible components

## Output Expressions

### Basic Output

```boxlang
<bx:output>
    <h1>Welcome, #userName#!</h1>
    <p>Today is #dateFormat( now(), "full" )#</p>
</bx:output>

<!-- Simple expression -->
<p>Total: #total#</p>

<!-- Function calls -->
<p>Price: #numberFormat( product.price, "$0.00" )#</p>

<!-- Arithmetic -->
<p>Tax: #total * 0.08#</p>

<!-- Struct access -->
<p>Email: #user.email#</p>
<p>Name: #user["fullName"]#</p>
```

### Safe Output

```boxlang
<!-- HTML escape (default) -->
<bx:output>
    <p>#encodeForHTML( userInput )#</p>
</bx:output>

<!-- Raw output (no encoding) -->
<bx:output>
    {{{htmlContent}}}
</bx:output>

<!-- URL encoding -->
<a href="/search?q=#encodeForURL( searchTerm )#">Search</a>

<!-- JavaScript encoding -->
<script>
    var message = '#encodeForJavaScript( message )#';
</script>
```

## Control Structures

### Conditionals

```boxlang
<!-- If/else -->
<bx:if condition="#user.isAdmin()#">
    <p>Admin Panel</p>
<bx:else>
    <p>User Dashboard</p>
</bx:if>

<!-- If/elseif/else -->
<bx:if condition="#status == 'active'#">
    <span class="badge-success">Active</span>
<bx:elseif condition="#status == 'pending'#">
    <span class="badge-warning">Pending</span>
<bx:else>
    <span class="badge-danger">Inactive</span>
</bx:if>

<!-- Inline condition -->
<p class="#user.isActive ? 'active' : 'inactive'#">
    Status: #user.status#
</p>
```

### Loops

```boxlang
<!-- Array loop -->
<bx:loop array="#products#" index="product">
    <div class="product">
        <h3>#product.name#</h3>
        <p>#product.description#</p>
        <span>$#product.price#</span>
    </div>
</bx:loop>

<!-- Query loop -->
<bx:loop query="users">
    <tr>
        <td>#users.firstName#</td>
        <td>#users.lastName#</td>
        <td>#users.email#</td>
    </tr>
</bx:loop>

<!-- Numeric loop -->
<bx:loop from="1" to="10" index="i">
    <p>Item #i#</p>
</bx:loop>

<!-- Struct loop -->
<bx:loop collection="#settings#" item="key" value="val">
    <p>#key#: #val#</p>
</bx:loop>

<!-- List loop -->
<bx:loop list="red,green,blue" index="color" delimiters=",">
    <span style="color: #color#">#color#</span>
</bx:loop>
```

### Switch Statements

```boxlang
<bx:switch expression="#user.role#">
    <bx:case value="admin">
        <p>Administrator Access</p>
    </bx:case>
    <bx:case value="moderator,editor" delimiters=",">
        <p>Content Management Access</p>
    </bx:case>
    <bx:defaultcase>
        <p>User Access</p>
    </bx:defaultcase>
</bx:switch>
```

## Script Blocks

### Embedded BoxLang

```boxlang
<bx:script>
    // BoxLang code
    var total = 0
    
    for ( var item in cart ) {
        total += item.price * item.quantity
    }
    
    var tax = total * 0.08
    var grandTotal = total + tax
</bx:script>

<bx:output>
    <p>Subtotal: #numberFormat( total, "$0.00" )#</p>
    <p>Tax: #numberFormat( tax, "$0.00" )#</p>
    <p>Total: #numberFormat( grandTotal, "$0.00" )#</p>
</bx:output>
```

### Mixed Content

```boxlang
<bx:script>
    var products = productService.list()
    var featuredProducts = products.filter( ( p ) => p.isFeatured )
</bx:script>

<div class="featured">
    <h2>Featured Products</h2>
    
    <bx:loop array="#featuredProducts#" index="product">
        <div class="product-card">
            <h3>#product.name#</h3>
            <p>#product.price#</p>
        </div>
    </bx:loop>
</div>
```

## Template Includes

### Include Files

```boxlang
<!-- Include template -->
<bx:include template="header.bxm">

<main>
    <h1>Page Content</h1>
</main>

<bx:include template="footer.bxm">

<!-- Include with variables -->
<bx:set name="pageTitle" value="Home">
<bx:include template="layout.bxm">

<!-- Dynamic include -->
<bx:include template="#getTemplate()#">
```

### Layouts

```boxlang
<!-- views/layouts/main.bxm -->
<!DOCTYPE html>
<html>
<head>
    <title>#pageTitle#</title>
    <link rel="stylesheet" href="/css/app.css">
</head>
<body>
    <header>
        <bx:include template="../includes/header.bxm">
    </header>
    
    <main>
        #renderView()#
    </main>
    
    <footer>
        <bx:include template="../includes/footer.bxm">
    </footer>
</body>
</html>

<!-- views/home/index.bxm -->
<bx:set name="pageTitle" value="Home">

<h1>Welcome to Our Site</h1>
<p>Content goes here</p>
```

## Custom Tags

### Creating Custom Tags

```boxlang
/**
 * customtags/alert.bxm
 */
<bx:param name="type" default="info">
<bx:param name="message" required="true">
<bx:param name="dismissible" default="false">

<div class="alert alert-#type#" role="alert">
    #message#
    
    <bx:if condition="#dismissible#">
        <button type="button" class="close">×</button>
    </bx:if>
</div>
```

### Using Custom Tags

```boxlang
<!-- Use custom tag -->
<bx:alert
    type="success"
    message="User created successfully!"
    dismissible="true">

<!-- Module-based custom tags -->
<bx:module template="ui/card" title="User Profile">
    <p>User content</p>
</bx:module>
```

## Template Comments

### Comment Syntax

```boxlang
<!--- BoxLang comment (not sent to browser) --->
<p>Visible content</p>

<!---
    Multi-line comment
    Not sent to browser
--->

<!-- HTML comment (sent to browser) -->
```

## Template Variables

### Setting Variables

```boxlang
<!-- Set variable -->
<bx:set name="userName" value="John Doe">
<p>Hello, #userName#</p>

<!-- Set with expression -->
<bx:set name="total" value="#calculateTotal()#">

<!-- Set struct -->
<bx:set name="user" value="#{ name: 'John', email: 'john@example.com' }#">

<!-- Multiple variables -->
<bx:set>
    var firstName = "John"
    var lastName = "Doe"
    var fullName = "#firstName# #lastName#"
</bx:set>
```

## Template Functions

### Scope Functions

```boxlang
<!-- Check if variable exists -->
<bx:if condition="#isDefined( 'userName' )#">
    <p>Welcome, #userName#!</p>
</bx:if>

<!-- Default value -->
<p>Name: #variables.name ?: 'Guest'#</p>

<!-- Param with default -->
<bx:param name="pageSize" default="25">
```

### String Functions

```boxlang
<bx:output>
    <!-- String manipulation -->
    <p>Upper: #uCase( text )#</p>
    <p>Lower: #lCase( text )#</p>
    <p>Length: #len( text )#</p>
    <p>Trim: #trim( text )#</p>
    
    <!-- Substring -->
    <p>First 10: #left( text, 10 )#</p>
    <p>Last 5: #right( text, 5 )#</p>
    <p>Middle: #mid( text, 5, 10 )#</p>
    
    <!-- Replace -->
    <p>#replace( text, "old", "new" )#</p>
    <p>#replaceNoCase( text, "OLD", "new" )#</p>
</bx:output>
```

### Date Functions

```boxlang
<bx:output>
    <!-- Current date/time -->
    <p>Now: #now()#</p>
    <p>Today: #today()#</p>
    
    <!-- Format date -->
    <p>Long: #dateFormat( now(), "full" )#</p>
    <p>Short: #dateFormat( now(), "mm/dd/yyyy" )#</p>
    <p>Time: #timeFormat( now(), "hh:mm:ss tt" )#</p>
    
    <!-- Date math -->
    <p>Tomorrow: #dateAdd( "d", 1, now() )#</p>
    <p>Last Week: #dateAdd( "ww", -1, now() )#</p>
    <p>Difference: #dateDiff( "d", startDate, endDate )# days</p>
</bx:output>
```

## Best Practices

### Design Guidelines

1. **Escape Output**: Always encode user input
2. **Minimize Logic**: Keep templates simple
3. **Use Includes**: Reuse common templates
4. **Consistent Naming**: Use clear variable names
5. **Comments**: Document complex sections
6. **Whitespace**: Proper indentation
7. **Security**: Never trust user input
8. **Performance**: Cache where possible
9. **Separation**: Business logic in components
10. **Accessibility**: Semantic HTML

### Common Patterns

```boxlang
<!-- ✅ Good: Escape user input -->
<p>#encodeForHTML( userInput )#</p>

<!-- ✅ Good: Use conditionals -->
<bx:if condition="#items.len()#">
    <ul>
        <bx:loop array="#items#" index="item">
            <li>#item.name#</li>
        </bx:loop>
    </ul>
<bx:else>
    <p>No items found</p>
</bx:if>

<!-- ✅ Good: Template includes -->
<bx:include template="components/header.bxm">
```

## Common Pitfalls

### Pitfalls to Avoid

1. **No Escaping**: XSS vulnerabilities
2. **Too Much Logic**: Business logic in templates
3. **Deep Nesting**: Hard to read
4. **Inline Styles**: Mixing concerns
5. **Missing Checks**: Undefined variable errors
6. **No Comments**: Unclear code
7. **Long Templates**: Monolithic files
8. **Hardcoded Values**: Not using variables
9. **No Validation**: Trusting user input
10. **Poor Formatting**: Unreadable code

### Anti-Patterns

```boxlang
<!-- ❌ Bad: No escaping -->
<p>#userInput#</p>

<!-- ✅ Good: Escape output -->
<p>#encodeForHTML( userInput )#</p>

<!-- ❌ Bad: Business logic in template -->
<bx:script>
    var user = userService.find( id )
    user.balance = calculateBalance()
    user.save()
</bx:script>

<!-- ✅ Good: Logic in component -->
<bx:script>
    // Just display logic
    var user = prc.user
    var formattedBalance = numberFormat( user.balance )
</bx:script>

<!-- ❌ Bad: Deep nesting -->
<bx:if ...>
    <bx:loop ...>
        <bx:if ...>
            <bx:switch ...>
                <!-- Too deep -->
            </bx:switch>
        </bx:if>
    </bx:loop>
</bx:if>

<!-- ✅ Good: Extract to functions/includes -->
<bx:include template="components/userList.bxm">
```

## Related Skills

- [BoxLang Syntax](boxlang-syntax.md) - Language fundamentals
- [BoxLang Components](boxlang-components.md) - Component development
- [ColdBox View Rendering](../coldbox/view-rendering.md) - View patterns

## References

- [BoxLang Templating Documentation](https://boxlang.ortusbooks.com/)
- [CFML Templates](https://cfdocs.org/)
- [Template Security](https://owasp.org/www-community/attacks/xss/)
