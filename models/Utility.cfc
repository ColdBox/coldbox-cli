component singleton {

	// DI
	property name="moduleService" inject="ModuleService";
	property name="wirebox"       inject="wirebox";
	property name="print"         inject="PrintBuffer";
	property name="settings"      inject="box:modulesettings:coldbox-cli";
	property name="config"        inject="box:moduleConfig:coldbox-cli";

	this.BREAK = chr( 13 ) & chr( 10 );
	this.TAB   = chr( 9 );

	/**
	 * Get the ColdBox CLI module version
	 *
	 * @return The version string from box.json
	 */
	function getColdboxCliVersion(){
		var boxJsonPath = variables.config.path & "/box.json"

		if ( fileExists( boxJsonPath ) ) {
			var boxJson = deserializeJSON( fileRead( boxJsonPath ) )
			return boxJson.version ?: "1.0.0"
		}

		return "1.0.0"
	}

	/**
	 * Get the templates path for the ColdBox CLI module
	 *
	 * @return The absolute path to the templates directory
	 */
	function getTemplatesPath(){
		return variables.settings.templatesPath
	}

	/**
	 * Verify that the TestBox module is installed
	 * else install it
	 */
	function ensureTestBoxModule(){
		if ( !isTestBoxModuleInstalled() ) {
			variables.print
				.redLine( "TestBox-CLI module not installed. Installing it for you, please wait..." )
				.line()
				.toConsole();
			variables.wirebox
				.getInstance(
					name         : "CommandDSL",
					initArguments: { name : "install testbox-cli" }
				)
				.run();
		}
	}

	/**
	 * Verify that the CommandBox Migrations module is installed
	 * else install it
	 */
	function ensureMigrationsModule(){
		if ( !isMigrationsModuleInstalled() ) {
			variables.print
				.redLine( "‼️ CommandBox-Migrations module not installed. Installing it for you, please wait..." )
				.line()
				.toConsole();
			variables.wirebox
				.getInstance(
					name         : "CommandDSL",
					initArguments: { name : "install commandbox-migrations" }
				)
				.run();
		}
	}

	/**
	 * Is TestBox module installed
	 */
	boolean function isTestBoxModuleInstalled(){
		return variables.moduleService
			.getModuleRegistry()
			.keyArray()
			.findNoCase( "testbox-cli" ) > 0 ? true : false;
	}

	/**
	 * Is CommandBox Migrations module installed
	 */
	boolean function isMigrationsModuleInstalled(){
		return variables.moduleService
			.getModuleRegistry()
			.keyArray()
			.findNoCase( "commandbox-migrations" ) > 0 ? true : false;
	}

	/**
	 * Convert a plural word to a singular word
	 *
	 * @word The word to convert
	 */
	function singularize( required word ){
		var result = arguments.word;

		if ( result.endsWith( "s" ) ) {
			if ( result.endsWith( "ss" ) || result.endsWith( "us" ) ) {
				result &= "es";
			} else if ( result.endsWith( "is" ) ) {
				result = left( result, len( result ) - 2 ) & "is";
			} else if ( result.endsWith( "es" ) ) {
				if ( len( result ) > 3 && arrayFindNoCase( [ "sh", "ch" ], right( result, 2 ) ) ) {
					result = left( result, len( result ) - 2 );
				} else {
					result = left( result, len( result ) - 1 );
				}
			} else {
				result = left( result, len( result ) - 1 );
			}
		}

		return result;
	}

	/**
	 * Convert a singular word to a plural word
	 *
	 * @word The word to convert
	 */
	function pluralize( required word ){
		var result = arguments.word;

		if ( result.endsWith( "s" ) ) {
			if ( result.endsWith( "ss" ) || result.endsWith( "us" ) ) {
				result &= "es";
			} else {
				result &= "s";
			}
		} else if ( result.endsWith( "y" ) ) {
			if (
				arrayFindNoCase(
					[ "ay", "ey", "iy", "oy", "uy" ],
					right( result, 2 )
				)
			) {
				result &= "s";
			} else {
				result = left( result, len( result ) - 1 ) & "ies";
			}
		} else if (
			arrayFindNoCase(
				[ "x", "s", "z", "ch", "sh" ],
				right( result, 1 )
			)
		) {
			result &= "es";
		} else {
			result &= "s";
		}

		return result;
	}

	/**
	 * Camel case a string using lower case for the first letter
	 *
	 * @target      The string to camel case
	 * @capitalized Whether or not to capitalize the first letter, default is false
	 */
	function camelCase(
		required target,
		boolean capitalized = false
	){
		var results = arguments.capitalized ? arguments.target.left( 1 ).ucase() : arguments.target.left( 1 ).lCase();

		if ( arguments.target.len() > 1 ) {
			results &= arguments.target.right( -1 );
		}

		return results;
	}

	/**
	 * Camel case a string using upper case for the first letter
	 */
	function camelCaseUpper( required target ){
		return camelCase( arguments.target, true );
	}

	/**
	 * Detect the ColdBox template type (flat or modern) based on project structure
	 *
	 * @directory The project directory
	 *
	 * @return string "modern" if app/ and public/ exist, "flat" otherwise
	 */
	function detectTemplateType( required string directory ){
		var hasAppFolder    = directoryExists( "#arguments.directory#/app" )
		var hasPublicFolder = directoryExists( "#arguments.directory#/public" )

		return ( hasAppFolder && hasPublicFolder ) ? "modern" : "flat"
	}

}
