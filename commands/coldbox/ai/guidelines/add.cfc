/**
 * Add a specific guideline to the project
 * Can specify version or auto-detect from box.json
 *
 * Examples:
 * coldbox ai guidelines add coldbox
 * coldbox ai guidelines add coldbox@8.x
 * coldbox ai guidelines add testbox@6.0.0
 */
component extends="coldbox-cli.models.BaseAICommand" {

	// DI
	property name="guidelineManager" inject="GuidelineManager@coldbox-cli";

	/**
	 * Run the command
	 *
	 * @name The guideline name (e.g., coldbox, testbox, wirebox)
	 * @version Optional version override (e.g., 8.x, 6.0.0)
	 * @directory The target directory (defaults to current directory)
	 */
	function run(
		required string name,
		string version   = "",
		string directory = getCwd()
	){
		showColdBoxBanner( "Add Guideline" )

		var info = ensureInstalled( arguments.directory )

		print.line()
		printInfo( "Adding guideline: #arguments.name#" )
		print.line()

		// Check if already installed
		var existing = info.guidelines.filter( ( g ) => g.name == name )
		if ( existing.len() ) {
			var current = existing[ 1 ]
			printWarn( "Guideline '#arguments.name#' is already installed (version: #current.version#)" )
			print.line()

			if ( !confirm( "Do you want to update/reinstall this guideline? [y/n]" ) ) {
				printInfo( "Operation cancelled." )
				return
			}
		}

		// Determine version
		var targetVersion = arguments.version
		if ( !targetVersion.len() ) {
			// Auto-detect from box.json
			targetVersion = variables.guidelineManager.detectModuleVersion(
				arguments.directory,
				arguments.name
			)

			if ( !targetVersion.len() ) {
				printWarn( "Could not auto-detect version for '#arguments.name#'" )
				targetVersion = ask( "Enter version (or press enter for 'latest'): " )
				if ( !targetVersion.len() ) {
					targetVersion = "latest"
				}
			}
		}

		printInfo( "Installing guideline '#arguments.name#' version: #targetVersion#" )

		// Install the guideline
		variables.guidelineManager.installGuideline(
			arguments.directory,
			arguments.name,
			targetVersion
		)

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
