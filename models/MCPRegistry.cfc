/**
 * MCP (Model Context Protocol) Server Registry
 * Manages discovery and configuration of MCP documentation servers
 *
 * MCP servers provide live documentation access for AI agents via the Model Context Protocol.
 * This registry tracks all known Ortus MCP servers and maps CommandBox modules to their
 * corresponding MCP documentation endpoints.
 */
component singleton {

	// DI
	property name="packageService" inject="PackageService";
	property name="utility"        inject="Utility@coldbox-cli";

	/**
	 * Get core MCP servers (always included for ColdBox/BoxLang projects)
	 *
	 * @return Array of server names
	 */
	function getCoreServers(){
		return [
			"boxlang",
			"coldbox",
			"commandbox",
			"testbox",
			"wirebox",
			"cachebox",
			"logbox"
		];
	}

	/**
	 * Get all known MCP servers from Ortus
	 *
	 * @return Struct with server definitions
	 */
	function getAllKnownServers(){
		return {
			// Core Platform
			"boxlang" : {
				"name"        : "boxlang",
				"description" : "BoxLang Language Documentation",
				"url"         : "https://ai.ortusbooks.com/~gitbook/mcp"
			},
			"boxlang-ide" : {
				"name"        : "boxlang-ide",
				"description" : "BoxLang IDE Documentation",
				"url"         : "https://boxlang-ide.ortusbooks.com/~gitbook/mcp"
			},
			"bx-ai" : {
				"name"        : "bx-ai",
				"description" : "BoxLang AI Module Documentation",
				"url"         : "https://ai.ortusbooks.com/~gitbook/mcp"
			},
			"modern-cfml" : {
				"name"        : "modern-cfml",
				"description" : "Modern CFML Guide",
				"url"         : "https://modern-cfml.ortusbooks.com/~gitbook/mcp"
			},
			// Core Frameworks
			"coldbox" : {
				"name"        : "coldbox",
				"description" : "ColdBox Framework Documentation",
				"url"         : "https://coldbox.ortusbooks.com/~gitbook/mcp"
			},
			"commandbox" : {
				"name"        : "commandbox",
				"description" : "CommandBox CLI Documentation",
				"url"         : "https://commandbox.ortusbooks.com/~gitbook/mcp"
			},
			"testbox" : {
				"name"        : "testbox",
				"description" : "TestBox Testing Framework",
				"url"         : "https://testbox.ortusbooks.com/~gitbook/mcp"
			},
			"wirebox" : {
				"name"        : "wirebox",
				"description" : "WireBox Dependency Injection",
				"url"         : "https://wirebox.ortusbooks.com/~gitbook/mcp"
			},
			"cachebox" : {
				"name"        : "cachebox",
				"description" : "CacheBox Caching Framework",
				"url"         : "https://cachebox.ortusbooks.com/~gitbook/mcp"
			},
			"logbox" : {
				"name"        : "logbox",
				"description" : "LogBox Logging Framework",
				"url"         : "https://logbox.ortusbooks.com/~gitbook/mcp"
			},
			"docbox" : {
				"name"        : "docbox",
				"description" : "DocBox Documentation Generator",
				"url"         : "https://docbox.ortusbooks.com/~gitbook/mcp"
			},
			// ORM & Database
			"bxorm" : {
				"name"        : "bxorm",
				"description" : "BoxLang ORM",
				"url"         : "https://bxorm.ortusbooks.com/~gitbook/mcp"
			},
			"cborm" : {
				"name"        : "cborm",
				"description" : "ColdBox ORM Utilities",
				"url"         : "https://coldbox-orm.ortusbooks.com/~gitbook/mcp"
			},
			"qb" : {
				"name"        : "qb",
				"description" : "Query Builder (QB)",
				"url"         : "https://qb.ortusbooks.com/~gitbook/mcp"
			},
			"quick" : {
				"name"        : "quick",
				"description" : "Quick ORM Active Record",
				"url"         : "https://quick.ortusbooks.com/~gitbook/mcp"
			},
			"cfmigrations" : {
				"name"        : "cfmigrations",
				"description" : "Database Migrations",
				"url"         : "https://cfmigrations.ortusbooks.com/~gitbook/mcp"
			},
			// Security
			"cbsecurity" : {
				"name"        : "cbsecurity",
				"description" : "CBSecurity Authentication/Authorization",
				"url"         : "https://coldbox-security.ortusbooks.com/~gitbook/mcp"
			},
			"cbauth" : {
				"name"        : "cbauth",
				"description" : "CBAuth User Authentication",
				"url"         : "https://cbauth.ortusbooks.com/~gitbook/mcp"
			},
			"cbsso" : {
				"name"        : "cbsso",
				"description" : "CBSSO Single Sign-On",
				"url"         : "https://cbsso.ortusbooks.com/~gitbook/mcp"
			},
			// Validation & Data
			"cbvalidation" : {
				"name"        : "cbvalidation",
				"description" : "CBValidation Validation Framework",
				"url"         : "https://coldbox-validation.ortusbooks.com/~gitbook/mcp"
			},
			"cbi18n" : {
				"name"        : "cbi18n",
				"description" : "CBI18N Internationalization",
				"url"         : "https://coldbox-i18n.ortusbooks.com/~gitbook/mcp"
			},
			"cbmailservices" : {
				"name"        : "cbmailservices",
				"description" : "CBMailServices Email Integration",
				"url"         : "https://coldbox-mailservices.ortusbooks.com/~gitbook/mcp"
			},
			// Development Tools
			"cbdebugger" : {
				"name"        : "cbdebugger",
				"description" : "CBDebugger Debugging Tools",
				"url"         : "https://cbdebugger.ortusbooks.com/~gitbook/mcp"
			},
			"cbelasticsearch" : {
				"name"        : "cbelasticsearch",
				"description" : "CBElasticsearch Integration",
				"url"         : "https://cbelasticsearch.ortusbooks.com/~gitbook/mcp"
			},
			"cbfs" : {
				"name"        : "cbfs",
				"description" : "CBFS File System Abstraction",
				"url"         : "https://cbfs.ortusbooks.com/~gitbook/mcp"
			},
			"cfconfig" : {
				"name"        : "cfconfig",
				"description" : "CFConfig Server Configuration",
				"url"         : "https://cfconfig.ortusbooks.com/~gitbook/mcp"
			},
			// Modern Development
			"cbwire" : {
				"name"        : "cbwire",
				"description" : "CBWire Reactive Components",
				"url"         : "https://cbwire.ortusbooks.com/~gitbook/mcp"
			},
			"cbq" : {
				"name"        : "cbq",
				"description" : "CBQ Job Queues",
				"url"         : "https://cbq.ortusbooks.com/~gitbook/mcp"
			},
			"megaphone" : {
				"name"        : "megaphone",
				"description" : "Megaphone Messaging",
				"url"         : "https://megaphone.ortusbooks.com/~gitbook/mcp"
			},
			// CMS
			"contentbox" : {
				"name"        : "contentbox",
				"description" : "ContentBox CMS",
				"url"         : "https://contentbox.ortusbooks.com/~gitbook/mcp"
			},
			// API & Documentation
			"relax" : {
				"name"        : "relax",
				"description" : "Relax REST API Documentation",
				"url"         : "https://coldbox-relax.ortusbooks.com/~gitbook/mcp"
			}
		};
	}

	/**
	 * Get module-to-MCP-server mapping
	 * Maps CommandBox module slugs to their MCP server identifiers
	 *
	 * @return Struct with module => server mappings
	 */
	function getModuleServerMap(){
		return {
			// Core modules (always added)
			"coldbox"               : "coldbox",
			"testbox"               : "testbox",
			"wirebox"               : "wirebox",
			"cachebox"              : "cachebox",
			"logbox"                : "logbox",
			"commandbox"            : "commandbox",
			// ORM & Database
			"bxorm"                 : "bxorm",
			"cborm"                 : "cborm",
			"qb"                    : "qb",
			"quick"                 : "quick",
			"cfmigrations"          : "cfmigrations",
			"commandbox-migrations" : "cfmigrations",
			// Security
			"cbsecurity"            : "cbsecurity",
			"cbauth"                : "cbauth",
			"cbsso"                 : "cbsso",
			// Validation & Data
			"cbvalidation"          : "cbvalidation",
			"cbi18n"                : "cbi18n",
			"cbmailservices"        : "cbmailservices",
			// Development
			"cbdebugger"            : "cbdebugger",
			"cbelasticsearch"       : "cbelasticsearch",
			"cbfs"                  : "cbfs",
			"cfconfig"              : "cfconfig",
			// Modern
			"cbwire"                : "cbwire",
			"cbq"                   : "cbq",
			"megaphone"             : "megaphone",
			// CMS
			"contentbox"            : "contentbox",
			// API
			"relax"                 : "relax",
			"cbswagger"             : "relax"
		}
	}

	/**
	 * Get MCP server definition
	 *
	 * @serverName The MCP server identifier
	 *
	 * @return Struct with server details or empty struct if not found
	 */
	function getServerDefinition( required string serverName ){
		var servers = getAllKnownServers();
		return servers[ arguments.serverName ] ?: {};
	}

	/**
	 * Get MCP servers for a project based on its dependencies
	 *
	 * @directory The project directory
	 *
	 * @return Struct with core, module, and all server arrays
	 */
	function getServersForProject( required string directory ){
		var result = {
			"core"   : getCoreServers(),
			"module" : [],
			"all"    : []
		};

		// Get installed modules from box.json
		var boxJson         = variables.packageService.readPackageDescriptor( arguments.directory );
		var moduleMap       = getModuleServerMap();
		var detectedServers = {};

		// Check dependencies
		if ( structKeyExists( boxJson, "dependencies" ) ) {
			boxJson.dependencies
				.keyArray()
				.each( ( moduleName ) => {
					if ( structKeyExists( moduleMap, moduleName ) ) {
						var serverName = moduleMap[ moduleName ];
						if ( !result.core.findNoCase( serverName ) && !detectedServers.keyExists( serverName ) ) {
							result.module.append( serverName );
							detectedServers[ serverName ] = true;
						}
					}
				} );
		}

		// Check devDependencies
		if ( structKeyExists( boxJson, "devDependencies" ) ) {
			boxJson.devDependencies
				.keyArray()
				.each( ( moduleName ) => {
					if ( structKeyExists( moduleMap, moduleName ) ) {
						var serverName = moduleMap[ moduleName ];
						if ( !result.core.findNoCase( serverName ) && !detectedServers.keyExists( serverName ) ) {
							result.module.append( serverName );
							detectedServers[ serverName ] = true;
						}
					}
				} );
		}

		// Build complete list
		result.all = duplicate( result.core );
		result.all.append( result.module, true );

		return result;
	}

	/**
	 * Check if an MCP server is a core server
	 *
	 * @serverName The server name to check
	 *
	 * @return boolean
	 */
	function isCoreServer( required string serverName ){
		return getCoreServers().findNoCase( arguments.serverName ) > 0;
	}

	/**
	 * Validate custom MCP server configuration
	 *
	 * @serverConfig Struct with name, url, and optional command/args
	 *
	 * @return Struct with valid (boolean) and message (string)
	 */
	function validateCustomServer( required struct serverConfig ){
		var result = { "valid" : true, "message" : "" };

		// Check required fields
		if ( !structKeyExists( arguments.serverConfig, "name" ) || !len( arguments.serverConfig.name ) ) {
			result.valid   = false;
			result.message = "Custom server must have a name";
			return result;
		}

		// Check name doesn't conflict with known servers
		var allServers = getAllKnownServers();
		if (
			structKeyExists(
				allServers,
				arguments.serverConfig.name
			)
		) {
			result.valid   = false;
			result.message = "Server name conflicts with known MCP server: #arguments.serverConfig.name#";
			return result;
		}

		// Check URL or command provided
		if (
			( !structKeyExists( arguments.serverConfig, "url" ) || !len( arguments.serverConfig.url ) ) &&
			( !structKeyExists( arguments.serverConfig, "command" ) || !len( arguments.serverConfig.command ) )
		) {
			result.valid   = false;
			result.message = "Custom server must have either a URL or command";
			return result;
		}

		return result;
	}

}
