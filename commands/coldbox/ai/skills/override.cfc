/**
 * Create an override for a core or module skill
 * Copies the skill as a starting point for customization
 *
 * Examples:
 * coldbox ai skills override handler-development
 * coldbox ai skills override rest-api-development --open
 * coldbox ai skills override cbwire-development --open
 */
component extends="coldbox-cli.models.BaseAICommand" {

	// DI
	property name="skillManager" inject="SkillManager@coldbox-cli";

	/**
	 * Run the command
	 *
	 * @name The skill name to override (core or module)
	 * @open Open the created override file in the default editor
	 * @directory The target directory (defaults to current directory)
	 */
	function run(
		required string name,
		boolean open     = false,
		string directory = getCwd()
	){
		showColdBoxBanner( "Override Skill" )

		var info = ensureInstalled( arguments.directory )

		print.line()
		printInfo( "Creating override for: #arguments.name#" )
		print.line()

		// Check if skill exists (core or module)
		var existing = info.skills.filter( ( s ) => s.name == name )
		if ( !existing.len() ) {
			printError( "Skill '#arguments.name#' not found." )
			print.line()
			printHelp( "Use 'coldbox ai skills list' to see available skills" )
			return
		}

		var skill = existing[ 1 ]

		// Check if override already exists
		var overridePath = "#arguments.directory#/.ai/skills/overrides/#arguments.name#.md"
		if ( fileExists( overridePath ) ) {
			printWarn( "Override for '#arguments.name#' already exists at:" )
			printWarn( "  #overridePath#" )
			print.line()

			if ( !confirm( "Do you want to overwrite it? [y/n]" ) ) {
				printInfo( "Operation cancelled." )
				return
			}
		}

		// Determine skill source type
		var skillType = skill.source == "core" ? "core" : "module"

		// Create override from skill
		variables.skillManager.createSkillOverride(
			arguments.directory,
			arguments.name,
			skillType
		)

		// Regenerate agent files
		print.line()
		printInfo( "Regenerating agent configuration files..." )
		variables.aiService.refresh( arguments.directory )

		print.line()
		printSuccess( "✓ Override created at:" )
		printSuccess( "  #overridePath#" )
		print.line()

		printInfo( "Override Guidelines:" )
		printInfo( "  • This override will be loaded AFTER the #skillType# skill" )
		printInfo( "  • You can add project-specific implementation patterns" )
		printInfo( "  • The original skill remains unchanged for reference" )
		printInfo( "  • Agents automatically read overrides from .ai/skills/overrides/" )
		print.line()

		printTip( "Edit the override to customize implementation patterns for your project" )

		if ( arguments.open ) {
			openPath( overridePath )
		}
	}

}
