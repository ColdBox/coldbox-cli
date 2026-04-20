<!-- COLDBOX-CLI:START -->
<!-- ⚡ This section is managed by ColdBox CLI and will be refreshed on `coldbox ai refresh`. -->
<!-- ⚠️  Do NOT edit content between COLDBOX-CLI:START and COLDBOX-CLI:END markers — changes will be overwritten. -->

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

Core ColdBox and |LANGUAGE_MODE| guidelines are installed in `.ai/guidelines/core/`. Supported tools
(e.g., VS Code Copilot) load them automatically via file attachments. For other agents, load them
explicitly when you need framework fundamentals:

- `read_file` on `.ai/guidelines/core/coldbox.md` — ColdBox conventions, handlers, routing, DI reference
- `read_file` on `.ai/guidelines/core/boxlang.md` — BoxLang syntax and patterns (or `cfml.md` for CFML projects)

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

## AI Integration

This project includes AI-powered development assistance with guidelines, skills, and MCP documentation servers.

### Directory Structure

```
/.ai/
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

**To load a skill:** Request it by name when implementing specific features or patterns.

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

<!-- COLDBOX-CLI:END -->

<!-- ℹ️ YOUR PROJECT DOCUMENTATION — Add your custom details below. ColdBox CLI will NOT overwrite this section. -->
<!-- 📝 TODO: Describe your business domain, key services, auth approach, and project-specific conventions. -->
<!-- Suggested sections: Business Domain, Key Services/Models, Authentication/Security, API Endpoints, Database, Deployment -->
