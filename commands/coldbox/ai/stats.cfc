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
			[ "Template", arguments.stats.templateType ],
			[ "Last Sync", arguments.stats.lastSync ]
		]
		print.table(
			headerNames = [ "Property", "Value" ],
			data = overviewData
		)
		print.line()

		// Guidelines
		print.boldGreenLine( "📚 Guidelines (#arguments.stats.guidelines.total#)" )
		var guidelinesData = [
			[ "Core", arguments.stats.guidelines.core ],
			[ "Module", arguments.stats.guidelines.module ],
			[ "Custom", arguments.stats.guidelines.custom ],
			[ "Override", arguments.stats.guidelines.override ]
		]
		print.table(
			headerNames = [ "Type", "Count" ],
			data = guidelinesData
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
			[ "Module", arguments.stats.skills.module ],
			[ "Custom", arguments.stats.skills.custom ],
			[ "Override", arguments.stats.skills.override ]
		]
		print.table(
			headerNames = [ "Type", "Count" ],
			data = skillsData
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
				data = agentsData
			)
		} else {
			print.dimLine( "  (none configured)" )
		}

		print.line()

		// MCP Servers
		print.boldCyanLine( "🌐 MCP Servers (#arguments.stats.mcpServers.total#)" )
		var mcpData = [
			[ "Core", arguments.stats.mcpServers.core ],
			[ "Module", arguments.stats.mcpServers.module ],
			[ "Custom", arguments.stats.mcpServers.custom ]
		]
		print.table(
			headerNames = [ "Type", "Count" ],
			data = mcpData
		)
		print.line()

		// Context Estimate
		print.boldWhiteLine( "💾 Estimated AI Context Usage" )
		var contextData = [
			[ "Guidelines", "~#arguments.stats.contextEstimate.guidelinesKB# KB" ],
			[ "Skills", "~#arguments.stats.contextEstimate.skillsKB# KB" ],
			[ "Total", "~#arguments.stats.contextEstimate.totalKB# KB" ]
		]
		print.table(
			headerNames = [ "Component", "Size" ],
			data = contextData
		)
		print.line()

		// Show usage indicator based on common AI models (using GPT-4 128K as baseline)
		var estimatedTokens = arguments.stats.contextEstimate.totalKB * 300
		var baselineTokens  = 128000 // GPT-4 context window
		var percentage      = ( estimatedTokens / baselineTokens ) * 100

		print.toConsole( "  Usage: " )
		if ( percentage < 30 ) {
			print.greenLine( "✓ Low (#numberFormat( percentage, "_._" )#% of typical AI context)" )
		} else if ( percentage < 60 ) {
			print.yellowLine( "⚠ Moderate (#numberFormat( percentage, "_._" )#% of typical AI context)" )
		} else if ( percentage < 90 ) {
			print.orangeLine( "⚠ High (#numberFormat( percentage, "_._" )#% of typical AI context)" )
		} else {
			print.redLine( "⛔ Very High (#numberFormat( percentage, "_._" )#% of typical AI context)" )
			print.dim( "  Consider reducing guidelines/skills for better AI performance" )
		}
		print.line()

		// Context window estimates for popular AI models
		if ( arguments.verbose ) {
			print.line()
			print.cyanLine( "📈 Context Window Utilization:" )

			// Build table data
			var estimatedTokens = arguments.stats.contextEstimate.totalKB * 300
			var tableData       = [
				[
					"Claude 3.5 Sonnet",
					numberFormat( 200000 ),
					numberFormat( estimatedTokens ),
					numberFormat(
						( estimatedTokens / 200000 ) * 100,
						"_._"
					) & "%"
				],
				[
					"GPT-4",
					numberFormat( 128000 ),
					numberFormat( estimatedTokens ),
					numberFormat(
						( estimatedTokens / 128000 ) * 100,
						"_._"
					) & "%"
				],
				[
					"GPT-3.5-Turbo",
					numberFormat( 16000 ),
					numberFormat( estimatedTokens ),
					numberFormat(
						( estimatedTokens / 16000 ) * 100,
						"_._"
					) & "%"
				],
				[
					"Gemini 1.5 Pro",
					numberFormat( 1000000 ),
					numberFormat( estimatedTokens ),
					numberFormat(
						( estimatedTokens / 1000000 ) * 100,
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
		}

		// Tips
		printTip( "Run 'coldbox ai tree' to see the structure" )

		if( !arguments.verbose ){
			printTip( "Run 'coldbox ai stats --verbose' for detailed breakdown" )
		}
	}

}
