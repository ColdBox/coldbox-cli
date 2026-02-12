---
title: CBMessagebox Module Guidelines
description: Flash messaging system for displaying notifications and alerts across requests
---

# CBMessagebox Module Guidelines

## Overview

CBMessagebox provides flash scope messaging for ColdBox applications with support for different message types (info, success, warning, error) and customizable rendering.

## Installation

```bash
box install cbmessagebox
```

## Usage

### Setting Messages

```boxlang
// In handlers
messagebox.info( "User profile updated" )
messagebox.success( "Changes saved successfully!" )
messagebox.warning( "Please verify your email address" )
messagebox.error( "An error occurred while processing your request" )

// With multiple messages
messagebox.info( "First message" )
messagebox.info( "Second message" )

// Clear messages
messagebox.clearMessage( "info" )
messagebox.clearAll()
```

### Rendering Messages

```cfml
<!--- In views/layouts --->
#messageBox.renderit()#

<!--- Custom message type --->
#messageBox.renderMessage( "success" )#

<!--- Check if has messages --->
<cfif messageBox.hasMessage()>
    #messageBox.renderit()#
</cfif>

<!--- Check specific type --->
<cfif messageBox.hasMessage( "error" )>
    #messageBox.renderMessage( "error" )#
</cfif>
```

### Custom Templates

```boxlang
// Override default templates
messagebox.setTemplate( 
    "<div class='alert alert-{type}'>{message}</div>"
)
```

## Common Patterns

```boxlang
function save( event, rc, prc ) {
    try {
        userService.update( rc.id, rc )
        messagebox.success( "User updated successfully" )
        relocate( "users.index" )
    } catch ( ValidationException e ) {
        messagebox.error( "Validation failed: #e.message#" )
        relocate( "users.edit" )
    }
}
```

## Documentation

https://github.com/coldbox-modules/cbmessagebox
