/**
 * Create a new module in an existing ColdBox application.  Make sure you are running this command in the root
 * of your app for it to find the correct folder.
 * .
 * {code:bash}
 * coldbox create module myModule
 * {code}
 *
 **/
component extends="coldbox-cli.models.BaseCommand" {

	/**
	 * @name           Name of the module to create.
	 * @author         Whoever wrote this module
	 * @authorURL      The author's URL
	 * @description    The description for this module
	 * @version        The semantic version number: major.minor.patch
	 * @cfmapping      A CF app mapping to create that points to the root of this module
	 * @modelNamespace The namespace to use when mapping the models in this module
	 * @dependencies   The list of dependencies for this module
	 * @directory      The base directory to create your model in and creates the directory if it does not exist.
	 * @views          Create the views folder on creatin or remove it. Defaults to true
	 * @boxlang 	 If this is a boxlang project, defaults to true
	 **/
	function run(
		required name,
		author          = "",
		authorURL       = "",
		description     = "",
		version         = "1.0.0",
		cfmapping       = "",
		modelNamespace  = arguments.name,
		dependencies    = "",
		directory       = "modules_app",
		boolean views   = true,
		boolean boxlang = isBoxLangProject( getCWD() )
	){
		// This will make each directory canonical and absolute
		arguments.directory = resolvePath( arguments.directory );

		// Validate directory
		if ( !directoryExists( arguments.directory ) ) {
			directoryCreate( arguments.directory );
		}
		var modulePrefix = arguments.boxlang ? "bx" : "cfml";

		// Read in Module Config
		var moduleConfig = fileRead( "#variables.settings.templatesPath#/modules/#modulePrefix#/ModuleConfig.cfc" );

		// Start Generation Replacing
		moduleConfig = replaceNoCase(
			moduleConfig,
			"@title@",
			arguments.name,
			"all"
		);
		moduleConfig = replaceNoCase(
			moduleConfig,
			"@author@",
			arguments.author,
			"all"
		);
		moduleConfig = replaceNoCase(
			moduleConfig,
			"@authorURL@",
			arguments.authorURL,
			"all"
		);
		moduleConfig = replaceNoCase(
			moduleConfig,
			"@description@",
			arguments.description,
			"all"
		);
		moduleConfig = replaceNoCase(
			moduleConfig,
			"@version@",
			arguments.version,
			"all"
		);
		moduleConfig = replaceNoCase(
			moduleConfig,
			"@cfmapping@",
			arguments.cfmapping,
			"all"
		);
		moduleConfig = replaceNoCase(
			moduleConfig,
			"@modelNamespace@",
			arguments.modelNamespace,
			"all"
		);
		moduleConfig = replaceNoCase(
			moduleConfig,
			"@dependencies@",
			serializeJSON( listToArray( arguments.dependencies ) ),
			"all"
		);

		// Confirm it
		if (
			directoryExists( arguments.directory & "/#arguments.name#" ) &&
			!confirm( "The module already exists, overwrite it (y/n)?" )
		) {
			printWarn( "Exiting..." );
			return;
		}

		// Copy module template
		directoryCopy(
			"#variables.settings.templatesPath#/modules/#modulePrefix#",
			arguments.directory & "/#arguments.name#",
			true
		);

		// Remove or keep Views?
		if ( !arguments.views ) {
			directoryDelete(
				arguments.directory & "/#arguments.name#/views",
				true
			);
		}

		// Write Out the New Config
		fileWrite(
			arguments.directory & "/#arguments.name#/ModuleConfig.cfc",
			moduleConfig
		);

		// Output
		printInfo( "Created Module (#arguments.name#) -> [#arguments.directory#]" );
		directoryList(
			arguments.directory & "/#arguments.name#",
			true,
			"path",
			( path ) => !reFindNoCase( "\.DS_Store", arguments.path )
		).each( ( item ) => print.greenLine( "  => " & item.replace( directory, "" ) ) );
	}

}
