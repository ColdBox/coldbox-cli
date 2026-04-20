/**
 * Registry for AI agent configurations
 * Manages agent-specific files (CLAUDE.md, .github/copilot-instructions.md, etc.)
 */
component singleton {

	// DI
	property name="print"          inject="PrintBuffer";
	property name="fileSystemUtil" inject="fileSystem";
	property name="wirebox"        inject="wirebox";
	property name="utility"        inject="Utility@coldbox-cli";
	property name="mcpRegistry"    inject="MCPRegistry@coldbox-cli";

	static {
		SUPPORTED_AGENTS = [
			"claude",
			"copilot",
			"cursor",
			"codex",
			"gemini",
			"opencode"
		]
		AGENT_FILES = {
			"claude"   : "CLAUDE.md",
			"copilot"  : ".github/copilot-instructions.md",
			"cursor"   : ".cursorrules",
			"codex"    : "AGENTS.md",
			"gemini"   : "GEMINI.md",
			"opencode" : "AGENTS.md"
		}
		// Demarcation markers that wrap the ColdBox CLI-managed section
		MANAGED_SECTION_START = "<!-- COLDBOX-CLI:START -->"
		MANAGED_SECTION_END   = "<!-- COLDBOX-CLI:END -->"
		AGENT_OPTIONS         = [
			{
				display : "Claude (Anthropic) - Recommended for general development",
				value   : "claude"
			},
			{
				display : "GitHub Copilot - Integrated with VS Code",
				value   : "copilot"
			},
			{
				display : "Cursor AI - AI-first code editor",
				value   : "cursor"
			},
			{
				display : "Codex (OpenAI) - GPT-powered coding assistant",
				value   : "codex"
			},
			{
				display : "Gemini (Google) - Google's AI assistant",
				value   : "gemini"
			},
			{
				display : "OpenCode - Open source AI assistant",
				value   : "opencode"
			}
		]

		// Compiled once (singleton) — matches any public function declaration
		FUNCTION_PATTERN = createObject( "java", "java.util.regex.Pattern" ).compile(
			"(?i)(?:^|\s)(?:public\s+)?(?:\w+\s+)?function\s+(\w+)\s*\("
		)
	}

	// Expose them as instance properties for easier access in commands
	this.SUPPORTED_AGENTS = static.SUPPORTED_AGENTS
	this.AGENT_OPTIONS    = static.AGENT_OPTIONS
	this.AGENT_FILES      = static.AGENT_FILES
	this.FUNCTION_PATTERN = static.FUNCTION_PATTERN

	/**
	 * Configure agents for a project
	 *
	 * @directory The project directory
	 * @agents Comma-separated list of agents
	 * @language Project language mode
	 */
	function configureAgents(
		required string directory,
		required string agents,
		required string language
	){
		return listToArray( arguments.agents ).map( ( agent ) => {
			configureAgent( directory, agent, language )
			return agent
		} )
	}

	/**
	 * Get the config path mapping for all supported agents or a specific agent if passed
	 *
	 * @agentName Optional agent name to get specific path for (claude, copilot, cursor, codex, gemini, opencode)
	 *
	 * @return Struct with agent names as keys and config paths as values as per their conventions
	 */
	function getAgentConfigPaths( string agentName ){
		if ( !isNull( arguments.agentName ) ) {
			return static.AGENT_FILES[ arguments.agentName ] ?: "AI_INSTRUCTIONS.md"
		}

		return static.AGENT_FILES
	}

	/**
	 * Diagnose agent configuration health
	 *
	 * @directory The project directory
	 * @manifest The manifest struct
	 */
	function diagnose(
		required string directory,
		required struct manifest
	){
		var issues = {
			"warnings"        : [],
			"recommendations" : []
		};

		// Check each configured agentr
		var agents = manifest.agents ?: [];
		agents.each( ( agent ) => {
			var configFile = getAgentConfigPath( directory, agent )
			if ( !fileExists( configFile ) ) {
				issues.warnings.append( "Agent config file missing: #agent#" )
				issues.recommendations.append( "Run 'coldbox ai refresh' to regenerate agent files" )
			}
		} )

		return issues;
	}

	// ========================================
	// Private Helpers
	// ========================================

	/**
	 * Merges newly generated managed content with any user-authored content from an existing file.
	 *
	 * The managed section is delimited by COLDBOX-CLI:START and COLDBOX-CLI:END HTML comment
	 * markers. On refresh, only the content between those markers is replaced; everything after
	 * the end marker (i.e. the user's custom documentation) is preserved unchanged.
	 *
	 * Behavior:
	 * - File does not exist → return newContent as-is (first-time write).
	 * - File exists but has no end marker → return newContent as-is (old format, no user section to preserve).
	 * - File exists with end marker → replace managed section, keep user section intact.
	 *
	 * @filePath   Absolute path to the existing agent config file (may not exist yet).
	 * @newContent Freshly generated content that includes both START and END markers.
	 *
	 * @return Combined content with updated managed section and preserved user section.
	 */
	private string function mergeUserContent(
		required string filePath,
		required string newContent
	){
		var endMarker = static.MANAGED_SECTION_END

		// Nothing to preserve — first-time write
		if ( !fileExists( filePath ) ) {
			return newContent
		}

		var existingContent = fileRead( filePath )

		// Find the end marker in the existing file
		var endPos = findNoCase( endMarker, existingContent )

		// Old-format file (no markers) — write fresh content, no user section to preserve
		if ( !endPos ) {
			return newContent
		}

		// Extract user content: everything that comes after the end marker
		var userStartPos = endPos + len( endMarker )
		var userContent  = mid(
			existingContent,
			userStartPos,
			len( existingContent ) - userStartPos + 1
		)

		// Find the end marker position in the newly generated content
		var newEndPos = findNoCase( endMarker, newContent )
		if ( !newEndPos ) {
			// New template has no end marker — return new content plus preserved user section
			return newContent & userContent
		}

		// Slice off the managed portion of the new content (up to and including the end marker)
		var managedContent = left(
			newContent,
			newEndPos + len( endMarker ) - 1
		)

		return managedContent & userContent
	}

	/**
	 * Configure a single agent
	 *
	 * @directory The project directory
	 * @agent The agent name (claude, copilot, cursor, etc.)
	 * @language Project language mode (boxlang, cfml, hybrid)
	 */
	function configureAgent(
		required string directory,
		required string agent,
		required string language
	){
		var configPath   = getAgentConfigPath( arguments.directory, arguments.agent )
		var templateType = variables.utility.detectTemplateType( arguments.directory )
		var content      = getAgentConfigContent(
			arguments.agent,
			arguments.language,
			templateType,
			arguments.directory
		)

		// Create directories if needed
		var configDir = getDirectoryFromPath( configPath )
		if ( !directoryExists( configDir ) ) {
			directoryCreate( configDir )
		}

		// For Claude, write the full content to AGENTS.md and make CLAUDE.md point to it
		if ( arguments.agent == "claude" ) {
			var agentsFilePath = getDirectoryFromPath( configPath ) & "AGENTS.md"
			var mergedContent  = mergeUserContent( agentsFilePath, content )
			fileWrite( agentsFilePath, mergedContent )
			fileWrite( configPath, "@AGENTS.md" )
			return
		}

		// Write agent config file, preserving any user-authored content outside the managed section
		fileWrite(
			configPath,
			mergeUserContent( configPath, content )
		)
	}

	/**
	 * Get agent config file path for a specific agent on a specific project directory
	 *
	 * @directory The project directory
	 * @agent The agent name (claude, copilot, cursor, etc.)
	 */
	function getAgentConfigPath(
		required string directory,
		required string agent
	){
		// Check if directory ends in / or \ and remove it for consistent path building
		if ( right( arguments.directory, 1 ) == "/" || right( arguments.directory, 1 ) == "\" ) {
			arguments.directory = left(
				arguments.directory,
				len( arguments.directory ) - 1
			)
		}

		switch ( arguments.agent ) {
			case "claude":
				return "#arguments.directory#/CLAUDE.md"
			case "copilot":
				return "#arguments.directory#/.github/copilot-instructions.md"
			case "cursor":
				return "#arguments.directory#/.cursorrules"
			case "codex":
				return "#arguments.directory#/AGENTS.md"
			case "gemini":
				return "#arguments.directory#/GEMINI.md"
			case "opencode":
				return "#arguments.directory#/AGENTS.md"
			default:
				return "#arguments.directory#/AI_INSTRUCTIONS.md"
		}
	}

	/**
	 * Get agent config content (reads from template)
	 *
	 * @agent The agent name (claude, copilot, cursor, etc.)
	 * @language Project language mode (boxlang, cfml, hybrid)
	 * @templateType Project template type (flat or modern)
	 * @directory The project directory
	 */
	private function getAgentConfigContent(
		required string agent,
		required string language,
		required string templateType,
		required string directory
	){
		var templatesPath = variables.utility.getTemplatesPath()
		var templateFile  = ""

		// Use layout-specific templates for all agents
		templateFile = arguments.templateType == "modern"
		 ? "#templatesPath#/ai/agents/agent-modern-instructions.md"
		 : "#templatesPath#/ai/agents/agent-flat-instructions.md"

		if ( !fileExists( templateFile ) ) {
			throw(
				type    = "AgentRegistry.TemplateNotFound",
				message = "Agent template not found: #templateFile#"
			)
		}

		var content = fileRead( templateFile )

		// Get project information
		var boxJson     = {}
		var boxJsonPath = "#arguments.directory#/box.json"
		if ( fileExists( boxJsonPath ) ) {
			boxJson = deserializeJSON( fileRead( boxJsonPath ) )
		}

		var projectName    = boxJson.name ?: getFileFromPath( arguments.directory )
		var coldboxVersion = boxJson.dependencies.coldbox ?: "8.x"

		// Determine language mode display
		var languageMode = "BoxLang"
		if ( arguments.language == "cfml" ) {
			languageMode = "CFML"
		} else if ( arguments.language == "hybrid" ) {
			languageMode = "BoxLang/CFML Hybrid"
		}

		// Detect enabled features
		var viteEnabled       = detectViteEnabled( arguments.directory )
		var dockerEnabled     = detectDockerEnabled( arguments.directory )
		var ormEnabled        = detectOrmEnabled( boxJson )
		var migrationsEnabled = detectMigrationsEnabled( arguments.directory, boxJson )

		// Build features list
		var enabledFeatures = []
		if ( viteEnabled ) enabledFeatures.append( "Vite" )
		if ( dockerEnabled ) enabledFeatures.append( "Docker" )
		if ( ormEnabled ) enabledFeatures.append( "ORM" )
		if ( migrationsEnabled ) enabledFeatures.append( "Migrations" )

		var features = enabledFeatures.len() ? enabledFeatures.toList( ", " ) : "None"

		// Replace placeholders
		content = replaceNoCase(
			content,
			"|PROJECT_NAME|",
			projectName,
			"all"
		)
		content = replaceNoCase(
			content,
			"|LANGUAGE_MODE|",
			languageMode,
			"all"
		)
		content = replaceNoCase(
			content,
			"|COLDBOX_VERSION|",
			coldboxVersion,
			"all"
		)
		content = replaceNoCase(
			content,
			"|FEATURES|",
			features,
			"all"
		)
		content = replaceNoCase(
			content,
			"|VITE_ENABLED|",
			viteEnabled ? "Yes" : "No",
			"all"
		)
		content = replaceNoCase(
			content,
			"|DOCKER_ENABLED|",
			dockerEnabled ? "Yes" : "No",
			"all"
		)
		content = replaceNoCase(
			content,
			"|ORM_ENABLED|",
			ormEnabled ? "Yes" : "No",
			"all"
		)
		content = replaceNoCase(
			content,
			"|MIGRATIONS_ENABLED|",
			migrationsEnabled ? "Yes" : "No",
			"all"
		)

		// Add guidelines inventory (module and additional guidelines only)
		// Language-specific guideline file and description
		var languageGuidelineFile = "`.ai/guidelines/core/boxlang.md`"
		var languageGuidelineDesc = "BoxLang syntax and patterns"
		if ( arguments.language == "cfml" ) {
			languageGuidelineFile = "`.ai/guidelines/core/cfml.md`"
			languageGuidelineDesc = "CFML syntax and patterns"
		} else if ( arguments.language == "hybrid" ) {
			languageGuidelineFile = "`.ai/guidelines/core/boxlang.md`"
			languageGuidelineDesc = "BoxLang/CFML syntax and patterns (or `cfml.md` for CFML-only)"
		}
		content = replaceNoCase(
			content,
			"|LANGUAGE_GUIDELINE_FILE|",
			languageGuidelineFile,
			"all"
		)
		content = replaceNoCase(
			content,
			"|LANGUAGE_GUIDELINE_DESC|",
			languageGuidelineDesc,
			"all"
		)

		// Generate installed modules content
		var installedModulesContent = generateInstalledModulesContent( arguments.directory, boxJson )
		content                     = replaceNoCase(
			content,
			"|INSTALLED_MODULES|",
			installedModulesContent,
			"all"
		)

		// Generate handlers snapshot
		var handlersSnapshotContent = generateHandlersSnapshot(
			arguments.directory,
			arguments.templateType
		)
		content = replaceNoCase(
			content,
			"|HANDLERS_SNAPSHOT|",
			handlersSnapshotContent,
			"all"
		)

		// Generate interceptors snapshot
		var interceptorsSnapshotContent = generateInterceptorsSnapshot(
			arguments.directory,
			arguments.templateType
		)
		content = replaceNoCase(
			content,
			"|INTERCEPTORS_SNAPSHOT|",
			interceptorsSnapshotContent,
			"all"
		)

		// Generate layouts snapshot
		var layoutsSnapshotContent = generateLayoutsSnapshot(
			arguments.directory,
			arguments.templateType
		)
		content = replaceNoCase(
			content,
			"|LAYOUTS_SNAPSHOT|",
			layoutsSnapshotContent,
			"all"
		)

		// Generate custom modules snapshot
		var customModulesContent = generateCustomModulesSnapshot(
			arguments.directory,
			arguments.templateType
		)
		content = replaceNoCase(
			content,
			"|CUSTOM_MODULES_SNAPSHOT|",
			customModulesContent,
			"all"
		)

		// Add guidelines inventory (module and additional guidelines only)
		var guidelinesContent = generateGuidelinesContent(
			arguments.directory,
			arguments.language
		)
		content = replaceNoCase(
			content,
			"|GUIDELINES_INVENTORY|",
			guidelinesContent,
			"all"
		)

		// Add skills inventory
		var skillsContent = generateSkillsContent( arguments.directory )
		content           = replaceNoCase(
			content,
			"|SKILLS_INVENTORY|",
			skillsContent,
			"all"
		)

		// Add MCP servers content
		var mcpContent = generateMCPServersContent( arguments.directory )
		content        = replaceNoCase(
			content,
			"|MCP_SERVERS|",
			mcpContent,
			"all"
		)

		return content
	}

	/**
	 * Detect if Vite is enabled in the project
	 */
	private function detectViteEnabled( required string directory ){
		var viteConfig  = "#arguments.directory#/vite.config.mjs"
		var packageJson = "#arguments.directory#/package.json"

		if ( fileExists( viteConfig ) ) return true

		if ( fileExists( packageJson ) ) {
			var pkgContent = deserializeJSON( fileRead( packageJson ) )
			return structKeyExists(
				pkgContent.dependencies ?: {},
				"vite"
			) ||
			structKeyExists(
				pkgContent.devDependencies ?: {},
				"vite"
			)
		}

		return false
	}

	/**
	 * Detect if Docker is enabled in the project
	 */
	private function detectDockerEnabled( required string directory ){
		return fileExists( "#arguments.directory#/Dockerfile" ) ||
		fileExists( "#arguments.directory#/docker-compose.yml" )
	}

	/**
	 * Detect if ORM is enabled (cborm or quick)
	 */
	private function detectOrmEnabled( required struct boxJson ){
		var deps    = boxJson.dependencies ?: {}
		var devDeps = boxJson.devDependencies ?: {}

		return structKeyExists( deps, "cborm" ) ||
		structKeyExists( devDeps, "cborm" ) ||
		structKeyExists( deps, "quick" ) ||
		structKeyExists( devDeps, "quick" )
	}

	/**
	 * Detect if migrations are enabled
	 */
	private function detectMigrationsEnabled(
		required string directory,
		required struct boxJson
	){
		// Check for migrations in dependencies
		var deps    = boxJson.dependencies ?: {}
		var devDeps = boxJson.devDependencies ?: {}

		if (
			structKeyExists( deps, "commandbox-migrations" ) ||
			structKeyExists( devDeps, "commandbox-migrations" )
		) {
			return true
		}

		// Check for migrations directory
		return directoryExists( "#arguments.directory#/resources/database/migrations" )
	}

	/**
	 * Generate inline guidelines content (core framework guidelines only)
	 *
	 * @directory The project directory
	 * @language The project language (boxlang, cfml, hybrid)
	 *
	 * @return String containing full content of core framework guidelines
	 */
	private function generateInlineGuidelinesContent(
		required string directory,
		required string language
	){
		var content          = [];
		var guidelineManager = variables.wirebox.getInstance( "GuidelineManager@coldbox-cli" );
		var aiService        = variables.wirebox.getInstance( "AIService@coldbox-cli" );
		var manifest         = aiService.loadManifest( arguments.directory );
		var coreGuidelines   = manifest.guidelines.filter( ( g ) => g.type == "core" );

		// Determine which guidelines to inline
		var guidelinesToInline = [ "coldbox" ];
		if ( arguments.language == "boxlang" || arguments.language == "hybrid" ) {
			guidelinesToInline.append( "boxlang" );
		}
		if ( arguments.language == "cfml" || arguments.language == "hybrid" ) {
			guidelinesToInline.append( "cfml" );
		}

		// Store directory in local variable for closure access
		var projectDirectory = arguments.directory;

		// Load and inline each guideline
		guidelinesToInline.each( ( guidelineName ) => {
			// Check if guideline is installed
			var installed = coreGuidelines.filter( ( g ) => g.name == guidelineName );
			if ( !installed.len() ) {
				return;
			}

			// Get guideline content
			var guidelineContent = guidelineManager.getGuidelineContent(
				projectDirectory,
				guidelineName,
				"core"
			);

			if ( guidelineContent.len() ) {
				content.append( "---" );
				content.append( "" );
				content.append( guidelineContent );
				content.append( "" );
			}
		} );

		if ( !content.len() ) {
			return "No core guidelines available. Run 'coldbox ai refresh' to initialize.";
		}

		return content.toList( chr( 10 ) );
	}

	/**
	 * Generate guidelines inventory for agent configuration
	 * Excludes inlined guidelines (core framework guidelines)
	 *
	 * @directory The project directory
	 * @language The project language (boxlang, cfml, hybrid)
	 *
	 * @return String containing formatted guidelines inventory
	 */
	private function generateGuidelinesContent(
		required string directory,
		required string language
	){
		// Load manifest to get guidelines
		var aiService = variables.wirebox.getInstance( "AIService@coldbox-cli" )
		var manifest  = aiService.loadManifest( arguments.directory )

		if ( !structKeyExists( manifest, "guidelines" ) || !manifest.guidelines.len() ) {
			return "No guidelines installed yet. Run 'coldbox ai install' to get started."
		}

		var content = [];

		// Determine which guidelines are inlined (should be excluded from inventory)
		var inlinedGuidelines = [ "coldbox" ];
		if ( arguments.language == "boxlang" || arguments.language == "hybrid" ) {
			inlinedGuidelines.append( "boxlang" );
		}
		if ( arguments.language == "cfml" || arguments.language == "hybrid" ) {
			inlinedGuidelines.append( "cfml" );
		}

		// Group guidelines by type, excluding inlined ones
		var coreGuidelines = manifest.guidelines.filter( ( g ) => {
			return g.type == "core" && !inlinedGuidelines.find( g.name )
		} );
		var customGuidelines = manifest.guidelines.filter( ( g ) => g.type == "custom" );

		// Core guidelines (only non-inlined ones)
		if ( coreGuidelines.len() ) {
			content.append( "**Additional Framework Guidelines (Available on request):**" );
			content.append( "" );
			coreGuidelines.each( ( guideline ) => {
				var desc = structKeyExists( guideline, "description" ) ? guideline.description : "Framework guideline";
				content.append( "- **#guideline.name#** - #desc#" );
			} );
			content.append( "" );
		}

		// Custom guidelines
		if ( customGuidelines.len() ) {
			content.append( "**Custom Guidelines:**" )
			content.append( "" )
			customGuidelines.each( ( guideline ) => {
				var desc = structKeyExists( guideline, "description" ) ? guideline.description : "Custom guideline"
				content.append( "- **#guideline.name#** - #desc#" )
			} )
			content.append( "" )
		}

		if ( !content.len() ) {
			return "No additional module guidelines installed."
		}

		return content.toList( chr( 10 ) )
	}

	/**
	 * Generate skills inventory for agent configuration
	 *
	 * @directory The project directory
	 *
	 * @return String containing formatted skills inventory
	 */
	private function generateSkillsContent( required string directory ){
		// Load manifest to get skills
		var aiService = variables.wirebox.getInstance( "AIService@coldbox-cli" )
		var manifest  = aiService.loadManifest( arguments.directory )

		if ( !structKeyExists( manifest, "skills" ) || !manifest.skills.len() ) {
			return "No skills installed yet. Run 'coldbox ai install' to get started."
		}

		// Prefix-to-category mapping for grouping skill names
		var prefixMap = {
			"coldbox"    : "ColdBox",
			"boxlang"    : "BoxLang",
			"testbox"    : "TestBox",
			"commandbox" : "CommandBox",
			"wirebox"    : "WireBox",
			"cachebox"   : "CacheBox",
			"logbox"     : "LogBox"
		}

		var content      = []
		var coreSkills   = manifest.skills.filter( ( s ) => s.source == "core" )
		var moduleSkills = manifest.skills.filter( ( s ) => s.source != "core" && s.source != "custom" )
		var customSkills = manifest.skills.filter( ( s ) => s.source == "custom" )

		// Helper: group skills by prefix and append formatted output to content
		var appendGroupedSkills = ( skills, sectionLabel ) => {
			if ( !skills.len() ) {
				return;
			}

			// Build grouped struct keyed by category name
			var groups = {}
			skills.each( ( skill ) => {
				var groupName = "Other"
				for ( var prefix in prefixMap ) {
					if ( skill.name.startsWith( prefix & "-" ) || skill.name == prefix ) {
						groupName = prefixMap[ prefix ]
						break
					}
				}
				if ( !structKeyExists( groups, groupName ) ) {
					groups[ groupName ] = []
				}
				groups[ groupName ].append( skill )
			} )

			content.append( "**#sectionLabel#:**" )
			content.append( "" )

			// Use for loops instead of .each() closures to avoid Lucee nested-closure scoping issues
			var sortedGroupNames = groups.keyArray().sort( "textnocase" )
			for ( var groupName in sortedGroupNames ) {
				content.append( "_#groupName# (#groups[ groupName ].len()#):_" )
				for ( var skill in groups[ groupName ] ) {
					var desc = structKeyExists( skill, "description" ) && len( skill.description ) ? skill.description : "Development skill"
					if ( len( desc ) > 80 ) desc = left( desc, 80 ) & "..."
					content.append( "- **#skill.name#** - #desc#" )
				}
				content.append( "" )
			}
		}

		appendGroupedSkills( coreSkills, "Core Skills" )
		appendGroupedSkills( moduleSkills, "Module Skills" )
		appendGroupedSkills( customSkills, "Custom Skills" )

		content.append( "**To load a skill:** Use `read_file` on `.ai/skills/{skill-name}/SKILL.md` (e.g., `.ai/skills/coldbox-handler-development/SKILL.md`)." )

		return content.toList( chr( 10 ) )
	}

	/**
	 * Generate MCP servers content for agent configuration
	 *
	 * @directory The project directory
	 *
	 * @return String containing formatted MCP server list
	 */
	private function generateMCPServersContent( required string directory ){
		// Load manifest to get MCP servers
		var aiService = variables.wirebox.getInstance( "AIService@coldbox-cli" )
		var manifest  = aiService.loadManifest( arguments.directory )

		if ( !structKeyExists( manifest, "mcpServers" ) ) {
			return "No MCP servers configured yet. Run 'coldbox ai refresh' to initialize."
		}

		var mcpServers = manifest.mcpServers
		var content    = []

		// Core servers
		if ( mcpServers.core.len() ) {
			content.append( "**Core Documentation Servers:**" )
			content.append( "" )
			mcpServers.core.each( ( mcpServer ) => {
				var serverDef = variables.mcpRegistry.getServerDefinition( mcpServer )
				if ( !serverDef.isEmpty() ) {
					content.append( "- **#mcpServer#**: #serverDef.description# - #serverDef.url#" )
				}
			} )
			content.append( "" )
		}

		// Module servers
		if ( mcpServers.module.len() ) {
			content.append( "**Module Documentation Servers:**" )
			content.append( "" )
			mcpServers.module.each( ( mcpServer ) => {
				var serverDef = variables.mcpRegistry.getServerDefinition( mcpServer )
				if ( !serverDef.isEmpty() ) {
					content.append( "- **#mcpServer#**: #serverDef.description# - #serverDef.url#" )
				}
			} )
			content.append( "" )
		}

		// Custom servers
		if ( mcpServers.custom.len() ) {
			content.append( "**Custom Documentation Servers:**" )
			content.append( "" )
			mcpServers.custom.each( ( mcpServer ) => {
				var desc    = mcpServer.description ?: "Custom MCP server"
				var details = ""
				if ( structKeyExists( mcpServer, "url" ) ) {
					details = " - #mcpServer.url#"
				} else if ( structKeyExists( mcpServer, "command" ) ) {
					details = " - Command: #mcpServer.command#"
				}
				content.append( "- **#mcpServer.name#**: #desc##details#" )
			} )
			content.append( "" )
		}

		content.append( "**Using MCP Servers:** Query these servers when you need current documentation, API references, or code examples. They provide live, up-to-date information directly from official documentation sources." )

		return content.toList( chr( 10 ) )
	}

	/**
	 * Generate a list of installed project modules (excluding framework packages)
	 *
	 * @directory The project directory
	 * @boxJson   The parsed box.json struct
	 *
	 * @return Formatted markdown bullet list of installed modules
	 */
	private function generateInstalledModulesContent(
		required string directory,
		required struct boxJson
	){
		// Packages to skip — framework internals that aren't actionable for the AI
		var frameworkPackages = [
			"coldbox",
			"testbox",
			"wirebox",
			"cachebox",
			"logbox"
		]

		var dependencies = arguments.boxJson.dependencies ?: {}
		var lines        = []

		for ( var pkg in dependencies ) {
			// Skip framework packages and commandbox-* infrastructure packages
			if ( frameworkPackages.findNoCase( pkg ) || pkg.startsWith( "commandbox-" ) ) {
				continue;
			}
			var version = dependencies[ pkg ]
			lines.append( "- **#pkg#** (#version#)" )
		}

		if ( !lines.len() ) {
			return "No additional modules installed yet."
		}

		lines.sort( "textnocase" )
		return lines.toList( chr( 10 ) )
	}

	/**
	 * Generate a snapshot of existing handlers and their public actions
	 *
	 * @directory    The project directory
	 * @templateType "modern" or "flat"
	 *
	 * @return Formatted markdown bullet list of handlers and their actions
	 */
	private function generateHandlersSnapshot(
		required string directory,
		required string templateType
	){
		var handlersRoot = arguments.templateType == "modern"
		 ? "#arguments.directory#/app/handlers"
		 : "#arguments.directory#/handlers"

		if ( !directoryExists( handlersRoot ) ) {
			return "No handlers found."
		}

		// Lifecycle / framework methods to exclude from the action list
		var lifecycleMethods = [
			"init",
			"onmissingaction",
			"onerror",
			"onrequeststart",
			"onrequestend",
			"onapplicationstart",
			"onsessionstart",
			"onsessionend",
			"onapplicationend"
		]

		var handlerFiles = directoryList(
			handlersRoot,
			false,
			"path",
			"*.cfc|*.bx"
		)
		var lines = []

		for ( var handlerFile in handlerFiles ) {
			var handlerName = listFirst( getFileFromPath( handlerFile ), "." )
			var actions     = extractFunctionNames(
				fileRead( handlerFile ),
				lifecycleMethods
			)

			lines.append(
				actions.len()
				 ? "- **#handlerName#**: #actions.toList( ", " )#"
				 : "- **#handlerName#**: _(no public actions)_"
			)
		}

		if ( !lines.len() ) {
			return "No handlers found."
		}

		lines.sort( "textnocase" )
		return lines.toList( chr( 10 ) )
	}

	/**
	 * Generate a snapshot of existing interceptors and their interception point methods
	 *
	 * @directory    The project directory
	 * @templateType "modern" or "flat"
	 *
	 * @return Formatted markdown bullet list of interceptors and their announced points
	 */
	private function generateInterceptorsSnapshot(
		required string directory,
		required string templateType
	){
		var interceptorsRoot = arguments.templateType == "modern"
		 ? "#arguments.directory#/app/interceptors"
		 : "#arguments.directory#/interceptors"

		if ( !directoryExists( interceptorsRoot ) ) {
			return "No interceptors found."
		}

		// Methods to exclude — framework inherited methods, not interception points
		var excludedMethods = [
			"init",
			"configure",
			"getproperty",
			"setproperty",
			"getproperties"
		]

		var interceptorFiles = directoryList(
			interceptorsRoot,
			false,
			"path",
			"*.cfc|*.bx"
		)
		var lines = []

		for ( var interceptorFile in interceptorFiles ) {
			var interceptorName = listFirst(
				getFileFromPath( interceptorFile ),
				"."
			)
			var points = extractFunctionNames(
				fileRead( interceptorFile ),
				excludedMethods
			)

			lines.append(
				points.len()
				 ? "- **#interceptorName#**: #points.toList( ", " )#"
				 : "- **#interceptorName#**: _(no interception points declared)_"
			)
		}

		if ( !lines.len() ) {
			return "No interceptors found."
		}

		lines.sort( "textnocase" )
		return lines.toList( chr( 10 ) )
	}

	/**
	 * Extract unique public function names from CFML/BoxLang source using the shared compiled pattern.
	 * The matched names are filtered against the provided exclusion list.
	 *
	 * @source          Raw source code string to scan
	 * @excludedMethods Array of method names (case-insensitive) to omit from results
	 *
	 * @return Ordered array of unique, non-excluded function names found in the source
	 */
	private array function extractFunctionNames(
		required string source,
		required array excludedMethods
	){
		var matcher = variables.FUNCTION_PATTERN.matcher( arguments.source )
		var names   = []

		while ( matcher.find() ) {
			var fnName = matcher.group( 1 )
			if ( !arguments.excludedMethods.findNoCase( fnName ) && !names.findNoCase( fnName ) ) {
				names.append( fnName )
			}
		}

		return names
	}

	/**
	 * Generate a snapshot of available layouts
	 *
	 * @directory    The project directory
	 * @templateType "modern" or "flat"
	 *
	 * @return Formatted markdown bullet list of layout files
	 */
	private function generateLayoutsSnapshot(
		required string directory,
		required string templateType
	){
		var layoutsRoot = arguments.templateType == "modern"
		 ? "#arguments.directory#/app/layouts"
		 : "#arguments.directory#/layouts"

		if ( !directoryExists( layoutsRoot ) ) {
			return "No layouts found."
		}

		var layoutFiles = directoryList(
			layoutsRoot,
			false,
			"path",
			"*.cfm|*.bxm"
		)
		var lines = []

		for ( var layoutFile in layoutFiles ) {
			var layoutName = getFileFromPath( layoutFile )
			lines.append( "- **#layoutName#**" )
		}

		if ( !lines.len() ) {
			return "No layouts found."
		}

		lines.sort( "textnocase" )
		return lines.toList( chr( 10 ) )
	}

	/**
	 * Generate a snapshot of application-level custom modules
	 *
	 * Modern template checks: /app/modules
	 * Flat template checks:   /modules_app
	 * Both check the alternate as a fallback if the primary is missing or empty.
	 *
	 * @directory    The project directory
	 * @templateType "modern" or "flat"
	 *
	 * @return Formatted markdown bullet list of custom module names
	 */
	private function generateCustomModulesSnapshot(
		required string directory,
		required string templateType
	){
		// Build candidate paths (primary first, then fallback)
		var candidates = arguments.templateType == "modern"
		 ? [
			"#arguments.directory#/app/modules",
			"#arguments.directory#/modules_app"
		]
		 : [
			"#arguments.directory#/modules_app",
			"#arguments.directory#/app/modules"
		]

		var lines = []

		for ( var modulesRoot in candidates ) {
			if ( !directoryExists( modulesRoot ) ) {
				continue;
			}

			// Each subdirectory is a module
			var moduleDirs = directoryList( modulesRoot, false, "path" )
			if ( !moduleDirs.len() ) {
				continue;
			}

			var label = modulesRoot.replace( arguments.directory, "" ).replaceAll( "^[/\\]", "" )

			for ( var moduleDir in moduleDirs ) {
				if ( directoryExists( moduleDir ) ) {
					var moduleName = getFileFromPath( moduleDir )
					lines.append( "- **#moduleName#** (`#label#`)" )
				}
			}
		}

		if ( !lines.len() ) {
			return "No custom modules found."
		}

		lines.sort( "textnocase" )
		return lines.toList( chr( 10 ) )
	}

}
