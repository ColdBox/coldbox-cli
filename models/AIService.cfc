/**
 * Central AI operations service for ColdBox CLI AI integration
 * Coordinates guidelines, skills, MCP servers, and agent configurations
 */
component singleton {

	// DI
	property name="print"            inject="PrintBuffer";
	property name="fileSystemUtil"   inject="fileSystem";
	property name="packageService"   inject="PackageService";
	property name="config"           inject="box:moduleconfig:coldbox-cli";
	property name="guidelineManager" inject="GuidelineManager@coldbox-cli";
	property name="skillManager"     inject="SkillManager@coldbox-cli";
	property name="agentRegistry"    inject="AgentRegistry@coldbox-cli";

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
		var manifest = {
			"coldboxCliVersion" : getColdboxCliVersion(),
			"lastSync"          : dateTimeFormat( now(), "iso" ),
			"language"          : arguments.language,
			"guidelines"        : [],
			"skills"            : [],
			"agents"            : listToArray( arguments.agents )
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
		updateBoxJsonAIConfig( arguments.directory, arguments.language, arguments.agents );

		result.message = "AI integration installed successfully!";
		return result;
	}

	/**
	 * Refresh AI integration (sync with installed modules)
	 *
	 * @directory The project directory
	 */
	function refresh( required string directory ){
		var result = {
			"success" : true,
			"message" : "",
			"added"   : [],
			"updated" : [],
			"removed" : []
		};

		// Load existing manifest
		var manifest = loadManifest( arguments.directory );
		if ( !structKeyExists( manifest, "coldboxCliVersion" ) ) {
			result.success = false;
			result.message = "No AI integration found. Run 'coldbox ai install' first.";
			return result;
		}

		// Update coldbox-cli version
		manifest.coldboxCliVersion = getColdboxCliVersion()
		manifest.lastSync          = dateTimeFormat( now(), "iso" )

		// Refresh guidelines based on installed modules
		var guidelineChanges = variables.guidelineManager.refresh( arguments.directory, manifest );
		result.added.append( guidelineChanges.added, true );
		result.updated.append( guidelineChanges.updated, true );
		result.removed.append( guidelineChanges.removed, true );

		// Refresh skills based on installed modules
		var skillChanges = variables.skillManager.refresh( arguments.directory, manifest );
		result.added.append( skillChanges.added, true );
		result.updated.append( skillChanges.updated, true );
		result.removed.append( skillChanges.removed, true );

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
		var currentVersion = getColdboxCliVersion();
		if ( manifest.coldboxCliVersion != currentVersion ) {
			issues.warnings.append(
				"coldbox-cli v#currentVersion# installed, but guidelines are from v#manifest.coldboxCliVersion#"
			);
			issues.recommendations.append( "Run 'coldbox ai refresh' to update guidelines/skills" );
		}

		// Validate guidelines
		var guidelineIssues = variables.guidelineManager.diagnose( arguments.directory, manifest );
		issues.warnings.append( guidelineIssues.warnings, true );
		issues.recommendations.append( guidelineIssues.recommendations, true );

		// Validate skills
		var skillIssues = variables.skillManager.diagnose( arguments.directory, manifest );
		issues.warnings.append( skillIssues.warnings, true );
		issues.recommendations.append( skillIssues.recommendations, true );

		// Validate agents
		var agentIssues = variables.agentRegistry.diagnose( arguments.directory, manifest );
		issues.warnings.append( agentIssues.warnings, true );
		issues.recommendations.append( agentIssues.recommendations, true );

		// Build summary
		issues.summary = {
			"status"           : issues.errors.len() ? "error" : ( issues.warnings.len() ? "warning" : "good" ),
			"errorCount"       : issues.errors.len(),
			"warningCount"     : issues.warnings.len(),
			"recommendationCount" : issues.recommendations.len()
		};

		return issues;
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
	 * Save manifest file
	 *
	 * @directory The project directory
	 * @manifest The manifest struct to save
	 */
	private function saveManifest( required string directory, required struct manifest ){
		var manifestPath = arguments.directory & "/.ai/.manifest.json";
		fileWrite( manifestPath, serializeJSON( arguments.manifest, true ) );
	}

	/**
	 * Load manifest file
	 *
	 * @directory The project directory
	 */
	private function loadManifest( required string directory ){
		var manifestPath = arguments.directory & "/.ai/.manifest.json";
		if ( !fileExists( manifestPath ) ) {
			return {};
		}
		return deserializeJSON( fileRead( manifestPath ) );
	}

	/**
	 * Get current coldbox-cli version
	 */
	private function getColdboxCliVersion(){
		// Read from the coldbox-cli module's own box.json using module config path
		var moduleRoot = variables.config.path
		var boxJson = variables.packageService.readPackageDescriptor( moduleRoot )
		return boxJson.version ?: "unknown";
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
