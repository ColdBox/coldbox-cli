/**
 * Base Command Handler
 */
component accessors="true" {

	// DI
	property name="utility"        inject="utility@coldbox-cli";
	property name="settings"       inject="box:modulesettings:coldbox-cli";
	property name="config"         inject="box:moduleconfig:coldbox-cli";
	property name="serverService"  inject="serverService";
	property name="packageService" inject="PackageService";

	/**
	 * Initialize the BaseCommand
	 */
	function init(){
		return this;
	}

	/**
	 * Detects the application layout and returns the appropriate path prefix.
	 * In a modern layout (app/ and public/ directories exist), returns "app/".
	 * In a flat layout, returns "".
	 *
	 * @cwd The current working directory
	 *
	 * @return string "app/" for modern layout, "" for flat layout
	 */
	function getAppPrefix( required cwd ){
		return variables.utility.detectTemplateType( cwd ) == "modern" ? "app/" : "";
	}

	/**
	 * Detects the application layout and returns the appropriate modules directory path.
	 * In a modern layout (or BoxLang project), modules live under lib/modules.
	 * In a flat layout, modules live under modules.
	 *
	 * @cwd The current working directory
	 *
	 * @return string "lib/modules" for modern/BoxLang layout, "modules" for flat layout
	 */
	function getModulesPrefix( required cwd ){
		var isModern = variables.utility.detectTemplateType( cwd ) == "modern" || isBoxLangProject( cwd );
		return isModern ? "lib/modules" : "modules";
	}

	/**
	 * Resolves the base URL (host:port) of the local server for the given directory.
	 * Resolution order:
	 *   1. CommandBox server.json discovery (getServerInfoByDiscovery)
	 *   2. miniserver.json in the project directory
	 *   3. Fallback: localhost:8080
	 *
	 * @directory The project directory to resolve the server for
	 *
	 * @return string  e.g. "localhost:8888" or "localhost:8080"
	 */
	function resolveServerBaseUrl( required string directory ){
		// 1. Try CommandBox server.json discovery
		var serverInfo = variables.serverService.getServerInfoByDiscovery(
			serverConfigFile = arguments.directory & "/server.json"
		);
		if ( structCount( serverInfo ) && serverInfo.keyExists( "host" ) ) {
			return "#serverInfo.host#:#serverInfo.port#";
		}

		// 2. Try miniserver.json in the project directory
		var miniServerFile = arguments.directory & "/miniserver.json";
		if ( fileExists( miniServerFile ) ) {
			try {
				var miniConfig = deserializeJSON( fileRead( miniServerFile ) );
				var miniHost   = miniConfig.keyExists( "host" ) ? miniConfig.host : "localhost";
				var miniPort   = miniConfig.keyExists( "port" ) ? miniConfig.port : 8080;
				// Normalize bind-all address to localhost
				if ( miniHost == "0.0.0.0" ) miniHost = "localhost";
				return "#miniHost#:#miniPort#";
			} catch ( any e ) {
				// Ignore parse errors and fall through to default
			}
		}

		// 3. Fallback
		return "localhost:8080";
	}

	/**
	 * Determines if we are running on a BoxLang server
	 * or using the BoxLang runner.
	 *
	 * @cwd The current working directory
	 *
	 * @return boolean
	 */
	private function isBoxLangProject( required cwd ){
		// Detect if it's a BoxLang server first.
		var serverInfo = variables.serverService.resolveServerDetails( {} ).serverInfo;
		if ( serverInfo.cfengine.findNoCase( "boxlang" ) ) {
			return true;
		}

		// Detect if you have the BoxLang runner set.
		var boxOptions = variables.packageService.readPackageDescriptor( arguments.cwd );
		if (
			boxOptions.testbox.keyExists( "runner" )
			&& isSimpleValue( boxOptions.testbox.runner )
			&& boxOptions.testbox.runner == "boxlang"
		) {
			return true;
		}

		// Language mode
		if ( boxOptions.keyExists( "language" ) && boxOptions.language == "boxlang" ) {
			return true;
		}

		// We don't know.
		return false;
	}

	function printInfo( required message ){
		variables.print
			.green1onDodgerBlue2( " INFO  " )
			.line( " #arguments.message#" )
			.line()
			.toConsole()
	}

	function printError( required message ){
		variables.print
			.whiteOnRed2( " ERROR " )
			.line( " #arguments.message#" )
			.line()
			.toConsole()
	}

	function printWarn( required message ){
		variables.print
			.blackOnWheat1( " WARN  " )
			.line( " #arguments.message#" )
			.line()
			.toConsole()
	}

	function printSuccess( required message ){
		variables.print
			.blackOnSeaGreen2( " SUCCESS  " )
			.line( " #arguments.message#" )
			.line()
			.toConsole()
	}

	function printTip( required string message ){
		variables.print
			.blackOnAquamarine2( "  TIP  " )
			.line( " #arguments.message#" )
			.line()
			.toConsole()
	}

	function printHelp( required message ){
		variables.print
			.blackOnLightSkyBlue1( " HELP  " )
			.line( " #arguments.message#" )
			.line()
			.toConsole()
	}

	function toBoxLangClass( required content ){
		return reReplaceNoCase(
			arguments.content,
			"component(\s|\n)?",
			"class #chr( 13 )#",
			"one"
		);
	}

	/**
	 * Display the ColdBox ASCII art banner with random gradient colors
	 *
	 * @subTitle Optional subtitle to display below the banner
	 * @theme Optional gradient theme name (e.g., "Ocean", "Fire", "Sunset", "Purple", "Mint", "Gray")
	 */
	function showColdBoxBanner(
		string subTitle = "",
		string theme    = ""
	){
		var lines = [
			" ██████╗  ██████╗  ██╗      ██████╗  ██████╗   ██████╗  ██╗  ██╗",
			"██╔════╝ ██╔═══██╗ ██║      ██╔══██╗ ██╔══██╗ ██╔═══██╗ ╚██╗██╔╝",
			"██║      ██║   ██║ ██║      ██║  ██║ ██████╔╝ ██║   ██║  ╚███╔╝ ",
			"██║      ██║   ██║ ██║      ██║  ██║ ██╔══██╗ ██║   ██║  ██╔██╗ ",
			"╚██████╗ ╚██████╔╝ ███████╗ ██████╔╝ ██████╔╝ ╚██████╔╝ ██╔╝ ██╗",
			" ╚═════╝  ╚═════╝  ╚══════╝ ╚═════╝  ╚═════╝   ╚═════╝  ╚═╝  ╚═╝"
		]

		var themes = {
			"Ocean" : [
				"color81",
				"color75",
				"color69",
				"color63",
				"color57",
				"color21"
			],
			"Fire" : [
				"color196",
				"color160",
				"color124",
				"color88",
				"color52",
				"color88"
			],
			"Sunset" : [
				"color214",
				"color208",
				"color202",
				"color196",
				"color160",
				"color124"
			],
			"Purple" : [
				"color213",
				"color177",
				"color141",
				"color105",
				"color69",
				"color39"
			],
			"Mint" : [
				"color158",
				"color122",
				"color86",
				"color50",
				"color44",
				"color38"
			],
			"Gray" : [
				"color250",
				"color248",
				"color245",
				"color243",
				"color240",
				"color238"
			],
			"Forest" : [
				"color154",
				"color148",
				"color142",
				"color106",
				"color70",
				"color34"
			],
			"Gold" : [
				"color226",
				"color220",
				"color214",
				"color208",
				"color172",
				"color136"
			]
		}

		// Randomly select a gradient theme if none provided
		if ( arguments.theme == "" ) {
			var themeNames = structKeyArray( themes )
			var themeName  = themeNames[ randRange( 1, arrayLen( themeNames ) ) ]
		} else {
			var themeName = arguments.theme
		}
		var gradient = themes[ themeName ]

		variables.print.line()

		for ( var i = 1; i <= arrayLen( lines ); i++ ) {
			variables.print.line( lines[ i ], gradient[ i ] )
		}

		// Add subtitle block if provided
		if ( len( arguments.subTitle ) ) {
			var blockWidth   = 48
			var contentWidth = blockWidth - 4 // Subtract 4 for the ██ borders (2 chars each side)
			var padding      = contentWidth - len( arguments.subTitle )
			var leftPad      = int( padding / 2 )
			var rightPad     = padding - leftPad
			var indent       = repeatString( " ", 8 )

			variables.print
				.line(
					indent & repeatString( "▄", blockWidth ),
					gradient.last()
				)
				.line(
					indent & "██" &
					repeatString( " ", leftPad ) &
					arguments.subTitle &
					repeatString( " ", rightPad ) &
					"██",
					"white"
				)
				.line(
					indent & repeatString( "▀", blockWidth ),
					gradient.last()
				)
		}

		variables.print.line().toConsole()
	}

}
