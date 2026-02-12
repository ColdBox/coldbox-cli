---
title: CFMigrations Module Guidelines
description: Database migration framework with SQL and schema builder support
---

# CFMigrations Module Guidelines

## Overview

CFMigrations provides database version control for CFML applications. It allows you to define schema changes in code, track which migrations have run, and provides a fluent schema builder API built on QB.

## Installation

```bash
box install cfmigrations
box install commandbox-migrations
```

## Configuration

Create `.cfmigrations.json` in your project root:

```bash
migrate init
```

```json
{
    "default": {
        "manager": "cfmigrations.models.QBMigrationManager",
        "migrationsDirectory": "resources/database/migrations/",
        "seedsDirectory": "resources/database/seeds/",
        "properties": {
            "defaultGrammar": "MySQLGrammar@qb",
            "schema": "${DB_SCHEMA}",
            "migrationsTable": "cfmigrations",
            "connectionInfo": {
                "host": "${DB_HOST}",
                "username": "${DB_USERNAME}",
                "password": "${DB_PASSWORD}",
                "database": "${DB_DATABASE}",
                "bundleName": "com.mysql.cj",
                "bundleVersion": "8.0.33"
            }
        }
    }
}
```

## CommandBox CLI Usage

```bash
# Install migration table
migrate install

# Create new migration
migrate create create_users_table
migrate create add_email_to_users

# Run migrations
migrate up

# Rollback last migration
migrate down

# Rollback all migrations
migrate reset

# Refresh (rollback all and re-run)
migrate refresh

# Run seeders
migrate seed run
```

## Migration File Structure

```boxlang
// resources/database/migrations/2024_02_07_143022_create_users_table.cfc
component {
    function up( schema, query ) {
        schema.create( "users", ( table ) => {
            table.increments( "id" )
            table.string( "username" ).unique()
            table.string( "email" ).unique()
            table.string( "password" )
            table.boolean( "active" ).default( true )
            table.timestamp( "created_at" ).nullable()
            table.timestamp( "updated_at" ).nullable()
        } )
    }
    
    function down( schema, query ) {
        schema.drop( "users" )
    }
}
```

## Schema Builder

### Creating Tables

```boxlang
function up( schema, query ) {
    schema.create( "posts", ( table ) => {
        // Primary key
        table.increments( "id" )
        
        // String columns
        table.string( "title" )
        table.string( "slug" ).unique()
        table.text( "body" )
        
        // Numeric columns
        table.integer( "view_count" ).default( 0 )
        table.decimal( "rating", 3, 2 ) // precision, scale
        
        // Boolean
        table.boolean( "published" ).default( false )
        
        // Dates
        table.date( "published_date" ).nullable()
        table.datetime( "scheduled_at" ).nullable()
        table.timestamp( "created_at" )
        table.timestamp( "updated_at" )
        
        // Foreign keys
        table.unsignedInteger( "user_id" )
        table.foreignKey( "user_id" ).references( "id" ).onTable( "users" ).onDelete( "CASCADE" )
        
        // JSON column
        table.json( "metadata" ).nullable()
        
        // Indexes
        table.index( "title" )
        table.index( [ "user_id", "published" ], "idx_user_published" )
    } )
}
```

### Column Types

```boxlang
// Integers
table.bigIncrements( "id" )
table.bigInteger( "big_number" )
table.increments( "id" )
table.integer( "count" )
table.unsignedInteger( "user_id" )
table.smallInteger( "small_number" )
table.tinyInteger( "tiny_number" )

// Strings
table.char( "code", 10 )
table.string( "name", 255 )
table.text( "description" )
table.mediumText( "content" )
table.longText( "markdown" )

// Decimals
table.decimal( "amount", 10, 2 )
table.float( "rating" )
table.double( "precise_value" )

// Dates
table.date( "birth_date" )
table.datetime( "scheduled_at" )
table.time( "alarm_time" )
table.timestamp( "created_at" )

// Binary
table.binary( "photo" )
table.blob( "data" )

// Boolean
table.boolean( "active" )

// JSON
table.json( "settings" )

// UUID
table.uuid( "id" )

// Enum
table.enum( "status", [ "pending", "active", "inactive" ] )
```

### Column Modifiers

```boxlang
table.string( "email" )
    .unique()
    .nullable()
    .default( "" )
    .comment( "User email address" )

table.integer( "order" )
    .unsigned()
    .default( 0 )

table.timestamp( "deleted_at" )
    .nullable()

table.decimal( "price", 10, 2 )
    .unsigned()
    .default( 0.00 )
```

### Altering Tables

```boxlang
function up( schema, query ) {
    schema.alter( "users", ( table ) => {
        // Add columns
        table.addColumn( table.string( "phone" ).nullable() )
        table.addColumn( table.integer( "login_count" ).default( 0 ) )
        
        // Rename column
        table.renameColumn( "email", "email_address" )
        
        // Modify column
        table.modifyColumn( "username", table.string( "username", 100 ) )
        
        // Drop column
        table.dropColumn( "old_field" )
        
        // Add index
        table.addIndex( "email" )
        table.addIndex( [ "last_name", "first_name" ], "idx_name" )
        
        // Drop index
        table.dropIndex( "email" )
        table.dropIndex( "idx_name" )
        
        // Add foreign key
        table.addConstraint(
            table.foreignKey( "role_id" )
                .references( "id" )
                .onTable( "roles" )
                .onDelete( "CASCADE" )
        )
        
        // Drop foreign key
        table.dropConstraint( "fk_users_role_id" )
    } )
}
```

### Dropping Tables

```boxlang
function down( schema, query ) {
    schema.drop( "users" )
}

// Drop if exists
function down( schema, query ) {
    schema.dropIfExists( "users" )
}
```

## Foreign Keys

### Creating Foreign Keys

```boxlang
schema.create( "posts", ( table ) => {
    table.increments( "id" )
    table.string( "title" )
    table.unsignedInteger( "user_id" )
    
    // Method 1: Inline
    table.foreignKey( "user_id" )
        .references( "id" )
        .onTable( "users" )
        .onDelete( "CASCADE" )
        .onUpdate( "CASCADE" )
    
    // Method 2: Combined
    table.unsignedInteger( "category_id" )
        .references( "id" )
        .onTable( "categories" )
} )
```

### Foreign Key Actions

```boxlang
// On delete actions
.onDelete( "CASCADE" )    // Delete related records
.onDelete( "SET NULL" )   // Set FK to NULL
.onDelete( "RESTRICT" )   // Prevent deletion
.onDelete( "NO ACTION" )  // Do nothing

// On update actions
.onUpdate( "CASCADE" )    // Update related FKs
.onUpdate( "RESTRICT" )   // Prevent update
```

## Indexes

```boxlang
schema.create( "users", ( table ) => {
    table.increments( "id" )
    table.string( "username" ).unique()
    table.string( "email" ).unique()
    table.string( "first_name" )
    table.string( "last_name" )
    
    // Single column index
    table.index( "email" )
    
    // Multi-column index
    table.index( [ "first_name", "last_name" ], "idx_full_name" )
    
    // Unique index
    table.unique( [ "username", "tenant_id" ] )
} )

// Add index to existing table
schema.alter( "users", ( table ) => {
    table.addIndex( [ "created_at", "active" ], "idx_recent_active" )
} )
```

## Data Seeding

### Creating Seeds

```bash
migrate seed create UserSeeder
```

```boxlang
// resources/database/seeds/UserSeeder.cfc
component {
    function run( qb, mockData ) {
        qb.table( "users" ).insert( [
            {
                username: "admin",
                email: "[email protected]",
                password: bcrypt.hashPassword( "admin123" ),
                active: true,
                created_at: now()
            },
            {
                username: "user",
                email: "[email protected]",
                password: bcrypt.hashPassword( "user123" ),
                active: true,
                created_at: now()
            }
        ] )
    }
}
```

### Running Seeds

```bash
# Run all seeders
migrate seed run

# Run specific seeder
migrate seed run --seeder=UserSeeder
```

## Using Query in Migrations

```boxlang
function up( schema, query ) {
    // Create table with schema
    schema.create( "roles", ( table ) => {
        table.increments( "id" )
        table.string( "name" ).unique()
        table.timestamp( "created_at" )
    } )
    
    // Insert data with query
    query.table( "roles" ).insert( [
        { name: "admin", created_at: now() },
        { name: "user", created_at: now() },
        { name: "guest", created_at: now() }
    ] )
}

function down( schema, query ) {
    schema.drop( "roles" )
}
```

## Common Migration Patterns

### User Authentication Table

```boxlang
function up( schema, query ) {
    schema.create( "users", ( table ) => {
        table.uuid( "id" ).primaryKey()
        table.string( "username" ).unique()
        table.string( "email" ).unique()
        table.string( "password" )
        table.string( "remember_token" ).nullable()
        table.boolean( "active" ).default( true )
        table.timestamp( "email_verified_at" ).nullable()
        table.timestamp( "last_login_at" ).nullable()
        table.timestamp( "created_at" )
        table.timestamp( "updated_at" )
        table.timestamp( "deleted_at" ).nullable()
        
        table.index( "email" )
        table.index( "active" )
    } )
}
```

### Pivot Table (Many-to-Many)

```boxlang
function up( schema, query ) {
    schema.create( "user_roles", ( table ) => {
        table.unsignedInteger( "user_id" )
        table.unsignedInteger( "role_id" )
        table.timestamp( "created_at" )
        
        // Composite primary key
        table.primaryKey( [ "user_id", "role_id" ] )
        
        // Foreign keys
        table.foreignKey( "user_id" )
            .references( "id" )
            .onTable( "users" )
            .onDelete( "CASCADE" )
        
        table.foreignKey( "role_id" )
            .references( "id" )
            .onTable( "roles" )
            .onDelete( "CASCADE" )
    } )
}
```

### Adding Column to Existing Table

```boxlang
function up( schema, query ) {
    schema.alter( "users", ( table ) => {
        table.addColumn( table.string( "phone" ).nullable() )
        table.addColumn( table.integer( "login_count" ).default( 0 ) )
    } )
}

function down( schema, query ) {
    schema.alter( "users", ( table ) => {
        table.dropColumn( "phone" )
        table.dropColumn( "login_count" )
    } )
}
```

## Best Practices

- **Name migrations descriptively** - Use clear, action-based names
- **Keep migrations small** - One logical change per migration
- **Always write down() methods** - Enable rollbacks
- **Test migrations** - Test both up and down
- **Use transactions** - Wrap multiple operations when supported
- **Don't modify old migrations** - Create new ones for changes
- **Version control migrations** - Commit migration files to git
- **Run in order** - Ensure correct execution sequence
- **Use seeders for test data** - Separate structure from data
- **Document complex migrations** - Add comments for clarity

## Documentation

For complete CFMigrations documentation, schema builder API, and advanced features, visit:
https://cfmigrations.ortusbooks.com
