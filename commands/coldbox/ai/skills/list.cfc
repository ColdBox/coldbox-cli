/**
 * List all AI skills (installed and available)
 * Shows core skills, module skills, and custom skills grouped by category
 *
 * Examples:
 * coldbox ai skills list
 * coldbox ai skills list --verbose
 * coldbox ai skills list --category=testing
 */
component extends="coldbox-cli.models.BaseAICommand" {

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
		showColdBoxBanner( "Installed AI Skills" )

		var info = ensureInstalled( arguments.directory )

		// Group skills by source and category
		var coreSkills     = []
		var moduleSkills   = []
		var customSkills   = []
		var overrideSkills = []

		info.skills.each( ( skill ) => {
			var skillType   = skill.type ?: ""
			var skillSource = skill.source ?: ""

			if ( skillType == "override" ) {
				overrideSkills.append( skill )
			} else if ( skillSource == "core" ) {
				coreSkills.append( skill )
			} else if ( skillSource == "custom" || skillType == "custom" ) {
				customSkills.append( skill )
			} else {
				moduleSkills.append( skill )
			}
		} )

		// Sort all skill arrays alphabetically by name
		coreSkills.sort( ( a, b ) => compareNoCase( a.name, b.name ) )
		moduleSkills.sort( ( a, b ) => compareNoCase( a.name, b.name ) )
		customSkills.sort( ( a, b ) => compareNoCase( a.name, b.name ) )
		overrideSkills.sort( ( a, b ) => compareNoCase( a.name, b.name ) )

		// Display core skills
		if ( coreSkills.len() ) {
			print
				.lineBlackOnSeaGreen1( "⭐ Core Skills (#coreSkills.len()#)" )
				.line()
				.line()
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
			print
				.lineBlackOnSeaGreen1( "📦 Module Skills (#moduleSkills.len()#)" )
				.line()
				.line()
			var skillsByModule = {}
			moduleSkills.each( ( skill ) => {
				if ( !structKeyExists( skillsByModule, skill.source ) ) {
					skillsByModule[ skill.source ] = []
				}
				skillsByModule[ skill.source ].append( skill.name )
			} )

			structEach( skillsByModule, ( module, skills ) => {
				print.indentedLine( "  From #module#:" )
				skills.sort( "textnocase" ).each( ( skillName ) => {
					print.indentedLine( "    • #skillName#" )
				} )
			} )
			print.line()
		}

		// Display custom skills
		if ( customSkills.len() ) {
			print
				.lineBlackOnSeaGreen1( "🔧 Custom Skills (#customSkills.len()#)" )
				.line()
				.line()
			customSkills.each( ( skill ) => {
				print.indentedLine( "  • #skill.name#" )
			} )
			print.line()
		}

		// Display override skills
		if ( overrideSkills.len() ) {
			print
				.lineBlackOnSeaGreen1( "🎯 Override Skills (#overrideSkills.len()#)" )
				.line()
				.line()
			overrideSkills.each( ( skill ) => {
				var baseName = replaceNoCase( skill.name, "-override", "" )
				print.indentedLine( "  • #baseName# (overridden)" )
				if ( verbose && structKeyExists( skill, "syncedAt" ) ) {
					print.indentedLine( "    Last synced: #skill.syncedAt#" )
				}
			} )
			print.line()
		}

		// Summary
		print.line()
		printInfo( "Total: #info.skills.len()# skill(s) installed" )
		print.line()

		printTip( "Run 'coldbox ai refresh' to sync with installed modules" )
		printTip( "Run 'coldbox ai skills create <name>' to create a custom skill" )
		printTip( "Run 'coldbox ai skills override <name>' to override a core/module skill" )
	}

}
