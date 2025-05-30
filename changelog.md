# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

* * *

## [Unreleased]

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

[Unreleased]: https://github.com/ColdBox/coldbox-cli/compare/v7.7.0...HEAD

[7.7.0]: https://github.com/ColdBox/coldbox-cli/compare/v7.6.0...v7.7.0

[7.6.0]: https://github.com/ColdBox/coldbox-cli/compare/v7.5.0...v7.6.0

[7.5.0]: https://github.com/ColdBox/coldbox-cli/compare/v7.4.0...v7.5.0

[7.4.0]: https://github.com/ColdBox/coldbox-cli/compare/v7.3.0...v7.4.0

[7.3.0]: https://github.com/ColdBox/coldbox-cli/compare/v7.2.1...v7.3.0

[7.2.1]: https://github.com/ColdBox/coldbox-cli/compare/v7.2.0...v7.2.1

[7.2.0]: https://github.com/ColdBox/coldbox-cli/compare/v7.1.0...v7.2.0

[7.1.0]: https://github.com/ColdBox/coldbox-cli/compare/v1.0.0...v7.1.0

[1.0.0]: https://github.com/ColdBox/coldbox-cli/compare/94e639a1ba9d10c8d9ad663435233bd115cf8586...v1.0.0
