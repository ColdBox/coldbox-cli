# WireBox Dependency Injection Guidelines

## Overview

WireBox is ColdBox's dependency injection and AOP framework.

## Injection

- `property name="userService" inject;` - Auto-discovery by name
- `property name="userService" inject="UserService";` - Explicit mapping
- `property name="userService" inject="id:UserService";` - By ID
- `property name="userService" inject="model:UserService";` - By DSL

## Scopes

- Transient (default) - New instance each time
- Singleton - One instance for application lifetime
- Request - One instance per request
- Session - One instance per session

## Configuration

- Configure mappings in `config/WireBox.cfc`
- Auto-discovery in `/models/` by default

## Mapping Example

```boxlang
function configure() {
    map( "UserService" )
        .to( "models.services.UserService" )
        .asSingleton()

    map( "UserDAO" )
        .to( "models.dao.UserDAO" )
        .asTransient()
}
```

## Provider Injection

```boxlang
property name="userServiceProvider" inject="provider:UserService";

function someMethod() {
    var userService = userServiceProvider.get()
}
```
