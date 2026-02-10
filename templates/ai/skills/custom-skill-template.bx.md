---
name: |skillName|
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

   ```boxlang
   /**
    * Example implementation
    */
   class MyClass {

       function init() {
           // Implementation
           return this
       }

       function myMethod() {
           // Method implementation
       }
   }
   ```

2. **Step Two**: Describe the second step

   ```boxlang
   // More example code with BoxLang syntax
   var result = someService.getData()
       .filter( ( item ) => item.active )
       .map( ( item ) => item.name )
   ```

3. **Step Three**: Continue with additional steps

## Code Examples

### Example 1: Basic Usage

```boxlang
/**
 * Provide a complete, working example
 */
class MyHandler {

    property name="userService" inject="UserService";

    /**
     * Example action
     */
    function index( event, rc, prc ) {
        prc.users = userService.getAll()

        event.setView( "users/index" )
    }
}
```

### Example 2: Advanced Pattern

```boxlang
/**
 * Show more complex usage with BoxLang features
 */
class MyService {

    property name="wirebox" inject="wirebox";

    function processData( required array data ) {
        return arguments.data
            .filter( ( item ) => item.status == "active" )
            .map( ( item ) => {
                return {
                    "id": item.id,
                    "name": item.name,
                    "processed": true
                }
            } )
    }

    function getRepository() {
        return wirebox.getInstance( "MyRepository" )
    }
}
```

## Best Practices

- Use BoxLang class syntax for modern components
- Leverage lambda expressions for cleaner code
- Follow BoxLang naming conventions
- Document all public methods with JavaDoc-style comments
- Use type hints where beneficial
- Implement proper dependency injection

## Testing Approach

```boxlang
/**
 * Example test case using TestBox BDD
 */
class MyHandlerTest extends BaseTestCase {

    function beforeAll() {
        super.beforeAll()
    }

    function run() {
        describe( "|skillName| Tests", () => {
            it( "should implement feature", () => {
                var result = getInstance( "MyHandler" ).index(
                    event = getRequestContext(),
                    rc = {},
                    prc = {}
                )

                expect( result ).notToBeNull()
            } )
        } )
    }
}
```

## Common Mistakes

- **Using component syntax instead of class**: BoxLang prefers `class` over `component`
- **Not using lambda expressions**: Take advantage of modern functional programming
- **Missing type hints**: While optional, type hints improve code clarity
- **Inconsistent formatting**: Follow BoxLang style guidelines

## References

- Link to relevant documentation
- Related skills
- External resources
- BoxLang documentation: <https://boxlang.io/docs>
