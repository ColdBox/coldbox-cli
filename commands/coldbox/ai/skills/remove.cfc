/**
 * Remove a skill from the project by name.
 * Skills are stored in the flat .agents/skills/{name}/ directory.
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

		// Check if skill exists, else exit with message
		var exists = variables.skillManager.hasSkill( arguments.directory, arguments.name )
		if ( !exists ) {
			printError( "Skill '#arguments.name#' not found." )
			print.line()
			printTip( "Use 'coldbox ai skills list' to see available skills" )
			return
		}

		// Confirm deletion
		if ( !arguments.force ) {
			if ( !confirm( "Are you sure you want to remove '#arguments.name#'? [y/n]" ) ) {
				printInfo( "Operation cancelled." )
				return
			}
		}

		// Remove the skill
		// Throws an error if skill not found
		variables.skillManager.removeSkillFromProject( arguments.directory, arguments.name )

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
