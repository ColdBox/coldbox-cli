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

	static {
		SUPPORTED_AGENTS = [ "claude", "copilot", "cursor", "codex", "gemini", "opencode" ]
		AGENT_FILES = {
			"claude"   : "CLAUDE.md",
			"copilot"  : ".github/copilot-instructions.md",
			"cursor"   : ".cursorrules",
			"codex"    : ".codex/instructions.md",
			"gemini"   : ".gemini/instructions.md",
			"opencode" : ".opencode/instructions.md"
		}
		AGENT_OPTIONS = [
			{ display: "Claude (Anthropic) - Recommended for general development", value: "claude" },
			{ display: "GitHub Copilot - Integrated with VS Code", value: "copilot" },
			{ display: "Cursor AI - AI-first code editor", value: "cursor" },
			{ display: "Codex (OpenAI) - GPT-powered coding assistant", value: "codex" },
			{ display: "Gemini (Google) - Google's AI assistant", value: "gemini" },
			{ display: "OpenCode - Open source AI assistant", value: "opencode" }
		]
	}

	// Expose them as instance properties for easier access in commands
	this.SUPPORTED_AGENTS = static.SUPPORTED_AGENTS
	this.AGENT_OPTIONS = static.AGENT_OPTIONS
	this.AGENT_FILES = static.AGENT_FILES

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
		return listToArray( arguments.agents )
			.map( ( agent ) => {
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

		if( !isNull( arguments.agentName ) ){
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
	function diagnose( required string directory, required struct manifest ){
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
		var configPath = getAgentConfigPath( arguments.directory, arguments.agent )
		var layout     = detectProjectLayout( arguments.directory )
		var content    = getAgentConfigContent( arguments.agent, arguments.language, layout )

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
	 function getAgentConfigPath( required string directory, required string agent ){
		// Check if directory ends in / or \ and remove it for consistent path building
		if ( right( arguments.directory, 1 ) == "/" || right( arguments.directory, 1 ) == "\" ) {
			arguments.directory = left( arguments.directory, len( arguments.directory ) - 1 )
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
	 * @layout Project layout type (flat or modern)
	 */
	private function getAgentConfigContent( required string agent, required string language, required string layout ){
		var templatesPath = variables.utility.getTemplatesPath()
		var templateFile  = ""

		// For copilot, use layout-specific templates
		if ( arguments.agent == "copilot" ) {
			templateFile = arguments.layout == "modern"
				? "#templatesPath#/ai/modern-copilot-instructions.md"
				: "#templatesPath#/ai/flat-copilot-instructions.md"
		} else {
			// Use generic template for other agents
			templateFile = "#templatesPath#/ai/agents/agent-instructions.md"
		}

		if ( !fileExists( templateFile ) ) {
			// Fallback content from template
			var fallbackPath = templatesPath & "/ai/agents/agent-fallback.md"
			var fallback = fileRead( fallbackPath )

			// Replace tokens
			fallback = replaceNoCase( fallback, "|agentName|", arguments.agent, "all" )
			fallback = replaceNoCase( fallback, "|language|", arguments.language, "all" )
			fallback = replaceNoCase( fallback, "|layout|", arguments.layout, "all" )

			return fallback
		}

		var content = fileRead( templateFile )

		// Replace placeholders
		var languageNote = arguments.language == "boxlang" ? "BoxLang" : ( arguments.language == "cfml" ? "CFML" : "BoxLang/CFML hybrid" )
		content = replaceNoCase( content, "|LANGUAGE|", languageNote, "all" )

		return content
	}

	/**
	 * Detect project layout type
	 *
	 * @directory The project directory
	 */
	private function detectProjectLayout( required string directory ){
		// Modern layout has separate /app and /public directories
		var hasAppDir    = directoryExists( "#arguments.directory#/app" )
		var hasPublicDir = directoryExists( "#arguments.directory#/public" )

		return ( hasAppDir && hasPublicDir ) ? "modern" : "flat"
	}


}
