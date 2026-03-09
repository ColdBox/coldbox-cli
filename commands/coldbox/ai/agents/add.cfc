/**
 * Add an AI agent configuration to the project
 * Creates the agent-specific instruction file
 *
 * Examples:
 * coldbox ai agents add                (shows interactive selection)
 * coldbox ai agents add claude
 * coldbox ai agents add copilot,cursor
 */
component extends="coldbox-cli.models.BaseAICommand" {

	// DI
	property name="agentRegistry" inject="AgentRegistry@coldbox-cli";

	/**
	 * Run the command
	 *
	 * @agent The agent name(s) to add (comma-separated: claude,copilot,cursor,codex,gemini,opencode). If not provided, shows interactive selection.
	 * @directory The target directory (defaults to current directory)
	 */
	function run(
		string agent     = "",
		string directory = getCwd()
	){
		showColdBoxBanner( "Add AI Agent" )

		var info = ensureInstalled( arguments.directory )

		print.line()

		// If no agent provided, show multiselect prompt
		if ( !arguments.agent.len() ) {
			print.line()
			printWarn( "🤖 Agent Selection" )
			print.line()

			var selectedAgents = multiselect( "Select one or more AI agents to add (use spacebar to select, enter to confirm):" )
				.options( variables.agentRegistry.AGENT_OPTIONS )
				.multiple()
				.required()
				.ask()

			if ( !selectedAgents.len() ) {
				printWarn( "No agents selected." )
				return
			}

			arguments.agent = selectedAgents.toList()
		}

		// Parse comma-separated agents
		var agents      = listToArray( arguments.agent )
		var validAgents = variables.agentRegistry.SUPPORTED_AGENTS
		var toAdd       = []
		var invalid     = []

		agents.each( ( agent ) => {
			if ( validAgents.find( agent ) ) {
				toAdd.append( agent )
			} else {
				invalid.append( agent )
			}
		} )

		// Validate agent names
		if ( invalid.len() ) {
			printError( "Invalid agent name(s): #invalid.toList()#" )
			printInfo( "Valid agents: #validAgents.toList()#" )
			return
		}

		// Check which are already configured
		var alreadyConfigured = []
		toAdd.each( ( agent ) => {
			if ( info.agents.find( agent ) ) {
				alreadyConfigured.append( agent )
			}
		} )

		if ( alreadyConfigured.len() ) {
			printWarn( "Already configured: #alreadyConfigured.toList()#" )
			print.line()

			if ( !confirm( "Do you want to reconfigure these agents? [y/n]" ) ) {
				// Remove already configured from toAdd
				toAdd = toAdd.filter( ( a ) => !alreadyConfigured.find( a ) )
				if ( !toAdd.len() ) {
					printInfo( "Operation cancelled." )
					return
				}
			}
		}

		print.line()
		printInfo( "Adding agent(s): #toAdd.toList()#" )

		// Get project language from manifest
		var manifest = loadManifest( arguments.directory )
		var language = manifest.language ?: "boxlang"

		// Configure each agent
		toAdd.each( ( agent ) => {
			variables.agentRegistry.configureAgent( directory, agent, language )
			print.greenLine( "  ✓ #agent# configured" )
		} )

		// Update manifest
		toAdd.each( ( agent ) => {
			if ( !manifest.agents.find( agent ) ) {
				manifest.agents.append( agent )
			}
		} )

		// If only 1 agent is configured after adding, automatically set it as active
		if ( manifest.agents.len() == 1 ) {
			manifest.activeAgent = manifest.agents.first()
		}

		saveManifest( arguments.directory, manifest )
		print.line()
		printSuccess( "Agent(s) added successfully!" )

		// If only 1 agent total, show it was set as active
		if ( manifest.agents.len() == 1 ) {
			printSuccess( "✓ Automatically set as active agent" )
			print.line()
		}

		// Show where files were created
		var agentPaths = variables.agentRegistry.getAgentConfigPaths()
		printInfo( "Configuration files created:" )
		toAdd.each( ( agent ) => {
			print.indentedLine( " ⊕ #variables.agentRegistry.getAgentConfigPath( directory, agent )#" )
		} )

		print.line()
		printTip( "Use 'coldbox ai agents list' to see all configured agents" )
	}

}
