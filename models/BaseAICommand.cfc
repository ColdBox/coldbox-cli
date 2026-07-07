/**
 * Base command for all AI-related CLI commands
 * Provides common functionality for checking installation status,
 * reading/writing manifests, and consistent error handling
 */
component extends="coldbox-cli.models.BaseCommand" {

	// DI - All AI commands need these services
	property name="aiService"     inject="AIService@coldbox-cli";
	property name="agentRegistry" inject="AgentRegistry@coldbox-cli";
	property name="formatterUtil" inject="Formatter";

	/**
	 * Ensures AI integration is installed and returns info
	 * Exits command if not installed with appropriate error message
	 *
	 * @directory The target directory to check
	 *
	 * @return The info struct from aiService.getInfo()
	 */
	function ensureInstalled( required string directory ){
		var info = variables.aiService.getInfo( arguments.directory )

		if ( !info.installed ) {
			printError( "AI integration not installed. Run 'coldbox ai install' first." )
		}

		return info
	}

	/**
	 * Gets the AI installation directory path (.agents)
	 *
	 * @directory The target directory
	 *
	 * @return The full path to the .agents directory
	 */
	function getAIInstallDirectory( required string directory ){
		return variables.aiService.getAIInstallDirectory( arguments.directory )
	}

	/**
	 * Gets the manifest file path for a directory
	 *
	 * @directory The target directory
	 *
	 * @return The full path to the manifest file
	 */
	function getManifestPath( required string directory ){
		return variables.aiService.getManifestPath( arguments.directory )
	}

	/**
	 * Reads and deserializes the manifest file
	 *
	 * @directory The target directory
	 *
	 * @return The deserialized manifest struct
	 */
	function loadManifest( required string directory ){
		return variables.aiService.loadManifest( arguments.directory )
	}

	/**
	 * Writes the manifest file with updated content
	 *
	 * @directory The target directory
	 * @manifest The manifest struct to write
	 */
	function saveManifest(
		required string directory,
		required struct manifest
	){
		variables.aiService.saveManifest(
			arguments.directory,
			arguments.manifest
		)
	}

	/**
	 * Generates (or regenerates) the root .mcp.json from the manifest's mcpServers.
	 * Delegates to AIService.generateMCPJson().
	 *
	 * @directory The project root directory
	 * @manifest  The current manifest struct
	 */
	function generateMCPJson(
		required string directory,
		required struct manifest
	){
		variables.aiService.generateMCPJson(
			arguments.directory,
			arguments.manifest
		)
	}

	/**
	 * Detects existing agent configuration files that lack managed section markers
	 * and prompts the user to choose how to handle them.
	 *
	 * Returns the conflict resolution strategy: "overwrite", "merge", or "skip".
	 * If no conflicts exist or --force is used, returns "overwrite" without prompting.
	 *
	 * @directory The project directory
	 * @agents Comma-separated list of agents to check
	 * @force If true, skip prompting and return "overwrite"
	 *
	 * @return The conflict resolution strategy string
	 */
	function promptForConflictResolution(
		required string directory,
		required string agents,
		boolean force = false
	){
		var conflicts = variables.agentRegistry.detectAgentFileConflicts(
			arguments.directory,
			arguments.agents
		)

		if ( !conflicts.len() || arguments.force ) {
			return "overwrite"
		}

		print.line()
		printWarn( "⚠️  Existing Agent Files Detected" )
		print.line()

		conflicts.each( ( conflict ) => {
			print.indentedLine( "  • #conflict.agent#: #conflict.filePath#" )
		} )

		print.line()
		print.indentedLine( "These files exist but were not created by ColdBox CLI." )
		print.indentedLine( "Choose how to handle them:" )
		print.line()

		var resolutionOptions = [
			{
				"display" : "Overwrite - Replace all files with ColdBox CLI content",
				"value"   : "overwrite"
			},
			{
				"display" : "Merge - Keep existing content below managed section",
				"value"   : "merge"
			},
			{
				"display" : "Skip - Don't modify existing files",
				"value"   : "skip"
			}
		]

		return multiSelect( "How should we handle these files?" )
			.options( resolutionOptions )
			.required()
			.ask()
	}

}
