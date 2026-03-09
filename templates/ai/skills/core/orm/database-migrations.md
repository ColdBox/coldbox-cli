---
name: Database Migrations
description: Complete guide to database migrations with CFMigrations for version control, schema changes, rollbacks, and seeding
category: orm
priority: high
triggers:
  - database migrations
  - schema migrations
  - migration create
  - migration rollback
  - database seeding
---

# Database Migrations

## Overview

Database migrations provide version control for your database schema, allowing you to define and share database changes across environments. CFMigrations integrates with CommandBox for seamless database evolution.

## Core Concepts

### Migration Benefits

- **Version Control**: Track database schema in code
- **Collaboration**: Share schema changes with team
- **Rollback**: Revert changes when needed
- **Environment Parity**: Consistent schemas across environments
- **Automation**: Apply changes programmatically

## Installation

```bash
box install commandbox-migrations
```

### Configuration

```boxlang
// config/ColdBox.cfc
moduleSettings = {
    cfmigrations: {
        manager: "cfmigrations.models.QBMigrationManager",
        migrationsDirectory: "/resources/database/migrations/",
        seedsDirectory: "/resources/database/seeds/",
        properties: {
            defaultGrammar: "MySQLGrammar@qb",
            datasource: "appDB"
        }
    }
}
```

## Creating Migrations

### Generate Migration

```bash
# Create migration file
box migrate create create_users_table

# With table shorthand
box migrate create create_users_table --table=users

# Create from template
box migrate create add_email_column_to_users_table
```

### Migration Structure

```boxlang
/**
 * resources/database/migrations/2026_02_11_143000_create_users_table.cfc
 */
component {

    function up( schema, query ) {
        schema.create( "users", ( table ) => {
            table.increments( "id" )
            table.string( "firstName" )
            table.string( "lastName" )
            table.string( "email" ).unique()
            table.string( "password" )
            table.boolean( "isActive" ).default( true )
            table.timestamp( "createdAt" ).nullable()
            table.timestamp( "updatedAt" ).nullable()
        } )
    }

    function down( schema, query ) {
        schema.drop( "users" )
    }
}
```

## Schema Builder

### Table Operations

```boxlang
// Create table
schema.create( "posts", ( table ) => {
    table.increments( "id" )
    table.unsignedInteger( "userId" )
    table.string( "title" )
    table.text( "content" )
    table.boolean( "published" ).default( false )
    table.timestamp( "publishedAt" ).nullable()
    table.timestamps()
} )

// Alter table
schema.alter( "posts", ( table ) => {
    table.addColumn( table.string( "slug" ).unique() )
    table.addColumn( table.text( "excerpt" ).nullable() )
} )

// Rename table
schema.rename( "posts", "articles" )

// Drop table
schema.drop( "posts" )

// Drop if exists
schema.dropIfExists( "posts" )

// Check if table exists
if ( schema.hasTable( "posts" ) ) {
    // Table exists
}
```

### Column Types

```boxlang
// Numeric types
table.increments( "id" )
table.bigIncrements( "id" )
table.integer( "age" )
table.bigInteger( "largeNumber" )
table.unsignedInteger( "count" )
table.decimal( "price", 8, 2 )
table.float( "amount" )

// String types
table.string( "name", 255 )
table.char( "code", 10 )
table.text( "description" )
table.mediumText( "content" )
table.longText( "content" )

// Date/Time types
table.date( "birthDate" )
table.datetime( "createdAt" )
table.timestamp( "updatedAt" )
table.time( "startTime" )

// Boolean
table.boolean( "isActive" )

// JSON
table.json( "metadata" )

// Binary
table.binary( "fileData" )

// Enum
table.enum( "status", [ "draft", "published", "archived" ] )
```

### Column Modifiers

```boxlang
// Nullable
table.string( "middleName" ).nullable()

// Default value
table.boolean( "isActive" ).default( true )
table.timestamp( "createdAt" ).default( "CURRENT_TIMESTAMP" )

// Unique constraint
table.string( "email" ).unique()

// Unsigned
table.integer( "count" ).unsigned()

// Auto-increment
table.integer( "id" ).autoIncrement()

// Comment
table.string( "name" ).comment( "User's full name" )

// Chain modifiers
table.string( "email" )
    .unique()
    .nullable( false )
    .comment( "User email address" )
```

### Indexes

```boxlang
// Primary key
table.increments( "id" )  // Auto-creates primary key

// Index
table.index( "email" )
table.index( [ "lastName", "firstName" ], "idx_name" )

// Unique index
table.unique( "email" )
table.unique( [ "email", "username" ] )

// Foreign key
table.unsignedInteger( "userId" )
    .references( "id" )
    .onTable( "users" )
    .onDelete( "CASCADE" )

// Drop indexes
table.dropIndex( "users_email_index" )
table.dropUnique( "users_email_unique" )
table.dropForeign( "posts_user_id_foreign" )
```

### Foreign Keys

```boxlang
// Add foreign key
schema.alter( "posts", ( table ) => {
    table.unsignedInteger( "userId" )

    table.foreignKey( "userId" )
        .references( "id" )
        .onTable( "users" )
        .onDelete( "CASCADE" )
        .onUpdate( "CASCADE" )
} )

// Drop foreign key
table.dropForeign( "posts_user_id_foreign" )

// Shorthand foreign key
table.foreignId( "userId" )
    .constrained( "users" )
    .onDelete( "CASCADE" )
```

## Running Migrations

### CommandBox CLI

```bash
# Run all pending migrations
box migrate up

# Run specific migration
box migrate up 2026_02_11_143000_create_users_table

# Rollback last batch
box migrate down

# Rollback all migrations
box migrate down --all

# Rollback specific migration
box migrate down 2026_02_11_143000_create_users_table

# Reset (rollback all + migrate up)
box migrate reset

# Refresh (reset + seed)
box migrate refresh

# Show migration status
box migrate status

# Install migration tables
box migrate install
```

### Programmatic Execution

```boxlang
/**
 * Run migrations from code
 */
component {

    property name="migrationService" inject="MigrationService@cfmigrations"

    function runMigrations() {
        try {
            // Check if migration table exists
            if ( !migrationService.isMigrationTableInstalled() ) {
                migrationService.install()
            }

            // Run pending migrations
            var result = migrationService.runAllMigrations( "up" )

            return {
                success: true,
                migrationsRun: result.len()
            }

        } catch ( any e ) {
            return {
                success: false,
                error: e.message
            }
        }
    }

    function rollbackMigrations( steps = 1 ) {
        return migrationService.runAllMigrations(
            direction: "down",
            steps: steps
        )
    }
}
```

## Database Seeding

### Create Seeder

```bash
box migrate seed create UserSeeder
```

### Seeder Structure

```boxlang
/**
 * resources/database/seeds/UserSeeder.cfc
 */
component {

    function run( query ) {
        // Insert single record
        query.table( "users" ).insert( {
            firstName: "John",
            lastName: "Doe",
            email: "john@example.com",
            password: bcrypt( "password" ),
            createdAt: now(),
            updatedAt: now()
        } )

        // Insert multiple records
        query.table( "users" ).insert( [
            {
                firstName: "Jane",
                lastName: "Smith",
                email: "jane@example.com",
                password: bcrypt( "password" ),
                createdAt: now(),
                updatedAt: now()
            },
            {
                firstName: "Bob",
                lastName: "Johnson",
                email: "bob@example.com",
                password: bcrypt( "password" ),
                createdAt: now(),
                updatedAt: now()
            }
        ] )
    }
}
```

### Running Seeds

```bash
# Run all seeders
box migrate seed run

# Run specific seeder
box migrate seed run UserSeeder

# Refresh database and seed
box migrate refresh --seed
```

## Advanced Patterns

### Conditional Migrations

```boxlang
component {

    function up( schema, query ) {
        // Check if column exists
        if ( !schema.hasColumn( "users", "phone" ) ) {
            schema.alter( "users", ( table ) => {
                table.addColumn( table.string( "phone" ).nullable() )
            } )
        }

        // Check if table exists
        if ( !schema.hasTable( "roles" ) ) {
            schema.create( "roles", ( table ) => {
                table.increments( "id" )
                table.string( "name" )
                table.timestamps()
            } )
        }
    }

    function down( schema, query ) {
        if ( schema.hasColumn( "users", "phone" ) ) {
            schema.alter( "users", ( table ) => {
                table.dropColumn( "phone" )
            } )
        }
    }
}
```

### Data Migrations

```boxlang
/**
 * Migrate data alongside schema changes
 */
component {

    function up( schema, query ) {
        // Add new column
        schema.alter( "users", ( table ) => {
            table.addColumn( table.string( "fullName" ).nullable() )
        } )

        // Migrate data
        var users = query.from( "users" ).get()

        users.each( ( user ) => {
            query.from( "users" )
                .where( "id", user.id )
                .update( {
                    fullName: "#user.firstName# #user.lastName#"
                } )
        } )

        // Make column non-nullable
        schema.alter( "users", ( table ) => {
            table.modifyColumn( "fullName", table.string( "fullName" ) )
        } )
    }

    function down( schema, query ) {
        schema.alter( "users", ( table ) => {
            table.dropColumn( "fullName" )
        } )
    }
}
```

### Pivot Table Migration

```boxlang
/**
 * Many-to-many relationship table
 */
component {

    function up( schema, query ) {
        schema.create( "user_roles", ( table ) => {
            table.unsignedInteger( "userId" )
            table.unsignedInteger( "roleId" )
            table.timestamp( "assignedAt" ).nullable()

            // Composite primary key
            table.primaryKey( [ "userId", "roleId" ] )

            // Foreign keys
            table.foreignKey( "userId" )
                .references( "id" )
                .onTable( "users" )
                .onDelete( "CASCADE" )

            table.foreignKey( "roleId" )
                .references( "id" )
                .onTable( "roles" )
                .onDelete( "CASCADE" )

            // Indexes
            table.index( "userId" )
            table.index( "roleId" )
        } )
    }

    function down( schema, query ) {
        schema.drop( "user_roles" )
    }
}
```

### Renaming Columns

```boxlang
component {

    function up( schema, query ) {
        schema.alter( "users", ( table ) => {
            table.renameColumn( "email", "emailAddress" )
        } )
    }

    function down( schema, query ) {
        schema.alter( "users", ( table ) => {
            table.renameColumn( "emailAddress", "email" )
        } )
    }
}
```

## Best Practices

### Design Guidelines

1. **Descriptive Names**: Use clear migration names
2. **One Purpose**: One logical change per migration
3. **Always Reversible**: Implement both up() and down()
4. **Data Safety**: Back up data before migrations
5. **Test Rollbacks**: Test down() migrations
6. **Idempotent**: Check existence before creating
7. **Seed Separately**: Keep seeds independent
8. **Version Control**: Commit migrations to VCS
9. **Production Care**: Review before production
10. **Team Coordination**: Communicate schema changes

### Common Patterns

```boxlang
// ✅ Good: Descriptive name
2026_02_11_143000_add_email_verification_to_users_table.cfc

// ✅ Good: Check before creating
if ( !schema.hasTable( "users" ) ) {
    schema.create( "users", ... )
}

// ✅ Good: Timestamps helper
table.timestamps()  // Creates createdAt and updatedAt

// ✅ Good: Soft deletes
table.timestamp( "deletedAt" ).nullable()

// ✅ Good: Foreign key with cascade
table.foreignKey( "userId" )
    .references( "id" )
    .onTable( "users" )
    .onDelete( "CASCADE" )
```

## Common Pitfalls

### Pitfalls to Avoid

1. **Skipping Down**: Not implementing down()
2. **Data Loss**: Dropping columns with data
3. **No Checks**: Not checking existence
4. **Wrong Order**: Foreign keys before tables
5. **Production Direct**: Running migrations manually
6. **No Backup**: Not backing up before migration
7. **Seeds in Migrations**: Mixing concerns
8. **Hardcoded Data**: Environment-specific data
9. **Complex Logic**: Too much code in migrations
10. **Not Testing**: Skipping rollback tests

### Anti-Patterns

```boxlang
// ❌ Bad: No down() method
function down( schema, query ) {
    // Empty - can't rollback
}

// ✅ Good: Reversible
function down( schema, query ) {
    schema.drop( "users" )
}

// ❌ Bad: Dropping column with data
schema.alter( "users", ( table ) => {
    table.dropColumn( "importantData" )
} )

// ✅ Good: Move data first
// Separate migration to move data
// Then drop column

// ❌ Bad: Seeding in migration
function up( schema, query ) {
    schema.create( "users", ... )

    // Bad: Seed data here
    query.table( "users" ).insert( ... )
}

// ✅ Good: Use separate seeder
// Keep migrations for schema only
```

## Environment-Specific Migrations

### Multiple Environments

```boxlang
// config/ColdBox.cfc
environments = {
    development: "^(localhost|127\.0\.0\.1)",
    staging: "^staging\.",
    production: "^www\."
}

moduleSettings = {
    cfmigrations: {
        properties: {
            datasource: getSystemSetting( "DB_NAME", "appDB" )
        }
    }
}
```

### CI/CD Integration

```yaml
# .github/workflows/deploy.yml
- name: Run Migrations
  run: |
    box migrate install
    box migrate up
  env:
    DB_HOST: ${{ secrets.DB_HOST }}
    DB_NAME: ${{ secrets.DB_NAME }}
    DB_USER: ${{ secrets.DB_USER }}
    DB_PASSWORD: ${{ secrets.DB_PASSWORD }}
```

## Related Skills

- [Quick ORM](orm-quick.md) - ORM patterns
- [Query Builder](query-builder.md) - QB queries
- [BoxLang JDBC](boxlang-jdbc.md) - Database connections

## References

- [CFMigrations Documentation](https://forgebox.io/view/commandbox-migrations)
- [Schema Builder](https://qb.ortusbooks.com/schema-builder)
- [Database Migrations Best Practices](https://www.prisma.io/dataguide/types/relational/migration-strategies)
