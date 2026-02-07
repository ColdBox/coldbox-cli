# CBi18n Internationalization Module Guidelines

## Overview

CBi18n provides comprehensive internationalization (i18n) and localization support for ColdBox applications. It supports both Java .properties files and JSON resource bundles with locale switching, resource management, and formatting utilities.

## Installation

```bash
box install cbi18n
```

## Configuration

In `config/ColdBox.cfc`:

```boxlang
moduleSettings = {
    cbi18n = {
        // Default resource bundle path (without locale/extension)
        defaultResourceBundle = "includes/i18n/main",
        
        // Default locale (Java format: lang_COUNTRY)
        defaultLocale = "en_US",
        
        // Locale storage (session, cookie, or custom)
        localeStorage = "cookieStorage@cbstorages",
        
        // Text shown for missing translations
        unknownTranslation = "**NOT FOUND**",
        
        // Log unknown translations
        logUnknownTranslation = true,
        
        // Additional resource bundles
        resourceBundles = {
            admin = "includes/i18n/admin",
            emails = "includes/i18n/emails"
        }
    }
}
```

## Resource Bundle Files

### Java Properties Format

```properties
# includes/i18n/main_en_US.properties
welcome.message=Welcome {1}!
user.login=Login
user.logout=Logout
btn.submit=Submit
btn.cancel=Cancel

error.required=The field {1} is required
error.email=Please provide a valid email address

date.format=MM/dd/yyyy
currency.symbol=$
```

```properties
# includes/i18n/main_es_ES.properties
welcome.message=¡Bienvenido {1}!
user.login=Iniciar Sesión
user.logout=Cerrar Sesión
btn.submit=Enviar
btn.cancel=Cancelar

error.required=El campo {1} es requerido
error.email=Por favor proporcione un email válido

date.format=dd/MM/yyyy
currency.symbol=€
```

### JSON Format

```json
// includes/i18n/main_en_US.json
{
    "welcome": {
        "message": "Welcome {1}!"
    },
    "user": {
        "login": "Login",
        "logout": "Logout"
    },
    "btn": {
        "submit": "Submit",
        "cancel": "Cancel"
    }
}
```

```json
// includes/i18n/main_es_ES.json
{
    "welcome": {
        "message": "¡Bienvenido {1}!"
    },
    "user": {
        "login": "Iniciar Sesión",
        "logout": "Cerrar Sesión"
    },
    "btn": {
        "submit": "Enviar",
        "cancel": "Cancelar"
    }
}
```

## Basic Usage

### Injection

```boxlang
// In your components
property name="i18n" inject="i18n@cbi18n";
property name="resourceService" inject="resourceService@cbi18n";

// Or use mixin helpers in handlers/views/layouts
var locale = getFWLocale()
var translated = getResource( "welcome.message" )
```

### Get Resources (Translations)

```boxlang
// Simple translation
<h1>#getResource( "welcome.message" )#</h1>

// With replacements (positional)
#getResource( 
    resource = "welcome.message",
    values = [ "John Doe" ]
)#
// Output: Welcome John Doe!

// With replacements (named)
#getResource(
    resource = "user.greeting",
    values = { name: "John", age: 30 }
)#
// Resource: Hello {name}, you are {age} years old

// From specific bundle
#getResource(
    resource = "admin.dashboard.title",
    bundle = "admin"
)#

// Short alias
#$r( "btn.submit" )#
```

## Locale Management

### Get/Set Locale

```boxlang
// Get current locale
var currentLocale = getFWLocale()
// Returns: en_US

// Set user locale
setFWLocale( "es_ES" )

// Set with defaults
setFWLocale( "es_ES", "Europe/Madrid" )
```

### Change Locale Handler

```boxlang
class Language extends coldbox.system.EventHandler {
    function changeLocale( event, rc, prc ) {
        // Set new locale
        setFWLocale( rc.locale ?: "en_US" )
        
        // Redirect back
        var referer = event.getHTTPHeader( "Referer", "/" )
        relocate( url = referer )
    }
}
```

### Locale Selector View

```cfml
<form action="#event.buildLink( 'language.changeLocale' )#" method="POST">
    <select name="locale" onchange="this.form.submit()">
        <option value="en_US" #getFWLocale() == "en_US" ? "selected" : ""#>
            English (US)
        </option>
        <option value="es_ES" #getFWLocale() == "es_ES" ? "selected" : ""#>
            Español (España)
        </option>
        <option value="fr_FR" #getFWLocale() == "fr_FR" ? "selected" : ""#>
            Français
        </option>
    </select>
</form>
```

## Localization Functions

### Date Formatting

```boxlang
// Format date for current locale
var formattedDate = i18n.formatDate( now() )

// Custom date format
var formattedDate = i18n.formatDate(
    date = now(),
    format = "medium" // full, long, medium, short
)

// Parse date from locale format
var parsedDate = i18n.parseDate( "02/07/2024" )
```

### Number Formatting

```boxlang
// Format number
var formatted = i18n.formatNumber( 1234567.89 )
// US: 1,234,567.89
// ES: 1.234.567,89

// Currency
var formatted = i18n.formatCurrency( 1234.56 )
// US: $1,234.56
// ES: 1.234,56 €

// Percentage
var formatted = i18n.formatPercent( 0.75 )
// Output: 75%
```

### Locale Information

```boxlang
// Get language name
var language = i18n.getLanguage()
// en_US → English

// Get country name
var country = i18n.getCountry()
// en_US → United States

// Get currency symbol
var symbol = i18n.getCurrencySymbol()
// en_US → $
// es_ES → €

// Get available locales
var locales = i18n.getAvailableLocales()
```

## Common Patterns

### Multilingual Handler

```boxlang
class Products extends coldbox.system.EventHandler {
    property name="productService" inject;
    
    function index( event, rc, prc ) {
        var locale = getFWLocale()
        
        prc.products = productService.getAll( locale )
        prc.pageTitle = getResource( "products.title" )
        
        event.setView( "products/index" )
    }
}
```

### Localized Flash Messages

```boxlang
function save( event, rc, prc ) {
    try {
        userService.create( rc )
        flash.put( "success", getResource( "user.created.success" ) )
        relocate( "users.index" )
    } catch ( ValidationException e ) {
        flash.put( "error", getResource( "user.created.error" ) )
        relocate( "users.new" )
    }
}
```

### Email Templates

```boxlang
function sendWelcomeEmail( required user ) {
    var locale = user.getLocale()
    
    mailService.send(
        to = user.getEmail(),
        subject = i18n.getResource(
            resource = "email.welcome.subject",
            locale = locale,
            values = [ user.getFirstName() ]
        ),
        body = renderer.renderView(
            view = "emails/welcome",
            args = { user = user, locale = locale }
        )
    )
}
```

### Validation Messages

Integration with cbvalidation:

```boxlang
// Validation with i18n
function save( event, rc, prc ) {
    var locale = getFWLocale()
    
    prc.validationResult = validate(
        target = rc,
        constraints = "userRegistration",
        locale = locale
    )
    
    if ( prc.validationResult.hasErrors() ) {
        // Errors are already localized
        flash.put( "errors", prc.validationResult.getAllErrors() )
        relocate( "users.new" )
    }
}
```

## Resource Bundle Hierarchy

CBi18n supports hierarchical resource bundles:

```
includes/i18n/main.properties        (default/fallback)
includes/i18n/main_en.properties     (English)
includes/i18n/main_en_US.properties  (US English)
includes/i18n/main_en_GB.properties  (British English)
includes/i18n/main_es.properties     (Spanish)
includes/i18n/main_es_ES.properties  (Spain Spanish)
includes/i18n/main_es_MX.properties  (Mexican Spanish)
```

Lookup order for `en_US`:
1. `main_en_US.properties`
2. `main_en.properties`
3. `main.properties`

## Best Practices

- **Use Java locale format** - Always use lang_COUNTRY (en_US, es_ES, fr_FR)
- **Organize by feature** - Group related translations
- **Use JSON for complex structures** - Easier to maintain than .properties
- **Provide fallback locale** - Always have default translations
- **Log missing translations** - Enable logUnknownTranslation in development
- **Cache resource bundles** - CBi18n caches for performance
- **Use placeholders** - Dynamic content with {1}, {2} or {name}
- **Translate all user-facing text** - Don't hardcode strings
- **Test all locales** - Verify translations render correctly
- **Store user preference** - Remember user's locale choice

## Documentation

For complete CBi18n documentation, locale utilities, and advanced features, visit:
https://coldbox-i18n.ortusbooks.com
