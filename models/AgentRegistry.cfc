/**
 * Registry for AI agent configurations
 * Manages agent-specific files (CLAUDE.md, .github/copilot-instructions.md, etc.)
 */
component singleton {

	// DI
	property name="print"          inject="PrintBuffer";
	property name="fileSystemUtil" inject="fileSystem";
	property name="wirebox"        inject="wirebox";

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
	private function configureAgent(
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
	 * Get agent config file path
	 *
	 * @directory The project directory
	 * @agent The agent name (claude, copilot, cursor, etc.)
	 */
	private function getAgentConfigPath( required string directory, required string agent ){
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
		var templatesPath = getTemplatesPath()
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
			// Fallback content
			return "## AI Instructions for #arguments.agent#

Project Language: #arguments.language#
Project Layout: #arguments.layout#

Guidelines available in .ai/guidelines/
Skills available in .ai/skills/"
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

	/**
	 * Get templates path from settings
	 */
	private function getTemplatesPath(){
		var moduleSettings = wirebox.getInstance( "box:modulesettings:coldbox-cli" );
		return moduleSettings.templatesPath;
	}

}
