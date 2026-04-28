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
	 * @set If true, will prompt to set an active agent if none is currently set
	 *     (only applies when no agent argument is provided)
	 *     This is useful for the case where a user wants to set an active agent but	 forgot to provide the agent name as an argument - it will prompt them to select from configured agents
	 */
	function run(
		string agent     = "",
		string directory = getCwd(),
		boolean set      = false
	){
		showColdBoxBanner( "Active AI Agent" )

		var info = ensureInstalled( arguments.directory )
		if ( !info.installed ) {
			return
		}
		var manifest = loadManifest( arguments.directory )

		print.line()

		// If no agent specified, show current active
		if ( !arguments.agent.len() || arguments.set ) {
			var activeAgent = manifest.activeAgent ?: "none"

			if ( activeAgent == "none" || arguments.set ) {
				printWarn( "No active agent is currently set." )
				print.toConsole()

				// If agents are configured, prompt to set one
				if ( info.agents.len() ) {
					var selectedAgent = multiSelect( "Which agent would you like to set as active?" )
						.options(
							info.agents.map( ( agent ) => {
								return { display : agent, value : agent }
							} )
						)
						.required()
						.ask()

					if ( selectedAgent.len() ) {
						// Set the selected agent as active
						manifest[ "activeAgent" ] = selectedAgent
						saveManifest( arguments.directory, manifest )

						print.line()
						printSuccess( "Active agent set to: #selectedAgent#" )
						printInfo( "This setting is informational - all configured agent files remain active." )
						printInfo( "Use it to track which AI assistant you're currently working with." )
					}
				} else {
					printInfo( "No agents configured yet." )
					print.line()
					printTip( "Use 'coldbox ai agents add' to configure AI agents" )
				}
				return
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
						print.line( "  ⊕ #agent#" )
					}
				} )
			}

			print.line()
			printTip( "Use 'coldbox ai agents active <name>' to set the active agent" )
			return
		}

		// Set new active agent
		if ( !info.agents.find( arguments.agent ) ) {
			printError( "Agent '#arguments.agent#' is not configured." )
			print.line()
			printTip( "Use 'coldbox ai agents list' to see configured agents" )
			printTip( "Use 'coldbox ai agents add #arguments.agent#' to add this agent" )
			return
		}

		// Update manifest
		manifest[ "activeAgent" ] = arguments.agent
		saveManifest( arguments.directory, manifest )

		printSuccess( "Active agent set to: #arguments.agent#" )
		printInfo( "This setting is informational - all configured agent files remain active." )
		printInfo( "Use it to track which AI assistant you're currently working with." )
	}

}
