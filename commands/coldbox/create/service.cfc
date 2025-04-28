/**
 * Create a new service CFC in an existing ColdBox application.
 * Make sure you are running this command in the root of your app for it to find the correct folder.
 * You can optionally create unit tests for your new service at the same time.
 * By default, your new service will be created in `/models` but you can override that with the `directory` param.
 * .
 * {code:bash}
 * coldbox create service UserService --open
 * {code}
 * .
 * {code:bash}
 * coldbox create service name=UserService methods="list,save,update" --open
 * {code}
 *
 **/
component extends="coldbox-cli.models.BaseCommand" {

	/**
	 * @name                 Name of the service to create without the .cfc. For packages, specify name as 'myPackage/MyModel'
	 * @methods              A comma-delimited list of method stubs to generate for you
	 * @tests                Generate the unit test BDD component
	 * @testsDirectory       Your unit tests directory. Only used if tests is true
	 * @directory            The base directory to create your service in and creates the directory if it does not exist
	 * @description          The service hint description
	 * @open                 Open the file once generated
	 * @force                Force overwrite of existing files
	 * @componentAnnotations Annotations to add to the component
	 * @initContent          Custom content to add to the init method
	 * @boxlang             Is this a boxlang project?
	 **/
	function run(
		required name,
		methods                     = "",
		boolean tests               = true,
		testsDirectory              = "tests/specs/unit",
		directory                   = "models",
		description                 = "I am a new service",
		boolean open                = false,
		boolean force               = false,
		string componentAnnotations = "",
		string initContent          = "",
		boolean boxlang             = isBoxLangProject( getCWD() )
	){
		// Prepare arguments
		var modelTestPath = arguments.directory;
		arguments.name    = variables.utility.camelCaseUpper( arguments.name );

		// This will make each directory canonical and absolute
		arguments.directory      = resolvePath( arguments.directory );
		arguments.testsDirectory = resolvePath( arguments.testsDirectory );

		// Validate directory
		if ( !directoryExists( arguments.directory ) ) {
			directoryCreate( arguments.directory );
		}
		// Validate persistence
		if ( !len( arguments.name ) ) {
			error( "Cannot scaffold a service with an empty name." );
		}

		// Allow dot-delimited paths
		arguments.name = replace( arguments.name, ".", "/", "all" );

		// Read in Template
		var modelContent           = fileRead( "#variables.settings.templatesPath#/ServiceContent.txt" );
		var modelMethodContent     = fileRead( "#variables.settings.templatesPath#/ModelMethodContent.txt" );
		var modelTestContent       = fileRead( "#variables.settings.templatesPath#/testing/ModelBDDContent.txt" );
		var modelTestMethodContent = fileRead( "#variables.settings.templatesPath#/testing/ModelBDDMethodContent.txt" );

		// Basic replacements
		modelContent = replaceNoCase(
			modelContent,
			"|componentAnnotations|",
			arguments.componentAnnotations,
			"all"
		);
		modelContent = replaceNoCase(
			modelContent,
			"|modelName|",
			listLast( arguments.name, "/\" ),
			"all"
		);
		modelContent = replaceNoCase(
			modelContent,
			"|modelDescription|",
			arguments.description,
			"all"
		);
		modelContent = replaceNoCase(
			modelContent,
			"|initContent|",
			arguments.initContent,
			"all"
		);
		if ( arguments.boxlang ) {
			modelContent = toBoxLangClass( modelContent );
		}

		modelTestContent = replaceNoCase(
			modelTestContent,
			"|modelName|",
			listChangeDelims( arguments.name, ".", "/\" ),
			"all"
		);
		modelTestContent = replaceNoCase(
			modelTestContent,
			"|modelPath|",
			listChangeDelims( modelTestPath, ".", "/\" ) & "." & listChangeDelims( arguments.name, ".", "/\" ),
			"all"
		);
		if ( arguments.boxlang ) {
			modelTestContent = toBoxLangClass( modelTestContent );
		}


		// Handle Model Methods
		if ( len( arguments.methods ) ) {
			var allMethods    = "";
			var allTestsCases = "";
			var methodContent = "";

			// Loop Over methods to generate them
			for ( var thisMethod in listToArray( arguments.methods ) ) {
				if ( thisMethod == "init" ) {
					continue;
				}

				thisMethod = trim( thisMethod );
				allMethods = allMethods & replaceNoCase(
					modelMethodContent,
					"|method|",
					thisMethod,
					"all"
				) & cr & cr;

				printInfo( "Generated Method: #thisMethod#()" );

				// Are we creating tests cases on methods
				if ( arguments.tests ) {
					var thisTestCase = replaceNoCase(
						modelTestMethodContent,
						"|method|",
						thisMethod,
						"all"
					);
					allTestsCases &= thisTestCase & CR & CR;
				}
			}

			// final replacement
			modelContent = replaceNoCase(
				modelContent,
				"|methods|",
				allMethods,
				"all"
			);
			modelTestContent = replaceNoCase(
				modelTestContent,
				"|TestCases|",
				allTestsCases,
				"all"
			);
		} else {
			modelContent     = replaceNoCase( modelContent, "|methods|", "", "all" );
			modelTestContent = replaceNoCase(
				modelTestContent,
				"|TestCases|",
				"",
				"all"
			);
		}

		// Write out the model
		var modelPath = "#arguments.directory#/#arguments.name#.#arguments.boxlang ? "bx" : "cfc"#";
		// Create dir if it doesn't exist
		directoryCreate(
			getDirectoryFromPath( modelPath ),
			true,
			true
		);

		// Prompt for override
		if (
			fileExists( modelPath ) && !arguments.force && !confirm(
				"The file '#getFileFromPath( modelPath )#' already exists, overwrite it (y/n)?"
			)
		) {
			printWarn( "Exiting..." );
			return;
		}

		// Write out the model
		fileWrite( modelPath, trim( modelContent ) );
		printInfo( "Created Service [#modelPath#]" );

		// Generate Tests
		if ( arguments.tests ) {
			command( "coldbox create model-test" )
				.params(
					path   : arguments.name,
					force  : arguments.force,
					open   : arguments.open,
					methods: arguments.methods,
					boxlang: arguments.boxlang
				)
				.run();
		}

		// Open file?
		if ( arguments.open ) {
			openPath( modelPath );
		}
	}

}
