# ContentBox CLI

This is the official ContentBox CLI for interacting with ContentBox headless instances and also for allowing you to create and manage ContentBox installations.

## LICENSE

Apache License, Version 2.0.

## SYSTEM REQUIREMENTS

- CommandBox 5.1+

## Installation

Install the commands via CommandBox like so:

```bash
box install contentbox-cli
```

## Usage

You can use the CLI for many thing like installing ContentBox, creating widgets, themes, and much more.  More importantly, the CLI is the official way to install ContentBox from version 5 forwards.  It is a gargantuan task to be able to maintain more than 4 CFML engines against 4 major databases.  That's why this CLI was built, to make things easier for installing and working with ContentBox across the board.

### Installing ContentBox

We have created the `install` and the `install-wizard` commands so you can easily install ContentBox on any OS, using any supported CFML engine and supported database.  Here are the supported engines and databases:

#### Suported CFML Engines

- Lucee 5+
- _Adobe 2016 (End of life December 2021)_
- Adobe 2018
- Adobe 2021

#### Supported Databases

- Hypersonic SQL
- MySQL 5.7
- MySQL 8+
- PostgreSQL 13+
- Microsoft SQL Server 2012+
- Oracle 11+ (Beta)

#### Pre-Requisites

Before using the commands you must do two things:

1. Create an empty directory with a name of your choice, and startup the CommandBox shell inside of it.
2. Create an empty database in your RDBMS of your choice and make sure you have the connection credentials handy.

```bash
# Start the CommandBox shell
box
# Create and move into the directory where we will install your site
mkdir --cd mySite
```

#### Install vs Install Wizard

The `install` command is meant to be used without user interactivity. It is great for automation and setting up ContentBox sites with no user input.  The `install-wizard` command is meant to be used as a wizard that will guide you through the installation process.

```bash
# Automated install
contentbox install name="MySite" databaseType="MySQL8" databaseUsername="root" databasePassword="mysql"

# Wizard install
contentbox install-wizard
```

#### Installation Arguments

The `install` command has several arguments you can use in order to install ContentBox. Please note the arguments with the `required` prefix.

- `required name` - The name of the site
- `cfmlEngine = "lucee@5"` - The CFML engine to use
- `cfmlPassword = "contentbox"` - The password to seed the CFML Admin with
- `coldboxPassword = "contentbox"` - The password to seed the ColdBox application with
- `required databaseType` - The database type you are installing against
- `databaseHost = "localhost"` - The host location for your database
- `databasePort=""` - The database port
- `required databaseUsername` - The database connection useranme
- `required databasePassword` - The database connection password
- `databaseName = "contentbox"` - The name of the database
- `boolean production = false` - Is this a development site or a production site
- `boolean deployServer = true` - If true, we will deploy the CFML Engine on CommandBox in the directory you chose for installation. Else, we just prepare everything for you to run the folder within your CFML installation.
- `boolean verbose = false` - Verbose logging to the cli

The available CFML Engines are:

- `lucee@5`
- `adobe@2016`
- `adobe@2018`
- `adobe@2021`

The available RDBMS are:

- `HyperSonicSQL`
- `MySQL5`
- `MySQL8`
- `MicrosoftSQL`
- `PostgreSQL`
- `Oracle`

Once you run the command, this command will do the following procedures:

- Install a `contentbox-site`
- Install `coldbox`
- Install all ContentBox dependency modules
- Create an `.env` in the root with the appropriate secrests and credentials to your database
- Create a `box.json` in your root configured with all dependencies and migrations connection information to your database
- Create a `server.json` in your root configured to your CFML engine of choice.
- Connect and verify to your database and install the database migrations table
- If you chose to deploy the server, we will configure, deploy and startup a CommandBox server with your chosen CFML engine.

That's it, enjoy ContentBox.

#### Examples

Here are some example commands for installation:

```bash
# Install against MySQL 8 with Lucee
contentbox install name="MySite" databaseType="MySQL8" databaseUsername="root" databasePassword="mysql"

# Install against MySQL 8 with Adobe 2018
contentbox install name="MySite" cfmlEngine="adobe@2018" databaseType="MySQL8" databaseUsername="root" databasePassword="mysql"

# Install against Microsoft SQL Server with Adobe 2018
contentbox install name="MySite" cfmlEngine="adobe@2018" databaseType="MicrosoftSQL" databaseUsername="sa" databasePassword="sqlserver"

# Install against Lucee and PostgreSQL
contentbox install name="MySite" databaseType="PostgreSQL" databaseUsername="myRole" databasePassword="myPassword"
```

----


# CREDITS & CONTRIBUTIONS

I THANK GOD FOR HIS WISDOM FOR THIS PROJECT

## THE DAILY BREAD

"I am the way, and the truth, and the life; no one comes to the Father, but by me (JESUS)" Jn 14:1-12

[1]: https://github.com/Ortus-Solutions/DocBox/wiki
[2]: https://github.com/Ortus-Solutions/DocBox
