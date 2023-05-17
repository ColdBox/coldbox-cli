/**
 * Base Command Handler
 */
component  {

	// DI
	property name="utility"  	inject="utility@coldbox-cli";
	property name="settings" 	inject="box:modulesettings:coldbox-cli";
	property name="config" 		inject="box:moduleconfig:coldbox-cli";

	function init(){
		return this;
	}

	function printInfo( required message ){
		print.green1onDodgerBlue2( " INFO  " )
			.line( " #arguments.message#" )
			.line();
	}

	function printError( required message ){
		print.whiteOnRed2( " ERROR " )
			.line( " #arguments.message#" )
			.line();
	}

	function printWarn( required message ){
		print.blackOnWheat1( " WARN  " )
			.line( " #arguments.message#" )
			.line();
	}

	function printSuccess( required message ){
		print.blackOnSeaGreen2( " SUCCESS  " )
			.line( " #arguments.message#" )
			.line();
	}

}
