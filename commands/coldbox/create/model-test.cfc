/**
 * Create a new model bdd test in an existing ColdBox application.  Make sure you are running this command in the root
 * of your app for it to find the correct folder.
 * .
 * {code:bash}
 * coldbox create model-test myModel --open
 * {code}
 *
 **/
component extends="coldbox-cli.models.BaseCommand" {

	/**
	 * Constructor
	 */
	function init(){
		// valid persistences
		variables.validPersistences = "Transient,Singleton";

		super.init();

		return this;
	}

	/**
	 * @path           The instantiation path of the model to create the test for without any .cfc or `models` prefix
	 * @methods        A comma-delimited list of method to generate tests for
	 * @testsDirectory Your unit tests directory. Only used if tests is true
	 * @open           Open the file once generated
	 * @force          Force overwrite of existing files
	 * @boxlang       Is this a boxlang project?
	 **/
	function run(
		required path,
		methods         = "",
		testsDirectory  = "tests/specs/unit",
		boolean open    = false,
		boolean force   = false,
		boolean boxlang = isBoxLangProject( getCWD() )
	){
		// This will make each directory canonical and absolute
		arguments.testsDirectory = resolvePath( arguments.testsDirectory );

		// Validate directory
		if ( !directoryExists( arguments.testsDirectory ) ) {
			directoryCreate( arguments.testsDirectory );
		}

		// Read in Template
		var modelTestContent       = fileRead( "#variables.settings.templatesPath#/testing/ModelBDDContent.txt" );
		var modelTestMethodContent = fileRead( "#variables.settings.templatesPath#/testing/ModelBDDMethodContent.txt" );

		// Basic replacements
		modelTestContent = replaceNoCase(
			modelTestContent,
			"|modelName|",
			arguments.path,
			"all"
		);
		modelTestContent = replaceNoCase(
			modelTestContent,
			"|modelPath|",
			arguments.path,
			"all"
		);
		if ( arguments.boxlang ) {
			modelTestContent = toBoxLangClass( modelTestContent );
		}

		// Handle Methods
		if ( len( arguments.methods ) ) {
			var allTestsCases = "";

			// Loop Over methods to generate them
			for ( var thisMethod in listToArray( arguments.methods ) ) {
				thisMethod = trim( thisMethod );

				var thisTestCase = replaceNoCase(
					modelTestMethodContent,
					"|method|",
					thisMethod,
					"all"
				);
				allTestsCases &= thisTestCase & CR & CR;

				printInfo( "Generated Test Method: #thisMethod#()" );
			}

			// final replacement
			modelTestContent = replaceNoCase(
				modelTestContent,
				"|TestCases|",
				allTestsCases,
				"all"
			);
		} else {
			modelTestContent = replaceNoCase(
				modelTestContent,
				"|TestCases|",
				"",
				"all"
			);
		}

		var testPath = "#arguments.TestsDirectory#/#listLast( arguments.path, "." )#Test.#arguments.boxlang ? "bx" : "cfc"#";
		// Create dir if it doesn't exist
		directoryCreate(
			getDirectoryFromPath( testPath ),
			true,
			true
		);

		// Confirm it
		if (
			fileExists( testPath ) && !arguments.force && !confirm(
				"The file '#getFileFromPath( testPath )#' already exists, overwrite it (y/n)?"
			)
		) {
			printWarn( "Exiting..." );
			return;
		}

		// Create the tests
		file action="write" file="#testPath#" mode="777" output="#modelTestContent#";

		// open file
		if ( arguments.open ) {
			openPath( testPath );
		}
		printInfo( "Created Test: [#testPath#]" );
	}

}
