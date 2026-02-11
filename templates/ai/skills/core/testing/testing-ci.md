---
name: Continuous Integration Testing
description: Complete guide to setting up continuous integration for automated testing, build pipelines, deployment workflows, and CI best practices
category: testing
priority: medium
triggers:
  - continuous integration
  - CI/CD
  - automated testing
  - build pipeline
  - github actions
  - gitlab ci
  - jenkins
---

# Continuous Integration Testing

## Overview

Continuous Integration (CI) is the practice of automatically building and testing code changes. CI ensures that your application remains in a working state, catches bugs early, and provides rapid feedback to developers. For CFML/BoxLang applications, CI involves running tests, checking code coverage, and validating builds on every commit.

## Core Concepts

### CI/CD Principles

- **Continuous Integration**: Automatically test every code change
- **Continuous Delivery**: Automatically deploy to staging/production
- **Fast Feedback**: Run tests quickly to provide rapid feedback
- **Automated Quality**: Enforce standards without manual intervention
- **Build Once, Deploy Many**: Create artifacts that can be deployed anywhere

### CI Workflow

```
Code Push → Build → Test → Coverage → Quality Checks → Artifact → Deploy
```

## GitHub Actions

### Basic Workflow

```yaml
# .github/workflows/tests.yml
name: Tests

on:
  push:
    branches: [ main, development ]
  pull_request:
    branches: [ main, development ]

jobs:
  test:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout code
        uses: actions/checkout@v3

      - name: Setup Java
        uses: actions/setup-java@v3
        with:
          distribution: 'temurin'
          java-version: '11'

      - name: Install CommandBox
        run: |
          curl -fsSL https://downloads.ortussolutions.com/debs/gpg | sudo apt-key add -
          echo "deb https://downloads.ortussolutions.com/debs/noarch /" | sudo tee /etc/apt/sources.list.d/commandbox.list
          sudo apt-get update && sudo apt-get install commandbox

      - name: Start CommandBox
        run: box start port=8080

      - name: Install Dependencies
        run: box install

      - name: Run Tests
        run: box testbox run

      - name: Stop Server
        if: always()
        run: box stop
```

### Advanced Configuration

```yaml
# .github/workflows/ci.yml
name: CI Pipeline

on:
  push:
    branches: [ main, development ]
  pull_request:
    branches: [ main ]

env:
  COMMANDBOX_VERSION: 5.9.0

jobs:
  test:
    name: Test on ${{ matrix.cfengine }}
    runs-on: ubuntu-latest

    strategy:
      matrix:
        cfengine:
          - lucee@5.4
          - adobe@2021
          - boxlang@1.0.0

    steps:
      - uses: actions/checkout@v3

      - name: Setup CommandBox
        uses: ortus-solutions/setup-commandbox@v2
        with:
          version: ${{ env.COMMANDBOX_VERSION }}

      - name: Cache Dependencies
        uses: actions/cache@v3
        with:
          path: |
            ~/.CommandBox
            ~/.box
          key: ${{ runner.os }}-commandbox-${{ hashFiles('**/box.json') }}

      - name: Install Dependencies
        run: box install

      - name: Start Server
        run: box server start cfengine=${{ matrix.cfengine }} port=8080 --noSaveSettings

      - name: Run Tests
        run: box testbox run

      - name: Generate Coverage Report
        if: matrix.cfengine == 'boxlang@1.0.0'
        run: box testbox run --coverage

      - name: Upload Coverage
        if: matrix.cfengine == 'boxlang@1.0.0'
        uses: codecov/codecov-action@v3
        with:
          files: ./coverage/coverage.xml
          flags: unittests
          name: codecov-umbrella

      - name: Archive Test Results
        if: always()
        uses: actions/upload-artifact@v3
        with:
          name: test-results-${{ matrix.cfengine }}
          path: tests/results/

      - name: Stop Server
        if: always()
        run: box server stop

  lint:
    name: Code Quality
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v3

      - name: CFLint
        run: |
          box install cflint
          box cflint pattern=**/*.cfc

      - name: Format Check
        run: |
          box install commandbox-cfformat
          box cfformat check

  build:
    name: Build Artifact
    needs: [test, lint]
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'

    steps:
      - uses: actions/checkout@v3

      - name: Setup CommandBox
        uses: ortus-solutions/setup-commandbox@v2

      - name: Build
        run: box task run build

      - name: Create Release Artifact
        run: |
          mkdir -p artifacts
          zip -r artifacts/app-${{ github.sha }}.zip * -x ".*" "tests/*" "node_modules/*"

      - name: Upload Artifact
        uses: actions/upload-artifact@v3
        with:
          name: app-artifact
          path: artifacts/
```

## GitLab CI

### Basic Pipeline

```yaml
# .gitlab-ci.yml
image: ortussolutions/commandbox:latest

stages:
  - test
  - coverage
  - deploy

before_script:
  - box install

test:
  stage: test
  script:
    - box server start port=8080 --noSaveSettings
    - box testbox run
    - box server stop
  artifacts:
    reports:
      junit: tests/results/*.xml
    paths:
      - tests/results/

coverage:
  stage: coverage
  script:
    - box testbox run --coverage
  coverage: '/Coverage: (\d+\.\d+)%/'
  artifacts:
    reports:
      coverage_report:
        coverage_format: cobertura
        path: coverage/coverage.xml

deploy:staging:
  stage: deploy
  script:
    - box task run deploy environment=staging
  only:
    - development
  environment:
    name: staging
    url: https://staging.example.com

deploy:production:
  stage: deploy
  script:
    - box task run deploy environment=production
  only:
    - main
  when: manual
  environment:
    name: production
    url: https://example.com
```

### Advanced Configuration

```yaml
# .gitlab-ci.yml
variables:
  MYSQL_DATABASE: test_db
  MYSQL_ROOT_PASSWORD: root

stages:
  - setup
  - test
  - quality
  - build
  - deploy

.test_template: &test_definition
  stage: test
  before_script:
    - box install
  script:
    - box server start cfengine=$CF_ENGINE port=8080 --noSaveSettings
    - box testbox run
    - box server stop
  artifacts:
    when: always
    reports:
      junit: tests/results/*.xml

test:lucee:
  <<: *test_definition
  variables:
    CF_ENGINE: lucee@5.4

test:adobe:
  <<: *test_definition
  variables:
    CF_ENGINE: adobe@2021

test:boxlang:
  <<: *test_definition
  variables:
    CF_ENGINE: boxlang@1.0.0

integration:
  stage: test
  services:
    - mysql:latest
  variables:
    DB_HOST: mysql
  script:
    - box install
    - box server start
    - box task run migrate
    - box testbox run --bundles=integration
    - box server stop

lint:
  stage: quality
  script:
    - box install cflint
    - box cflint pattern=**/*.cfc
  allow_failure: true

security:
  stage: quality
  script:
    - box install commandbox-security-scanner
    - box security scan
  allow_failure: true

build:
  stage: build
  script:
    - box task run build
    - zip -r app-$CI_COMMIT_SHA.zip * -x ".*" "tests/*"
  artifacts:
    paths:
      - app-$CI_COMMIT_SHA.zip
    expire_in: 1 week
  only:
    - main
```

## Jenkins Pipeline

### Jenkinsfile

```groovy
pipeline {
    agent any

    environment {
        COMMANDBOX_HOME = "/usr/local/bin/box"
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Install Dependencies') {
            steps {
                sh 'box install'
            }
        }

        stage('Start Server') {
            steps {
                sh 'box server start port=8080 --noSaveSettings'
            }
        }

        stage('Run Tests') {
            steps {
                sh 'box testbox run'
            }
            post {
                always {
                    junit 'tests/results/**/*.xml'
                }
            }
        }

        stage('Coverage') {
            steps {
                sh 'box testbox run --coverage'
                publishHTML([
                    reportDir: 'coverage',
                    reportFiles: 'index.html',
                    reportName: 'Coverage Report'
                ])
            }
        }

        stage('Code Quality') {
            parallel {
                stage('Lint') {
                    steps {
                        sh 'box install cflint'
                        sh 'box cflint pattern=**/*.cfc'
                    }
                }
                stage('Format Check') {
                    steps {
                        sh 'box install commandbox-cfformat'
                        sh 'box cfformat check'
                    }
                }
            }
        }

        stage('Build') {
            when {
                branch 'main'
            }
            steps {
                sh 'box task run build'
                archiveArtifacts artifacts: 'build/**/*.zip'
            }
        }

        stage('Deploy') {
            when {
                branch 'main'
            }
            steps {
                input message: 'Deploy to production?'
                sh 'box task run deploy environment=production'
            }
        }
    }

    post {
        always {
            sh 'box server stop'
            cleanWs()
        }
    }
}
```

## Build Tasks

### CommandBox Build Task

```boxlang
/**
 * Build.cfc
 * CommandBox task for CI builds
 */
component {

    function run() {
        print.line( "Starting build process..." )

        // Clean previous builds
        cleanBuild()

        // Install dependencies
        command( "install --production" ).run()

        // Run tests
        if ( !runTests() ) {
            print.redLine( "Tests failed!" )
            return setExitCode( 1 )
        }

        // Check coverage
        if ( !checkCoverage() ) {
            print.redLine( "Coverage below threshold!" )
            return setExitCode( 1 )
        }

        // Lint code
        if ( !lintCode() ) {
            print.yellowLine( "Linting issues found" )
        }

        // Create build artifact
        createArtifact()

        print.greenLine( "Build completed successfully!" )
    }

    private function cleanBuild() {
        print.line( "Cleaning build directory..." )

        if ( directoryExists( "build" ) ) {
            directoryDelete( "build", true )
        }

        directoryCreate( "build" )
    }

    private function runTests() {
        print.line( "Running tests..." )

        result = command( "testbox run" )
            .run( returnOutput = true )

        testData = deserializeJSON( result )

        print.line( "Tests: #testData.totalPass# passed, #testData.totalFail# failed" )

        return testData.totalFail == 0
    }

    private function checkCoverage() {
        print.line( "Checking code coverage..." )

        command( "testbox run --coverage" ).run()

        coverageData = deserializeJSON(
            fileRead( expandPath( "/coverage/coverage.json" ) )
        )

        threshold = 80

        print.line( "Coverage: #numberFormat( coverageData.coverage, '0.00' )#%" )

        return coverageData.coverage >= threshold
    }

    private function lintCode() {
        print.line( "Linting code..." )

        try {
            command( "cflint pattern=**/*.cfc --strict" ).run()
            return true
        } catch ( any e ) {
            return false
        }
    }

    private function createArtifact() {
        print.line( "Creating build artifact..." )

        // Copy application files
        directoryCopy(
            expandPath( "/" ),
            expandPath( "/build/app" ),
            true,
            ( path ) => {
                // Exclude patterns
                excludes = [ ".git", "tests", "node_modules", ".env" ]

                for ( exclude in excludes ) {
                    if ( path.findNoCase( exclude ) ) {
                        return false
                    }
                }

                return true
            }
        )

        // Create ZIP
        zip action="zip"
            file=expandPath( "/build/app-#createUUID()#.zip" )
            source=expandPath( "/build/app" )
            overwrite=true

        print.greenLine( "Artifact created in /build/" )
    }
}
```

## Database Setup

### Test Database Configuration

```boxlang
/**
 * SetupTestDB.cfc
 * CommandBox task to setup test database
 */
component {

    function run() {
        print.line( "Setting up test database..." )

        // Create test database
        createTestDatabase()

        // Run migrations
        command( "migrate up" ).run()

        // Seed test data
        command( "migrate seed run TestSeeder" ).run()

        print.greenLine( "Test database ready!" )
    }

    private function createTestDatabase() {
        queryExecute( "
            CREATE DATABASE IF NOT EXISTS test_db
        " )

        queryExecute( "USE test_db" )
    }
}
```

### CI Database Configuration

```yaml
# .github/workflows/tests.yml
services:
  mysql:
    image: mysql:8.0
    env:
      MYSQL_ROOT_PASSWORD: root
      MYSQL_DATABASE: test_db
    ports:
      - 3306:3306
    options: >-
      --health-cmd="mysqladmin ping"
      --health-interval=10s
      --health-timeout=5s
      --health-retries=3

steps:
  - name: Wait for MySQL
    run: |
      until mysqladmin ping -h 127.0.0.1 --silent; do
        echo 'waiting for mysql...'
        sleep 1
      done

  - name: Setup Database
    env:
      DB_HOST: 127.0.0.1
      DB_PORT: 3306
      DB_NAME: test_db
      DB_USER: root
      DB_PASSWORD: root
    run: box task run setupTestDB
```

## Environment Configuration

### Environment Variables

```boxlang
// config/ColdBox.cfc
component {

    function configure() {
        coldbox = {
            appName: "My App"
        }

        // Load from environment
        environments = {
            development: "localhost,127.0.0.1",
            testing: "ci.example.com",
            production: "example.com"
        }

        // CI-specific settings
        if ( getSetting( "environment" ) == "testing" ) {
            settings = {
                dsn: systemSettings.getEnv( "DB_NAME", "test_db" ),
                dbHost: systemSettings.getEnv( "DB_HOST", "localhost" ),
                dbUser: systemSettings.getEnv( "DB_USER", "root" ),
                dbPassword: systemSettings.getEnv( "DB_PASSWORD", "" )
            }
        }
    }
}
```

### Secrets Management

```yaml
# GitHub Secrets
steps:
  - name: Run Tests
    env:
      DB_PASSWORD: ${{ secrets.DB_PASSWORD }}
      API_KEY: ${{ secrets.API_KEY }}
      AWS_ACCESS_KEY: ${{ secrets.AWS_ACCESS_KEY }}
    run: box testbox run
```

## Notifications

### Slack Integration

```yaml
# .github/workflows/tests.yml
jobs:
  test:
    steps:
      # ... test steps ...

      - name: Notify Slack on Success
        if: success()
        uses: slackapi/slack-github-action@v1
        with:
          payload: |
            {
              "text": "✅ Tests passed for ${{ github.repository }}",
              "blocks": [
                {
                  "type": "section",
                  "text": {
                    "type": "mrkdwn",
                    "text": "*Build Success*\nCommit: ${{ github.sha }}\nAuthor: ${{ github.actor }}"
                  }
                }
              ]
            }
        env:
          SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK }}

      - name: Notify Slack on Failure
        if: failure()
        uses: slackapi/slack-github-action@v1
        with:
          payload: |
            {
              "text": "❌ Tests failed for ${{ github.repository }}"
            }
        env:
          SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK }}
```

## Best Practices

### Design Guidelines

1. **Fail Fast**: Run quick tests first
2. **Parallel Execution**: Run independent tests in parallel
3. **Cache Dependencies**: Cache installed packages
4. **Clean Environment**: Start with clean state
5. **Meaningful Feedback**: Provide clear error messages
6. **Matrix Testing**: Test on multiple CF engines/versions
7. **Artifact Storage**: Save build artifacts
8. **Branch Protection**: Require CI to pass before merge
9. **Secrets Management**: Never commit secrets
10. **Performance**: Keep CI pipeline fast (<10 minutes)

### Common Patterns

```yaml
# ✅ Good: Matrix testing
strategy:
  matrix:
    cfengine: [lucee@5.4, adobe@2021, boxlang@1.0.0]

# ✅ Good: Parallel jobs
jobs:
  test:
    # ...
  lint:
    # ...
  coverage:
    # ...

# ✅ Good: Caching
- uses: actions/cache@v3
  with:
    path: ~/.CommandBox
    key: ${{ runner.os }}-commandbox-${{ hashFiles('box.json') }}

# ✅ Good: Environment-specific config
if: github.ref == 'refs/heads/main'
```

## Common Pitfalls

### Pitfalls to Avoid

1. **Slow Builds**: Long-running CI pipelines
2. **Flaky Tests**: Tests that randomly fail
3. **No Caching**: Reinstalling dependencies every time
4. **Missing Cleanup**: Not stopping servers/cleaning up
5. **Secrets in Code**: Hardcoded credentials
6. **No Notifications**: Silent failures
7. **Single Engine**: Only testing one CF engine
8. **No Artifacts**: Losing test results
9. **Manual Steps**: Requiring human intervention
10. **Ignoring Failures**: Allowing builds to pass with warnings

### Anti-Patterns

```yaml
# ❌ Bad: Hardcoded secrets
env:
  API_KEY: "abc123"

# ✅ Good: Use secrets
env:
  API_KEY: ${{ secrets.API_KEY }}

# ❌ Bad: No cleanup
- name: Run Tests
  run: box testbox run

# ✅ Good: Always cleanup
- name: Run Tests
  run: box testbox run

- name: Cleanup
  if: always()
  run: box server stop

# ❌ Bad: Ignoring test failures
- name: Run Tests
  continue-on-error: true
  run: box testbox run

# ✅ Good: Fail on test failure
- name: Run Tests
  run: box testbox run
```

## Related Skills

- [Unit Testing](testing-unit.md) - Unit test patterns
- [Integration Testing](testing-integration.md) - Integration testing
- [Code Coverage](testing-coverage.md) - Coverage analysis
- [Testing Fixtures](testing-fixtures.md) - Test data management

## References

- [GitHub Actions](https://docs.github.com/en/actions)
- [GitLab CI/CD](https://docs.gitlab.com/ee/ci/)
- [Jenkins Pipeline](https://www.jenkins.io/doc/book/pipeline/)
- [CommandBox CI/CD](https://commandbox.ortusbooks.com/usage/continuous-integration)
