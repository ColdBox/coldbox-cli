# |PROJECT_NAME| - AI Agent Instructions

This is a ColdBox HMVC application using the **flat template structure** where all application code lives in the webroot. Compatible with Adobe ColdFusion 2018+, Lucee 5.x+, and BoxLang 1.0+.

## Project Overview

**Language Mode:** |LANGUAGE_MODE|
**ColdBox Version:** |COLDBOX_VERSION|
**Template Type:** Flat (traditional webroot structure)

## Application Structure

```
/                      - Application root (webroot)
├── Application.cfc    - Bootstrap that directly loads ColdBox
├── index.cfm          - Front controller
├── config/            - Framework and app configuration
├── handlers/          - Event handlers (controllers)
├── models/            - Service objects, business logic
├── views/             - HTML templates
├── layouts/           - Page layouts wrapping views
├── includes/          - Public assets (CSS, JS, images)
├── modules_app/       - Application modules (HMVC)
├── tests/             - Test suites
└── lib/               - Framework dependencies
```

**Key Characteristics:**
- Everything in webroot (simpler for traditional hosting)
- No `/app` vs `/public` separation
- All code is web-accessible by default
- `COLDBOX_APP_MAPPING = ""` (empty, app at root)

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
- Framework config in `config/ColdBox.cfc`
- Routes in `config/Router.cfc`

### Application Helpers

- `includes/helpers/ApplicationHelper.cfm` - Available in all handlers/views
- Add common utility functions here

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

# Reinit framework (dev)
/?fwreinit=true
```

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

### Deployment

<!-- Document deployment process -->

### Third-Party Integrations

<!-- List external services, APIs, or integrations -->

## Important Notes

- Framework reinit: Use `?fwreinit=true` or configure `reinitPassword` for production
- Module routes process before app routes - be aware of conflicts
- Use PRC for internal data, RC only for user input
- Always validate user input from RC

## MCP Documentation Servers

This project has access to the following Model Context Protocol (MCP) documentation servers for live, up-to-date information:

|MCP_SERVERS|

## Additional Resources

- ColdBox Docs: https://coldbox.ortusbooks.com
- TestBox: https://testbox.ortusbooks.com
- WireBox: https://wirebox.ortusbooks.com
