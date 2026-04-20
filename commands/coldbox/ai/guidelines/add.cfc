/**
 * Add a specific core guideline to the project
 * Core guidelines come from coldbox-cli templates
 *
 * Examples:
 * coldbox ai guidelines add coldbox
 * coldbox ai guidelines add testbox
 * coldbox ai guidelines add wirebox
 */
component extends="coldbox-cli.models.BaseAICommand" {

	// DI
	property name="guidelineManager" inject="GuidelineManager@coldbox-cli";

	/**
	 * Run the command
	 *
	 * @name The core guideline name (e.g., coldbox, testbox, wirebox, boxlang, cfml)
	 * @directory The target directory (defaults to current directory)
	 */
	function run(
		required string name,
		string directory = getCwd()
	){
		showColdBoxBanner( "Add Guideline" )

		var info = ensureInstalled( arguments.directory )
		if ( !info.installed ) {
			return
		}

		print.line()
		printInfo( "Adding guideline: #arguments.name#" )
		print.line()

		// Validate it's a core guideline
		if ( !variables.guidelineManager.isCoreGuideline( arguments.name ) ) {
			printError( "'#arguments.name#' is not a valid core guideline." )
			print.line()
			printInfo( "Valid core guidelines: #variables.guidelineManager.CORE_GUIDELINES.toList()#" )
			print.line()
			printTip( "Module guidelines are automatically installed via 'coldbox ai refresh'" )
			return
		}

		// Check if already installed
		var existing = info.guidelines.filter( ( g ) => g.name == name )
		if ( existing.len() ) {
			var current = existing[ 1 ]
			printWarn( "Guideline '#arguments.name#' is already installed (coldbox-cli version: #current.installedVersion#)" )
			print.line()

			if ( !confirm( "Do you want to reinstall this guideline? [y/n]" ) ) {
				printInfo( "Operation cancelled." )
				return
			}
		}

		print.line()
		printInfo( "Installing core guideline '#arguments.name#'..." )

		// Install the guideline (version will be coldbox-cli version)
		variables.guidelineManager.installGuideline( arguments.directory, arguments.name )

		// Regenerate agent files
		print.line()
		printInfo( "Regenerating agent configuration files..." )
		variables.aiService.refresh( arguments.directory )

		print.line()
		printSuccess( "✓ Guideline '#arguments.name#' added successfully!" )
		print.line()
		printTip( "Use 'coldbox ai guidelines list' to see all installed guidelines" )
	}

}
