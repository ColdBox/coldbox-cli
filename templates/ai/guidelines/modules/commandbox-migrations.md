---
title: CommandBox Migrations Module Guidelines
description: Database migration tool for schema versioning, changes tracking, and environment synchronization
---

# CommandBox Migrations Module Guidelines

## Overview

CommandBox Migrations provides CLI commands for running cfmigrations from the command line. It extends cfmigrations functionality with easy-to-use CommandBox commands.

## Installation

```bash
box install commandbox-migrations
```

## Configuration

Create `.cfmigrations.json` in project root:

```bash
migrate init
```

See **cfmigrations** module guidelines for full configuration details.

## Commands

### Initialize

```bash
# Create .cfmigrations.json config file
migrate init
```

### Install/Uninstall

```bash
# Install migrations table in database
migrate install

# Uninstall migrations table
migrate uninstall
```

### Create Migrations

```bash
# Create new migration
migrate create create_users_table

# Creates: YYYY_MM_DD_HHMMSS_create_users_table.cfc
```

### Run Migrations

```bash
# Run all pending migrations
migrate up

# Run next migration
migrate up --once

# Run specific number of migrations
migrate up --steps=3

# Use specific manager
migrate up --manager=secondary
```

### Rollback Migrations

```bash
# Rollback last migration
migrate down

# Rollback all migrations
migrate reset

# Rollback and re-run
migrate refresh

# Rollback specific number
migrate down --steps=2
```

### Seeders

```bash
# Create seeder
migrate seed create UserSeeder

# Run all seeders
migrate seed run

# Run specific seeder
migrate seed run --seeder=UserSeeder
```

### Status

```bash
# Show migration status
migrate status

# List all migrations
migrate list
```

## Best Practices

- **Version control migrations** - Commit migration files to git
- **Test migrations** - Test both up and down
- **Use in CI/CD** - Run migrations in deployment pipeline
- **Create seeders for test data** - Separate test data from migrations
- **Name migrations clearly** - Use descriptive action-based names

## Documentation

For complete CommandBox Migrations documentation, visit:
https://github.com/commandbox-modules/commandbox-migrations

See also: **cfmigrations** module guidelines for migration file structure and schema builder API.
