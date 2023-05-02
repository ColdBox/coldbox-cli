# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

----

## [Unreleased]

### Added

- Migration from CommandBox core to a separate module
- `create view` command now has an `open` attribute to open the created views in the editor
- Updated all templates to ColdBox 7
- Updated all `resources` to ColdBox 7 standard code
- Create app new argument: `migrations` to init the migrations on the project

### Fixed

- Was resetting the `scripts` in the templates, which is not needed

### Removed

- Eclipse support
