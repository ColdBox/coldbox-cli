# CFML Core Guidelines

## Overview

CFML is a dynamic, tag-based language designed for rapid web development.

## Syntax Basics

- Components use `component { }`
- Functions use `function functionName() { }`
- Properties use `property name="propertyName" type="type";`
- Tags available: cfquery, cfloop, cfif, etc.

## Best Practices

- Use CFScript over tags when possible
- Prefer component-based development
- Use meaningful variable names
- Leverage built-in functions

## Component Example

```cfml
component {
    property name="userDAO" inject;

    function getAll() {
        return userDAO.findAll();
    }

    function create( required struct data ) {
        return userDAO.create( data );
    }
}
```

## Query Example

```cfml
function getActiveUsers() {
    var qUsers = queryExecute(
        "SELECT * FROM users WHERE active = :active",
        { active: true },
        { datasource: "myDB" }
    );
    return qUsers;
}
```
