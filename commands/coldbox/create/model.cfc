/**
 * Create a new model CFC in an existing ColdBox application.  Make sure you are running this command in the root
 * of your app for it to find the correct folder.  You can optionally create unit tests for your new model at the same time.
 * By default, your new model will be created in `/models` but you can override that with the directory param.
 * Once you create a model you can add a mapping for it in your WireBox binder, or use ColdBox's default scan location and
 * just reference it with getModel( 'modelName' ).
 * .
 * {code:bash}
 * coldbox create model myModel --open
 * {code}
 * .
 * {code:bash}
 * coldbox create model name=User properties=fname,lname,email --accessors --open
 * {code}
 *
 **/
component extends="coldbox-cli.models.BaseCommand" {

	/**
	 * Constructor
	 */
	function init(){
		// valid persistences
		variables.validPersistences   = "Transient,Singleton";
		variables.migrationsDirectory = "resources/database/migrations";
		variables.seedsDirectory      = "resources/database/seeds";

		return this;
	}

	/**
	 * @name                 Name of the model to create without the .cfc. For packages, specify name as 'myPackage/myModel'
	 * @methods              A comma-delimited list of method stubs to generate for you
	 * @persistence          Specify singleton to have only one instance of this model created
	 * @persistence.options  Transient,Singleton
	 * @tests                Generate the unit test BDD component
	 * @testsDirectory       Your unit tests directory. Only used if tests is true
	 * @directory            The base directory to create your model in and creates the directory if it does not exist.
	 * @description          The model hint description
	 * @open                 Open the file once generated
	 * @accessors            Setup accessors to be true in the component
	 * @properties           Enter a list of properties to generate. You can add the type via colon separator. Ex: firstName,age:numeric,wheels:array
	 * @force                Force overwrite of existing files
	 * @migration            Generate a migration file for this model
	 * @seeder               Generate a seeder file for this model
	 * @handler              Generate a handler for this model
	 * @rest                 Generate a REST handler for this model
	 * @resource             Generate a resourceful handler with all the actions
	 * @all                  Generate all the things: handler, resource, migration, seeder, tests
	 * @componentAnnotations Annotations to add to the component
	 * @ormTypes             Generate ORM types for the properties or normal ColdFusion types
	 * @propertyContent      Custom content to add to the properties
	 * @initContent          Custom content to add to the init method
	 **/
	function run(
		required name,
		methods                     = "",
		persistence                 = "transient",
		boolean tests               = true,
		testsDirectory              = "tests/specs/unit",
		directory                   = "models",
		description                 = "I am a new Model Object",
		boolean open                = false,
		boolean accessors           = true,
		properties                  = "id:numeric",
		boolean force               = false,
		boolean migration           = false,
		boolean seeder              = false,
		boolean handler             = false,
		boolean rest                = false,
		boolean resource            = false,
		boolean all                 = false,
		string componentAnnotations = "",
		boolean ormTypes            = false,
		string propertyContent      = "",
		string initContent          = ""
	){
		// Prepare arguments
		var modelTestPath   = arguments.directory;
		var modelNamePlural = variables.utility.pluralize( arguments.name.lcase() );
		if ( arguments.all ) {
			arguments.seeder    = true;
			arguments.migration = true;
			arguments.handler   = true;
			arguments.resource  = true;
		}

		// This will make each directory canonical and absolute
		arguments.directory      = resolvePath( arguments.directory );
		arguments.testsDirectory = resolvePath( arguments.testsDirectory );

		// Validate directory
		if ( !directoryExists( arguments.directory ) ) {
			directoryCreate( arguments.directory );
		}
		// Validate persistence
		if ( !len( arguments.name ) ) {
			error( "Cannot scaffold a model with an empty name." );
		}
		// Validate persistence
		if ( !listFindNoCase( variables.validPersistences, arguments.persistence ) ) {
			error(
				"The persistence value [#arguments.persistence#] is invalid. Valid values are [#listChangeDelims( variables.validPersistences, ", ", "," )#]"
			);
		}
		// Exit the command if something above failed
		if ( hasError() ) {
			return;
		}

		// Allow dot-delimited paths
		arguments.name = replace( arguments.name, ".", "/", "all" );

		// Read in Template
		var modelContent           = fileRead( "#variables.settings.templatesPath#/ModelContent.txt" );
		var modelMethodContent     = fileRead( "#variables.settings.templatesPath#/ModelMethodContent.txt" );
		var modelTestContent       = fileRead( "#variables.settings.templatesPath#/testing/ModelBDDContent.txt" );
		var modelTestMethodContent = fileRead(
			"#variables.settings.templatesPath#/testing/ModelBDDMethodContent.txt"
		);

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

		// Persistence
		switch ( Persistence ) {
			case "Transient":
				modelContent = replaceNoCase( modelContent, "|modelPersistence|", "", "all" );
				break;
			case "Singleton":
				modelContent = replaceNoCase(
					modelContent,
					"|modelPersistence|",
					"singleton ",
					"all"
				);
		}

		// Accessors
		if ( arguments.accessors ) {
			modelContent = replaceNoCase(
				modelContent,
				"|accessors|",
				"accessors=""true""",
				"all"
			);
		} else {
			modelContent = replaceNoCase( modelContent, "|accessors|", "", "all" );
		}

		// Generate Model Properties
		var properties = listToArray( arguments.properties );
		var buffer     = createObject( "java", "java.lang.StringBuffer" ).init( arguments.propertyContent );
		for ( var thisProperty in properties ) {
			var propName = getToken( trim( thisProperty ), 1, ":" );
			var propType = getToken( trim( thisProperty ), 2, ":" );
			if ( NOT len( propType ) ) {
				propType = "string";
			}
			buffer.append(
				"property name=""#propName#"" #arguments.ormTypes ? "ormtype" : "type"#=""#propType#"";#variables.cr & variables.utility.TAB#"
			);
		}
		modelContent = replaceNoCase(
			modelContent,
			"|properties|",
			buffer.toString()
		);

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
			modelContent     = replaceNoCase( modelContent, "|methods|", allMethods, "all" );
			modelTestContent = replaceNoCase(
				modelTestContent,
				"|TestCases|",
				allTestsCases,
				"all"
			);
		} else {
			modelContent     = replaceNoCase( modelContent, "|methods|", "", "all" );
			modelTestContent = replaceNoCase( modelTestContent, "|TestCases|", "", "all" );
		}

		// Write out the model
		var modelPath = "#arguments.directory#/#arguments.name#.cfc";
		// Create dir if it doesn't exist
		directoryCreate( getDirectoryFromPath( modelPath ), true, true );

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
		printInfo( "Created Model: [#modelPath#]" );

		// Generate migrations
		if ( arguments.migration ) {
			var migrationPath    = "#resolvePath( variables.migrationsDirectory )#/#dateTimeFormat( now(), "yyyy_mm_dd_HHnnss" )#_create_#modelNamePlural#_table.cfc";
			var migrationContent = replaceNoCase(
				fileRead( "#variables.settings.templatesPath#/ModelMigrationContent.txt" ),
				"|modelName|",
				modelNamePlural,
				"all"
			);
			// Create dir if it doesn't exist
			directoryCreate(
				getDirectoryFromPath( migrationPath ),
				true,
				true
			);
			// Create the migration
			file action="write" file="#migrationPath#" mode="777" output="#migrationContent#";
			// open file
			if ( arguments.open ) {
				openPath( migrationPath );
			}
			printInfo( "Created Migration: [#migrationPath#]" );
		}

		// Generate Seeder
		if ( arguments.seeder ) {
			var seederPath  = "#resolvePath( variables.seedsDirectory )#/#modelNamePlural#.cfc";
			var seedContent = replaceNoCase(
				fileRead( "#variables.settings.templatesPath#/ModelSeederContent.txt" ),
				"|modelName|",
				modelNamePlural,
				"all"
			);
			// Create dir if it doesn't exist
			directoryCreate( getDirectoryFromPath( seederPath ), true, true );
			// Create the migration
			file action="write" file="#seederPath#" mode="777" output="#seedContent#";
			// open file
			if ( arguments.open ) {
				openPath( seederPath );
			}
			printInfo( "Created Seeder: [#seederPath#]" );
		}

		// Generate Handler
		if ( arguments.handler ) {
			command( "coldbox create handler" )
				.params(
					name    : modelNamePlural,
					force   : arguments.force,
					open    : arguments.open,
					rest    : arguments.rest,
					resource: arguments.resource
				)
				.run();
		}

		// Generate Tests
		if ( arguments.tests ) {
			command( "coldbox create model-test" )
				.params(
					path   : arguments.name,
					force  : arguments.force,
					open   : arguments.open,
					methods: arguments.methods
				)
				.run();
		}

		// Open file?
		if ( arguments.open ) {
			openPath( modelPath );
		}
	}

}
