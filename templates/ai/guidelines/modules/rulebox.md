---
title: RuleBox Business Rules Engine Module Guidelines
description: Guidance for modeling declarative decision logic with RuleBox, including rule composition, evaluation strategy, testability, and maintainable policy-driven workflows.
---

# RuleBox Business Rules Engine Module Guidelines

## Overview

RuleBox provides a business rules engine for ColdBox applications. Define, evaluate, and manage business rules separately from application logic using a fluent rule builder API.

## Installation

```bash
box install rulebox
```

## Usage

### Basic Rules

```boxlang
property name="ruleEngine" inject="RuleEngine@rulebox";

// Define simple rule
var rule = ruleEngine.newRule()
    .when( ( context ) => context.age >= 18 )
    .then( ( context ) => context.canVote = true )

// Evaluate rule
var context = { age: 21, canVote: false }
rule.evaluate( context )
// context.canVote is now true
```

### Complex Rules

```boxlang
// Discount rule
var discountRule = ruleEngine.newRule()
    .when( ( ctx ) => {
        return ctx.orderTotal >= 100 && ctx.isSubscriber
    } )
    .then( ( ctx ) => {
        ctx.discount = ctx.orderTotal * 0.15
        ctx.discountApplied = true
    } )

// Evaluate
var order = {
    orderTotal: 150,
    isSubscriber: true,
    discount: 0
}
discountRule.evaluate( order )
// order.discount = 22.50
```

### Rule Sets

```boxlang
// Create rule set
var pricingRules = ruleEngine.newRuleSet()
    .addRule( subsciberDiscountRule )
    .addRule( bulkOrderDiscountRule )
    .addRule( firstTimeBuyerDiscountRule )

// Evaluate all rules
pricingRules.evaluate( orderContext )
```

## Common Patterns

```boxlang
// Shipping rules
var shippingRules = ruleEngine.newRuleSet()

// Free shipping over $50
shippingRules.addRule(
    ruleEngine.newRule()
        .when( ( ctx ) => ctx.total >= 50 )
        .then( ( ctx ) => ctx.shippingCost = 0 )
)

// Flat rate under $50
shippingRules.addRule(
    ruleEngine.newRule()
        .when( ( ctx ) => ctx.total < 50 )
        .then( ( ctx ) => ctx.shippingCost = 5.99 )
)

// Apply rules
var order = { total: 75, shippingCost: 0 }
shippingRules.evaluate( order )
```

## Documentation

https://github.com/ortus-solutions/rulebox
