component excludeFromHelp=true extends="coldbox-cli.models.BaseCommand" {

	function run(){
		showColdBoxBanner( "AI Integration" )
		print.line();
		print
			.boldCyan( "ColdBox AI Integration Commands" )
			.line()
			.line()
			.whiteLine( "Enhance your development workflow with AI-powered assistants" )
			.line()
			.boldWhiteLine( "Setup & Management:" )
			.line()
			.greenLine( "  coldbox ai install          Set up AI integration for your project" )
			.greenLine( "  coldbox ai refresh          Sync guidelines and skills with installed modules" )
			.greenLine( "  coldbox ai info             Display current AI configuration" )
			.greenLine( "  coldbox ai doctor           Diagnose AI integration health" )
			.line()
			.boldWhiteLine( "Component Management:" )
			.line()
			.greenLine( "  coldbox ai agents           Manage AI agent configurations (Claude, Copilot, etc.)" )
			.greenLine( "  coldbox ai guidelines       Manage framework guidelines and documentation" )
			.greenLine( "  coldbox ai skills           Manage AI skills (how-to cookbooks)" )
			.greenLine( "  coldbox ai mcp              Manage MCP documentation servers" )
			.line()
			.yellowLine( "Examples:" )
			.line()
			.dim( "  ## Set up AI integration with Claude" )
			.line( "  coldbox ai install --agents=claude" )
			.line()
			.dim( "  ## Add GitHub Copilot support" )
			.line( "  coldbox ai agents add copilot" )
			.line()
			.dim( "  ## List installed guidelines" )
			.line( "  coldbox ai guidelines list" )
			.line()
			.line()
			.yellowLine( "Tip: Type 'coldbox ai <command> --help' for detailed command information" )
			.line()
	}

}
