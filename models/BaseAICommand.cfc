/**
 * Base command for all AI-related CLI commands
 * Provides common functionality for checking installation status,
 * reading/writing manifests, and consistent error handling
 */
component extends="coldbox-cli.models.BaseCommand" {

	// DI - All AI commands need these services
	property name="aiService" inject="AIService@coldbox-cli";

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
			abort
		}

		return info
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

}
