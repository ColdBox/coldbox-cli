/**
 * List all AI skills installed in this project, grouped by owner/repo.
 *
 * Examples:
 * coldbox ai skills list
 * coldbox ai skills list --outdated
 * coldbox ai skills list --verbose
 */
component extends="coldbox-cli.models.BaseAICommand" {

	property name="skillManager" inject="SkillManager@coldbox-cli";
	property name="progressBarGeneric" inject="progressBarGeneric";

	/**
	 * Run the command
	 *
	 * @outdated  Only show skills that have a newer version available in the registry
	 * @verbose   Show extra columns (SHA, last synced)
	 * @directory The target directory (defaults to current directory)
	 */
	function run(
		boolean outdated = false,
		boolean verbose  = false,
		string directory = getCwd()
	){
		showColdBoxBanner( "Installed AI Skills" )

		var info = ensureInstalled( arguments.directory )
		if ( !info.installed ) {
			return
		}

		// --outdated: validate integrity and keep only stale skills
		if ( outdated ) {
			printInfo( "Checking registry for skill updates..." )
			print.line().toConsole()

			var integrity = skillManager.validateSkillIntegrity(
				arguments.directory,
				info,
				( currentCount, totalCount, skillName ) => {
					var percent = totalCount > 0 ? int( ( currentCount / totalCount ) * 100 ) : 100
					variables.progressBarGeneric.update(
						percent      = percent,
						currentCount = currentCount,
						totalCount   = totalCount
					)
				}
			)

			variables.progressBarGeneric.clear()
			print.line().toConsole()

			var staleNames = integrity.stale
			if ( staleNames.isEmpty() ) {
				printSuccess( "All skills are up to date." )
				return
			}
			info.skills       = info.skills.filter( ( s ) => staleNames.find( s.name ) > 0 )
			info.customSkills = [] // custom skills have no remote SHA, cannot be outdated
			printWarn( "#staleNames.len()# skill(s) have updates available:" )
			print.line()
		}

		if ( info.skills.isEmpty() && info.customSkills.isEmpty() ) {
			printWarn( "No skills installed. Run 'coldbox ai skills install --list' to browse the registry." )
			return
		}

		// Group by owner/repo (custom skills in their own bucket from customSkills manifest section)
		var groups = {}
		info.skills.each( ( skill ) => {
			var bucket = ( skill.owner ?: "" ) != "" ? "#skill.owner#/#skill.repo#" : "unknown"
			if ( !groups.keyExists( bucket ) ) {
				groups[ bucket ] = []
			}
			groups[ bucket ].append( skill )
		} )

		// Add custom skills from manifest.customSkills
		if ( info.customSkills.len() ) {
			groups[ "custom" ] = info.customSkills
		}

		// Sort groups: custom last, then alphabetical
		var groupKeys = groups
			.keyArray()
			.sort( ( a, b ) => {
				if ( a == "custom" ) return 1
				if ( b == "custom" ) return -1
				return compareNoCase( a, b )
			} )

		groupKeys.each( ( bucket ) => {
			var bucketSkills = groups[ bucket ].sort( ( a, b ) => compareNoCase( a.name, b.name ) )
			var label        = bucket == "custom" ? "🔧 Custom" : "📦 #bucket#"

			print
				.lineBlackOnSeaGreen1( "#label# (#bucketSkills.len()#)" )
				.line()
				.line()

			if ( verbose ) {
				// Full table with SHA + syncedAt
				var rows = bucketSkills.map( ( skill ) => {
					var sha       = len( skill.sha ?: "" ) >= 7 ? left( skill.sha, 7 ) : ( skill.sha ?: "—" )
					var synced    = skill.syncedAt ?: "—"
					var skillType = skill.type ?: "registry"
					return [ skill.name, sha, synced, skillType ]
				} )
				print.table(
					headerNames = [ "Name", "SHA", "Last Synced", "Type" ],
					data        = rows
				)
			} else {
				// Compact table
				var rows = bucketSkills.map( ( skill ) => {
					var sha = len( skill.sha ?: "" ) >= 7 ? left( skill.sha, 7 ) : ( skill.sha ?: "—" )
					return [ skill.name, sha ]
				} )
				print.table(
					headerNames = [ "Name", "SHA" ],
					data        = rows
				)
			}
			print.line()
		} )

		// Summary
		print.line()
		printInfo( "Total: #(info.skills.len() + info.customSkills.len())# skill(s) installed" )
		print.line()

		if ( !outdated ) {
			printTip( "Run 'coldbox ai skills list --outdated' to check for updates" )
			printTip( "Run 'coldbox ai skills refresh' to update all skills" )
			printTip( "Run 'coldbox ai skills find <query>' to search the registry" )
		}
	}

}
