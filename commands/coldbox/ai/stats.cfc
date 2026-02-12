/**
 * Display AI integration statistics and context usage
 * Shows file counts, sizes, and estimated AI context consumption
 *
 * Examples:
 * coldbox ai stats
 * coldbox ai stats --verbose
 * coldbox ai stats --json
 */
component extends="coldbox-cli.models.BaseAICommand" {

	// DI
	property name="agentRegistry" inject="AgentRegistry@coldbox-cli";

	/**
	 * Run the command
	 *
	 * @verbose Show detailed breakdown by category
	 * @json Output as JSON
	 * @directory The target directory (defaults to current directory)
	 */
	function run(
		boolean verbose  = false,
		boolean json     = false,
		string directory = getCwd()
	){
		if ( !arguments.json ) {
			showColdBoxBanner( "AI Integration Statistics" )
		}

		try {
			var stats = variables.aiService.getStats( arguments.directory )

			// JSON output
			if ( arguments.json ) {
				print.line( serializeJSON( stats ) )
				return
			}

			// Console output
			printStats( stats, arguments.verbose )
		} catch ( any e ) {
			printError( "Failed to calculate stats: #e.message#" )
			printError( e.stackTrace )
		}
	}

	/**
	 * Print statistics to console
	 */
	private function printStats(
		required struct stats,
		boolean verbose = false
	){
		print.line()

		// Overview
		print.boldCyanLine( "📊 Overview" )
		var overviewData = [
			[ "Language", arguments.stats.language ],
			[
				"Template",
				arguments.stats.templateType
			],
			[
				"Last Sync",
				arguments.stats.lastSync
			]
		]
		print.table(
			headerNames = [ "Property", "Value" ],
			data        = overviewData
		)
		print.line()

		// Guidelines
		print.boldGreenLine( "📚 Guidelines (#arguments.stats.guidelines.total#)" )
		var guidelinesData = [
			[
				"Core",
				arguments.stats.guidelines.core
			],
			[
				"Module",
				arguments.stats.guidelines.module
			],
			[
				"Custom",
				arguments.stats.guidelines.custom
			],
			[
				"Override",
				arguments.stats.guidelines.override
			]
		]
		print.table(
			headerNames = [ "Type", "Count" ],
			data        = guidelinesData
		)

		if ( arguments.verbose && arguments.stats.guidelines.totalSize > 0 ) {
			print.dim( "  Total Size: #variables.utility.formatBytes( arguments.stats.guidelines.totalSize )#" )
			print.dimLine( "  Avg Size: #variables.utility.formatBytes( arguments.stats.guidelines.avgSize )#" )
		}

		print.line()

		// Skills
		print.boldYellowLine( "🎯 Skills (#arguments.stats.skills.total#)" )
		var skillsData = [
			[ "Core", arguments.stats.skills.core ],
			[
				"Module",
				arguments.stats.skills.module
			],
			[
				"Custom",
				arguments.stats.skills.custom
			],
			[
				"Override",
				arguments.stats.skills.override
			]
		]
		print.table(
			headerNames = [ "Type", "Count" ],
			data        = skillsData
		)

		if ( arguments.verbose && arguments.stats.skills.totalSize > 0 ) {
			print.dim( "  Total Size: #variables.utility.formatBytes( arguments.stats.skills.totalSize )#" )
			print.dimLine( "  Avg Size: #variables.utility.formatBytes( arguments.stats.skills.avgSize )#" )
		}
		print.line()

		// Agents
		print.boldMagentaLine( "🤖 Agents (#arguments.stats.agents.total#)" )
		if ( arguments.stats.agents.total > 0 ) {
			var agentFiles = variables.agentRegistry.getAgentConfigPaths()
			var agentsData = []
			arguments.stats.agents.configured.each( ( agent ) => {
				var configFile = agentFiles[ agent ] ?: "Unknown"
				agentsData.append( [ agent, configFile ] )
			} )
			print.table(
				headerNames = [ "Agent", "Config File" ],
				data        = agentsData
			)
		} else {
			print.dimLine( "  (none configured)" )
		}

		print.line()

		// MCP Servers
		print.boldCyanLine( "🌐 MCP Servers (#arguments.stats.mcpServers.total#)" )
		var mcpData = [
			[
				"Core",
				arguments.stats.mcpServers.core
			],
			[
				"Module",
				arguments.stats.mcpServers.module
			],
			[
				"Custom",
				arguments.stats.mcpServers.custom
			]
		]
		print.table(
			headerNames = [ "Type", "Count" ],
			data        = mcpData
		)
		print.line()

		// Context Estimate - Subagent Pattern
		print.boldWhiteLine( "💾 AI Context Usage (Subagent Pattern)" )
		var contextData = [
			[
				"Base Context",
				"~#arguments.stats.contextEstimate.baseContextKB# KB",
				"Agent files loaded at startup"
			],
			[
				"  ├─ Inlined",
				"~#arguments.stats.contextEstimate.inlinedKB# KB",
				"Core guidelines embedded in agents"
			],
			[
				"  └─ Agent Files",
				"~#arguments.stats.contextEstimate.baseContextKB - arguments.stats.contextEstimate.inlinedKB# KB",
				"Agent configuration overhead"
			],
			[
				"On-Demand",
				"~#arguments.stats.contextEstimate.onDemandKB# KB",
				"Available but not loaded (inventoried)"
			],
			[
				"Total Available",
				"~#arguments.stats.contextEstimate.totalAvailableKB# KB",
				"If all resources were loaded"
			]
		]
		print.table(
			headerNames = [ "Component", "Size", "Description" ],
			data        = contextData
		)
		print.line()

		// Show usage indicator based on BASE CONTEXT (what's actually loaded)
		var estimatedTokens = arguments.stats.contextEstimate.baseContextKB * 300
		var baselineTokens  = 128000 // GPT-4 context window
		var percentage      = ( estimatedTokens / baselineTokens ) * 100

		print.toConsole( "  Base Context Usage: " )
		if ( percentage < 30 ) {
			printSuccess( "✓ Low (#numberFormat( percentage, "_._" )#% of typical AI context)" )
		} else if ( percentage < 60 ) {
			printInfo( "⚠ Moderate (#numberFormat( percentage, "_._" )#% of typical AI context)" )
		} else if ( percentage < 90 ) {
			printWarn( "⚠ High (#numberFormat( percentage, "_._" )#% of typical AI context)" )
		} else {
			printError( "⛔ Very High (#numberFormat( percentage, "_._" )#% of typical AI context)" )
			print.dimLine( "  Consider reducing inlined guidelines for better AI performance" )
		}
		printHelp( "On-demand resources are loaded only when needed via subagent pattern" )
		print.line()

		// Context window estimates for popular AI models (top 2 per provider)
		if ( arguments.verbose ) {
			print.cyanLine( "📈 Context Window Utilization (Base Context):" )

			// Build table data - use BASE CONTEXT (what's actually loaded)
			var estimatedTokens = arguments.stats.contextEstimate.baseContextKB * 300
			var tableData       = [
				[
					"Claude 4.5",
					numberFormat( 200000 ),
					numberFormat( estimatedTokens ),
					numberFormat(
						( estimatedTokens / 200000 ) * 100,
						"_._"
					) & "%"
				],
				[
					"Claude Opus 4.6",
					numberFormat( 200000 ),
					numberFormat( estimatedTokens ),
					numberFormat(
						( estimatedTokens / 200000 ) * 100,
						"_._"
					) & "%"
				],
				[
					"GPT-5.2",
					numberFormat( 128000 ),
					numberFormat( estimatedTokens ),
					numberFormat(
						( estimatedTokens / 128000 ) * 100,
						"_._"
					) & "%"
				],
				[
					"GPT-4.1",
					numberFormat( 128000 ),
					numberFormat( estimatedTokens ),
					numberFormat(
						( estimatedTokens / 128000 ) * 100,
						"_._"
					) & "%"
				],
				[
					"Gemini 3 Pro",
					numberFormat( 2000000 ),
					numberFormat( estimatedTokens ),
					numberFormat(
						( estimatedTokens / 2000000 ) * 100,
						"_._"
					) & "%"
				],
				[
					"Gemini 3 Flash",
					numberFormat( 1000000 ),
					numberFormat( estimatedTokens ),
					numberFormat(
						( estimatedTokens / 1000000 ) * 100,
						"_._"
					) & "%"
				],
				[
					"Grok 4",
					numberFormat( 128000 ),
					numberFormat( estimatedTokens ),
					numberFormat(
						( estimatedTokens / 128000 ) * 100,
						"_._"
					) & "%"
				],
				[
					"Grok 3",
					numberFormat( 128000 ),
					numberFormat( estimatedTokens ),
					numberFormat(
						( estimatedTokens / 128000 ) * 100,
						"_._"
					) & "%"
				]
			]

			print.table(
				headerNames = [
					"Model",
					"Window Size",
					"Used Tokens",
					"Utilization"
				],
				data = tableData
			)
			print.line()
			print.dimLine( "  * Utilization shown for base context only (agent files + inlined guidelines)" )
			print.dimLine( "  * On-demand resources (~#arguments.stats.contextEstimate.onDemandKB# KB) loaded via subagent as needed" )
			print.line()

			// Model comparison links
			print.dimLine( "  Model Comparison Resources:" )
			print.dimLine( "    • Claude: https://platform.claude.com/docs/en/about-claude/models/overview##latest-models-comparison" )
			print.dimLine( "    • OpenAI: https://developers.openai.com/api/docs/models/compare" )
			print.dimLine( "    • Gemini: https://ai.google.dev/gemini-api/docs/models" )
			print.dimLine( "    • Grok: https://docs.x.ai/developers/models" )
			print.line()
		}

		// Tips
		printTip( "Run 'coldbox ai tree' to see the structure" )

		if ( !arguments.verbose ) {
			printTip( "Run 'coldbox ai stats --verbose' for detailed breakdown" )
		}
	}

}
