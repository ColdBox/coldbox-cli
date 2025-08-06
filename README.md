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

**Available Templates:** `default`, `boxlang`, `modern`, `rest`, `elixir`

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

- `--force` - Overwrite existing files
- `--open` - Open generated files in your default editor
- `--boxlang` - Generate BoxLang code instead of CFML
- `--help` - Show detailed help for any command

### 💡 BoxLang Support

The CLI automatically detects BoxLang projects and generates appropriate code. You can also force BoxLang mode:

```bash
# Force BoxLang generation
coldbox create handler users --boxlang

# BoxLang project detection based on:
# - Server engine (BoxLang)
# - package.json testbox.runner setting
# - package.json language property
```

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
