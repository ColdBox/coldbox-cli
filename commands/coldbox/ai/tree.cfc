/**
 * Display AI integration structure as a visual tree
 * Shows guidelines, skills, agents, and MCP servers in a hierarchical view
 *
 * Examples:
 * coldbox ai tree
 * coldbox ai tree --verbose
 */
component extends="coldbox-cli.models.BaseAICommand" {

	property name="agentRegistry" inject="AgentRegistry@coldbox-cli";

	/**
	 * Run the command
	 *
	 * @verbose Show detailed file paths and sizes
	 * @directory The target directory (defaults to current directory)
	 */
	function run(
		boolean verbose  = false,
		string directory = getCwd()
	){
		showColdBoxBanner( "AI Integration Structure" );

		try {
			var info     = ensureInstalled( arguments.directory );
			var manifest = loadManifest( arguments.directory );

			// Read package descriptor for name and version
			var packageDescriptor = packageService.readPackageDescriptor( arguments.directory );
			var packageName       = packageDescriptor.name ?: "Unknown";
			var packageVersion    = packageDescriptor.version ?: "0.0.0";

			// Build tree structure
			var treeData = buildTreeStructure( info, manifest, arguments.verbose );

			print.line();
			print.boldSeaGreen1Line( "AI Integration Structure - #packageName# (#packageVersion#)" );
			print.tree( treeData, ( path, pathArray ) => formatTreeItem(
				path,
				pathArray,
				info,
				manifest,
				verbose
			) );

			// Summary
			print.line();
			printSummary( info, manifest );
		} catch ( any e ) {
			printError( "Failed to display tree: #e.message#" );
			printError( e.stackTrace );
		}
	}

	/**
	 * Format tree items with colors and verbose info
	 */
	private function formatTreeItem(
		required string path,
		required array pathArray,
		required struct info,
		required struct manifest,
		boolean verbose = false
	){
		var lastKey = pathArray[ pathArray.len() ];

		// Color coding based on path using ANSI codes
		var green   = chr( 27 ) & "[32m";
		var cyan    = chr( 27 ) & "[36m";
		var yellow  = chr( 27 ) & "[33m";
		var magenta = chr( 27 ) & "[35m";
		var dim     = chr( 27 ) & "[2m";
		var reset   = chr( 27 ) & "[0m";

		// Apply colors based on path
		if ( path contains "/core/" ) {
			return green & lastKey & reset;
		} else if ( path contains "/module" ) {
			return cyan & lastKey & reset;
		} else if ( path contains "/custom/" ) {
			return yellow & lastKey & reset;
		} else if ( path contains "/overrides/" ) {
			return magenta & lastKey & reset;
		} else if ( path contains "/.ai/agents/" ) {
			return green & lastKey & reset;
		} else if ( arguments.verbose && ( lastKey contains ".md" || lastKey contains ".cfc" || lastKey contains "rules" ) ) {
			return dim & lastKey & reset;
		}

		return lastKey;
	}

	/**
	 * Build the tree data structure as nested struct
	 */
	private function buildTreeStructure(
		required struct info,
		required struct manifest,
		boolean verbose = false
	){
		var tree = [
			".ai/": {
				"guidelines/ (#arguments.info.guidelines.len()#)" : buildGuidelinesStruct(
					arguments.info,
					arguments.verbose
				),
				"skills/ (#arguments.info.skills.len()#)"     : buildSkillsStruct( arguments.info ),
				"agents/ (#arguments.manifest.agents.len()#)" : buildAgentsStruct(
					arguments.manifest,
					arguments.verbose
				),
				"mcp-servers/ (#getTotalMCPServers( arguments.manifest )#)" : buildMCPServersStruct(
					arguments.manifest
				)
			}
		]

		return tree
	}

	/**
	 * Get total MCP servers count
	 */
	private function getTotalMCPServers( required struct manifest ){
		var mcpServers = arguments.manifest.mcpServers ?: {
			"core"   : [],
			"module" : [],
			"custom" : []
		};
		return mcpServers.core.len() + mcpServers.module.len() + mcpServers.custom.len();
	}

	/**
	 * Build guidelines struct
	 */
	private function buildGuidelinesStruct(
		required struct info,
		boolean verbose = false
	){
		var guidelines = arguments.info.guidelines;
		var result     = {};

		// Group guidelines
		var grouped = {
			"core"     : [],
			"module"   : [],
			"custom"   : [],
			"override" : []
		};

		guidelines.each( ( guideline ) => {
			var type = guideline.type ?: "module";
			if ( !structKeyExists( grouped, type ) ) {
				grouped[ type ] = [];
			}
			grouped[ type ].append( guideline );
		} );

		// Build struct for each category
		if ( grouped.core.len() ) {
			result[ "core/ (#grouped.core.len()#)" ] = {};
			grouped.core.each( ( guideline ) => {
				if ( verbose && structKeyExists( guideline, "path" ) ) {
					result[ "core/ (#grouped.core.len()#)" ][ guideline.name ] = { "#guideline.path#" : {} };
				} else {
					result[ "core/ (#grouped.core.len()#)" ][ guideline.name ] = {};
				}
			} );
		}

		if ( grouped.module.len() ) {
			result[ "modules/ (#grouped.module.len()#)" ] = {};
			grouped.module.each( ( guideline ) => {
				if ( verbose && structKeyExists( guideline, "path" ) ) {
					result[ "modules/ (#grouped.module.len()#)" ][ guideline.name ] = { "#guideline.path#" : {} };
				} else {
					result[ "modules/ (#grouped.module.len()#)" ][ guideline.name ] = {};
				}
			} );
		}

		if ( grouped.custom.len() ) {
			result[ "custom/ (#grouped.custom.len()#)" ] = {};
			grouped.custom.each( ( guideline ) => {
				if ( verbose && structKeyExists( guideline, "path" ) ) {
					result[ "custom/ (#grouped.custom.len()#)" ][ guideline.name ] = { "#guideline.path#" : {} };
				} else {
					result[ "custom/ (#grouped.custom.len()#)" ][ guideline.name ] = {};
				}
			} );
		}

		if ( grouped.override.len() ) {
			result[ "overrides/ (#grouped.override.len()#)" ] = {};
			grouped.override.each( ( guideline ) => {
				if ( verbose && structKeyExists( guideline, "path" ) ) {
					result[ "overrides/ (#grouped.override.len()#)" ][ guideline.name ] = { "#guideline.path#" : {} };
				} else {
					result[ "overrides/ (#grouped.override.len()#)" ][ guideline.name ] = {};
				}
			} );
		}

		return result;
	}

	/**
	 * Build skills struct
	 */
	private function buildSkillsStruct( required struct info ){
		var skills = arguments.info.skills;
		var result = {};

		// Group skills
		var grouped = {
			"core"     : [],
			"module"   : [],
			"custom"   : [],
			"override" : []
		};

		skills.each( ( skill ) => {
			var type   = skill.type ?: "module";
			var source = skill.source ?: "";

			if ( type == "override" ) {
				grouped.override.append( skill );
			} else if ( source == "core" ) {
				grouped.core.append( skill );
			} else if ( source == "custom" || type == "custom" ) {
				grouped.custom.append( skill );
			} else {
				grouped.module.append( skill );
			}
		} );

		// Build struct for each category
		if ( grouped.core.len() ) {
			result[ "core/ (#grouped.core.len()#)" ] = {};
			grouped.core.each( ( skill ) => {
				result[ "core/ (#grouped.core.len()#)" ][ skill.name ] = {};
			} );
		}

		if ( grouped.module.len() ) {
			result[ "modules/ (#grouped.module.len()#)" ] = {};
			grouped.module.each( ( skill ) => {
				result[ "modules/ (#grouped.module.len()#)" ][ skill.name ] = {};
			} );
		}

		if ( grouped.custom.len() ) {
			result[ "custom/ (#grouped.custom.len()#)" ] = {};
			grouped.custom.each( ( skill ) => {
				result[ "custom/ (#grouped.custom.len()#)" ][ skill.name ] = {};
			} );
		}

		if ( grouped.override.len() ) {
			result[ "overrides/ (#grouped.override.len()#)" ] = {};
			grouped.override.each( ( skill ) => {
				result[ "overrides/ (#grouped.override.len()#)" ][ skill.name ] = {};
			} );
		}

		return result;
	}

	/**
	 * Build agents struct
	 */
	private function buildAgentsStruct(
		required struct manifest,
		boolean verbose = false
	){
		var agents = arguments.manifest.agents ?: [];
		var result = {};

		if ( agents.len() ) {
			var agentFiles = variables.agentRegistry.AGENT_FILES

			agents.each( ( agent ) => {
				if ( verbose && structKeyExists( agentFiles, agent ) ) {
					result[ agent ] = { "#agentFiles[ agent ]#" : {} };
				} else {
					result[ agent ] = {};
				}
			} );
		} else {
			result[ "(none configured)" ] = {};
		}

		return result;
	}

	/**
	 * Build MCP servers struct
	 */
	private function buildMCPServersStruct( required struct manifest ){
		var mcpServers = arguments.manifest.mcpServers ?: {
			"core"   : [],
			"module" : [],
			"custom" : []
		};

		var result = {};

		// Core
		if ( mcpServers.core.len() ) {
			result[ "core/ (#mcpServers.core.len()#)" ] = {};
			mcpServers.core.each( ( serverName ) => {
				result[ "core/ (#mcpServers.core.len()#)" ][ serverName ] = {};
			} );
		}

		// Module
		if ( mcpServers.module.len() ) {
			result[ "module/ (#mcpServers.module.len()#)" ] = {};
			mcpServers.module.each( ( serverName ) => {
				result[ "module/ (#mcpServers.module.len()#)" ][ serverName ] = {};
			} );
		}

		// Custom
		if ( mcpServers.custom.len() ) {
			result[ "custom/ (#mcpServers.custom.len()#)" ] = {};
			mcpServers.custom.each( ( mcpServer ) => {
				var name                                                = isStruct( mcpServer ) ? mcpServer.name : mcpServer;
				result[ "custom/ (#mcpServers.custom.len()#)" ][ name ] = {};
			} );
		}

		return result;
	}

	/**
	 * Print summary
	 */
	private function printSummary(
		required struct info,
		required struct manifest
	){
		var mcpServers = arguments.manifest.mcpServers ?: {
			"core"   : [],
			"module" : [],
			"custom" : []
		};
		var totalMCP = mcpServers.core.len() + mcpServers.module.len() + mcpServers.custom.len();

		print.line();
		print.boldWhiteLine( "Summary:" );

		print.table(
			[
				{
					"Component" : "Guidelines",
					"Count"     : arguments.info.guidelines.len()
				},
				{
					"Component" : "Skills",
					"Count"     : arguments.info.skills.len()
				},
				{
					"Component" : "Agents",
					"Count"     : arguments.manifest.agents.len()
				},
				{
					"Component" : "MCP Servers",
					"Count"     : totalMCP
				}
			],
			[ "Component", "Count" ]
		);

		print.line();
		printTip( "Run 'coldbox ai stats' to see context usage analysis" );
	}

}
