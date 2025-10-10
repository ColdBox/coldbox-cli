# ColdBox CLI

<p align="center">
	<img src="https://www.ortussolutions.com/__media/coldbox-185-logo.png">
	<br>
	<img src="https://www.ortussolutions.com/__media/wirebox-185.png" height="125">
	<img src="https://www.ortussolutions.com/__media/cachebox-185.png" height="125" >
	<img src="https://www.ortussolutions.com/__media/logbox-185.png"  height="125">
</p>

<p align="center">
	<a href="https://github.com/coldbox/coldbox-cli/actions/workflows/snapshot.yml"><img src="https://github.com/coldbox/coldbox-cli/actions/workflows/snapshot.yml/badge.svg" alt="ColdBox Snapshots" /></a>
	<a href="https://forgebox.io/view/coldbox-cli"><img src="https://forgebox.io/api/v1/entry/coldbox-cli/badges/downloads" alt="Total Downloads" /></a>
	<a href="https://forgebox.io/view/coldbox-cli"><img src="https://forgebox.io/api/v1/entry/coldbox-cli/badges/version" alt="Latest Stable Version" /></a>
	<a href="https://forgebox.io/view/coldbox-cli"><img src="https://img.shields.io/badge/License-Apache2-brightgreen" alt="Apache2 License" /></a>
</p>

<p align="center">
	Copyright Since 2005 ColdBox Platform by Luis Majano and Ortus Solutions, Corp
	<br>
	<a href="https://www.coldbox.org">www.coldbox.org</a> |
	<a href="https://www.ortussolutions.com">www.ortussolutions.com</a>
</p>

----

This is the official ColdBox CLI for CommandBox.  It is a collection of commands to help you work with ColdBox and its ecosystem for building, testing, and deploying BoxLang and CFML applications.  It provides commands for scaffolding applications, creating tests, modules, models, views, and much more.

## License

Apache License, Version 2.0.

## ColdBox CLI Versions

The CLI also matches the major version of ColdBox.  If you are using ColdBox 7, then you should use CLI `@7`.  This is to ensure that you are using the correct commands for your version of ColdBox.

## System Requirements

- CommandBox 5.5+

## Installation

Install the commands via CommandBox like so:

```bash
box install coldbox-cli
```

## Usage

The ColdBox CLI provides powerful scaffolding and development tools for both **CFML** and **BoxLang** applications. All commands support the `--help` flag for detailed information.

### 📱 Application Creation

Create new ColdBox applications from various templates:

```bash
# Create a basic ColdBox app
coldbox create app myApp

# Create with specific templates
coldbox create app myApp skeleton=modern
coldbox create app myApp skeleton=boxlang
coldbox create app myApp skeleton=rest
coldbox create app myApp skeleton=elixir

# Create with migrations support
coldbox create app myApp --migrations

# Interactive app wizard
coldbox create app-wizard
```

### Application Templates

The CLI supports multiple application templates (skeletons), or you can use your own via any FORGEBOX ID, GitHub repo, local path, zip or URL.  The default templates  for modern development are:

- `boxlang` - A ColdBox app using BoxLang as the primary language.
- `modern` - A modern ColdBox app with the latest features and best practices for both BoxLang or Adobe ColdFusion

The older and flat style templates are:

- `flat` - A classic ColdBox app with a flat structure.
- `rest` - A ColdBox app pre-configured for RESTful APIs.
- `rest-hmvc` - A RESTful ColdBox app using HMVC architecture.
- `vite` - A ColdBox app integrated with Vite for frontend development.

### 🎯 Handlers (Controllers)

Generate MVC handlers with actions and optional views:

```bash
# Basic handler
coldbox create handler myHandler

# Handler with specific actions
coldbox create handler users index,show,edit,delete

# REST handler
coldbox create handler api/users --rest

# Resourceful handler (full CRUD)
coldbox create handler photos --resource

# Generate with views and tests
coldbox create handler users --views --integrationTests
```

### 📊 Models & Services

Create domain models and business services:

```bash
# Basic model
coldbox create model User

# Model with properties and accessors
coldbox create model User properties=fname,lname,email --accessors

# Model with migration
coldbox create model User --migration

# Model with service
coldbox create model User --service

# Model with everything (service, handler, migration, seeder)
coldbox create model User --all

# Standalone service
coldbox create service UserService
```

### 🎨 Views & Layouts

Generate view templates and layouts:

```bash
# Create a view
coldbox create view users/index

# View with helper file
coldbox create view users/show --helper

# View with content
coldbox create view welcome content="<h1>Welcome!</h1>"

# Create layout
coldbox create layout main

# Layout with content
coldbox create layout admin content="<cfoutput>#view()#</cfoutput>"
```

### 🔧 Resources & CRUD

Generate complete resourceful components:

```bash
# Single resource (handler, model, views, routes)
coldbox create resource photos

# Multiple resources
coldbox create resource photos,users,categories

# Custom handler name
coldbox create resource photos PhotoGallery

# With specific features
coldbox create resource users --tests --migration
```

### 📦 Modules

Create reusable ColdBox modules:

```bash
# Create module
coldbox create module myModule

# Module with specific features
coldbox create module myModule --models --handlers --views
```

### 🧪 Testing

Generate various types of tests:

```bash
# Unit tests
coldbox create unit models.UserTest

# BDD specs
coldbox create bdd UserServiceTest

# Integration tests
coldbox create integration-test handlers.UsersTest

# Model tests
coldbox create model-test User

# Interceptor tests
coldbox create interceptor-test Security --actions=preProcess,postProcess
```

### 🗄️ ORM & Database

Work with ORM entities and database operations:

```bash
# ORM Entity
coldbox create orm-entity User table=users

# ORM Service
coldbox create orm-service UserService entity=User

# Virtual Entity Service
coldbox create orm-virtual-service UserService

# ORM Event Handler
coldbox create orm-event-handler

# CRUD operations
coldbox create orm-crud User
```

### 🔗 Interceptors

Create AOP interceptors:

```bash
# Basic interceptor
coldbox create interceptor Security

# Interceptor with specific interception points
coldbox create interceptor Logger points=preProcess,postProcess

# With tests
coldbox create interceptor Security --tests
```

### 🔄 Development Workflow

Manage your development environment:

```bash
# Reinitialize ColdBox framework
coldbox reinit

# Auto-reinit on file changes
coldbox watch-reinit

# Open documentation
coldbox docs
coldbox docs search="event handlers"

# Open API documentation
coldbox apidocs
```

### 🎛️ Global Options

Most commands support these common options:

- `--force` - Overwrite existing files without prompting
- `--open` - Open generated files in your default editor
- `--boxlang` - Force BoxLang code generation (overrides auto-detection)
- `--!boxlang` - Force CFML code generation (overrides auto-detection)
- `--help` - Show detailed help for any command

#### Language Generation Control

The CLI supports both automatic detection and manual override of the target language:

- **Automatic**: Uses detection methods (server engine, `box.json` settings)
- **Force BoxLang**: Use `--boxlang` flag to generate BoxLang code regardless of detection
- **Force CFML**: Use `--!boxlang` flag to generate CFML code regardless of detection

### 💡 BoxLang Support

The CLI automatically detects BoxLang projects and generates appropriate code. You can also force BoxLang mode using the `--boxlang` flag.

#### 🔍 Automatic Detection

The CLI detects BoxLang projects using three methods (in order of precedence):

1. **Server Engine Detection**: Running on a BoxLang server
2. **TestBox Runner Setting**: When `testbox.runner` is set to `"boxlang"` in `box.json`
3. **Language Property**: When `language` is set to `"boxlang"` in `box.json`

#### ⚙️ Configuration Examples

##### Method 1: Language Property (Recommended)

```json
{
    "name": "My BoxLang App",
    "language": "boxlang",
    "testbox": {
        "runner": "/tests/runner.bxm"
    }
}
```

##### Method 2: TestBox Runner Setting

```json
{
    "name": "My App",
    "testbox": {
        "runner": "boxlang"
    }
}
```

#### 🚀 Usage Examples

```bash
# Automatic detection (uses box.json settings)
coldbox create handler users

# Force BoxLang generation (overrides detection)
coldbox create handler users --boxlang

# Force CFML generation (overrides detection)
coldbox create handler users --!boxlang
```

#### 📝 Generated Code Differences

When BoxLang mode is detected or forced:

- Uses `.bx` file extensions instead of `.cfc`
- Generates `class` syntax instead of `component`
- Uses BoxLang-specific template variants
- Creates BoxLang test files (`.bxm` extensions)

### 📖 Getting Help

Every command provides detailed help:

```bash
# General help
coldbox help

# Specific command help
coldbox create handler --help
coldbox create model --help
```

----

## Credits & Contributions

I THANK GOD FOR HIS WISDOM IN THIS PROJECT

### The Daily Bread

"I am the way, and the truth, and the life; no one comes to the Father, but by me (JESUS)" Jn 14:1-12
