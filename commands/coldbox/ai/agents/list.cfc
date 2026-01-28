/**
 * List configured AI agents
 * Shows which agents have been configured and their config file locations
 *
 * Examples:
 * coldbox ai agents list
 * coldbox ai agents list --verbose
 */
component extends="coldbox-cli.models.BaseCommand" {

	// DI
	property name="aiService" inject="AIService@coldbox-cli"

	/**
	 * Run the command
	 *
	 * @verbose Show detailed information including file paths
	 * @directory The target directory (defaults to current directory)
	 */
	function run(
		boolean verbose  = false,
		string directory = getCwd()
	){
		showColdBoxBanner( "AI Agents" )

		try {
			var info = variables.aiService.getInfo( arguments.directory )

			if ( !info.installed ) {
				printError( "AI integration not installed. Run 'coldbox ai install' first." )
				return
			}

			print.line()
			printInfo( "Configured AI Agents" )
			print.line()

			if ( !info.agents.len() ) {
				printWarn( "No agents configured yet." )
				print.line()
				printHelp( "Run 'coldbox ai install --agent=claude,copilot' to configure agents" )
				return
			}

			// Agent config paths mapping
			var agentPaths = {
				"claude"   : "CLAUDE.md",
				"copilot"  : ".github/copilot-instructions.md",
				"cursor"   : ".cursorrules",
				"codex"    : ".codex/instructions.md",
				"gemini"   : ".gemini/instructions.md",
				"opencode" : ".opencode/instructions.md"
			}

			// Display each configured agent
			info.agents.each( ( agent ) => {
				var configPath = agentPaths[ agent ] ?: "AI_INSTRUCTIONS.md"
				var fullPath   = arguments.directory & "/" & configPath
				var exists     = fileExists( fullPath )

				if ( exists ) {
					print.greenLine( "  ✓ #agent#" )
				} else {
					print.redLine( "  ✗ #agent# (config file missing)" )
				}

				if ( arguments.verbose ) {
					print.indentedLine( "    Config: #configPath#" )
					if ( !exists ) {
						print.indentedLine( "    Status: Missing - run 'coldbox ai refresh' to regenerate" )
					}
				}
			} )

			print.line()
			printInfo( "Total: #info.agents.len()# agent(s) configured" )
			print.line()

			printHelp( "Tip: Agent config files contain project context for AI assistants" )
		} catch ( any e ) {
			printError( "Failed to list agents: #e.message#" )
			if ( arguments.verbose ) {
				printError( e.stackTrace )
			}
		}
	}

}
