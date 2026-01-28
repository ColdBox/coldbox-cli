# TestBox Testing Guidelines

## Overview
TestBox is a BDD/TDD testing framework for CFML/BoxLang.

## BDD Style
```boxlang
describe( "User Registration", function(){
    it( "should create a new user", function(){
        var result = userService.create( { email: "test@test.com" } )
        expect( result ).toBeStruct()
        expect( result.id ).toBeNumeric()
    } )
} )
```

## Assertions
- `expect().toBe()` - Equality check
- `expect().toBeTrue()` - Boolean checks
- `expect().toHaveKey()` - Struct key checks
- `expect().toThrow()` - Exception checks
- `expect().toBeArray()` - Array checks
- `expect().toBeStruct()` - Struct checks

## Test Organization
- Specs in `/tests/specs/`
- Use `beforeEach()` and `afterEach()` for setup/teardown
- Group related tests with `describe()` blocks

## Handler Testing
```boxlang
describe( "Users Handler", function(){
    beforeEach( function(){
        setup()
    } )
    
    it( "should list all users", function(){
        var event = execute( event="users.index", renderResults=true )
        expect( event.getValue( "users", "" ) ).toBeArray()
    } )
} )
```