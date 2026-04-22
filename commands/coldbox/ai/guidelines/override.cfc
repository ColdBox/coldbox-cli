/**
 * Create an override for a core or module guideline
 * Copies the guideline as a starting point for customization
 *
 * Examples:
 * coldbox ai guidelines override coldbox
 * coldbox ai guidelines override boxlang --open
 * coldbox ai guidelines override cfml --open
 */
component extends="coldbox-cli.models.BaseAICommand" {

	// DI
	property name="guidelineManager" inject="GuidelineManager@coldbox-cli";

	/**
	 * Run the command
	 *
	 * @name The guideline name to override (core or module)
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
		if ( !info.installed ) {
			return
		}

		print.line()
		printInfo( "Creating override for: #arguments.name#" )
		print.line()

		// Check if guideline exists (core or module)
		var existing = info.guidelines.filter( ( g ) => g.name == name )
		if ( !existing.len() ) {
			printError( "Guideline '#arguments.name#' not found." )
			print.line()
			printHelp( "Use 'coldbox ai guidelines list' to see available guidelines" )
			return
		}

		var guideline = existing[ 1 ]

		// Check if override already exists
		var overridePath = guidelineManager.getGuidelinesDirectory( arguments.directory ) & "/overrides/#arguments.name#.md"
		if ( fileExists( overridePath ) ) {
			printWarn( "Override for '#arguments.name#' already exists at:" )
			printWarn( "  #overridePath#" )
			print.line()

			if ( !confirm( "Do you want to overwrite it? [y/n]" ) ) {
				printInfo( "Operation cancelled." )
				return
			}
		}

		// Create override from guideline
		variables.guidelineManager.createGuidelineOverride(
			arguments.directory,
			arguments.name,
			guideline.type
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
		printInfo( "  • This override will be loaded AFTER the #guideline.type# guideline" )
		printInfo( "  • You can add project-specific rules and modifications" )
		printInfo( "  • The original guideline remains unchanged for reference" )
		printInfo( "  • Agents automatically read overrides from .ai/guidelines/overrides/" )
		print.line()

		printTip( "Edit the override to customize conventions for your project" )

		if ( arguments.open ) {
			openPath( overridePath )
		}
	}

}
