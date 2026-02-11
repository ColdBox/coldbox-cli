---
name: CBWire Development
description: Complete guide to CBWire - LiveWire-style reactive components for ColdBox with real-time updates, two-way data binding, and wire actions
category: modern
priority: high
triggers:
  - cbwire
  - reactive components
  - wire model
  - wire actions
  - livewire
---

# CBWire Development

## Overview

CBWire brings LiveWire-style reactive components to ColdBox, enabling dynamic interfaces without writing JavaScript. Components automatically sync state between server and browser.

## Core Concepts

### CBWire Features

- **Reactive Components**: Auto-sync state
- **Two-Way Binding**: wire:model directive
- **Actions**: Server-side event handlers
- **Real-Time Updates**: DOM updates without page reload
- **No JavaScript**: Build dynamic UIs server-side
- **Component Lifecycle**: Hooks for state management

## Installation

```bash
box install cbwire
```

### Configuration

```boxlang
// config/ColdBox.cfc
moduleSettings = {
    cbwire: {
        assetsURL: "/cbwire",
        enableDebugging: false,
        componentPaths: [ "/wires" ]
    }
}
```

## Creating Wire Components

### Generate Component

```bash
coldbox create wire Counter
coldbox create wire TodoList
```

### Basic Wire Component

```boxlang
/**
 * wires/Counter.cfc
 */
component extends="cbwire.models.Component" {
    
    // Component data
    data = {
        "count": 0
    }
    
    /**
     * Increment counter
     */
    function increment() {
        data.count++
    }
    
    /**
     * Decrement counter
     */
    function decrement() {
        data.count--
    }
    
    /**
     * Reset counter
     */
    function reset() {
        data.count = 0
    }
}
```

### Component View

```html
<!-- views/wires/counter.cfm -->
<cfoutput>
<div>
    <h3>Counter: #data.count#</h3>
    
    <button wire:click="increment">+</button>
    <button wire:click="decrement">-</button>
    <button wire:click="reset">Reset</button>
</div>
</cfoutput>
```

## Using Wire Components

### Rendering Components

```html
<!-- In any ColdBox view -->
<cfoutput>
<h1>My Page</h1>

<!-- Render wire component -->
#wire( "Counter" )#

<!-- With parameters -->
#wire( "TodoList", { userId: prc.user.id } )#
</cfoutput>
```

### Component Parameters

```boxlang
/**
 * wires/TodoList.cfc
 */
component extends="cbwire.models.Component" {
    
    // Accept parameters
    property name="userId" default="0"
    
    property name="todoService" inject="TodoService"
    
    data = {
        "todos": []
    }
    
    /**
     * Initialize component
     */
    function onMount( params ) {
        userId = params.userId ?: 0
        data.todos = todoService.getByUser( userId )
    }
}
```

## Two-Way Data Binding

### wire:model

```html
<!-- Simple binding -->
<input type="text" wire:model="searchTerm">
<p>Searching for: #data.searchTerm#</p>

<!-- Deferred binding (on blur) -->
<input type="text" wire:model.defer="email">

<!-- Debounced binding (500ms delay) -->
<input type="text" wire:model.debounce.500ms="search">

<!-- Lazy binding (on change) -->
<select wire:model.lazy="category">
    <option value="">All</option>
    <option value="tech">Technology</option>
    <option value="news">News</option>
</select>
```

### Form Binding

```boxlang
/**
 * wires/UserForm.cfc
 */
component extends="cbwire.models.Component" {
    
    data = {
        "firstName": "",
        "lastName": "",
        "email": "",
        "errors": {}
    }
    
    function save() {
        // Validate
        data.errors = {}
        
        if ( data.email.len() == 0 ) {
            data.errors.email = "Email is required"
            return
        }
        
        // Save user
        userService.create( data )
        
        // Reset form
        data.firstName = ""
        data.lastName = ""
        data.email = ""
        
        // Show success message
        flash.put( "success", "User created!" )
    }
}
```

```html
<!-- View -->
<cfoutput>
<form wire:submit.prevent="save">
    <div>
        <label>First Name</label>
        <input type="text" wire:model.defer="firstName">
    </div>
    
    <div>
        <label>Last Name</label>
        <input type="text" wire:model.defer="lastName">
    </div>
    
    <div>
        <label>Email</label>
        <input type="email" wire:model.defer="email">
        <cfif structKeyExists( data.errors, "email" )>
            <span class="error">#data.errors.email#</span>
        </cfif>
    </div>
    
    <button type="submit">Save</button>
    
    <div wire:loading>
        Saving...
    </div>
</form>
</cfoutput>
```

## Wire Actions

### Click Events

```html
<!-- Simple action -->
<button wire:click="delete">Delete</button>

<!-- With parameters -->
<button wire:click="delete( #user.id# )">Delete User</button>

<!-- Multiple parameters -->
<button wire:click="update( #id#, '#status#' )">Update</button>

<!-- Prevent default -->
<a href="##" wire:click.prevent="handleClick">Click Me</a>

<!-- Stop propagation -->
<div wire:click="parentAction">
    <button wire:click.stop="childAction">Child</button>
</div>
```

### Component Methods

```boxlang
component extends="cbwire.models.Component" {
    
    property name="userService" inject="UserService"
    
    data = {
        "users": []
    }
    
    function onMount() {
        loadUsers()
    }
    
    function loadUsers() {
        data.users = userService.list()
    }
    
    function delete( userId ) {
        userService.delete( userId )
        loadUsers()
    }
    
    function toggleActive( userId ) {
        var user = userService.find( userId )
        user.isActive = !user.isActive
        user.save()
        
        loadUsers()
    }
}
```

## Component Lifecycle

### Lifecycle Hooks

```boxlang
component extends="cbwire.models.Component" {
    
    /**
     * Called once when component is mounted
     */
    function onMount( params ) {
        // Initialize component
        data.items = itemService.list()
    }
    
    /**
     * Called before each update
     */
    function onUpdate() {
        // Pre-update logic
    }
    
    /**
     * Called after each update
     */
    function onHydrate() {
        // Post-update logic
        // Good for dependency injection
    }
    
    /**
     * Called before rendering
     */
    function onRender() {
        // Prepare view data
        data.formattedDate = dateFormat( now(), "mm/dd/yyyy" )
    }
}
```

## Real-Time Features

### Loading States

```html
<!-- Show during any action -->
<div wire:loading>
    Loading...
</div>

<!-- Show for specific action -->
<div wire:loading wire:target="save">
    Saving...
</div>

<!-- Remove element when loading -->
<div wire:loading.remove>
    Content shown when not loading
</div>

<!-- Show element when loading -->
<div wire:loading.class="opacity-50">
    This gets dimmed during loading
</div>

<!-- Delay showing loader -->
<div wire:loading.delay>
    Shows after 500ms delay
</div>
```

### Polling

```html
<!-- Poll every 2 seconds -->
<div wire:poll.2s>
    Current time: #timeFormat( now(), "hh:mm:ss" )#
</div>

<!-- Poll specific action -->
<div wire:poll.5s="refreshData">
    Last updated: #data.lastUpdate#
</div>

<!-- Poll when visible -->
<div wire:poll.visible.10s="loadStats">
    Stats: #data.stats#
</div>
```

## Advanced Patterns

### Real-Time Search

```boxlang
/**
 * wires/ProductSearch.cfc
 */
component extends="cbwire.models.Component" {
    
    property name="productService" inject="ProductService"
    
    data = {
        "searchTerm": "",
        "results": []
    }
    
    /**
     * Watch for search term changes
     */
    function updatedSearchTerm() {
        if ( data.searchTerm.len() >= 3 ) {
            data.results = productService.search( data.searchTerm )
        } else {
            data.results = []
        }
    }
}
```

```html
<cfoutput>
<div>
    <input
        type="text"
        wire:model.debounce.300ms="searchTerm"
        placeholder="Search products..."
    >
    
    <div wire:loading wire:target="searchTerm">
        Searching...
    </div>
    
    <cfif data.results.len()>
        <ul>
            <cfloop array="#data.results#" index="product">
                <li>#product.name# - $#product.price#</li>
            </cfloop>
        </ul>
    </cfif>
</div>
</cfoutput>
```

### Pagination

```boxlang
/**
 * wires/UserList.cfc
 */
component extends="cbwire.models.Component" {
    
    property name="userService" inject="UserService"
    
    data = {
        "users": [],
        "page": 1,
        "perPage": 25,
        "total": 0
    }
    
    function onMount() {
        loadUsers()
    }
    
    function loadUsers() {
        var result = userService.paginate(
            page: data.page,
            perPage: data.perPage
        )
        
        data.users = result.data
        data.total = result.total
    }
    
    function nextPage() {
        data.page++
        loadUsers()
    }
    
    function previousPage() {
        if ( data.page > 1 ) {
            data.page--
            loadUsers()
        }
    }
}
```

### Confirmation Dialogs

```html
<!-- Confirm before action -->
<button
    wire:click="delete( #user.id# )"
    wire:confirm="Are you sure you want to delete this user?"
>
    Delete
</button>

<!-- Custom confirmation -->
<button
    wire:click="permanentDelete( #id# )"
    wire:confirm="This action cannot be undone. Are you sure?"
>
    Permanent Delete
</button>
```

## Best Practices

### Design Guidelines

1. **Small Components**: Keep components focused
2. **Use Computed**: Cache expensive operations
3. **Debounce**: Add delays for search inputs
4. **Loading States**: Show feedback
5. **Validate**: Server-side validation
6. **Reset State**: Clear data after actions
7. **Dependency Injection**: Use property injection
8. **Lifecycle Hooks**: Initialize in onMount
9. **Error Handling**: Display errors to users
10. **Security**: Validate all user input

### Common Patterns

```boxlang
// ✅ Good: Debounced search
data = { "searchTerm": "" }

function updatedSearchTerm() {
    // Auto-called when searchTerm changes
    performSearch()
}

// ✅ Good: Loading indicator
<div wire:loading wire:target="save">
    Saving...
</div>

// ✅ Good: Validation
function save() {
    if ( !validate() ) {
        return
    }
    
    userService.create( data )
}
```

## Common Pitfalls

### Pitfalls to Avoid

1. **Large Components**: Too much in one component
2. **No Debounce**: Excessive server requests
3. **Missing Loading**: No user feedback
4. **Client Validation Only**: Skipping server validation
5. **Nested Components**: Performance issues
6. **No Error States**: Silent failures
7. **Heavy Polling**: Unnecessary server load
8. **Stale Data**: Not refreshing after actions
9. **Missing Keys**: Loop items without keys
10. **Expose Sensitive**: Data exposure

### Anti-Patterns

```boxlang
// ❌ Bad: No debounce on search
<input wire:model="search">  // Hits server on every keystroke

// ✅ Good: Debounce search
<input wire:model.debounce.300ms="search">

// ❌ Bad: No loading indicator
<button wire:click="save">Save</button>

// ✅ Good: Show loading
<button wire:click="save">
    Save
    <span wire:loading>...</span>
</button>

// ❌ Bad: Client validation only
function save() {
    // Just save, no validation
    userService.create( data )
}

// ✅ Good: Server validation
function save() {
    data.errors = validate( data )
    
    if ( structCount( data.errors ) > 0 ) {
        return
    }
    
    userService.create( data )
}
```

## Related Skills

- [ColdBox Handler Development](../coldbox/handler-development.md) - Handler patterns
- [ColdBox View Rendering](../coldbox/view-rendering.md) - View patterns
- [BoxLang Components](boxlang-components.md) - Component development

## References

- [CBWire Documentation](https://cbwire.ortusbooks.com/)
- [Laravel Livewire](https://laravel-livewire.com/)
- [Alpine.js](https://alpinejs.dev/)
