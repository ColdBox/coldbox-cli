<!-- COLDBOX-CLI:START -->
<!-- ⚡ This section is managed by ColdBox CLI and will be refreshed on `coldbox ai refresh`. -->
<!-- ⚠️  Do NOT edit content between COLDBOX-CLI:START and COLDBOX-CLI:END markers — changes will be overwritten. -->

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

Core ColdBox and language guidelines are installed in `.ai/guidelines/core/`. Supported tools
(e.g., VS Code Copilot) load them automatically via file attachments. For other agents, load them
explicitly when you need framework fundamentals:

- `read_file` on `.ai/guidelines/core/coldbox.md` — ColdBox conventions, handlers, routing, DI reference
- `read_file` on |LANGUAGE_GUIDELINE_FILE| — |LANGUAGE_GUIDELINE_DESC|

## Installed Modules

The following ColdBox modules are installed in this project. Use these when generating code, checking available services, and suggesting relevant skills or guidelines:

|INSTALLED_MODULES|

## Handlers Snapshot

Current event handlers and their public actions (auto-updated on `coldbox ai refresh`):

|HANDLERS_SNAPSHOT|

## Interceptors Snapshot

Registered interceptors and their interception points (auto-updated on `coldbox ai refresh`):

|INTERCEPTORS_SNAPSHOT|

## Layouts

Available layouts (auto-updated on `coldbox ai refresh`):

|LAYOUTS_SNAPSHOT|

## Custom Modules

Application-level modules located in `/app/modules` (auto-updated on `coldbox ai refresh`):

|CUSTOM_MODULES_SNAPSHOT|

## AI Integration & Resources

This project includes AI-powered development assistance with on-demand guidelines, skills, and MCP documentation servers.

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

## AI Integration

This project includes AI-powered development assistance with guidelines, skills, and MCP documentation servers.

### Directory Structure

```
/.agents/
  /manifest.json       - AI configuration (language, agents, guidelines, skills, MCP servers)
  /guidelines/         - Framework documentation and best practices
    /core/             - Core ColdBox/BoxLang guidelines
    /modules/          - Module-specific guidelines
    /custom/           - Your custom guidelines
    /overrides/        - Override core guidelines
  /skills/             - Implementation cookbooks (how-to guides)
    /{name}/           - One folder per skill (flat, no subdirectories)
      SKILL.md         - Skill content (fetched from registry or created locally)
  /mcp-servers/        - MCP server configurations
```

### Manifest

The `.ai/manifest.json` file contains the complete AI integration configuration:

- **language**: Project language mode (boxlang, cfml, hybrid)
- **templateType**: Application template (modern, flat)
- **guidelines**: Array of installed guideline names
- **skills**: Array of installed skill names
- **agents**: Array of configured AI agents
- **mcpServers**: Configured MCP documentation servers (core, module, custom)
- **activeAgent**: Currently active AI agent (if set)
- **lastSync**: Last synchronization timestamp

**Reading the manifest** helps you understand available resources and project configuration.

### Using Guidelines & Skills

Guidelines and skills are stored locally in `.ai/` and loaded via `read_file` when needed:

**Core Guidelines** (`.ai/guidelines/core/`) — framework fundamentals:
- `read_file` on `.ai/guidelines/core/coldbox.md` — ColdBox conventions, handler/routing/DI reference
- `read_file` on `.ai/guidelines/core/boxlang.md` — BoxLang syntax, classes, lambdas (or `cfml.md` for CFML)

**Module/Custom Guidelines** — load by name on request from `.ai/guidelines/modules/` or `.ai/guidelines/custom/`.

**Skills** (`.ai/skills/{name}/SKILL.md`) — step-by-step implementation patterns. Examples:
- Implement a CRUD handler: `read_file` on `.ai/skills/coldbox-handler-development/SKILL.md`
- Build a REST API: `read_file` on `.ai/skills/coldbox-rest-api-development/SKILL.md`
- Write tests: `read_file` on `.ai/skills/coldbox-testing-handler/SKILL.md`

**To load any skill or guideline:** use `read_file` on the path shown above or in the inventories below.

### Available Guidelines

The following additional guidelines are available for this project. Request them by name when needed:

|GUIDELINES_INVENTORY|

**To load a guideline:** Request it by name when you need detailed framework or module documentation.

### Available Skills

The following skills provide step-by-step implementation patterns. Request specific skills when you need detailed how-to instructions:

|SKILLS_INVENTORY|

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

<!-- COLDBOX-CLI:END -->

<!-- ℹ️ YOUR PROJECT DOCUMENTATION — Add your custom details below. ColdBox CLI will NOT overwrite this section. -->

## About This Application

> ⚠️ Fill in this section to give your AI assistant context about your specific application.

### Business Domain

<!-- Describe what this application does and its primary purpose -->

### Key Services & Models

<!-- List important services and their responsibilities, e.g.:
- UserService — authentication, registration, profile management
- OrderService — cart, checkout, order lifecycle
-->

### Authentication & Security

<!-- Describe authentication approach, e.g., cbSecurity + JWT, session-based, etc. -->

### API Endpoints

<!-- Document REST API routes if applicable, e.g.:
- GET /api/v1/users — list users
- POST /api/v1/users — create user
-->

### Database

<!-- Document database setup, ORM entities, migrations if applicable -->

### Deployment

<!-- Document deployment process, environments, CI/CD pipeline -->
