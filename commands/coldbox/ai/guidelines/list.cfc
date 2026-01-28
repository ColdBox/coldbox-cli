/**
 * List all AI guidelines (installed and available)
 * Shows core guidelines, module guidelines, and custom guidelines
 *
 * Examples:
 * coldbox ai guidelines list
 * coldbox ai guidelines list --verbose
 */
component extends="coldbox-cli.models.BaseCommand" {

	// DI
	property name="aiService" inject="AIService@coldbox-cli"

	/**
	 * Run the command
	 *
	 * @verbose Show detailed information
	 * @directory The target directory (defaults to current directory)
	 */
	function run(
		boolean verbose  = false,
		string directory = getCwd()
	){
		showColdBoxBanner( "AI Guidelines" )

		try {
			var info = variables.aiService.getInfo( arguments.directory )

			if ( !info.installed ) {
				printError( "AI integration not installed. Run 'coldbox ai install' first." )
				return
			}

			print.line()
			printInfo( "Installed Guidelines" )
			print.line()

			// Group guidelines by source
			var coreGuidelines   = []
			var moduleGuidelines = []
			var customGuidelines = []

			info.guidelines.each( ( guideline ) => {
				if ( guideline.source == "coldbox-cli" ) {
					coreGuidelines.append( guideline )
				} else if ( guideline.source == "custom" ) {
					customGuidelines.append( guideline )
				} else {
					moduleGuidelines.append( guideline )
				}
			} )

			// Display core guidelines
			if ( coreGuidelines.len() ) {
				printSuccess( "⭐ Core Guidelines (#coreGuidelines.len()#)" )
				coreGuidelines.each( ( guideline ) => {
					print.indentedLine( "  • #guideline.name# (v#guideline.installedVersion#)" )
					if ( arguments.verbose && structKeyExists( guideline, "syncedAt" ) ) {
						print.indentedLine( "    Last synced: #guideline.syncedAt#" )
					}
				} )
				print.line()
			}

			// Display module guidelines
			if ( moduleGuidelines.len() ) {
				printInfo( "📦 Module Guidelines (#moduleGuidelines.len()#)" )
				moduleGuidelines.each( ( guideline ) => {
					print.indentedLine( "  • #guideline.name# (from #guideline.source#)" )
					if ( arguments.verbose && structKeyExists( guideline, "syncedAt" ) ) {
						print.indentedLine( "    Last synced: #guideline.syncedAt#" )
					}
				} )
				print.line()
			}

			// Display custom guidelines
			if ( customGuidelines.len() ) {
				printWarn( "🔧 Custom Guidelines (#customGuidelines.len()#)" )
				customGuidelines.each( ( guideline ) => {
					print.indentedLine( "  • #guideline.name#" )
					if ( arguments.verbose && structKeyExists( guideline, "syncedAt" ) ) {
						print.indentedLine( "    Last synced: #guideline.syncedAt#" )
					}
				} )
				print.line()
			}

			// Summary
			print.line()
			printInfo( "Total: #info.guidelines.len()# guideline(s) installed" )
			print.line()

			printHelp( "Tip: Run 'coldbox ai refresh' to sync with installed modules" )
		} catch ( any e ) {
			printError( "Failed to list guidelines: #e.message#" )
			if ( arguments.verbose ) {
				printError( e.stackTrace )
			}
		}
	}

}
