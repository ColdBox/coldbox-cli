# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

* * *

## [Unreleased]

## [8.4.0] - 2025-12-15

### Added

- New ColdBox ASCII art banner when creating apps and using the app-wizard
- Improved readme and help commands
- Name question in app-wizard if not provided
- Install `bx-compat-cfml` when doing `--rest` due to needing some CFML compatibility

#### AI Integration - Complete System

**Complete AI-powered development assistant** for ColdBox with 41 guidelines, 62 skills, 30+ MCP documentation servers, and support for 6 AI agents (Claude, Copilot, Cursor, Codex, Gemini, OpenCode).

##### Core Commands

- `coldbox ai install` - Set up AI integration with agent selection and language detection
- `coldbox ai refresh` - Sync guidelines, skills, and MCP servers with installed modules
- `coldbox ai info` - Display current AI configuration
- `coldbox ai doctor` - Diagnose AI integration health with detailed reporting

##### Guidelines System (41 Total)

- **Core Guidelines (10)**: boxlang, cfml, coldbox, coldbox-cli, cachebox, wirebox, logbox, testbox, testbox-cli, docbox
- **Security & Auth (6)**: cbsecurity, cbauth, cbsecurity-passkeys, cbsso, cbcsrf, cbantisamy
- **Validation & Data (6)**: cbvalidation, cbi18n, cbmailservices, cbmessagebox, cbpaginator, cbfeeds
- **ORM & Database (4)**: cborm, qb, quick, cfmigrations
- **API & Integration (5)**: hyper, cbproxies, cbswagger, cbelasticsearch, s3sdk
- **Utility & Development (8)**: cbdebugger, cbfs, cbstorages, stachebox, cbjavaloader, cbmarkdown, cbmockdata, docbox
- **Modern Development (6)**: cbwire, cbq, socketbox, mementifier, unleashsdk, cbplaywright
- **Additional (7)**: bcrypt, cors, rulebox, commandbox-migrations, commandbox-boxlang, route-visualizer, relax
- Guidelines commands: `list`, `add`, `remove`, `create`, `override`, `refresh`, `help`

##### Skills System (62 Total)

- **BoxLang Development (21)**: syntax, classes, functions, lambdas, modules, streams, types, interop, scheduled-tasks, futures, http-client, soap-client, executors, jdbc, templating, caching, file-handling, properties, zip, interceptors, sse, components, application
- **ColdBox Development (12)**: handler-development, rest-api-development, module-development, interceptor-development, layout-development, routing-development, event-model, view-rendering, cache-integration, coldbox-configuration, coldbox-request-context, coldbox-flash-messaging
- **Testing (8)**: testing-bdd, testing-unit, testing-integration, testing-handler, testing-mocking, testing-fixtures, testing-coverage, testing-ci
- **Internal Libraries (3)**: cachebox-caching-patterns, logbox-logging-patterns, wirebox-di-patterns
- **Security (9)**: security-implementation, authentication, authorization, sso-integration, jwt-development, passkeys-integration, csrf-protection, api-authentication, rbac-patterns
- **ORM & Database (5)**: cborm, qb (query-builder), orm-quick, boxlang-queries, database-migrations
- **Modern Development (1)**: cbwire-development
- Skills commands: `list`, `create`, `override`, `refresh`, `remove`, `help`

##### MCP Server Integration (30+ Servers)

- **Core Servers (7)**: boxlang, coldbox, commandbox, testbox, wirebox, cachebox, logbox - always included
- **Module Servers (23)**: bxorm, cborm, qb, quick, cfmigrations, cbsecurity, cbauth, cbsso, cbvalidation, cbi18n, cbmailservices, cbdebugger, cbelasticsearch, cbfs, cfconfig, cbwire, cbq, megaphone, contentbox, docbox, relax (cbswagger), modern-cfml, boxlang-ide
- Auto-detection from box.json dependencies with zero configuration
- Custom MCP server support for company/internal documentation
- MCP commands: `list`, `add`, `remove`, `help`

##### Multi-Agent Support (6 Agents)

- **Supported Agents**: Claude (`CLAUDE.md`), GitHub Copilot (`.github/copilot-instructions.md`), Cursor (`.cursorrules`), Codex (`AGENTS.md`), Gemini (`GEMINI.md`), OpenCode (`AGENTS.md`)
- Layout-specific templates (modern, flat)
- Project context detection (Vite, Docker, ORM, Migrations)
- Agents commands: `list`, `add`, `remove`, `active`, `open`

##### Override System

- **Guidelines Override**: `coldbox ai guidelines override <name>` - Customize any guideline with project-specific conventions
- **Skills Override**: `coldbox ai skills override <name>` - Override core/module skills with project-specific patterns
- Override files stored in `.ai/guidelines/overrides/` and `.ai/skills/overrides/`
- List commands show overrides separately with 🎯 icon
- Remove commands support `--override` flag for targeted removal
- Template-based override creation (copies original + adds override header)
- Priority system: override > core/module

##### Module Integration

- Zero-config auto-discovery from box.json dependencies
- Module creation with `--ai` flag creates `.ai/guidelines` and `.ai/skills` directories
- Three-tier guideline fallback: module-shipped → bundled templates → auto-generated
- Auto-registers MCP servers for installed modules
- Path consistency: always uses `.ai/` convention (not `resources/`)

##### Language Support

- BoxLang and CFML project detection
- Hybrid project support
- Language-specific skill variants
- Code generation respects project language choice

## [8.4.0] - 2025-12-15

### Added

- Make sure `commandbox-boxlang` is a dependency to detect BoxLang projects

### Fixed

- Creation of `bx` classes when `--boxlang` is used was missing from handler creation
- App generation install tweaks to avoid path issues by @gpickin
- Fix on copying files starting with a dot, like `.babelrc` for vite support, which is ignored by default by git ignores.

## [8.3.0] - 2025-12-08

### Added

- More Modern CFML template support

## [8.2.0] - 2025-11-11

### Added

- Missing rest resources for the `boxlang` template

### Fixed

- Cleanup for vite resources only if vite is not selected

## [8.1.0] - 2025-10-22

### Changed

- `docker` argument to create app was supposed to be `false` by default, not `true`

### Fixed

- Docker ignore issues
- App env sample ignore issues

## [8.0.0] - 2025-10-13

## [7.10.0] - 2025-10-10

### Added

- Forgot to bump it to match ColdBox version.

## [7.10.0] - 2025-10-10

### Added

- Modules Inherit Entry Point defaults to `true` now
- Brand new app-wizard for creating apps interactively
- fix colors for ps screens
- BoxLang is now the default engine for new apps
- Updated all new templates from repos
- New create app argument for modern or boxlang skeletons: `vite` to create a Vite enabled app: `coldbox create app name="myApp" --vite`
- New create app argument for modern or boxlang skeletons: `rest` to create a REST enabled app: `coldbox create app name="myApp" --rest`
- - New create app argument for modern or boxlang skeletons: `docker` to create a Docker enabled app: `coldbox create app name="myApp" --docker`
- New create app argument for modern or boxlang skeletons: `migrations` to create a Migrations enabled app: `coldbox create app name="myApp" --migrations`
- New `--cfml` argument to create a CFML app: `coldbox create app name="myApp" --cfml` instead of BoxLang (app is default)
- BoxLang template skeleton rename
- Updated docs for BoxLang detection

## [7.8.0] - 2025-09-29

### Added

- Copilot instructions for AI coding assistance
- If the skeleton is `default` and this is a BoxLang project, it will switch the skeleton to `BoxLang`.
- added dependabot
- Moved `testbox-cli` and `commandbox-migrations` to dependencies so we can use them in the CLI commands

## [7.7.0] - 2025-04-29

### Fixed

- More fixes for `boxlang` arguments

## [7.6.0] - 2025-04-28

### Added

- New `modern` template for creating modern apps with the latest features
- New `boxlang` template for creating apps with the latest boxlang features
- Modernization of all templates to use the latest features of ColdBox
- New `--boxlang` argument to create content for BoxLang
- New `language` argument detection for BoxLang

### Changed

- Updated to the latest Ubuntu images for the GitHub actions

### Fixed

- Fixed resource handler creation.

## [7.5.0] - 2024-10-16

### Fixed

- watch reinit issues with `coldbox watch` command
- key [TEMPLATEPATH] doesn't exist when doing orm operations. This was a typo, it should have been `templatesPath`

## [7.4.0] - 2024-03-20

### Fixed

- Create resources missing `open` param

### Added

- More documentation

## [7.3.0] - 2024-02-12

### Added

- New github actions
- Lazy load `testbox-cli, commandbox-migrations` only when used.

## [7.2.1] - 2023-05-19

### Fixed

- Fixed `coldbox create layout` failing due to unescpaed `#view()#` command

## [7.2.0] - 2023-05-18

### Added

- New version of CommandBox Migrations
- Added `testbox-cli` as a dependency

## [7.1.0] - 2023-05-18

### Added

- `BaseCommand` hierarchy for all commands to inherit from
- New print functions for uniformity of info, warning, success and error messages
- New `coldbox create service` command to create services easily
- Create model with migration now actually generates the property migrations
- Create `coldbox create model --service` to create a model with a service
- Create `coldbox create model --all` to create a model with a service and all the things

### Fixed

- Version should match major ColdBox version, moved to `7`
- Fixed `coldbox create app` command to finalize the create app job
- Set default location to `forgeboxStorage` for new apps, this was missing
- `coldbox create handler` was not creating the `views`
- Models `isLoaded()` was actually wrong
- Handler test specs carriage returns
- When creating models with rest or resources, the handler was not being created

## [1.0.0] - 2023-05-03

### Added

- Migration from CommandBox core to a separate module
- Updated all templates to ColdBox 7
- Updated all `resources` to ColdBox 7 standard code
- Add `--force` command to several commands for overwriting files
- Create app new argument: `migrations` to init the migrations on the project: `coldbox create app name="myApp" --migrations`
- `create view` command now has an `open` attribute to open the created views in the editor
- You can create layouts with content now: `create layout name="myLayout" content="my content"`
- You can create views with content now: `create view name="myView" content="my content"`
- You can create resourceful handlers: `create handler name="myHandler" --resource`
- You can create resourceful rest handlers: `create handler name="myHandler" --resource --rest`
- You can create models with migrations now: `create model name="myModel" --migration`
- You can create models with seeders now: `create model name="myModel" --seeder`
- You can create models with handlers (normal or rest) now: `create model name="myModel" --handler` or `create model name="myModel" --handler --rest`
- You can create models with a resource handler now: `create model name="myModel" --resource`
- You can create models will all the things now: `create model name="myModel" --all`
- New `coldbox docs` command to open the ColdBox docs in your browser and search as well: `coldbox docs search="event handlers"`
- New `coldbox apidocs` command to open the ColdBox API Docs in your browser.

### Fixed

- Was resetting the `scripts` in the templates, which is not needed

### Removed

- Eclipse support

[unreleased]: https://github.com/ColdBox/coldbox-cli/compare/v8.4.0...HEAD
[8.4.0]: https://github.com/ColdBox/coldbox-cli/compare/v8.3.0...v8.4.0
[8.3.0]: https://github.com/ColdBox/coldbox-cli/compare/v8.2.0...v8.3.0
[8.2.0]: https://github.com/ColdBox/coldbox-cli/compare/v8.1.0...v8.2.0
[8.1.0]: https://github.com/ColdBox/coldbox-cli/compare/v8.0.0...v8.1.0
[8.0.0]: https://github.com/ColdBox/coldbox-cli/compare/v7.10.0...v8.0.0
[7.10.0]: https://github.com/ColdBox/coldbox-cli/compare/v7.8.0...v7.10.0
[7.8.0]: https://github.com/ColdBox/coldbox-cli/compare/v7.8.0...v7.8.0
[7.7.0]: https://github.com/ColdBox/coldbox-cli/compare/v7.6.0...v7.7.0
[7.6.0]: https://github.com/ColdBox/coldbox-cli/compare/v7.5.0...v7.6.0
[7.5.0]: https://github.com/ColdBox/coldbox-cli/compare/v7.4.0...v7.5.0
[7.4.0]: https://github.com/ColdBox/coldbox-cli/compare/v7.3.0...v7.4.0
[7.3.0]: https://github.com/ColdBox/coldbox-cli/compare/v7.2.1...v7.3.0
[7.2.1]: https://github.com/ColdBox/coldbox-cli/compare/v7.2.0...v7.2.1
[7.2.0]: https://github.com/ColdBox/coldbox-cli/compare/v7.1.0...v7.2.0
[7.1.0]: https://github.com/ColdBox/coldbox-cli/compare/v1.0.0...v7.1.0
[1.0.0]: https://github.com/ColdBox/coldbox-cli/compare/94e639a1ba9d10c8d9ad663435233bd115cf8586...v1.0.0
