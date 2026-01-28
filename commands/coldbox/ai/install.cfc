/**
 * Install AI integration for a ColdBox application
 * Sets up guidelines, skills, MCP servers, and agent configurations
 *
 * Examples:
 * coldbox ai install
 * coldbox ai install --agent=claude,copilot
 * coldbox ai install --language=boxlang
 * coldbox ai install --force
 */
component extends="coldbox-cli.models.BaseCommand" {

	// DI
	property name="aiService" inject="AIService@coldbox-cli";
	property name="config"         inject="box:moduleconfig:coldbox-cli";

	/**
	 * Run the command
	 *
	 * @agent Comma-separated list of AI agents to configure (claude,copilot,codex,gemini,opencode)
	 * @language Project language mode: boxlang, cfml, hybrid
	 * @force Overwrite existing AI configuration
	 * @directory The target directory (defaults to current directory)
	 */
	function run(
		string agent    = "claude",
		string language = "",
		boolean force   = false,
		string directory = getCwd()
	){

		showColdBoxBanner( "AI Integration Installer" );

		// Detect language if not specified
		if ( !len( arguments.language ) ) {
			arguments.language = promptForLanguage();
		}

		printInfo( "Installing AI integration..." );
		printInfo( "Agent(s): #arguments.agent#" );
		printInfo( "Language: #arguments.language#" );
		print.line();

		try {
			var result = variables.aiService.install(
				directory = arguments.directory,
				agents    = arguments.agent,
				language  = arguments.language,
				force     = arguments.force
			);

			if ( !result.success ) {
				printError( result.message );
				return;
			}

			// Success!
			printSuccess( "✓ AI integration installed successfully!" );
			print.line();

			// Show what was installed
			printInfo( "Guidelines installed: #result.guidelines.len()#" );
			result.guidelines.each( function( guideline ){
				print.indentedLine( "  • #guideline#" );
			} );
			print.line();

			printInfo( "Skills installed: #result.skills.len()#" );
			result.skills.each( function( skill ){
				print.indentedLine( "  • #skill#" );
			} );
			print.line();

			printInfo( "Agents configured:" );
			result.agents.each( function( agent ){
				print.indentedLine( "  • #agent#" );
			} );
			print.line();

			// Show next steps
			printWarn( "Next Steps:" );
			print.indentedLine( "1. Review generated agent files (CLAUDE.md, etc.)" );
			print.indentedLine( "2. Install modules as needed (box install cbsecurity, quick, etc.)" );
			print.indentedLine( "3. Run 'coldbox ai refresh' after installing modules" );
			print.indentedLine( "4. Run 'coldbox ai doctor' to verify configuration" );
			print.line();

			printInfo( "Your AI assistant is now configured with ColdBox knowledge!" );
		} catch ( any e ) {
			printError( "Failed to install AI integration: #e.message#" );
			printError( e.stackTrace );
		}
	}

	/**
	 * Prompt user to select language mode
	 */
	private function promptForLanguage(){
		print.line();
		printWarn( "🌟 Language Selection" );
		print.line();
		print.line( "Choose your project's primary language:" );
		print.line( "  1. BoxLang (recommended) - Modern class-based syntax" );
		print.line( "  2. CFML - Traditional component syntax" );
		print.line( "  3. Hybrid - Support both BoxLang and CFML" );
		print.line();

		var choice = ask( "Enter choice (1-3): " );
		// Default to BoxLang if empty/ENTER
		if ( !len( trim( choice ) ) ) {
			choice = "1"
		}
		switch ( choice ) {
			case "1":
				return "boxlang";
			case "2":
				return "cfml";
			case "3":
				return "hybrid";
			default:
				printWarn( "Invalid choice, defaulting to BoxLang" );
				return "boxlang";
		}
	}

}
