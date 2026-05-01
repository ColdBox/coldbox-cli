---
name: coldbox-testing-coverage
description: "Use this skill when setting up code coverage analysis for ColdBox/ColdFusion/BoxLang applications, configuring coverage reporting, integrating coverage with CI pipelines, using TestBox coverage options, interpreting coverage metrics, or improving test coverage of untested code paths."
---

# Code Coverage Testing in ColdBox

## Overview

Code coverage measures which parts of your code execute during tests. TestBox and CommandBox integrate with coverage tools to generate reports, identify untested code, and track coverage over time.

## Language Mode Reference

Examples use **BoxLang (`.bx`)** syntax by default. Adapt for your target language:

| Concept | BoxLang (`.bx`) | CFML (`.cfc`) |
|---------|-----------------|---------------|
| Class declaration | `class [extends="..."] {` | `component [extends="..."] {` |
| DI annotation | `@inject` above `property name="svc";` | `property name="svc" inject="svc";` |
| View templates | `.bxm` suffix | `.cfm` / `.cfml` suffix |
| Tag prefix | `<bx:if>`, `<bx:output>`, `<bx:set>` | `<cfif>`, `<cfoutput>`, `<cfset>` |

> **CFML Compat Mode**: With BoxLang + CFML Compat module, `.bx` and `.cfc` files coexist freely. BoxLang-native classes use `class {}` (`.bx` files); CFML-compat classes use `component {}` (`.cfc` files).

## Coverage Types

- **Line Coverage**: Percentage of code lines executed
- **Branch Coverage**: Percentage of decision branches taken (if/else paths)
- **Function Coverage**: Percentage of functions called

**Coverage Goals:**
- **80%+** — Good for most projects
- **90%+** — Excellent for critical systems

## TestBox Coverage Configuration

```boxlang
// box.json — configure TestBox coverage
{
    "testbox": {
        "runner": "http://localhost:8080/tests/runner.cfm",
        "coverage": {
            "enabled": true,
            "sonarQubeXML": "coverage/sonarqube.xml",
            "pathMappings": {
                "/app": "#expandPath( '/' )#"
            },
            "excludes": [
                "tests/**",
                "node_modules/**",
                "*.json"
            ],
            "includes": [
                "models/**",
                "handlers/**",
                "modules/**"
            ]
        }
    }
}
```

## Running Coverage via CommandBox

```bash
# Run tests with coverage
box testbox run --coverage

# Generate HTML coverage report
box testbox run --coverage --reporter=HtmlCoverage

# Coverage with specific output directory
box testbox run coverage outputDir=./coverage reporter=HtmlCoverage

# Run and generate Cobertura XML for CI
box testbox run --reporter=Cobertura --outputFile=coverage.xml
```

## Coverage in TestBox Runner

```boxlang
// tests/runner.cfm
<cfscript>
    testBox = new testbox.system.TestBox({
        runner: "http://localhost:8080/index.cfm",
        options: {
            coverage: {
                enabled: true,
                pathMappings: {
                    "/app": expandPath( "/" )
                },
                excludes: [
                    "tests/**",
                    "node_modules/**"
                ]
            }
        }
    })

    results = testBox.run(
        reporter: "HTMLCoverage",
        outputFile: expandPath( "/coverage/report.html" )
    )
</cfscript>
```

## GitHub Actions with Coverage

```yaml
# .github/workflows/coverage.yml
name: Test Coverage

on:
  push:
    branches: [ main, development ]
  pull_request:
    branches: [ main ]

jobs:
  coverage:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - name: Setup CommandBox
        uses: ortus-solutions/setup-commandbox@v2

      - name: Install Dependencies
        run: box install

      - name: Start Server
        run: box server start port=8080

      - name: Run Tests with Coverage
        run: box testbox run --coverage --reporter=Cobertura --outputFile=coverage.xml

      - name: Upload to Codecov
        uses: codecov/codecov-action@v3
        with:
          files: ./coverage.xml
          flags: unittests
          fail_ci_if_error: true

      - name: Stop Server
        if: always()
        run: box server stop
```

## Coverage in Application.cfc (FusionReactor)

```boxlang
// Application.cfc — FusionReactor-based coverage
component {

    function onApplicationStart() {
        if ( getSetting( "environment" ) == "testing" ) {
            application.coverageEnabled = true
        }
    }
}
```

## Identifying Untested Code

```boxlang
/**
 * Pattern: Identify uncovered branches systematically
 */
component extends="testbox.system.BaseSpec" {

    function run() {
        describe( "Coverage-driven testing", () => {

            // Add tests for each branch to hit 100% branch coverage
            describe( "processOrder status handling", () => {

                it( "should handle pending orders", () => {
                    result = orderService.process( { status: "pending" } )
                    expect( result.action ).toBe( "queued" )
                } )

                it( "should handle active orders", () => {
                    result = orderService.process( { status: "active" } )
                    expect( result.action ).toBe( "processing" )
                } )

                it( "should handle cancelled orders", () => {
                    result = orderService.process( { status: "cancelled" } )
                    expect( result.action ).toBe( "skipped" )
                } )

                it( "should handle unknown status", () => {
                    expect( () => {
                        orderService.process( { status: "unknown" } )
                    } ).toThrow( type: "InvalidStatusException" )
                } )
            } )
        } )
    }
}
```

## Coverage Badge in README

```markdown
[![Coverage Status](https://codecov.io/gh/your-org/your-repo/branch/main/graph/badge.svg)](https://codecov.io/gh/your-org/your-repo)
```

## Excluding Code from Coverage

```boxlang
/**
 * Mark code explicitly excluded from coverage
 * (Useful for generated code, dead code paths, etc.)
 */
component {

    /**
     * @covignore
     */
    function legacyMethod() {
        // This method is excluded from coverage reports
    }
}
```

## Coverage Configuration Reference

| Setting | Description | Default |
|---------|-------------|---------|
| `enabled` | Toggle coverage on/off | `false` |
| `sonarQubeXML` | Path for SonarQube XML output | — |
| `pathMappings` | Map virtual paths to disk paths | — |
| `excludes` | Glob patterns to exclude from coverage | `[]` |
| `includes` | Glob patterns to include (if set, excludes all others) | `[]` |

## Improving Coverage Checklist

- [ ] Identify uncovered branches in if/else statements
- [ ] Add tests for exception paths (`toThrow()` assertions)
- [ ] Test null/empty input edge cases
- [ ] Test boundary values (min/max numbers, empty strings)
- [ ] Cover all `switch/case` branches
- [ ] Add integration tests for database error paths
- [ ] Test early-return conditions
