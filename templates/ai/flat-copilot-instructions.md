# ColdBox Flat Template - AI Coding Instructions

This is a ColdBox HMVC framework template using the traditional "flat" structure where all application code lives in the webroot. Use CFML with ColdBox 7+ conventions. Compatible with Adobe ColdFusion 2018+, Lucee 5.x+, and BoxLang 1.0+.

## 🏗️ Architecture Overview

**Key Design Decision**: This template uses the traditional flat structure with all files in the webroot (unlike the Modern template). This makes it simpler for learning, prototyping, and traditional hosting environments.

### Directory Structure

```
/                      - Application root (webroot)
├── Application.cfc    - Bootstrap that directly loads ColdBox
├── index.cfm          - Front controller
├── config/            - Framework and app configuration
├── handlers/          - Event handlers (controllers)
├── models/            - Service objects, business logic
├── views/             - HTML templates
├── layouts/           - Page layouts wrapping views
├── includes/          - Public assets (CSS, JS, images)
├── modules_app/       - Application modules (HMVC)
├── tests/             - Test suites
└── lib/               - Framework dependencies (coldbox/, testbox/)
    └── coldbox/       - ColdBox framework installed here
```

### Application Bootstrap Flow

1. Request hits `index.cfm` (front controller)
2. `Application.cfc` sets up mappings and bootstraps ColdBox:
   - `COLDBOX_APP_ROOT_PATH = getDirectoryFromPath(getCurrentTemplatePath())`
   - `COLDBOX_APP_MAPPING = ""` (empty because app is at root)
   - `this.mappings["/app"] = COLDBOX_APP_ROOT_PATH`
   - `this.mappings["/coldbox"] = COLDBOX_APP_ROOT_PATH & "coldbox"`
3. `onApplicationStart()` creates Bootstrap and calls `loadColdbox()`
4. ColdBox loads `config/ColdBox.cfc` for framework settings
5. ColdBox loads `config/Router.cfc` for URL routing
6. Request is processed by handler action

**Important**: Unlike Modern template, there's no `/app` vs `/public` separation - everything is web-accessible.

## 📝 Handler Patterns

### Standard Handler Structure

```cfml
component extends="coldbox.system.EventHandler" {

    // Dependency injection
    property name="userService" inject="UserService";

    // All actions receive three arguments:
    // - event: RequestContext object
    // - rc: Request collection (form/URL variables)
    // - prc: Private request collection (handler-to-view data)

    function index(event, rc, prc){
        prc.welcomeMessage = "Data for the view";
        event.setView("main/index");
    }

    // RESTful data - return any data type
    function data(event, rc, prc){
        return [
            { "id": createUUID(), "name": "Luis" }
        ];
    }

    // Relocations (redirects)
    function doSomething(event, rc, prc){
        relocate("main.index"); // Internal redirect to event
    }

    // Optional lifecycle handlers (must be enabled in config/ColdBox.cfc)
    function onAppInit(event, rc, prc){
        // Runs once on application startup
    }

    function onRequestStart(event, rc, prc){
        // Runs before each request
    }

    function onException(event, rc, prc){
        event.setHTTPHeader(statusCode = 500);
        var exception = prc.exception; // Populated by ColdBox
    }
}
```

### Request Collection Conventions

- **rc (Request Collection)**: Automatically populated with FORM/URL variables. Never trust this data - always validate.
- **prc (Private Request Collection)**: Pass data from handlers to views/layouts. Not accessible from URL.

Example:
```cfml
function edit(event, rc, prc){
    // URL: /index.cfm?event=users.edit&id=123
    var userId = event.getValue("id", 0); // From rc, defaults to 0

    prc.user = userService.get(userId);
    event.setView("users/edit");
}
```

## 🧪 Testing Patterns

### Integration Test Structure

**CRITICAL**: Tests extend `BaseTestCase` with `appMapping="/app"` pointing to the root mapping:

```cfml
component extends="coldbox.system.testing.BaseTestCase" appMapping="/app" {

    function run(){
        describe("Main Handler", function(){
            beforeEach(function(currentSpec){
                // MUST call setup() to reset request context per test
                setup();
            });

            it("can render the homepage", function(){
                var event = this.get("main.index");
                expect(event.getValue(name="welcomeMessage", private=true))
                    .toBe("Welcome to ColdBox!");
            });

            it("can return RESTful data", function(){
                var event = this.post("main.data");
                expect(event.getRenderedContent()).toBeJSON();
            });
        });
    }
}
```

### Testing Helpers

- **`this.get(event)`** - Execute GET request
- **`this.post(event, params)`** - Execute POST request
- **`execute(event, private, prePostExempt)`** - Execute any event
- **`getRequestContext()`** - Get current request context

### Common Testing Mistake

❌ **Forgetting to call `setup()`** in `beforeEach()` causes tests to share request context
✅ **Always call `setup()`** to ensure test isolation

## 🛠️ Build Commands (box.json scripts)

```bash
# Install dependencies (first time setup)
box install

# Start server
box server start

# Code formatting
box run-script format              # Format all CFML code
box run-script format:check        # Check formatting without changes
box run-script format:watch        # Watch and auto-format on save

# Testing
box testbox run                    # Run all tests
box testbox run bundles=tests.specs.integration.MainSpec  # Run specific bundle

# Docker
box run-script docker:build        # Build Docker image
box run-script docker:run          # Run container
box run-script docker:stack up     # Start docker-compose stack
box run-script docker:stack down   # Stop docker-compose stack

# ColdBox CLI scaffolding
coldbox create handler name=Users actions=index,create,save,delete
coldbox create model name=UserService methods=getAll,save,delete
coldbox create integration-test handler=Users
```

## 🎯 Configuration Patterns

### Environment Variables (.env)

Use `getSystemSetting()` in config files to read from `.env`:

```cfml
// config/ColdBox.cfc
variables.coldbox = {
    appName: getSystemSetting("APPNAME", "Your app name here"),
    // ...
};

// In any handler/model
var dbHost = getSystemSetting("DB_HOST", "localhost");
```

### Implicit Event Handlers

To enable lifecycle methods like `onAppInit`, configure in `config/ColdBox.cfc`:

```cfml
variables.coldbox = {
    applicationStartHandler: "Main.onAppInit",
    requestStartHandler: "Main.onRequestStart",
    exceptionHandler: "main.onException"
};
```

### Application Helper

The `includes/helpers/ApplicationHelper.cfm` is automatically available in all handlers, views, and layouts. Use it for common utility functions:

```cfml
<!--- includes/helpers/ApplicationHelper.cfm --->
<cfscript>
function formatCurrency(required numeric amount){
    return dollarFormat(arguments.amount);
}
</cfscript>
```

## 🔄 Routing (config/Router.cfc)

```cfml
component {
    function configure(){
        // Closure routes
        route("/healthcheck", function(event, rc, prc){
            return "Ok!";
        });

        // RESTful API routes
        route("/api/echo", function(event, rc, prc){
            return {error: false, data: "Welcome!"};
        });

        // Pattern-based routes
        route("/users/:id").to("users.show");

        // RESTful resources (generates 7 routes)
        resources("photos");

        // Route groups
        group({prefix: "/api/v1"}, function(){
            route("/users").to("api.users.index");
        });

        // Conventions-based catch-all (should be last)
        route(":handler/:action?").end();
    }
}
```

## 💉 Dependency Injection (WireBox)

### Property Injection

```cfml
component {
    // Inject by model name (auto-resolved from models/ folder)
    property name="userService" inject="UserService";

    // Inject by ID
    property name="cache" inject="cachebox:default";

    // Inject logger for this component
    property name="log" inject="logbox:logger:{this}";

    // Provider injection (lazy loading)
    property name="userServiceProvider" inject="provider:UserService";
}
```

### Models Auto-Discovery

When `autoMapModels=true` in `config/ColdBox.cfc` (default), all CFCs in `models/` are automatically registered:

```
models/
├── UserService.cfc          → inject="UserService"
├── security/
│   └── AuthService.cfc      → inject="security.AuthService"
```

## ☕ Java Dependencies (Maven Integration)

This template includes `pom.xml` for Java library management:

```bash
# Add dependencies to pom.xml, then:
mvn install    # Download JARs to lib/ folder
mvn clean      # Remove all JARs
```

The `Application.cfc` automatically loads all JARs from `lib/`:

```cfml
this.javaSettings = {
    loadPaths: [expandPath("./lib")],
    loadColdFusionClassPath: true,
    reloadOnChange: false
};
```

## 🚨 Common Pitfalls

1. **Test Isolation**: Forgetting `setup()` in `beforeEach()` causes tests to fail mysteriously
2. **appMapping**: Tests require `appMapping="/app"` to match the Application.cfc mapping
3. **Environment Variables**: `.env` file is created by postInstall script from `.env.example`
4. **Framework Reinit**: Use `?fwreinit=true` or configure `reinitPassword` for production
5. **Module Routes**: Module routes are processed before app routes - be aware of conflicts
6. **Library Installation**: `box.json` installs to `coldbox/` and `testbox/` (not `lib/` subdirs)

## 📦 Key Files Reference

- **`Application.cfc`** - Bootstrap, mappings, lifecycle methods
- **`config/ColdBox.cfc`** - Framework configuration, environment detection
- **`config/Router.cfc`** - URL routing definitions
- **`box.json`** - Dependencies, scripts, CommandBox settings
- **`server.json`** - Server configuration (engine, JVM, rewrites)
- **`tests/Application.cfc`** - Test bootstrap (mirrors main Application.cfc)

## 🔍 Debugging Tips

```cfml
// Enable debug mode in config/ColdBox.cfc
variables.settings = {
    debugMode: true
};

// Use writeDump() in handlers
writeDump(var=rc, abort=true);

// Use log injection
property name="log" inject="logbox:logger:{this}";
log.info("Debug message", rc);

// TestBox debug helper
debug(event.getHandlerResults());
```

## 📚 Documentation

- **ColdBox Docs**: https://coldbox.ortusbooks.com
- **WireBox DI**: https://wirebox.ortusbooks.com
- **TestBox Testing**: https://testbox.ortusbooks.com
- **CommandBox CLI**: https://commandbox.ortusbooks.com
