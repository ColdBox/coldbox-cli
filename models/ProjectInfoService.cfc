/**
 * Project info inspection service for ColdBox applications
 * Collects section-based metadata with error isolation and heuristic parsing.
 */
component singleton {

	// DI
	property name="utility"        inject="Utility@coldbox-cli";
	property name="packageService" inject="PackageService";

	/**
	 * Collect project info by sections
	 *
	 * @directory Target project directory
	 * @sections Array of section names to collect
	 * @verbose Include expanded details
	 * @serverInfo Optional server info struct collected by command layer
	 */
	struct function collect(
		required string directory,
		required array sections,
		boolean verbose  = false,
		struct serverInfo = {}
	){
		var root = arguments.directory

		var report = {
			version      : 1,
			generatedAt  : dateTimeFormat( now(), "iso" ),
			directory    : root,
			warnings     : [],
			errors       : [],
			sections     : {},
			sectionOrder : arguments.sections
		}


		try {
			var context = buildContext( root )
		} catch ( any e ) {
			// Failed to build context
			for ( var sectionName in arguments.sections ) {
				report.sections[ sectionName ] = {
					status : "error",
					data   : { message : "Context build failed: #e.message# #e.detail#" }
				}
				report.errors.append( "#sectionName#: Context build failed: #e.message# #e.detail#" )
			}
			return report
		}

		for ( var sectionName in arguments.sections ) {
		var payload = {}
		switch ( sectionName ) {
			case "project":
					payload = collectProjectSection( context )
					break
				case "server":
					payload = collectServerSection( context, arguments.serverInfo )
					break
				case "deps":
					payload = collectDependenciesSection( context, arguments.verbose )
					break
				case "modules":
					payload = collectModulesSection( context, arguments.verbose )
					break
				case "routes":
					payload = collectRoutesSection( context, arguments.verbose )
					break
				case "scheduler":
					payload = collectSchedulerSection( context, arguments.verbose )
					break
				case "env":
					payload = collectEnvSection( context, arguments.verbose )
					break
				case "cachebox":
					payload = collectCacheBoxSection( context, arguments.verbose )
					break
				case "wirebox":
					payload = collectWireBoxSection( context, arguments.verbose )
					break
				case "logbox":
					payload = collectLogBoxSection( context, arguments.verbose )
					break
				case "config":
					payload = collectConfigSection( context, arguments.verbose )
					break
				default:
					payload = {
						status : "warning",
						data   : { message : "Unknown section '#sectionName#'" }
					}
			}

			report.sections[ sectionName ] = payload
			if ( payload.keyExists( "warnings" ) && payload.warnings.len() ) {
				report.warnings.append( payload.warnings, true )
			}
		}

		return report
	}

	/**
	 * Export report to file
	 */
	string function exportReport(
		required struct report,
		required string format,
		required string directory
	){
		var ext      = lCase( arguments.format )
		var stamp    = dateTimeFormat( now(), "yyyymmdd-HHnnss" )
		var filePath = "#arguments.directory#/coldbox-info-#stamp#.#ext#"

		if ( ext == "json" ) {
			fileWrite( filePath, serializeJSON( arguments.report, true ) )
			return filePath
		}

		if ( ext == "md" ) {
			fileWrite( filePath, toMarkdown( arguments.report ) )
			return filePath
		}

		throw( message = "Unsupported export format '#arguments.format#'. Supported: json, md" )
	}

	// --------------------------------------------------------------------------
	// Context + Section Isolation
	// --------------------------------------------------------------------------

	private struct function buildContext( required string root ){
		var templateType = variables.utility.detectTemplateType( arguments.root )
		var boxJsonPath  = "#arguments.root#/box.json"
		var boxJson      = fileExists( boxJsonPath ) ? deserializeJSON( fileRead( boxJsonPath ) ) : {}

		var appConfigPath = templateType == "modern" ? "#arguments.root#/app/config" : "#arguments.root#/config"
		var appRoot       = templateType == "modern" ? "#arguments.root#/app" : arguments.root

		var routerPath = findFirstExistingFile( [ "#appConfigPath#/Router.bx", "#appConfigPath#/Router.cfc" ] )
		var coldboxPath = findFirstExistingFile( [ "#appConfigPath#/ColdBox.bx", "#appConfigPath#/Coldbox.bx", "#appConfigPath#/ColdBox.cfc", "#appConfigPath#/Coldbox.cfc" ] )
		var schedulerPath = findFirstExistingFile( [ "#appConfigPath#/Scheduler.bx", "#appConfigPath#/Scheduler.cfc" ] )
		var cacheboxPath = findFirstExistingFile( [ "#appConfigPath#/CacheBox.bx", "#appConfigPath#/CacheBox.cfc" ] )
		var wireboxPath = findFirstExistingFile( [ "#appConfigPath#/WireBox.bx", "#appConfigPath#/WireBox.cfc" ] )
		var logboxPath = findFirstExistingFile( [ "#appConfigPath#/LogBox.bx", "#appConfigPath#/LogBox.cfc" ] )

		return {
			root         : arguments.root,
			templateType : templateType,
			appRoot      : appRoot,
			configRoot   : appConfigPath,
			boxJsonPath  : boxJsonPath,
			boxJson      : boxJson,
			paths        : {
				handlers   : "#appRoot#/handlers",
				models     : "#appRoot#/models",
				views      : "#appRoot#/views",
				layouts    : "#appRoot#/layouts",
				tests      : "#arguments.root#/tests",
				modules    : "#arguments.root#/modules",
				modulesApp : "#arguments.root#/modules_app",
				router     : routerPath,
				coldbox    : coldboxPath,
				scheduler  : schedulerPath,
				cachebox   : cacheboxPath,
				wirebox    : wireboxPath,
				logbox     : logboxPath
			}
		}
	}

	private string function findFirstExistingFile( required array candidates ){
		for ( var thisPath in arguments.candidates ) {
			if ( thisPath.len() && fileExists( thisPath ) ) {
				return thisPath
			}
		}
		return ""
	}

	// --------------------------------------------------------------------------
	// Section Collectors
	// --------------------------------------------------------------------------

	private struct function collectProjectSection( required struct context ){
		var boxJson = arguments.context.boxJson
		return {
			status : "ok",
			data   : {
				name         : boxJson.keyExists( "name" ) ? boxJson.name : "unknown",
				version      : boxJson.keyExists( "version" ) ? boxJson.version : "unknown",
				templateType : arguments.context.templateType,
				language     : boxJson.keyExists( "language" ) ? boxJson.language : "unknown",
				root         : arguments.context.root,
				coldbox      : arguments.context.paths.coldbox,
				router       : arguments.context.paths.router
			}
		}
	}

	private struct function collectServerSection(
		required struct context,
		struct serverInfo = {}
	){
		if ( !arguments.serverInfo.count() ) {
			return {
				status   : "warning",
				warnings : [ "Server information unavailable" ],
				data     : { available : false }
			}
		}

		return {
			status : "ok",
			data   : duplicate( arguments.serverInfo )
		}
	}

	private struct function collectDependenciesSection(
		required struct context,
		boolean verbose = false
	){
		var boxJson      = arguments.context.boxJson
		var deps         = boxJson.dependencies ?: {}
		var devDeps      = boxJson.devDependencies ?: {}
		var installPaths = boxJson.installPaths ?: {}

		var data = {
			productionCount : deps.count(),
			developmentCount: devDeps.count(),
			core            : {
				coldbox : deps.coldbox ?: "",
				testbox : devDeps.testbox ?: deps.testbox ?: ""
			}
		}

		if ( arguments.verbose ) {
			data.production = deps
			data.development = devDeps
			data.installPaths = installPaths
		}

		return { status : "ok", data : data }
	}

	private struct function collectModulesSection(
		required struct context,
		boolean verbose = false
	){
		var roots = []
		if ( directoryExists( arguments.context.paths.modules ) ) {
			roots.append( arguments.context.paths.modules )
		}
		if ( directoryExists( arguments.context.paths.modulesApp ) ) {
			roots.append( arguments.context.paths.modulesApp )
		}

		var modules = []
		roots.each( ( rootPath ) => {
			modules.append( discoverModulesRecursive( rootPath ), true )
		} )

		var data = {
			count   : modules.len(),
			modules : modules.map( ( mod ) => {
				return {
					name         : mod.name,
					path         : mod.path,
					root         : mod.root,
					hasRouter    : mod.hasRouter,
					hasScheduler : mod.hasScheduler,
					hasConfig    : mod.hasConfig
				}
			} )
		}

		if ( arguments.verbose ) {
			data.details = modules
		}

		return { status : "ok", data : data }
	}

	private array function discoverModulesRecursive( required string rootPath ){
		var discovered = []
		var dirs       = directoryList( arguments.rootPath, true, "path", "", "dir" )

		dirs.each( ( dirPath ) => {
			var moduleConfig = findFirstExistingFile( [ "#dirPath#/ModuleConfig.bx", "#dirPath#/ModuleConfig.cfc" ] )
			if ( moduleConfig.len() ) {
				var relativeName = replaceNoCase( dirPath, arguments.rootPath & "/", "" )
				discovered.append( {
					name         : relativeName,
					path         : dirPath,
					root         : getFileFromPath( arguments.rootPath ),
					hasConfig    : true,
					hasRouter    : findFirstExistingFile( [ "#dirPath#/config/Router.bx", "#dirPath#/config/Router.cfc" ] ).len() > 0,
					hasScheduler : findFirstExistingFile( [ "#dirPath#/config/Scheduler.bx", "#dirPath#/config/Scheduler.cfc" ] ).len() > 0
				} )
			}
		} )

		return discovered
	}

	private struct function collectRoutesSection(
		required struct context,
		boolean verbose = false
	){
		var routeFiles = []
		if ( arguments.context.paths.router.len() ) {
			routeFiles.append( {
				scope : "app",
				path  : arguments.context.paths.router
			} )
		}

		var modulesSection = collectModulesSection( arguments.context, true )
		modulesSection.data.details.each( ( mod ) => {
			var moduleRouter = findFirstExistingFile( [ "#mod.path#/config/Router.bx", "#mod.path#/config/Router.cfc" ] )
			if ( moduleRouter.len() ) {
				routeFiles.append( {
					scope  : "module",
					module : mod.name,
					path   : moduleRouter
				} )
			}
		} )

		var entries = []
		routeFiles.each( ( fileInfo ) => {
			entries.append( parseRoutesFromFile( fileInfo.path, fileInfo.scope, fileInfo.module ?: "" ), true )
		} )

		var data = {
			files        : routeFiles,
			count        : entries.len(),
			appCount     : entries.filter( ( e ) => e.scope == "app" ).len(),
			moduleCount  : entries.filter( ( e ) => e.scope == "module" ).len(),
			parseMode    : "heuristic"
		}

		if ( arguments.verbose ) {
			data.entries = entries
		}

		return { status : "ok", data : data }
	}

	private array function parseRoutesFromFile(
		required string filePath,
		required string scope,
		string moduleName = ""
	){
		var lines   = fileRead( arguments.filePath ).listToArray( chr( 10 ) )
		var entries = []

		for ( var i = 1; i <= lines.len(); i++ ) {
			var line = trim( lines[ i ] )
			if ( reFindNoCase( "(route|resources|apiResources|moduleRouting)\s*\(", line ) ) {
				var typeMatch = reFindNoCase( "(route|resources|apiResources|moduleRouting)", line, 1, true )
				var routeType = typeMatch.pos.len() ? mid( line, typeMatch.pos[ 1 ], typeMatch.len[ 1 ] ) : "route"
				entries.append( {
					file      : arguments.filePath,
					scope     : arguments.scope,
					module    : arguments.moduleName,
					line      : i,
					type      : routeType,
					signature : line,
					confidence: "heuristic"
				} )
			}
		}

		return entries
	}

	private struct function collectSchedulerSection(
		required struct context,
		boolean verbose = false
	){
		var schedulerFiles = []
		if ( arguments.context.paths.scheduler.len() ) {
			schedulerFiles.append( {
				scope : "app",
				path  : arguments.context.paths.scheduler
			} )
		}

		var modulesSection = collectModulesSection( arguments.context, true )
		modulesSection.data.details.each( ( mod ) => {
			var moduleScheduler = findFirstExistingFile( [ "#mod.path#/config/Scheduler.bx", "#mod.path#/config/Scheduler.cfc" ] )
			if ( moduleScheduler.len() ) {
				schedulerFiles.append( {
					scope  : "module",
					module : mod.name,
					path   : moduleScheduler
				} )
			}
		} )

		var tasks = []
		schedulerFiles.each( ( fileInfo ) => {
			tasks.append( parseTasksFromScheduler( fileInfo.path, fileInfo.scope, fileInfo.module ?: "" ), true )
		} )

		var data = {
			files     : schedulerFiles,
			taskCount : tasks.len(),
			parseMode : "heuristic"
		}

		if ( arguments.verbose ) {
			data.tasks = tasks
		}

		return { status : "ok", data : data }
	}

	private array function parseTasksFromScheduler(
		required string filePath,
		required string scope,
		string moduleName = ""
	){
		var lines = fileRead( arguments.filePath ).listToArray( chr( 10 ) )
		var tasks = []

		for ( var i = 1; i <= lines.len(); i++ ) {
			var line = trim( lines[ i ] )
			if ( reFindNoCase( "task\s*\(", line ) ) {
				var taskName = extractFirstQuotedValue( line )
				tasks.append( {
					file       : arguments.filePath,
					scope      : arguments.scope,
					module     : arguments.moduleName,
					line       : i,
					task       : taskName,
					signature  : line,
					confidence : "heuristic"
				} )
			}
		}

		return tasks
	}

	private string function extractFirstQuotedValue( required string line ){
		var firstDouble = find( '"', arguments.line )
		var firstSingle = find( "'", arguments.line )

		var quotePos  = 0
		var quoteChar = ""

		if ( firstDouble && firstSingle ) {
			if ( firstDouble < firstSingle ) {
				quotePos  = firstDouble
				quoteChar = '"'
			} else {
				quotePos  = firstSingle
				quoteChar = "'"
			}
		} else if ( firstDouble ) {
			quotePos  = firstDouble
			quoteChar = '"'
		} else if ( firstSingle ) {
			quotePos  = firstSingle
			quoteChar = "'"
		}

		if ( !quotePos ) {
			return "(unknown)"
		}

		var endQuotePos = find( quoteChar, arguments.line, quotePos + 1 )
		if ( !endQuotePos ) {
			return "(unknown)"
		}

		return mid( arguments.line, quotePos + 1, endQuotePos - quotePos - 1 )
	}

	private struct function collectEnvSection(
		required struct context,
		boolean verbose = false
	){
		var envPath = "#arguments.context.root#/.env"
		if ( !fileExists( envPath ) ) {
			return {
				status : "warning",
				data   : {
					present : false,
					keys    : []
				},
				warnings : [ ".env file not found" ]
			}
		}

		var keys = []
		fileRead( envPath )
			.listToArray( chr( 10 ) )
			.each( ( line ) => {
				var trimmed = trim( line )
				if ( !trimmed.len() || left( trimmed, 1 ) == "##" || !trimmed.find( "=" ) ) {
					return
				}
				keys.append( trim( listFirst( trimmed, "=" ) ) )
			} )

		return {
			status : "ok",
			data   : {
				present : true,
				count   : keys.len(),
				keys    : keys
			}
		}
	}

	private struct function collectCacheBoxSection(
		required struct context,
		boolean verbose = false
	){
		var sourceFile = arguments.context.paths.cachebox
		var sourceType = "dedicated"

		if ( !sourceFile.len() ) {
			sourceFile = arguments.context.paths.coldbox
			sourceType = "inline"
		}

		if ( !sourceFile.len() ) {
			return {
				status : "warning",
				warnings : [ "CacheBox configuration not found" ],
				data : { configured : false }
			}
		}

		var content = fileRead( sourceFile )
		var cacheStructHits = reMatchNoCase( "cacheBox\\s*[:=]\\s*\\{", content )
		var providerHits    = reMatchNoCase( "provider\\s*[:=]", content )

		var data = {
			configured : cacheStructHits.len() > 0,
			sourceFile : sourceFile,
			sourceType : sourceType,
			providers  : providerHits.len(),
			parseMode  : "heuristic"
		}

		if ( arguments.verbose ) {
			data.structMatches = cacheStructHits.len()
		}

		return { status : "ok", data : data }
	}

	private struct function collectWireBoxSection(
		required struct context,
		boolean verbose = false
	){
		var sourceFile = arguments.context.paths.wirebox
		var sourceType = "dedicated"

		if ( !sourceFile.len() ) {
			sourceFile = arguments.context.paths.coldbox
			sourceType = "inline"
		}

		if ( !sourceFile.len() ) {
			return {
				status : "warning",
				warnings : [ "WireBox configuration not found" ],
				data : { configured : false }
			}
		}

		var content      = fileRead( sourceFile )
		var mappingHits  = reMatchNoCase( "map\s*\(", content )
		var aopHints     = reMatchNoCase( "aop|aspect|bindAspect|virtualInheritance", content )
		var scopeRegHits = reMatchNoCase( "scopeRegistration", content )

		var data = {
			configured        : true,
			sourceFile        : sourceFile,
			sourceType        : sourceType,
			mappingsEstimated : mappingHits.len(),
			aopHints          : aopHints.len(),
			scopeRegistration : scopeRegHits.len() > 0,
			parseMode         : "heuristic"
		}

		if ( arguments.verbose ) {
			data.mappingLines = mappingHits.len()
		}

		return { status : "ok", data : data }
	}

	private struct function collectLogBoxSection(
		required struct context,
		boolean verbose = false
	){
		var sourceFile = arguments.context.paths.logbox
		var sourceType = "dedicated"

		if ( !sourceFile.len() ) {
			sourceFile = arguments.context.paths.coldbox
			sourceType = "inline"
		}

		if ( !sourceFile.len() ) {
			return {
				status : "warning",
				warnings : [ "LogBox configuration not found" ],
				data : { configured : false }
			}
		}

		var content      = fileRead( sourceFile )
		var appenders    = reMatchNoCase( "appenders\s*[:=]", content )
		var appenderRefs = reMatchNoCase( "Appender", content )
		var rootHits     = reMatchNoCase( "root\s*[:=]", content )

		var data = {
			configured         : true,
			sourceFile         : sourceFile,
			sourceType         : sourceType,
			appendersDeclared  : appenders.len() > 0,
			appendersEstimated : appenderRefs.len(),
			hasRootLogger      : rootHits.len() > 0,
			parseMode          : "heuristic"
		}

		if ( arguments.verbose ) {
			data.matches = {
				appenders : appenders.len(),
				root      : rootHits.len()
			}
		}

		return { status : "ok", data : data }
	}

	private struct function collectConfigSection(
		required struct context,
		boolean verbose = false
	){
		if ( !arguments.context.paths.coldbox.len() ) {
			return {
				status : "warning",
				warnings : [ "ColdBox configuration file not found" ],
				data : { configured : false }
			}
		}

		var content = fileRead( arguments.context.paths.coldbox )
		var data    = {
			configured      : true,
			sourceFile      : arguments.context.paths.coldbox,
			hasModuleConfig : reFindNoCase( "moduleSettings", content ) > 0,
			hasConventions  : reFindNoCase( "conventions", content ) > 0,
			hasEnvironments : reFindNoCase( "environments", content ) > 0,
			parseMode       : "heuristic"
		}

		if ( arguments.verbose ) {
			data.matches = {
				moduleSettings : reMatchNoCase( "moduleSettings", content ).len(),
				conventions    : reMatchNoCase( "conventions", content ).len(),
				environments   : reMatchNoCase( "environments", content ).len()
			}
		}

		return { status : "ok", data : data }
	}

	// --------------------------------------------------------------------------
	// Markdown Export
	// --------------------------------------------------------------------------

	private string function toMarkdown( required struct report ){
		var lines = []
		lines.append( "## ColdBox Project Info" )
		lines.append( "" )
		lines.append( "Generated: #arguments.report.generatedAt#" )
		lines.append( "Directory: #arguments.report.directory#" )
		lines.append( "" )

		if ( arguments.report.errors.len() ) {
			lines.append( "## Errors" )
			arguments.report.errors.each( ( err ) => lines.append( "- #err#" ) )
			lines.append( "" )
		}

		if ( arguments.report.warnings.len() ) {
			lines.append( "## Warnings" )
			arguments.report.warnings.each( ( warning ) => lines.append( "- #warning#" ) )
			lines.append( "" )
		}

		arguments.report.sectionOrder.each( ( sectionName ) => {
			if ( !arguments.report.sections.keyExists( sectionName ) ) {
				return
			}
			lines.append( "## #uCase( left( sectionName, 1 ) )##right( sectionName, -1 )#" )
			lines.append( "```json" )
			lines.append( serializeJSON( arguments.report.sections[ sectionName ].data ?: {}, true ) )
			lines.append( "```" )
			lines.append( "" )
		} )

		return lines.toList( chr( 10 ) )
	}

}
