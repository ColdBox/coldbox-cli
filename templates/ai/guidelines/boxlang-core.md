# BoxLang Core Guidelines

## Overview
BoxLang is a modern, dynamic JVM language with a clean class-based syntax.

## Syntax Basics
- Use `class` instead of `component`
- Properties use `property name="value" type="type";`
- Functions don't require the `function` keyword in class context
- Semicolons are optional except for property declarations

## Key Features
- Modern class syntax
- Lambda expressions and streams
- Strong type system (optional typing)
- Full CFML interoperability
- Enhanced performance

## Class Example
```boxlang
class UserService {
    property name="userDAO" inject;

    function getAll() {
        return userDAO.findAll()
    }

    function create( required struct data ) {
        return userDAO.create( data )
    }
}
```

## Lambda Expressions
```boxlang
var numbers = [ 1, 2, 3, 4, 5 ]
var doubled = numbers.map( ( n ) => n * 2 )
var evens = numbers.filter( ( n ) => n % 2 == 0 )
```

## Streams
```boxlang
var users = userService.getAll()
    .stream()
    .filter( ( user ) => user.active )
    .map( ( user ) => user.email )
    .collect()
```
