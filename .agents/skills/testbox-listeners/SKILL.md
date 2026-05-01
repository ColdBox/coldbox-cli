---
name: testbox-listeners
description: "Use this skill when implementing TestBox run listeners (callbacks): onBundleStart, onBundleEnd, onSuiteStart, onSuiteEnd, onSpecStart, onSpecEnd; building progress indicators, custom loggers, or live dashboards that react to test lifecycle events; or passing listener callbacks to TestBox's run(), runRaw(), or the standalone runner."
---

# TestBox Run Listeners — Comprehensive Reference

## When to Use This Skill

- Building custom progress bars, live dashboards, or real-time loggers during test runs
- Reacting to test lifecycle events (bundle start/end, suite start/end, spec start/end)
- Implementing CI annotations that annotate specific failures as they occur
- Integrating with external notification systems (Slack, webhooks) upon suite completion

---

## Listener Events

| Event | When It Fires |
|---|---|
| `onBundleStart` | Before any suite in a bundle (CFC file) begins |
| `onBundleEnd` | After all suites in a bundle complete |
| `onSuiteStart` | Before a `describe()` / `feature()` block begins |
| `onSuiteEnd` | After a `describe()` / `feature()` block completes |
| `onSpecStart` | Before an `it()` / `scenario()` / test function begins |
| `onSpecEnd` | After an `it()` / `scenario()` / test function completes |

---

## Listener Arguments

Each callback receives a single `required struct results` argument. The struct differs by event:

### `onBundleStart` / `onBundleEnd`

```
results = {
    bundle:        <BundleStats CFC>,
    testbox:       <TestBox CFC>,
    bundleReport:  <struct>   // onBundleEnd only — final result struct
}
```

### `onSuiteStart` / `onSuiteEnd`

```
results = {
    suite:       <SuiteStats CFC>,
    bundle:      <BundleStats CFC>,
    testbox:     <TestBox CFC>
}
```

### `onSpecStart` / `onSpecEnd`

```
results = {
    spec:     <SpecStats CFC>,
    suite:    <SuiteStats CFC>,
    bundle:   <BundleStats CFC>,
    testbox:  <TestBox CFC>
}
```

Common `spec` properties:
- `spec.name` — spec display name
- `spec.status` — `"passed"`, `"failed"`, `"error"`, `"skipped"`, `"pending"`
- `spec.duration` — ms taken
- `spec.failMessage` — failure message if status is failed/error
- `spec.failOrigin` — origin file/line of failure

---

## Passing Listeners to TestBox

Listeners are passed as a `callbacks` struct — each key is the event name, value is a closure (or function reference).

### Programmatic

```boxlang
new testbox.system.TestBox(
    directory:  { mapping: "tests.specs", recurse: true },
    reporter:   "min",
    callbacks: {

        onBundleStart: function( required struct results ) {
            systemOutput( ">> Bundle: #results.bundle.path#" )
        },

        onBundleEnd: function( required struct results ) {
            systemOutput( "   Bundle done: #results.bundleReport.totalPass# pass, #results.bundleReport.totalFail# fail" )
        },

        onSuiteStart: function( required struct results ) {
            systemOutput( "  Suite: #results.suite.name#" )
        },

        onSpecEnd: function( required struct results ) {
            switch ( results.spec.status ) {
                case "passed":  systemOutput( "    [OK]   #results.spec.name# (#results.spec.duration#ms)" ); break
                case "failed":  systemOutput( "    [FAIL] #results.spec.name# — #results.spec.failMessage#" ); break
                case "error":   systemOutput( "    [ERR]  #results.spec.name# — #results.spec.failMessage#" ); break
                case "skipped": systemOutput( "    [SKIP] #results.spec.name#" ); break
            }
        }

    }
).run()
```

---

## Class-Based Listeners

For reusable, maintainable listeners, implement them as a component. The component has methods matching the event names.

```boxlang
// tests/listeners/ProgressListener.bx
class {

    property name="failedSpecs" type="array"

    function init() {
        variables.failedSpecs = []
        return this
    }

    function onBundleStart( required struct results ) {
        systemOutput( "" )
        systemOutput( "Bundle: #results.bundle.getBundlePath()#" )
    }

    function onBundleEnd( required struct results ) {
        var r = results.bundleReport
        systemOutput( "  Done | Pass=#r.totalPass# Fail=#r.totalFail# Error=#r.totalError# Skipped=#r.totalSkipped# (#r.totalDuration#ms)" )
    }

    function onSuiteStart( required struct results ) {
        systemOutput( "  Suite: #results.suite.getName()#" )
    }

    function onSpecEnd( required struct results ) {
        var spec = results.spec
        if ( spec.status == "failed" || spec.status == "error" ) {
            variables.failedSpecs.append( spec.name )
            systemOutput( "    [FAIL] #spec.name# — #spec.failMessage ?: 'unknown error'#" )
        }
    }

    function getSummary() {
        return variables.failedSpecs
    }

}
```

```boxlang
// Instantiate and pass to TestBox
var listener = new tests.listeners.ProgressListener()

new testbox.system.TestBox(
    directory: { mapping: "tests.specs", recurse: true },
    callbacks: {
        onBundleStart: listener.onBundleStart,
        onBundleEnd:   listener.onBundleEnd,
        onSuiteStart:  listener.onSuiteStart,
        onSpecEnd:     listener.onSpecEnd
    }
).run()

// Access gathered data after run
var failed = listener.getSummary()
if ( !failed.isEmpty() ) {
    // send webhook, write report, etc.
}
```

---

## Common Listener Patterns

### Progress Bar

```boxlang
var total   = 0
var current = 0

callbacks = {

    // Count total specs first via dry-run or estimate
    onSpecStart: function( required struct results ) {
        current++
        var pct = ( total > 0 ) ? int( current / total * 100 ) : 0
        systemOutput( "\r[#repeatString("#", pct)##repeatString("-", 100 - pct)#] #pct#%", false )
    }

}
```

### Failure Capture for CI Annotation

```boxlang
var failures = []

callbacks = {
    onSpecEnd: function( required struct results ) {
        if ( results.spec.status == "failed" || results.spec.status == "error" ) {
            failures.append( {
                name:    results.spec.name,
                message: results.spec.failMessage ?: "",
                origin:  results.spec.failOrigin  ?: ""
            } )
        }
    }
}

new testbox.system.TestBox(
    directory: { mapping: "tests.specs", recurse: true },
    callbacks: callbacks
).run()

// After run — write GitHub Actions annotations
for ( var f in failures ) {
    // ::error file=...,line=...::message
    systemOutput( "::error file=#f.origin#::#f.name# — #f.message#" )
}
```

### Timing Profiler — Find Slowest Specs

```boxlang
var timings = []

callbacks = {
    onSpecEnd: function( required struct results ) {
        timings.append( {
            name:     results.spec.name,
            duration: results.spec.duration
        } )
    }
}

new testbox.system.TestBox(
    directory: { mapping: "tests.specs", recurse: true },
    callbacks: callbacks
).run()

// Sort and print top 5 slowest
timings.sort( "numeric", "desc", "duration" )
systemOutput( "--- Top 5 Slowest Specs ---" )
timings.slice( 1, min( 5, timings.len() ) ).each( ( t ) => {
    systemOutput( "#t.duration#ms — #t.name#" )
} )
```

### Suite-Level Logging

```boxlang
callbacks = {
    onSuiteStart: function( required struct results ) {
        // Log entry to external system, e.g., Elasticsearch
        logService.info( "Suite started: #results.suite.getName()#" )
    },

    onSuiteEnd: function( required struct results ) {
        var suite = results.suite
        logService.info( "Suite ended: #suite.getName()# — #suite.getTotalPass()# pass, #suite.getTotalFail()# fail" )
    }
}
```

---

## Listener in `runRaw()`

Callbacks work identically with `runRaw()`:

```boxlang
var results = new testbox.system.TestBox(
    directory: { mapping: "tests.specs", recurse: true },
    callbacks: {
        onSpecEnd: ( r ) => systemOutput( r.spec.status == "passed" ? "." : "F" )
    }
).runRaw()
```

---

## Quick Reference

| Event | Good For |
|---|---|
| `onBundleStart` | Log which file is being processed |
| `onBundleEnd` | Per-file summary, CI file annotation |
| `onSuiteStart` | Suite-level logging, progress tracking |
| `onSuiteEnd` | Suite timing, per-suite metrics |
| `onSpecStart` | Timeout tracking, verbose mode |
| `onSpecEnd` | Progress dots, failure capture, timing profiler, notifications |
