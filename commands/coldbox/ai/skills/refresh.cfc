/**
 * Refresh skills from installed modules
 * Re-scans box.json and auto-discovers skills from all installed modules
 *
 * Examples:
 * coldbox ai skills refresh
 * coldbox ai skills refresh --verbose
 */
component extends="coldbox-cli.models.BaseCommand" {

	// DI
	property name="skillManager" inject="SkillManager@coldbox-cli";
	property name="aiService"    inject="AIService@coldbox-cli";

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
		showColdBoxBanner( "Refresh Skills" )

		var info = variables.aiService.getInfo( arguments.directory )

		if ( !info.installed ) {
			printError( "AI integration not installed. Run 'coldbox ai install' first." )
			return
		}

		print.line()
		printInfo( "Refreshing skills from installed modules..." )
		print.line()

		// Refresh skills
		var result = variables.aiService.refresh( arguments.directory )

		// Display results
		if ( result.skills.added.len() ) {
			printSuccess( "Added #result.skills.added.len()# skill(s):" )
			result.skills.added.each( ( skill ) => {
				print.greenLine( "  + #skill#" )
			} )
			print.line()
		}

		if ( result.skills.updated.len() ) {
			printInfo( "Updated #result.skills.updated.len()# skill(s):" )
			result.skills.updated.each( ( skill ) => {
				print.blueLine( "  ↻ #skill#" )
			} )
			print.line()
		}

		if ( result.skills.removed.len() ) {
			printWarn( "Removed #result.skills.removed.len()# skill(s):" )
			result.skills.removed.each( ( skill ) => {
				print.yellowLine( "  - #skill#" )
			} )
			print.line()
		}

		if ( !result.skills.added.len() && !result.skills.updated.len() && !result.skills.removed.len() ) {
			printInfo( "No changes - all skills are up to date." )
			print.line()
		}

		printSuccess( "✓ Skills refresh complete!" )
		print.line()

		if ( arguments.verbose ) {
			print.line()
			printInfo( "Installed Skills Summary:" )
			print.line()

			var updatedInfo = variables.aiService.getInfo( arguments.directory )
			var coreSkills = updatedInfo.skills.filter( ( s ) => s.source == "coldbox-cli" )
			var moduleSkills = updatedInfo.skills.filter( ( s ) => s.source != "coldbox-cli" && s.source != "custom" )
			var customSkills = updatedInfo.skills.filter( ( s ) => s.source == "custom" )

			if ( coreSkills.len() ) {
				printInfo( "Core Skills ⭐: #coreSkills.len()#" )
			}
			if ( moduleSkills.len() ) {
				printInfo( "Module Skills 📦: #moduleSkills.len()#" )
			}
			if ( customSkills.len() ) {
				printInfo( "Custom Skills 🔧: #customSkills.len()#" )
			}
			print.line()
		}

		printHelp( "Tip: Use 'coldbox ai skills list' to see all installed skills" )
	}

}
