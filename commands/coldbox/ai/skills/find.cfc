/**
 * Search the skills registry and display matching skills.
 * Use this to discover skills before installing them.
 *
 * Examples:
 *   coldbox ai skills find
 *   coldbox ai skills find testing
 *   coldbox ai skills find owner=ortus-boxlang
 *   coldbox ai skills find owner=coldbox repo=skills
 *   coldbox ai skills find query=boxlang owner=ortus-boxlang
 *   coldbox ai skills find category=coldbox
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
	 * @table     Show results as a compact table instead of cards.
	 * @directory The target directory (defaults to current directory).
	 */
	function run(
		string query     = "",
		string owner     = "",
		string repo      = "",
		string category  = "",
		boolean table    = false,
		string directory = getCwd()
	){
		showColdBoxBanner( "Find AI Skills" )
		var info = ensureInstalled( arguments.directory )
		if( !info.installed ){
			return
		}

		print.blueLine( "🔍 Searching for AI skills..." ).line().toConsole()

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
		for ( var r in reposToSearch ) {
			var repoSkills = variables.skillManager.fetchRepoSkillList( r.owner, r.repo )
			for ( var s in repoSkills ) {
				s.ownerRepo = "#r.owner#/#r.repo#"
				s.repoOwner = r.owner
				s.repoName  = r.repo
				allSkills.append( s )
			}
		}

		if ( allSkills.isEmpty() ) {
			printError( "Could not retrieve skills from the registry. Check your network connection." )
			return
		}

		// Filter by query (name, description, or category)
		if ( arguments.query.len() ) {
			var q = lcase( arguments.query )
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

		printInfo( "Found [#allSkills.len()#] skill(s):" )
		print.line()

		// ----------------------------------------------------------------
		// TABLE view  (--table flag)
		// ----------------------------------------------------------------
		if ( arguments.table ) {
			var tableData = []
			for ( var s in allSkills ) {
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
