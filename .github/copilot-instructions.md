# ColdBox CLI - AI Coding Instructions

This is a CommandBox module providing CLI commands for ColdBox framework development. It generates scaffolded code for handlers, models, views, tests, and complete applications with support for both CFML and BoxLang.

## Architecture & Key Components

**Command Structure**: Commands follow CommandBox's hierarchical structure in `/commands/coldbox/` with subcommands in nested folders (e.g., `create/handler.cfc`, `create/model.cfc`). Each command extends `BaseCommand.cfc` which provides common functionality like BoxLang detection and standardized print methods.

**Template System**: Code generation uses text templates in `/templates/` with token replacement (e.g., `|handlerName|`, `|Description|`). Templates are organized by type and language:
- `/templates/modules/cfml/` - CFML templates
- `/templates/modules/bx/` - BoxLang templates
- `/templates/crud/cfml/` vs `/templates/crud/bx/` - Language-specific variants

**BoxLang Detection**: The `isBoxLangProject()` method in `BaseCommand.cfc` detects BoxLang projects via:
1. Server engine detection (`serverInfo.cfengine` contains "boxlang")
2. Package.json `testbox.runner` setting
3. Package.json `language` property

## Development Workflows

**Command Development**:
- New commands extend `BaseCommand.cfc` and use dependency injection (`property name="utility" inject="utility@coldbox-cli"`)
- Use standardized print methods: `printInfo()`, `printError()`, `printWarn()`, `printSuccess()`
- Commands support `--force` for overwriting and `--open` for opening generated files

**Template Management**:
- Templates use token replacement with `replaceNoCase(content, "|token|", value, "all")`
- BoxLang conversion uses `toBoxLangClass()` to transform `component` to `class`
- Resource generation supports both REST and standard handlers via template selection

**Module Dependencies**: The module lazy-loads `testbox-cli` and `commandbox-migrations` via utility methods `ensureTestBoxModule()` and `ensureMigrationsModule()` only when needed.

## Key Patterns & Conventions

**File Generation Logic**: Commands typically:
1. Resolve and validate paths using `resolvePath()`
2. Read appropriate templates based on `--rest`, `--boxlang` flags
3. Perform token replacements for customization
4. Create directories if they don't exist
5. Generate additional files (views, tests) based on flags

**Cross-Component Integration**:
- Models can generate handlers via `--handler` flag
- Handlers can generate views via `--views` flag
- Resource commands generate full CRUD scaffolding
- Migration and seeder generation integrated with model creation

**Error Handling**: Use `BaseCommand` print methods for consistent user feedback and check file existence before operations when `--force` is not specified.

## Testing & Build

**Build Process**: Uses `/build/Build.cfc` task runner with `box scripts` integration. Run `box build:module` for full build or `box format` for code formatting.

**Template Testing**: The `/tests/` directory contains sample module structure for testing generated code patterns.
