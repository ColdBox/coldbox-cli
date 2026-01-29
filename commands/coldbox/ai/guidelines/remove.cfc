/**
 * Remove a specific guideline from the project
 * Requires confirmation before deletion
 *
 * Examples:
 * coldbox ai guidelines remove testbox
 * coldbox ai guidelines remove coldbox --force
 */
component extends="coldbox-cli.models.BaseAICommand" {

	// DI
	property name="guidelineManager" inject="GuidelineManager@coldbox-cli";

	/**
	 * Run the command
	 *
	 * @name The guideline name to remove
	 * @force Skip confirmation prompt
	 * @directory The target directory (defaults to current directory)
	 */
	function run(
		required string name,
		boolean force    = false,
		string directory = getCwd()
	){
		showColdBoxBanner( "Remove Guideline" )

		var info = ensureInstalled( arguments.directory )

		print.line()
		printInfo( "Removing guideline: #arguments.name#" )
		print.line()

		// Check if guideline exists
		var existing = info.guidelines.filter( ( g ) => g.name == arguments.name )
		if ( !existing.len() ) {
			printError( "Guideline '#arguments.name#' is not installed." )
			print.line()
			printHelp( "Use 'coldbox ai guidelines list' to see installed guidelines" )
			return
		}

		var guideline = existing[ 1 ]

		// Warn if core guideline
		if ( guideline.source == "core" ) {
			printWarn( "WARNING: '#arguments.name#' is a core guideline." )
			printWarn( "Removing it may reduce AI effectiveness for this framework." )
			print.line()
		}

		// Confirm deletion
		if ( !arguments.force ) {
			if ( !confirm( "Are you sure you want to remove '#arguments.name#'? [y/n]" ) ) {
				printInfo( "Operation cancelled." )
				return
			}
		}

		// Remove the guideline
		variables.guidelineManager.removeGuideline(
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
		printSuccess( "✓ Guideline '#arguments.name#' removed successfully!" )
		print.line()
		printHelp( "Tip: Use 'coldbox ai refresh' to sync guidelines with installed modules" )
	}

}
