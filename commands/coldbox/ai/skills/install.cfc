/**
 * Install one or more AI skills from the skills registry.
 *
 * Slug formats accepted:
 *   owner/repo                        — install all skills for the repo
 *   owner/repo/category               — install all skills in a category
 *   owner/repo/category/skill         — install a single skill
 *   (space-separated list of any above for batch installs)
 *
 * Examples:
 *   coldbox ai skills install ortus-boxlang/skills
 *   coldbox ai skills install ortus-boxlang/skills/boxlang-developer
 *   coldbox ai skills install ortus-boxlang/skills/boxlang-developer/boxlang-syntax
 *   coldbox ai skills install --list
 *   coldbox ai skills install --all
 *   coldbox ai skills install --force ortus-boxlang/skills/boxlang-developer/boxlang-syntax
 */
component extends="coldbox-cli.models.BaseAICommand" aliases="coldbox ai skills add" {

	// DI
	property name="skillManager"  inject="SkillManager@coldbox-cli";
	property name="agentRegistry" inject="AgentRegistry@coldbox-cli";

	/**
	 * Run the command
	 *
	 * @slug      Skill slug(s) to install (owner/repo, owner/repo/category, or owner/repo/category/skill).
	 *            Accepts a comma-separated or space-after-quote list.
	 * @list      Show available skills and prompt for selection instead of installing directly.
	 * @all       Install all available skills for the default repos (ColdBox + BoxLang).
	 * @force     Overwrite existing skills if already installed.
	 * @directory The target directory (defaults to current directory).
	 */
	function run(
		string slug      = "",
		boolean list     = false,
		boolean all      = false,
		boolean force    = false,
		string directory = getCwd()
	){
		showColdBoxBanner( "Install AI Skills" )

		var info = ensureInstalled( arguments.directory )
		if ( !info.installed ) {
			return
		}
		var manifest = loadManifest( arguments.directory )
		var language = manifest.language ?: "boxlang"

		print
			.blueLine( "📥 Installing AI skills..." )
			.line()
			.toConsole()

		// ------------------------------------------------------------------
		// --list mode: interactive multi-select
		// ------------------------------------------------------------------
		if ( arguments.list && !arguments.slug.len() ) {
			_runInteractiveInstall(
				directory = arguments.directory,
				manifest  = manifest,
				language  = language,
				force     = arguments.force
			)
			return
		}

		// ------------------------------------------------------------------
		// --all mode: install all default skills
		// ------------------------------------------------------------------
		if ( arguments.all ) {
			printInfo( "Installing all default skills..." )
			print.line()

			var installed = variables.skillManager.installCoreSkills(
				directory = arguments.directory,
				language  = language,
				manifest  = manifest
			)

			if ( installed.len() ) {
				printSuccess( "Installed #installed.len()# skill(s):" )
				installed.each( ( name ) => print.greenLine( "  + #name#" ) )
			} else {
				printInfo( "No new skills to install." )
			}

			saveManifest( arguments.directory, manifest )
			_regenerateAgents( arguments.directory, manifest )
			print.line()
			printTip( "Run 'coldbox ai skills list' to see all installed skills." )
			return
		}

		// ------------------------------------------------------------------
		// Slug install (single or space-separated list)
		// ------------------------------------------------------------------
		if ( !arguments.slug.len() ) {
			printError( "Please provide a slug, or use --list / --all." )
			print.line()
			printInfo( "Usage: coldbox ai skills install <owner/repo[/category[/skill]]>" )
			return
		}

		var slugs = listToArray( arguments.slug, " ," )

		// Expand any owner/repo or owner/repo/category slugs using the registry listing
		var resolvedItems = _resolveSlugs( slugs, language )

		if ( resolvedItems.isEmpty() ) {
			printError( "No matching skills found for the given slug(s) '#arguments.slug#'." )
			return
		} else {
			printInfo( "Resolved #resolvedItems.len()# skill(s) to install from the registry:" )
			resolvedItems.each( ( item ) => print.blueLine( "  - #item.owner#/#item.repo#/#item.slug#" ) )
			print.line().toConsole()
		}

		// Install (batch if >1)
		if ( resolvedItems.len() == 1 ) {
			var item   = resolvedItems.first()
			var result = variables.skillManager.installSkillBySlug(
				directory = arguments.directory,
				owner     = item.owner,
				repo      = item.repo,
				skillSlug = item.slug,
				skillType = item.type ?: "core",
				source    = item.source ?: "",
				force     = arguments.force,
				manifest  = manifest
			)
			_printInstallResult( result )
		} else {
			printInfo( "Installing [#resolvedItems.len()#] skills..." )
			print.line()

			var batchItems = resolvedItems.map( ( r ) => {
				return {
					owner : r.owner,
					repo  : r.repo,
					skill : r.slug
				}
			} )
			var batchResult = variables.skillManager.downloadSkillBatch( batchItems )

			var successCount = 0
			var failCount    = 0

			batchResult.each( ( result ) => {
				if ( result.keyExists( "error" ) && result.error ) {
					printError( "  ✗ #result.skill ?: "unknown"#: #result.message ?: "download failed"#" )
					failCount++
					return
				}

				var skill       = result.skill
				var auditStatus = skill.audit_status ?: "skipped"

				if ( auditStatus == "block" ) {
					printWarn( "  ⚠ #skill.skill_dir.listLast( "/" )# blocked by security audit — skipped" )
					failCount++
					return
				}

				// Find matching resolved item for the skill type/source
				var matchSlug = skill.skill_slug ?: ""
				var matchItem = resolvedItems.filter( ( r ) => r.slug == matchSlug ).first( {} )
				var localName = matchItem.name ?: skill.skill_dir.listLast( "/" )

				if ( !arguments.force ) {
					var existing = variables.skillManager.getSkillFilePath( arguments.directory, localName )
					if ( !isNull( existing ) ) {
						printInfo( "  → #localName# already installed (use --force to overwrite)" )
						return
					}
				}

				localName = variables.skillManager.installRemoteSkill(
					directory   = arguments.directory,
					name        = localName,
					content     = result.content,
					owner       = skill.owner,
					repo        = skill.repo,
					path        = skill.skill_dir,
					sha         = skill.file_sha,
					description = skill.description ?: "",
					auditStatus = auditStatus,
					skillType   = matchItem.type ?: "core",
					source      = matchItem.source ?: "",
					manifest    = manifest
				)

				print.greenLine( "  + #localName#" )
				successCount++
			} )

			print.line()
			if ( successCount ) printSuccess( "Installed #successCount# skill(s)." )
			if ( failCount ) printWarn( "#failCount# skill(s) had errors." )
		}

		saveManifest( arguments.directory, manifest )
		_regenerateAgents( arguments.directory, manifest )

		print.line()
		printTip( "Run 'coldbox ai skills list' to see all installed skills." )
	}

	// =====================================================================
	// Private Helpers
	// =====================================================================

	/**
	 * Interactive multi-select install.
	 */
	private function _runInteractiveInstall(
		required string directory,
		required struct manifest,
		required string language,
		required boolean force
	){
		var settings = variables.settings ?: {}
		var bxRepo   = settings.boxlangSkillsRepo ?: {
			owner : "ortus-boxlang",
			repo  : "skills"
		}
		var cbRepo = settings.coldboxSkillsRepo ?: { owner : "coldbox", repo : "skills" }

		// Fetch both repos in parallel
		var bxList    = variables.skillManager.fetchRepoSkillList( bxRepo.owner, bxRepo.repo )
		var cbList    = variables.skillManager.fetchRepoSkillList( cbRepo.owner, cbRepo.repo )
		var allSkills = []
		bxList.each( ( s ) => allSkills.append( {
			label : "#bxRepo.owner#/#bxRepo.repo#/#s.slug#",
			value : {
				owner : bxRepo.owner,
				repo  : bxRepo.repo,
				slug  : s.slug,
				name  : s.name
			},
			description : s.description ?: ""
		} ) )
		cbList.each( ( s ) => allSkills.append( {
			label : "#cbRepo.owner#/#cbRepo.repo#/#s.slug#",
			value : {
				owner : cbRepo.owner,
				repo  : cbRepo.repo,
				slug  : s.slug,
				name  : s.name
			},
			description : s.description ?: ""
		} ) )

		if ( allSkills.isEmpty() ) {
			printError( "Could not retrieve skills from registry." )
			return
		}

		printInfo( "Select skills to install (space = toggle, enter = confirm):" )
		print.line()

		var choices = multiselect( "Skills" ).options( allSkills ).ask()

		if ( choices.isEmpty() ) {
			printInfo( "No skills selected." )
			return
		}

		print.line()
		printInfo( "Installing #choices.len()# selected skill(s)..." )
		print.line()

		var resolvedItems = choices.map( ( c ) => c.value )
		var batchItems    = resolvedItems.map( ( r ) => {
			return {
				owner : r.owner,
				repo  : r.repo,
				skill : r.slug
			}
		} )
		var batchResult = variables.skillManager.downloadSkillBatch( batchItems )

		batchResult.each( ( result ) => {
			if ( result.keyExists( "error" ) && result.error ) {
				printError( "  ✗ #result.message ?: "download failed"#" )
				return
			}
			var skill     = result.skill
			var matchSlug = skill.skill_slug ?: ""
			var matchItem = resolvedItems.filter( ( r ) => r.slug == matchSlug ).first( {} )
			var localName = matchItem.name ?: skill.skill_dir.listLast( "/" )
			localName     = variables.skillManager.installRemoteSkill(
				directory   = arguments.directory,
				name        = localName,
				content     = result.content,
				owner       = skill.owner,
				repo        = skill.repo,
				path        = skill.skill_dir,
				sha         = skill.file_sha,
				description = skill.description ?: "",
				auditStatus = skill.audit_status ?: "skipped",
				skillType   = "core",
				source      = "",
				manifest    = arguments.manifest
			)
			print.greenLine( "  + #localName#" )
		} )

		saveManifest(
			arguments.directory,
			arguments.manifest
		)
		_regenerateAgents(
			arguments.directory,
			arguments.manifest
		)
		print.line()
		printTip( "Run 'coldbox ai skills list' to see all installed skills." )
	}

	/**
	 * Resolve slug pattern(s) to {owner,repo,slug,name,type,source} items.
	 * - "owner/repo"          → fetch all from registry
	 * - "owner/repo/category" → filter to category
	 * - "owner/repo/cat/skill"→ single skill
	 *
	 * @slugs Array of slug strings to resolve
	 * @language Optional language filter for registry fetch (defaults to "boxlang")
	 *
	 * @return Array of resolved skill items with {owner, repo, slug, name, type, source}
	 */
	private array function _resolveSlugs(
		required array slugs,
		string language = "boxlang"
	){
		var resolved = []

		for ( var slug in arguments.slugs ) {
			var parts = slug.listToArray( "/" )

			if ( parts.len() < 2 ) {
				continue;
			}

			var slugOwner = parts[ 1 ]
			var slugRepo  = parts[ 2 ]

			if ( parts.len() == 2 ) {
				// Whole repo: owner/repo — install everything in it
				var repoList = variables.skillManager.fetchRepoSkillList( slugOwner, slugRepo )
				for ( var s in repoList ) {
					resolved.append( {
						owner  : slugOwner,
						repo   : slugRepo,
						slug   : s.slug,
						name   : s.name,
						type   : "core",
						source : ""
					} )
				}
			} else if ( parts.len() == 3 ) {
				// owner/repo/name — try it first as a direct skill slug; if not found, treat as a category filter
				var thirdPart   = parts[ 3 ]
				var repoSkills  = variables.skillManager.fetchRepoSkillList( slugOwner, slugRepo )
				var directMatch = repoSkills.filter( ( s ) => s.slug == thirdPart )

				if ( directMatch.len() ) {
					var dm = directMatch.first()
					resolved.append( {
						owner  : slugOwner,
						repo   : slugRepo,
						slug   : dm.slug,
						name   : dm.name,
						type   : "core",
						source : ""
					} )
				} else {
					// Fall back to category filter
					var categoryMatches = repoSkills.filter( ( s ) => s?.category == thirdPart )
					if ( categoryMatches.len() ) {
						for ( var cs in categoryMatches ) {
							resolved.append( {
								owner  : slugOwner,
								repo   : slugRepo,
								slug   : cs.slug,
								name   : cs.name,
								type   : "core",
								source : ""
							} )
						}
					}
					// If neither a direct skill nor a category matched, resolved stays empty for this slug
				}
			} else {
				// Explicit 4+ part slug: owner/repo/category/skill-name
				// Registry stores skill_slug with ~ as separator (not /), so join accordingly
				var skillSlug = parts.slice( 3 ).toList( "~" )
				resolved.append( {
					owner  : slugOwner,
					repo   : slugRepo,
					slug   : skillSlug,
					name   : parts.last(),
					type   : "core",
					source : ""
				} )
			}
		}

		return resolved
	}

	/**
	 * Print the result of a single installSkillBySlug call.
	 */
	private function _printInstallResult( required struct result ){
		print.line().toConsole()
		if ( result.success ) {
			printSuccess( "  ✓ Installed #result.name#" )
			if ( ( result.auditStatus ?: "" ) == "warn" ) {
				printWarn( "    ⚠ Audit warning — review skill before use" )
			}
		} else {
			printError( "  ✗ #result.message ?: "Install failed"#" )
		}
	}

	/**
	 * Regenerate all agent instruction files after skill changes.
	 */
	private function _regenerateAgents(
		required string directory,
		required struct manifest
	){
		if ( manifest.keyExists( "agents" ) && manifest.agents.len() ) {
			var language = manifest.language ?: "boxlang"
			printInfo( "Regenerating agent configuration files..." )
			manifest.agents.each( ( agent ) => {
				variables.agentRegistry.configureAgent( directory, agent, language )
			} )
		}
	}

}
