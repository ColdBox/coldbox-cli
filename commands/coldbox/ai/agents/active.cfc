/**
 * Show or set the active AI agent
 * Used to indicate which agent is currently being used for development
 *
 * Examples:
 * coldbox ai agents active              (shows current active agent)
 * coldbox ai agents active claude       (sets active agent)
 */
component extends="coldbox-cli.models.BaseAICommand" {

	/**
	 * Run the command
	 *
	 * @agent Optional agent name to set as active
	 * @directory The target directory (defaults to current directory)
	 */
	function run(
		string agent     = "",
		string directory = getCwd()
	){
		showColdBoxBanner( "Active AI Agent" )

		var info = ensureInstalled( arguments.directory )
		var manifest = readManifest( arguments.directory )

		print.line()

		// If no agent specified, show current active
		if ( !arguments.agent.len() ) {
			var activeAgent = manifest.activeAgent ?: "none"

			if ( activeAgent == "none" ) {
				printInfo( "No active agent set." )
			} else {
				printSuccess( "Active Agent: #activeAgent#" )
			}

			print.line()

			if ( info.agents.len() ) {
				printInfo( "Configured agents:" )
				info.agents.each( ( agent ) => {
					if ( agent == activeAgent ) {
						print.greenLine( "  ▶ #agent# (active)" )
					} else {
						print.line( "  · #agent#" )
					}
				} )
			}

			print.line()
			printHelp( "Tip: Use 'coldbox ai agents active <name>' to set the active agent" )
			return
		}

		// Set new active agent
		if ( !info.agents.find( arguments.agent ) ) {
			printError( "Agent '#arguments.agent#' is not configured." )
			print.line()
			printHelp( "Use 'coldbox ai agents list' to see configured agents" )
			printHelp( "Use 'coldbox ai agents add #arguments.agent#' to add this agent" )
			return
		}

		// Update manifest
		manifest.activeAgent = arguments.agent
		writeManifest( arguments.directory, manifest )

		showSuccess( "Active agent set to: #arguments.agent#" )
		printInfo( "This setting is informational - all configured agent files remain active." )
		printInfo( "Use it to track which AI assistant you're currently working with." )
	}

}
