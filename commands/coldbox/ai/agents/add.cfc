/**
 * Add an AI agent configuration to the project
 * Creates the agent-specific instruction file
 *
 * Examples:
 * coldbox ai agents add claude
 * coldbox ai agents add copilot,cursor
 */
component extends="coldbox-cli.models.BaseAICommand" {

	// DI
	property name="agentRegistry" inject="AgentRegistry@coldbox-cli";

	/**
	 * Run the command
	 *
	 * @agent The agent name(s) to add (comma-separated: claude,copilot,cursor,codex,gemini,opencode)
	 * @directory The target directory (defaults to current directory)
	 */
	function run(
		required string agent,
		string directory = getCwd()
	){
		showColdBoxBanner( "Add AI Agent" )

		var info = ensureInstalled( arguments.directory )

		print.line()

		// Parse comma-separated agents
		var agents = listToArray( arguments.agent )
		var validAgents = [ "claude", "copilot", "cursor", "codex", "gemini", "opencode" ]
		var toAdd = []
		var invalid = []

		agents.each( ( agent ) => {
			if ( validAgents.find( agent ) ) {
				toAdd.append( agent )
			} else {
				invalid.append( agent )
			}
		} )

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

		printInfo( "Adding agent(s): #toAdd.toList()#" )
		print.line()

		// Get project language from manifest
		var manifest = readManifest( arguments.directory )
		var language = manifest.language ?: "boxlang"

		// Configure each agent
		toAdd.each( ( agent ) => {
			variables.agentRegistry.configureAgent(
				arguments.directory,
				agent,
				language
			)
			print.greenLine( "  ✓ #agent# configured" )
		} )

		// Update manifest
		toAdd.each( ( agent ) => {
			if ( !manifest.agents.find( agent ) ) {
				manifest.agents.append( agent )
			}
		} )

		writeManifest( arguments.directory, manifest )

		showSuccess( "Agent(s) added successfully!" )

		// Show where files were created
		var agentPaths = variables.agentRegistry.getAgentConfigPaths()
		printInfo( "Configuration files created:" )
		toAdd.each( ( agent ) => {
			var path = agentPaths[ agent ] ?: "AI_INSTRUCTIONS.md"
			print.indentedLine( "  #path#" )
		} )

		print.line()
		printHelp( "Tip: Use 'coldbox ai agents list' to see all configured agents" )
	}

}
