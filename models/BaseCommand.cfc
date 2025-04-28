/**
 * Base Command Handler
 */
component accessors="true" {

	// DI
	property name="utility"  inject="utility@coldbox-cli";
	property name="settings" inject="box:modulesettings:coldbox-cli";
	property name="config"   inject="box:moduleconfig:coldbox-cli";

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

	function toBoxLangClass( required content ){
		return replaceNoCase(
			arguments.content,
			"component ",
			"class",
			"all"
		);
	}

}
