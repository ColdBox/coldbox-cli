# CBValidation Module Guidelines

## Overview

CBValidation is a server-side validation engine for ColdBox applications that provides a unified approach to object, struct, and form validation through declarative constraint rules.

## Installation

```bash
box install cbvalidation
```

## Configuration

In `config/ColdBox.cfc`:

```boxlang
moduleSettings = {
    cbvalidation = {
        // Custom validation manager (optional)
        manager = "ValidationManager@cbvalidation",
        
        // Shared constraints for reuse
        sharedConstraints = {
            userRegistration = {
                email = { required=true, type="email" },
                password = { required=true, size="8..50" },
                firstName = { required=true, size="1..50" },
                lastName = { required=true, size="1..50" }
            },
            userUpdate = {
                email = { required=true, type="email" },
                firstName = { required=true, size="1..50" },
                lastName = { required=true, size="1..50" }
            }
        }
    }
}
```

## Basic Usage

### In Handlers

```boxlang
class Users extends coldbox.system.EventHandler {
    function save( event, rc, prc ) {
        // Define constraints
        var constraints = {
            firstName = { required=true, size="1..100" },
            lastName = { required=true, size="1..100" },
            email = { required=true, type="email" },
            age = { required=true, type="numeric", min=18, max=120 }
        }
        
        // Validate
        prc.validationResult = validate(
            target = rc,
            constraints = constraints
        )
        
        if ( prc.validationResult.hasErrors() ) {
            flash.put( "errors", prc.validationResult.getAllErrors() )
            flash.put( "data", rc )
            relocate( "users.new" )
        }
        
        // Save user
        userService.create( rc )
        relocate( "users.index" )
    }
}
```

### Using Shared Constraints

```boxlang
function register( event, rc, prc ) {
    prc.validationResult = validate(
        target = rc,
        constraints = "userRegistration" // Reference shared constraint
    )
    
    if ( prc.validationResult.hasErrors() ) {
        // Handle errors
    }
}
```

### ValidateOrFail

Throws exception on validation failure:

```boxlang
function save( event, rc, prc ) {
    try {
        validateOrFail(
            target = rc,
            constraints = "userRegistration"
        )
        
        userService.create( rc )
        relocate( "users.index" )
    } catch ( ValidationException e ) {
        flash.put( "errors", e.getValidationResult().getAllErrors() )
        relocate( "users.new" )
    }
}
```

## Available Constraints

### required

Field must have a value:

```boxlang
email = { required = true }
```

### type

Validate specific data types:

```boxlang
// Available types: alpha, array, binary, boolean, component, 
// creditcard, date, email, eurodate, float, GUID, integer,
// ipaddress, json, numeric, query, ssn, string, struct,
// telephone, url, usdate, UUID, xml, zipcode

email = { type = "email" }
age = { type = "numeric" }
data = { type = "struct" }
```

### size

Length or size validation:

```boxlang
// Exact size
username = { size = 10 }

// Range
password = { size = "8..50" }
firstName = { size = "1..100" }
```

### min / max

Numeric min/max values:

```boxlang
age = { min = 18, max = 120 }
quantity = { min = 1 }
discount = { max = 100 }
```

### range

Value must be in range:

```boxlang
age = { range = "18..65" }
temperature = { range = "-20..50" }
```

### regex

Regular expression matching:

```boxlang
zipCode = { regex = "^\d{5}(-\d{4})?$" }
phoneNumber = { regex = "^\d{3}-\d{3}-\d{4}$" }
```

### sameAs / sameAsNoCase

Must match another field:

```boxlang
passwordConfirm = { sameAs = "password" }
emailConfirm = { sameAsNoCase = "email" }
```

### notSameAs / notSameAsNoCase

Must NOT match another field:

```boxlang
newPassword = { notSameAs = "oldPassword" }
```

### inList

Value must be in list:

```boxlang
status = { inList = "active,inactive,pending" }
country = { inList = "US,CA,MX,UK" }
```

### discrete

Discrete math comparisons:

```boxlang
// gt (greater than)
age = { discrete = "gt:17" }

// gte (greater than or equal)
quantity = { discrete = "gte:1" }

// lt (less than)
discount = { discrete = "lt:100" }

// lte (less than or equal)
age = { discrete = "lte:65" }

// eq (equal)
status = { discrete = "eq:1" }

// neq (not equal)
status = { discrete = "neq:0" }
```

### unique

Check database uniqueness:

```boxlang
email = {
    unique = {
        table = "users",
        column = "email"
    }
}

username = {
    unique = {
        table = "users",
        column = "username"
    }
}
```

### accepted

Must be yes, on, 1, or true:

```boxlang
termsAccepted = { accepted = true }
agreeToPolicy = { accepted = true }
```

### date comparisons

```boxlang
// after
startDate = { after = "2024-01-01" }

// afterOrEqual
validFrom = { afterOrEqual = now() }

// before
endDate = { before = "2024-12-31" }

// beforeOrEqual
expires = { beforeOrEqual = now() }

// dateEquals
birthDate = { dateEquals = "1990-01-01" }
```

### requiredIf

Required if another field has specific value:

```boxlang
shippingAddress = {
    requiredIf = {
        otherField = "shipToDifferentAddress",
        otherValue = true
    }
}
```

### requiredUnless

Required unless another field has specific value:

```boxlang
billingAddress = {
    requiredUnless = {
        otherField = "sameAsShipping",
        otherValue = true
    }
}
```

### isEmpty / isNotEmpty

```boxlang
notes = { isEmpty = true }
description = { isNotEmpty = true }
```

## Object-Based Constraints

Define constraints in your model:

```boxlang
component accessors="true" {
    property name="firstName";
    property name="lastName";
    property name="email";
    property name="password";
    
    this.constraints = {
        firstName = { required=true, size="1..50" },
        lastName = { required=true, size="1..50" },
        email = { required=true, type="email" },
        password = { required=true, size="8..50" }
    }
}

// Validation in handler
function save( event, rc, prc ) {
    var user = populateModel( "User" )
    
    prc.validationResult = validate( user )
    
    if ( prc.validationResult.hasErrors() ) {
        // Handle errors
    }
}
```

## Constraint Profiles

Define multiple validation profiles:

```boxlang
component {
    this.constraints = {
        email = { required=true, type="email" },
        password = { required=true, size="8..50" },
        firstName = { required=true, size="1..50" },
        lastName = { required=true, size="1..50" },
        phone = { required=false, type="telephone" }
    }
    
    this.constraintProfiles = {
        registration = "email,password,firstName,lastName",
        update = "firstName,lastName,phone",
        passwordChange = "password"
    }
}

// Use profile in validation
prc.validationResult = validate(
    target = user,
    profiles = "registration"
)
```

## Nested Constraints

Validate nested structures:

```boxlang
constraints = {
    "address" = {
        required = true,
        type = "struct",
        constraints = {
            street = { required=true, size="5..100" },
            city = { required=true, size="2..50" },
            state = { required=true, size=2 },
            zip = { required=true, type="numeric", size=5 }
        }
    }
}
```

## Array Item Constraints

Validate array items:

```boxlang
constraints = {
    "tags" = {
        required = true,
        type = "array",
        items = {
            type = "string",
            size = "1..50"
        }
    },
    "emails" = {
        type = "array",
        items = {
            type = "email"
        }
    }
}
```

## Custom UDF Validators

Define custom validation logic:

```boxlang
constraints = {
    email = {
        udf = ( value, target ) => {
            // Custom validation logic
            return !isNull( value ) && value.findNoCase( "@example.com" ) > 0
        },
        udfMessage = "Email must be from example.com domain"
    },
    
    password = {
        udf = ( value, target ) => {
            // Check password strength
            if ( isNull( value ) ) return false
            return reFindNoCase( "[A-Z]", value ) && 
                   reFindNoCase( "[0-9]", value ) &&
                   reFindNoCase( "[!@#$%^&*]", value )
        },
        udfMessage = "Password must contain uppercase, number, and special character"
    }
}
```

## Custom Validator Components

Create reusable validators:

```boxlang
// models/validators/UniqueEmailValidator.cfc
component singleton {
    property name="userService" inject;
    
    function getName() {
        return "UniqueEmailValidator"
    }
    
    function validate(
        required validationResult,
        required target,
        required field,
        targetValue,
        validationData
    ) {
        // Check if email exists
        var exists = userService.emailExists( arguments.targetValue )
        
        if ( exists ) {
            validationResult.addError(
                field = arguments.field,
                message = "Email address already in use"
            )
            return false
        }
        
        return true
    }
}

// Usage in constraints
constraints = {
    email = {
        required = true,
        type = "email",
        UniqueEmailValidator = {}
    }
}
```

## Method Validators

Validate using model methods:

```boxlang
component {
    property name="email";
    property name="username";
    
    this.constraints = {
        email = {
            method = "validateEmail"
        },
        username = {
            method = "validateUsername"
        }
    }
    
    function validateEmail( value, target ) {
        // Custom email validation
        if ( isNull( value ) ) return false
        return value.len() > 5 && value.find( "@" ) > 0
    }
    
    function validateUsername( value, target ) {
        // Custom username validation
        if ( isNull( value ) ) return false
        return value.len() >= 3 && !reFindNoCase( "[^a-z0-9_]", value )
    }
}
```

## Validation Results

Working with validation results:

```boxlang
var result = validate( target=rc, constraints=constraints )

// Check for errors
if ( result.hasErrors() ) {
    // Get all errors
    var allErrors = result.getAllErrors()
    // Returns: { fieldName: ["error message 1", "error message 2"] }
    
    // Get errors for specific field
    var emailErrors = result.getFieldErrors( "email" )
    
    // Get first error message
    var firstError = result.getAllErrorMessages()[ 1 ]
    
    // Get error count
    var errorCount = result.getErrorCount()
}

// Get result data
var resultData = result.getResultStruct()
// Returns: { errors: {}, errorMessages: [], hasErrors: false }
```

## Common Patterns

### Form Validation

```boxlang
function processContactForm( event, rc, prc ) {
    var constraints = {
        name = { required=true, size="1..100" },
        email = { required=true, type="email" },
        subject = { required=true, size="1..200" },
        message = { required=true, size="10..5000" }
    }
    
    prc.validationResult = validate( target=rc, constraints=constraints )
    
    if ( prc.validationResult.hasErrors() ) {
        flash.put( "errors", prc.validationResult.getAllErrors() )
        flash.put( "data", rc )
        relocate( "contact.form" )
    }
    
    mailService.sendContactEmail( rc )
    flash.put( "success", "Message sent successfully!" )
    relocate( "contact.thankyou" )
}
```

### API Validation

```boxlang
function createUser( event, rc, prc ) {
    try {
        validateOrFail(
            target = rc,
            constraints = "userRegistration"
        )
        
        var user = userService.create( rc )
        
        event.renderData(
            data = user,
            statusCode = 201
        )
    } catch ( ValidationException e ) {
        event.renderData(
            data = {
                error = "Validation failed",
                errors = e.getValidationResult().getAllErrors()
            },
            statusCode = 422
        )
    }
}
```

### Multi-Step Form Validation

```boxlang
function step1( event, rc, prc ) {
    var constraints = {
        firstName = { required=true },
        lastName = { required=true },
        email = { required=true, type="email" }
    }
    
    if ( event.isPOST() ) {
        prc.validationResult = validate( target=rc, constraints=constraints )
        
        if ( !prc.validationResult.hasErrors() ) {
            session.registrationData.step1 = rc
            relocate( "registration.step2" )
        }
    }
    
    event.setView( "registration/step1" )
}
```

### Conditional Validation

```boxlang
function saveAddress( event, rc, prc ) {
    var constraints = {
        addressType = { required=true, inList="residential,business" },
        street = { required=true },
        city = { required=true },
        state = { required=true },
        zipCode = { required=true }
    }
    
    // Add business-specific fields if needed
    if ( rc.addressType == "business" ) {
        constraints.companyName = { required=true }
        constraints.taxId = { required=true }
    }
    
    prc.validationResult = validate( target=rc, constraints=constraints )
}
```

## i18n Integration

CBValidation integrates with cbi18n for internationalized error messages:

```properties
# resources/i18n/validation_en_US.properties
User.email.required=Email address is required
User.email.type=Please provide a valid email address
User.password.size=Password must be between 8 and 50 characters
User.firstName.required=First name is required
```

```boxlang
// Use with locale
prc.validationResult = validate(
    target = user,
    constraints = "userRegistration",
    locale = session.locale
)
```

## Best Practices

- **Use shared constraints** - Define reusable constraints in config
- **Validate early** - Validate at entry points (handlers, APIs)
- **Use specific types** - Leverage type constraints for better validation
- **Create custom validators** - Encapsulate complex validation logic
- **Provide clear messages** - Use custom messages for better UX
- **Validate on both client and server** - Never trust client-side only
- **Use constraint profiles** - Different validation rules for different contexts
- **Handle errors gracefully** - Provide helpful feedback to users
- **Test validation rules** - Write tests for complex validators

## Documentation

For complete CBValidation documentation, all constraints, and advanced features, visit:
https://coldbox-validation.ortusbooks.com
