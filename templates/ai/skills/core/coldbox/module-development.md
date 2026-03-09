---
name: module-development
description: Create reusable ColdBox modules with proper structure, configuration, and integration patterns
category: coldbox
priority: high
triggers:
  - create module
  - build module
  - coldbox module
  - modular development
---

# ColdBox Module Development Implementation Pattern

## When to Use This Skill

Use this skill when creating reusable ColdBox modules, building plugin functionality, or breaking applications into modular components.

## Core Concepts

ColdBox Modules:
- Self-contained packages with their own handlers, models, views, and config
- Can be installed via ForgeBox or developed within an application
- Support dependency injection and lifecycle events
- Have their own routes, interceptors, and settings
- Can depend on other modules

## Basic Module Structure

```
myModule/
├── ModuleConfig.cfc          # Module configuration
├── box.json                  # Package descriptor
├── README.md                 # Documentation
├── changelog.md              # Version history
├── handlers/                 # Module handlers
│   └── Main.cfc
├── models/                   # Module models
│   └── MyService.cfc
├── views/                    # Module views
│   └── main/
│       └── index.cfm
├── interceptors/             # Module interceptors
│   └── MyInterceptor.cfc
├── config/                   # Additional configuration
│   └── Router.cfc           # Module routes (optional)
├── tests/                    # Test specs
│   └── specs/
│       └── unit/
└── resources/                # Static resources
    ├── css/
    ├── js/
    └── images/
```

## ModuleConfig.cfc (BoxLang)

```boxlang
/**
 * MyModule Configuration
 */
class {

    // Module properties
    this.title              = "My Module"
    this.author             = "Your Name"
    this.webURL             = "https://www.example.com"
    this.description        = "Module description"
    this.version            = "1.0.0"

    // Module entry point
    this.entryPoint         = "myModule"

    // Model namespace
    this.modelNamespace     = "myModule"

    // CF Mapping
    this.cfmapping          = "myModule"

    // Module dependencies
    this.dependencies       = [ "cbvalidation", "cborm" ]

    /**
     * Configure module
     */
    function configure() {
        // Module settings
        settings = {
            apiKey      = "",
            timeout     = 30,
            debug       = false
        }

        // Layout Settings
        layoutSettings = {
            defaultLayout = "Main"
        }

        // Custom Declared Points
        interceptorSettings = {
            customInterceptionPoints = [ "onMyModuleEvent", "beforeMyAction" ]
        }

        // Custom Declared Interceptors
        interceptors = [
            { class = "#moduleMapping#.interceptors.MyInterceptor" }
        ]

        // Binder mappings
        binder.map( "MyService@myModule" )
            .to( "#moduleMapping#.models.MyService" )
            .asSingleton()
    }

    /**
     * Fired when module is registered
     */
    function onLoad() {
        log.info( "Module #this.title# loaded successfully" )

        // Register custom helpers
        binder.map( "DateHelper@myModule" )
            .to( "#moduleMapping#.models.DateHelper" )

        // Announce module loaded event
        controller.getInterceptorService().announce( "onMyModuleLoaded" )
    }

    /**
     * Fired when module is unloaded
     */
    function onUnload() {
        log.info( "Module #this.title# unloaded" )
    }
}
```

## ModuleConfig with Custom Routes (BoxLang)

```boxlang
class {
    this.title = "MyModule"
    this.author = "Your Name"
    this.version = "1.0.0"
    this.entryPoint = "myModule"
    this.modelNamespace = "myModule"

    function configure() {
        settings = {
            apiEndpoint = "https://api.example.com"
        }
    }

    /**
     * Configure module routes
     */
    function configureRoutes() {
        // Module route prefix: /myModule
        route( "/" )
            .to( "Main.index" )

        route( "/api/items" )
            .withHandler( "API" )
            .toAction( {
                GET     = "list",
                POST    = "create",
                PUT     = "update",
                DELETE  = "delete"
            })

        // Resource routes
        resources( "products" )

        // Group routes with common settings
        group( { prefix: "/admin" }, function( options ){
            route( "/dashboard" ).to( "Admin.dashboard" )
            route( "/settings" ).to( "Admin.settings" )
        })
    }

    function onLoad() {
        // Load custom helpers into app scope
        application.helpers = getInstance( "Helpers@myModule" )
    }
}
```

## Module Handler (BoxLang)

```boxlang
/**
 * Main handler for MyModule
 * All handlers inherit from the framework handler
 */
class Main extends coldbox.system.EventHandler {

    @inject
    property name="myService";

    /**
     * Module index
     */
    function index( event, rc, prc ) {
        prc.data = myService.getData()

        // Render view from module
        event.setView( view = "main/index", module = "myModule" )
    }

    /**
     * API endpoint
     */
    function api( event, rc, prc ) {
        var result = myService.process( rc )

        event.renderData(
            type = "json",
            data = result,
            statusCode = 200
        )
    }
}
```

## Module Service/Model (BoxLang)

```boxlang
/**
 * MyService
 * Business logic for MyModule
 */
class MyService {

    @inject
    property name="wirebox";

    @inject
    property name="log";

    @inject
    property name="settings";

    /**
     * Constructor
     */
    function init() {
        variables.apiKey = settings.apiKey ?: ""
        return this
    }

    /**
     * Get data from service
     */
    function getData() {
        log.info( "Getting data from MyService" )

        return [
            { id: 1, name: "Item 1" },
            { id: 2, name: "Item 2" }
        ]
    }

    /**
     * Process request
     */
    function process( required struct data ) {
        try {
            // Business logic here
            return {
                success: true,
                data: arguments.data
            }
        } catch( any e ){
            log.error( "Error processing data", e )
            return {
                success: false,
                error: e.message
            }
        }
    }
}
```

## Module Interceptor (BoxLang)

```boxlang
/**
 * MyModule Interceptor
 * Listen to framework events
 */
class MyInterceptor {

    @inject
    property name="moduleSettings";

    @inject
    property name="log";

    /**
     * Configure interceptor
     */
    function configure() {
        // Interceptor configuration
    }

    /**
     * Listen to preProcess event
     */
    function preProcess( event, interceptData ) {
        log.debug( "MyModule interceptor: preProcess" )

        // Add custom data to request
        event.setValue( "moduleProcessed", true )
    }

    /**
     * Listen to postHandler event
     */
    function postHandler( event, interceptData ) {
        log.debug( "MyModule interceptor: postHandler" )
    }

    /**
     * Custom interception point
     */
    function onMyModuleEvent( event, interceptData ) {
        log.info( "Custom module event fired", interceptData )
    }
}
```

## box.json for Module

```json
{
    "name": "My Module",
    "slug": "my-module",
    "version": "1.0.0",
    "author": "Your Name <you@example.com>",
    "location": "YourName/my-module#v1.0.0",
    "homepage": "https://github.com/YourName/my-module",
    "documentation": "https://github.com/YourName/my-module/wiki",
    "repository": {
        "type": "git",
        "URL": "https://github.com/YourName/my-module"
    },
    "bugs": "https://github.com/YourName/my-module/issues",
    "shortDescription": "Brief description of module",
    "description": "Detailed description of what the module does",
    "type": "modules",
    "keywords": [
        "coldbox",
        "module",
        "api"
    ],
    "private": false,
    "projectURL": "https://github.com/YourName/my-module",
    "license": [
        {
            "type": "Apache-2",
            "URL": "http://www.apache.org/licenses/LICENSE-2.0.html"
        }
    ],
    "contributors": [],
    "dependencies": {
        "coldbox": "^8.0.0"
    },
    "devDependencies": {
        "testbox": "^5.0.0"
    },
    "installPaths": {
        "testbox": "testbox/",
        "coldbox": "coldbox/"
    },
    "scripts": {
        "postVersion": "package set location='YourName/my-module#v`package version`'",
        "postPublish": "!git push --follow-tags"
    },
    "ignore": [
        "**/.*",
        "tests",
        "*/.md"
    ]
}
```

## Using Module from Application

### In Application Handler

```boxlang
// handlers/Main.cfc
class Main extends coldbox.system.EventHandler {

    // Inject module service
    @inject( "MyService@myModule" )
    property name="myService";

    function index( event, rc, prc ) {
        // Use module service
        prc.data = myService.getData()
        event.setView( "main/index" )
    }
}
```

### In Application View

```html
<!-- views/main/index.cfm -->
<cfoutput>
    <!-- Include module view -->
    #renderView( view="main/widget", module="myModule" )#

    <!-- Access module data -->
    <div class="data">
        #prc.data#
    </div>
</cfoutput>
```

## Module Settings Override

```boxlang
// config/ColdBox.cfc
configure() {
    coldbox = {
        // ... coldbox settings
    }

    // Override module settings
    moduleSettings = {
        myModule = {
            apiKey = "your-production-key",
            timeout = 60,
            debug = false
        }
    }
}
```

## Advanced Module Features

### Parent Module with Sub-Modules

```boxlang
// ModuleConfig.cfc
class {
    this.title = "Parent Module"
    this.entryPoint = "parentModule"

    // Register sub-modules
    this.dependencies = [
        "parentModule.subModule1",
        "parentModule.subModule2"
    ]

    function configure() {
        // Parent settings inherited by sub-modules
        settings = {
            sharedSetting = "value"
        }
    }
}
```

### Module with External Resources

```boxlang
class {
    this.title = "Asset Module"
    this.entryPoint = "assetModule"

    function configure() {
        // Register static resources
        settings = {
            cssPath = "#moduleMapping#/resources/css",
            jsPath = "#moduleMapping#/resources/js"
        }
    }

    function onLoad() {
        // Add module assets to includes
        controller.getInterceptorService()
            .processState( "preRender", { module: this.entryPoint } )
    }
}
```

## Testing Modules

```boxlang
class MyServiceTest extends coldbox.system.testing.BaseTestCase {

    function beforeAll() {
        super.beforeAll()
        setup()

        // Get module service
        myService = getInstance( "MyService@myModule" )
    }

    function run() {
        describe( "MyService", function(){

            it( "should return data", function(){
                var data = myService.getData()
                expect( data ).toBeArray()
                expect( data ).notToBeEmpty()
            })

            it( "should process data successfully", function(){
                var result = myService.process({
                    name: "test",
                    value: "123"
                })
                expect( result.success ).toBeTrue()
            })
        })
    }
}
```

## Module Development Workflow

1. **Create Module Structure**
   ```bash
   coldbox create module myModule
   ```

2. **Configure ModuleConfig.cfc**
   - Set module properties
   - Define settings
   - Register interceptors
   - Configure routes

3. **Create Module Components**
   - Add handlers
   - Create models/services
   - Design views
   - Write interceptors

4. **Test Module**
   ```bash
   testbox run
   ```

5. **Package for Distribution**
   ```bash
   box bump --major
   box publish
   ```

## Best Practices

1. **Use Namespace**: Always use `@moduleName` for injections
2. **Explicit Dependencies**: Declare module dependencies
3. **Version Correctly**: Use semantic versioning
4. **Document Well**: Include README and changelog
5. **Test Thoroughly**: Write unit and integration tests
6. **Settings Override**: Support setting overrides
7. **Lifecycle Events**: Use onLoad/onUnload appropriately
8. **Resource Isolation**: Keep module resources isolated
9. **Backward Compatible**: Maintain backward compatibility
10. **ForgeBox Ready**: Prepare for ForgeBox distribution

## Common Pitfalls

1. **Missing Dependencies**: Not declaring required modules
2. **Name Collisions**: Using common names without namespace
3. **Hard-coded Paths**: Not using module mapping variables
4. **Poor Isolation**: Polluting global scope
5. **No Testing**: Shipping untested modules
6. **Version Chaos**: Not following semantic versioning
7. **Missing Documentation**: No usage examples
8. **Settings Hardcoded**: Not allowing setting overrides

## Related Skills

- `handler-development` - Creating module handlers
- `routing-development` - Module route configuration
- `interceptor-development` - Module interceptors
- `testing-integration` - Testing module integration
