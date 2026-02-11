/**
 * Central AI operations service for ColdBox CLI AI integration
 * Coordinates guidelines, skills, MCP servers, and agent configurations
 */
component singleton {

	// DI
	property name="print"            inject="PrintBuffer";
	property name="fileSystemUtil"   inject="fileSystem";
	property name="packageService"   inject="PackageService";
	property name="guidelineManager" inject="GuidelineManager@coldbox-cli";
	property name="skillManager"     inject="SkillManager@coldbox-cli";
	property name="agentRegistry"    inject="AgentRegistry@coldbox-cli";
	property name="mcpRegistry"      inject="MCPRegistry@coldbox-cli";
	property name="utility"          inject="Utility@coldbox-cli";

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
		var aiDir = arguments.directory & "/.ai";
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
		var mcpServers = variables.mcpRegistry.getServersForProject( arguments.directory );
		manifest.mcpServers.core   = mcpServers.core;
		manifest.mcpServers.module = mcpServers.module;

		// Configure agents
		result.agents = variables.agentRegistry.configureAgents(
			arguments.directory,
			arguments.agents,
			arguments.language
		);

		// Save manifest
		saveManifest( arguments.directory, manifest );
		result.manifest = manifest;

		// Update box.json with AI configuration
		updateBoxJsonAIConfig(
			arguments.directory,
			arguments.language,
			arguments.agents
		);

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
			"mcpServers" : {
				"added"   : [],
				"removed" : []
			}
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
		var skillChanges = variables.skillManager.refresh( arguments.directory, manifest );
		result.skills.added.append( skillChanges.added, true );
		result.skills.updated.append( skillChanges.updated, true );
		result.skills.removed.append( skillChanges.removed, true );

		// Refresh MCP servers based on installed modules
		var newMcpServers = variables.mcpRegistry.getServersForProject( arguments.directory );
		var oldMcpServers = manifest.mcpServers ?: { "core" : [], "module" : [], "custom" : [] };
		
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
		var customServers = oldMcpServers.custom ?: [];
		manifest.mcpServers = {
			"core"   : newMcpServers.core,
			"module" : newMcpServers.module,
			"custom" : customServers
		};

		// Save updated manifest
		saveManifest( arguments.directory, manifest );

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
			"agents"            : manifest.agents ?: []
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
			issues.errors.append( "Invalid or missing .ai/.manifest.json file" )
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
	 * Load the manifest file
	 *
	 * @directory The project directory
	 */
	struct function loadManifest( required string directory ){
		var manifestPath = arguments.directory & "/.ai/.manifest.json";
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
		return arguments.directory & "/.ai/.manifest.json";
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
		fileWrite(
			manifestPath,
			serializeJSON( arguments.manifest, true )
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
		var dirs = [
			"#arguments.directory#/.ai",
			"#arguments.directory#/.ai/guidelines",
			"#arguments.directory#/.ai/guidelines/core",
			"#arguments.directory#/.ai/guidelines/modules",
			"#arguments.directory#/.ai/guidelines/custom",
			"#arguments.directory#/.ai/skills",
			"#arguments.directory#/.ai/skills/core",
			"#arguments.directory#/.ai/skills/modules",
			"#arguments.directory#/.ai/skills/custom"
		];

		dirs.each( ( dir ) => {
			if ( !directoryExists( dir ) ) {
				directoryCreate( dir )
			}
		} )
	}

	/**
	 * Update box.json with AI configuration
	 *
	 * @directory The project directory
	 * @language Project language mode (boxlang, cfml, hybrid)
	 * @agents Comma-separated list of agents
	 */
	private function updateBoxJsonAIConfig(
		required string directory,
		required string language,
		required string agents
	){
		var packageDir = arguments.directory;
		var boxJson    = variables.packageService.readPackageDescriptor( packageDir );

		// Add language at top level
		boxJson.language = arguments.language;

		// Add ai configuration section
		boxJson.ai = {
			"enabled" : true,
			"agents"  : listToArray( arguments.agents )
		};

		variables.packageService.writePackageDescriptor( boxJson, packageDir );
	}

}
