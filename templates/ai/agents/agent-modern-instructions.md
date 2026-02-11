# |PROJECT_NAME| - AI Agent Instructions

This is a ColdBox HMVC application using the **modern template structure** with application code separated from the public webroot. Compatible with Adobe ColdFusion 2018+, Lucee 5.x+, and BoxLang 1.0+.

## Project Overview

**Language Mode:** |LANGUAGE_MODE|
**ColdBox Version:** |COLDBOX_VERSION|
**Template Type:** Modern (app/public separation)
**Features:** |FEATURES|

## Application Structure

```
/app/              - Application code (handlers, models, views, config)
/public/           - Public webroot (index.cfm, static assets)
  /Application.cfc - Entry point that maps to /app
/lib/              - Framework and dependency storage
  /coldbox/        - ColdBox framework files
  /testbox/        - TestBox testing framework
  /java/           - Java JAR dependencies (if using Maven)
  /modules/        - CommandBox-installed modules
/tests/            - Test suites
/resources/        - Non-web resources (migrations, apidocs, etc.)
```

**Key Characteristics:**
- Application code in `/app` (not web-accessible)
- Public-facing files in `/public` only
- Enhanced security through separation
- Requires CommandBox aliases or web server configuration

### Application Bootstrap

1. Request → `/public/index.cfm`
2. `/public/Application.cfc` sets mappings:
   - `COLDBOX_APP_ROOT_PATH = this.mappings["/app"]`
   - `COLDBOX_APP_MAPPING = "/app"`
3. Config in `/app/config/ColdBox.cfc`
4. Routes in `/app/config/Router.cfc`
5. Handlers in `/app/handlers/`

**Security Note:** `/app/Application.cfc` contains only `abort;` to prevent direct web access.

## CommandBox Aliases

**Critical:** This template requires aliases in `server.json`:

```json
"web": {
    "webroot": "public",
    "aliases": {
        "/coldbox/system/exceptions": "./lib/coldbox/system/exceptions/",
        "/tests": "./tests/"
    }
}
```

**When adding UI modules** (cbdebugger, cbswagger), add corresponding aliases.

## Framework Knowledge

**Important:** For ColdBox framework documentation, refer to the **ColdBox guideline** which covers:
- Event handlers and routing
- Request context (event object)
- Dependency injection (WireBox)
- Interceptors (AOP)
- Modules
- Configuration patterns

Additional framework guidelines are available for TestBox, WireBox, CacheBox, and LogBox.

## Project-Specific Conventions

### Code Style

- **Semicolons:** Optional in CFML/BoxLang. Only use when demarcating properties or in inline component syntax
- **Handler naming:** Plural nouns (Users.cfc, Orders.cfc)
- **Service naming:** Descriptive with "Service" suffix (UserService.cfc)
- **Dependency injection:** Use `property name="service" inject` over manual getInstance()

### Testing

- Tests located in `/tests/specs/`
- Integration tests extend `BaseTestCase` with `appMapping="/app"`
- **Critical:** Always call `setup()` in `beforeEach()` for test isolation
- Run tests: `box testbox run`

### Configuration

- Environment variables defined in `.env` (copy from `.env.example`)
- Access via `getSystemSetting("VAR_NAME", "default")`
- Framework config in `/app/config/ColdBox.cfc`
- Routes in `/app/config/Router.cfc`

### Development Workflow

```bash
# Install dependencies
box install

# Start server
box server start

# Format code
box run-script format

# Run tests
box testbox run

# Vite (if enabled)
npm install
npm run dev          # Development with HMR
npm run build        # Production build

# Docker (if enabled)
docker-compose up -d
docker-compose logs -f
```

## Optional Features

<!-- Mark which features are enabled in this project -->

- **Vite:** |VITE_ENABLED| - Modern frontend asset building with hot module replacement
- **Docker:** |DOCKER_ENABLED| - Containerized development and deployment
- **ORM:** |ORM_ENABLED| - Object-Relational Mapping via CBORM or Quick
- **Migrations:** |MIGRATIONS_ENABLED| - Database version control with CommandBox Migrations

## Custom Application Details

<!-- Add project-specific information below -->

### Business Domain

<!-- Describe what this application does -->

### Key Services/Models

<!-- List important services and their responsibilities -->

### Authentication/Security

<!-- Describe authentication approach if applicable -->

### API Endpoints

<!-- Document REST API routes if applicable -->

### Database

<!-- Document database setup, migrations, seeders if applicable -->

### Deployment

<!-- Document deployment process -->

### Third-Party Integrations

<!-- List external services, APIs, or integrations -->

## MCP Documentation Servers

This project has access to the following Model Context Protocol (MCP) documentation servers for live, up-to-date information:

|MCP_SERVERS|

## Important Notes

- **File Paths:** Application code uses `/app` paths, public files in `/public`
- **Aliases Required:** Module UI assets need CommandBox aliases in server.json
- **Test AppMapping:** Must be `appMapping="/app"` to match production paths
- Use PRC for internal data, RC only for user input
- Always validate user input from RC
- Framework reinit: Use `?fwreinit=true` or configure `reinitPassword`

## Additional Resources

- ColdBox Docs: https://coldbox.ortusbooks.com
- TestBox: https://testbox.ortusbooks.com
- WireBox: https://wirebox.ortusbooks.com
