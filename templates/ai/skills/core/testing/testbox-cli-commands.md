---
name: TestBox CLI Commands & Test Execution
description: Complete guide to TestBox CLI commands for test creation, execution, watching, and CI/CD integration. Covers BDD, xUnit, runners, and output formats.
category: testing
priority: high
triggers:
  - testbox cli
  - test command
  - testbox run
  - testbox watch
  - testbox create
  - test runner
  - test execution
---

# TestBox CLI Commands & Test Execution

## Overview

TestBox CLI is a CommandBox module providing comprehensive CLI commands for TestBox testing framework. It enables test creation, execution, watching, and report generation from the command line.

## Installation

```bash
box install testbox-cli
```

## Core Commands

### Running Tests

The `testbox run` command executes tests via HTTP(S) against any server.

```bash
# Run tests using default runner
testbox run

# Specify custom runner URL
testbox run runner="http://localhost:8080/tests/runner.cfm"

# Use relative path (CommandBox server detection)
testbox run runner="/tests/runner.cfm"

# Run specific directory
testbox run directory="tests.specs"

# Run specific bundles
testbox run bundles="tests.specs.UserServiceTest"

# Multiple bundles
testbox run bundles="tests.unit,tests.integration"

# With reporter
testbox run reporter="simple"

# Filter by labels
testbox run labels="integration,database"
testbox run excludes="slow,external"

# Target specific tests
testbox run testBundles="UserServiceTest,ProductServiceTest"
testbox run testSuites="Authentication Suite"
testbox run testSpecs="can create user,can update user"

# Generate output reports
testbox run outputFormats="json,junit,html"
testbox run outputFormats="json,antjunit,xml" outputFile="test-results"

# Verbose output
testbox run verbose=true
```

### Watch Mode

Continuously watch files and auto-run tests on changes.

```bash
# Watch with defaults
testbox watch

# Custom watch paths
testbox watch paths="**.cfc"
testbox watch paths="models/**.cfc,handlers/**.cfc"

# With delay (milliseconds)
testbox watch delay=1000

# Watch with test filtering
testbox watch directory="tests.specs" labels="unit"
testbox watch bundles="tests.unit" verbose=true

# Watch with custom options
testbox watch directory="tests.specs" reporter="simple" labels="integration"
```

## Test Generation

### Creating Tests

```bash
# Create BDD spec
testbox create bdd UserServiceTest
testbox create bdd UserServiceTest open=true
testbox create bdd UserServiceTest directory="tests/specs/services"

# Create xUnit test
testbox create unit UserServiceTest
testbox create unit UserServiceTest directory="tests/unit"

# With package notation
testbox create bdd models/services/UserServiceTest
testbox create unit handlers/UserHandlerTest

# BoxLang vs CFML (auto-detected)
testbox create bdd UserTest --boxlang
testbox create unit UserTest --cfml
```

### Generating Test Infrastructure

```bash
# Generate test harness
testbox generate harness
testbox generate harness directory="myapp"
testbox generate harness --boxlang

# Generate test browser
testbox generate browser
testbox generate browser directory="myapp/tests"

# Generate test visualizer
testbox generate visualizer
testbox generate visualizer directory="myapp"

# Generate TestBox module
testbox generate module myModule
testbox generate module myModule rootDirectory="tests/resources/modules"
```

## Configuration via box.json

Configure default test behavior in your `box.json`:

```json
{
    "testbox": {
        "runner": "http://localhost:8080/tests/runner.cfm",
        "directory": "tests.specs",
        "bundles": "",
        "recurse": true,
        "reporter": "json",
        "labels": "",
        "excludes": "",
        "testBundles": "",
        "testSuites": "",
        "testSpecs": "",
        "verbose": true,
        "watchDelay": 500,
        "watchPaths": "**.cfc",
        "options": {
            "custom1": "value1",
            "custom2": "value2"
        }
    }
}
```

### Setting Configuration

```bash
# Set runner URL
package set testbox.runner="http://localhost:8080/tests/runner.cfm"
package set testbox.runner="/tests/runner.cfm"

# Set test directory
package set testbox.directory="tests.specs"

# Set default options
package set testbox.verbose=true
package set testbox.recurse=true
package set testbox.reporter="simple"

# Set custom options
package set testbox.options.appMapping="/myapp"
package set testbox.options.coverageEnabled=true

# Watch configuration
package set testbox.watchDelay=1000
package set testbox.watchPaths="models/**.cfc,handlers/**.cfc"

# View configuration
package show testbox
```

## Multiple Runner URLs

Configure multiple runner endpoints for different test suites:

```json
{
    "testbox": {
        "runner": [
            { "default": "http://localhost:8080/tests/runner.cfm" },
            { "core": "http://localhost:8080/tests/runner.cfm" },
            { "api": "http://localhost:8080/api/tests/runner.cfm" },
            { "integration": "http://localhost:9000/tests/runner.cfm" }
        ]
    }
}
```

```bash
# Use named runners
testbox run runner="default"
testbox run runner="core"
testbox run runner="api"
testbox run runner="integration"

# Set up multiple runners
package set testbox.runner="[ { default : 'http://localhost/tests/runner.cfm' } ]" --append
package set testbox.runner="[ { api : 'http://localhost/api/tests/runner.cfm' } ]" --append
```

## Output Formats

Generate test reports in multiple formats:

### Available Formats

- `json` - JSON output (default)
- `xml` - XML output
- `junit` - JUnit XML format
- `antjunit` - Ant JUnit XML format
- `simple` - Simple text report
- `dot` - Dot notation output
- `doc` - Documentation style HTML
- `min` - Minimal HTML
- `mintext` - Minimal text
- `text` - Text format
- `tap` - TAP (Test Anything Protocol)
- `codexwiki` - Codex Wiki markdown

### Usage

```bash
# Single format
testbox run outputFormats="json"

# Multiple formats
testbox run outputFormats="json,junit,html" outputFile="results"

# Results in files:
# - results.json
# - results-junit.xml
# - results-doc.html

# Common CI/CD patterns
testbox run outputFormats="json,junit" outputFile="test-results"
testbox run outputFormats="antjunit" outputFile="build/test-results"
```

## Runner Options

All arguments can be passed via command line or configured in `box.json`:

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `runner` | string | `/tests/runner.cfm` | URL or slug of test runner |
| `bundles` | string | `""` | Comma-separated list of bundle CFCs |
| `directory` | string | `""` | Directory mapping to test |
| `recurse` | boolean | `true` | Recurse directory mapping |
| `reporter` | string | `json` | Reporter type |
| `labels` | string | `""` | Required labels filter |
| `excludes` | string | `""` | Excluded labels filter |
| `options` | struct | `{}` | Custom URL parameters |
| `testBundles` | string | `""` | Specific bundles to run |
| `testSuites` | string | `""` | Specific suites to run |
| `testSpecs` | string | `""` | Specific specs to run |
| `outputFile` | string | `""` | Output file path |
| `outputFormats` | string | `""` | Output formats to generate |
| `verbose` | boolean | `true` | Display detailed output |

## Language Detection

TestBox CLI automatically detects BoxLang vs CFML projects using:

1. **Server Detection** - Is CommandBox server running BoxLang?
2. **Runner Configuration** - `testbox.runner="boxlang"` in box.json
3. **Language Property** - `language="boxlang"` in box.json

```bash
# Force BoxLang generation
testbox create bdd UserTest --boxlang

# Force CFML generation
testbox create unit UserTest --cfml
```

## Common Patterns

### Local Development

```bash
# Set up for local testing
package set testbox.runner="/tests/runner.cfm"
server start
testbox run

# Enable watch mode during development
testbox watch paths="models/**.cfc,handlers/**.cfc"
```

### CI/CD Integration

```bash
# Generate reports for CI
testbox run \
    directory="tests.specs" \
    outputFormats="json,junit,html" \
    outputFile="build/test-results" \
    verbose=false

# Check test results
if [ $? -ne 0 ]; then
    echo "Tests failed!"
    exit 1
fi
```

### Multi-Environment Testing

```json
{
    "testbox": {
        "runner": [
            { "local": "/tests/runner.cfm" },
            { "dev": "https://dev.example.com/tests/runner.cfm" },
            { "staging": "https://staging.example.com/tests/runner.cfm" }
        ]
    }
}
```

```bash
# Test against different environments
testbox run runner="local"
testbox run runner="dev"
testbox run runner="staging"
```

### Focused Testing

```bash
# Test specific areas
testbox run directory="tests.unit" labels="fast"
testbox run bundles="tests.integration.DatabaseTest" verbose=true

# Exclude slow tests during development
testbox run directory="tests.specs" excludes="slow,external"

# Run only integration tests
testbox run directory="tests.specs" labels="integration"
```

## Documentation Commands

```bash
# Open TestBox documentation
testbox docs
testbox docs search="assertions"
testbox docs search="mocking"

# Open API documentation
testbox apidocs
```

## Best Practices

### Test Organization

```bash
# Separate test types
testbox create bdd services/UserServiceTest directory="tests/specs/services"
testbox create unit models/UserTest directory="tests/unit/models"
testbox create bdd integration/APITest directory="tests/specs/integration"
```

### Watch Mode Usage

```bash
# Watch relevant files only
testbox watch paths="models/**.cfc,tests/specs/**.cfc"

# Faster polling for rapid development
testbox watch delay=250

# Configure in box.json for team consistency
package set testbox.watchPaths="models/**.cfc,handlers/**.cfc"
package set testbox.watchDelay=500
```

### CI/CD Configuration

```json
{
    "testbox": {
        "runner": "/tests/runner.cfm",
        "directory": "tests.specs",
        "reporter": "json",
        "verbose": false,
        "outputFormats": "json,junit"
    }
}
```

```bash
# CI command
testbox run outputFile="reports/test-results"
```

## Troubleshooting

### Runner Not Found

```bash
# Check configuration
package show testbox.runner

# Set correct runner
package set testbox.runner="/tests/runner.cfm"

# Verify server is running
server status
server start
```

### Tests Not Running

```bash
# Check runner URL accessibility
curl http://localhost:8080/tests/runner.cfm

# Verify test directory
package show testbox.directory

# Run with verbose output
testbox run verbose=true
```

### Watch Mode Issues

```bash
# Check watch configuration
package show testbox.watchPaths
package show testbox.watchDelay

# Increase delay if too sensitive
package set testbox.watchDelay=1000

# Narrow watch paths
package set testbox.watchPaths="tests/**.cfc"
```

## Template Locations

TestBox CLI includes templates for:

- BDD specs (`templates/bx/bdd.txt`, `templates/cfml/bdd.txt`)
- xUnit tests (`templates/bx/unit.txt`, `templates/cfml/unit.txt`)
- Test harness (`templates/bx/tests/`, `templates/cfml/tests/`)
- Test browser (`templates/cfml/browser/`)
- Test visualizer (`templates/visualizer/`)
- TestBox modules (`templates/bx/module/`, `templates/cfml/module/`)

## Integration with ColdBox

When using ColdBox framework:

```bash
# ColdBox automatically configures TestBox CLI
coldbox create app myapp --testing

# Generated box.json includes:
# {
#   "testbox": {
#     "runner": "/tests/runner.cfm"
#   }
# }

# Run ColdBox tests
testbox run

# Watch ColdBox application
testbox watch paths="models/**.cfc,handlers/**.cfc,tests/**.cfc"
```

## Advanced Usage

### Custom Test Options

```bash
# Pass custom parameters to runner
testbox run options:appMapping="/myapp" options:coverageEnabled=true

# In box.json
package set testbox.options.appMapping="/myapp"
package set testbox.options.datasource="testdb"
```

### Test Filtering

```bash
# Multiple label filters
testbox run labels="unit,fast" excludes="database,external"

# Target specific test methods
testbox run testSpecs="can create user,can update user,can delete user"

# Target test suites
testbox run testSuites="User Management,Product Management"
```

### Output File Naming

```bash
# Default naming
testbox run outputFormats="json,junit" outputFile="results"
# Creates: results.json, results-junit.xml

# With paths
testbox run outputFormats="json,junit" outputFile="build/reports/test-results"
# Creates: build/reports/test-results.json, build/reports/test-results-junit.xml
```

## Related Skills

- [TestBox Testing](testbox-testing.md) - TestBox framework and testing patterns
- [ColdBox Testing](../coldbox/coldbox-testing.md) - ColdBox application testing
- [Handler Testing](../coldbox/handler-development.md) - Handler test patterns

## References

- [TestBox CLI GitHub](https://github.com/ortus-solutions/testbox-cli)
- [TestBox CLI Documentation](https://testbox.ortusbooks.com/getting-started/running-tests/commandbox-runner)
- [TestBox Documentation](https://testbox.ortusbooks.com/)
- [CommandBox Documentation](https://commandbox.ortusbooks.com/)
