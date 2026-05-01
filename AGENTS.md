# ColdBox CLI - AI Coding Instructions

This is a CommandBox module providing CLI commands for ColdBox framework development. It generates scaffolded code for handlers, models, views, tests, ORM entities, and complete applications. It also provides AI integration commands for managing agents, skills, guidelines, and MCP servers. **BoxLang is now the default language** for all new applications and generated code, with full CFML support available via the `--cfml` flag.

## Architecture & Key Components

**Command Structure**: Commands follow CommandBox's hierarchical structure in `/commands/coldbox/` with subcommands in nested folders:

- **Core commands**: `apidocs.cfc`, `docs.cfc`, `help.cfc`, `reinit.cfc`, `watch-reinit.cfc`
- **Create subcommands** (`/commands/coldbox/create/`): `app.cfc`, `app-wizard.cfc`, `handler.cfc`, `model.cfc`, `view.cfc`, `layout.cfc`, `interceptor.cfc`, `service.cfc`, `resource.cfc`, `module.cfc`, `bdd.cfc`, `unit.cfc`, `integration-test.cfc`, `orm-crud.cfc`, `orm-entity.cfc`, `orm-event-handler.cfc`, `orm-service.cfc`, `orm-virtual-service.cfc`
- **AI subcommands** (`/commands/coldbox/ai/`):
  - `agents/` — `active.cfc`, `add.cfc`, `list.cfc`, `open.cfc`, `remove.cfc`
  - `skills/` — `create.cfc`, `find.cfc`, `install.cfc`, `list.cfc`, `override.cfc`, `refresh.cfc`, `remove.cfc`
  - `guidelines/` — `add.cfc`, `create.cfc`, `list.cfc`, `override.cfc`, `refresh.cfc`, `remove.cfc`
  - `mcp/` — `add.cfc`, `install.cfc`, `list.cfc`, `remove.cfc`
  - `doctor.cfc`, `info.cfc`, `refresh.cfc`, `stats.cfc`, `tree.cfc`, `uninstall.cfc`

Each command extends `BaseCommand.cfc` (or `BaseAICommand.cfc` for AI commands) which provides common functionality like BoxLang detection, layout detection, and standardized print methods.

**Model Layer** (`/models/`):
- `BaseCommand.cfc` — Base for all commands: DI properties, `isBoxLangProject()`, `getAppPrefix()`, `getModulesPrefix()`, `resolveServerBaseUrl()`, and print helpers (`printInfo()`, `printError()`, `printWarn()`, `printSuccess()`)
- `BaseAICommand.cfc` — Extends `BaseCommand` for AI commands: `ensureInstalled()`, manifest read/write helpers, MCP JSON generation
- `Utility.cfc` — Shared utilities: template path resolution, `ensureTestBoxModule()`, `ensureMigrationsModule()`, `ensureBoxLangModule()`, module installation checks
- `AIService.cfc` — Central AI operations: install/uninstall AI integration, coordinate guidelines/skills/MCP/agents, manage `.agents/` directory and manifest
- `SkillManager.cfc` — Remote-first skill management: install/refresh skills from `skills.boxlang.io`, SHA-locked downloads, batch operations, orphan pruning
- `GuidelineManager.cfc` — Guideline management for AI coding standards
- `AgentRegistry.cfc` — Agent configuration registry (Claude, Copilot, Codex, Gemini, OpenCode)
- `MCPRegistry.cfc` — MCP server registry and `.mcp.json` generation

**Template System**: Code generation uses text templates in `/templates/` with token replacement (e.g., `|handlerName|`, `|Description|`). Templates are organized by type and language:
- `/templates/modules/cfml/` — CFML module templates
- `/templates/modules/bx/` — BoxLang module templates
- `/templates/crud/cfml/` vs `/templates/crud/bx/` — Language-specific CRUD variants
- `/templates/ai/` — AI integration templates (agents, guidelines, skills)
- `/templates/docker/` — Docker configuration templates (`Dockerfile`, `docker-compose.yml`, `.dockerignore`)
- `/templates/orm/` — ORM templates (`ORMEventHandler.txt`, `TemplatedEntityService.txt`, `VirtualEntityService.txt`)
- `/templates/resources/` — Resource handler templates
- `/templates/rest/` — REST API templates (router, handlers, models, specs, config, apidocs)
- `/templates/testing/` — Test templates (BDD, TestCase, Handler/Interceptor/Model tests)
- `/templates/vite/` — Vite frontend templates (`vite.config.mjs`, `package.json`, `babelrc`, assets, layouts)

**BoxLang Detection**: The `isBoxLangProject()` method in `BaseCommand.cfc` detects BoxLang projects via:
1. Server engine detection (`serverInfo.cfengine` contains "boxlang")
2. Package.json `testbox.runner` setting
3. Package.json `language` property

**Layout Detection**: The `Utility.detectTemplateType()` method distinguishes between:
- **Modern layout** — `app/` and `public/` directories exist; code lives under `app/`
- **Flat layout** — Traditional structure with code at project root

**Language Flags**:
- `--boxlang` — Force BoxLang generation (usually not needed as it's the default)
- `--cfml` — Force CFML generation (overrides BoxLang default)

**Application Creation Features**:
- `coldbox create app` — Quick app creation with skeleton selection
- `coldbox create app-wizard` — Interactive wizard for creating applications
- `--migrations` — Include database migrations support
- `--docker` — Include Docker configuration and containerization
- `--vite` — Include Vite frontend asset building (modern/BoxLang templates)
- `--rest` — Configure as REST API application (BoxLang templates)

**AI Integration Features**:
- `coldbox ai install` — Install AI integration (`.agents/` directory, manifest, guidelines, skills)
- `coldbox ai refresh` — Refresh all AI assets from remote sources
- `coldbox ai uninstall` — Remove AI integration
- `coldbox ai info` / `coldbox ai stats` / `coldbox ai tree` / `coldbox ai doctor` — Diagnostics and status
- `coldbox ai agents` — Manage AI agent configurations (add, list, remove, open, active)
- `coldbox ai skills` — Manage skills (install, find, list, refresh, remove, override, create)
- `coldbox ai guidelines` — Manage coding guidelines (add, list, refresh, remove, override, create)
- `coldbox ai mcp` — Manage MCP servers (install, list, add, remove)

**AI Assets Directory** (`.agents/`):
- `.agents/skills/` — Installed skills from `skills.boxlang.io` and other sources. Each skill is a folder containing a `SKILL.md` file (e.g., `.agents/skills/coldbox-docbox-annotations/SKILL.md`)
- `.agents/guidelines/` — AI coding guidelines and standards
- `.agents/agents/` — Agent-specific configurations (Claude, Copilot, etc.)
- `.agents/manifest.json` — Tracks installed skills, guidelines, agents, and their versions/SHAs

**Module Settings** (from `ModuleConfig.cfc`):
- `templatesPath` — Absolute path to `/templates/`
- `skillsRegistryUrl` — `https://skills.boxlang.io`
- `coldboxSkillsRepo` — `{ owner: "coldbox", repo: "skills" }`
- `boxlangSkillsRepo` — `{ owner: "ortus-boxlang", repo: "skills" }`
- `ortusSkillsRepo` — `{ owner: "ortus-solutions", repo: "skills" }`

**Code Style Conventions**:
- **Semicolons are optional** in CFML/BoxLang and should NOT be used in generated code except:
  - When demarcating property declarations
  - When required in inline component syntax
  - Example: `property name="userService" inject="UserService";` (property with semicolon)
  - Example: `var result = service.getData()` (no semicolon needed)

- **Closure Scoping**: When using closures (arrow functions or anonymous functions), you CANNOT use the `arguments` scope to access outer function parameters
  - ❌ WRONG: `guidelines.filter( ( g ) => g.name != arguments.name )` (will fail - arguments.name is not accessible)
  - ✅ CORRECT: `guidelines.filter( ( g ) => g.name != name )` (remove scope prefix, variable will be found in outer scope)
  - This applies to all scopes inside closures - use unscoped variable names to access outer function variables
  - The closure will automatically search outer scopes for unscoped variables
  - If there is ambiguity with a variable declared internally, then before the closure call you can assign the outer variable to a new variable with a different name and use that inside the closure

**Markdown File Standards**:
- **Always lint markdown files after editing** - Run `npx markdownlint-cli -f {filename}` after any markdown file modifications
- Markdown linting configuration is in `.markdownlint.json`
- Fix any linting errors before committing changes

## Development Workflows

**Command Development**:
- New commands extend `BaseCommand.cfc` and use dependency injection (`property name="utility" inject="utility@coldbox-cli"`)
- AI commands extend `BaseAICommand.cfc` which adds AI-specific helpers
- Use standardized print methods: `printInfo()`, `printError()`, `printWarn()`, `printSuccess()`
- Commands support `--force` for overwriting and `--open` for opening generated files

**CLI User Interface Guidelines**:

Creating beautiful CLI interfaces enhances user experience. CommandBox provides rich output formatting capabilities:

- **Print Helpers** - Color text, indentation, lines, boxes: <https://commandbox.ortusbooks.com/task-runners/task-output>
- **Tables** - Display data in formatted tables: <https://commandbox.ortusbooks.com/task-runners/task-output/printing-tables>
- **Columns** - Multi-column output layouts: <https://commandbox.ortusbooks.com/task-runners/task-output/printing-columns>
- **Trees** - Hierarchical tree structures: <https://commandbox.ortusbooks.com/task-runners/task-output/printing-tree>
- **Progress Bars** - Visual progress indicators: <https://commandbox.ortusbooks.com/task-runners/progress-bar>
- **Interactive Jobs** - User prompts, confirmations, selections: <https://commandbox.ortusbooks.com/task-runners/interactive-jobs>

Use these tools to create polished, professional command interfaces that improve usability and provide clear visual feedback.

**Template Management**:
- Templates use token replacement with `replaceNoCase(content, "|token|", value, "all")`
- BoxLang conversion uses `toBoxLangClass()` to transform `component` to `class`
- Resource generation supports both REST and standard handlers via template selection
- Modern templates (`boxlang`, `modern`) support additional features via flags: `--vite`, `--rest`, `--docker`, `--migrations`
- Default skeleton is now `boxlang` instead of `advanced`

**Module Dependencies**: The module declares dependencies in `box.json`:
- `testbox-cli` — TestBox CLI integration
- `commandbox-migrations` — Database migration support
- `commandbox-boxlang` — BoxLang language support
- Dev dependencies: `commandbox-cfformat`, `commandbox-docbox`

The module lazy-loads `testbox-cli` and `commandbox-migrations` via utility methods `ensureTestBoxModule()` and `ensureMigrationsModule()` only when needed.

## Key Patterns & Conventions

**File Generation Logic**: Commands typically:
1. Resolve and validate paths using `resolvePath()`
2. Detect layout type (modern vs flat) via `Utility.detectTemplateType()`
3. Read appropriate templates based on `--rest`, `--boxlang`, `--cfml` flags
4. Perform token replacements for customization
5. Create directories if they don't exist
6. Generate additional files (views, tests) based on flags
7. For app creation: apply feature flags (`--vite`, `--docker`, `--migrations`) to configure project

**Cross-Component Integration**:
- Models can generate handlers via `--handler` flag
- Handlers can generate views via `--views` flag
- Resource commands generate full CRUD scaffolding
- Migration and seeder generation integrated with model creation
- ORM commands generate entities, services, virtual services, event handlers, and full CRUD

**Error Handling**: Use `BaseCommand` print methods for consistent user feedback and check file existence before operations when `--force` is not specified.

## Testing & Build

**Build Scripts** (from `box.json`):
- `box build:module` — Full module build via `/build/Build.cfc`
- `box build:docs` — Generate documentation via DocBox
- `box format` — Run CFFormat on commands, models, build, and ModuleConfig.cfc
- `box format:watch` — Watch and auto-format on file changes
- `box format:check` — Check formatting without modifying files
- `box release` — Run release recipe (`build/release.boxr`)

**Template Testing**: The `/tests/` directory contains sample module structure for testing generated code patterns. The `/testapp/` directory contains a full test application with modern layout. handlers via template selection
- Modern templates (`boxlang`, `modern`) support additional features via flags: `--vite`, `--rest`, `--docker`, `--migrations`
- Default skeleton is now `boxlang` instead of `advanced`

**Module Dependencies**: The module lazy-loads `testbox-cli` and `commandbox-migrations` via utility methods `ensureTestBoxModule()` and `ensureMigrationsModule()` only when needed.

## Key Patterns & Conventions

**File Generation Logic**: Commands typically:
1. Resolve and validate paths using `resolvePath()`
2. Read appropriate templates based on `--rest`, `--boxlang`, `--cfml` flags
3. Perform token replacements for customization
4. Create directories if they don't exist
5. Generate additional files (views, tests) based on flags
6. For app creation: apply feature flags (`--vite`, `--docker`, `--migrations`) to configure project

**Cross-Component Integration**:
- Models can generate handlers via `--handler` flag
- Handlers can generate views via `--views` flag
- Resource commands generate full CRUD scaffolding
- Migration and seeder generation integrated with model creation

**Error Handling**: Use `BaseCommand` print methods for consistent user feedback and check file existence before operations when `--force` is not specified.

## Testing & Build

**Build Process**: Uses `/build/Build.cfc` task runner with `box scripts` integration. Run `box build:module` for full build or `box format` for code formatting.

**Template Testing**: The `/tests/` directory contains sample module structure for testing generated code patterns.
