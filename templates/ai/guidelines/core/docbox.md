# DocBox API Documentation Guidelines

## Overview

DocBox is a JavaDoc-style API documentation generator for BoxLang and CFML codebases. It parses component metadata and structured comment blocks (docblocks) to generate comprehensive HTML, JSON, or UML documentation.

## Installation

### CommandBox Installation

```bash
# Install as development dependency
box install docbox --saveDev

# Install CommandBox module for CLI usage
box install commandbox-docbox
```

### BoxLang Module

```bash
# CommandBox with BoxLang
box install bx-docbox

# Native BoxLang runtime
install-bx-module bx-docbox
```

## Documenting Your Code

### Docblock Format

DocBox uses JavaDoc-style comment blocks placed above components, properties, functions, and arguments.

```boxlang
/**
 * This is a DocBox comment block
 * Multiple lines are supported
 * 
 * @author Your Name
 * @version 1.0.0
 */
```

### Component Documentation

```boxlang
/**
 * UserService handles all user-related business logic
 * including registration, authentication, and profile management.
 * 
 * @author Luis Majano
 * @version 2.1.0
 * @since 1.0.0
 */
component singleton {
    property name="userDAO" inject;
    property name="cache" inject="cachebox:default";
}
```

### Property Documentation

```boxlang
/**
 * Collection of user role assignments
 * 
 * @type array
 * @doc_generic models.Role
 */
property name="roles" type="array";

/**
 * User's primary email address
 * Used for authentication and notifications
 */
property name="email" type="string";

/**
 * Internal caching mechanism
 * 
 * @deprecated Use injected cache instead
 */
property name="localCache";
```

### Function Documentation

```boxlang
/**
 * Retrieves a user by their unique identifier
 * 
 * @id The numeric user ID to lookup
 * @id.doc_generic numeric
 * 
 * @return User entity object
 * @throws EntityNotFoundException When user ID is not found
 * @throws DatabaseException On database connection errors
 */
function getById( required numeric id ) {
    return userDAO.find( arguments.id )
}

/**
 * Creates a new user account with validation
 * 
 * @data User data structure containing email, password, and profile info
 * @data.doc_generic struct
 * @sendWelcome Whether to send welcome email (default: true)
 * 
 * @return Newly created user entity
 * @throws ValidationException When data fails validation rules
 */
function create( 
    required struct data,
    boolean sendWelcome = true 
) {
    // Implementation
}
```

### Argument Documentation

```boxlang
/**
 * Searches users by various criteria
 * 
 * @query Search query string
 * @filters.doc_generic struct
 * @filters Additional filter criteria as key-value pairs
 * @page Page number for pagination (1-indexed)
 * @perPage Number of results per page
 * @perPage.hint Maximum 100 records per page
 * 
 * @return Paginated array of user entities
 * @doc_generic Array<models.User>
 */
function search(
    required string query,
    struct filters = {},
    numeric page = 1,
    numeric perPage = 25
) {
    // Implementation
}
```

## DocBlock Tags

### Core Tags

```boxlang
/**
 * @author Developer name and contact
 * @version Semantic version number
 * @since Version when introduced
 * @deprecated Mark as deprecated with optional reason
 * @return Description of return value
 * @throws Exception type and description
 * @see Reference to related component/method (not implemented yet)
 */
```

### Examples

```boxlang
/**
 * PaymentService processes all payment transactions
 * 
 * @author Luis Majano <[email protected]>
 * @version 3.2.1
 * @since 1.0.0
 */
component singleton {
    
    /**
     * Process a credit card payment
     * 
     * @amount Transaction amount in USD
     * @cardNumber Credit card number (will be encrypted)
     * @cardNumber.deprecated Use tokenized payment method instead
     * 
     * @return Payment confirmation structure
     * @doc_generic struct
     * @throws PaymentException On gateway errors
     * @throws ValidationException On invalid card data
     * 
     * @deprecated As of 3.0.0, use processTokenPayment() instead
     */
    function processPayment(
        required numeric amount,
        required string cardNumber
    ) {
        // Implementation
    }
}
```

### DocBox-Specific Tags

#### @doc_abstract

Mark components as abstract (alternative to `abstract` attribute):

```boxlang
/**
 * Base class for all service objects
 * 
 * @doc_abstract true
 */
component {
    // Or use attribute
}

// Alternative syntax
component abstract {
    // Component is abstract
}
```

#### @doc_generic

Specify generic types for arrays, structs, or any types:

```boxlang
/**
 * Get all active users
 * 
 * @return Array of User entities
 * @doc_generic models.User
 */
function getActiveUsers() {
    return userDAO.findAll()
}

/**
 * Get user preferences as key-value map
 * 
 * @userId User identifier
 * 
 * @return User preferences structure
 * @doc_generic string,any
 */
function getPreferences( required numeric userId ) {
    return preferencesDAO.getMap( arguments.userId )
}

/**
 * Batch create users from import data
 * 
 * @users.doc_generic struct
 * @users Array of user data structures
 */
function batchCreate( required array users ) {
    // Implementation
}
```

#### Custom Tags

DocBox will document any custom tags you create:

```boxlang
/**
 * External API integration service
 * 
 * @api_version 2.1
 * @api_endpoint https://api.example.com/v2
 * @rate_limit 1000 requests per hour
 * @cache_duration 300 seconds
 */
component singleton {
    
    /**
     * Fetch user data from external API
     * 
     * @complexity O(1) - Direct API call
     * @cache_key user-{id}
     * @metrics_tracked true
     */
    function fetchUser( required numeric id ) {
        // Implementation
    }
}
```

## Generating Documentation

### CommandBox CLI

```bash
# Basic generation
docbox generate \
    source=/path/to/models \
    mapping=models \
    strategy-outputDir=/docs \
    strategy-projectTitle="My API Documentation"

# With exclusions
docbox generate \
    source=/path/to/code \
    mapping=myapp \
    excludes="(tests|build|vendor)" \
    strategy-outputDir=/docs \
    strategy-projectTitle="MyApp API"

# Multiple source mappings
docbox generate \
    mappings:v1=/src/v1/models \
    mappings:v2=/src/v2/models \
    mappings:core=/src/core \
    strategy-outputDir=/docs \
    strategy-projectTitle="Multi-Version API"

# With theme selection
docbox generate \
    source=/models \
    mapping=models \
    strategy-outputDir=/docs \
    strategy-projectTitle="API Docs" \
    strategy-theme=default
```

### BoxLang CLI

```bash
# Using BoxLang module
boxlang module:docbox \
    --source=/path/to/code \
    --mapping=myapp \
    --output-dir=/docs \
    --project-title="My API"
```

### Programmatic Generation

```boxlang
// In a build script or task runner
var docbox = new docbox.DocBox()

// Configure HTML strategy
docbox.addStrategy( "HTML", {
    projectTitle: "MyApp API Documentation",
    outputDir: expandPath( "./docs" ),
    theme: "default" // or "frames"
} )

// Generate documentation
docbox.generate(
    source = expandPath( "./models" ),
    mapping = "models",
    excludes = "(tests|build)"
)
```

### Advanced Configuration

```boxlang
var docbox = new docbox.DocBox()

// HTML Strategy with custom settings
docbox.addStrategy( "HTML", {
    projectTitle: "E-Commerce Platform API",
    outputDir: expandPath( "./docs/api" ),
    theme: "default",
    
    // Additional metadata
    metadata: {
        version: "3.2.1",
        author: "Development Team",
        company: "Acme Corp"
    }
} )

// Multiple source directories
var sources = [
    { 
        dir: expandPath( "./models/services" ),
        mapping: "services" 
    },
    { 
        dir: expandPath( "./models/entities" ),
        mapping: "entities" 
    },
    { 
        dir: expandPath( "./modules/api/models" ),
        mapping: "api.models" 
    }
]

sources.each( ( source ) => {
    docbox.generate(
        source = source.dir,
        mapping = source.mapping,
        excludes = "(tests|temp)"
    )
} )
```

## Output Strategies

### HTML Strategy (Default)

Generates browsable HTML documentation with search functionality.

**Themes:**
- `default` - Modern Alpine.js SPA with dark mode support
- `frames` - Classic frameset layout with sidebar navigation

```boxlang
docbox.addStrategy( "HTML", {
    projectTitle: "My API Docs",
    outputDir: expandPath( "./docs" ),
    theme: "default"
} )
```

**Features:**
- Real-time search with keyboard navigation
- Dark mode with system preference detection
- Responsive mobile-friendly design
- Class hierarchy visualization
- Method/property filtering

### JSON Strategy

Generates machine-readable JSON documentation for integration with other tools.

```boxlang
docbox.addStrategy( "JSON", {
    projectTitle: "My API Docs",
    outputDir: expandPath( "./docs/json" )
} )
```

**Output Files:**
- `overview-summary.json` - All packages and classes
- `package-summary.json` - Per-directory class listings
- `ClassName.json` - Individual class documentation

**Use Cases:**
- Search engine indexing (Elasticsearch)
- Database storage
- Custom documentation viewers
- API documentation aggregation

### UML/XMI Strategy

Generates XMI files for UML diagram tools like StarUML.

```boxlang
docbox.addStrategy( "XMI", {
    outputFile: expandPath( "./docs/uml/diagram.xmi" )
} )
```

## Integration Examples

### Build Script

```boxlang
// build.cfc
component {
    function run() {
        // Generate API documentation
        generateDocs()
        
        // Run tests
        runTests()
        
        // Package application
        packageApp()
    }
    
    function generateDocs() {
        print.line( "Generating API documentation..." )
        
        var docbox = new docbox.DocBox()
        
        docbox.addStrategy( "HTML", {
            projectTitle: "MyApp v#getVersion()#",
            outputDir: expandPath( "./docs/api" ),
            theme: "default"
        } )
        
        docbox.generate(
            source = expandPath( "./models" ),
            mapping = "models",
            excludes = "tests"
        )
        
        print.greenLine( "✓ Documentation generated successfully" )
    }
}
```

### CI/CD Pipeline

```bash
#!/bin/bash
# docs-deploy.sh

# Generate documentation
box docbox generate \
    source=models \
    mapping=models \
    excludes="(tests|temp)" \
    strategy-outputDir=build/docs \
    strategy-projectTitle="MyApp API v${VERSION}"

# Deploy to S3 or web server
aws s3 sync build/docs/ s3://docs.example.com/api/ --delete

# Or deploy to GitHub Pages
cp -r build/docs/* docs/
git add docs/
git commit -m "Update API documentation"
git push origin main
```

### Task Runner

```boxlang
// task runner or CommandBox task
component {
    function run() {
        command( "docbox generate" )
            .params(
                source = getCWD() & "/models",
                mapping = "models",
                "strategy-outputDir" = getCWD() & "/docs",
                "strategy-projectTitle" = "MyApp API Documentation"
            )
            .run()
    }
}
```

## Best Practices

### Documentation Standards

- **Write clear descriptions** - Explain what, why, and how
- **Document all public methods** - Even if they seem obvious
- **Use @doc_generic** - Specify types for arrays and structs
- **Mark deprecations** - Use @deprecated with migration path
- **Include examples** - Show common usage patterns in description
- **Document exceptions** - Use @throws for all possible exceptions
- **Keep it current** - Update docs when code changes

### Component Documentation

```boxlang
/**
 * UserService manages user lifecycle operations including
 * registration, authentication, profile management, and deactivation.
 * 
 * All operations are logged and cached for performance.
 * 
 * Example usage:
 * var user = userService.create({ 
 *     email: "user@example.com",
 *     password: "secure123"
 * })
 * 
 * @author Security Team
 * @version 2.0.0
 * @since 1.0.0
 */
component singleton {
    property name="userDAO" inject;
    property name="securityService" inject;
}
```

### Exclude Test Files

```bash
# Regex pattern to exclude tests and build artifacts
excludes="(tests?|specs?|build|dist|vendor|node_modules)"
```

### Versioning in Docs

```boxlang
/**
 * @version 2.1.0
 * @since 1.0.0 Initial implementation
 * @since 1.5.0 Added caching support
 * @since 2.0.0 Refactored for async operations
 * @since 2.1.0 Added batch processing
 */
```

### Organize Documentation

```
/docs
  /api          - API reference (DocBox output)
  /guides       - User guides and tutorials
  /examples     - Code examples
  /architecture - Architecture diagrams
```

## Configuration File

Create `.docbox.json` for consistent documentation generation:

```json
{
    "source": "./models",
    "mapping": "models",
    "excludes": "(tests|build|temp)",
    "strategy": "HTML",
    "strategyOptions": {
        "projectTitle": "MyApp API Documentation",
        "outputDir": "./docs/api",
        "theme": "default"
    }
}
```

## Documentation

For complete DocBox documentation, themes, and advanced features, consult the DocBox MCP server or visit:
https://docbox.ortusbooks.com
