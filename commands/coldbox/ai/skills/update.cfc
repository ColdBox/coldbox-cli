/**
 * Update (re-download) one or all installed AI skills from the registry.
 *
 * Examples:
 * coldbox ai skills update
 * coldbox ai skills update boxlang-syntax
 */
component extends="coldbox-cli.models.BaseAICommand" {

	// DI
	property name="skillManager"       inject="SkillManager@coldbox-cli";
	property name="agentRegistry"      inject="AgentRegistry@coldbox-cli";
	property name="progressBarGeneric" inject="progressBarGeneric";

	/**
	 * Run the command
	 *
	 * @name Optional skill name to update. Omit to update all installed skills.
	 * @directory The target directory (defaults to current directory).
	 */
	function run(
		string name      = "",
		string directory = getCwd()
	){
		showColdBoxBanner( "Update AI Skills" )

		var info = ensureInstalled( arguments.directory )
		if ( !info.installed ) {
			return
		}

		var manifest = loadManifest( arguments.directory )
		print.line()

		if ( arguments.name.len() ) {
			_updateSingle(
				name      = arguments.name,
				directory = arguments.directory,
				manifest  = manifest
			)
			return
		}

		_updateAll(
			directory = arguments.directory,
			manifest  = manifest
		)
	}

	/**
	 * Update a single skill by local name.
	 */
	private function _updateSingle(
		required string name,
		required string directory,
		required struct manifest
	){
		var normalizedName = arguments.name.replaceAll( "\\s+", "-" )
		var entries        = arguments.manifest.skills.filter( ( s ) => s.name == normalizedName )

		if ( entries.isEmpty() ) {
			printError( "Skill '#normalizedName#' is not installed." )
			print.line()
			printTip( "Use 'coldbox ai skills list' to see installed skills." )
			return
		}

		var entry = entries.first()
		if ( ( entry.type ?: "" ) == "custom" ) {
			printError( "Skill '#normalizedName#' is custom and cannot be updated from the registry." )
			return
		}

		if ( !( entry.owner ?: "" ).len() || !( entry.repo ?: "" ).len() || !( entry.slug ?: "" ).len() ) {
			printError( "Skill '#normalizedName#' is missing owner/repo/slug metadata and cannot be updated." )
			return
		}

		printInfo( "Updating #normalizedName# (#entry.owner#/#entry.repo#/#entry.slug#)..." )
		print.toConsole()

		var result = variables.skillManager.downloadSkill( entry.owner, entry.repo, entry.slug )

		if ( result.keyExists( "error" ) && result.error ) {
			printError( "Failed to download '#normalizedName#': #result.message ?: "unknown error"#" )
			return
		}

		var skill       = result.skill
		var auditStatus = skill.audit_status ?: "skipped"
		if ( auditStatus == "block" ) {
			printError( "Update blocked for '#normalizedName#' by security audit." )
			return
		}

		variables.skillManager.installRemoteSkill(
			directory   = arguments.directory,
			name        = normalizedName,
			content     = result.content,
			owner       = skill.owner,
			repo        = skill.repo,
			path        = skill.skill_dir,
			sha         = skill.file_sha,
			description = skill.description ?: "",
			auditStatus = auditStatus,
			skillType   = entry.type ?: "core",
			source      = entry.source ?: "",
			manifest    = arguments.manifest
		)

		saveManifest(
			arguments.directory,
			arguments.manifest
		)
		_regenerateAgents(
			arguments.directory,
			arguments.manifest
		)

		print.line()
		printSuccess( "✓ Updated #normalizedName#" )
	}

	/**
	 * Re-download all non-custom registry skills.
	 */
	private function _updateAll(
		required string directory,
		required struct manifest
	){
		var targets = arguments.manifest.skills.filter( ( s ) => {
			return ( s.type ?: "" ) != "custom" &&
			( s.owner ?: "" ).len() &&
			( s.repo ?: "" ).len() &&
			( s.slug ?: "" ).len()
		} )

		if ( targets.isEmpty() ) {
			printInfo( "No registry skills installed to update." )
			print.line()
			printTip( "Use 'coldbox ai skills install --all' to install default registry skills." )
			return
		}

		var total = targets.len()
		printInfo( "Updating #total# installed skill(s):" )
		targets.each( ( t ) => {
			print.blueLine( "  - #t.name# (#t.owner#/#t.repo#/#t.slug#)" )
		} )
		print.line().toConsole()

		var batchItems = targets.map( ( t ) => {
			return {
				owner : t.owner,
				repo  : t.repo,
				skill : t.slug
			}
		} )

		printInfo( "Downloading updated skills from registry..." )
		variables.progressBarGeneric.update(
			percent      = 0,
			currentCount = 0,
			totalCount   = total
		)
		var batchResults = variables.skillManager.downloadSkillBatch( batchItems )
		variables.progressBarGeneric.update(
			percent      = 100,
			currentCount = total,
			totalCount   = total
		)
		variables.progressBarGeneric.clear()
		print.line().toConsole()

		var successCount   = 0
		var failCount      = 0
		var repoSkillCache = {}

		batchResults.each( ( result ) => {
			if ( result.keyExists( "error" ) && result.error ) {
				var failedCoords  = _extractBatchCoordinates( result )
				var failedMessage = _extractBatchMessage( result )
				var targetMatch   = targets
					.filter( ( t ) => {
						return t.owner == failedCoords.owner && t.repo == failedCoords.repo && t.slug == failedCoords.slug
					} )
					.first() ?: {}

				if ( failedCoords.owner.len() && failedCoords.repo.len() && failedCoords.slug.len() ) {
					var retry = variables.skillManager.downloadSkill(
						failedCoords.owner,
						failedCoords.repo,
						failedCoords.slug
					)

					if ( !( retry.keyExists( "error" ) && retry.error ) ) {
						result = retry
					} else {
						var retryMessage = retry.message ?: failedMessage

						if ( _isSkillNotFoundMessage( retryMessage ) && !targetMatch.isEmpty() ) {
							var replacement = _resolveReplacementSkill( targetMatch, repoSkillCache )

							if ( !replacement.isEmpty() ) {
								printInfo( "  ↻ #targetMatch.name#: trying '#replacement.slug#'" )
								var replacementRetry = variables.skillManager.downloadSkill(
									targetMatch.owner,
									targetMatch.repo,
									replacement.slug
								)

								if ( !( replacementRetry.keyExists( "error" ) && replacementRetry.error ) ) {
									replacementRetry[ "_targetEntry" ] = targetMatch
									result                             = replacementRetry
								} else {
									var replacementLabel = "#targetMatch.owner#/#targetMatch.repo#/#replacement.slug#"
									printWarn( "  ⚠ #replacementLabel#: #replacementRetry.message ?: retryMessage#" )
									failCount++
									return
								}
							} else {
								var missingLabel = "#failedCoords.owner#/#failedCoords.repo#/#failedCoords.slug#"
								printWarn( "  ⚠ #missingLabel# not found in registry (possibly renamed/removed) — skipped" )
								failCount++
								return
							}
						} else {
							var failedLabel = "#failedCoords.owner#/#failedCoords.repo#/#failedCoords.slug#"
							printError( "  ✗ #failedLabel#: #retryMessage#" )
							failCount++
							return
						}
					}
				} else {
					if ( _isSkillNotFoundMessage( failedMessage ) ) {
						printWarn( "  ⚠ #failedMessage#" )
					} else {
						printError( "  ✗ #failedMessage#" )
					}
					failCount++
					return
				}
			}

			var skill       = result.skill
			var auditStatus = skill.audit_status ?: "skipped"
			var matchSlug   = skill.skill_slug ?: skill.skill_dir.listLast( "/" )

			if ( auditStatus == "block" ) {
				printWarn( "  ⚠ #matchSlug# blocked by security audit and skipped" )
				failCount++
				return
			}

			var matches    = targets.filter( ( t ) => t.slug == matchSlug )
			var matchEntry = result.keyExists( "_targetEntry" ) ? result._targetEntry : (
				matches.isEmpty() ? {} : matches.first()
			)
			var localName = matchEntry.keyExists( "name" ) ? matchEntry.name : skill.skill_dir.listLast( "/" )

			print.toConsole( "  Updating #localName#..." )

			variables.skillManager.installRemoteSkill(
				directory   = directory,
				name        = localName,
				content     = result.content,
				owner       = skill.owner,
				repo        = skill.repo,
				path        = skill.skill_dir,
				sha         = skill.file_sha,
				description = skill.description ?: "",
				auditStatus = auditStatus,
				skillType   = matchEntry.keyExists( "type" ) ? matchEntry.type : "core",
				source      = matchEntry.keyExists( "source" ) ? matchEntry.source : "",
				manifest    = manifest
			)

			print.greenLine( " ✓" )
			successCount++
		} )

		variables.progressBarGeneric.clear()
		print.line().toConsole()

		saveManifest( directory, manifest )
		_regenerateAgents( directory, manifest )

		if ( successCount ) {
			printSuccess( "Updated #successCount# of #total# skill(s)." )
		}
		if ( failCount ) {
			printWarn( "#failCount# skill(s) failed to update." )
		}
		print.line()
	}

	/**
	 * Extract owner/repo/slug values from varying batch error payload shapes.
	 */
	private struct function _extractBatchCoordinates( required struct result ){
		var skillPayload = arguments.result.keyExists( "skill" ) ? arguments.result.skill : {}

		var owner = _extractBatchScalar( skillPayload.owner ?: skillPayload.OWNER ?: "" )
		var repo  = _extractBatchScalar( skillPayload.repo ?: skillPayload.REPO ?: "" )
		var slug  = _extractBatchScalar( skillPayload.skill ?: skillPayload.SKILL ?: "" )

		return {
			owner : owner,
			repo  : repo,
			slug  : slug
		}
	}

	/**
	 * Extract a readable message from varying batch error payload shapes.
	 */
	private string function _extractBatchMessage( required struct result ){
		if ( arguments.result.keyExists( "message" ) && len( arguments.result.message ?: "" ) ) {
			return arguments.result.message
		}

		if (
			arguments.result.keyExists( "messages" ) && isArray( arguments.result.messages ) && arguments.result.messages.len()
		) {
			return arguments.result.messages[ 1 ]
		}

		return "download failed"
	}

	/**
	 * Detect not-found errors from registry responses.
	 */
	private boolean function _isSkillNotFoundMessage( required string message ){
		return findNoCase(
			"skill not found",
			arguments.message ?: ""
		) > 0
	}

	/**
	 * Attempt to resolve a replacement slug for renamed skills in the same repo.
	 */
	private struct function _resolveReplacementSkill(
		required struct target,
		required struct repoSkillCache
	){
		var cacheKey = "#arguments.target.owner#/#arguments.target.repo#"
		if ( !arguments.repoSkillCache.keyExists( cacheKey ) ) {
			arguments.repoSkillCache[ cacheKey ] = variables.skillManager.fetchRepoSkillList(
				arguments.target.owner,
				arguments.target.repo
			)
		}

		var repoSkills = arguments.repoSkillCache[ cacheKey ]
		if ( !isArray( repoSkills ) || repoSkills.isEmpty() ) {
			return {}
		}

		var needles = [
			( arguments.target.slug ?: "" ).lcase(),
			( arguments.target.name ?: "" ).lcase(),
			( arguments.target.path ?: "" ).listLast( "/" ).lcase()
		].filter( ( n ) => n.len() )

		for ( var needle in needles ) {
			var exact = repoSkills.filter( ( s ) => {
				var slug = ( s.slug ?: "" ).lcase()
				var name = ( s.name ?: "" ).lcase()
				return slug == needle || name == needle
			} )
			if ( !exact.isEmpty() ) {
				return exact.first()
			}
		}

		for ( var needle in needles ) {
			var suffix = "-#needle#"
			var fuzzy  = repoSkills.filter( ( s ) => {
				var slug = ( s.slug ?: "" ).lcase()
				return findNoCase( needle, slug ) > 0 || right( slug, suffix.len() ) == suffix
			} )
			if ( !fuzzy.isEmpty() ) {
				return fuzzy.first()
			}
		}

		return {}
	}

	/**
	 * Reduce nested/simple/list payload values to a scalar string.
	 */
	private string function _extractBatchScalar( required any value ){
		if ( isSimpleValue( arguments.value ) ) {
			return trim( arguments.value & "" )
		}

		if ( isArray( arguments.value ) && arguments.value.len() ) {
			return _extractBatchScalar( arguments.value[ 1 ] )
		}

		if ( isStruct( arguments.value ) ) {
			for ( var key in arguments.value ) {
				return _extractBatchScalar( arguments.value[ key ] )
			}
		}

		return ""
	}

	/**
	 * Regenerate all configured agent files after manifest changes.
	 */
	private function _regenerateAgents(
		required string directory,
		required struct manifest
	){
		if ( arguments.manifest.keyExists( "agents" ) && arguments.manifest.agents.len() ) {
			var language = arguments.manifest.language ?: "boxlang"
			printInfo( "Regenerating agent configuration files..." )
			arguments.manifest.agents.each( ( agent ) => {
				variables.agentRegistry.configureAgent( directory, agent, language )
			} )
		}
	}

}
