/**
 * Display AI integration information
 * Shows current configuration, installed guidelines, skills, and agents
 *
 * Examples:
 * coldbox ai info
 * coldbox ai info --verbose
 */
component extends="coldbox-cli.models.BaseAICommand" {

	/**
	 * Run the command
	 *
	 * @directory The target directory (defaults to current directory)
	 * @verbose   Show detailed lists of guidelines, skills, agents, and MCP servers
	 */
	function run(
		string directory = getCwd(),
		boolean verbose  = false
	){
		showColdBoxBanner( "AI Integration Info" );

		var info = variables.aiService.getInfo( arguments.directory )

		if ( !info.installed ) {
			printWarn( "AI integration is not installed." );
			print.line()
			printInfo( "Run 'coldbox ai install' to set up AI integration." )
			return
		}

		// Load manifest to get active agent
		var manifest        = loadManifest( arguments.directory )
		var activeAgent     = manifest[ "activeAgent" ] ?: "none"
		var totalMcpServers = info.mcpServers.core.len() + info.mcpServers.module.len() + info.mcpServers.custom.len()

		// Print configuration in a table
		print.line()
		print.table(
			headerNames = [ "Setting", "Value" ],
			data        = [
				[
					"ColdBox CLI Version",
					info.coldboxCliVersion
				],
				[ "Language Mode", info.language ],
				[ "App Type", info.templateType ],
				[ "Active Agent", activeAgent ],
				[ "Guidelines", info.guidelines.len() ],
				[ "Skills", info.skills.len() ],
				[ "MCP Servers", totalMcpServers ]
			]
		)
		print.line()

		if ( arguments.verbose ) {
			// Guidelines (sorted alphabetically)
			printInfo( "Guidelines (#info.guidelines.len()#):" )
			if ( info.guidelines.len() ) {
				var sortedGuidelines = info.guidelines.sort( ( a, b ) => {
					return compare( a.name, b.name );
				} )
				sortedGuidelines.each( ( guideline ) => {
					print.indentedLine( "  📝  #guideline.name# (from #guideline.source#)" )
				} )
			} else {
				print.indentedLine( "  No guidelines installed" )
			}
			print.line()

			// Skills (sorted alphabetically within groups)
			printInfo( "Skills (#info.skills.len()#):" )
			if ( info.skills.len() ) {
				// Group by source
				var coreSkills = info.skills.filter( ( s ) => {
					return s.source == "core"
				} )
				var moduleSkills = info.skills.filter( ( s ) => {
					return s.source != "core"
				} )

				if ( coreSkills.len() ) {
					print.indentedCyanLine( "  Core:" );
					coreSkills
						.sort( ( a, b ) => {
							return compare( a.name, b.name )
						} )
						.each( ( skill ) => {
							print.indentedLine( "    ⭐ #skill.name#" )
						} )
				}

				if ( moduleSkills.len() ) {
					print.indentedCyanLine( "  Modules:" )
					moduleSkills
						.sort( ( a, b ) => {
							return compare( a.name, b.name )
						} )
						.each( ( skill ) => {
							print.indentedLine( "    • #skill.name# (from #skill.source#)" )
						} )
				}
			} else {
				print.indentedLine( "  No skills installed" )
			}
			print.line()

			// Agents
			printInfo( "Configured Agents (#info.agents.len()#):" )
			if ( info.agents.len() ) {
				info.agents.each( ( agent ) => {
					if ( agent == activeAgent ) {
						print.indentedGreenLine( "  ▶ #agent# (active)" )
					} else {
						print.indentedLine( "  🤖 #agent#" )
					}
				} );
			} else {
				print.indentedLine( "  No agents configured" )
			}
			print.line()

			// MCP Servers
			printInfo( "MCP Servers (#totalMcpServers#):" )
			if ( totalMcpServers > 0 ) {
				if ( info.mcpServers.core.len() ) {
					print.indentedCyanLine( "  Core (#info.mcpServers.core.len()#):" )
					info.mcpServers.core.each( ( mcpServer ) => {
						print.indentedLine( "    🔌 #mcpServer#" )
					} )
				}
				if ( info.mcpServers.module.len() ) {
					print.indentedCyanLine( "  Module (#info.mcpServers.module.len()#):" )
					info.mcpServers.module.each( ( mcpServer ) => {
						print.indentedLine( "    🔌 #mcpServer#" )
					} )
				}
				if ( info.mcpServers.custom.len() ) {
					print.indentedCyanLine( "  Custom (#info.mcpServers.custom.len()#):" )
					info.mcpServers.custom.each( ( mcpServer ) => {
						print.indentedLine( "    🔌 #mcpServer#" )
					} )
				}
			} else {
				print.indentedLine( "  No MCP servers configured" )
			}
			print.line()
		} else {
			printTip( "Run 'coldbox ai info --verbose' to see detailed lists" )
		}

		// Quick health check
		printTip( "Run 'coldbox ai doctor' for a detailed health check" )
	}

}
