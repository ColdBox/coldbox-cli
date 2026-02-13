/**
 * Display ColdBox project information with section filters and exports.
 *
 * Examples:
 * coldbox info
 * coldbox info --routes
 * coldbox info --modules --routes --verbose
 * coldbox info --preset=full --export=md
 */
component extends="coldbox-cli.models.BaseCommand" {

	// DI
	property name="projectInfoService" inject="ProjectInfoService@coldbox-cli";

	/**
	 * @directory The target directory (defaults to current directory)
	 * @preset Section preset: default, full, minimal
	 * @sections Comma-delimited section names to include
	 * @project Include project section
	 * @server Include server section
	 * @deps Include dependencies section
	 * @modules Include modules section
	 * @routes Include routes section
	 * @scheduler Include scheduler section
	 * @env Include env section
	 * @cachebox Include cachebox section
	 * @wirebox Include wirebox section
	 * @logbox Include logbox section
	 * @config Include coldbox config section
	 * @verbose Show expanded details in each section
	 * @json Output report as JSON
	 * @export Export report to file format: json|md
	 * @failOn Fail with non-zero exit code on warnings or errors
	 */
	function run(
		string directory        = getCwd(),
		string preset           = "default",
		string sections         = "",
		boolean project         = false,
		boolean server          = false,
		boolean deps            = false,
		boolean modules         = false,
		boolean routes          = false,
		boolean scheduler       = false,
		boolean env             = false,
		boolean cachebox        = false,
		boolean wirebox         = false,
		boolean logbox          = false,
		boolean config          = false,
		boolean verbose         = false,
		boolean json            = false,
		string export           = "",
		string failOn           = ""
	){
		arguments.directory = resolvePath( arguments.directory )

		if ( !directoryExists( arguments.directory ) ) {
			printError( "Directory does not exist: #arguments.directory#" )
			return
		}

		var sectionOrder = resolveSections( argumentCollection = arguments )
		var serverInfo   = collectServerInfo( arguments.directory )
		var report       = variables.projectInfoService.collect(
			directory  = arguments.directory,
			sections   = sectionOrder,
			verbose    = arguments.verbose,
			serverInfo = serverInfo
		)

		if ( arguments.export.len() ) {
			try {
				var exportPath = variables.projectInfoService.exportReport(
					report    = report,
					format    = arguments.export,
					directory = arguments.directory
				)
				printSuccess( "Report exported to #exportPath#" )
			} catch ( any e ) {
				printError( "Export failed: #e.message#" )
				report.errors.append( "export: #e.message#" )
			}
		}

		if ( arguments.json ) {
			print.line( serializeJSON( report, true ) )
		} else {
			showColdBoxBanner( "Project Info" )
			printHumanReport( report, arguments.verbose )
		}

		applyExitSemantics( report, arguments.failOn )
	}

	private array function resolveSections(
		string preset,
		string sections,
		boolean project,
		boolean server,
		boolean deps,
		boolean modules,
		boolean routes,
		boolean scheduler,
		boolean env,
		boolean cachebox,
		boolean wirebox,
		boolean logbox,
		boolean config
	){
		var presets = {
			"default" : [
				"project",
				"server",
				"deps",
				"modules",
				"routes",
				"scheduler",
				"env",
				"cachebox",
				"wirebox",
				"logbox",
				"config"
			],
			"full" : [
				"project",
				"server",
				"deps",
				"modules",
				"routes",
				"scheduler",
				"env",
				"cachebox",
				"wirebox",
				"logbox",
				"config"
			],
			"minimal" : [ "project", "server" ]
		}

		var selectedPreset = lCase( arguments.preset )
		if ( !presets.keyExists( selectedPreset ) ) {
			selectedPreset = "default"
		}

		var selected = duplicate( presets[ selectedPreset ] )

		if ( arguments.sections.len() ) {
			var sectionList = listToArray( arguments.sections )
			for ( var s in sectionList ) {
				s = lCase( trim( s ) )
				if ( s.len() && !selected.find( s ) ) {
					selected.append( s )
				}
			}
		}

		var sectionFlags = {
			"project"   : arguments.project,
			"server"    : arguments.server,
			"deps"      : arguments.deps,
			"modules"   : arguments.modules,
			"routes"    : arguments.routes,
			"scheduler" : arguments.scheduler,
			"env"       : arguments.env,
			"cachebox"  : arguments.cachebox,
			"wirebox"   : arguments.wirebox,
			"logbox"    : arguments.logbox,
			"config"    : arguments.config
		}

		for ( var sectionName in sectionFlags ) {
			if ( sectionFlags[ sectionName ] && !selected.find( sectionName ) ) {
				selected.append( sectionName )
			}
		}

		return selected
	}

	private struct function collectServerInfo( required string directory ){
		var originalCwd = getCwd()
		var output = command( "server info" )
			.inWorkingDirectory( arguments.directory )
			.params( json = true )
			.run( returnOutput: true )

		if ( !isSimpleValue( output ) || !len( trim( output ) ) ) {
			return {}
		}

		var raw      = trim( output )
		var jsonOpen = find( "{", raw )
		var jsonEnd  = raw.rFind( "}" )
		if ( jsonOpen && jsonEnd > jsonOpen ) {
			raw = mid( raw, jsonOpen, ( jsonEnd - jsonOpen ) + 1 )
		}

		var parsed = deserializeJSON( raw )
		return {
			status : parsed.status ?: "unknown",
			host   : parsed.host ?: "",
			port   : parsed.port ?: "",
			engine : parsed.cfengine ?: parsed.engineName ?: "",
			name   : parsed.name ?: "",
			raw    : parsed
		}
	}

	private void function printHumanReport(
		required struct report,
		boolean verbose = false
	){
		if ( arguments.report.errors.len() ) {
			print.boldRedLine( "❌ Errors (#arguments.report.errors.len()#)" )
			for ( var err in arguments.report.errors ) {
				print.indentedRedLine( "  • #err#" )
			}
			print.line()
		}

		if ( arguments.report.warnings.len() ) {
			print.boldYellowLine( "⚠ Warnings (#arguments.report.warnings.len()#)" )
			for ( var warning in arguments.report.warnings ) {
				print.indentedYellowLine( "  • #warning#" )
			}
			print.line()
		}

		for ( var sectionName in arguments.report.sectionOrder ) {
			if ( !arguments.report.sections.keyExists( sectionName ) ) {
				continue;
			}

			var section = arguments.report.sections[ sectionName ]

			// Skip error and warning sections
			if ( section.status == "error" || section.status == "warning" ) {
				continue;
			}

			// Skip sections with no meaningful data
			if ( !hasMeaningfulData( sectionName, section.data ?: {} ) ) {
				continue;
			}

			print.boldCyanLine( "#getSectionTitle( sectionName )#" )
			printSectionData( sectionName, section.data ?: {}, arguments.verbose )
			print.line()
		}
	}

	private boolean function hasMeaningfulData(
		required string sectionName,
		required struct data
	){
		switch ( arguments.sectionName ) {
			case "project":
				return true // Always show project section
			case "server":
				return arguments.data.keyExists( "available" ) && arguments.data.available
			case "deps":
				var prodCount = arguments.data.productionCount ?: 0
				var devCount = arguments.data.developmentCount ?: 0
				return prodCount > 0 || devCount > 0
			case "modules":
				return ( arguments.data.count ?: 0 ) > 0
			case "routes":
				return ( arguments.data.count ?: 0 ) > 0
			case "scheduler":
				return ( arguments.data.taskCount ?: 0 ) > 0
			case "env":
				return ( arguments.data.present ?: false )
			case "cachebox":
			case "wirebox":
			case "logbox":
			case "config":
				return arguments.data.keyExists( "configured" ) && arguments.data.configured
			default:
				return arguments.data.count() > 0
		}
	}

	private void function printSectionData(
		required string sectionName,
		required struct data,
		boolean verbose = false
	){
		switch ( arguments.sectionName ) {
			case "project":
				print.table(
					headerNames = [ "Property", "Value" ],
					data        = [
						[ "Name", arguments.data.name ?: "unknown" ],
						[ "Version", arguments.data.version ?: "unknown" ],
						[ "Language", arguments.data.language ?: "unknown" ],
						[ "Template", arguments.data.templateType ?: "unknown" ],
						[ "Root", arguments.data.root ?: "" ]
					]
				)
				break

			case "server":
				if ( !( arguments.data.available ?: true ) && !arguments.data.count() ) {
					print.yellowLine( "  Server info unavailable" )
					break
				}
				print.table(
					headerNames = [ "Property", "Value" ],
					data        = [
						[ "Status", arguments.data.status ?: "unknown" ],
						[ "Name", arguments.data.name ?: "" ],
						[ "Engine", arguments.data.engine ?: "" ],
						[ "Host", arguments.data.host ?: "" ],
						[ "Port", arguments.data.port ?: "" ]
					]
				)
				break

			case "deps":
				print.table(
					headerNames = [ "Group", "Count" ],
					data        = [
						[ "Production", arguments.data.productionCount ?: 0 ],
						[ "Development", arguments.data.developmentCount ?: 0 ]
					]
				)
				if ( ( arguments.data.core.coldbox ?: "" ).len() || ( arguments.data.core.testbox ?: "" ).len() ) {
					var coldboxVersion = arguments.data.core.coldbox ?: "n/a"
					var testboxVersion = arguments.data.core.testbox ?: "n/a"
					print.dimLine( "  Core: coldbox #coldboxVersion#, testbox #testboxVersion#" )
				}
				if ( arguments.verbose ) {
					print.dimLine( "  Production dependencies:" )
					var productionDeps = arguments.data.production ?: {}
					for ( var key in productionDeps ) {
						print.line( "    - #key#: #productionDeps[ key ]#" )
					}
					print.dimLine( "  Development dependencies:" )
					var developmentDeps = arguments.data.development ?: {}
					for ( var key in developmentDeps ) {
						print.line( "    - #key#: #developmentDeps[ key ]#" )
					}
				}
				break

			case "modules":
				if ( !( arguments.data.count ?: 0 ) || !arguments.data.keyExists( "modules" ) ) {
					print.yellowLine( "  No custom modules found in modules/ or modules_app/" )
			} else {
				var moduleRows = []
				for ( var mod in arguments.data.modules ) {
					moduleRows.append( [ mod.name, mod.root, mod.hasRouter ? "yes" : "no", mod.hasScheduler ? "yes" : "no" ] )
				}
				print.table(
					headerNames = [ "Module", "Root", "Router", "Scheduler" ],
					data        = moduleRows
				)
			}
				print.table(
					headerNames = [ "Metric", "Value" ],
					data        = [
						[ "Total", arguments.data.count ?: 0 ],
						[ "App", arguments.data.appCount ?: 0 ],
						[ "Modules", arguments.data.moduleCount ?: 0 ],
						[ "Parse", arguments.data.parseMode ?: "heuristic" ]
					]
				)
				if ( arguments.verbose && ( arguments.data.entries ?: [] ).len() ) {
					var entries = arguments.data.entries ?: []
					for ( var entry in entries ) {
						print.line( "  [#entry.scope#] #entry.type# @ #entry.file#:#entry.line#" )
					}
				}
				break

			case "scheduler":
				print.table(
					headerNames = [ "Metric", "Value" ],
					data        = [
						[ "Files", ( arguments.data.files ?: [] ).len() ],
						[ "Tasks", arguments.data.taskCount ?: 0 ],
						[ "Parse", arguments.data.parseMode ?: "heuristic" ]
					]
				)
				if ( arguments.verbose && ( arguments.data.tasks ?: [] ).len() ) {
					var tasks = arguments.data.tasks ?: []
					for ( var task in tasks ) {
						print.line( "  [#task.scope#] #task.task# @ #task.file#:#task.line#" )
					}
				}
				break

			case "env":
				if ( !( arguments.data.present ?: false ) ) {
					print.yellowLine( "  .env not found" )
					break
				}
				print.table(
					headerNames = [ "Property", "Value" ],
					data        = [
						[ ".env", "present" ],
						[ "Keys", arguments.data.count ?: 0 ]
					]
				)
				print.line( "  Keys (values hidden): #arrayToList( arguments.data.keys ?: [], ", " )#" )
				break

			case "cachebox":
			case "wirebox":
			case "logbox":
			case "config":
				var rows = []
				for ( var key in arguments.data ) {
					var value = arguments.data[ key ]
					rows.append( [ key, isSimpleValue( value ) ? value : serializeJSON( value ) ] )
				}
				print.table(
					headerNames = [ "Property", "Value" ],
					data        = rows
				)
				break

			default:
				print.line( serializeJSON( arguments.data, true ) )
		}
	}

	private string function getSectionTitle( required string name ){
		var titles = {
			"project"   : "📦 Project",
			"server"    : "🖥️ Server",
			"deps"      : "📚 Dependencies",
			"modules"   : "🧩 Custom Modules",
			"routes"    : "🛣️ Routes",
			"scheduler" : "⏰ Scheduler",
			"env"       : "🌿 Environment",
			"cachebox"  : "🗄️ CacheBox",
			"wirebox"   : "🔌 WireBox",
			"logbox"    : "🪵 LogBox",
			"config"    : "⚙️ ColdBox Config"
		}
		return titles[ arguments.name ] ?: arguments.name
	}

	private void function applyExitSemantics(
		required struct report,
		string failOn = ""
	){
		var mode = lCase( trim( arguments.failOn ) )
		if ( !mode.len() ) {
			return
		}

		if ( mode == "warnings" ) {
			if ( arguments.report.warnings.len() || arguments.report.errors.len() ) {
				setExitCode( 1 )
			}
			return
		}

		if ( mode == "errors" ) {
			if ( arguments.report.errors.len() ) {
				setExitCode( 1 )
			}
			return
		}
	}

}
