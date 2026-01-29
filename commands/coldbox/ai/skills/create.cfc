/**
 * Create a custom skill template
 * Scaffolds a new skill in .ai/skills/custom/
 *
 * Examples:
 * coldbox ai skills create api-development
 * coldbox ai skills create testing-patterns --open
 */
component extends="coldbox-cli.models.BaseCommand" {

	// DI
	property name="skillManager" inject="SkillManager@coldbox-cli";
	property name="aiService"    inject="AIService@coldbox-cli";

	/**
	 * Run the command
	 *
	 * @name The custom skill name
	 * @open Open the created file in the default editor
	 * @directory The target directory (defaults to current directory)
	 */
	function run(
		required string name,
		boolean open     = false,
		string directory = getCwd()
	){
		showColdBoxBanner( "Create Custom Skill" )

		var info = variables.aiService.getInfo( arguments.directory )

		if ( !info.installed ) {
			printError( "AI integration not installed. Run 'coldbox ai install' first." )
			return
		}

		print.line()
		printInfo( "Creating custom skill: #arguments.name#" )
		print.line()

		// Check if already exists
		var skillPath = "#arguments.directory#/.ai/skills/custom/#arguments.name#/SKILL.md"
		if ( fileExists( skillPath ) ) {
			printError( "Skill '#arguments.name#' already exists at:" )
			printError( "  #skillPath#" )
			print.line()

			if ( !confirm( "Do you want to overwrite it? [y/n]" ) ) {
				printInfo( "Operation cancelled." )
				return
			}
		}

		// Create skill from template
		variables.skillManager.createCustomSkill(
			arguments.directory,
			arguments.name
		)

		// Update manifest
		variables.aiService.updateManifest(
			arguments.directory,
			{ "lastSync": dateTimeFormat( now(), "iso" ) }
		)

		// Regenerate agent files
		print.line()
		printInfo( "Regenerating agent configuration files..." )
		variables.aiService.refresh( arguments.directory )

		print.line()
		printSuccess( "✓ Custom skill created at:" )
		printSuccess( "  #skillPath#" )
		print.line()

		printInfo( "Skill Structure:" )
		printInfo( "  • SKILL.md contains the skill definition" )
		printInfo( "  • Add triggers to determine when the skill is activated" )
		printInfo( "  • Include code examples and best practices" )
		printInfo( "  • Use markdown formatting for clarity" )
		print.line()

		printHelp( "Tip: Edit the SKILL.md file to define when and how this skill should be used" )

		if ( arguments.open ) {
			openPath( skillPath )
		}
	}

}
