/**
 * Remove a specific skill from the project
 * Requires explicit type flag to specify which skill type to remove
 * Requires confirmation before deletion
 *
 * Examples:
 * coldbox ai skills remove handler-development --core
 * coldbox ai skills remove api-patterns --custom
 * coldbox ai skills remove handler-development --override
 * coldbox ai skills remove security-implementation --module
 * coldbox ai skills remove testing-bdd --core --force
 */
component extends="coldbox-cli.models.BaseAICommand" {

	// DI
	property name="skillManager" inject="SkillManager@coldbox-cli";

	/**
	 * Run the command
	 *
	 * @name The skill name to remove
	 * @core Remove a core skill
	 * @module Remove a module skill
	 * @custom Remove a custom skill
	 * @override Remove an override skill
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
		showColdBoxBanner( "Remove Skill" )

		ensureInstalled( arguments.directory )

		// Validate exactly one type flag is specified
		var typeFlags = [
			arguments.core,
			arguments.module,
			arguments.custom,
			arguments.override
		]
		var typeFlagCount = typeFlags.filter( ( flag ) => flag ).len()

		if ( typeFlagCount == 0 ) {
			printError( "You must specify a skill type to remove." )
			print.line()
			printHelp( "Use one of: --core, --module, --custom, or --override" )
			print.line()
			printInfo( "Examples:" )
			printInfo( "  coldbox ai skills remove handler-development --core" )
			printInfo( "  coldbox ai skills remove api-patterns --custom" )
			printInfo( "  coldbox ai skills remove handler-development --override" )
			printInfo( "  coldbox ai skills remove security-implementation --module" )
			return
		}

		if ( typeFlagCount > 1 ) {
			printError( "You can only specify one skill type at a time." )
			return
		}

		// Determine type
		var displayType = "";
		if ( arguments.core ) {
			displayType = "core";
		} else if ( arguments.module ) {
			displayType = "module";
		} else if ( arguments.custom ) {
			displayType = "custom";
		} else if ( arguments.override ) {
			displayType = "override";
		}

		print.line()
		printInfo( "Removing #displayType# skill: #arguments.name#" )
		print.line()

		// Type-specific warnings
		if ( displayType == "core" ) {
			printWarn( "⚠️  WARNING: '#arguments.name#' is a core skill." )
			printWarn( "Removing it may reduce AI effectiveness for common tasks." )
			print.line()
		} else if ( displayType == "module" ) {
			printWarn( "ℹ️  This is a module skill." )
			printWarn( "It will be restored when you run 'coldbox ai refresh' if the module is still installed." )
			print.line()
		} else if ( displayType == "override" ) {
			printInfo( "🎯 This is an override skill." )
			printInfo( "The original skill will be used after removal." )
			print.line()
		} else if ( displayType == "custom" ) {
			printInfo( "🔧 This is a custom skill." )
			printInfo( "This directory will be permanently deleted." )
			print.line()
		}

		// Confirm deletion
		if ( !arguments.force ) {
			if ( !confirm( "Are you sure you want to remove '#arguments.name#'? [y/n]" ) ) {
				printInfo( "Operation cancelled." )
				return
			}
		}

		// Remove the skill
		try {
			variables.skillManager.removeSkillFromProject(
				arguments.directory,
				arguments.name,
				displayType
			)
		} catch ( any e ) {
			printError( "Failed to remove skill: #e.message#" )
			print.line()
			if ( e.type == "SkillManager.SkillNotFound" ) {
				printTip( "Use 'coldbox ai skills list' to see available skills" )
			}
			return
		}

		// Regenerate agent files
		print.line()
		printInfo( "Regenerating agent configuration files..." )
		variables.aiService.refresh( arguments.directory )

		print.line()
		printSuccess( "✓ Skill '#arguments.name#' removed successfully!" )
		print.line()

		// Type-specific tips
		if ( displayType == "module" ) {
			printTip( "Use 'coldbox ai refresh' to restore this skill if the module is still installed" )
		} else if ( displayType == "override" ) {
			printTip( "The original '#replaceNoCase( arguments.name, "-override", "" )#' skill is now active" )
		} else if ( displayType == "core" ) {
			printTip( "Use 'coldbox ai refresh' to restore core skills" )
		} else {
			printTip( "Use 'coldbox ai skills list' to see remaining skills" )
		}
	}

}
