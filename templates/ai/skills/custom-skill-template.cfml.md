---
name: |skillName|
description: Project-specific CFML implementation playbook with activation triggers, step-by-step patterns, code examples, testing guidance, and maintenance notes.
category: custom
triggers:
  - "Add trigger keywords here"
  - "When implementing [feature]"
  - "For [specific use case]"
confidence: high
---

# |skillName| Skill

## When to Use

Describe when this skill should be activated. Be specific about:

- User requests that should trigger this skill
- Project contexts where this applies
- Specific keywords or phrases that indicate this skill is needed

## Implementation Pattern

### Overview

Provide a high-level description of the implementation approach.

### Step-by-Step Guide

1. **Step One**: Describe the first step

   ```cfml
   /**
    * Example implementation
    */
   component {

       function init() {
           // Implementation
           return this;
       }

       function myMethod() {
           // Method implementation
       }
   }
   ```

2. **Step Two**: Describe the second step

   ```cfml
   // More example code with CFML syntax
   var result = [];
   for( var item in collection ) {
       if( item.active ) {
           result.append( item );
       }
   }
   ```

3. **Step Three**: Continue with additional steps

## Code Examples

### Example 1: Basic Usage

```cfml
/**
 * Provide a complete, working example
 */
component {

    property name="userService" inject="UserService";

    /**
     * Example action
     */
    function index( event, rc, prc ) {
        prc.users = userService.getAll();

        event.setView( "users/index" );
    }
}
```

### Example 2: Advanced Pattern

```cfml
/**
 * Show more complex usage
 */
component singleton {

    property name="wirebox" inject="wirebox";

    function processData( required array data ) {
        var processed = [];

        for( var item in arguments.data ) {
            if( item.status == "active" ) {
                processed.append({
                    "id": item.id,
                    "name": item.name,
                    "processed": true
                });
            }
        }

        return processed;
    }

    function getRepository() {
        return wirebox.getInstance( "MyRepository" );
    }
}
```

## Best Practices

- Use component syntax for CFML compatibility
- Follow implicit accessors pattern for properties
- Document all public methods with JavaDoc-style comments
- Use semicolons consistently
- Implement proper dependency injection
- Follow CFML naming conventions (camelCase)

## Testing Approach

```cfml
/**
 * Example test case using TestBox BDD
 */
component extends="tests.resources.BaseTestCase" {

    function beforeAll() {
        super.beforeAll();
    }

    function run() {
        describe( "|skillName| Tests", function() {
            it( "should implement feature", function() {
                var result = getInstance( "MyHandler" ).index(
                    event = getRequestContext(),
                    rc = {},
                    prc = {}
                );

                expect( result ).notToBeNull();
            });
        });
    }
}
```

## Common Mistakes

- **Not using semicolons**: CFML requires semicolons at statement endings
- **Missing var scope**: Always scope variables with `var` in functions
- **Incorrect closure syntax**: Use traditional function syntax for better compatibility
- **Not handling null values**: Always check for existence before using variables

## References

- Link to relevant documentation
- Related skills
- External resources
- CFML documentation: <https://cfdocs.org>
