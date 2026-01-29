/**
 * List all AI skills (installed and available)
 * Shows core skills, module skills, and custom skills grouped by category
 *
 * Examples:
 * coldbox ai skills list
 * coldbox ai skills list --verbose
 * coldbox ai skills list --category=testing
 */
component extends="coldbox-cli.models.BaseCommand" {

	// DI
	property name="aiService" inject="AIService@coldbox-cli";

	/**
	 * Run the command
	 *
	 * @verbose Show detailed information
	 * @category Filter by category (core, testing, security, orm, modern)
	 * @directory The target directory (defaults to current directory)
	 */
	function run(
		boolean verbose  = false,
		string category  = "",
		string directory = getCwd()
	){
		showColdBoxBanner( "AI Skills" )

		var info = variables.aiService.getInfo( arguments.directory )

		if ( !info.installed ) {
			printError( "AI integration not installed. Run 'coldbox ai install' first." )
			return
		}

		print.line()
		printInfo( "Installed Skills" )
		print.line()

		// Group skills by source and category
		var coreSkills   = []
		var moduleSkills = []
		var customSkills = []

		info.skills.each( ( skill ) => {
			if ( skill.source == "core" ) {
				coreSkills.append( skill )
			} else if ( skill.source == "custom" ) {
				customSkills.append( skill )
			} else {
				moduleSkills.append( skill )
			}
		} )

		// Display core skills
		if ( coreSkills.len() ) {
			printSuccess( "⭐ Core Skills (#coreSkills.len()#)" )
			printHelp( "  Always available - covering ColdBox, BoxLang, CFML, and Testing" )
			if ( verbose ) {
				coreSkills.each( ( skill ) => {
					print.indentedLine( "  • #skill.name#" )
				} )
			}
			print.line()
		}

		// Display module skills
		if ( moduleSkills.len() ) {
			printInfo( "📦 Module Skills (#moduleSkills.len()#)" )
			var skillsByModule = {}
			moduleSkills.each( ( skill ) => {
				if ( !structKeyExists( skillsByModule, skill.source ) ) {
					skillsByModule[ skill.source ] = []
				}
				skillsByModule[ skill.source ].append( skill.name )
			} )

			structEach( skillsByModule, ( module, skills ) => {
				print.indentedLine( "  From #module#:" )
				skills.each( ( skillName ) => {
					print.indentedLine( "    • #skillName#" )
				} )
			} )
			print.line()
		}

		// Display custom skills
		if ( customSkills.len() ) {
			printWarn( "🔧 Custom Skills (#customSkills.len()#)" )
			customSkills.each( ( skill ) => {
				print.indentedLine( "  • #skill.name#" )
			} )
			print.line()
		}

		// Summary
		print.line()
		printInfo( "Total: #info.skills.len()# skill(s) installed" )
		print.line()

		printHelp( "Tip: Run 'coldbox ai refresh' to sync with installed modules" )
		printHelp( "Tip: Run 'coldbox ai skills create <name>' to create a custom skill" )
	}
}
