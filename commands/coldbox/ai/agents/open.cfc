/**
 * Open the active AI agent configuration file in your editor
 *
 * Examples:
 * coldbox ai agents open
 * coldbox ai agents open claude  (open specific agent config)
 */
component extends="coldbox-cli.models.BaseAICommand" {

	// DI
	property name="agentRegistry" inject="AgentRegistry@coldbox-cli";

	/**
	 * Run the command
	 *
	 * @agent Optional agent name to open (defaults to active agent)
	 * @directory The target directory (defaults to current directory)
	 */
	function run(
		string agent     = "",
		string directory = getCwd()
	){
		showColdBoxBanner( "Open Agent Config" )

		var info     = ensureInstalled( arguments.directory )
		if( !info.installed ){
			return
		}
		var manifest = loadManifest( arguments.directory )

		print.line()

		// Determine which agent to open
		var agentToOpen = ""

		if ( arguments.agent.len() ) {
			// Specific agent requested
			agentToOpen = arguments.agent

			// Check if agent is configured
			if ( !info.agents.find( agentToOpen ) ) {
				printError( "Agent '#agentToOpen#' is not configured." )
				print.line()
				printTip( "Use 'coldbox ai agents list' to see configured agents" )
				printTip( "Use 'coldbox ai agents add #agentToOpen#' to add this agent" )
				return
			}
		} else {
			// Use active agent
			var activeAgent = manifest.activeAgent ?: "none"

			if ( activeAgent == "none" ) {
				printWarn( "No active agent is set." )
				print.line()

				// If only one agent configured, use it
				if ( info.agents.len() == 1 ) {
					agentToOpen = info.agents[ 1 ]
					printInfo( "Opening configured agent: #agentToOpen#" )
					print.line()
				} else if ( info.agents.len() > 1 ) {
					// Prompt to select
					agentToOpen = multiSelect( "Which agent configuration would you like to open?" )
						.options(
							info.agents.map( ( agent ) => {
								return { display : agent, value : agent }
							} )
						)
						.required()
						.ask()

					if ( !agentToOpen.len() ) {
						return
					}
				} else {
					printError( "No agents configured yet." )
					print.line()
					printTip( "Use 'coldbox ai agents add' to configure AI agents" )
					return
				}
			} else {
				agentToOpen = activeAgent
			}
		}

		// Get the config file path
		var configPath = variables.agentRegistry.getAgentConfigPath( arguments.directory, agentToOpen )

		// Check if file exists
		if ( !fileExists( configPath ) ) {
			printError( "Agent config file not found: #configPath#" )
			print.line()
			printTip( "Run 'coldbox ai refresh' to regenerate agent configuration files" )
			return
		}

		// Open the file
		printInfo( "Opening #agentToOpen# configuration..." )
		print.line()
		openPath( configPath )
	}

}
