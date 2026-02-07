/**
 * Remove an AI agent configuration from the project
 * Deletes the agent-specific instruction file
 *
 * Examples:
 * coldbox ai agents remove cursor
 * coldbox ai agents remove codex --force
 */
component extends="coldbox-cli.models.BaseAICommand" {

	// DI
	property name="agentRegistry" inject="AgentRegistry@coldbox-cli";

	/**
	 * Run the command
	 *
	 * @agent The agent name to remove
	 * @force Skip confirmation prompt
	 * @directory The target directory (defaults to current directory)
	 */
	function run(
		required string agent,
		boolean force    = false,
		string directory = getCwd()
	){
		showColdBoxBanner( "Remove AI Agent" )

		var info = ensureInstalled( arguments.directory )

		print.line()
		printInfo( "Removing agent: #arguments.agent#" )
		print.line()

		// Check if agent is configured
		if ( !info.agents.find( arguments.agent ) ) {
			printError( "Agent '#arguments.agent#' is not configured." )
			print.line()
			printHelp( "Use 'coldbox ai agents list' to see configured agents" )
			return
		}

		// Confirm removal
		if ( !arguments.force ) {
			if ( !confirm( "Are you sure you want to remove '#arguments.agent#'? [y/n]" ) ) {
				printInfo( "Operation cancelled." )
				return
			}
		}

		// Get config file path
		var configPath = variables.agentRegistry.getAgentConfigPath( arguments.directory, arguments.agent )
		print.line()

		// Delete config file
		if ( fileExists( configPath ) ) {
			fileDelete( configPath )
			printSuccess( "✓ Deleted config file: #configPath#" )
		} else {
			printWarn( "Config file not found (may have been manually deleted)" )
		}

		// Update manifest
		var manifest = loadManifest( arguments.directory )
		manifest.agents = manifest.agents.filter( ( a ) => a != agent )
		saveManifest( arguments.directory, manifest )

		print.line()
		printSuccess( "✓ Agent '#arguments.agent#' removed successfully!" )
		print.line()
		printTip( "Use 'coldbox ai agents add #arguments.agent#' to re-add this agent" )
	}

}
