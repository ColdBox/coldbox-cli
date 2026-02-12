---
title: UnleashSDK - Feature Flags & A/B Testing
description: Unleash feature flag SDK for feature toggles and gradual rollouts
---

# UnleashSDK - Feature Flags & A/B Testing

> **Module**: unleashsdk
> **Category**: Feature Management
> **Purpose**: Feature flag management and A/B testing integration with Unleash

## Overview

UnleashSDK integrates Unleash feature flag platform into ColdBox applications, enabling feature toggles, gradual rollouts, A/B testing, and controlled feature releases without code deployments.

## Core Features

- Feature toggle management
- Gradual feature rollouts
- A/B testing and experimentation
- User targeting and segmentation
- Environment-specific features
- Real-time flag updates
- Metrics and analytics
- Custom activation strategies

## Installation

```bash
box install unleashsdk
```

## Configuration

```javascript
// config/ColdBox.cfc - moduleSettings
moduleSettings = {
    unleashsdk: {
        // Unleash server URL
        url: "https://unleash.example.com/api",

        // API token
        apiToken: getSystemSetting( "UNLEASH_API_TOKEN" ),

        // Application name
        appName: "myapp",

        // Environment
        environment: getEnvironment(),

        // Polling interval (minutes)
        refreshInterval: 15,

        // Custom strategies
        strategies: {}
    }
};
```

## Usage Patterns

### Basic Feature Flags

```javascript
component {
    property name="unleash" inject="UnleashClient@unleashsdk";

    function showFeature( event, rc, prc ) {
        // Simple flag check
        if ( unleash.isEnabled( "new-dashboard" ) ) {
            prc.view = "dashboard/new";
        } else {
            prc.view = "dashboard/legacy";
        }
    }

    // With user context
    function showPremiumFeature( event, rc, prc ) {
        var context = {
            userId: auth().user().getId(),
            properties: {
                plan: "premium",
                region: "us-east"
            }
        };

        if ( unleash.isEnabled( "premium-features", context ) ) {
            // Show premium content
        }
    }
}
```

### Gradual Rollout

```javascript
// Enable feature for percentage of users
function showBetaFeature( event, rc, prc ) {
    var context = {
        userId: auth().user().getId()
    };

    // Rollout to 25% of users
    if ( unleash.isEnabled( "beta-editor", context ) ) {
        prc.editorVersion = "beta";
    } else {
        prc.editorVersion = "stable";
    }
}
```

### A/B Testing

```javascript
component {
    property name="unleash" inject="UnleashClient@unleashsdk";

    function showCheckoutFlow( event, rc, prc ) {
        var variant = unleash.getVariant(
            toggle = "checkout-flow",
            context = {
                userId: auth().user().getId()
            }
        );

        switch ( variant.name ) {
            case "variant-a":
                prc.view = "checkout/single-page";
                break;
            case "variant-b":
                prc.view = "checkout/multi-step";
                break;
            default:
                prc.view = "checkout/default";
        }

        // Track variant for analytics
        analytics.track( "checkout_variant", {
            userId: auth().user().getId(),
            variant: variant.name
        } );
    }
}
```

### Custom Activation Strategies

```javascript
// Register custom strategy
component implements="unleashsdk.interfaces.IActivationStrategy" {

    function isEnabled( required struct parameters, required struct context ) {
        // Custom logic
        var userTier = context.properties.tier ?: "free";
        var allowedTiers = listToArray( parameters.tiers ?: "" );

        return allowedTiers.find( userTier );
    }
}

// Register in config
moduleSettings = {
    unleashsdk: {
        strategies: {
            "userTier": getInstance( "UserTierStrategy" )
        }
    }
};
```

### Feature Flag Defaults

```javascript
// Provide fallback value if Unleash unavailable
var isEnabled = unleash.isEnabled(
    toggle = "new-feature",
    context = context,
    default = false // Fallback if service down
);
```

### Multi-Variant Testing

```javascript
function showPricingPage( event, rc, prc ) {
    var variant = unleash.getVariant( "pricing-experiment" );

    prc.pricing = switch ( variant.name ) {
        case "low-price":
            pricingService.getLowPricingTier();
            break;
        case "mid-price":
            pricingService.getMidPricingTier();
            break;
        case "high-price":
            pricingService.getHighPricingTier();
            break;
        default:
            pricingService.getDefaultPricing();
    };

    prc.variantPayload = variant.payload; // Additional config from Unleash
}
```

### View Helper Integration

```javascript
// In view
<cfif unleash.isEnabled( "chat-widget" )>
    <div id="chat-widget">
        <!-- Chat widget code -->
    </div>
</cfif>

<cfif unleash.isEnabled( "promotional-banner", { userId: auth().user().getId() } )>
    <div class="promo-banner">
        <!-- Promotional content -->
    </div>
</cfif>
```

### Feature Dependencies

```javascript
// Check multiple features
function canAccessAdvancedFeatures() {
    var context = { userId: auth().user().getId() };

    return unleash.isEnabled( "premium-plan", context ) &&
           unleash.isEnabled( "advanced-features", context );
}
```

### Environment-Specific Features

```javascript
// Development-only features
if ( unleash.isEnabled( "debug-toolbar" ) && getSetting( "environment" ) == "development" ) {
    prc.showDebugToolbar = true;
}

// Production canary release
if ( unleash.isEnabled( "new-api-version" ) ) {
    prc.apiEndpoint = "/api/v2";
} else {
    prc.apiEndpoint = "/api/v1";
}
```

## Testing with Feature Flags

```javascript
describe( "Feature Flag Behavior", function() {

    beforeEach( function() {
        unleash = createMock( "unleash.Client" );

        // Mock feature flags for testing
        unleash.$( "isEnabled" )
            .$args( "new-feature" )
            .$results( true );
    });

    it( "shows new feature when enabled", function() {
        var event = execute(
            event = "main.index",
            renderResults = true
        );

        expect( event.getRenderedContent() ).toInclude( "new-feature-ui" );
    });

    it( "hides feature when disabled", function() {
        unleash.$( "isEnabled" ).$results( false );

        var event = execute( event = "main.index" );

        expect( event.getRenderedContent() ).notToInclude( "new-feature-ui" );
    });
});
```

## Best Practices

1. **Use Descriptive Names**: Clear, meaningful feature flag names
2. **Clean Up Old Flags**: Remove flags after full rollout
3. **Default to Safe Values**: Fallback to stable behavior
4. **Document Flags**: Maintain flag registry and purpose
5. **Monitor Performance**: Track flag evaluation impact
6. **Test Both States**: Test feature enabled and disabled
7. **Gradual Rollouts**: Use percentage-based rollouts for new features
8. **User Context**: Provide rich context for targeting

## Common Patterns

### Beta Program Access

```javascript
if ( unleash.isEnabled( "beta-program", {
    userId: user.getId(),
    properties: { betaTester: user.isBetaTester() }
} ) ) {
    // Grant beta access
}
```

### Regional Features

```javascript
if ( unleash.isEnabled( "eu-features", {
    properties: { region: user.getRegion() }
} ) ) {
    // EU-specific features
}
```

### Kill Switch

```javascript
// Emergency feature disable
if ( !unleash.isEnabled( "payment-processing" ) ) {
    throw( type="ServiceUnavailable", message="Payment processing temporarily unavailable" );
}
```

##Additional Resources

- [Unleash Documentation](https://docs.getunleash.io/)
- [Feature Toggle Best Practices](https://martinfowler.com/articles/feature-toggles.html)
- [A/B Testing Guide](https://www.optimizely.com/optimization-glossary/ab-testing/)
