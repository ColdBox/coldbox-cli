/**
 * Remove a skill from the project by name.
 * Skills are stored in the flat .ai/skills/{name}/ directory.
 *
 * Examples:
 * coldbox ai skills remove boxlang-syntax
 * coldbox ai skills remove api-patterns --force
 */
component extends="coldbox-cli.models.BaseAICommand" {

	// DI
	property name="skillManager" inject="SkillManager@coldbox-cli";

	/**
	 * Run the command
	 *
	 * @name      The skill name to remove
	 * @force     Skip confirmation prompt
	 * @directory The target directory (defaults to current directory)
	 */
	function run(
		required string name,
		boolean force    = false,
		string directory = getCwd()
	){
		showColdBoxBanner( "Remove Skill" )
		ensureInstalled( arguments.directory )

		// Replace spaces with dashes for skill name
		arguments.name = arguments.name.replaceAll( "\s+", "-" )
		print.line()
		printInfo( "Removing skill: #arguments.name#" )
		print.line()

		// Confirm deletion
		if ( !arguments.force ) {
			if ( !confirm( "Are you sure you want to remove '#arguments.name#'? [y/n]" ) ) {
				printInfo( "Operation cancelled." )
				return
			}
		}

		// Remove the skill
		try {
			variables.skillManager.removeSkillFromProject( arguments.directory, arguments.name )
		} catch ( any e ) {
			printError( "Failed to remove skill: #e.message#" )
			print.line()
			if ( e.type == "SkillManager.SkillNotFound" ) {
				printTip( "Use 'coldbox ai skills list' to see available skills" )
			}
			return
		}

		// Regenerate agent files
		print.line()
		printInfo( "Regenerating agent configuration files..." )
		variables.aiService.refresh( arguments.directory )

		print.line()
		printSuccess( "✓ Skill '#arguments.name#' removed successfully!" )
		print.line()
		printTip( "Use 'coldbox ai skills list' to see remaining skills" )
	}

}
