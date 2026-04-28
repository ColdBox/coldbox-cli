/**
 * Uninstall AI integration from a ColdBox application
 * Removes the .ai directory and all AI configuration
 *
 * Examples:
 * coldbox ai uninstall
 * coldbox ai uninstall --force
 */
component extends="coldbox-cli.models.BaseAICommand" {

	/**
	 * Run the command
	 *
	 * @force Skip confirmation prompt
	 * @directory The target directory (defaults to current directory)
	 * @showBanner Whether to show the ColdBox banner (default: true)
	 */
	function run(
		boolean force      = false,
		string directory   = getCwd(),
		boolean showBanner = true
	){
		if ( arguments.showBanner ) {
			showColdBoxBanner( "AI Integration Uninstaller" )
		}

		var aiDirectory = "#arguments.directory#/.ai"

		// Check if .ai directory exists
		if ( !directoryExists( aiDirectory ) ) {
			printWarn( "No AI integration found in this project." )
			return
		}

		// Confirm uninstall unless force flag is set
		if ( !arguments.force ) {
			print.line()
			printWarn( "⚠️  This will permanently delete the .ai directory and all AI configuration." )
			print.line()

			var confirmed = confirm( "Are you sure you want to uninstall AI integration? [y/N]: " )

			if ( !confirmed ) {
				printInfo( "Uninstall cancelled." )
				return
			}
		}

		try {
			printInfo( "🗑️  Removing AI integration..." )
			directoryDelete( aiDirectory, true )
			printSuccess( "✓ AI integration uninstalled successfully!" )
			printTip( "To reinstall AI integration, run: coldbox ai install" )
		} catch ( any e ) {
			printError( "Failed to uninstall AI integration: #e.message#" )
			printError( e.stackTrace )
		}
	}

}
