# ColdBox Framework Core Guidelines

## Overview
ColdBox is a conventions-based HMVC framework for CFML/BoxLang applications.

## Handler Conventions
- Handlers extend `coldbox.system.EventHandler`
- Located in `/handlers/` directory
- Use plural nouns: `Users.cfc`, `Orders.cfc`
- Actions are public functions

## Dependency Injection
- Use `property name="service" inject;` for automatic injection
- WireBox provides dependency injection
- Inject by convention (name matches), by ID, or by DSL

## Event Model
- `event.getValue()` - Get request collection value
- `event.setValue()` - Set request collection value
- `event.renderData()` - Render JSON/XML/etc
- `prc` - Private request collection
- `rc` - Request collection

## Routing
- Routes defined in `config/Router.cfc`
- Convention: `event` parameter determines handler.action
- RESTful routes supported

## Handler Example
```boxlang
class Users extends coldbox.system.EventHandler {
    property name="userService" inject;
    
    function index( event, rc, prc ) {
        prc.users = userService.getAll()
        event.setView( "users/index" )
    }
    
    function create( event, rc, prc ) {
        var user = userService.create( rc )
        event.renderData(
            data = user,
            statusCode = 201
        )
    }
}
```