/**
 * Central AI operations service for ColdBox CLI AI integration
 * Coordinates guidelines, skills, MCP servers, and agent configurations
 */
component singleton {

	// DI
	property name="guidelineManager" inject="GuidelineManager@coldbox-cli";
	property name="skillManager"     inject="SkillManager@coldbox-cli";
	property name="agentRegistry"    inject="AgentRegistry@coldbox-cli";
	property name="mcpRegistry"      inject="MCPRegistry@coldbox-cli";
	property name="utility"          inject="Utility@coldbox-cli";
	// From CommandBox CLI
	property name="JSONService"      inject="JSONService";
	property name="print"            inject="PrintBuffer";
	property name="fileSystemUtil"   inject="fileSystem";
	property name="packageService"   inject="PackageService";

	static {
		AI_DIR = ".agents"
	}

	/**
	 * Install AI integration for a project
	 *
	 * @directory The project directory (defaults to current directory)
	 * @agents Comma-separated list of agents to configure (claude,copilot,codex,gemini,opencode)
	 * @language Project language mode: boxlang, cfml, hybrid (default: boxlang)
	 * @force Overwrite existing AI configuration
	 */
	function install(
		required string directory,
		string agents   = "claude",
		string language = "boxlang",
		boolean force   = false
	){
		var result = {
			"success"    : true,
			"message"    : "",
			"guidelines" : [],
			"skills"     : [],
			"agents"     : [],
			"manifest"   : {}
		};

		// Validate directory
		if ( !directoryExists( arguments.directory ) ) {
			result.success = false;
			result.message = "Directory does not exist: #arguments.directory#";
			return result;
		}

		// Check if already installed
		var aiDir = arguments.directory & "/" & static.AI_DIR;
		if ( directoryExists( aiDir ) && !arguments.force ) {
			result.success = false;
			result.message = "AI integration already installed. Use --force to overwrite.";
			return result;
		}

		// Create .ai directory structure
		createAIDirectoryStructure( arguments.directory );

		// Initialize manifest
		var templateType = variables.utility.detectTemplateType( arguments.directory )
		var manifest     = {
			"coldboxCliVersion" : variables.utility.getColdboxCliVersion(),
			"lastSync"          : dateTimeFormat( now(), "iso" ),
			"language"          : arguments.language,
			"templateType"      : templateType,
			"guidelines"        : [],
			"skills"            : [],
			"agents"            : listToArray( arguments.agents ),
			"mcpServers"        : {
				"core"   : [],
				"module" : [],
				"custom" : []
			}
		};

		// Install core guidelines
		result.guidelines = variables.guidelineManager.installCoreGuidelines(
			arguments.directory,
			arguments.language,
			manifest
		);

		// Install core skills
		result.skills = variables.skillManager.installCoreSkills(
			arguments.directory,
			arguments.language,
			manifest
		);

		// Initialize MCP servers
		var mcpServers             = variables.mcpRegistry.getServersForProject( arguments.directory );
		manifest.mcpServers.core   = mcpServers.core;
		manifest.mcpServers.module = mcpServers.module;
		result.mcpServers.core     = mcpServers.core;
		result.mcpServers.module   = mcpServers.module;

		// If only 1 agent is configured, automatically set it as active
		var agentsList = listToArray( arguments.agents )
		if ( agentsList.len() == 1 ) {
			manifest[ "activeAgent" ] = agentsList.first()
		}

		// Save manifest BEFORE configuring agents so they can read MCP servers
		saveManifest( arguments.directory, manifest );

		// Configure agents (reads manifest for MCP servers)
		result.agents = variables.agentRegistry.configureAgents(
			arguments.directory,
			arguments.agents,
			arguments.language
		);

		result.manifest = manifest;

		// Generate .mcp.json from manifest MCP servers
		generateMCPJson( arguments.directory, manifest );

		result.message = "AI integration installed successfully!";
		return result;
	}

	/**
	 * Refresh AI integration (sync with installed modules)
	 *
	 * The refresh process will:
	 * 1. Load the existing manifest to understand current state
	 * 2. Check installed modules and determine if any guidelines or skills need to be added
	 *   updated, or removed based on the current box.json dependencies and the guidelines/skills they provide
	 * 3. Update the manifest with any changes and save it
	 * 4. Return a result struct with details on what was added, updated, or removed, along with a success status and message
	 *
	 * @directory The project directory
	 *
	 * @return Struct with success status, message, and lists of added/updated/removed guidelines and skills
	 */
	struct function refresh( required string directory ){
		var result = {
			"success"    : true,
			"message"    : "",
			"guidelines" : {
				"added"   : [],
				"updated" : [],
				"removed" : []
			},
			"skills" : {
				"added"   : [],
				"updated" : [],
				"removed" : []
			},
			"mcpServers" : { "added" : [], "removed" : [] },
			"agents"     : []
		};

		// Load existing manifest
		var manifest = loadManifest( arguments.directory );
		if ( !structKeyExists( manifest, "coldboxCliVersion" ) ) {
			result.success = false;
			result.message = "No AI integration found. Run 'coldbox ai install' first.";
			return result;
		}

		// Update coldbox-cli version
		manifest.coldboxCliVersion = variables.utility.getColdboxCliVersion()
		manifest.lastSync          = dateTimeFormat( now(), "iso" )

		// Update/add template type (detects current structure, handles old manifests or structure changes)
		manifest.templateType = variables.utility.detectTemplateType( arguments.directory )

		// Refresh guidelines based on installed modules
		var guidelineChanges = variables.guidelineManager.refresh( arguments.directory, manifest );
		result.guidelines.added.append( guidelineChanges.added, true );
		result.guidelines.updated.append( guidelineChanges.updated, true );
		result.guidelines.removed.append( guidelineChanges.removed, true );

		// Refresh skills based on installed modules
		var language = manifest.language ?: "boxlang";
		var skillChanges = variables.skillManager.refresh( arguments.directory, manifest, language );
		result.skills.added.append( skillChanges.added, true );
		result.skills.updated.append( skillChanges.updated, true );
		result.skills.removed.append( skillChanges.removed, true );

		// Refresh MCP servers based on installed modules
		var newMcpServers = variables.mcpRegistry.getServersForProject( arguments.directory );
		var oldMcpServers = manifest.mcpServers ?: {
			"core"   : [],
			"module" : [],
			"custom" : []
		};

		// Track changes in module servers (core servers never change, custom servers are preserved)
		var oldModuleServers = oldMcpServers.module ?: [];
		var newModuleServers = newMcpServers.module;

		// Find added module servers
		newModuleServers.each( ( serverName ) => {
			if ( !oldModuleServers.findNoCase( serverName ) ) {
				result.mcpServers.added.append( serverName );
			}
		} );

		// Find removed module servers
		oldModuleServers.each( ( serverName ) => {
			if ( !newModuleServers.findNoCase( serverName ) ) {
				result.mcpServers.removed.append( serverName );
			}
		} );

		// Preserve custom servers
		var customServers   = oldMcpServers.custom ?: [];
		manifest.mcpServers = {
			"core"   : newMcpServers.core,
			"module" : newMcpServers.module,
			"custom" : customServers
		};

		// Save updated manifest
		saveManifest( arguments.directory, manifest );

		// Regenerate agent configuration files with updated content
		// This ensures MCP servers and other changes are reflected in agent instruction files
		if ( structKeyExists( manifest, "agents" ) && manifest.agents.len() ) {
			var language = manifest.language ?: "boxlang";
			manifest.agents.each( ( agent ) => {
				variables.agentRegistry.configureAgent( directory, agent, language );
				result.agents.append( agent );
			} );
		}

		// Regenerate .mcp.json to reflect updated MCP servers
		generateMCPJson( arguments.directory, manifest );

		result.message = "AI integration refreshed successfully!";
		return result;
	}

	/**
	 * Get AI integration info for a project
	 *
	 * @directory The project directory
	 */
	function getInfo( required string directory ){
		var manifest = loadManifest( arguments.directory );

		return {
			"installed"         : structKeyExists( manifest, "coldboxCliVersion" ),
			"coldboxCliVersion" : manifest.coldboxCliVersion ?: "unknown",
			"language"          : manifest.language ?: "unknown",
			"templateType"      : manifest.templateType ?: "unknown",
			"lastSync"          : manifest.lastSync ?: "never",
			"guidelines"        : manifest.guidelines ?: [],
			"skills"            : manifest.skills ?: [],
			"agents"            : manifest.agents ?: [],
			"mcpServers"        : manifest.mcpServers ?: {
				"core"   : [],
				"module" : [],
				"custom" : []
			}
		};
	}

	/**
	 * Diagnose AI integration health
	 *
	 * @directory The project directory
	 */
	function diagnose( required string directory ){
		var issues = {
			"errors"          : [],
			"warnings"        : [],
			"recommendations" : [],
			"summary"         : {}
		};

		// Check if AI integration is installed
		var aiDir = arguments.directory & "/.ai"
		if ( !directoryExists( aiDir ) ) {
			issues.errors.append( "AI integration not installed. Run 'coldbox ai install' first." )
			// Build summary for early return
			issues.summary = {
				"status"              : "error",
				"errorCount"          : issues.errors.len(),
				"warningCount"        : issues.warnings.len(),
				"recommendationCount" : issues.recommendations.len()
			}
			return issues
		}

		// Load manifest
		var manifest = loadManifest( arguments.directory )
		if ( !structKeyExists( manifest, "coldboxCliVersion" ) ) {
			issues.errors.append( "Invalid or missing /.agents/manifest.json file" )
			// Build summary for early return
			issues.summary = {
				"status"              : "error",
				"errorCount"          : issues.errors.len(),
				"warningCount"        : issues.warnings.len(),
				"recommendationCount" : issues.recommendations.len()
			}
			return issues
		}

		// Check coldbox-cli version
		var currentVersion = variables.utility.getColdboxCliVersion();
		if ( manifest.coldboxCliVersion != currentVersion ) {
			issues.warnings.append(
				"coldbox-cli v#currentVersion# installed, but guidelines are from v#manifest.coldboxCliVersion#"
			);
			issues.recommendations.append( "Run 'coldbox ai refresh' to update guidelines/skills" );
		}

		// Validate guidelines
		var guidelineIssues = variables.guidelineManager.diagnose( arguments.directory, manifest );
		issues.warnings.append( guidelineIssues.warnings, true );
		issues.recommendations.append(
			guidelineIssues.recommendations,
			true
		);

		// Validate skills
		var skillIssues = variables.skillManager.diagnose( arguments.directory, manifest );
		issues.warnings.append( skillIssues.warnings, true );
		issues.recommendations.append( skillIssues.recommendations, true );

		// Validate agents
		var agentIssues = variables.agentRegistry.diagnose( arguments.directory, manifest );
		issues.warnings.append( agentIssues.warnings, true );
		issues.recommendations.append( agentIssues.recommendations, true );

		// Validate MCP servers
		if ( !structKeyExists( manifest, "mcpServers" ) ) {
			issues.warnings.append( "MCP servers not configured in manifest" );
			issues.recommendations.append( "Run 'coldbox ai refresh' to initialize MCP servers" );
		} else {
			var coreServers = manifest.mcpServers.core ?: [];
			if ( !coreServers.len() ) {
				issues.warnings.append( "No core MCP servers configured" );
				issues.recommendations.append( "Run 'coldbox ai refresh' to add core servers" );
			}
		}

		// Build summary
		issues.summary = {
			"status"              : issues.errors.len() ? "error" : ( issues.warnings.len() ? "warning" : "good" ),
			"errorCount"          : issues.errors.len(),
			"warningCount"        : issues.warnings.len(),
			"recommendationCount" : issues.recommendations.len()
		};

		return issues;
	}

	/**
	 * Get the AI installation directory path (.agents)
	 *
	 * @directory The project directory
	 *
	 * @return The full path to the .agents directory
	 */
	string function getAIInstallDirectory( required string directory ){
		return arguments.directory & "/" & static.AI_DIR;
	}

	/**
	 * Load the manifest file
	 *
	 * @directory The project directory
	 */
	struct function loadManifest( required string directory ){
		var manifestPath = getAIInstallDirectory( arguments.directory ) & "/manifest.json";
		if ( !fileExists( manifestPath ) ) {
			return {};
		}
		return deserializeJSON( fileRead( manifestPath ) );
	}

	/**
	 * Get the manifest file path for a directory
	 *
	 * @directory The target directory
	 *
	 * @return The full path to the manifest file
	 */
	string function getManifestPath( required string directory ){
		return getAIInstallDirectory( arguments.directory ) & "/manifest.json";
	}

	/**
	 * Save a manifest file and update last sync time
	 *
	 * @directory The project directory
	 * @manifest The manifest struct to save
	 */
	AIService function saveManifest(
		required string directory,
		required struct manifest
	){
		var manifestPath            = getManifestPath( arguments.directory )
		arguments.manifest.lastSync = dateTimeFormat( now(), "iso" )
		variables.JSONService.writeJSONFile(
			path: manifestPath,
			json: arguments.manifest
		)
		return this
	}

	/**
	 * This function updates the last sync time in the manifest without modifying any other content, then saves it.
	 * This is useful for operations that want to update the sync time after making changes to guidelines/skills/agents without needing to re-save the entire manifest content.
	 *
	 * @directory The project directory
	 */
	AIService function updateLastSync( required string directory ){
		var manifest = loadManifest( arguments.directory );
		return saveManifest( arguments.directory, manifest );
	}

	// ========================================
	// Private Helpers
	// ========================================

	/**
	 * Create .ai directory structure
	 *
	 * @directory The project directory where .ai structure will be created
	 */
	private function createAIDirectoryStructure( required string directory ){
		var aiDir = getAIInstallDirectory( arguments.directory )
		var dirs  = [
			"#aiDir#",
			"#aiDir#/guidelines",
			"#aiDir#/guidelines/core",
			"#aiDir#/guidelines/custom",
			"#aiDir#/skills"
		];

		dirs.each( ( dir ) => {
			if ( !directoryExists( dir ) ) {
				directoryCreate( dir )
			}
		} )
	}

	/**
	 * Get AI integration statistics
	 *
	 * @directory The project directory
	 *
	 * @return Struct with detailed statistics about guidelines, skills, agents, MCP servers, and context usage
	 */
	function getStats( required string directory ){
		// Load manifest and info
		var manifest = loadManifest( arguments.directory );
		var info     = getInfo( arguments.directory );

		var stats = {
			"guidelines" : {
				"total"        : info.guidelines.len(),
				"core"         : 0,
				"module"       : 0,
				"custom"       : 0,
				"override"     : 0,
				"totalSize"    : 0,
				"avgSize"      : 0,
				"inlinedSize"  : 0,
				"onDemandSize" : 0
			},
			"skills" : {
				"total"     : info.skills.len(),
				"core"      : 0,
				"module"    : 0,
				"custom"    : 0,
				"override"  : 0,
				"totalSize" : 0,
				"avgSize"   : 0
			},
			"agents" : {
				"total"      : manifest.agents.len(),
				"configured" : manifest.agents,
				"filesSize"  : 0
			},
			"mcpServers" : {
				"total"  : 0,
				"core"   : 0,
				"module" : 0,
				"custom" : 0
			},
			"language"        : manifest.language ?: "unknown",
			"templateType"    : manifest.templateType ?: "unknown",
			"lastSync"        : manifest.lastSync ?: "never",
			"contextEstimate" : {
				"baseContextKB"    : 0,
				"inlinedKB"        : 0,
				"onDemandKB"       : 0,
				"totalAvailableKB" : 0
			}
		};

		// Determine which guidelines are inlined based on language
		var inlinedGuidelines = [ "coldbox" ];
		if ( stats.language == "boxlang" || stats.language == "hybrid" ) {
			inlinedGuidelines.append( "boxlang" );
		}
		if ( stats.language == "cfml" || stats.language == "hybrid" ) {
			inlinedGuidelines.append( "cfml" );
		}

		// Count guidelines by type and calculate sizes
		var aiDir         = getAIInstallDirectory( arguments.directory )
		var guidelinesDir = aiDir & "/guidelines";
		info.guidelines.each( ( guideline ) => {
			var type = guideline.type ?: "module";
			if ( structKeyExists( stats.guidelines, type ) ) {
				stats.guidelines[ type ]++;
			}

			// Calculate if this guideline is inlined or on-demand
			if ( type == "core" && inlinedGuidelines.find( guideline.name ) ) {
				// Core inlined guideline - calculate actual file size
				var guidelineFile = guidelinesDir & "/core/" & guideline.name & ".md";
				if ( fileExists( guidelineFile ) ) {
					stats.guidelines.inlinedSize += getFileInfo( guidelineFile ).size;
				}
			} else {
				// On-demand guideline - only description counts in base context
				// Full file counts toward on-demand total
				var guidelinePath = "";
				if ( type == "core" ) {
					guidelinePath = guidelinesDir & "/core/" & guideline.name & ".md";
				} else if ( type == "module" ) {
					guidelinePath = guidelinesDir & "/modules/" & guideline.name & ".md";
				} else if ( type == "custom" ) {
					guidelinePath = guidelinesDir & "/custom/" & guideline.name & ".md";
				} else if ( type == "override" ) {
					guidelinePath = guidelinesDir & "/overrides/" & guideline.name & ".md";
				}
				if ( len( guidelinePath ) && fileExists( guidelinePath ) ) {
					stats.guidelines.onDemandSize += getFileInfo( guidelinePath ).size;
				}
			}
		} );

		// Calculate total guidelines size
		if ( directoryExists( guidelinesDir ) ) {
			stats.guidelines.totalSize = calculateDirectorySize( guidelinesDir );
			stats.guidelines.avgSize   = stats.guidelines.total > 0 ? int(
				stats.guidelines.totalSize / stats.guidelines.total
			) : 0;
		}

		// Count skills by type (all skills are on-demand)
		info.skills.each( ( skill ) => {
			var type   = skill.type ?: "module";
			var source = skill.source ?: "";

			if ( type == "override" ) {
				stats.skills.override++;
			} else if ( source == "core" ) {
				stats.skills.core++;
			} else if ( source == "custom" || type == "custom" ) {
				stats.skills.custom++;
			} else {
				stats.skills.module++;
			}
		} );

		// Skills size (all on-demand)
		var skillsDir = aiDir & "/skills";
		if ( directoryExists( skillsDir ) ) {
			var skillsSize         = calculateDirectorySize( skillsDir );
			stats.skills.totalSize = skillsSize;
			stats.skills.avgSize   = stats.skills.total > 0 ? int( skillsSize / stats.skills.total ) : 0;
		}

		// Count MCP servers
		var mcpServers = manifest.mcpServers ?: {
			"core"   : [],
			"module" : [],
			"custom" : []
		};
		stats.mcpServers.core   = mcpServers.core.len();
		stats.mcpServers.module = mcpServers.module.len();
		stats.mcpServers.custom = mcpServers.custom.len();
		stats.mcpServers.total  = stats.mcpServers.core + stats.mcpServers.module + stats.mcpServers.custom;

		// Calculate agent files size (the actual base context)
		if ( manifest.agents.len() ) {
			manifest.agents.each( ( agent ) => {
				var agentPath = variables.agentRegistry.getAgentConfigPath( directory, agent );
				if ( fileExists( agentPath ) ) {
					stats.agents.filesSize += getFileInfo( agentPath ).size;
				}
			} );
		}

		// Calculate context estimates
		// Base context = agent files (includes inlined guidelines + inventories)
		stats.contextEstimate.baseContextKB    = int( stats.agents.filesSize / 1024 );
		// Inlined guidelines (part of base context, shown separately for clarity)
		stats.contextEstimate.inlinedKB        = int( stats.guidelines.inlinedSize / 1024 );
		// On-demand resources (not in base context, but available)
		stats.contextEstimate.onDemandKB       = int( ( stats.guidelines.onDemandSize + stats.skills.totalSize ) / 1024 );
		// Total available if all resources were loaded
		stats.contextEstimate.totalAvailableKB = int(
			( stats.agents.filesSize + stats.guidelines.onDemandSize + stats.skills.totalSize ) / 1024
		);

		return stats;
	}

	/**
	 * Generate or update the root .mcp.json file from the manifest's mcpServers.
	 * This file follows the VS Code / Claude Desktop MCP configuration format:
	 * { "mcpServers": { "name": { "type": "http", "url": "..." } } }
	 *
	 * - core/module servers: looked up by name from MCPRegistry to get their URL
	 * - custom servers: URL-based → type "http"; command-based → type "stdio"
	 *
	 * @directory The project root directory
	 * @manifest  The current manifest struct (must contain mcpServers)
	 */
	function generateMCPJson(
		required string directory,
		required struct manifest
	){
		var mcpJson  = { "mcpServers" : {} };
		var allKnown = variables.mcpRegistry.getAllKnownServers();

		// Process core and module servers (string names → look up definition)
		var namedServers = [];
		namedServers.append(
			arguments.manifest.mcpServers.core ?: [],
			true
		);
		namedServers.append(
			arguments.manifest.mcpServers.module ?: [],
			true
		);

		namedServers.each( ( serverName ) => {
			if ( structKeyExists( allKnown, serverName ) ) {
				mcpJson.mcpServers[ serverName ] = {
					"type" : "http",
					"url"  : allKnown[ serverName ].url
				};
			}
		} );

		// Process custom servers (objects with url or command)
		( arguments.manifest.mcpServers.custom ?: [] ).each( ( targetServer ) => {
			if ( structKeyExists( targetServer, "url" ) ) {
				mcpJson.mcpServers[ targetServer.name ] = {
					"type" : "http",
					"url"  : targetServer.url
				};
			} else if ( structKeyExists( targetServer, "command" ) ) {
				var entry = {
					"type"    : "stdio",
					"command" : targetServer.command
				};
				if ( structKeyExists( targetServer, "args" ) && targetServer.args.len() ) {
					entry.args = targetServer.args;
				}
				mcpJson.mcpServers[ targetServer.name ] = entry;
			}
		} );

		variables.JSONService.writeJSONFile(
			path: arguments.directory & "/.mcp.json",
			json: mcpJson
		);

		return this;
	}

	/**
	 * Calculate directory size recursively (only .md and .txt files)
	 *
	 * @path The directory path
	 *
	 * @return Total size in bytes
	 */
	private function calculateDirectorySize( required string path ){
		var totalSize = 0;

		if ( !directoryExists( arguments.path ) ) {
			return 0;
		}

		var files = directoryList(
			arguments.path,
			true,
			"path",
			"*.md|*.txt"
		);

		files.each( ( target ) => {
			totalSize += getFileInfo( target ).size;
		} );

		return totalSize;
	}

}
