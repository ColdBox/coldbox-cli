/**
 * Create a new virtual entity service model in an existing ColdBox application.  Make sure you are running this command in the root
 * of your app for it to find the correct folder.
 * .
 * {code:bash}
 * coldbox create orm-virtual-service Contact --open
 * {code}
 *
 **/
component extends="coldbox-cli.models.BaseCommand" {

	/**
	 * @entityName     The name of the entity this virtual service will be bound to
	 * @directory      The base directory to create your model in and creates the directory if it does not exist.
	 * @queryCaching   Activate query caching
	 * @eventHandling  Enable the virtual entity service to emit events
	 * @cacheRegion    The cache region the virtual entity service methods will use
	 * @tests          Generate the unit test BDD component
	 * @testsDirectory Your unit tests directory. Only used if tests is true
	 * @open           Open the file once generated
	 * @force          Force overwrite of existing files
	 * @boxlang       Is this a boxlang project?
	 **/
	function run(
		required entityName,
		directory             = "models",
		boolean queryCaching  = false,
		boolean eventHandling = true,
		cacheRegion           = "",
		boolean tests         = true,
		testsDirectory        = "tests/specs/unit",
		boolean open          = false,
		boolean force         = false,
		boolean boxlang = isBoxLangProject( getCWD() )
	){
		// non-canonical path
		var nonCanonicalDirectory = arguments.directory;
		// This will make each directory canonical and absolute
		arguments.directory       = resolvePath( arguments.directory );
		arguments.testsDirectory  = resolvePath( arguments.testsDirectory );

		// Validate directory
		if ( !directoryExists( arguments.directory ) ) {
			directoryCreate( arguments.directory );
		}

		// Read in Template
		var modelContent     = fileRead( "#variables.settings.templatesPath#/orm/VirtualEntityService.txt" );
		var modelTestContent = fileRead( "#variables.settings.templatesPath#/testing/ModelBDDContent.txt" );

		// Query cache Region
		if ( !len( arguments.cacheRegion ) ) {
			arguments.cacheRegion = "ormservice.#arguments.entityName#";
		}

		// Basic replacements
		modelContent = replaceNoCase(
			modelContent,
			"|entityName|",
			arguments.entityname,
			"all"
		);
		modelContent = replaceNoCase(
			modelContent,
			"|QueryCaching|",
			arguments.QueryCaching,
			"all"
		);
		modelContent = replaceNoCase(
			modelContent,
			"|cacheRegion|",
			arguments.cacheRegion,
			"all"
		);
		modelContent = replaceNoCase(
			modelContent,
			"|eventHandling|",
			arguments.eventHandling,
			"all"
		);
		if ( arguments.boxlang ) {
			modelContent = toBoxLangClass( modelContent );
		}

		modelTestContent = replaceNoCase(
			modelTestContent,
			"|modelName|",
			"#nonCanonicalDirectory#.#arguments.entityName#",
			"all"
		);
		modelTestContent = replaceNoCase(
			modelTestContent,
			"|TestCases|",
			"",
			"all"
		);
		if ( arguments.boxlang ) {
			modelTestContent = toBoxLangClass( modelTestContent );
		}

		// Write out the model
		var modelPath = "#arguments.directory#/#arguments.entityName#Service.#arguments.boxlang ? "bx" : "cfc"#";
		// Create dir if it doesn't exist
		directoryCreate(
			getDirectoryFromPath( modelPath ),
			true,
			true
		);

		// Confirm it
		if (
			fileExists( modelPath ) && !arguments.force && !confirm(
				"The file '#getFileFromPath( modelPath )#' already exists, overwrite it (y/n)?"
			)
		) {
			printWarn( "Exiting..." );
			return;
		}

		file action="write" file="#modelPath#" mode="777" output="#modelContent#";
		printInfo( "Created Virtual Service [#modelPath#]" );

		if ( arguments.tests ) {
			var testPath = "#arguments.TestsDirectory#/#arguments.entityName#ServiceTest.#arguments.boxlang ? "bx" : "cfc"#";
			// Create dir if it doesn't exist
			directoryCreate(
				getDirectoryFromPath( testPath ),
				true,
				true
			);
			// Create the tests
			file action="write" file="#testPath#" mode="777" output="#modelTestContent#";
			// open file
			if ( arguments.open ) {
				openPath( testPath );
			}
			printInfo( "Created #testPath#" );
		}

		// Open file?
		if ( arguments.open ) {
			openPath( modelPath );
		}
	}

}
