/**
 * Install the ColdBox MCP module (cbMCP) for your project.
 *
 * cbMCP is the official ColdBox MCP (Model Context Protocol) server module.
 * It exposes your running ColdBox application as an MCP server so that AI agents
 * can introspect your live routes, handlers, models, and more at development time.
 *
 * The module is installed as a dev dependency via CommandBox and wired into
 * your project's manifest and .mcp.json automatically.
 *
 * The MCP endpoint is served at: http://<host>:<port>/cbmcp
 * The host and port are resolved automatically: first via CommandBox server.json,
 * then via miniserver.json, and finally falling back to localhost:8080.
 * This requires a running BoxLang/ColdBox server for the AI agent to connect to.
 *
 * GitHub: https://github.com/coldbox-modules/cbmcp
 *
 * Examples:
 * coldbox ai mcp install
 * coldbox ai mcp install --directory=/path/to/project
 */
component extends="coldbox-cli.models.BaseAICommand" {

	// DI
	property name="agentRegistry"  inject="AgentRegistry@coldbox-cli";
	property name="packageService" inject="PackageService";
	property name="serverService"  inject="ServerService";

	/**
	 * Run the command
	 *
	 * @force.hint     Overwrite existing cbmcp entry if already configured
	 * @directory      The target directory (defaults to current directory)
	 */
	function run(
		boolean force    = false,
		string directory = getCwd()
	){
		showColdBoxBanner( "Install cbMCP" );

		var info     = ensureInstalled( arguments.directory );
		if( !info.installed ){
			return;
		}
		var manifest = loadManifest( arguments.directory );

		// Ensure mcpServers structure exists
		if ( !structKeyExists( manifest, "mcpServers" ) ) {
			manifest.mcpServers = {
				"core"   : [],
				"module" : [],
				"custom" : []
			};
		}

		// Check if cbmcp is already configured
		var serverName    = "cbmcp";
		var existingIndex = manifest.mcpServers.custom.findAll( ( s ) => s.name == serverName );

		if ( existingIndex.len() && !arguments.force ) {
			printWarn( "cbMCP is already configured in this project" );
			print.line();
			printTip( "Use --force to overwrite the existing configuration" );
			printTip( "Run 'coldbox ai mcp list' to see the current configuration" );
			return;
		}

		// Resolve host and port - checks server.json, then miniserver.json, then defaults to localhost:8080
		var mcpBase      = resolveServerBaseUrl( arguments.directory );
		var mcpUrl       = "http://#mcpBase#/cbmcp";
		var serverConfig = {
			"name"        : serverName,
			"description" : "ColdBox Application MCP Server (live routes, handlers, models)",
			"url"         : mcpUrl
		};

		print.line();
		printInfo( "Installing cbMCP module..." );
		print.line();

		// Determine modules directory based on template type / language
		var modulesDir = getModulesPrefix( arguments.directory );

		// Install the CommandBox module as a dev dependency
		command( "install" )
			.params(
				id        = "cbmcp",
				saveDev   = true,
				directory = modulesDir
			)
			.inWorkingDirectory( arguments.directory )
			.run();

		print.line();

		// Remove existing cbmcp entry if --force
		if ( existingIndex.len() ) {
			manifest.mcpServers.custom.deleteAt( existingIndex[ 1 ] );
		}

		// Add cbmcp to custom MCP servers
		manifest.mcpServers.custom.append( serverConfig );

		// Save manifest
		saveManifest( arguments.directory, manifest );

		// Regenerate .mcp.json immediately after saving manifest
		generateMCPJson( arguments.directory, manifest );

		// Regenerate all agent config files
		var language = manifest.language ?: "boxlang";
		manifest.agents.each( ( agent ) => {
			variables.agentRegistry.configureAgent( directory, agent, language );
		} );

		// Success output
		print.line();
		printSuccess( "cbMCP installed and configured successfully!" );
		print.line();

		print.boldWhiteLine( "Configuration:" );
		print.greenLine( "  Name:        #serverConfig.name#" );
		print.line( "  Description: #serverConfig.description#" );
		print.cyanLine( "  URL:         #serverConfig.url#" );
		print.line();

		printInfo( "What was done:" );
		print.line( "  ✓ Installed cbmcp module (dev dependency)" );
		print.line( "  ✓ Added cbmcp to manifest MCP servers" );
		print.line( "  ✓ Updated .mcp.json at project root" );
		print.line( "  ✓ Regenerated agent configuration files" );
		print.line();

		print.boldYellowLine( "Next Steps:" );
		print.line( "  1. Make sure your ColdBox server is running:" );
		print.line( "     box server start" );
		print.line();
		print.line( "  2. The MCP endpoint will be available at:" );
		print.cyanLine( "     #mcpUrl#" );
		print.line();
		print.line( "  3. Configure your AI agent to use the .mcp.json at the project root," );
		print.line( "     or point it directly to the URL above." );
		print.line();


		printTip( "Run 'coldbox ai mcp list' to verify the configuration" );
	}

}
