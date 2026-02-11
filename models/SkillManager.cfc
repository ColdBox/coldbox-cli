/**
 * Manages AI skills (implementation patterns and code templates)
 * Skills are loaded on-demand when AI needs specific implementation guidance
 */
component singleton {

	// DI
	property name="print"          inject="PrintBuffer";
	property name="fileSystemUtil" inject="fileSystem";
	property name="packageService" inject="PackageService";
	property name="wirebox"        inject="wirebox";
	property name="utility"        inject="Utility@coldbox-cli";
	property name="aiService"      inject="AIService@coldbox-cli";

	/**
	 * Install core skills for a project
	 *
	 * @directory The project directory
	 * @language Project language mode (boxlang, cfml, hybrid)
	 * @manifest The manifest struct to update
	 */
	function installCoreSkills(
		required string directory,
		required string language,
		required struct manifest
	){
		var installed = [];

		// Core skills - always installed based on language
		var coreSkills = getCoreSkillsList( arguments.language );

		coreSkills.each( ( skillName ) => {
			installSkill(
				directory,
				skillName,
				"core",
				manifest
			)
			installed.append( skillName )
		} )

		return installed;
	}

	/**
	 * Refresh skills based on installed modules
	 * - Updates module skills based on box.json dependencies
	 * - Syncs custom skills from .ai/skills/custom/
	 * - Syncs override skills from .ai/skills/overrides/
	 * - Removes manifest entries for deleted files
	 * - Removes skills for uninstalled modules
	 *
	 * @directory The project directory
	 * @manifest The manifest struct to update
	 */
	function refresh(
		required string directory,
		required struct manifest
	){
		var changes = {
			"added"   : [],
			"updated" : [],
			"removed" : []
		};

		// Get installed modules from box.json
		var boxJson         = variables.packageService.readPackageDescriptor( arguments.directory );
		var dependencies    = boxJson.dependencies ?: {};
		var devDependencies = boxJson.devDependencies ?: {};
		var allDependencies = {};
		allDependencies.append( dependencies );
		allDependencies.append( devDependencies );

		// Map of module slugs to skills
		var skillMap = getSkillModuleMap();

		// Install/update skills for installed modules
		for ( var moduleSlug in allDependencies ) {
			if ( structKeyExists( skillMap, moduleSlug ) ) {
				var skills = skillMap[ moduleSlug ];
				skills.each( ( skillName ) => {
					var existing = manifest.skills.filter( ( s ) => {
						return s.name == skillName
					} )

					if ( existing.len() ) {
						// Already installed - check if needs update
						// For now, just mark as updated if module version changed
						changes.updated.append( skillName )
					} else {
						// New skill
						installSkill(
							directory,
							skillName,
							moduleSlug,
							manifest
						)
						changes.added.append( skillName )
					}
				} )
			}
		}

		// Remove skills for uninstalled modules (but keep core and custom skills)
		var toRemove = [];
		for ( var skill in manifest.skills ) {
			var skillSource = skill.source ?: ""
			var skillType   = skill.type ?: ""

			// Don't remove core, custom, or override skills
			if ( skillSource == "core" || skillSource == "user" || skillType == "custom" || skillType == "override" ) {
				continue;
			}

			// Remove module skills if module no longer installed
			if ( !structKeyExists( allDependencies, skillSource ) ) {
				toRemove.append( skill.name );
			}
		}

		toRemove.each( ( name ) => {
			removeSkill( directory, name, manifest )
			changes.removed.append( name )
		} )

		// Sync custom skills from filesystem
		var customDir = "#arguments.directory#/.ai/skills/custom"
		if ( directoryExists( customDir ) ) {
			var customDirs = directoryList( customDir, false, "name" )
			customDirs.each( ( dirName ) => {
				var skillPath = "#customDir#/#dirName#/SKILL.md"
				if ( fileExists( skillPath ) ) {
					// Check if in manifest
					var existing = manifest.skills.filter( ( s ) => s.name == dirName )
					if ( !existing.len() ) {
						// Add to manifest
						manifest.skills.append( {
							"name"             : dirName,
							"source"           : "custom",
							"type"             : "custom",
							"installedVersion" : variables.utility.getColdboxCliVersion(),
							"syncedAt"         : dateTimeFormat( now(), "iso" )
						} )
						changes.added.append( dirName )
					}
				}
			} )
		}

		// Sync override skills from filesystem
		var overridesDir = "#arguments.directory#/.ai/skills/overrides"
		if ( directoryExists( overridesDir ) ) {
			var overrideFiles = directoryList( overridesDir, false, "name", "*.md" )
			overrideFiles.each( ( fileName ) => {
				var baseName     = replaceNoCase( fileName, ".md", "" )
				var manifestName = "#baseName#-override"

				// Check if in manifest
				var existing = manifest.skills.filter( ( s ) => s.name == manifestName )
				if ( !existing.len() ) {
					// Add to manifest
					manifest.skills.append( {
						"name"             : manifestName,
						"source"           : "user",
						"type"             : "override",
						"installedVersion" : variables.utility.getColdboxCliVersion(),
						"syncedAt"         : dateTimeFormat( now(), "iso" )
					} )
					changes.added.append( manifestName )
				}
			} )
		}

		// Remove manifest entries for files/directories that no longer exist
		var orphanedSkills = []
		for ( var skill in manifest.skills ) {
			var skillType   = skill.type ?: ""
			var skillSource = skill.source ?: skill.type ?: ""
			var skillPath   = ""

			// Determine expected file/directory path
			if ( skillSource == "core" ) {
				skillPath = "#arguments.directory#/.ai/skills/core/#skill.name#/SKILL.md"
			} else if ( skillType == "custom" ) {
				skillPath = "#arguments.directory#/.ai/skills/custom/#skill.name#/SKILL.md"
			} else if ( skillType == "override" ) {
				var baseName = replaceNoCase( skill.name, "-override", "" )
				skillPath    = "#arguments.directory#/.ai/skills/overrides/#baseName#.md"
			} else {
				// Module skill
				skillPath = "#arguments.directory#/.ai/skills/modules/#skill.name#/SKILL.md"
			}

			// Check if file exists
			if ( skillPath.len() && !fileExists( skillPath ) ) {
				orphanedSkills.append( skill.name )
			}
		}

		orphanedSkills.each( ( name ) => {
			manifest.skills = manifest.skills.filter( ( s ) => s.name != name )
			changes.removed.append( name )
		} )

		return changes;
	}

	/**
	 * Create a custom skill from template
	 *
	 * @directory The project directory
	 * @name The custom skill name
	 * @language The language variant (boxlang or cfml)
	 */
	function createCustomSkill(
		required string directory,
		required string name,
		string language = "boxlang"
	){
		var targetDir = "#arguments.directory#/.ai/skills/custom/#arguments.name#"
		var skillFile = "#targetDir#/SKILL.md"

		// Ensure custom directory exists
		if ( !directoryExists( targetDir ) ) {
			directoryCreate( targetDir, true )
		}

		// Create skill from template
		var languageSuffix = arguments.language == "cfml" ? ".cfml" : ".bx"
		var templatePath   = variables.utility.getTemplatesPath() & "/ai/skills/custom-skill-template#languageSuffix#.md"
		var template       = fileRead( templatePath )

		// Replace tokens
		template = replaceNoCase(
			template,
			"|skillName|",
			arguments.name,
			"all"
		)
		fileWrite( skillFile, template )

		// Update manifest
		var manifest = variables.aiService.loadManifest( arguments.directory );

		manifest.skills.append( {
			"name"             : arguments.name,
			"source"           : "custom",
			"installedVersion" : "1.0.0",
			"syncedAt"         : dateTimeFormat( now(), "iso" )
		} )

		variables.aiService.saveManifest( arguments.directory, manifest )
	}

	/**
	 * Remove a skill from the project
	 *
	 * @directory The project directory
	 * @name The skill name to remove
	 * @type The skill type (core, module, custom, override)
	 */
	function removeSkillFromProject(
		required string directory,
		required string name,
		required string type
	){
		// Determine file/directory location based on type
		var skillPath    = ""
		var manifestName = arguments.name

		if ( arguments.type == "override" ) {
			// Override files are stored with base name, manifest has -override suffix
			skillPath    = "#arguments.directory#/.ai/skills/overrides/#arguments.name#.md"
			manifestName = "#arguments.name#-override"
		} else if ( arguments.type == "core" ) {
			skillPath = "#arguments.directory#/.ai/skills/core/#arguments.name#"
		} else if ( arguments.type == "module" ) {
			skillPath = "#arguments.directory#/.ai/skills/modules/#arguments.name#"
		} else if ( arguments.type == "custom" ) {
			skillPath = "#arguments.directory#/.ai/skills/custom/#arguments.name#"
		}

		// Check if path exists
		if ( !fileExists( skillPath ) && !directoryExists( skillPath ) ) {
			throw(
				type    = "SkillManager.SkillNotFound",
				message = "#arguments.type# skill '#arguments.name#' not found at: #skillPath#"
			)
		}

		// Delete the file or directory
		if ( fileExists( skillPath ) ) {
			fileDelete( skillPath )
		} else {
			directoryDelete( skillPath, true )
		}

		// Update manifest
		var manifest    = variables.aiService.loadManifest( arguments.directory )
		manifest.skills = manifest.skills.filter( ( s ) => s.name != manifestName )
		variables.aiService.saveManifest( arguments.directory, manifest )

		return true
	}

	/**
	 * Create a skill override
	 *
	 * @directory The project directory
	 * @name The name of the skill to override
	 * @type The skill type (core or module)
	 */
	function createSkillOverride(
		required string directory,
		required string name,
		required string type
	){
		// Load manifest
		var manifest = variables.aiService.loadManifest( arguments.directory )

		// Determine source path based on type
		var sourcePath = arguments.type == "core"
		 ? "#arguments.directory#/.ai/skills/core/#arguments.name#/SKILL.md"
		 : "#arguments.directory#/.ai/skills/modules/#arguments.name#/SKILL.md"

		if ( !fileExists( sourcePath ) ) {
			throw(
				type    = "SkillManager.SkillNotFound",
				message = "Skill '#arguments.name#' not found at: #sourcePath#"
			)
		}

		// Read the original skill content
		var originalContent = fileRead( sourcePath )

		// Read override template
		var templatesPath = variables.utility.getTemplatesPath() & "/ai/skills/"
		var templatePath  = templatesPath & "skill-override-template.md"

		if ( !fileExists( templatePath ) ) {
			throw(
				type    = "SkillManager.TemplateNotFound",
				message = "Override template not found: #templatePath#"
			)
		}

		var content = fileRead( templatePath )

		// Replace placeholders
		content = replaceNoCase(
			content,
			"|skillName|",
			arguments.name,
			"all"
		)
		content = replaceNoCase(
			content,
			"|coreContent|",
			originalContent,
			"all"
		)

		// Ensure overrides directory exists
		var overridesDir = "#arguments.directory#/.ai/skills/overrides"
		if ( !directoryExists( overridesDir ) ) {
			directoryCreate( overridesDir, true )
		}

		var targetFile = "#overridesDir#/#arguments.name#.md"

		// Write override file
		fileWrite( targetFile, content )

		// Update manifest with override entry
		var skillEntry = {
			"name"             : "#arguments.name#-override",
			"source"           : "user",
			"type"             : "override",
			"installedVersion" : variables.utility.getColdboxCliVersion(),
			"syncedAt"         : dateTimeFormat( now(), "iso" )
		}

		manifest.skills.append( skillEntry )

		// Save manifest
		variables.aiService.saveManifest( arguments.directory, manifest )

		return targetFile
	}

	/**
	 * Diagnose skill health
	 *
	 * @directory The project directory
	 * @manifest The manifest struct
	 */
	function diagnose(
		required string directory,
		required struct manifest
	){
		var issues = {
			"warnings"        : [],
			"recommendations" : []
		};

		// Check for missing core skills
		var language   = manifest.language ?: "boxlang";
		var coreSkills = getCoreSkillsList( language );

		coreSkills.each( ( skillName ) => {
			var found = manifest.skills.filter( ( s ) => {
				return s.name == skillName
			} )
			if ( !found.len() ) {
				issues.warnings.append( "Missing core skill: #skillName#" )
				issues.recommendations.append( "Run 'coldbox ai refresh' to install missing skills" )
			}
		} )

		// Check skill directories exist
		for ( var skill in manifest.skills ) {
			var skillDir = skill.source == "core" ? "#arguments.directory#/.ai/skills/core/#skill.name#" : "#arguments.directory#/.ai/skills/modules/#skill.name#";

			if ( !directoryExists( skillDir ) ) {
				issues.warnings.append( "Skill directory missing: #skill.name#" );
				issues.recommendations.append( "Run 'coldbox ai refresh' to regenerate missing skills" );
			}
		}

		return issues;
	}

	// ========================================
	// Private Helpers
	// ========================================

	/**
	 * Get list of core skills based on language mode
	 *
	 * @language Project language mode (boxlang, cfml, hybrid)
	 */
	private function getCoreSkillsList( required string language ){
		var skills = [];

		// ColdBox skills - always included
		skills.append( "handler-development", true );
		skills.append( "rest-api-development", true );
		skills.append( "module-development", true );
		skills.append( "interceptor-development", true );
		skills.append( "routing-development", true );
		skills.append( "event-model", true );
		skills.append( "view-rendering", true );
		skills.append( "layout-development", true );
		skills.append( "cache-integration", true );

		// BoxLang skills
		if ( arguments.language != "cfml" ) {
			skills.append( "boxlang-syntax", true );
			skills.append( "boxlang-classes", true );
			skills.append( "boxlang-functions", true );
			skills.append( "boxlang-lambdas", true );
			skills.append( "boxlang-modules", true );
			skills.append( "boxlang-streams", true );
			skills.append( "boxlang-types", true );
			skills.append( "boxlang-interop", true );
		}

		// CFML skills
		if ( arguments.language != "boxlang" ) {
			skills.append( "cfml-development", true );
		}

		// Testing skills - always included
		skills.append( "testing-bdd", true );
		skills.append( "testing-unit", true );
		skills.append( "testing-integration", true );
		skills.append( "testing-handler", true );
		skills.append( "testing-mocking", true );
		skills.append( "testing-fixtures", true );
		skills.append( "testing-coverage", true );
		skills.append( "testing-ci", true );

		return skills;
	}

	/**
	 * Install a single skill
	 *
	 * @directory The project directory
	 * @skillName The name of the skill to install
	 * @source The source of the skill (core or module slug)
	 * @manifest The manifest struct to update
	 */
	private function installSkill(
		required string directory,
		required string skillName,
		required string source,
		required struct manifest
	){
		// Determine target directory
		var targetDir = arguments.source == "core" ? "core" : "modules";
		var skillDir  = "#arguments.directory#/.ai/skills/#targetDir#/#arguments.skillName#";

		// Create skill directory
		if ( !directoryExists( skillDir ) ) {
			directoryCreate( skillDir );
		}

		// Create SKILL.md file with frontmatter (check if module ships its own)
		var content = getSkillContent(
			skillName  = arguments.skillName,
			directory  = arguments.directory,
			moduleSlug = arguments.source != "core" ? arguments.source : ""
		);
		fileWrite( "#skillDir#/SKILL.md", content );

		// Update manifest
		var existingIndex = 0;
		for ( var i = 1; i <= arguments.manifest.skills.len(); i++ ) {
			if ( arguments.manifest.skills[ i ].name == arguments.skillName ) {
				existingIndex = i;
				break;
			}
		}

		var skillEntry = {
			"name"             : arguments.skillName,
			"source"           : arguments.source,
			"installedVersion" : variables.utility.getColdboxCliVersion(),
			"syncedAt"         : dateTimeFormat( now(), "iso" )
		};

		if ( existingIndex ) {
			arguments.manifest.skills[ existingIndex ] = skillEntry;
		} else {
			arguments.manifest.skills.append( skillEntry );
		}
	}

	/**
	 * Remove a skill
	 *
	 * @directory The project directory
	 * @skillName The name of the skill to remove
	 * @manifest The manifest struct to update
	 */
	private function removeSkill(
		required string directory,
		required string skillName,
		required struct manifest
	){
		// Remove directory
		var possiblePaths = [
			"#arguments.directory#/.ai/skills/core/#arguments.skillName#",
			"#arguments.directory#/.ai/skills/modules/#arguments.skillName#"
		];

		possiblePaths.each( ( path ) => {
			if ( directoryExists( path ) ) {
				directoryDelete( path, true )
			}
		} )

		// Remove from manifest
		arguments.manifest.skills = arguments.manifest.skills.filter( ( s ) => {
			return s.name != skillName
		} )
	}

	/**
	 * Get skill content (reads from template files or module-shipped skills)
	 *
	 * @skillName The name of the skill to retrieve content for
	 * @directory Optional project directory (for checking module-shipped skills)
	 * @moduleSlug Optional module slug (for module-specific skills)
	 */
	private function getSkillContent(
		required string skillName,
		string directory  = "",
		string moduleSlug = ""
	){
		// 1. If moduleSlug provided, check if module ships its own skill at .ai/skills/<skillName>/SKILL.md
		if ( arguments.moduleSlug.len() && arguments.directory.len() ) {
			var moduleSkill = "#arguments.directory#/modules/#arguments.moduleSlug#/.ai/skills/#arguments.skillName#/SKILL.md"
			if ( fileExists( moduleSkill ) ) {
				return fileRead( moduleSkill )
			}
		}

		// 2. Check coldbox-cli bundled template
		var templatePath = variables.utility.getTemplatesPath() & "/ai/skills/#arguments.skillName#.md";
		if ( fileExists( templatePath ) ) {
			return fileRead( templatePath );
		}

		// 3. Try generic template
		templatePath = variables.utility.getTemplatesPath() & "/ai/skills/skill-template.md";
		if ( fileExists( templatePath ) ) {
			var content = fileRead( templatePath );
			// Replace placeholder with actual skill name
			content     = replaceNoCase(
				content,
				"skill-template",
				arguments.skillName,
				"all"
			);
			content = replaceNoCase(
				content,
				"Skill Name",
				arguments.skillName,
				"all"
			);
			return content;
		}

		// 4. Final fallback
		return "---
name: #arguments.skillName#
description: Implementation patterns for #arguments.skillName#
category: development
---

## #arguments.skillName# Implementation Pattern

This skill will be populated with actual content.";
	}

	/**

	 * Get map of module slugs to skills
	 */
	private function getSkillModuleMap(){
		return {
			"cbsecurity" : [
				"security-implementation",
				"authentication",
				"authorization",
				"jwt-development",
				"csrf-protection",
				"api-authentication",
				"rbac-patterns"
			],
			"cbauth"                : [ "authentication" ],
			"cbsso"                 : [ "sso-integration" ],
			"quick"                 : [ "orm-quick", "orm-relationships" ],
			"qb"                    : [ "query-builder" ],
			"commandbox-migrations" : [ "database-migrations" ],
			"cbwire"                : [ "cbwire-development" ],
			"cbq"                   : [ "queue-development" ]
		};
	}

}
