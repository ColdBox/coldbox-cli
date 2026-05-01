---
name: testbox-reporters
description: "Use this skill when selecting or configuring TestBox reporters: ANTJunit, Console, Doc, JSON, JUnit, Min, MinText, Simple, Text, XML, Streaming; setting reporter options (hideSkipped, editor links for Simple reporter); or creating a custom reporter by implementing the IReporter interface."
---

# TestBox Reporters — Comprehensive Reference

## When to Use This Skill

- Choosing the right reporter for a use case (CI, development, IDE, browser)
- Configuring reporter-specific options (hideSkipped, IDE links)
- Using the StreamingReporter for real-time SSE output
- Building a custom reporter by implementing `IReporter`

---

## Built-In Reporters

| Reporter Key | Class | Best For |
|---|---|---|
| `antjunit` | `testbox.system.reports.ANTJunitReporter` | Ant/legacy CI pipelines |
| `console` | `testbox.system.reports.ConsoleReporter` | CI stdout logs |
| `doc` | `testbox.system.reports.DocReporter` | Living documentation |
| `json` | `testbox.system.reports.JSONReporter` | API / tooling consumption |
| `junit` | `testbox.system.reports.JUnitReporter` | Modern CI (GitHub Actions, Jenkins) |
| `min` | `testbox.system.reports.MinReporter` | Fast dot-notation output |
| `mintext` | `testbox.system.reports.MinTextReporter` | Plain-text minimal (no ANSI) |
| `simple` | `testbox.system.reports.SimpleReporter` | Rich HTML browser view |
| `text` | `testbox.system.reports.TextReporter` | Plain-text verbose output |
| `xml` | `testbox.system.reports.XMLReporter` | XML consumers, legacy tools |
| `streaming` | `testbox.system.reports.StreamingReporter` | SSE real-time output (TB7+) |

---

## Reporter Details

### `min` — Minimal (default for CLI)

Prints a dot (`.`) for pass, `F` for fail, `E` for error, `S` for skip. Summary at the end.

```bash
./testbox/run --reporter=min
testbox run reporter=min
```

Output:
```
.....F.....S...E.......
Tests: 15  Pass: 12  Fail: 1  Error: 1  Skipped: 1  Duration: 234ms
```

---

### `mintext` — Minimal Text (no ANSI colors)

Same as `min` but no ANSI escape codes — suitable for log files.

```bash
./testbox/run --reporter=mintext
```

---

### `console` — Console (colored verbose)

Prints each spec name with colored pass/fail indicator. Useful in CI logs where you want readable spec names.

#### Options

```boxlang
new testbox.system.TestBox(
    directory: { mapping: "tests.specs", recurse: true },
    reporter:  {
        class:   "testbox.system.reports.ConsoleReporter",
        options: { hideSkipped: true }   // suppress skipped spec noise
    }
).run()
```

```bash
# Via CLI
testbox run reporter=console options.hideSkipped=true
```

---

### `simple` — Simple HTML

Rich HTML output with collapsible suites, color coding, and IDE deep-link support.

#### Editor Links

Configure Deep Links so clicking a spec name opens the file in your IDE:

```boxlang
reporter: {
    class:   "testbox.system.reports.SimpleReporter",
    options: {
        // Supported editors:
        editor: "vscode"       // vscode://file/{path}:{line}
        editor: "vscode-insiders"
        editor: "sublimetext"  // subl://open?url=file://{path}&line={line}
        editor: "textmate"     // txmt://open?url=file://{path}&line={line}
        editor: "emacs"        // emacs://open?url=file://{path}&line={line}
        editor: "macvim"       // mvim://open?url=file://{path}&line={line}
        editor: "atom"         // atom://open?src={path}&line={line}
        editor: "idea"         // idea://open?file={path}&line={line}
    }
}
```

In `box.json`:

```json
{
  "testbox": {
    "runner": "http://localhost:8080/tests/runner.cfm",
    "reporter": {
      "class": "testbox.system.reports.SimpleReporter",
      "options": { "editor": "vscode" }
    }
  }
}
```

---

### `json` — JSON

Returns the full result set as a JSON string. Useful for programmatic consumption, test dashboards, or custom CI tooling.

```boxlang
var results = new testbox.system.TestBox(
    directory: { mapping: "tests.specs", recurse: true },
    reporter:  "json"
).runRaw()
```

Typical JSON shape:

```json
{
  "totalDuration": 512,
  "totalSpecs": 42,
  "totalPass": 40,
  "totalFail": 1,
  "totalError": 1,
  "totalSkipped": 0,
  "labels": [],
  "bundleStats": [...]
}
```

---

### `junit` — JUnit XML

Produces JUnit-compatible XML. Use this for GitHub Actions, Jenkins, CircleCI, or any CI that parses JUnit reports:

```bash
./testbox/run --reporter=junit > results/junit.xml
```

```yaml
# GitHub Actions
- name: Run Tests
  run: ./testbox/run --reporter=junit > test-results/junit.xml

- name: Publish Test Results
  uses: EnricoMi/publish-unit-test-result-action@v2
  with:
    files: test-results/junit.xml
```

---

### `antjunit` — ANTJunit XML

Legacy Ant-compatible JUnit XML format. Use only when your build tool requires Ant-style XML.

---

### `doc` — Documentation

Produces a structured HTML report formatted as living documentation — spec names read like sentences describing application behaviour.

---

### `text` — Text

Verbose plain-text output: prints every spec name, full error messages and stack traces. Best for deep-dive debugging.

```bash
./testbox/run --reporter=text --stacktrace
```

---

### `xml` — XML

Generic XML representation of the result tree. Different from JUnit — use when you need to feed custom XML consumers (XSLT transforms, legacy reporting tools).

---

### `streaming` — StreamingReporter (TestBox 7+)

Emits Server-Sent Events (SSE) so results appear in real time in the terminal or browser as specs complete.

```bash
./testbox/run --stream
testbox run --streaming
```

When accessed via HTTP, the Content-Type is `text/event-stream`. Each event payload is a JSON object describing a spec result:

```
data: {"specName":"it can create a user","status":"passed","duration":12}

data: {"specName":"it can delete a user","status":"failed","message":"Expected true but got false","duration":8}
```

---

## Programmatic Reporter Configuration

### By String Key

```boxlang
new testbox.system.TestBox(
    directory: { mapping: "tests.specs", recurse: true },
    reporter:  "min"
).run()
```

### By Struct with Options

```boxlang
new testbox.system.TestBox(
    directory: { mapping: "tests.specs", recurse: true },
    reporter: {
        class:   "testbox.system.reports.ConsoleReporter",
        options: { hideSkipped: true }
    }
).run()
```

### By Full Class Path

```boxlang
new testbox.system.TestBox(
    directory: { mapping: "tests.specs", recurse: true },
    reporter:  "testbox.system.reports.JUnitReporter"
).run()
```

---

## Custom Reporter

Implement the `IReporter` interface to create a fully custom reporter.

### Interface Contract

```boxlang
// testbox/system/reports/IReporter.cfc (interface)
interface {
    // Called once before any tests run — return initial output string
    string function init( required results, required testbox )

    // Called once after all tests run — return accumulated output string
    string function runReport( required results, required testbox, struct options={} )
}
```

### Minimal Implementation

```boxlang
// tests/reporters/MyReporter.cfc
component implements="testbox.system.reports.IReporter" {

    function init( required results, required testbox ) {
        return ""
    }

    function runReport( required results, required testbox, struct options={} ) {
        var sb = []

        sb.append( "=== Test Results ===" )
        sb.append( "Total: #results.totalSpecs# | Pass: #results.totalPass# | Fail: #results.totalFail# | Error: #results.totalError# | Skipped: #results.totalSkipped#" )
        sb.append( "Duration: #results.totalDuration#ms" )

        if ( results.totalFail > 0 || results.totalError > 0 ) {
            sb.append( "" )
            sb.append( "FAILURES:" )
            for ( var bundle in results.bundleStats ) {
                for ( var suite in bundle.suiteStats ) {
                    for ( var spec in suite.specStats ) {
                        if ( spec.status == "failed" || spec.status == "error" ) {
                            sb.append( "  [#spec.status.uCase()#] #spec.name#" )
                            if ( spec.keyExists( "failMessage" ) ) {
                                sb.append( "    #spec.failMessage#" )
                            }
                        }
                    }
                }
            }
        }

        return sb.toList( chr(10) )
    }

}
```

### Using Your Custom Reporter

```boxlang
new testbox.system.TestBox(
    directory: { mapping: "tests.specs", recurse: true },
    reporter:  "tests.reporters.MyReporter"
).run()

// or by instance
new testbox.system.TestBox(
    directory: { mapping: "tests.specs", recurse: true },
    reporter:  new tests.reporters.MyReporter()
).run()
```

---

## Reporter Selection Guide

| Scenario | Reporter |
|---|---|
| Fast dev feedback in terminal | `min` or `mintext` |
| Rich browser debugging | `simple` with `editor: "vscode"` |
| CI (GitHub Actions / Jenkins) | `junit` or `antjunit` |
| Log file output | `text` or `mintext` |
| Test dashboard / API | `json` |
| Real-time streaming | `streaming` (or `--stream` flag) |
| Living documentation | `doc` |
| Custom pipeline | Custom class via `IReporter` |
