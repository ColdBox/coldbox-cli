component excludeFromHelp=true extends="coldbox-cli.models.BaseCommand" {

	function run(){
		showColdBoxBanner()
		print.line();
		print
			.boldCyan( "Welcome to the ColdBox CLI!" )
			.line()
			.line()
			.whiteLine( "Build modern ColdBox applications with ease using BoxLang or CFML." )
			.line()
			.boldWhiteLine( "What you can do:" )
			.line()
			.greenLine( "  • Generate complete applications with coldbox create app-wizard" )
			.greenLine( "  • Scaffold handlers, models, views, and modules" )
			.greenLine( "  • Create REST APIs and CRUD resources" )
			.greenLine( "  • Generate tests (BDD & Unit)" )
			.greenLine( "  • Add Docker, Vite, and database migrations support" )
			.greenLine( "  • Configure AI integration for enhanced development" )
			.greenLine( "  • Reinit and watch your application during development" )
			.line()
			.yellowLine( "Tip: Type 'coldbox create --help' or 'help coldbox <command>' for more details" )
			.line()
			.dim( "Quick start: coldbox create app-wizard | coldbox ai install" )
			.line()
			.line()
			.dim( "ColdBox CLI Version: #config.version#" )
			.line()
			.line()
	}

}
