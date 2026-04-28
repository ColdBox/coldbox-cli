/**
 * Create a custom guideline template
 * Scaffolds a new guideline in .agents/guidelines/custom/
 *
 * Examples:
 * coldbox ai guidelines create my-conventions
 * coldbox ai guidelines create team-standards --open
 */
component extends="coldbox-cli.models.BaseAICommand" {

	// DI
	property name="guidelineManager" inject="GuidelineManager@coldbox-cli";

	/**
	 * Run the command
	 *
	 * @name The custom guideline name
	 * @open Open the created file in the default editor
	 * @directory The target directory (defaults to current directory)
	 */
	function run(
		required string name,
		boolean open     = false,
		string directory = getCwd()
	){
		showColdBoxBanner( "Create Custom Guideline" )

		var info = ensureInstalled( arguments.directory )
		if ( !info.installed ) {
			return
		}

		print.line()
		printInfo( "Creating custom guideline: #arguments.name#" )
		print.line()

		// Check if already exists
		var guidelinePath = guidelineManager.getGuidelinesDirectory( arguments.directory ) & "/custom/#arguments.name#.md"
		if ( fileExists( guidelinePath ) ) {
			printError( "Guideline '#arguments.name#' already exists at:" )
			printError( "  #guidelinePath#" )
			print.line()

			if ( !confirm( "Do you want to overwrite it? [y/n]" ) ) {
				printInfo( "Operation cancelled." )
				return
			}
		}

		// Create guideline from template
		variables.guidelineManager.createCustomGuideline( arguments.directory, arguments.name )

		// Regenerate agent files
		print.line()
		printInfo( "Regenerating agent configuration files..." )
		variables.aiService.refresh( arguments.directory )

		print.line()
		printSuccess( "✓ Custom guideline created at:" )
		printSuccess( "  #guidelinePath#" )
		print.line()

		printHelp( "Edit the guideline file to add your team's conventions and standards." )
		printHelp( "Guidelines support markdown formatting and code examples." )

		if ( arguments.open ) {
			openPath( guidelinePath )
		}
	}

}
