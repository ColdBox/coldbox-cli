/**
 * Refresh skills from installed modules
 * Re-scans box.json and auto-discovers skills from all installed modules
 *
 * Examples:
 * coldbox ai skills refresh
 * coldbox ai skills refresh --verbose
 */
component extends="coldbox-cli.models.BaseAICommand" {

	// DI
	property name="skillManager" inject="SkillManager@coldbox-cli";

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

		var info = ensureInstalled( arguments.directory )
		if( !info.installed ){
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

			var updatedInfo    = ensureInstalled( arguments.directory )
			var registrySkills = updatedInfo.skills.filter( ( s ) => ( s.type ?: "" ) != "custom" )
			var customSkills   = updatedInfo.skills.filter( ( s ) => ( s.type ?: "" ) == "custom" )

			// Tally by owner/repo
			var byRepo = {}
			registrySkills.each( ( s ) => {
				var key       = ( ( s.owner ?: "" ) != "" ) ? "#s.owner#/#s.repo#" : "unknown"
				byRepo[ key ] = ( byRepo[ key ] ?: 0 ) + 1
			} )
			byRepo.each( ( repo, count ) => printInfo( "  📦 #repo#: #count# skill(s)" ) )
			if ( customSkills.len() ) {
				printInfo( "  🔧 Custom: #customSkills.len()# skill(s)" )
			}
			print.line()
		}

		printTip( "Use 'coldbox ai skills list' to see all installed skills" )
	}

}
