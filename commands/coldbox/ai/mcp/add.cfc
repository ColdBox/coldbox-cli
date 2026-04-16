/**
 * Add a custom MCP server to your project
 * Allows integration of company-specific or internal documentation servers
 *
 * MCP (Model Context Protocol) servers provide live documentation access for AI agents.
 * This command adds custom servers to complement the auto-detected Ortus MCP servers.
 *
 * Examples:
 * coldbox ai mcp add company-docs --url=https://docs.company.com/mcp
 * coldbox ai mcp add local-docs --command=node --args=./mcp-server.js
 * coldbox ai mcp add internal --url=http://localhost:3000/mcp --description="Internal project docs"
 */
component extends="coldbox-cli.models.BaseAICommand" {

	// DI
	property name="mcpRegistry"   inject="MCPRegistry@coldbox-cli";
	property name="agentRegistry" inject="AgentRegistry@coldbox-cli";

	/**
	 * Run the command
	 *
	 * @name.hint The name/identifier for the custom MCP server
	 * @url.hint The URL endpoint for the MCP server (required if command not specified)
	 * @command.hint The command to run the MCP server (alternative to URL)
	 * @args.hint Comma-separated list of arguments for the command
	 * @description.hint Optional description of the MCP server
	 * @directory The target directory (defaults to current directory)
	 */
	function run(
		required string name,
		string url         = "",
		string command     = "",
		string args        = "",
		string description = "",
		string directory   = getCwd()
	){
		showColdBoxBanner( "Add MCP Server" );

		var info     = ensureInstalled( arguments.directory );
		var manifest = loadManifest( arguments.directory );

		// Ensure mcpServers structure exists
		if ( !structKeyExists( manifest, "mcpServers" ) ) {
			manifest.mcpServers = {
				"core"   : [],
				"module" : [],
				"custom" : []
			};
		}

		// Build server config
		var serverConfig = { "name" : arguments.name };

		if ( len( arguments.description ) ) {
			serverConfig.description = arguments.description;
		}

		if ( len( arguments.url ) ) {
			serverConfig.url = arguments.url;
		}

		if ( len( arguments.command ) ) {
			serverConfig.command = arguments.command;
			if ( len( arguments.args ) ) {
				serverConfig.args = listToArray( arguments.args );
			}
		}

		// Validate custom server
		var validation = variables.mcpRegistry.validateCustomServer( serverConfig );
		if ( !validation.valid ) {
			printError( validation.message );
			return;
		}

		// Check if custom server already exists
		var serverName    = arguments.name;
		var existingIndex = manifest.mcpServers.custom.findAll( ( mcpServer ) => mcpServer.name == serverName );
		if ( existingIndex.len() ) {
			printWarn( "Custom MCP server '#arguments.name#' already exists" );
			print.line();
			if ( !confirm( "Overwrite existing server? [y/n]" ) ) {
				printInfo( "Cancelled" );
				return;
			}
			// Remove existing
			manifest.mcpServers.custom.deleteAt( existingIndex[ 1 ] );
		}

		// Add custom server
		manifest.mcpServers.custom.append( serverConfig );

		// Save manifest
		saveManifest( arguments.directory, manifest );

		// Regenerate all agent config files
		var directory = arguments.directory;
		var language  = manifest.language ?: "boxlang";
		manifest.agents.each( ( agent ) => {
			variables.agentRegistry.configureAgent( directory, agent, language );
		} );

		// Regenerate .mcp.json with added server
		generateMCPJson( arguments.directory, manifest );

		print.line();
		printSuccess( "Custom MCP server '#arguments.name#' added successfully!" );
		print.line();

		// Show details
		print.boldWhiteLine( "Server Details:" );
		print.greenLine( "  Name: #serverConfig.name#" );
		if ( structKeyExists( serverConfig, "description" ) ) {
			print.line( "  Description: #serverConfig.description#" );
		}
		if ( structKeyExists( serverConfig, "url" ) ) {
			print.cyanLine( "  URL: #serverConfig.url#" );
		}
		if ( structKeyExists( serverConfig, "command" ) ) {
			print.cyanLine( "  Command: #serverConfig.command#" );
			if ( structKeyExists( serverConfig, "args" ) ) {
				print.line( "  Args: #serializeJSON( serverConfig.args )#" );
			}
		}
		print.line();

		printTip( "Agent configuration files have been updated with the new MCP server" );
		printTip( "Run 'coldbox ai mcp list' to see all configured servers" );
	}

}
