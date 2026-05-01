---
name: testbox-runners
description: "Use this skill when running TestBox tests: CommandBox CLI (testbox run), BoxLang CLI (./testbox/run), HTML web runner, programmatic TestBox instantiation (run/runRaw/runRemote), configuring test directories or bundles, using the streaming runner (--stream flag / StreamingRunner), watcher mode, all CLI flags (--show-failed-only, --dry-run, --slow-threshold-ms, --stacktrace, --max-failures), or setting up box.json testbox configuration."
---

# TestBox Runners — Comprehensive Reference

## When to Use This Skill

- Running tests from the command line (CommandBox or BoxLang CLI)
- Configuring `testbox` in `box.json`
- Starting a file-watcher to auto-run tests on change
- Using `--stream` / `StreamingRunner` for SSE-based real-time output
- Invoking TestBox programmatically from CFML/BoxLang code
- Choosing the right runner for a use case (CLI, web, CI, programmatic)

---

## Runner Overview

| Runner | Use Case |
|---|---|
| CommandBox CLI | Standard development workflow; wraps `testbox run` |
| BoxLang CLI | BoxLang projects; binary at `./testbox/run` |
| HTML Web Runner | Browser-based interactive test runner |
| Programmatic API | Embedding tests in application code or custom scripts |
| StreamingRunner | Real-time SSE-based output (TestBox 7+) |

---

## CommandBox CLI Runner

### Basic Usage

```bash
# Run all tests configured in box.json
testbox run

# Override directory at runtime
testbox run runner="http://localhost:8080/tests/runner.cfm"
```

### `box.json` Configuration

```json
{
  "testbox": {
    "runner": "http://localhost:8080/tests/runner.cfm",
    "verbose": false,
    "labels": "",
    "excludes": "",
    "reporter": "min",
    "recurse": true,
    "bundles": "",
    "directory": {
      "mapping": "tests.specs",
      "recurse": true,
      "filter": ""
    },
    "options": {}
  }
}
```

### Key CLI Flags

```bash
# Streaming real-time output (SSE)
testbox run --streaming

# Verbose output
testbox run verbose=true

# Specific reporter
testbox run reporter=json

# Run with labels
testbox run labels=integration

# Limit concurrent specs (parallel)
testbox run options.maxParallel=4
```

### File Watcher

Start a persistent process that re-runs tests on file changes:

```bash
testbox watch

# Watch specific directory
testbox watch directory=models

# With streaming output
testbox watch --streaming
```

Watch is configured in `box.json`:

```json
{
  "testbox": {
    "runner": "http://localhost:8080/tests/runner.cfm",
    "watchDelay": 500,
    "watchPaths": "**.cfc,templates/**"
  }
}
```

---

## BoxLang CLI Runner

For BoxLang projects, TestBox ships a native binary runner at `./testbox/run`.

### Installation

TestBox CLI runner is automatically installed when TestBox is a dependency:

```bash
# Install testbox (adds ./testbox/run)
install testbox
```

### All Flags

```bash
# Run all specs under tests/
./testbox/run

# Run specific directory
./testbox/run --directory=tests/unit

# Run specific bundles (comma-separated)
./testbox/run --bundles=tests.specs.MySpec,tests.specs.OtherSpec

# Streaming / real-time output
./testbox/run --stream

# Dry run — discover specs without executing
./testbox/run --dry-run

# Show only failed specs
./testbox/run --show-failed-only

# Show passed specs explicitly
./testbox/run --show-passed

# Show skipped specs explicitly
./testbox/run --show-skipped

# Show full stack traces
./testbox/run --stacktrace

# Set maximum failures before stopping
./testbox/run --max-failures=10

# Flag specs slower than N ms
./testbox/run --slow-threshold-ms=100

# Show top N slowest specs
./testbox/run --top-slowest=5

# Set reporter (min, json, junit, etc.)
./testbox/run --reporter=min

# Combine options
./testbox/run --directory=tests/unit --show-failed-only --slow-threshold-ms=50 --top-slowest=5
```

### Exit Codes

| Code | Meaning |
|---|---|
| `0` | All tests passed |
| `1` | One or more failures or errors |

Use exit codes in CI/CD pipelines to gate deployments.

---

## StreamingRunner (TestBox 7+)

The StreamingRunner emits specs in real time using SSE (Server-Sent Events), allowing the terminal or browser to show results as they complete instead of waiting for the full suite.

### Via CommandBox

```bash
testbox run --streaming
```

### Via BoxLang CLI

```bash
./testbox/run --stream
```

### Programmatic Setup

```boxlang
var runner = new testbox.system.runners.StreamingRunner()
runner.run(
    directory: { mapping: "tests.specs", recurse: true },
    reporter:  "min",
    labels:    []
)
```

### Web Endpoint (SSE)

The web-based streaming endpoint sends `text/event-stream`:

```
GET /testbox/runners/streamingrunner.bxm?reporter=min&directory=tests.specs
```

Browser-side:

```javascript
const es = new EventSource( "/testbox/stream?reporter=min" )
es.onmessage = ( e ) => console.log( JSON.parse( e.data ) )
```

---

## HTML Web Runner

The HTML runner is the classic browser-based test interface.

### Quick Setup

```
http://localhost:8080/tests/runner.cfm
```

Create `tests/runner.cfm` (or `tests/runner.cfm`):

```cfm
<cfscript>
    // Defaults: directory = /tests/specs
    new testbox.system.TestBox(
        directory: { mapping: "tests.specs", recurse: true }
    ).run()
</cfscript>
```

### With Options

```cfm
<cfscript>
    new testbox.system.TestBox(
        directory: { mapping: "tests.specs", recurse: true },
        reporter:  "simple",
        labels:    url.keyExists( "labels" ) ? url.labels : [],
        excludes:  [],
        options:   {}
    ).run()
</cfscript>
```

---

## Programmatic Runner API

### TestBox Construction

```boxlang
// By directory
var tb = new testbox.system.TestBox(
    directory: {
        mapping: "tests.specs",   // dot-notation mapping
        recurse:  true,
        filter:   ""              // optional glob filter
    }
)

// By specific bundles
var tb = new testbox.system.TestBox(
    bundles: [
        "tests.specs.unit.UserServiceSpec",
        "tests.specs.integration.APISpec"
    ]
)

// With reporter and labels
var tb = new testbox.system.TestBox(
    directory: { mapping: "tests.specs", recurse: true },
    reporter:  "json",
    labels:    [ "unit", "fast" ],
    excludes:  [ "slow" ]
)
```

### Running

```boxlang
// Run and render output (returns and writes results to browser/stdout)
tb.run()

// Run and return raw result struct
var results = tb.runRaw()
// results.totalDuration, results.totalSpecs, results.totalPass,
// results.totalFail, results.totalError, results.totalSkipped

// Run via HTTP and return result string (for cross-server testing)
var output = tb.runRemote(
    testBundles: "tests.specs.MySpec",
    reporter:    "json",
    options:     {}
)
writeOutput( output )
```

### Inspecting Raw Results

```boxlang
var results = new testbox.system.TestBox(
    directory: { mapping: "tests.specs", recurse: true }
).runRaw()

if ( results.totalFail > 0 || results.totalError > 0 ) {
    // CI: exit with failure
    systemOutput( "TESTS FAILED: #results.totalFail# failures, #results.totalError# errors" )
    abort
}
```

---

## Auto-Load via `Application.bx`

In BoxLang projects, wire TestBox into the app lifecycle so you can hit `/tests/` without a dedicated runner file:

```boxlang
// Application.bx
class {
    variables.this.name    = "MyApp"
    variables.this.mappings[ "/testbox" ] = expandPath( "/testbox" )
    variables.this.mappings[ "/tests"   ] = expandPath( "/tests"   )
}
```

---

## Integration Testing with `bx-web-support`

Install the `bx-web-support` BoxLang module to run web requests from the CLI runner:

```bash
install bx-web-support
./testbox/run --directory=tests/integration
```

Integration tests can then make HTTP calls directly without a running web server.

---

## CI/CD Integration

```yaml
# GitHub Actions example
- name: Run TestBox Tests
  run: |
    ./testbox/run --directory=tests --reporter=junit --show-failed-only
  # Non-zero exit on failure automatically fails the step
```

```bash
# Jenkins / generic shell
./testbox/run --directory=tests --reporter=junit
if [ $? -ne 0 ]; then
  echo "Tests failed"
  exit 1
fi
```

---

## Quick Reference

| Task | Command |
|---|---|
| Run all tests | `./testbox/run` or `testbox run` |
| Stream output | `./testbox/run --stream` |
| Only failures | `./testbox/run --show-failed-only` |
| Dry run | `./testbox/run --dry-run` |
| Stack traces | `./testbox/run --stacktrace` |
| Slow spec report | `./testbox/run --slow-threshold-ms=200 --top-slowest=10` |
| Max failures | `./testbox/run --max-failures=5` |
| Specific directory | `./testbox/run --directory=tests/unit` |
| Specific bundles | `./testbox/run --bundles=tests.specs.MySpec` |
| JUnit for CI | `./testbox/run --reporter=junit` |
| Watch mode | `testbox watch` |
