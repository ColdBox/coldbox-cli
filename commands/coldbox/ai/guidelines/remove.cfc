/**
 * Remove a specific guideline from the project
 * Requires explicit type flag to specify which guideline type to remove
 * Requires confirmation before deletion
 *
 * Examples:
 * coldbox ai guidelines remove coldbox --core
 * coldbox ai guidelines remove my-rules --custom
 * coldbox ai guidelines remove coldbox --override
 * coldbox ai guidelines remove cbsecurity --module
 * coldbox ai guidelines remove testbox --core --force
 */
component extends="coldbox-cli.models.BaseAICommand" {

	// DI
	property name="guidelineManager" inject="GuidelineManager@coldbox-cli";

	/**
	 * Run the command
	 *
	 * @name The guideline name to remove
	 * @core Remove a core guideline
	 * @module Remove a module guideline
	 * @custom Remove a custom guideline
	 * @override Remove an override guideline
	 * @force Skip confirmation prompt
	 * @directory The target directory (defaults to current directory)
	 */
	function run(
		required string name,
		boolean core     = false,
		boolean module   = false,
		boolean custom   = false,
		boolean override = false,
		boolean force    = false,
		string directory = getCwd()
	){
		showColdBoxBanner( "Remove Guideline" )

		ensureInstalled( arguments.directory )

		// Validate exactly one type flag is specified
		var typeFlags = [ arguments.core, arguments.module, arguments.custom, arguments.override ]
		var typeFlagCount = typeFlags.filter( ( flag ) => flag ).len()

		if ( typeFlagCount == 0 ) {
			printError( "You must specify a guideline type to remove." )
			print.line()
			printHelp( "Use one of: --core, --module, --custom, or --override" )
			print.line()
			printInfo( "Examples:" )
			printInfo( "  coldbox ai guidelines remove coldbox --core" )
			printInfo( "  coldbox ai guidelines remove my-rules --custom" )
			printInfo( "  coldbox ai guidelines remove coldbox --override" )
			return
		}

		if ( typeFlagCount > 1 ) {
			printError( "You can only specify one guideline type at a time." )
			return
		}

		// Determine type
		var displayType = ""
		if ( arguments.core ) displayType = "core"
		else if ( arguments.module ) displayType = "module"
		else if ( arguments.custom ) displayType = "custom"
		else if ( arguments.override ) displayType = "override"

		print.line()
		printInfo( "Removing #displayType# guideline: #arguments.name#" )
		print.line()

		// Type-specific warnings
		if ( displayType == "core" ) {
			printWarn( "⚠️  WARNING: '#arguments.name#' is a core guideline." )
			printWarn( "Removing it may reduce AI effectiveness for this framework." )
			print.line()
		} else if ( displayType == "module" ) {
			printWarn( "ℹ️  This is a module guideline." )
			printWarn( "It will be restored when you run 'coldbox ai refresh' if the module is still installed." )
			print.line()
		} else if ( displayType == "override" ) {
			printInfo( "🎯 This is an override guideline." )
			printInfo( "The original guideline will be used after removal." )
			print.line()
		} else if ( displayType == "custom" ) {
			printInfo( "🔧 This is a custom guideline." )
			printInfo( "This file will be permanently deleted." )
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
			arguments.name,
			displayType
		)

		// Regenerate agent files
		print.line()
		printInfo( "Regenerating agent configuration files..." )
		variables.aiService.refresh( arguments.directory )

		print.line()
		printSuccess( "✓ Guideline '#arguments.name#' removed successfully!" )
		print.line()

		// Type-specific tips
		if ( displayType == "module" ) {
			printTip( "Use 'coldbox ai refresh' to restore this guideline if the module is still installed" )
		} else if ( displayType == "override" ) {
			printTip( "The original '#replaceNoCase( arguments.name, "-override", "" )#' guideline is now active" )
		} else {
			printTip( "Use 'coldbox ai guidelines list' to see remaining guidelines" )
		}
	}

}
