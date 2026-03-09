/**
 * Remove an MCP server from your project
 * Removes custom MCP servers or module servers (with --force flag)
 *
 * MCP (Model Context Protocol) servers provide live documentation access for AI agents.
 * This command removes custom servers or forces removal of module servers.
 *
 * Note: Core servers cannot be removed as they are fundamental to ColdBox/BoxLang development.
 *
 * Examples:
 * coldbox ai mcp remove company-docs
 * coldbox ai mcp remove cbsecurity --force
 */
component extends="coldbox-cli.models.BaseAICommand" {

	// DI
	property name="mcpRegistry"   inject="MCPRegistry@coldbox-cli";
	property name="agentRegistry" inject="AgentRegistry@coldbox-cli";

	/**
	 * Run the command
	 *
	 * @name.hint The name of the MCP server to remove
	 * @force.hint Force removal of module servers (they will be re-added on next refresh)
	 * @directory The target directory (defaults to current directory)
	 */
	function run(
		required string name,
		boolean force    = false,
		string directory = getCwd()
	){
		showColdBoxBanner( "Remove MCP Server" );

		var info     = ensureInstalled( arguments.directory );
		var manifest = loadManifest( arguments.directory );

		// Ensure mcpServers structure exists
		if ( !structKeyExists( manifest, "mcpServers" ) ) {
			printError( "No MCP servers configured" );
			return;
		}

		var mcpServers = manifest.mcpServers;

		// Check if it's a core server (cannot be removed)
		if ( mcpServers.core.findNoCase( arguments.name ) ) {
			printError( "Cannot remove core MCP server: #arguments.name#" );
			print.line();
			printInfo( "Core servers: #mcpServers.core.toList( ", " )#" );
			return;
		}

		// Check if it's a custom server
		var serverName  = arguments.name;
		var customIndex = mcpServers.custom.findAll( ( mcpServer ) => mcpServer.name == serverName );
		if ( customIndex.len() ) {
			mcpServers.custom.deleteAt( customIndex[ 1 ] );
			saveManifest( arguments.directory, manifest );

			// Regenerate all agent config files
			var directory = arguments.directory;
			var language  = manifest.language ?: "boxlang";
			manifest.agents.each( ( agent ) => {
				variables.agentRegistry.configureAgent( directory, agent, language );
			} );

			print.line();
			printSuccess( "Custom MCP server '#arguments.name#' removed successfully!" );
			print.line();
			printTip( "Agent configuration files have been updated" );
			return;
		}

		// Check if it's a module server
		var moduleIndex = mcpServers.module.findNoCase( arguments.name );
		if ( moduleIndex ) {
			if ( !arguments.force ) {
				printWarn( "Cannot remove module server '#arguments.name#' without --force flag" );
				print.line();
				printInfo( "Module servers are auto-detected from your dependencies" );
				printTip( "Use --force to remove (will be re-added on next 'coldbox ai refresh')" );
				return;
			}

			mcpServers.module.deleteAt( moduleIndex );
			saveManifest( arguments.directory, manifest );

			// Regenerate all agent config files
			var directory = arguments.directory;
			var language  = manifest.language ?: "boxlang";
			manifest.agents.each( ( agent ) => {
				variables.agentRegistry.configureAgent( directory, agent, language );
			} );

			print.line();
			printSuccess( "Module MCP server '#arguments.name#' removed!" );
			print.line();
			printWarn( "This server will be auto-added again if the module is still installed" );
			printTip( "Run 'coldbox ai refresh' to sync with installed modules" );
			return;
		}

		// Server not found
		printError( "MCP server '#arguments.name#' not found" );
		print.line();
		printTip( "Run 'coldbox ai mcp list' to see configured servers" );
	}

}
