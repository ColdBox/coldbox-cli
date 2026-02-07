# CBWire Module Guidelines

## Overview

CBWire brings reactive, real-time components to ColdBox applications inspired by Laravel Livewire. Build dynamic interfaces without writing JavaScript using CFML components that automatically sync with the frontend.

## Installation

```bash
box install cbwire
```

## Configuration

In `config/ColdBox.cfc`:

```boxlang
moduleSettings = {
    cbwire = {
        // Component scan paths
        componentPaths = [ "/modules_app", "/models/wires" ],
        
        // Assets CDN
        assetsURL = ""
    }
}
```

## Creating Wire Components

```boxlang
// wires/Counter.cfc
component extends="cbwire.models.Component" {
    
    data = {
        count = 0
    };
    
    function increment() {
        data.count++
    }
    
    function decrement() {
        data.count--
    }
}
```

```cfml
<!-- views/wires/counter.cfm -->
<div>
    <h1>Count: #args.count#</h1>
    <button wire:click="increment">+</button>
    <button wire:click="decrement">-</button>
</div>
```

## Usage in Views

```cfml
<!--- Render wire component --->
#wire( "Counter" )#

<!--- With parameters --->
#wire( "UserProfile", { userId: 1 } )#
```

## Wire Directives

```cfml
<!--- Click events --->
<button wire:click="save">Save</button>

<!--- Model binding --->
<input type="text" wire:model="name">

<!--- Lazy loading --->
<input type="text" wire:model.lazy="search">

<!--- Debounce --->
<input type="text" wire:model.debounce.500ms="search">
```

## Documentation

For complete CBWire documentation, component lifecycle, and directives, visit:
https://cbwire.ortusbooks.com
