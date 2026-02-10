/**
 * Refresh guidelines from installed modules
 * Re-scans box.json and auto-discovers guidelines from all installed modules
 *
 * Examples:
 * coldbox ai guidelines refresh
 * coldbox ai guidelines refresh --verbose
 */
component extends="coldbox-cli.models.BaseAICommand" {

	// DI
	property name="guidelineManager" inject="GuidelineManager@coldbox-cli";

	/**
	 * Run the command
	 *
	 * @verbose Show detailed information about changes
	 * @directory The target directory (defaults to current directory)
	 */
	function run(
		boolean verbose  = false,
		string directory = getCwd()
	){
		showColdBoxBanner( "Refresh Guidelines" )

		var info = ensureInstalled( arguments.directory )

		print.line()
		printInfo( "Refreshing guidelines from installed modules..." )
		print.line()

		// Refresh guidelines
		var result = variables.aiService.refresh( arguments.directory )

		// Display results
		if ( result.guidelines.added.len() ) {
			printSuccess( "Added #result.guidelines.added.len()# guideline(s):" )
			result.guidelines.added.each( ( guideline ) => {
				print.greenLine( "  + #guideline#" )
			} )
			print.line()
		}

		if ( result.guidelines.updated.len() ) {
			printInfo( "Updated #result.guidelines.updated.len()# guideline(s):" )
			result.guidelines.updated.each( ( guideline ) => {
				print.blueLine( "  ↻ #guideline#" )
			} )
			print.line()
		}

		if ( result.guidelines.removed.len() ) {
			printWarn( "Removed #result.guidelines.removed.len()# guideline(s):" )
			result.guidelines.removed.each( ( guideline ) => {
				print.yellowLine( "  - #guideline#" )
			} )
			print.line()
		}

		if ( !result.guidelines.added.len() && !result.guidelines.updated.len() && !result.guidelines.removed.len() ) {
			printInfo( "No changes - all guidelines are up to date." )
			print.line()
		}

		printSuccess( "✓ Guidelines refresh complete!" )
		print.line()

		if ( arguments.verbose ) {
			print.line()
			printInfo( "Installed Guidelines Summary:" )
			print.line()

			var updatedInfo = variables.aiService.getInfo( arguments.directory )
			var coreGuidelines = updatedInfo.guidelines.filter( ( g ) => g.source == "coldbox-cli" )
			var moduleGuidelines = updatedInfo.guidelines.filter( ( g ) => g.source != "coldbox-cli" && g.source != "custom" )
			var customGuidelines = updatedInfo.guidelines.filter( ( g ) => g.source == "custom" )

			if ( coreGuidelines.len() ) {
				printInfo( "Core Guidelines ⭐: #coreGuidelines.len()#" )
			}
			if ( moduleGuidelines.len() ) {
				printInfo( "Module Guidelines 📦: #moduleGuidelines.len()#" )
			}
			if ( customGuidelines.len() ) {
				printInfo( "Custom Guidelines 🔧: #customGuidelines.len()#" )
			}
			print.line()
		}

		printTip( "Use 'coldbox ai guidelines list' to see all installed guidelines" )
	}

}
