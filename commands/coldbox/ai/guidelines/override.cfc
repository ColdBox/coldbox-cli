/**
 * Create an override for a core guideline
 * Copies the core guideline as a starting point for customization
 *
 * Examples:
 * coldbox ai guidelines override coldbox
 * coldbox ai guidelines override testbox --open
 */
component extends="coldbox-cli.models.BaseAICommand" {

	// DI
	property name="guidelineManager" inject="GuidelineManager@coldbox-cli";

	/**
	 * Run the command
	 *
	 * @name The core guideline name to override
	 * @open Open the created override file in the default editor
	 * @directory The target directory (defaults to current directory)
	 */
	function run(
		required string name,
		boolean open     = false,
		string directory = getCwd()
	){
		showColdBoxBanner( "Override Guideline" )

		var info = ensureInstalled( arguments.directory )

		print.line()
		printInfo( "Creating override for: #arguments.name#" )
		print.line()

		// Check if core guideline exists
		var existing = info.guidelines.filter( ( g ) => g.name == arguments.name && g.source == "core" )
		if ( !existing.len() ) {
			printError( "Core guideline '#arguments.name#' not found." )
			print.line()
			printHelp( "Use 'coldbox ai guidelines list' to see available core guidelines" )
			return
		}

		// Check if override already exists
		var overridePath = "#arguments.directory#/.ai/guidelines/custom/#arguments.name#-override.md"
		if ( fileExists( overridePath ) ) {
			printWarn( "Override for '#arguments.name#' already exists at:" )
			printWarn( "  #overridePath#" )
			print.line()

			if ( !confirm( "Do you want to overwrite it? [y/n]" ) ) {
				printInfo( "Operation cancelled." )
				return
			}
		}

		// Create override from core guideline
		variables.guidelineManager.createGuidelineOverride(
			arguments.directory,
			arguments.name
		)

		// Update manifest
		variables.aiService.updateManifest(
			arguments.directory,
			{ "lastSync": dateTimeFormat( now(), "iso" ) }
		)

		// Regenerate agent files
		print.line()
		printInfo( "Regenerating agent configuration files..." )
		variables.aiService.refresh( arguments.directory )

		print.line()
		printSuccess( "✓ Override created at:" )
		printSuccess( "  #overridePath#" )
		print.line()

		printInfo( "Override Guidelines:" )
		printInfo( "  • This override will be loaded AFTER the core guideline" )
		printInfo( "  • You can add project-specific rules and modifications" )
		printInfo( "  • The core guideline remains unchanged for reference" )
		print.line()

		printHelp( "Tip: Edit the override to customize conventions for your project" )

		if ( arguments.open ) {
			openPath( overridePath )
		}
	}

}
