---
name: Code Coverage Testing
description: Complete guide to code coverage analysis in CFML/BoxLang applications, including coverage metrics, reporting, CI integration, and improving test coverage
category: testing
priority: medium
triggers:
  - code coverage
  - test coverage
  - coverage report
  - coverage analysis
  - line coverage
  - branch coverage
---

# Code Coverage Testing

## Overview

Code coverage measures which parts of your code are executed during tests. It helps identify untested code, improve test quality, and maintain confidence in your codebase. While high coverage doesn't guarantee quality tests, it provides valuable metrics for identifying gaps in your test suite.

## Core Concepts

### Coverage Types

- **Line Coverage**: Percentage of code lines executed
- **Branch Coverage**: Percentage of decision branches taken
- **Function Coverage**: Percentage of functions called
- **Statement Coverage**: Percentage of statements executed

### Coverage Metrics

```
Line Coverage = (Lines Executed / Total Lines) × 100
Branch Coverage = (Branches Taken / Total Branches) × 100
Function Coverage = (Functions Called / Total Functions) × 100
```

### Coverage Goals

- **80%+**: Good coverage target for most projects
- **90%+**: Excellent coverage for critical systems
- **100%**: Aspirational (often impractical)

## Coverage Tools

### FusionReactor

FusionReactor provides code coverage for CFML applications.

#### Installation

```bash
# Install FusionReactor (commercial product)
# Download from https://www.fusion-reactor.com/
```

#### Configuration

```boxlang
// Application.cfc
component {
    this.name = "MyApp"

    function onApplicationStart() {
        // Enable coverage tracking
        if ( getSetting( "environment" ) == "testing" ) {
            application.fusionReactor = createObject( "java", "com.intergral.fusionreactor.api.FusionReactor" )
            application.fusionReactor.startCoverageRecording()
        }
    }

    function onRequestEnd() {
        if ( structKeyExists( application, "fusionReactor" ) ) {
            application.fusionReactor.stopCoverageRecording()
            application.fusionReactor.generateCoverageReport( expandPath( "/coverage" ) )
        }
    }
}
```

### CommandBox CFCoverage

```bash
# Install cfcoverage
box install cfcoverage

# Generate coverage report
box testbox run --runner=http://localhost/tests/runner.cfm --coverage=true

# Generate HTML report
box cfcoverage report --format=html --output=coverage.html
```

### Custom Coverage Tracking

```boxlang
/**
 * SimpleCoverageTracker.cfc
 * Basic coverage tracking implementation
 */
component singleton {

    property name="coverage" type="struct"

    function init() {
        reset()
        return this
    }

    function reset() {
        variables.coverage = {
            files: {},
            totalLines: 0,
            coveredLines: 0
        }
        return this
    }

    function trackExecution( filePath, lineNumber ) {
        if ( !coverage.files.keyExists( filePath ) ) {
            coverage.files[filePath] = {
                lines: {},
                totalLines: getTotalLines( filePath )
            }
            coverage.totalLines += coverage.files[filePath].totalLines
        }

        if ( !coverage.files[filePath].lines.keyExists( lineNumber ) ) {
            coverage.files[filePath].lines[lineNumber] = 0
            coverage.coveredLines++
        }

        coverage.files[filePath].lines[lineNumber]++
    }

    function getReport() {
        return {
            coverage: getCoveragePercentage(),
            files: getFileReports(),
            totalLines: coverage.totalLines,
            coveredLines: coverage.coveredLines
        }
    }

    function getCoveragePercentage() {
        if ( coverage.totalLines == 0 ) return 0
        return ( coverage.coveredLines / coverage.totalLines ) * 100
    }

    private function getFileReports() {
        reports = []

        for ( filePath in coverage.files ) {
            fileData = coverage.files[filePath]

            reports.append( {
                file: filePath,
                coverage: ( fileData.lines.count() / fileData.totalLines ) * 100,
                coveredLines: fileData.lines.count(),
                totalLines: fileData.totalLines
            } )
        }

        return reports
    }

    private function getTotalLines( filePath ) {
        content = fileRead( filePath )
        return listLen( content, chr(10) )
    }
}
```

## Generating Coverage Reports

### TestBox Integration

```boxlang
/**
 * runner.cfm
 * Test runner with coverage tracking
 */
component {

    function run() {
        // Initialize coverage tracker
        coverageTracker = getInstance( "CoverageTracker" )
        coverageTracker.reset()

        // Run tests
        testbox = new testbox.system.TestBox(
            directory = {
                mapping: "tests.specs",
                recurse: true
            }
        )

        results = testbox.run()

        // Generate coverage report
        coverage = coverageTracker.getReport()
        saveCoverageReport( coverage )

        return results
    }

    private function saveCoverageReport( coverage ) {
        // Save JSON report
        fileWrite(
            expandPath( "/coverage/coverage.json" ),
            serializeJSON( coverage )
        )

        // Generate HTML report
        html = generateHTMLReport( coverage )
        fileWrite(
            expandPath( "/coverage/coverage.html" ),
            html
        )
    }
}
```

### HTML Report Template

```boxlang
function generateHTMLReport( coverage ) {
    savecontent variable="html" {
        writeOutput( '
            <!DOCTYPE html>
            <html>
            <head>
                <title>Code Coverage Report</title>
                <style>
                    body { font-family: Arial, sans-serif; margin: 20px; }
                    .summary { background: ##f0f0f0; padding: 20px; margin-bottom: 20px; }
                    .coverage-high { color: green; }
                    .coverage-medium { color: orange; }
                    .coverage-low { color: red; }
                    table { border-collapse: collapse; width: 100%; }
                    th, td { border: 1px solid ##ddd; padding: 8px; text-align: left; }
                    th { background: ##4CAF50; color: white; }
                </style>
            </head>
            <body>
                <h1>Code Coverage Report</h1>

                <div class="summary">
                    <h2>Summary</h2>
                    <p>
                        Total Coverage:
                        <strong class="#getCoverageClass( coverage.coverage )#">
                            #numberFormat( coverage.coverage, "0.00" )#%
                        </strong>
                    </p>
                    <p>Covered Lines: #coverage.coveredLines# / #coverage.totalLines#</p>
                </div>

                <h2>File Coverage</h2>
                <table>
                    <thead>
                        <tr>
                            <th>File</th>
                            <th>Coverage</th>
                            <th>Lines</th>
                        </tr>
                    </thead>
                    <tbody>
        ' )

        for ( file in coverage.files ) {
            writeOutput( '
                <tr>
                    <td>#file.file#</td>
                    <td class="#getCoverageClass( file.coverage )#">
                        #numberFormat( file.coverage, "0.00" )#%
                    </td>
                    <td>#file.coveredLines# / #file.totalLines#</td>
                </tr>
            ' )
        }

        writeOutput( '
                    </tbody>
                </table>
            </body>
            </html>
        ' )
    }

    return html
}

private function getCoverageClass( percentage ) {
    if ( percentage >= 80 ) return "coverage-high"
    if ( percentage >= 60 ) return "coverage-medium"
    return "coverage-low"
}
```

## Analyzing Coverage Results

### Identifying Gaps

```boxlang
/**
 * CoverageAnalyzer.cfc
 * Analyzes coverage reports to identify gaps
 */
component {

    function analyzeReport( coverageData ) {
        return {
            summary: getSummary( coverageData ),
            gaps: identifyGaps( coverageData ),
            recommendations: getRecommendations( coverageData )
        }
    }

    private function getSummary( coverageData ) {
        return {
            overallCoverage: coverageData.coverage,
            fileCount: coverageData.files.len(),
            wellCovered: countFilesAbove( coverageData, 80 ),
            poorlyCovered: countFilesBelow( coverageData, 60 ),
            untested: countFilesAt( coverageData, 0 )
        }
    }

    private function identifyGaps( coverageData ) {
        gaps = []

        for ( file in coverageData.files ) {
            if ( file.coverage < 60 ) {
                gaps.append( {
                    file: file.file,
                    coverage: file.coverage,
                    uncoveredLines: file.totalLines - file.coveredLines,
                    priority: calculatePriority( file )
                } )
            }
        }

        // Sort by priority
        gaps.sort( ( a, b ) => b.priority - a.priority )

        return gaps
    }

    private function getRecommendations( coverageData ) {
        recommendations = []

        if ( coverageData.coverage < 60 ) {
            recommendations.append( "Overall coverage is low. Focus on testing core business logic first." )
        }

        if ( countFilesAt( coverageData, 0 ) > 0 ) {
            recommendations.append( "You have untested files. Start by adding basic tests for these." )
        }

        return recommendations
    }

    private function calculatePriority( file ) {
        // Higher priority for files with more uncovered lines
        // and lower current coverage
        uncoveredLines = file.totalLines - file.coveredLines
        coverageGap = 100 - file.coverage

        return uncoveredLines * coverageGap
    }
}
```

### Coverage Enforcement

```boxlang
/**
 * CoverageEnforcer.cfc
 * Enforces minimum coverage thresholds
 */
component {

    property name="minimumCoverage" type="numeric" default="80"
    property name="minimumFileCoverage" type="numeric" default="60"

    function enforce( coverageData ) {
        violations = []

        // Check overall coverage
        if ( coverageData.coverage < minimumCoverage ) {
            violations.append( {
                type: "overall",
                message: "Overall coverage #numberFormat( coverageData.coverage, '0.00' )#% is below minimum #minimumCoverage#%",
                severity: "error"
            } )
        }

        // Check individual files
        for ( file in coverageData.files ) {
            if ( file.coverage < minimumFileCoverage ) {
                violations.append( {
                    type: "file",
                    file: file.file,
                    message: "File coverage #numberFormat( file.coverage, '0.00' )#% is below minimum #minimumFileCoverage#%",
                    severity: "warning"
                } )
            }
        }

        return {
            passed: violations.len() == 0,
            violations: violations
        }
    }
}
```

## Improving Coverage

### Strategies

1. **Start with High-Value Code**: Test business logic first
2. **Test Edge Cases**: Cover error paths and boundary conditions
3. **Incremental Improvement**: Set coverage targets and gradually increase
4. **Review Uncovered Lines**: Understand why code isn't covered
5. **Remove Dead Code**: Delete unused code to improve metrics

### Testing Untested Code

```boxlang
describe( "Previously untested UserService methods", () => {

    it( "should handle duplicate email", () => {
        // Setup: Create user with email
        userService.create( {
            name: "John",
            email: "john@example.com"
        } )

        // Test duplicate detection
        expect( () => {
            userService.create( {
                name: "Jane",
                email: "john@example.com"  // Duplicate
            } )
        } ).toThrow( type = "DuplicateEmail" )
    } )

    it( "should deactivate inactive users", () => {
        // Create old inactive user
        user = userService.create( {
            name: "Old User",
            email: "old@example.com",
            lastLogin: dateAdd( "d", -365, now() )
        } )

        // Run cleanup
        userService.deactivateInactiveUsers()

        // Verify deactivated
        updated = userService.find( user.id )
        expect( updated.active ).toBeFalse()
    } )
} )
```

### Testing Error Paths

```boxlang
describe( "Error handling coverage", () => {

    it( "should handle database connection failure", () => {
        // Mock database to throw error
        mockDB = mockBox.createMock( "models.Database" )
        mockDB.$( "query" ).$throws(
            type = "Database",
            message = "Connection failed"
        )

        userService.setDatabase( mockDB )

        // Should handle error gracefully
        result = userService.listUsers()

        expect( result.success ).toBeFalse()
        expect( result.error ).toInclude( "database" )
    } )

    it( "should validate required fields", () => {
        // Test all validation paths
        testCases = [
            { data: { name: "" }, error: "name" },
            { data: { email: "" }, error: "email" },
            { data: { email: "invalid" }, error: "email" },
            { data: { age: -1 }, error: "age" }
        ]

        for ( testCase in testCases ) {
            result = userService.validate( testCase.data )

            expect( result.isValid ).toBeFalse()
            expect( result.errors ).toHaveKey( testCase.error )
        }
    } )
} )
```

## CI/CD Integration

### GitHub Actions

```yaml
# .github/workflows/test.yml
name: Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v2

      - name: Setup CommandBox
        run: |
          curl -fsSL https://downloads.ortussolutions.com/debs/gpg | sudo apt-key add -
          echo "deb https://downloads.ortussolutions.com/debs/noarch /" | sudo tee -a /etc/apt/sources.list.d/commandbox.list
          sudo apt-get update && sudo apt-get install commandbox

      - name: Install Dependencies
        run: box install

      - name: Run Tests with Coverage
        run: box testbox run --coverage=true

      - name: Check Coverage Threshold
        run: |
          COVERAGE=$(box cfcoverage report --format=json | jq '.coverage')
          echo "Coverage: $COVERAGE%"
          if (( $(echo "$COVERAGE < 80" | bc -l) )); then
            echo "Coverage $COVERAGE% is below threshold 80%"
            exit 1
          fi

      - name: Upload Coverage Report
        uses: actions/upload-artifact@v2
        with:
          name: coverage-report
          path: coverage/
```

### GitLab CI

```yaml
# .gitlab-ci.yml
test:
  stage: test
  image: ortussolutions/commandbox:latest
  script:
    - box install
    - box testbox run --coverage=true
    - box cfcoverage report --format=html --output=coverage.html
  coverage: '/Coverage: (\d+\.\d+)%/'
  artifacts:
    paths:
      - coverage/
    reports:
      coverage_report:
        coverage_format: cobertura
        path: coverage/coverage.xml
```

### CommandBox Task

```boxlang
/**
 * task.cfc in /build
 * Build task with coverage enforcement
 */
component {

    function run() {
        // Run tests with coverage
        command( "testbox run --coverage=true" ).run()

        // Check coverage threshold
        coverage = deserializeJSON(
            fileRead( expandPath( "/coverage/coverage.json" ) )
        )

        if ( coverage.coverage < 80 ) {
            print.redLine( "Coverage #coverage.coverage#% is below threshold 80%" )
            setExitCode( 1 )
        } else {
            print.greenLine( "Coverage #coverage.coverage#% meets threshold" )
        }
    }
}
```

## Best Practices

### Design Guidelines

1. **Set Realistic Targets**: Start with achievable goals (60-70%), increase over time
2. **Focus on Quality**: Coverage alone doesn't ensure good tests
3. **Test Behavior**: Cover functionality, not just lines
4. **Track Trends**: Monitor coverage over time
5. **Enforce Minimums**: Use CI to enforce coverage thresholds
6. **Review Reports**: Regularly analyze coverage data
7. **Test Critical Paths**: Prioritize important business logic
8. **Don't Game Metrics**: Avoid tests that just execute code without assertions
9. **Document Exceptions**: Note why some code isn't covered
10. **Incremental Improvement**: Improve coverage with each PR

### Common Patterns

```boxlang
// ✅ Good: Meaningful test with coverage
it( "should calculate discount correctly", () => {
    order = { total: 100, customerType: "premium" }

    discount = orderService.calculateDiscount( order )

    expect( discount ).toBe( 20 )
} )

// ❌ Bad: Just executing code without verification
it( "covers discount calculation", () => {
    orderService.calculateDiscount( { total: 100 } )
    // No assertions!
} )

// ✅ Good: Testing multiple branches
describe( "Discount calculation", () => {
    it( "should give premium discount", () => {
        discount = orderService.calculateDiscount( {
            total: 100,
            customerType: "premium"
        } )
        expect( discount ).toBe( 20 )
    } )

    it( "should give standard discount", () => {
        discount = orderService.calculateDiscount( {
            total: 100,
            customerType: "standard"
        } )
        expect( discount ).toBe( 10 )
    } )

    it( "should give no discount for new customers", () => {
        discount = orderService.calculateDiscount( {
            total: 100,
            customerType: "new"
        } )
        expect( discount ).toBe( 0 )
    } )
} )
```

## Common Pitfalls

### Pitfalls to Avoid

1. **100% Obsession**: Chasing 100% coverage at all costs
2. **False Confidence**: High coverage with poor tests
3. **Testing Getters/Setters**: Wasting time on trivial code
4. **Ignoring Branches**: Only testing happy paths
5. **Gaming Metrics**: Tests without assertions
6. **No Enforcement**: Not failing builds on low coverage
7. **Stale Reports**: Not updating coverage regularly
8. **Coverage Theater**: Focusing on metrics over quality
9. **Testing Framework Code**: Covering library code
10. **No Review Process**: Not analyzing coverage gaps

### Anti-Patterns

```boxlang
// ❌ Bad: No assertions, just coverage
it( "test user creation", () => {
    userService.create( { name: "John" } )
    // Missing expectations!
} )

// ✅ Good: Meaningful assertions
it( "should create user and return ID", () => {
    user = userService.create( { name: "John" } )

    expect( user.id ).toBeNumeric()
    expect( user.name ).toBe( "John" )
} )

// ❌ Bad: Testing trivial getters
it( "should get name", () => {
    user.setName( "John" )
    expect( user.getName() ).toBe( "John" )
} )

// ✅ Good: Testing actual behavior
it( "should format full name correctly", () => {
    user = createObject( "models.User" ).init(
        firstName = "John",
        lastName = "Doe"
    )

    expect( user.getFullName() ).toBe( "John Doe" )
} )
```

## Related Skills

- [Unit Testing](testing-unit.md) - Unit test patterns
- [Integration Testing](testing-integration.md) - Integration testing
- [Testing BDD](testing-bdd.md) - BDD patterns
- [CI/CD](testing-ci.md) - Continuous integration

## References

- [Code Coverage Best Practices](https://martinfowler.com/bliki/TestCoverage.html)
- [TestBox Coverage](https://testbox.ortusbooks.com/test-runners/code-coverage)
- [FusionReactor Coverage](https://www.fusion-reactor.com/features/code-coverage/)
