---
name: Flash RAM and Messaging
description: Complete guide to ColdBox Flash RAM for temporary data persistence across redirects and CBMessageBox for user messaging patterns
category: coldbox
priority: medium
triggers:
  - flash scope
  - flash ram
  - flash messaging
  - redirects with data
  - cbmessagebox
  - user notifications
  - success messages
---

# Flash RAM and Messaging

## Overview

Flash RAM is ColdBox's mechanism for temporarily persisting data across HTTP redirects. Combined with CBMessageBox, it provides elegant patterns for user messaging, form validation feedback, and maintaining state during POST-REDIRECT-GET workflows.

## Flash RAM Basics

### Flash Configuration

```boxlang
// config/ColdBox.cfc
coldbox = {
    flash: {
        scope: "session",  // or "client", "cluster", "cache", "mock"
        properties: {},  // Additional properties for storage
        inflateToRC: true,  // Inflate flash to rc automatically
        inflateToPRC: false,  // Inflate flash to prc automatically
        autoPurge: true,  // Auto-purge flash after read
        autoSave: true  // Auto-save flash on relocate
    }
}
```

### Basic Usage

```boxlang
class extends="coldbox.system.EventHandler" {

    function save( event, rc, prc ) {
        var user = userService.create( rc )

        // Put data in flash
        flash.put( "userId", user.id )
        flash.put( "message", "User created successfully" )

        // Redirect - flash data available in next request
        relocate( "users.show" )
    }

    function show( event, rc, prc ) {
        // Get flash data
        var userId = flash.get( "userId", 0 )
        var message = flash.get( "message", "" )

        // Flash is automatically purged after reading (if autoPurge=true)
    }
}
```

## Flash Methods

### Storing Data

```boxlang
function flashOperations( event, rc, prc ) {
    // Put single value
    flash.put( "key", "value" )

    // Put multiple values
    flash.putAll( {
        userId: 1,
        message: "Success",
        timestamp: now()
    } )

    // Put with custom options
    flash.put(
        name: "tempData",
        value: complexObject,
        keep: true,  // Don't auto-purge
        inflate: true,  // Inflate to rc/prc
        saveNow: false  // Don't save immediately
    )
}
```

### Retrieving Data

```boxlang
function retrieveFlash( event, rc, prc ) {
    // Get single value with default
    var message = flash.get( "message", "" )

    // Check existence
    if ( flash.exists( "userId" ) ) {
        var userId = flash.get( "userId" )
    }

    // Get and remove immediately
    var tempData = flash.get( "tempData" )
    flash.remove( "tempData" )

    // Get all flash data
    var allFlash = flash.getFlash()

    // Get specific keys only
    var subset = flash.getKeys( [ "userId", "message" ] )
}
```

### Managing Flash

```boxlang
function manageFlash( event, rc, prc ) {
    // Remove specific key
    flash.remove( "tempData" )

    // Remove multiple keys
    flash.removeFlash( "key1,key2,key3" )

    // Clear all flash
    flash.clearFlash()

    // Keep flash for another request
    flash.keep( "userId" )

    // Discard flash (prevent auto-save)
    flash.discard()

    // Save flash immediately
    flash.saveFlash()
}
```

## Relocate with Flash

### Persisting Request Collection Data

```boxlang
function update( event, rc, prc ) {
    userService.update( rc.id, rc )

    // Persist specific rc keys to flash
    relocate(
        event: "users.edit",
        persist: "id"
    )
}

function edit( event, rc, prc ) {
    // id is now available in rc (inflated from flash)
    var userId = rc.id
    prc.user = userService.find( userId )
}
```

### Persisting Multiple Values

```boxlang
function search( event, rc, prc ) {
    var results = searchService.search( rc )

    // Persist search parameters
    relocate(
        event: "search.results",
        persist: "q,category,page,sort"
    )
}

function results( event, rc, prc ) {
    // All search params available in rc
    var query = rc.q
    var category = rc.category
    var page = rc.page
    var sort = rc.sort
}
```

## CBMessageBox Integration

### Installing CBMessageBox

```bash
box install cbmessagebox
```

### Configuration

```boxlang
// config/ColdBox.cfc
moduleSettings = {
    cbmessagebox: {
        // Styling for different message types
        styleOverride: true,
        template: "

<div class='alert alert-#type#' role='alert'>#message#</div>"
    }
}
```

### Basic Messaging

```boxlang
class extends="coldbox.system.EventHandler" {

    property name="messagebox" inject="messagebox@cbmessagebox"

    function save( event, rc, prc ) {
        try {
            var user = userService.create( rc )

            // Success message
            messagebox.setMessage( "success", "User created successfully!" )

            relocate( "users.index" )
        } catch ( any e ) {
            // Error message
            messagebox.setMessage( "error", "Failed to create user: #e.message#" )

            relocate( "users.create" )
        }
    }
}
```

### Message Types

```boxlang
function messageTypes( event, rc, prc ) {
    // Success
    messagebox.success( "Operation completed successfully" )

    // Info
    messagebox.info( "Your profile has been updated" )

    // Warning
    messagebox.warn( "Your session will expire soon" )

    // Error
    messagebox.error( "Invalid credentials" )

    // Custom type
    messagebox.setMessage( "notice", "Please check your email" )
}
```

### Rendering Messages

```html
<!-- In your layout or view -->
<cfoutput>
    #getInstance( "messagebox@cbmessagebox" ).renderIt()#
</cfoutput>

<!-- BoxLang view -->
<!--- views/main/index.bxm --->
<bx:output>
    #getInstance( "messagebox@cbmessagebox" ).renderIt()#
</bx:output>
```

### Multiple Messages

```boxlang
function multipleMessages( event, rc, prc ) {
    // Append multiple messages
    messagebox.success( "User created" )
    messagebox.info( "Welcome email sent" )
    messagebox.warn( "Please verify your email" )

    relocate( "users.index" )
}
```

### Message with Data

```boxlang
function messageWithData( event, rc, prc ) {
    var user = userService.create( rc )

    // Include data with message
    messagebox.success(
        message: "User ##user.id## created successfully",
        messageArray: [ user.id, user.name ]
    )

    relocate( "users.show" )
}
```

## Form Validation Patterns

### Validation with Redirect

```boxlang
class extends="coldbox.system.EventHandler" {

    property name="messagebox" inject="messagebox@cbmessagebox"
    property name="validator" inject="ValidationManager@cbvalidation"

    function store( event, rc, prc ) {
        // Validate
        var result = validator.validate(
            target: rc,
            constraints: {
                email: { required: true, type: "email" },
                password: { required: true, minLength: 8 }
            }
        )

        if ( result.hasErrors() ) {
            // Show validation errors
            for ( var error in result.getAllErrors() ) {
                messagebox.error( error.message )
            }

            // Persist form data
            flash.putAll( rc )

            relocate( "users.create" )
        }

        // Process valid data
        var user = userService.create( rc )

        messagebox.success( "User created successfully" )
        relocate( "users.index" )
    }

    function create( event, rc, prc ) {
        // Repopulate form with flash data
        prc.formData = flash.getFlash()
    }
}
```

### Pre-populating Forms

```html
<!-- views/users/create.bxm -->
<form method="post" action="#event.buildLink( 'users.store' )#">
    <input
        type="text"
        name="name"
        value="#prc.formData.name ?: ''#"
    >

    <input
        type="email"
        name="email"
        value="#prc.formData.email ?: ''#"
    >

    <textarea name="bio">#prc.formData.bio ?: ''#</textarea>

    <button type="submit">Create User</button>
</form>
```

## POST-REDIRECT-GET Pattern

### PRG Implementation

```boxlang
// POST - Process form submission
function store( event, rc, prc ) {
    try {
        var user = userService.create( rc )

        // Success - redirect to GET
        flash.put( "userId", user.id )
        messagebox.success( "User created successfully" )

        relocate( "users.show" )
    } catch ( any e ) {
        // Error - redirect back to form
        flash.putAll( rc )  // Preserve form data
        messagebox.error( e.message )

        relocate( "users.create" )
    }
}

// GET - Show result
function show( event, rc, prc ) {
    var userId = flash.get( "userId", rc.id ?: 0 )
    prc.user = userService.find( userId )
}

// GET - Show form
function create( event, rc, prc ) {
    // Repopulate form if redirected with errors
    prc.formData = flash.getFlash()
}
```

## Advanced Patterns

### Complex Object Persistence

```boxlang
function saveWizard( event, rc, prc ) {
    // Store complex wizard state
    flash.put( "wizardData", {
        step: rc.step,
        userData: rc.userData,
        addressData: rc.addressData,
        paymentData: rc.paymentData
    } )

    relocate( "wizard.step#rc.step#" )
}

function wizardStep( event, rc, prc ) {
    // Retrieve wizard state
    prc.wizardData = flash.get( "wizardData", {} )

    // Keep for next step
    flash.keep( "wizardData" )
}
```

### Conditional Flash Messages

```boxlang
function update( event, rc, prc ) {
    var changes = userService.update( rc.id, rc )

    if ( changes.isEmpty() ) {
        messagebox.info( "No changes detected" )
    } else {
        messagebox.success(
            "Updated #changes.count()# field(s): #changes.keyList()#"
        )
    }

    relocate( "users.edit" )
}
```

### Flash with Interceptors

```boxlang
/**
 * FlashMessageInterceptor.cfc
 * Automatically adds flash messages to prc
 */
component extends="coldbox.system.Interceptor" {

    function preProcess( event, interceptData ) {
        // Auto-inflate flash messages to prc
        var messagebox = getInstance( "messagebox@cbmessagebox" )

        if ( messagebox.isEmpty() == false ) {
            event.setPrivateValue( "flashMessages", messagebox.getMessages() )
        }
    }
}
```

## Flash Scopes

### Session Scope (Default)

```boxlang
// config/ColdBox.cfc
coldbox = {
    flash: {
        scope: "session"  // Stored in session
    }
}
```

### Client Scope

```boxlang
coldbox = {
    flash: {
        scope: "client"  // Stored in client cookies
    }
}
```

### Cache Scope

```boxlang
coldbox = {
    flash: {
        scope: "cache",
        properties: {
            cacheName: "default",
            timeout: 5  // minutes
        }
    }
}
```

### Cluster Scope

```boxlang
coldbox = {
    flash: {
        scope: "cluster"  // For clustered environments
    }
}
```

## Best Practices

### Design Guidelines

1. **Use PRG Pattern**: Always redirect after POST
2. **Minimal Flash**: Store only necessary data
3. **Flash for UI**: Use for messages and temporary data only
4. **Auto Purge**: Enable autoPurge for automatic cleanup
5. **Type Safety**: Validate flash data types
6. **Security**: Never store sensitive data in flash
7. **User Feedback**: Always provide feedback after actions
8. **Form Repopulation**: Preserve form data on validation errors
9. **Message Clarity**: Write clear, actionable messages
10. **Consistent Styling**: Use message types consistently

### Common Patterns

```boxlang
// ✅ Good: POST-REDIRECT-GET
function save( event, rc, prc ) {
    userService.create( rc )
    messagebox.success( "User created" )
    relocate( "users.index" )
}

// ✅ Good: Flash for form repopulation
function store( event, rc, prc ) {
    if ( validationFails ) {
        flash.putAll( rc )
        messagebox.error( "Fix the errors" )
        relocate( "users.create" )
    }
}

// ✅ Good: Minimal flash usage
flash.put( "userId", user.id )  // Just the ID
```

## Common Pitfalls

### Pitfalls to Avoid

1. **No PRG**: Allowing form resubmission
2. **Large Objects**: Storing big objects in flash
3. **Sensitive Data**: Flash contains passwords/tokens
4. **No Purge**: Flash data accumulating
5. **Missing Messages**: No user feedback
6. **Vague Messages**: "Error occurred" without details
7. **Flash Abuse**: Using flash as session storage
8. **No Validation**: Not checking flash data types
9. **keep() Misuse**: Keeping flash indefinitely
10. **Poor UX**: Multiple redirects losing context

### Anti-Patterns

```boxlang
// ❌ Bad: No redirect after POST
function save( event, rc, prc ) {
    userService.create( rc )
    event.setView( "users/show" )  // Browser refresh = duplicate submission
}

// ✅ Good: POST-REDIRECT-GET
function save( event, rc, prc ) {
    var user = userService.create( rc )
    flash.put( "userId", user.id )
    relocate( "users.show" )
}

// ❌ Bad: Storing entire entity in flash
flash.put( "user", largeUserObject )  // Memory overhead

// ✅ Good: Store only ID
flash.put( "userId", user.id )

// ❌ Bad: No user feedback
function delete( event, rc, prc ) {
    userService.delete( rc.id )
    relocate( "users.index" )  // Silent delete
}

// ✅ Good: With feedback
function delete( event, rc, prc ) {
    userService.delete( rc.id )
    messagebox.success( "User deleted" )
    relocate( "users.index" )
}
```

## Related Skills

- [Request Context](coldbox-request-context.md) - Request/response patterns
- [Handler Development](handler-development.md) - Handler patterns
- [View Rendering](view-rendering.md) - View patterns

## References

- [Flash RAM](https://coldbox.ortusbooks.com/the-basics/flash-ram)
- [CBMessageBox](https://forgebox.io/view/cbmessagebox)
- [POST-REDIRECT-GET Pattern](https://en.wikipedia.org/wiki/Post/Redirect/Get)
