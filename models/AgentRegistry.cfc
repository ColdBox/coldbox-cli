/**
 * Registry for AI agent configurations
 * Manages agent-specific files (CLAUDE.md, .github/copilot-instructions.md, etc.)
 */
component singleton {

	// DI
	property name="print"          inject="PrintBuffer";
	property name="fileSystemUtil" inject="fileSystem";
	property name="wirebox"        inject="wirebox";
	property name="utility"        inject="Utility@coldbox-cli";
	property name="mcpRegistry"    inject="MCPRegistry@coldbox-cli";

	static {
		SUPPORTED_AGENTS = [
			"claude",
			"copilot",
			"cursor",
			"codex",
			"gemini",
			"opencode"
		]
		AGENT_FILES = {
			"claude"   : "CLAUDE.md",
			"copilot"  : ".github/copilot-instructions.md",
			"cursor"   : ".cursorrules",
			"codex"    : ".codex/instructions.md",
			"gemini"   : ".gemini/instructions.md",
			"opencode" : ".opencode/instructions.md"
		}
		AGENT_OPTIONS = [
			{
				display : "Claude (Anthropic) - Recommended for general development",
				value   : "claude"
			},
			{
				display : "GitHub Copilot - Integrated with VS Code",
				value   : "copilot"
			},
			{
				display : "Cursor AI - AI-first code editor",
				value   : "cursor"
			},
			{
				display : "Codex (OpenAI) - GPT-powered coding assistant",
				value   : "codex"
			},
			{
				display : "Gemini (Google) - Google's AI assistant",
				value   : "gemini"
			},
			{
				display : "OpenCode - Open source AI assistant",
				value   : "opencode"
			}
		]
	}

	// Expose them as instance properties for easier access in commands
	this.SUPPORTED_AGENTS = static.SUPPORTED_AGENTS
	this.AGENT_OPTIONS    = static.AGENT_OPTIONS
	this.AGENT_FILES      = static.AGENT_FILES

	/**
	 * Configure agents for a project
	 *
	 * @directory The project directory
	 * @agents Comma-separated list of agents
	 * @language Project language mode
	 */
	function configureAgents(
		required string directory,
		required string agents,
		required string language
	){
		return listToArray( arguments.agents ).map( ( agent ) => {
			configureAgent( directory, agent, language )
			return agent
		} )
	}

	/**
	 * Get the config path mapping for all supported agents or a specific agent if passed
	 *
	 * @agentName Optional agent name to get specific path for (claude, copilot, cursor, codex, gemini, opencode)
	 *
	 * @return Struct with agent names as keys and config paths as values as per their conventions
	 */
	function getAgentConfigPaths( string agentName ){
		if ( !isNull( arguments.agentName ) ) {
			return static.AGENT_FILES[ arguments.agentName ] ?: "AI_INSTRUCTIONS.md"
		}

		return static.AGENT_FILES
	}

	/**
	 * Diagnose agent configuration health
	 *
	 * @directory The project directory
	 * @manifest The manifest struct
	 */
	function diagnose(
		required string directory,
		required struct manifest
	){
		var issues = {
			"warnings"        : [],
			"recommendations" : []
		};

		// Check each configured agentr
		var agents = manifest.agents ?: [];
		agents.each( ( agent ) => {
			var configFile = getAgentConfigPath( directory, agent )
			if ( !fileExists( configFile ) ) {
				issues.warnings.append( "Agent config file missing: #agent#" )
				issues.recommendations.append( "Run 'coldbox ai refresh' to regenerate agent files" )
			}
		} )

		return issues;
	}

	// ========================================
	// Private Helpers
	// ========================================

	/**
	 * Configure a single agent
	 *
	 * @directory The project directory
	 * @agent The agent name (claude, copilot, cursor, etc.)
	 * @language Project language mode (boxlang, cfml, hybrid)
	 */
	function configureAgent(
		required string directory,
		required string agent,
		required string language
	){
		var configPath   = getAgentConfigPath( arguments.directory, arguments.agent )
		var templateType = variables.utility.detectTemplateType( arguments.directory )
		var content      = getAgentConfigContent(
			arguments.agent,
			arguments.language,
			templateType,
			arguments.directory
		)

		// Create directories if needed
		var configDir = getDirectoryFromPath( configPath )
		if ( !directoryExists( configDir ) ) {
			directoryCreate( configDir )
		}

		// Write agent config file
		fileWrite( configPath, content )
	}

	/**
	 * Get agent config file path for a specific agent on a specific project directory
	 *
	 * @directory The project directory
	 * @agent The agent name (claude, copilot, cursor, etc.)
	 */
	function getAgentConfigPath(
		required string directory,
		required string agent
	){
		// Check if directory ends in / or \ and remove it for consistent path building
		if ( right( arguments.directory, 1 ) == "/" || right( arguments.directory, 1 ) == "\" ) {
			arguments.directory = left(
				arguments.directory,
				len( arguments.directory ) - 1
			)
		}

		switch ( arguments.agent ) {
			case "claude":
				return "#arguments.directory#/CLAUDE.md"
			case "copilot":
				return "#arguments.directory#/.github/copilot-instructions.md"
			case "cursor":
				return "#arguments.directory#/.cursorrules"
			case "codex":
				return "#arguments.directory#/.codex/instructions.md"
			case "gemini":
				return "#arguments.directory#/.gemini/instructions.md"
			case "opencode":
				return "#arguments.directory#/.opencode/instructions.md"
			default:
				return "#arguments.directory#/AI_INSTRUCTIONS.md"
		}
	}

	/**
	 * Get agent config content (reads from template)
	 *
	 * @agent The agent name (claude, copilot, cursor, etc.)
	 * @language Project language mode (boxlang, cfml, hybrid)
	 * @templateType Project template type (flat or modern)
	 * @directory The project directory
	 */
	private function getAgentConfigContent(
		required string agent,
		required string language,
		required string templateType,
		required string directory
	){
		var templatesPath = variables.utility.getTemplatesPath()
		var templateFile  = ""

		// Use layout-specific templates for all agents
		templateFile = arguments.templateType == "modern"
		 ? "#templatesPath#/ai/agents/agent-modern-instructions.md"
		 : "#templatesPath#/ai/agents/agent-flat-instructions.md"

		if ( !fileExists( templateFile ) ) {
			throw(
				type    = "AgentRegistry.TemplateNotFound",
				message = "Agent template not found: #templateFile#"
			)
		}

		var content = fileRead( templateFile )

		// Get project information
		var boxJson     = {}
		var boxJsonPath = "#arguments.directory#/box.json"
		if ( fileExists( boxJsonPath ) ) {
			boxJson = deserializeJSON( fileRead( boxJsonPath ) )
		}

		var projectName    = boxJson.name ?: getFileFromPath( arguments.directory )
		var coldboxVersion = boxJson.dependencies.coldbox ?: "8.x"

		// Determine language mode display
		var languageMode = "BoxLang"
		if ( arguments.language == "cfml" ) {
			languageMode = "CFML"
		} else if ( arguments.language == "hybrid" ) {
			languageMode = "BoxLang/CFML Hybrid"
		}

		// Detect enabled features
		var viteEnabled       = detectViteEnabled( arguments.directory )
		var dockerEnabled     = detectDockerEnabled( arguments.directory )
		var ormEnabled        = detectOrmEnabled( boxJson )
		var migrationsEnabled = detectMigrationsEnabled( arguments.directory, boxJson )

		// Build features list
		var enabledFeatures = []
		if ( viteEnabled ) enabledFeatures.append( "Vite" )
		if ( dockerEnabled ) enabledFeatures.append( "Docker" )
		if ( ormEnabled ) enabledFeatures.append( "ORM" )
		if ( migrationsEnabled ) enabledFeatures.append( "Migrations" )

		var features = enabledFeatures.len() ? enabledFeatures.toList( ", " ) : "None"

		// Replace placeholders
		content = replaceNoCase(
			content,
			"|PROJECT_NAME|",
			projectName,
			"all"
		)
		content = replaceNoCase(
			content,
			"|LANGUAGE_MODE|",
			languageMode,
			"all"
		)
		content = replaceNoCase(
			content,
			"|COLDBOX_VERSION|",
			coldboxVersion,
			"all"
		)
		content = replaceNoCase(
			content,
			"|FEATURES|",
			features,
			"all"
		)
		content = replaceNoCase(
			content,
			"|VITE_ENABLED|",
			viteEnabled ? "Yes" : "No",
			"all"
		)
		content = replaceNoCase(
			content,
			"|DOCKER_ENABLED|",
			dockerEnabled ? "Yes" : "No",
			"all"
		)
		content = replaceNoCase(
			content,
			"|ORM_ENABLED|",
			ormEnabled ? "Yes" : "No",
			"all"
		)
		content = replaceNoCase(
			content,
			"|MIGRATIONS_ENABLED|",
			migrationsEnabled ? "Yes" : "No",
			"all"
		)

		// Add MCP servers content
		var mcpContent = generateMCPServersContent( arguments.directory )
		content = replaceNoCase(
			content,
			"|MCP_SERVERS|",
			mcpContent,
			"all"
		)

		return content
	}

	/**
	 * Detect if Vite is enabled in the project
	 */
	private function detectViteEnabled( required string directory ){
		var viteConfig  = "#arguments.directory#/vite.config.mjs"
		var packageJson = "#arguments.directory#/package.json"

		if ( fileExists( viteConfig ) ) return true

		if ( fileExists( packageJson ) ) {
			var pkgContent = deserializeJSON( fileRead( packageJson ) )
			return structKeyExists(
				pkgContent.dependencies ?: {},
				"vite"
			) ||
			structKeyExists(
				pkgContent.devDependencies ?: {},
				"vite"
			)
		}

		return false
	}

	/**
	 * Detect if Docker is enabled in the project
	 */
	private function detectDockerEnabled( required string directory ){
		return fileExists( "#arguments.directory#/Dockerfile" ) ||
		fileExists( "#arguments.directory#/docker-compose.yml" )
	}

	/**
	 * Detect if ORM is enabled (cborm or quick)
	 */
	private function detectOrmEnabled( required struct boxJson ){
		var deps    = boxJson.dependencies ?: {}
		var devDeps = boxJson.devDependencies ?: {}

		return structKeyExists( deps, "cborm" ) ||
		structKeyExists( devDeps, "cborm" ) ||
		structKeyExists( deps, "quick" ) ||
		structKeyExists( devDeps, "quick" )
	}

	/**
	 * Detect if migrations are enabled
	 */
	private function detectMigrationsEnabled(
		required string directory,
		required struct boxJson
	){
		// Check for migrations in dependencies
		var deps    = boxJson.dependencies ?: {}
		var devDeps = boxJson.devDependencies ?: {}

		if (
			structKeyExists( deps, "commandbox-migrations" ) ||
			structKeyExists( devDeps, "commandbox-migrations" )
		) {
			return true
		}

		// Check for migrations directory
		return directoryExists( "#arguments.directory#/resources/database/migrations" )
	}

	/**
	 * Generate MCP servers content for agent configuration
	 *
	 * @directory The project directory
	 *
	 * @return String containing formatted MCP server list
	 */
	private function generateMCPServersContent( required string directory ){
		// Load manifest to get MCP servers
		var aiService = variables.wirebox.getInstance( "AIService@coldbox-cli" )
		var manifest = aiService.loadManifest( arguments.directory )

		if ( !structKeyExists( manifest, "mcpServers" ) ) {
			return "No MCP servers configured yet. Run 'coldbox ai refresh' to initialize."
		}

		var mcpServers = manifest.mcpServers
		var content = []

		// Core servers
		if ( mcpServers.core.len() ) {
			content.append( "**Core Documentation Servers:**" )
			content.append( "" )
			mcpServers.core.each( ( server ) => {
				var serverDef = variables.mcpRegistry.getServerDefinition( server )
				if ( !serverDef.isEmpty() ) {
					content.append( "- **#server#**: #serverDef.description#" )
				}
			} )
			content.append( "" )
		}

		// Module servers
		if ( mcpServers.module.len() ) {
			content.append( "**Module Documentation Servers:**" )
			content.append( "" )
			mcpServers.module.each( ( server ) => {
				var serverDef = variables.mcpRegistry.getServerDefinition( server )
				if ( !serverDef.isEmpty() ) {
					content.append( "- **#server#**: #serverDef.description#" )
				}
			} )
			content.append( "" )
		}

		// Custom servers
		if ( mcpServers.custom.len() ) {
			content.append( "**Custom Documentation Servers:**" )
			content.append( "" )
			mcpServers.custom.each( ( mcpServer ) => {
				var desc = mcpServer.description ?: "Custom MCP server"
				content.append( "- **#mcpServer.name#**: #desc#" )
			} )
			content.append( "" )
		}

		content.append( "**Using MCP Servers:** Query these servers when you need current documentation, API references, or code examples. They provide live, up-to-date information directly from official documentation sources." )

		return content.toList( chr( 10 ) )
	}

}
