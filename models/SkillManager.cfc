/**
 * Manages AI skills — remote-first, SHA-locked, flat storage.
 *
 * Skills are downloaded from skills.boxlang.io and stored at:
 *   {project}/.ai/skills/{name}/SKILL.md
 *
 * The manifest records sha (from registry), owner, repo, path, and syncedAt.
 * On refresh, stale skills (sha mismatch) are re-downloaded; orphaned module
 * skills (removed from box.json) are pruned automatically.
 *
 * Multi-directory lookup order for agent instructions:
 *   1. .ai/skills/{name}/SKILL.md    (coldbox-cli managed)
 *   2. .agents/skills/{name}/SKILL.md
 *   3. .claude/skills/{name}/SKILL.md
 */
component singleton {

	// DI
	property name="print"          inject="PrintBuffer";
	property name="fileSystemUtil" inject="fileSystem";
	property name="packageService" inject="PackageService";
	property name="wirebox"        inject="wirebox";
	property name="utility"        inject="Utility@coldbox-cli";
	property name="aiService"      inject="AIService@coldbox-cli";
	property name="settings"       inject="box:modulesettings:coldbox-cli";

	// =========================================================================
	// Public API — install / refresh
	// =========================================================================

	/**
	 * Install skills for a project based on detected dependencies.
	 * - commandbox/* always installed
	 * - boxlang-developer/* installed when language != cfml
	 * - coldbox/testbox/* per box.json deps
	 * - coldbox/skills/modules/{slug} per installed module
	 *
	 * @directory The project directory
	 * @language  Project language mode (boxlang, cfml, hybrid)
	 * @manifest  The manifest struct to update (mutated in place)
	 *
	 * @return Array of skill names that were installed
	 */
	function installCoreSkills(
		required string directory,
		required string language,
		required struct manifest
	){
		var installed = [];
		var targets   = getSkillsMap( arguments.directory, arguments.language );

		// Use batch API when there are multiple skills to install
		if ( targets.len() > 1 ) {
			var batchItems = targets.map( ( t ) => { return { owner: t.owner, repo: t.repo, skill: t.slug, source: t.source, type: t.type } } )

			variables.print
				.blueLine( "⬇️  Downloading #batchItems.len()# skill(s) from registry..." )
				.toConsole()

			downloadSkillBatch( batchItems )
				.each( ( result ) => {
					if ( result.keyExists( "error" ) && result.error ) {
						variables.print
							.yellowLine( "  ⚠️  Skipped (download error): #result.message ?: 'unknown'#" )
							.toConsole()
						return
					}

					var skillAudit = result.skill.audit_status ?: "skipped"
					var skillSlug  = result.skill.skill_slug ?: result.skill.skill_dir.listLast( "/" )

					if ( skillAudit == "block" ) {
						variables.print
							.redLine( "  🚫  Blocked (failed security audit): #skillSlug#" )
							.toConsole()
						return
					}

					var _filtered  = targets.filter( ( t ) => t.slug == skillSlug )
					var targetInfo = _filtered.len() ? _filtered.first() : {}
					var localName  = targetInfo.name ?: result.skill.skill_dir.listLast( "/" )

					variables.print.blueLine( "  ⬇️  Installing: #localName#" ).toConsole()

					installRemoteSkill(
						directory   = directory,
						name        = localName,
						content     = result.content,
						owner       = result.skill.owner,
						repo        = result.skill.repo,
						path        = result.skill.skill_dir,
						sha         = result.skill.file_sha,
						description = result.skill.description,
						auditStatus = skillAudit,
						skillType   = targetInfo.type ?: "core",
						source      = targetInfo.source ?: "",
						manifest    = manifest
					)
					installed.append( localName )
				} )

			if ( installed.len() ) {
				variables.print.greenLine( "✅  Installed #installed.len()# skill(s)." ).toConsole()
			}

		} else if ( targets.len() == 1 ) {
			var t = targets.first()
			variables.print.blueLine( "⬇️  Downloading skill: #t.slug#..." ).toConsole()
			var result = downloadSkill( t.owner, t.repo, t.slug )
			if ( result.keyExists( "error" ) && result.error ) {
				variables.print
					.yellowLine( "  ⚠️  Skipped (download error): #result.message ?: 'unknown'#" )
					.toConsole()
			} else if ( ( result.skill.audit_status ?: "skipped" ) == "block" ) {
				variables.print
					.redLine( "  🚫  Blocked (failed security audit): #t.slug#" )
					.toConsole()
			} else {
				variables.print.blueLine( "  ⬇️  Installing: #t.name#" ).toConsole()
				installRemoteSkill(
					directory   = arguments.directory,
					name        = t.name,
					content     = result.content,
					owner       = result.skill.owner,
					repo        = result.skill.repo,
					path        = result.skill.skill_dir,
					sha         = result.skill.file_sha,
					description = result.skill.description,
					auditStatus = result.skill.audit_status ?: "skipped",
					skillType   = t.type,
					source      = t.source,
					manifest    = manifest
				)
				installed.append( t.name )
				variables.print.greenLine( "✅  Installed: #t.name#" ).toConsole()
			}
		}

		return installed;
	}

	/**
	 * Refresh skills: re-download stale skills, prune orphaned module skills,
	 * sync custom skills from filesystem.
	 *
	 * @directory The project directory
	 * @manifest  The manifest struct to update (mutated in place)
	 *
	 * @return Struct {added[], updated[], removed[]}
	 */
	function refresh(
		required string directory,
		required struct manifest
	){
		var changes = { "added": [], "updated": [], "removed": [] };

		// ------------------------------------------------------------------
		// 1. Prune orphaned module skills (module removed from box.json)
		// ------------------------------------------------------------------
		var boxJson         = variables.packageService.readPackageDescriptor( arguments.directory );
		var allDependencies = {};
		allDependencies.append( boxJson.dependencies    ?: {} );
		allDependencies.append( boxJson.devDependencies ?: {} );

		var toRemove = [];
		for ( var skill in arguments.manifest.skills ) {
			var skillType = skill.type ?: ""
			if ( skillType != "module" ) continue

			var source = skill.source ?: ""
			if ( source.len() && !allDependencies.keyExists( source ) ) {
				toRemove.append( skill.name )
			}
		}

		toRemove.each( ( name ) => {
			variables.print.yellowLine( "  🗑️  Removing orphaned module skill: #name#" ).toConsole()
			deleteSkillDir( directory, name )
			manifest.skills = manifest.skills.filter( ( s ) => s.name != name )
			changes.removed.append( name )
		} )

		// ------------------------------------------------------------------
		// 2. Collect remote skills that need SHA check
		// ------------------------------------------------------------------
		var remoteSkills = arguments.manifest.skills.filter( ( s ) => {
			var type = s.type ?: ""
			return type != "custom"
		} )

		// Group by owner/repo for efficient API calls
		var repoMap = {}
		remoteSkills.each( ( s ) => {
			var owner = s.owner ?: ""
			var repo  = s.repo  ?: ""
			if ( !owner.len() || !repo.len() ){
				return;
			}
			var targetKey = "#owner#/#repo#"
			if ( !repoMap.keyExists( targetKey ) ) {
				repoMap[ targetKey ] = []
			}
			repoMap[ targetKey ].append( s )
		} )

		// For each repo, fetch the skill list and compare SHAs
		var staleItems = []
		for ( var repoKey in repoMap ) {
			var parts      = repoKey.listToArray( "/" )
			var owner      = parts[ 1 ]
			var repo       = parts[ 2 ]
			var repoSkills = repoMap[ repoKey ]
			var remoteList = fetchRepoSkillList( owner, repo )

			repoSkills.each( ( manifestEntry ) => {
				var entrySlug = manifestEntry.slug ?: ""
				var entryPath = manifestEntry.path ?: ""
				var remote    = remoteList.filter( ( r ) => r.slug == entrySlug || r.path == entryPath )
				if ( !remote.len() ){
					return;
				}

				var currentSha = remote.first().sha ?: ""
				var storedSha  = manifestEntry.sha  ?: ""
				if ( currentSha != storedSha ) {
					staleItems.append( { entry: manifestEntry, newSha: currentSha } )
				}
			} )
		}

		// ------------------------------------------------------------------
		// 3. Re-download stale skills via batch
		// ------------------------------------------------------------------
		if ( staleItems.len() ) {
			variables.print.yellowLine( "  📦  Found #staleItems.len()# outdated skill(s), re-downloading..." ).toConsole()
			var batchItems = staleItems.map( ( item ) => {
				return {
					owner : item.entry.owner ?: "",
					repo  : item.entry.repo  ?: "",
					skill : item.entry.slug  ?: item.entry.path.listLast( "/" )
				}
			} )
			var batchResult = downloadSkillBatch( batchItems )

			batchResult.each( ( result ) => {
				if ( result.keyExists( "error" ) && result.error ) return

				var resultSlug    = result.skill.skill_slug ?: ""
				var _staleFiltered = staleItems.filter( ( i ) => i.entry.slug == resultSlug )
				var staleItem      = _staleFiltered.len() ? _staleFiltered.first() : {}
				if ( staleItem.isEmpty() ) return

				variables.print.blueLine( "  🔄  Updating: #staleItem.entry.name#" ).toConsole()

				installRemoteSkill(
					directory   = arguments.directory,
					name        = staleItem.entry.name,
					content     = result.content,
					owner       = result.skill.owner,
					repo        = result.skill.repo,
					path        = result.skill.skill_dir,
					sha         = result.skill.file_sha,
					description = result.skill.description,
					auditStatus = result.skill.audit_status,
					skillType   = staleItem.entry.type ?: "core",
					source      = staleItem.entry.source ?: "",
					manifest    = arguments.manifest
				)
				changes.updated.append( staleItem.entry.name )
			} )
		}

		// ------------------------------------------------------------------
		// 4. Remove manifest entries whose files no longer exist on disk
		// ------------------------------------------------------------------
		var orphaned = []
		for ( var skill in arguments.manifest.skills ) {
			var skillFile = getSkillFilePath( arguments.directory, skill.name )
			if ( isNull( skillFile ) ) {
				orphaned.append( skill.name )
			}
		}
		orphaned.each( ( name ) => {
			variables.print.yellowLine( "  🧹  Removing missing-file entry: #name#" ).toConsole()
			arguments.manifest.skills = arguments.manifest.skills.filter( ( s ) => s.name != name )
			changes.removed.append( name )
		} )

		// ------------------------------------------------------------------
		// 5. Sync custom skills from .ai/skills/ that aren't in manifest yet
		// ------------------------------------------------------------------
		var skillsDir = "#arguments.directory#/.ai/skills"
		if ( directoryExists( skillsDir ) ) {
			directoryList( skillsDir, false, "name" ).each( ( dirName ) => {
				var skillFilePath = "#skillsDir#/#dirName#/SKILL.md"
				if ( !fileExists( skillFilePath ) ) {
					return;
				}

				var alreadyInManifest = manifest.skills.filter( ( s ) => s.name == dirName ).len() > 0
				if ( alreadyInManifest ) {
					return;
				}

				variables.print.greenLine( "  ✨  Found new custom skill: #dirName#" ).toConsole()

				var content     = fileRead( skillFilePath )
				var parsed      = variables.utility.parseFrontmatter( content )
				var description = parsed.frontmatter.description ?: ""

				manifest.skills.append( {
					"name"       : dirName,
					"owner"      : "",
					"repo"       : "",
					"path"       : "",
					"sha"        : "",
					"description": description,
					"type"       : "custom",
					"source"     : "custom",
					"syncedAt"   : dateTimeFormat( now(), "iso" )
				} )
				changes.added.append( dirName )
			} )
		}

		return changes;
	}

	// =========================================================================
	// Public API — single install / validation / path resolution
	// =========================================================================

	/**
	 * Download and install a single remote skill into a project.
	 *
	 * @directory   The project directory
	 * @owner       GitHub owner/org
	 * @repo        GitHub repo name
	 * @skillSlug   The skill_slug value (as used by the registry)
	 * @name        Optional local name override (defaults to last segment of skill_dir)
	 * @skillType   Manifest type: core|module|commandbox|custom (default: core)
	 * @source      Module slug when type=module, otherwise ""
	 * @force       Overwrite existing skill file
	 * @manifest    Manifest struct to update (if empty, loaded and saved automatically)
	 *
	 * @return Struct: {success, name, sha, auditStatus, message}
	 */
	struct function installSkillBySlug(
		required string directory,
		required string owner,
		required string repo,
		required string skillSlug,
		string name      = "",
		string skillType = "core",
		string source    = "",
		boolean force    = false,
		struct manifest  = {}
	){
		var managingManifest = arguments.manifest.isEmpty()
		if ( managingManifest ) {
			arguments.manifest = variables.aiService.loadManifest( arguments.directory )
		}

		variables.print.blueLine( "⬇️  Downloading #arguments.owner#/#arguments.repo#/#arguments.skillSlug#..." ).toConsole()

		var downloadResult = downloadSkill( arguments.owner, arguments.repo, arguments.skillSlug )
		if ( downloadResult.keyExists( "error" ) && downloadResult.error ) {
			variables.print.redLine( "  ❌  Download failed: #downloadResult.message ?: 'unknown'#" ).toConsole()
			return { success: false, name: arguments.skillSlug, message: downloadResult.message ?: "Download failed" }
		}

		var skill       = downloadResult.skill
		var content     = downloadResult.content
		var auditStatus = skill.audit_status ?: "skipped"

		if ( auditStatus == "block" ) {
			variables.print.redLine( "  🚫  Blocked (failed security audit): #arguments.skillSlug#" ).toConsole()
			return {
				success     : false,
				name        : arguments.skillSlug,
				auditStatus : auditStatus,
				message     : "Skill failed security audit and cannot be installed"
			}
		}

		var localName = arguments.name.len() ? arguments.name : skill.skill_dir.listLast( "/" )

		if ( !arguments.force ) {
			var existing = getSkillFilePath( arguments.directory, localName )
			if ( !isNull( existing ) ) {
				variables.print.yellowLine( "  ⚠️  Already installed: #localName# (use --force to overwrite)" ).toConsole()
				return {
					success     : false,
					name        : localName,
					auditStatus : auditStatus,
					message     : "Skill already installed. Use --force to overwrite."
				}
			}
		}

		installRemoteSkill(
			directory   = arguments.directory,
			name        = localName,
			content     = content,
			owner       = skill.owner,
			repo        = skill.repo,
			path        = skill.skill_dir,
			sha         = skill.file_sha,
			description = skill.description,
			auditStatus = auditStatus,
			skillType   = arguments.skillType,
			source      = arguments.source,
			manifest    = arguments.manifest
		)

		variables.print.greenLine( "  ✅  Installed: #localName#" ).toConsole()

		if ( managingManifest ) {
			variables.aiService.saveManifest( arguments.directory, arguments.manifest )
		}

		return {
			success     : true,
			name        : localName,
			sha         : skill.file_sha,
			auditStatus : auditStatus,
			message     : "Installed #localName#"
		}
	}

	/**
	 * Validate skill integrity — compares manifest SHAs against current registry.
	 *
	 * @directory The project directory
	 * @manifest  The manifest struct
	 *
	 * @return Struct: {valid[], stale[], missing[]}
	 */
	struct function validateSkillIntegrity(
		required string directory,
		required struct manifest
	){
		var result = { valid: [], stale: [], missing: [] }

		for ( var skill in arguments.manifest.skills ) {
			var skillFile = getSkillFilePath( arguments.directory, skill.name )
			if ( isNull( skillFile ) ) {
				result.missing.append( skill.name )
				continue;
			}

			var owner = skill.owner ?: ""
			var repo  = skill.repo  ?: ""
			var slug  = skill.slug  ?: ""
			var type  = skill.type  ?: ""

			if ( type == "custom" || !owner.len() || !repo.len() || !slug.len() ) {
				result.valid.append( skill.name )
				continue;
			}

			var remoteList = fetchRepoSkillList( owner, repo )
			var remote     = remoteList.filter( ( r ) => r.slug == slug )
			if ( !remote.len() ) {
				result.valid.append( skill.name )
				continue;
			}

			var currentSha = remote.first().sha ?: ""
			if ( currentSha != ( skill.sha ?: "" ) ) {
				result.stale.append( skill.name )
			} else {
				result.valid.append( skill.name )
			}
		}

		return result
	}

	/**
	 * Return the absolute path to a skill's SKILL.md file, checking three locations:
	 *   1. {directory}/.ai/skills/{name}/SKILL.md
	 *   2. {directory}/.agents/skills/{name}/SKILL.md
	 *   3. {directory}/.claude/skills/{name}/SKILL.md
	 *
	 * @directory The project directory
	 * @name      The skill name (directory name)
	 *
	 * @return Absolute path string, or null if not found
	 */
	function getSkillFilePath( required string directory, required string name ){
		var candidates = [
			"#arguments.directory#/.ai/skills/#arguments.name#/SKILL.md",
			"#arguments.directory#/.agents/skills/#arguments.name#/SKILL.md",
			"#arguments.directory#/.claude/skills/#arguments.name#/SKILL.md"
		]
		for ( var candidate in candidates ) {
			if ( fileExists( candidate ) ) return candidate
		}
		return javacast( "null", "" )
	}

	/**
	 * Create a custom skill from template in the flat .ai/skills/{name}/ directory.
	 *
	 * @directory The project directory
	 * @name      The custom skill name
	 * @language  The language variant (boxlang or cfml)
	 */
	function createCustomSkill(
		required string directory,
		required string name,
		string language = "boxlang"
	){
		var targetDir = "#arguments.directory#/.ai/skills/#arguments.name#"
		var skillFile = "#targetDir#/SKILL.md"

		if ( !directoryExists( targetDir ) ){
			directoryCreate( targetDir, true )
		}

		var languageSuffix = arguments.language == "cfml" ? ".cfml" : ".bx"
		var templatePath   = variables.utility.getTemplatesPath() & "/ai/skills/custom-skill-template#languageSuffix#.md"
		var template       = fileRead( templatePath )
		template           = replaceNoCase( template, "|skillName|", arguments.name, "all" )
		fileWrite( skillFile, template )

		var manifest = variables.aiService.loadManifest( arguments.directory );
		manifest.skills.append( {
			"name"       : arguments.name,
			"owner"      : "",
			"repo"       : "",
			"path"       : "",
			"sha"        : "",
			"description": "",
			"type"       : "custom",
			"source"     : "custom",
			"syncedAt"   : dateTimeFormat( now(), "iso" )
		} )
		variables.aiService.saveManifest( arguments.directory, manifest )
	}

	/**
	 * Remove a skill from the project (flat path).
	 *
	 * @directory The project directory
	 * @name      The skill name to remove
	 *
	 * @return true
	 * @throws SkillManager.SkillNotFound if not found
	 */
	function removeSkillFromProject(
		required string directory,
		required string name
	){
		var skillDir = "#arguments.directory#/.ai/skills/#arguments.name#"

		if ( !directoryExists( skillDir ) ) {
			throw(
				type    = "SkillManager.SkillNotFound",
				message = "Skill '#arguments.name#' not found at: #skillDir#"
			)
		}

		directoryDelete( skillDir, true )

		var manifest    = variables.aiService.loadManifest( arguments.directory )
		manifest.skills = manifest.skills.filter( ( s ) => s.name != arguments.name )
		variables.aiService.saveManifest( arguments.directory, manifest )

		return true
	}

	/**
	 * Create a skill override (custom copy) in the flat .ai/skills/{name}/ directory.
	 * Sets type=custom, empty owner/repo so refresh skips it.
	 *
	 * @directory The project directory
	 * @name      The name of the skill to override
	 */
	function createSkillOverride(
		required string directory,
		required string name
	){
		var manifest   = variables.aiService.loadManifest( arguments.directory )
		var sourcePath = getSkillFilePath( arguments.directory, arguments.name )

		if ( isNull( sourcePath ) ) {
			throw(
				type    = "SkillManager.SkillNotFound",
				message = "Skill '#arguments.name#' not found in .ai/skills/, .agents/skills/, or .claude/skills/"
			)
		}

		var originalContent = fileRead( sourcePath )

		var templatePath = variables.utility.getTemplatesPath() & "/ai/skills/skill-override-template.md"
		if ( !fileExists( templatePath ) ) {
			throw(
				type    = "SkillManager.TemplateNotFound",
				message = "Override template not found: #templatePath#"
			)
		}

		var content = fileRead( templatePath )
		content     = replaceNoCase( content, "|skillName|",   arguments.name,  "all" )
		content     = replaceNoCase( content, "|coreContent|", originalContent, "all" )

		var targetDir  = "#arguments.directory#/.ai/skills/#arguments.name#"
		var targetFile = "#targetDir#/SKILL.md"
		if ( !directoryExists( targetDir ) ) directoryCreate( targetDir, true )
		fileWrite( targetFile, content )

		// Find existing manifest entry
		var existingIndex = 0
		for ( var i = 1; i <= manifest.skills.len(); i++ ) {
			if ( manifest.skills[ i ].name == arguments.name ) { existingIndex = i; break }
		}

		var skillEntry = {
			"name"       : arguments.name,
			"owner"      : "",
			"repo"       : "",
			"path"       : "",
			"sha"        : "",
			"description": existingIndex ? ( manifest.skills[ existingIndex ].description ?: "" ) : "",
			"type"       : "custom",
			"source"     : "custom",
			"syncedAt"   : dateTimeFormat( now(), "iso" )
		}

		if ( existingIndex ) {
			manifest.skills[ existingIndex ] = skillEntry
		} else {
			manifest.skills.append( skillEntry )
		}

		variables.aiService.saveManifest( arguments.directory, manifest )

		return targetFile
	}

	/**
	 * Diagnose skill health: missing files.
	 *
	 * @directory The project directory
	 * @manifest  The manifest struct
	 */
	function diagnose(
		required string directory,
		required struct manifest
	){
		var issues = { "warnings": [], "recommendations": [] };

		for ( var skill in arguments.manifest.skills ) {
			var skillFile = getSkillFilePath( arguments.directory, skill.name )
			if ( isNull( skillFile ) || skillFile.isEmpty() ) {
				issues.warnings.append( "Missing skill file: #skill.name#" )
				issues.recommendations.append( "Run 'coldbox ai skills refresh' to restore missing skills" )
			}
		}

		return issues;
	}

	// =========================================================================
	// Remote API Helpers
	// =========================================================================

	/**
	 * Download a single skill from the registry.
	 *
	 * @owner     GitHub owner/org
	 * @repo      GitHub repo name
	 * @skillSlug The skill_slug value
	 *
	 * @return Registry response struct: {skill, content, audit, counts} or {error, message}
	 */
	struct function downloadSkill(
		required string owner,
		required string repo,
		required string skillSlug
	){
		var registryUrl = variables.settings.skillsRegistryUrl
		var targetUrl   = "#registryUrl#/api/install"

		var httpResult = ""
		cfhttp(
			method  = "POST",
			url     = targetUrl,
			result  = "httpResult",
			timeout = 30
		) {
			cfhttpparam( type="url", name="owner", value=arguments.owner );
			cfhttpparam( type="url", name="repo",  value=arguments.repo  );
			cfhttpparam( type="url", name="skill", value=arguments.skillSlug );
		};

		if ( httpResult.statusCode >= 400 ) {
			return {
				error   : true,
				message : "Registry returned #httpResult.statusCode# for #arguments.owner#/#arguments.repo#/#arguments.skillSlug#"
			}
		}

		try {
			return deserializeJSON( httpResult.fileContent )
		} catch ( any e ) {
			return { error: true, message: "Failed to parse registry response: #e.message#" }
		}
	}

	/**
	 * Batch-download multiple skills in one HTTP round-trip.
	 * Falls back to sequential single downloads if the batch endpoint fails.
	 *
	 * @skills Array of {owner, repo, skill} structs
	 *
	 * @return Array of registry result structs
	 */
	array function downloadSkillBatch( required array skills ){
		if ( arguments.skills.isEmpty() ) {
			return []
		}

		var registryUrl = variables.settings.skillsRegistryUrl
		var targetUrl   = "#registryUrl#/api/install/batch"
		var payload     = serializeJSON( arguments.skills )
		var httpResult = ""
		cfhttp(
			method  = "POST",
			url     = targetUrl,
			result  = "httpResult",
			timeout = 60
		) {
			cfhttpparam( type="header", name="Content-Type", value="application/json; charset=utf-8" );
			cfhttpparam( type="body",   value=payload );
		};

		if ( httpResult.statusCode > 400 ) {
			variables.print
				.printLine( "⚠️ Batch skill download failed: HTTP #httpResult.statusCode#. Try again." )
				.println( "ErrorDetail: #httpResult.fileContent#" )
			return []
		}

		try {
			var response = deserializeJSON( httpResult.fileContent )
			return isStruct( response ) && response.keyExists( "data" ) ? response.data : response
		} catch ( any e ) {
			variables.print
				.printLine( "⚠️ Failed to parse batch download response: #e.message#" )
				.println( "Content: #httpResult.fileContent#" )
			return []
		}
	}

	/**
	 * Fetch the skill list for a repo from the registry (for SHA comparison).
	 *
	 * @owner GitHub owner/org
	 * @repo  GitHub repo name
	 *
	 * @return Array of {name, path, sha, slug, category, description} or empty array on failure
	 */
	array function fetchRepoSkillList( required string owner, required string repo ){
		var registryUrl = variables.settings.skillsRegistryUrl
		var targetUrl   = "#registryUrl#/api/skills/#arguments.owner#/#arguments.repo#"
		var httpResult = ""
		cfhttp(
			method  = "GET",
			url     = targetUrl,
			result  = "httpResult",
			timeout = 30
		);

		if ( httpResult.statusCode >= 400 ) {
			variables.print
				.printLine( "🔴Failed to fetch skill list for #arguments.owner#/#arguments.repo#: HTTP #httpResult.statusCode#" )
				.println( "ErrorDetail: #httpResult.fileContent#" )
				.toConsole()
			return []
		}

		try {
			var response = deserializeJSON( httpResult.fileContent )
			return isStruct( response ) && response.keyExists( "data" ) ? response.data : response
		} catch ( any e ) {
			variables.print
				.printLine( "🔴Failed to parse skill list for #arguments.owner#/#arguments.repo#: #e.message#" )
				.println( "ResponseContent: #httpResult.fileContent#" )
				.toConsole()
			return []
		}
	}

	// =========================================================================
	// Private Helpers
	// =========================================================================

	/**
	 * Build the ordered list of skills to install for a project.
	 * Returns array of {owner, repo, slug, name, type, source}.
	 *
	 * @directory The project directory
	 * @language  Project language mode (boxlang, cfml, hybrid)
	 */
	private array function getSkillsMap(
		required string directory,
		string language = "boxlang"
	){
		var targets = []
		var bxRepo  = variables.settings.boxlangSkillsRepo
		var cbRepo  = variables.settings.coldboxSkillsRepo

		// Always: commandbox/* — fetch once, used for both commandbox and boxlang-developer
		var bxRepoList = fetchRepoSkillList( bxRepo.owner, bxRepo.repo )

		bxRepoList
			.filter( ( s ) => s?.category == "commandbox" )
			.each( ( s ) => {
				targets.append( {
					owner  : bxRepo.owner,
					repo   : bxRepo.repo,
					slug   : s.slug,
					name   : s.name,
					type   : "commandbox",
					source : "commandbox"
				} )
			} )

		// BoxLang projects: boxlang-developer/* (no boxlang-core-development — Java only)
		if ( arguments.language != "cfml" ) {
			bxRepoList
				.filter( ( s ) => s?.category == "boxlang-developer" )
				.each( ( s ) => {
					targets.append( {
						owner  : bxRepo.owner,
						repo   : bxRepo.repo,
						slug   : s.slug,
						name   : s.name,
						type   : "core",
						source : "boxlang"
					} )
				} )
		}

		// ColdBox / TestBox / modules from coldbox/skills
		var boxJson         = variables.packageService.readPackageDescriptor( arguments.directory )
		var allDependencies = {}
		allDependencies.append( boxJson.dependencies    ?: {} )
		allDependencies.append( boxJson.devDependencies ?: {} )

		var depsLower = allDependencies.keyList().lcase()
		var hasColdBox = depsLower.listFindNoCase( "coldbox" )
		var hasTestBox = depsLower.listFindNoCase( "testbox" )

		if ( hasColdBox || hasTestBox ) {
			var cbRepoList = fetchRepoSkillList( cbRepo.owner, cbRepo.repo )
			var coldboxFrameworks = [ "coldbox", "cachebox", "logbox", "wirebox" ]

			if ( hasColdBox ) {
				cbRepoList
					.filter( ( s ) => s?.category == "coldbox" || coldboxFrameworks.contains( s?.slug ) )
					.each( ( s ) => {
						targets.append( { owner: cbRepo.owner, repo: cbRepo.repo, slug: s.slug, name: s.name, type: "core", source: "coldbox" } )
					} )
			}

			if ( hasTestBox ) {
				cbRepoList
					.filter( ( s ) => s?.category == "testbox" )
					.each( ( s ) => {
						targets.append( { owner: cbRepo.owner, repo: cbRepo.repo, slug: s.slug, name: s.name, type: "core", source: "testbox" } )
					} )
			}

			// Module-specific skills: one skill per installed module slug in coldbox/skills/modules/*
			cbRepoList
				.filter( ( s ) => s?.category == "modules" )
				.each( ( s ) => {
					var moduleSlug = s.name
					if ( allDependencies.keyExists( moduleSlug ) ) {
						targets.append( { owner: cbRepo.owner, repo: cbRepo.repo, slug: s.slug, name: s.name, type: "module", source: moduleSlug } )
					}
				} )
		}

		return targets
	}

	/**
	 * Write a skill file and upsert the manifest entry.
	 *
	 * @directory   Project directory
	 * @name        Local skill name (directory name)
	 * @content     SKILL.md content
	 * @owner       GitHub owner
	 * @repo        GitHub repo
	 * @path        skill_dir from registry
	 * @sha         file_sha from registry
	 * @description Skill description
	 * @auditStatus Audit status
	 * @skillType   Manifest type: core|module|commandbox|custom
	 * @source      Module slug when type=module
	 * @manifest    Manifest struct (mutated in place)
	 */
	private function installRemoteSkill(
		required string directory,
		required string name,
		required string content,
		required string owner,
		required string repo,
		required string path,
		required string sha,
		required string description,
		required string auditStatus,
		required string skillType,
		required string source,
		required struct manifest
	){
		var slug     = arguments.path.listLast( "/" )
		var skillDir = "#arguments.directory#/.ai/skills/#arguments.name#"

		if ( !directoryExists( skillDir ) ) {
			directoryCreate( skillDir, true )
		}
		fileWrite( "#skillDir#/SKILL.md", arguments.content )

		// Upsert manifest entry
		var existingIndex = 0
		for ( var i = 1; i <= arguments.manifest.skills.len(); i++ ) {
			if ( arguments.manifest.skills[ i ].name == arguments.name ) { existingIndex = i; break }
		}

		var entry = {
			"name"       : arguments.name,
			"owner"      : arguments.owner,
			"repo"       : arguments.repo,
			"path"       : arguments.path,
			"slug"       : slug,
			"sha"        : arguments.sha,
			"description": arguments.description,
			"type"       : arguments.skillType,
			"source"     : arguments.source,
			"syncedAt"   : dateTimeFormat( now(), "iso" )
		}

		if ( existingIndex ) {
			arguments.manifest.skills[ existingIndex ] = entry
		} else {
			arguments.manifest.skills.append( entry )
		}
	}

	/**
	 * Delete a skill directory under .ai/skills/ if it exists.
	 *
	 * @directory The project directory
	 * @name      The skill name (directory name)
	 */
	private function deleteSkillDir( required string directory, required string name ){
		var skillDir = "#arguments.directory#/.ai/skills/#arguments.name#"
		if ( directoryExists( skillDir ) ) {
			directoryDelete( skillDir, true )
		}
	}


}
