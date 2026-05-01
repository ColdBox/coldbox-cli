---
name: coldbox-docbox-annotations
description: "Use this skill when writing JavaDoc-style DocBox comments on BoxLang or CFML classes, properties, functions, and arguments; adding @author/@version/@since/@return/@throws/@deprecated block tags; using @doc.type for generic array/struct types; or preparing source code for API documentation generation with DocBox."
---

# DocBox Annotations

## When to Use This Skill

Use this skill when:
- Adding documentation comments to BoxLang or CFML components
- Annotating functions with parameter and return type documentation
- Marking deprecated APIs or specifying generic types
- Preparing source code so DocBox can generate API docs

## Language Mode Reference

Examples use **BoxLang (`.bx`)** syntax by default. Adapt for your target language:

| Concept | BoxLang (`.bx`) | CFML (`.cfc`) |
|---------|-----------------|---------------|
| Class declaration | `class [extends="..."] {` | `component [extends="..."] {` |
| DI annotation | `@inject` above `property name="svc";` | `property name="svc" inject="svc";` |
| View templates | `.bxm` suffix | `.cfm` / `.cfml` suffix |
| Tag prefix | `<bx:if>`, `<bx:output>`, `<bx:set>` | `<cfif>`, `<cfoutput>`, `<cfset>` |

> **CFML Compat Mode**: With BoxLang + CFML Compat module, `.bx` and `.cfc` files coexist freely. BoxLang-native classes use `class {}` (`.bx` files); CFML-compat classes use `component {}` (`.cfc` files).

## Comment Block Syntax

DocBox parses `/** ... */` JavaDoc-style comments placed immediately above the element being documented.

```js
/**
 * Short description (first line/sentence is used as the summary).
 *
 * Longer description can span multiple lines and supports
 * basic HTML for formatting when rendered in HTML output.
 *
 * @author  Jane Smith
 * @version 2.0
 * @since   1.0
 */
```

## Annotating a Class / Component

### BoxLang

```js
/**
 * Manages user authentication and session lifecycle.
 *
 * @author  Luis Majano
 * @version 1.5
 * @since   1.0
 */
class extends="coldbox.system.EventHandler" {
    // ...
}
```

### CFML

```cfscript
/**
 * Manages user authentication and session lifecycle.
 *
 * @author  Luis Majano
 * @version 1.5
 * @since   1.0
 */
component extends="coldbox.system.EventHandler" {
    // ...
}
```

## Annotating Properties

Place the comment block directly above the property declaration.

```js
/**
 * The WireBox injector instance.
 */
property name="wirebox" inject="wirebox";

/**
 * The underlying cache provider.
 * @deprecated Use the new CacheBox provider instead
 */
property name="legacyCacheProvider" type="any";

/**
 * List of allowed HTTP methods for this handler.
 */
property name="allowedMethods" type="array" default="[]";
```

## Annotating Functions

Place the comment block immediately before the function signature. Arguments are documented with `@argName` tags; the return value with `@return`; exceptions with `@throws`.

```js
/**
 * Creates and persists a new user account.
 *
 * @email        The user's email address — must be unique
 * @password     Plain-text password; will be hashed before storage
 * @displayName  Optional display name shown in the UI
 * @return       Populated User entity after persistence
 * @throws       InvalidEmail     When the email format is not valid
 * @throws       DuplicateEmail   When the email already exists
 */
User function createUser(
    required string email,
    required string password,
    string displayName = ""
) { ... }
```

### Argument Sub-Annotations (Dot Notation)

Use dot notation to add metadata to a specific argument without affecting others.

```js
/**
 * Fetches a record by its primary key.
 *
 * @id          The primary key value
 * @id.since    2.0
 * @format      Output format: "entity" | "struct" | "json"
 * @format.deprecated Use the outputFormat argument instead
 * @outputFormat  New preferred argument: "entity" | "struct" | "json"
 */
any function findById( required numeric id, string format = "entity", string outputFormat = "entity" ) { ... }
```

## Core Block Tags Reference

| Tag | Applies To | Purpose |
|-----|-----------|---------|
| `@author` | Class | Author name and optional contact |
| `@version` | Class | Current version number |
| `@since` | Class / Function | First version this element appeared |
| `@return` | Function | Description of the return value |
| `@throws` | Function | Exception types the function can throw (one per exception) |
| `@deprecated` | Any | Mark element as deprecated; add migration hint |
| `@{argName}` | Function | Document a specific argument |
| `@{argName}.{attr}` | Function | Sub-annotation for an argument (e.g., `.deprecated`, `.since`) |

## Using `@doc.type` for Generic Types

BoxLang/CFML has no generics, but `@doc.type` tells DocBox what kind of values an `array`, `struct`, or `any` typed element actually contains:

```js
/**
 * Returns all active orders for a customer.
 *
 * @return  An array of Order model instances
 * @doc.return.type  Order
 */
array function getOrders() { ... }

/**
 * Map of role names to permission arrays.
 *
 * @doc.type  struct<string,array<string>>
 */
property name="rolePermissions" type="struct";
```

## Inline HTML in Descriptions

DocBox renders descriptions as HTML, so you can use basic markup:

```js
/**
 * Processes the event request.
 *
 * <p>This is the primary entry point called by the ColdBox framework
 * for every HTTP request routed to this handler.</p>
 *
 * <ul>
 *   <li>Validates the incoming request</li>
 *   <li>Delegates to the appropriate service</li>
 *   <li>Prepares view data</li>
 * </ul>
 *
 * @event  The RequestContext (rc/prc scope container)
 */
void function index( event, rc, prc ) { ... }
```

## Complete ColdBox Handler Example

```js
/**
 * Handles all user-related HTTP endpoints.
 *
 * Supports CRUD for the User entity, plus authentication
 * and profile management operations.
 *
 * @author  Dev Team
 * @version 3.0
 * @since   1.0
 */
class extends="coldbox.system.EventHandler" {

    /**
     * @inject
     */
    property name="userService" inject="UserService";

    /**
     * List all active users. Supports pagination via `page` and `pageSize` RC params.
     *
     * @event    RequestContext
     * @rc       Request Collection
     * @prc      Private Request Collection
     * @return   void
     */
    function index( event, rc, prc ) {
        prc.users = userService.list(
            page     : rc.page     ?: 1,
            pageSize : rc.pageSize ?: 25
        )
        event.setView( "users/index" )
    }

    /**
     * Display a single user profile.
     *
     * @event    RequestContext
     * @rc       Request Collection - expects `rc.userId`
     * @prc      Private Request Collection
     * @throws   EntityNotFound  When the userId does not match any user
     */
    function show( event, rc, prc ) {
        prc.user = userService.findOrFail( rc.userId )
        event.setView( "users/show" )
    }

    /**
     * Create a new user account from posted form data.
     *
     * @event    RequestContext
     * @rc       Request Collection - expects `rc.email`, `rc.password`
     * @prc      Private Request Collection
     * @return   void
     */
    function create( event, rc, prc ) {
        prc.user = userService.create( rc )
        relocate( "users.show", { userId: prc.user.getId() } )
    }

    /**
     * Delete a user by ID.
     *
     * @event       RequestContext
     * @rc          Request Collection - expects `rc.userId`
     * @prc         Private Request Collection
     * @since       2.0
     * @deprecated  Admin deletion moved to users.admin.delete
     */
    function delete( event, rc, prc ) { ... }
}
```

## Common Mistakes to Avoid

| Mistake | Correct Pattern |
|---------|----------------|
| `/* ... */` (single star) | `/** ... */` (double star — DocBox only parses `/**`) |
| Skipping `@return` on non-void functions | Always document the return type and what it contains |
| Using `@param` (Javadoc Java style) | Use `@argName` matching the actual argument name |
| Placing comment after the declaration | Comment must be **immediately above** the declaration |
| Empty comment blocks `/** */` | Add at least a one-sentence description |
