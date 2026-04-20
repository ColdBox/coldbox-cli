/**
 * List configured MCP servers for this project
 * Shows core, module-detected, and custom MCP documentation servers
 *
 * MCP (Model Context Protocol) servers provide live documentation access for AI agents.
 * This command shows which servers are configured based on your project's dependencies.
 *
 * Examples:
 * coldbox ai mcp list
 * coldbox ai mcp list --verbose
 */
component extends="coldbox-cli.models.BaseAICommand" {

	// DI
	property name="mcpRegistry" inject="MCPRegistry@coldbox-cli";

	/**
	 * Run the command
	 *
	 * @verbose Show detailed information including URLs
	 * @directory The target directory (defaults to current directory)
	 */
	function run(
		boolean verbose  = false,
		string directory = getCwd()
	){
		showColdBoxBanner( "MCP Servers" );

		var info = ensureInstalled( arguments.directory );
		if ( !info.installed ) {
			return;
		}
		var manifest = loadManifest( arguments.directory );

		print.line();
		printInfo( "MCP Servers for this project" );
		print.line();

		// Get MCP servers from manifest
		var mcpServers = manifest.mcpServers ?: {
			"core"   : [],
			"module" : [],
			"custom" : []
		};

		// Display core servers
		print.boldWhiteLine( "Core Servers (#mcpServers.core.len()#):" );
		if ( !mcpServers.core.len() ) {
			print.indentedLine( "  None" );
		} else {
			mcpServers.core.each( ( serverName ) => {
				var serverDef = variables.mcpRegistry.getServerDefinition( serverName );
				print.greenLine( "  ✓ #serverName#" );
				if ( verbose && structKeyExists( serverDef, "description" ) ) {
					print.indentedCyanLine( "    #serverDef.description#" );
				}
				if ( verbose && structKeyExists( serverDef, "url" ) ) {
					print.indentedLine( "    #serverDef.url#" );
				}
			} );
		}
		print.line();

		// Display module servers
		print.boldWhiteLine( "Module Servers (#mcpServers.module.len()#):" );
		if ( !mcpServers.module.len() ) {
			print.indentedLine( "  None (install ColdBox modules to add MCP servers)" );
		} else {
			mcpServers.module.each( ( serverName ) => {
				var serverDef = variables.mcpRegistry.getServerDefinition( serverName );
				print.greenLine( "  ✓ #serverName#" );
				if ( verbose && structKeyExists( serverDef, "description" ) ) {
					print.indentedCyanLine( "    #serverDef.description#" );
				}
				if ( verbose && structKeyExists( serverDef, "url" ) ) {
					print.indentedLine( "    #serverDef.url#" );
				}
			} );
		}
		print.line();

		// Display custom servers
		print.boldWhiteLine( "Custom Servers (#mcpServers.custom.len()#):" );
		if ( !mcpServers.custom.len() ) {
			print.indentedLine( "  None (use 'coldbox ai mcp add' to add custom servers)" );
		} else {
			mcpServers.custom.each( ( mcpServer ) => {
				print.greenLine( "  ✓ #mcpServer.name#" );
				if ( structKeyExists( mcpServer, "description" ) ) {
					print.indentedCyanLine( "    #mcpServer.description#" );
				}
				if ( verbose ) {
					if ( structKeyExists( mcpServer, "url" ) ) {
						print.indentedLine( "    URL: #mcpServer.url#" );
					}
					if ( structKeyExists( mcpServer, "command" ) ) {
						print.indentedLine( "    Command: #mcpServer.command#" );
						if ( structKeyExists( mcpServer, "args" ) ) {
							print.indentedLine( "    Args: #serializeJSON( mcpServer.args )#" );
						}
					}
				}
			} );
		}
		print.line();

		// Summary
		var totalServers = mcpServers.core.len() + mcpServers.module.len() + mcpServers.custom.len();
		printInfo( "Total: #totalServers# MCP server(s) configured" );
		print.line();

		printTip( "MCP servers provide live documentation access for AI agents" );
		printTip( "Servers are auto-updated when you install/remove modules (via 'coldbox ai refresh')" );
	}

}
