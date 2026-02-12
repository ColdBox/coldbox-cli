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
component extends="coldbox-cli.models.BaseAICommand" {

	/**
	 * Run the command
	 *
	 * @agent Comma-separated list of AI agents to configure (claude,copilot,codex,gemini,opencode)
	 * @language Project language mode: boxlang, cfml, hybrid
	 * @force Overwrite existing AI configuration
	 * @directory The target directory (defaults to current directory)
	 * @boxlang Is the project BoxLang (auto-detected)
	 * @showBanner Whether to show the ColdBox banner (default: true)
	 */
	function run(
		string agent       = "",
		string language    = "",
		boolean force      = false,
		string directory   = getCwd(),
		boolean boxlang    = isBoxLangProject( getCWD() ),
		boolean showBanner = true
	){
		if ( arguments.showBanner ) {
			showColdBoxBanner( "AI Integration Installer" )
		}

		// Prompt for agents if not specified
		if ( !len( arguments.agent ) ) {
			arguments.agent = promptForAgents()
		}

		// Auto-detect or prompt for language
		if ( !len( arguments.language ) ) {
			if ( arguments.boxlang ) {
				arguments.language = "boxlang"
				printInfo( "🥊 BoxLang project detected - language set to BoxLang" )
			} else {
				arguments.language = promptForLanguage()
			}
		}

		printInfo( "🔧  Installing AI integration..." )
		printInfo( "🤖  Agent(s): #arguments.agent#" )
		printInfo( "🔤  Language: #arguments.language#" )

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
			printSuccess( "🍭  AI integration installed successfully!" );

			// Show what was installed
			printInfo( "Guidelines installed: #result.guidelines.len()#" );
			result.guidelines.each( function( guideline ){
				print.indentedLine( "  • #guideline#" );
			} );
			print.line();

			printInfo( "Skills installed: #result.skills.len()#" );
			result.skills
				.sort( "textnocase" )
				.each( function( skill ){
					print.indentedLine( "  • #skill#" );
				} );
			print.line();

			printInfo( "Agents configured:" );
			result.agents.each( function( agent ){
				print.indentedLine( "  • #agent#" );
			} );
			// If only 1 agent, show it was set as active
			if ( result.agents.len() == 1 ) {
				printSuccess( "  ✓ Automatically set as active agent" );
			}
			print.line();

			// Show MCP servers
			var totalMcpServers = result.mcpServers.core.len() + result.mcpServers.module.len();
			printInfo( "MCP Servers configured: #totalMcpServers#" );
			if ( result.mcpServers.core.len() ) {
				print.indentedCyanLine( "  Core (#result.mcpServers.core.len()#): #result.mcpServers.core.toList( ", " )#" );
			}
			if ( result.mcpServers.module.len() ) {
				print.indentedCyanLine( "  Module (#result.mcpServers.module.len()#): #result.mcpServers.module.toList( ", " )#" );
			}
			print.line();

			// Show next steps
			printTip( "Next Steps:" );
			print.indentedLine( "1. Review generated agent files (CLAUDE.md, etc.)" );
			print.indentedLine( "2. Install modules as needed (box install cbsecurity, quick, etc.)" );
			print.indentedLine( "3. Run 'coldbox ai info' to verify integrations" );
			print.indentedLine( "4. Run 'coldbox ai refresh' after installing modules" );
			print.indentedLine( "5. Run 'coldbox ai doctor' to verify configuration" );
			print.line();

			printInfo( "Your AI assistant is now configured with ColdBox + #arguments.language# knowledge!" );
		} catch ( any e ) {
			printError( "Failed to install AI integration: #e.message#" );
			printError( e.stackTrace );
		}
	}

	/**
	 * Prompt user to select AI agents (multi-select)
	 */
	private function promptForAgents(){
		print.line()
		printWarn( "🤖 Agent Selection" )
		print.line()

		var agentOptions = [
			{
				"display" : "Claude (Anthropic) - Recommended for general development",
				"value"   : "claude"
			},
			{
				"display" : "GitHub Copilot - Integrated with VS Code",
				"value"   : "copilot"
			},
			{
				"display" : "Cursor AI - AI-first code editor",
				"value"   : "cursor"
			},
			{
				"display" : "Codex (OpenAI) - GPT-powered coding assistant",
				"value"   : "codex"
			},
			{
				"display" : "Gemini (Google) - Google's AI assistant",
				"value"   : "gemini"
			},
			{
				"display" : "OpenCode - Open source AI assistant",
				"value"   : "opencode"
			}
		]

		var selected = multiSelect( "Select one or more AI agents to configure (use spacebar to select, enter to confirm):" )
			.options( agentOptions )
			.multiple()
			.required()
			.ask()

		// Convert array of selections to comma-separated string
		return selected.toList()
	}

	/**
	 * Prompt user to select language mode
	 */
	private function promptForLanguage(){
		print.line()
		printWarn( "🌟 Language Selection" )
		print.line()

		var languageOptions = [
			{
				"display" : "BoxLang (recommended) - Modern class-based syntax",
				"value"   : "boxlang"
			},
			{
				"display" : "CFML - Traditional component syntax",
				"value"   : "cfml"
			},
			{
				"display" : "Hybrid - Support both BoxLang and CFML",
				"value"   : "hybrid"
			}
		]

		return multiSelect( "Choose your project's primary language:" )
			.options( languageOptions )
			.required()
			.ask()
	}

}
