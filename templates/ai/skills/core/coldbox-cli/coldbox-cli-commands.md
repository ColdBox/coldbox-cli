---
name: ColdBox CLI Commands & Code Generation
description: Complete guide to ColdBox CLI commands for scaffolding, code generation, AI integration, and development workflows. Includes BoxLang and CFML support.
category: coldbox-cli
priority: high
triggers:
  - cli
  - command
  - generate
  - create
  - scaffold
  - coldbox cli
  - ai commands
  - coldbox create
  - coldbox ai
---

# ColdBox CLI Commands & Code Generation

## Overview

The ColdBox CLI is a CommandBox module providing comprehensive scaffolding and development tools for ColdBox framework applications. It supports both **BoxLang (default)** and **CFML**, offering commands for creating applications, generating code, managing modules, running tests, and integrating AI coding assistance.

**Key Features:**
- Application scaffolding with multiple templates
- MVC component generation (handlers, models, views)
- REST API and CRUD scaffolding
- Module development tools
- Database migrations and ORM support
- Testing infrastructure
- AI integration for enhanced development
- Docker and Vite support

## Installation

```bash
box install coldbox-cli
```

**Version Matching**: CLI versions match ColdBox major versions:
- ColdBox 8 → CLI `@8`
- ColdBox 7 → CLI `@7.8.0`
- ColdBox 6 → CLI `@6`

## Application Creation

### Basic Application

```bash
## Default BoxLang application
coldbox create app myApp

## CFML application (explicit)
coldbox create app myApp --cfml

## With specific template
coldbox create app myApp skeleton=modern
coldbox create app myApp skeleton=rest
coldbox create app myApp skeleton=flat
```

### Application Templates

**BoxLang Templates (Recommended):**
- `boxlang` (default) - Modern ColdBox app with BoxLang
- `modern` - Contemporary architecture supporting BoxLang and CFML
- `rest` - REST API template optimized for BoxLang

**Legacy CFML Templates:**
- `flat` - Classic flat structure for traditional CFML
- `rest-hmvc` - RESTful app with HMVC architecture
- `supersimple` - Bare-bones minimal setup
- `vite` - Legacy Vite integration

### Feature Flags

Modern templates (`boxlang`, `modern`) support additional features:

```bash
## Database migrations
coldbox create app myApp --migrations

## Docker containerization
coldbox create app myApp --docker

## Vite frontend assets
coldbox create app myApp --vite

## REST API configuration
coldbox create app myApp --rest

## Combine multiple features
coldbox create app myApp --migrations --docker --vite --rest
```

### Interactive App Wizard

Guided step-by-step application creation:

```bash
coldbox create app-wizard
```

**Wizard Steps:**
1. Project location (current directory or new folder)
2. Language selection (BoxLang or CFML)
3. Project type (API/REST or full web)
4. Frontend setup (Vite integration)
5. Environment (Docker containerization)
6. Database (migrations support)

**Example Flow:**
```bash
Are you currently inside the "myapp" folder? [y/n]: n
Is this a BoxLang project? [y/n]: y
Are you creating an API? [y/n]: n
Would you like to configure Vite? [y/n]: y
Would you like to setup Docker? [y/n]: y
Are you going to require Database Migrations? [y/n]: y
```

## Handlers (Controllers)

### Basic Handlers

```bash
## Simple handler
coldbox create handler users

## Handler with actions
coldbox create handler users index,show,edit,delete

## REST handler
coldbox create handler api/users --rest

## Resourceful handler (full CRUD)
coldbox create handler photos --resource

## With views and tests
coldbox create handler users --views --integrationTests
```

### Generated Handler (BoxLang)

```boxlang
class Users extends coldbox.system.EventHandler {
    property name="userService" inject

    function index( event, rc, prc ) {
        prc.users = userService.getAll()
        event.setView( "users/index" )
    }

    function show( event, rc, prc ) {
        prc.user = userService.getById( rc.id ?: 0 )
        event.setView( "users/show" )
    }

    function create( event, rc, prc ) {
        var user = userService.create( rc )
        flash.put( "notice", "User created" )
        relocate( "users.show", { id: user.id } )
    }
}
```

### REST Handler Pattern

```boxlang
class API extends coldbox.system.EventHandler {
    property name="userService" inject

    function index( event, rc, prc ) {
        event.renderData(
            data = userService.getAll(),
            formats = "json,xml"
        )
    }

    function show( event, rc, prc ) {
        event.renderData(
            data = userService.getById( rc.id ?: 0 )
        )
    }

    function create( event, rc, prc ) {
        event.renderData(
            data = userService.create( rc ),
            statusCode = 201
        )
    }

    function update( event, rc, prc ) {
        event.renderData(
            data = userService.update( rc.id, rc )
        )
    }

    function delete( event, rc, prc ) {
        userService.delete( rc.id )
        event.renderData(
            data = { message: "Deleted" },
            statusCode = 204
        )
    }
}
```

## Models & Services

### Model Creation

```bash
## Basic model
coldbox create model User

## Model with properties and accessors
coldbox create model User properties=fname,lname,email --accessors

## Model with migration
coldbox create model User --migration

## Model with service
coldbox create model User --service

## Complete model (service, handler, migration, seeder)
coldbox create model User --all

## Standalone service
coldbox create service UserService
```

### Generated Model (BoxLang)

```boxlang
class User {
    property name="wirebox" inject="wirebox"
    property name="log" inject="logbox:logger:{this}"

    function init() {
        return this
    }

    function getAll() {
        return []
    }

    function getById( required id ) {
        return {}
    }

    function create( required struct data ) {
        return data
    }

    function update( required id, required struct data ) {
        return data
    }

    function delete( required id ) {
        return true
    }
}
```

### Service Pattern

```boxlang
class UserService {
    property name="userDAO" inject="User"
    property name="log" inject="logbox:logger:{this}"

    function getAll() {
        return userDAO.getAll()
    }

    function getById( required id ) {
        return userDAO.getById( arguments.id )
    }

    function create( required struct data ) {
        // Validation and business logic
        return userDAO.create( arguments.data )
    }

    function update( required id, required struct data ) {
        // Validation and business logic
        return userDAO.update( arguments.id, arguments.data )
    }

    function delete( required id ) {
        return userDAO.delete( arguments.id )
    }
}
```

## Views & Layouts

### View Creation

```bash
## Create view
coldbox create view users/index

## View with helper
coldbox create view users/show --helper

## View with content
coldbox create view welcome content="<h1>Welcome!</h1>"

## Create layout
coldbox create layout main

## Layout with content
coldbox create layout admin content="<cfoutput>##view()##</cfoutput>"
```

### Generated View (BoxLang)

```boxlang
<cfoutput>
<div class="container">
    <h1>Users Index</h1>
    <div class="content">
        ## Your view content here
    </div>
</div>
</cfoutput>
```

### Layout Pattern

```boxlang
<cfoutput>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>##prc.title ?: "My Application"##</title>
    <link rel="stylesheet" href="/includes/css/app.css">
</head>
<body>
    ##view()##
    <script src="/includes/js/app.js"></script>
</body>
</html>
</cfoutput>
```

## Resources & CRUD

### Resource Scaffolding

```bash
## Single resource (handler, model, views, routes)
coldbox create resource photos

## Multiple resources
coldbox create resource photos,users,categories

## Custom handler name
coldbox create resource photos PhotoGallery

## With tests and migration
coldbox create resource users --tests --migration
```

### What Gets Generated

A resource command creates:
- Handler with CRUD actions (index, show, new, create, edit, update, delete)
- Model with basic CRUD methods
- Views for all actions (index, show, new, edit)
- Test specs for handler and model
- Optional migration file
- Route recommendations

### Resource Route Pattern

```boxlang
// config/Router.bx
resources( "photos" ) // Generates RESTful routes
resources( "users", { except: "delete" } ) // Exclude specific actions
resources( "posts", { only: [ "index", "show" ] } ) // Include specific actions
```

## Modules

### Module Creation

```bash
## Create module
coldbox create module myModule

## Module with features
coldbox create module myModule --models --handlers --views
```

### Generated Module Structure

```
myModule/
├── ModuleConfig.cfc
├── box.json
├── handlers/
├── models/
├── views/
├── interceptors/
├── tests/
└── README.md
```

### ModuleConfig Pattern

```boxlang
class {
    this.name = "myModule"
    this.author = "Your Name"
    this.description = "Module description"
    this.version = "1.0.0"

    function configure() {
        settings = {}

        interceptors = []

        interceptorSettings = {
            customInterceptionPoints = []
        }
    }

    function onLoad() {
        // Module loaded
    }

    function onUnload() {
        // Module unloaded
    }
}
```

## ORM & Database

### ORM Entity

```bash
## ORM Entity
coldbox create orm-entity User table=users

## ORM Service
coldbox create orm-service UserService entity=User

## Virtual Entity Service
coldbox create orm-virtual-service UserService

## ORM Event Handler
coldbox create orm-event-handler

## CRUD operations
coldbox create orm-crud User
```

### ORM Entity Pattern

```boxlang
class persistent="true" table="users" {
    property name="id" fieldtype="id" generator="native"
    property name="firstName" column="first_name"
    property name="lastName" column="last_name"
    property name="email" unique="true"
    property name="createdDate" ormtype="timestamp"
    property name="modifiedDate" ormtype="timestamp"

    function init() {
        variables.createdDate = now()
        variables.modifiedDate = now()
        return this
    }
}
```

### Virtual Entity Service Pattern

```boxlang
class extends="cborm.models.VirtualEntityService" {
    this.entityName = "User"

    function init() {
        super.init( arguments.entityName ?: this.entityName )
        return this
    }

    // Custom methods beyond base CRUD
    function findByEmail( required string email ) {
        return newCriteria()
            .eq( "email", arguments.email )
            .get()
    }

    function getActiveUsers() {
        return newCriteria()
            .eq( "active", true )
            .list()
    }
}
```

## Testing

### Test Creation

```bash
## Unit tests
coldbox create unit models.UserTest

## BDD specs
coldbox create bdd UserServiceTest

## Integration tests
coldbox create integration-test handlers.UsersTest

## Model tests
coldbox create model-test User

## Interceptor tests
coldbox create interceptor-test Security --actions=preProcess,postProcess
```

### BDD Test Pattern (BoxLang)

```boxlang
class extends="testbox.system.BaseSpec" {

    function beforeAll() {
        // Setup before all tests
    }

    function afterAll() {
        // Cleanup after all tests
    }

    function run() {
        describe( "User Service", function() {

            it( "can create a user", function() {
                var user = userService.create( {
                    firstName: "John",
                    lastName: "Doe",
                    email: "john@example.com"
                } )

                expect( user ).toHaveKey( "id" )
                expect( user.firstName ).toBe( "John" )
            } )

            it( "can retrieve a user by ID", function() {
                var user = userService.getById( 1 )
                expect( user ).toBeStruct()
            } )

            it( "validates required fields", function() {
                expect( function() {
                    userService.create( {} )
                } ).toThrow()
            } )
        } )
    }
}
```

### Integration Test Pattern

```boxlang
class extends="coldbox.system.testing.BaseTestCase" {

    function beforeAll() {
        super.beforeAll()
    }

    function run() {
        describe( "Users Handler", function() {

            beforeEach( function() {
                setup()
            } )

            it( "can display index page", function() {
                var event = execute( event="users.index", renderResults=true )
                expect( event.getValue( "users", [] ) ).toBeArray()
            } )

            it( "can show user detail", function() {
                var event = execute( event="users.show", eventArguments={ id: 1 } )
                expect( event.getValue( "user", {} ) ).toBeStruct()
            } )

            it( "can create a user", function() {
                var event = execute(
                    event = "users.create",
                    renderResults = false,
                    eventArguments = {
                        firstName: "John",
                        lastName: "Doe",
                        email: "john@example.com"
                    }
                )
                expect( event.getValue( "relocate_URI" ) ).toInclude( "users.show" )
            } )
        } )
    }
}
```

## Interceptors

### Interceptor Creation

```bash
## Basic interceptor
coldbox create interceptor Security

## Interceptor with points
coldbox create interceptor Logger points=preProcess,postProcess

## With tests
coldbox create interceptor Security --tests
```

### Interceptor Pattern

```boxlang
class {
    property name="log" inject="logbox:logger:{this}"

    function configure() {}

    function preProcess( event, interceptData ) {
        var rc = event.getCollection()
        log.debug( "Request started: ##event.getCurrentEvent()##" )
    }

    function postProcess( event, interceptData ) {
        log.debug( "Request completed: ##event.getCurrentEvent()##" )
    }

    function onException( event, interceptData ) {
        log.error( "Exception occurred", interceptData.exception )
    }

    function preRender( event, interceptData ) {
        // Add data to views
        event.setPrivateValue( "currentYear", year( now() ) )
    }
}
```

## Development Workflow

### Framework Operations

```bash
## Reinitialize ColdBox
coldbox reinit

## Auto-reinit on file changes (watch mode)
coldbox watch-reinit

## Open documentation
coldbox docs
coldbox docs search="event handlers"

## Open API documentation
coldbox apidocs
```

### Watch Mode Pattern

The `watch-reinit` command monitors your codebase and automatically reinitializes the framework when files change:

```bash
coldbox watch-reinit

## With specific path
coldbox watch-reinit --directory=/path/to/watch
```

**Watched Files:**
- Handlers
- Models
- Interceptors
- Module configs
- Router
- Application config

## Language Detection

The CLI automatically detects BoxLang or CFML projects using three methods:

### Detection Methods (Priority Order)

1. **Server Engine Detection**: Running on BoxLang server
2. **TestBox Runner Setting**: `testbox.runner` set to `"boxlang"` in `box.json`
3. **Language Property**: `language` set to `"boxlang"` in `box.json`

### Configuration

**Method 1: Language Property (Recommended)**

```json
{
    "name": "My BoxLang App",
    "language": "boxlang",
    "testbox": {
        "runner": "/tests/runner.bxm"
    }
}
```

**Method 2: TestBox Runner Setting**

```json
{
    "name": "My App",
    "testbox": {
        "runner": "boxlang"
    }
}
```

### Manual Override

```bash
## Default (BoxLang for new apps)
coldbox create handler users

## Explicit BoxLang
coldbox create handler users --boxlang

## Force CFML for legacy projects
coldbox create handler users --cfml
coldbox create app myApp --cfml
```

### Generated Code Differences

**BoxLang Mode:**
- Uses `.bx` file extensions
- Generates `class` syntax
- BoxLang-specific template variants
- BoxLang test files (`.bxm` extensions)

**CFML Mode:**
- Uses `.cfc` file extensions
- Generates `component` syntax
- CFML template variants
- CFML test files (`.cfc` extensions)

## AI Coding Assistance

The CLI provides AI integration to enhance development workflows with intelligent code generation and project understanding.

### AI Commands

```bash
## Install AI integration
coldbox ai install

## Initialize/configure AI
coldbox ai init

## Display AI configuration info
coldbox ai info

## Refresh AI configuration
coldbox ai refresh

## Uninstall AI integration
coldbox ai uninstall
```

### Agent Management

```bash
## List available agents
coldbox ai agents list

## Set active agent
coldbox ai agents active copilot

## Add custom agent
coldbox ai agents add myagent --path=/path/to/config.md

## Remove agent
coldbox ai agents remove myagent

## Open agent config
coldbox ai agents open copilot
```

### Guidelines Management

```bash
## List guidelines
coldbox ai guidelines list

## Add guideline
coldbox ai guidelines add myconventions

## Remove guideline
coldbox ai guidelines remove myconventions

## Create custom guideline
coldbox ai guidelines create team-standards --open
```

### Skills Management

```bash
## List skills
coldbox ai skills list

## Add skill
coldbox ai skills add deployment

## Remove skill
coldbox ai skills remove deployment

## Create custom skill
coldbox ai skills create custom-task --open
```

### AI Integration Features

**Automatic Detection:**
- Project language (BoxLang/CFML)
- Template type (flat/modern)
- Enabled features (Vite, Docker, ORM, Migrations)
- Module dependencies

**Generated Instructions:**
- Framework conventions and patterns
- Project structure documentation
- Module-specific guidelines
- Custom team conventions
- Development workflow

**Agent Configuration:**
- Project-aware context
- Language-specific patterns
- Template-specific guidance
- Feature documentation
- Best practices

## Docker Integration

### Docker Creation

```bash
## Create app with Docker
coldbox create app myApp --docker

## Combine with other features
coldbox create app myApp --docker --vite --migrations
```

### Generated Docker Files

**Dockerfile:**
- Multi-stage build optimization
- ColdBox application setup
- Production-ready configuration
- Health checks

**docker-compose.yml:**
- Application service
- Database service (PostgreSQL/MySQL)
- Redis caching
- Environment variables
- Volume mounts
- Network configuration

### Docker Workflow

```bash
## Build and start
docker-compose up -d

## View logs
docker-compose logs -f

## Stop services
docker-compose down

## Rebuild
docker-compose up --build

## Execute commands in container
docker-compose exec app box server info
```

## Vite Integration

### Vite Setup

```bash
## Create app with Vite
coldbox create app myApp --vite

## Available for modern templates
coldbox create app myApp skeleton=modern --vite
```

### Generated Vite Files

**vite.config.mjs:**
- ColdBox/BoxLang integration
- Hot module replacement (HMR)
- Build optimization
- Asset preprocessing
- Proxy configuration

**package.json:**
- Development scripts
- Build scripts
- Preview scripts
- Dependencies

### Vite Workflow

```bash
## Start dev server with HMR
npm run dev

## Build for production
npm run build

## Preview production build
npm run preview
```

### Vite Features

- Hot module replacement (HMR)
- Optimized production builds
- Code splitting
- CSS preprocessing (SCSS, Less)
- JavaScript/TypeScript support
- Asset optimization

## Global Options

Most commands support these options:

### Common Flags

```bash
--force              ## Overwrite existing files without prompting
--open               ## Open generated files in default editor
--boxlang            ## Force BoxLang code generation
--cfml               ## Force CFML code generation
--help               ## Show detailed help
```

### Application Flags

```bash
--migrations         ## Include database migrations support
--docker             ## Include Docker configuration
--vite               ## Include Vite frontend asset building
--rest               ## Configure as REST API application
```

### Generation Flags

```bash
--views              ## Generate views with handlers
--tests              ## Generate test specs
--integrationTests   ## Generate integration tests
--accessors          ## Generate getters/setters
--migration          ## Generate database migration
--service            ## Generate service layer
--handler            ## Generate handler with model
--all                ## Generate all related components
```

## Best Practices

### Project Setup

```bash
## Use wizard for new projects
coldbox create app-wizard

## Pin ColdBox CLI version in box.json
{
    "dependencies": {
        "coldbox-cli": "^8.0.0"
    }
}

## Configure language explicitly
{
    "language": "boxlang"
}
```

### Code Generation

```bash
## Generate complete features at once
coldbox create model User --all

## Use descriptive names
coldbox create handler admin/UserManagement
coldbox create service UserRegistrationService

## Generate tests immediately
coldbox create handler users --integrationTests
coldbox create model User --tests
```

### Module Development

```bash
## Create module with structure
coldbox create module myModule --models --handlers --views

## Keep modules focused
## One module = one feature/domain

## Document module dependencies
{
    "dependencies": {
        "cborm": "^3.0.0",
        "cbvalidation": "^4.0.0"
    }
}
```

### Testing Strategy

```bash
## Generate tests with code
coldbox create handler users --integrationTests
coldbox create model User --tests

## Separate unit and integration tests
coldbox create unit models.UserServiceTest
coldbox create integration-test handlers.UsersTest

## Use BDD for readability
coldbox create bdd features.UserRegistrationTest
```

### AI Integration

```bash
## Install AI integration early
coldbox ai install

## Keep custom guidelines updated
coldbox ai guidelines create team-conventions

## Refresh after major changes
coldbox ai refresh

## Use guidelines for team standards
coldbox ai guidelines create coding-standards --open
```

## Common Patterns

### Full CRUD Workflow

```bash
## Create complete CRUD feature
coldbox create resource users --tests --migration

## What gets generated:
## - handlers/Users.cfc (with all CRUD actions)
## - models/User.cfc (with CRUD methods)
## - views/users/index.cfm
## - views/users/show.cfm
## - views/users/new.cfm
## - views/users/edit.cfm
## - tests/specs/integration/UsersTest.cfc
## - resources/database/migrations/YYYY_MM_DD_HHmmss_create_users_table.cfc

## Add routes
resources( "users" )
```

### REST API Pattern

```bash
## Create REST application
coldbox create app myAPI skeleton=rest --migrations

## Generate API handlers
coldbox create handler api/users --rest
coldbox create handler api/products --rest

## Generate models with migrations
coldbox create model User --migration --service
coldbox create model Product --migration --service

## Configure routes
route( "/api/users" )
    .withHandler( "api.users" )
    .get( index )
    .post( create )
    .get( "/:id", show )
    .put( "/:id", update )
    .delete( "/:id", delete )
```

### Module Pattern

```bash
## Create feature module
coldbox create module blog --models --handlers --views

## Generate module components
cd modules/blog
coldbox create handler Posts
coldbox create model Post --migration
coldbox create view posts/index

## Configure module routes in ModuleConfig
function configure() {
    router
        .route( "/" )
        .withHandler( "Posts" )
        .toAction( { GET: "index", POST: "create" } )
}
```

### Service Layer Pattern

```bash
## Create model and service
coldbox create model User --service

## Or separately
coldbox create model User
coldbox create service UserService

## Service handles business logic
## Model handles data access
## Handler coordinates request/response
```

### Testing Pattern

```bash
## Generate comprehensive tests
coldbox create handler users --integrationTests
coldbox create model User --tests

## Create custom test suites
coldbox create bdd features.UserRegistration
coldbox create bdd features.Checkout
coldbox create bdd features.AdminDashboard

## Run tests
box testbox run
box testbox run --bundles=tests.specs.integration
```

## Troubleshooting

### Command Not Found

If `coldbox` commands aren't recognized:

```bash
## Reinstall CLI
box install coldbox-cli --force

## Verify installation
box coldbox help
```

### Wrong Language Generated

If CLI generates wrong language:

```bash
## Check box.json
{
    "language": "boxlang"
}

## Or use explicit flag
coldbox create handler users --boxlang
coldbox create handler users --cfml
```

### File Overwrite Protection

If CLI refuses to overwrite files:

```bash
## Use force flag
coldbox create handler users --force

## Or remove existing files first
```

### AI Integration Issues

```bash
## Refresh AI configuration
coldbox ai refresh

## Verify installation
coldbox ai info

## Reinstall if needed
coldbox ai uninstall
coldbox ai install
```

## Related Skills

- [Handler Development](../coldbox/handler-development.md) - Handler patterns and best practices
- [Module Development](../coldbox/module-development.md) - Module creation and structure
- [Testing Patterns](../testing/testbox-testing.md) - Testing strategies and patterns

## References

- [ColdBox CLI Repository](https://github.com/coldbox/coldbox-cli)
- [ColdBox Documentation](https://coldbox.ortusbooks.com/getting-started/conventions/cli)
- [ForgeBox Package](https://forgebox.io/view/coldbox-cli)
