/**
 * Search the skills registry and display matching skills.
 * Use this to discover skills before installing them.
 *
 * Examples:
 *   coldbox ai skills find
 *   coldbox ai skills find testing
 *   coldbox ai skills find --owner=ortus-boxlang
 *   coldbox ai skills find --owner=coldbox --repo=skills
 *   coldbox ai skills find boxlang --owner=ortus-boxlang
 */
component extends="coldbox-cli.models.BaseAICommand" {

	// DI
	property name="skillManager" inject="SkillManager@coldbox-cli";

	/**
	 * Run the command
	 *
	 * @query     Optional search term to filter skill names or descriptions.
	 * @owner     Filter by GitHub owner/org (defaults to both ortus-boxlang and coldbox).
	 * @repo      Filter by GitHub repo (requires --owner when specified).
	 * @category  Filter by skill category.
	 * @directory The target directory (defaults to current directory).
	 */
	function run(
		string query     = "",
		string owner     = "",
		string repo      = "",
		string category  = "",
		string directory = getCwd()
	){
		showColdBoxBanner( "Find AI Skills" )
		ensureInstalled( arguments.directory )

		print.line()

		var bxRepo = variables.settings.boxlangSkillsRepo
		var cbRepo = variables.settings.coldboxSkillsRepo

		// Determine which repos to search
		var reposToSearch = []
		if ( arguments.owner.len() && arguments.repo.len() ) {
			reposToSearch.append( {
				owner : arguments.owner,
				repo  : arguments.repo
			} )
		} else if ( arguments.owner.len() ) {
			var guessedRepo = "skills"
			reposToSearch.append( {
				owner : arguments.owner,
				repo  : guessedRepo
			} )
		} else {
			reposToSearch.append( bxRepo )
			reposToSearch.append( cbRepo )
		}

		// Gather all skills
		var allSkills = []
		reposToSearch.each( ( r ) => {
			var repoSkills = variables.skillManager.fetchRepoSkillList( r.owner, r.repo )
			repoSkills.each( ( s ) => {
				s.ownerRepo = "#r.owner#/#r.repo#"
				allSkills.append( s )
			} )
		} )

		if ( allSkills.isEmpty() ) {
			printError( "Could not retrieve skills from the registry. Check your network connection." )
			return
		}

		// Filter by query (name or description)
		if ( arguments.query.len() ) {
			allSkills = allSkills.filter( ( s ) => {
				var q = lCase( query )
				return lCase( s.name ?: "" ).findNoCase( q ) ||
				lCase( s.description ?: "" ).findNoCase( q ) ||
				lCase( s.category ?: "" ).findNoCase( q )
			} )
		}

		// Filter by category
		if ( arguments.category.len() ) {
			allSkills = allSkills.filter( ( s ) => compareNoCase( s.category ?: "", arguments.category ) == 0 )
		}

		if ( allSkills.isEmpty() ) {
			printInfo( "No skills matched your search." )
			print.line()
			printTip( "Try browsing all skills with: coldbox ai skills find" )
			return
		}

		// Group by category for display
		var grouped = {}
		allSkills.each( ( s ) => {
			var cat = s?.category ?: "other"
			if ( !grouped.keyExists( cat ) ) grouped[ cat ] = []
			grouped[ cat ].append( s )
		} )

		var totalCount = allSkills.len()
		printInfo( "Found [#totalCount#] skill(s):" )
		print.line()

		var tableData = []
		for ( var cat in grouped ) {
			grouped[ cat ].each( ( s ) => {
				tableData.append( [
					s.name ?: "",
					s.ownerRepo ?: "",
					left( s.description ?: "", 60 )
				] )
			} )
		}

		print.table(
			headerNames = [ "Name", "Repo", "Description" ],
			data        = tableData
		)

		print.line()
		printTip( "Install a skill: coldbox ai skills install <owner/repo/category/skill-name>" )
		printTip( "Install all skills in a category: coldbox ai skills install <owner/repo/category>" )
	}

}
