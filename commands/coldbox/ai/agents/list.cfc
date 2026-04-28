/**
 * List configured AI agents
 * Shows which agents have been configured and their config file locations
 *
 * Examples:
 * coldbox ai agents list
 * coldbox ai agents list --verbose
 */
component extends="coldbox-cli.models.BaseAICommand" {

	// DI
	property name="agentRegistry" inject="AgentRegistry@coldbox-cli";

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

		var info = ensureInstalled( arguments.directory )
		if ( !info.installed ) {
			return
		}

		print.line()
		printInfo( "Configured AI Agents" )

		if ( !info.agents.len() ) {
			printWarn( "No agents configured yet." )
			print.line()
			printHelp( "Run 'coldbox ai install --agent=claude,copilot' to configure agents" )
			return
		}

		// Display each configured agent
		info.agents.each( ( agent ) => {
			var configPath = variables.agentRegistry.getAgentConfigPath( directory, agent )
			var exists     = fileExists( configPath )

			if ( exists ) {
				print.greenLine( "  ✓ #agent#" )
			} else {
				print.redLine( "  ✗ #agent# (config file missing - run `coldbox ai refresh` to regenerate)" )
			}

			if ( verbose ) {
				print.indentedLine( "    Config: #configPath#" )
				if ( !exists ) {
					print.indentedLine( "    Status: Missing - run 'coldbox ai refresh' to regenerate" )
				}
			}
		} )

		print.line()
		printInfo( "Total: #info.agents.len()# agent(s) configured" )
		print.line()

		printTip( "Agent config files contain project context for AI assistants" )
	}

}
