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
			showColdBoxBanner( "AI Integration Statistics" );
		}

		try {
			var info     = ensureInstalled( arguments.directory );
			var manifest = loadManifest( arguments.directory );
			var stats    = calculateStats( info, manifest, arguments.directory );

			// JSON output
			if ( arguments.json ) {
				print.line( serializeJSON( stats ) );
				return;
			}

			// Console output
			printStats( stats, arguments.verbose );
		} catch ( any e ) {
			printError( "Failed to calculate stats: #e.message#" );
			printError( e.stackTrace );
		}
	}

	/**
	 * Calculate statistics
	 */
	private function calculateStats(
		required struct info,
		required struct manifest,
		required string directory
	){
		var stats = {
			"guidelines" : {
				"total"     : arguments.info.guidelines.len(),
				"core"      : 0,
				"module"    : 0,
				"custom"    : 0,
				"override"  : 0,
				"totalSize" : 0,
				"avgSize"   : 0
			},
			"skills" : {
				"total"     : arguments.info.skills.len(),
				"core"      : 0,
				"module"    : 0,
				"custom"    : 0,
				"override"  : 0,
				"totalSize" : 0,
				"avgSize"   : 0
			},
			"agents" : {
				"total"      : arguments.manifest.agents.len(),
				"configured" : arguments.manifest.agents
			},
			"mcpServers" : {
				"total"  : 0,
				"core"   : 0,
				"module" : 0,
				"custom" : 0
			},
			"language"        : arguments.manifest.language ?: "unknown",
			"templateType"    : arguments.manifest.templateType ?: "unknown",
			"lastSync"        : arguments.manifest.lastSync ?: "never",
			"contextEstimate" : {
				"totalKB"      : 0,
				"guidelinesKB" : 0,
				"skillsKB"     : 0
			}
		};

		// Count guidelines by type
		arguments.info.guidelines.each( ( guideline ) => {
			var type = guideline.type ?: "module";
			if ( structKeyExists( stats.guidelines, type ) ) {
				stats.guidelines[ type ]++;
			}
		} );

		// Count skills by type
		arguments.info.skills.each( ( skill ) => {
			var type   = skill.type ?: "module";
			var source = skill.source ?: "";

			if ( type == "override" ) {
				stats.skills.override++;
			} else if ( source == "core" ) {
				stats.skills.core++;
			} else if ( source == "custom" || type == "custom" ) {
				stats.skills.custom++;
			} else {
				stats.skills.module++;
			}
		} );

		// Count MCP servers
		var mcpServers = arguments.manifest.mcpServers ?: {
			"core"   : [],
			"module" : [],
			"custom" : []
		};
		stats.mcpServers.core   = mcpServers.core.len();
		stats.mcpServers.module = mcpServers.module.len();
		stats.mcpServers.custom = mcpServers.custom.len();
		stats.mcpServers.total  = stats.mcpServers.core + stats.mcpServers.module + stats.mcpServers.custom;

		// Calculate file sizes
		var aiDir = arguments.directory & "/.ai";
		if ( directoryExists( aiDir ) ) {
			// Guidelines size
			var guidelinesDir = aiDir & "/guidelines";
			if ( directoryExists( guidelinesDir ) ) {
				var guidelineSize                  = calculateDirectorySize( guidelinesDir );
				stats.guidelines.totalSize         = guidelineSize;
				stats.guidelines.avgSize           = stats.guidelines.total > 0 ? int( guidelineSize / stats.guidelines.total ) : 0;
				stats.contextEstimate.guidelinesKB = int( guidelineSize / 1024 );
			}

			// Skills size
			var skillsDir = aiDir & "/skills";
			if ( directoryExists( skillsDir ) ) {
				var skillsSize                 = calculateDirectorySize( skillsDir );
				stats.skills.totalSize         = skillsSize;
				stats.skills.avgSize           = stats.skills.total > 0 ? int( skillsSize / stats.skills.total ) : 0;
				stats.contextEstimate.skillsKB = int( skillsSize / 1024 );
			}

			// Total context estimate
			stats.contextEstimate.totalKB = stats.contextEstimate.guidelinesKB + stats.contextEstimate.skillsKB;
		}

		return stats;
	}

	/**
	 * Calculate directory size recursively
	 */
	private function calculateDirectorySize( required string path ){
		var totalSize = 0;

		if ( !directoryExists( arguments.path ) ) {
			return 0;
		}

		var files = directoryList(
			arguments.path,
			true,
			"path",
			"*.md|*.txt"
		);

		files.each( ( file ) => {
			if ( fileExists( file ) ) {
				totalSize += getFileInfo( file ).size;
			}
		} );

		return totalSize;
	}

	/**
	 * Print statistics to console
	 */
	private function printStats(
		required struct stats,
		boolean verbose = false
	){
		print.line();

		// Overview
		print.boldCyanLine( "📊 Overview" );
		print.line( "  Language: #arguments.stats.language#" );
		print.line( "  Template: #arguments.stats.templateType#" );
		print.line( "  Last Sync: #arguments.stats.lastSync#" );
		print.line();

		// Guidelines
		print.boldGreenLine( "📚 Guidelines (#arguments.stats.guidelines.total#)" );
		print.line( "  Core: #arguments.stats.guidelines.core#" );
		print.line( "  Module: #arguments.stats.guidelines.module#" );
		print.line( "  Custom: #arguments.stats.guidelines.custom#" );
		print.line( "  Override: #arguments.stats.guidelines.override#" );

		if ( arguments.verbose && arguments.stats.guidelines.totalSize > 0 ) {
			print.dim( "  Total Size: #formatBytes( arguments.stats.guidelines.totalSize )#" );
			print.dim( "  Avg Size: #formatBytes( arguments.stats.guidelines.avgSize )#" );
		}
		print.line();

		// Skills
		print.boldYellowLine( "🎯 Skills (#arguments.stats.skills.total#)" );
		print.line( "  Core: #arguments.stats.skills.core#" );
		print.line( "  Module: #arguments.stats.skills.module#" );
		print.line( "  Custom: #arguments.stats.skills.custom#" );
		print.line( "  Override: #arguments.stats.skills.override#" );

		if ( arguments.verbose && arguments.stats.skills.totalSize > 0 ) {
			print.dim( "  Total Size: #formatBytes( arguments.stats.skills.totalSize )#" );
			print.dim( "  Avg Size: #formatBytes( arguments.stats.skills.avgSize )#" );
		}
		print.line();

		// Agents
		print.boldMagentaLine( "🤖 Agents (#arguments.stats.agents.total#)" );
		if ( arguments.stats.agents.total > 0 ) {
			arguments.stats.agents.configured.each( ( agent ) => {
				print.line( "  • #agent#" );
			} );
		} else {
			print.dim( "  (none configured)" );
		}
		print.line();

		// MCP Servers
		print.boldCyanLine( "🌐 MCP Servers (#arguments.stats.mcpServers.total#)" );
		print.line( "  Core: #arguments.stats.mcpServers.core#" );
		print.line( "  Module: #arguments.stats.mcpServers.module#" );
		print.line( "  Custom: #arguments.stats.mcpServers.custom#" );
		print.line();

		// Context Estimate
		print.boldWhiteLine( "💾 Estimated AI Context Usage" );
		print.line( "  Guidelines: ~#arguments.stats.contextEstimate.guidelinesKB# KB" );
		print.line( "  Skills: ~#arguments.stats.contextEstimate.skillsKB# KB" );
		print.boldLine( "  Total: ~#arguments.stats.contextEstimate.totalKB# KB" );

		// Show usage indicator based on common AI models (using GPT-4 128K as baseline)
		var estimatedTokens = arguments.stats.contextEstimate.totalKB * 300;
		var baselineTokens  = 128000; // GPT-4 context window
		var percentage      = ( estimatedTokens / baselineTokens ) * 100;

		print.toConsole( "  Usage: " );
		if ( percentage < 30 ) {
			print.greenLine( "✓ Low (#numberFormat( percentage, "_._" )#% of typical AI context)" );
		} else if ( percentage < 60 ) {
			print.yellowLine( "⚠ Moderate (#numberFormat( percentage, "_._" )#% of typical AI context)" );
		} else if ( percentage < 90 ) {
			print.orangeLine( "⚠ High (#numberFormat( percentage, "_._" )#% of typical AI context)" );
		} else {
			print.redLine( "⛔ Very High (#numberFormat( percentage, "_._" )#% of typical AI context)" );
			print.dim( "  Consider reducing guidelines/skills for better AI performance" );
		}
		print.line();

		// Context window estimates for popular AI models
		if ( arguments.verbose ) {
			print.cyanLine( "📈 Context Window Utilization:" );
			printContextUtilization(
				"Claude 3.5 Sonnet",
				200000,
				arguments.stats.contextEstimate.totalKB
			);
			printContextUtilization(
				"GPT-4",
				128000,
				arguments.stats.contextEstimate.totalKB
			);
			printContextUtilization(
				"GPT-3.5-Turbo",
				16000,
				arguments.stats.contextEstimate.totalKB
			);
			printContextUtilization(
				"Gemini 1.5 Pro",
				1000000,
				arguments.stats.contextEstimate.totalKB
			);
			print.line();
		}

		// Tips
		printTip( "Run 'coldbox ai tree' to see the structure" );
		printTip( "Run 'coldbox ai stats --verbose' for detailed breakdown" );
	}

	/**
	 * Print context utilization for a model
	 */
	private function printContextUtilization(
		required string modelName,
		required numeric contextTokens,
		required numeric usedKB
	){
		// Rough estimate: 1KB ≈ 300 tokens
		var estimatedTokens = arguments.usedKB * 300;
		var percentage      = ( estimatedTokens / arguments.contextTokens ) * 100;
		var color           = percentage < 30 ? "green" : ( percentage < 60 ? "yellow" : "red" );

		print.line( "  #arguments.modelName#: " );
		print.toConsole( "    " );

		if ( color == "green" ) {
			print.greenText( "#numberFormat( percentage, "_._" )#%" );
		} else if ( color == "yellow" ) {
			print.yellowText( "#numberFormat( percentage, "_._" )#%" );
		} else {
			print.redText( "#numberFormat( percentage, "_._" )#%" );
		}

		print.line( " (~#numberFormat( estimatedTokens )# tokens of #numberFormat( arguments.contextTokens )#)" );
	}

	/**
	 * Format bytes to human readable
	 */
	private function formatBytes( required numeric bytes ){
		if ( arguments.bytes < 1024 ) {
			return "#arguments.bytes# B";
		} else if ( arguments.bytes < 1048576 ) {
			return "#numberFormat( arguments.bytes / 1024, "_._" )# KB";
		} else {
			return "#numberFormat( arguments.bytes / 1048576, "_._" )# MB";
		}
	}

}
