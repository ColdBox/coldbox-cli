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
			installSkill( directory, skillName, "core", manifest )
			installed.append( skillName )
		} )

		return installed;
	}

	/**
	 * Refresh skills based on installed modules
	 *
	 * @directory The project directory
	 * @manifest The manifest struct to update
	 */
	function refresh( required string directory, required struct manifest ){
		var changes = {
			"added"   : [],
			"updated" : [],
			"removed" : []
		};

		// Get installed modules from box.json
		var boxJson        = variables.packageService.readPackageDescriptor( arguments.directory );
		var dependencies   = boxJson.dependencies ?: {};
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
						installSkill( directory, skillName, moduleSlug, manifest )
						changes.added.append( skillName )
					}
				} )
			}
		}

		// Remove skills for uninstalled modules (but keep core skills)
		var toRemove = [];
		for ( var skill in manifest.skills ) {
			if ( skill.source != "core" && !structKeyExists( allDependencies, skill.source ) ) {
				toRemove.append( skill.name );
			}
		}

		toRemove.each( ( name ) => {
			removeSkill( directory, name, manifest )
			changes.removed.append( name )
		} )

		return changes;
	}

	/**
	 * Diagnose skill health
	 *
	 * @directory The project directory
	 * @manifest The manifest struct
	 */
	function diagnose( required string directory, required struct manifest ){
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

		// Create SKILL.md file with frontmatter
		var content = getSkillContent( arguments.skillName );
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
			"installedVersion" : getColdboxCliVersion(),
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
	 * Get skill content (reads from template files)
	 *
	 * @skillName The name of the skill to retrieve content for
	 */
	private function getSkillContent( required string skillName ){
		var templatePath = getTemplatesPath() & "/ai/skills/#arguments.skillName#.md";

		if ( fileExists( templatePath ) ) {
			return fileRead( templatePath );
		}

		// Use generic template
		templatePath = getTemplatesPath() & "/ai/skills/skill-template.md";
		if ( fileExists( templatePath ) ) {
			var content = fileRead( templatePath );
			// Replace placeholder with actual skill name
			content = replaceNoCase( content, "skill-template", arguments.skillName, "all" );
			content = replaceNoCase( content, "Skill Name", arguments.skillName, "all" );
			return content;
		}

		// Final fallback
		return "---
name: #arguments.skillName#
description: Implementation patterns for #arguments.skillName#
category: development
---

## #arguments.skillName# Implementation Pattern

This skill will be populated with actual content.";
	}

	/**
	 * Get templates path from settings
	 */
	private function getTemplatesPath(){
		var moduleSettings = wirebox.getInstance( "box:modulesettings:coldbox-cli" );
		return moduleSettings.templatesPath;
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
			"cbauth" : [ "authentication" ],
			"cbsso"  : [ "sso-integration" ],
			"quick"  : [ "orm-quick", "orm-relationships" ],
			"qb"     : [ "query-builder" ],
			"commandbox-migrations" : [ "database-migrations" ],
			"cbwire" : [ "cbwire-development" ],
			"cbq"    : [ "queue-development" ]
		};
	}

	/**
	 * Get current coldbox-cli version
	 */
	private function getColdboxCliVersion(){
		// Stub - will get from actual package
		return "1.0.0";
	}

}
