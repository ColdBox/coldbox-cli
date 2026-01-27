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

	function init(){
		return this;
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
			.line();
	}

	function printError( required message ){
		variables.print
			.whiteOnRed2( " ERROR " )
			.line( " #arguments.message#" )
			.line();
	}

	function printWarn( required message ){
		variables.print
			.blackOnWheat1( " WARN  " )
			.line( " #arguments.message#" )
			.line();
	}

	function printSuccess( required message ){
		variables.print
			.blackOnSeaGreen2( " SUCCESS  " )
			.line( " #arguments.message#" )
			.line();
	}

	function printHelp( required message ){
		variables.print
			.blackOnLightSkyBlue1( " HELP  " )
			.line( " #arguments.message#" )
			.line();
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
	 */
	function showColdBoxBanner(){
		var lines = [
			" ██████╗  ██████╗  ██╗      ██████╗  ██████╗   ██████╗  ██╗  ██╗",
			"██╔════╝ ██╔═══██╗ ██║      ██╔══██╗ ██╔══██╗ ██╔═══██╗ ╚██╗██╔╝",
			"██║      ██║   ██║ ██║      ██║  ██║ ██████╔╝ ██║   ██║  ╚███╔╝ ",
			"██║      ██║   ██║ ██║      ██║  ██║ ██╔══██╗ ██║   ██║  ██╔██╗ ",
			"╚██████╗ ╚██████╔╝ ███████╗ ██████╔╝ ██████╔╝ ╚██████╔╝ ██╔╝ ██╗",
			" ╚═════╝  ╚═════╝  ╚══════╝ ╚═════╝  ╚═════╝   ╚═════╝  ╚═╝  ╚═╝"
		]

		var gradients = {
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
			]
		}

		// Randomly select a gradient theme
		var themeNames = structKeyArray( gradients )
		var themeName  = themeNames[ randRange( 1, arrayLen( themeNames ) ) ]
		var gradient   = gradients[ themeName ]

		variables.print.line()

		for ( var i = 1; i <= arrayLen( lines ); i++ ) {
			variables.print.line( lines[ i ], gradient[ i ] )
		}

		variables.print.line()
	}

}
