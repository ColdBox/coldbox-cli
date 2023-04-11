/**
 * Create a new model CFC in an existing ColdBox application.  Make sure you are running this command in the root
 * of your app for it to find the correct folder.  You can optionally create unit tests for your new model at the same time.
 * By default, your new model will be created in /model but you can override that with the directory param.
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
component {

	/**
	 * Constructor
	 */
	function init(){
		// valid persistences
		variables.validPersistences = "Transient,Singleton";

		return this;
	}

	/**
	 * @name                Name of the model to create without the .cfc. For packages, specify name as 'myPackage/myModel'
	 * @methods             A comma-delimited list of method stubs to generate for you
	 * @persistence         Specify singleton to have only one instance of this model created
	 * @persistence.options Transient,Singleton
	 * @tests               Generate the unit test BDD component
	 * @testsDirectory      Your unit tests directory. Only used if tests is true
	 * @directory           The base directory to create your model in and creates the directory if it does not exist.
	 * @description         The model hint description
	 * @open                Open the file once generated
	 * @accessors           Setup accessors to be true in the component
	 * @properties          Enter a list of properties to generate. You can add the type via colon separator. Ex: firstName,age:numeric,wheels:array
	 **/
	function run(
		required name,
		methods           = "",
		persistence       = "transient",
		boolean tests     = true,
		testsDirectory    = "tests/specs/unit",
		directory         = "models",
		description       = "I am a new Model Object",
		boolean open      = false,
		boolean accessors = true,
		properties        = ""
	){
		// store incoming relative path for testing purposes
		var modelTestPath        = arguments.directory;
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
		// This help readability so the success messages aren't up against the previous command line
		print.line();

		// Read in Template
		var modelContent           = fileRead( "/coldbox-commands/templates/ModelContent.txt" );
		var modelMethodContent     = fileRead( "/coldbox-commands/templates/ModelMethodContent.txt" );
		var modelTestContent       = fileRead( "/coldbox-commands/templates/testing/ModelBDDContent.txt" );
		var modelTestMethodContent = fileRead( "/coldbox-commands/templates/testing/ModelBDDMethodContent.txt" );


		// Basic replacements
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

		// Properties
		var properties = listToArray( arguments.properties );
		var buffer     = createObject( "java", "java.lang.StringBuffer" ).init();
		for ( var thisProperty in properties ) {
			var propName = getToken( trim( thisProperty ), 1, ":" );
			var propType = getToken( trim( thisProperty ), 2, ":" );
			if ( NOT len( propType ) ) {
				propType = "string";
			}
			buffer.append( "property name=""#propName#"" type=""#propType#"";#chr( 13 ) & chr( 9 )#" );
		}
		modelContent = replaceNoCase(
			modelContent,
			"|properties|",
			buffer.toString()
		);

		// Handle Methods
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

				print.yellowLine( "Generated method: #thisMethod#" );

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
		var modelPath = "#directory#/#arguments.name#.cfc";
		// Create dir if it doesn't exist
		directoryCreate( getDirectoryFromPath( modelPath ), true, true );
		// Prompt for override
		if (
			fileExists( modelPath ) && !confirm(
				"The file '#getFileFromPath( modelPath )#' already exists, overwrite it (y/n)?"
			)
		) {
			print.redLine( "Exiting..." );
			return;
		}
		// Write out file
		fileWrite( modelPath, trim( modelContent ) );
		print.greenLine( "Created #modelPath#" );

		if ( arguments.tests ) {
			var testPath = "#arguments.TestsDirectory#/#arguments.name#Test.cfc";
			// Create dir if it doesn't exist
			directoryCreate( getDirectoryFromPath( testPath ), true, true );
			// Create the tests
			file action="write" file="#testPath#" mode="777" output="#modelTestContent#";
			// open file
			if ( arguments.open ) {
				openPath( testPath );
			}
			print.greenLine( "Created #testPath#" );
		}

		// Open file?
		if ( arguments.open ) {
			openPath( modelPath );
		}
	}

}
