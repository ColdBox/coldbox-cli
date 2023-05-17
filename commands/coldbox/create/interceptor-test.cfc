/**
 * Create a new interceptor BDD test in an existing ColdBox application.  Make sure you are running this command in the root
 * of your app for it to find the correct folder.
 * .
 * {code:bash}
 * coldbox create interceptor-test interceptors.MyInterceptor preProcess,postEvent
 * {code}
 *
 **/
component extends="coldbox-cli.models.BaseCommand"{

	/**
	 * @path           The instantiation path of the interceptor to create the test for
	 * @points         A comma-delimited list of interception points to generate tests for
	 * @testsDirectory Your unit tests directory. Only used if tests is true
	 * @open           Open the test once generated
	 * @force          Force overwrite of existing test
	 **/
	function run(
		required path,
		points         = "",
		testsDirectory = "tests/specs/interceptors",
		boolean open   = false,
		boolean force  = false
	){
		// This will make each directory canonical and absolute
		arguments.testsDirectory = resolvePath( arguments.testsDirectory );

		// Validate directory
		if ( !directoryExists( arguments.testsDirectory ) ) {
			directoryCreate( arguments.testsDirectory );
		}

		// Read in Template
		var interceptorTestContent = fileRead(
			"#variables.settings.templatesPath#/testing/InterceptorBDDContent.txt"
		);
		var interceptorTestCase = fileRead(
			"#variables.settings.templatesPath#/testing/InterceptorBDDCaseContent.txt"
		);

		// Start Replacing
		interceptorTestContent = replaceNoCase(
			interceptorTestContent,
			"|name|",
			arguments.path,
			"all"
		);

		// Interception Points
		if ( len( arguments.points ) ) {
			var allTestsCases = "";
			var thisTestCase  = "";

			for ( var thisPoint in listToArray( arguments.points ) ) {
				thisTestCase = replaceNoCase(
					interceptorTestCase,
					"|point|",
					thisPoint,
					"all"
				);
				allTestsCases &= thisTestCase & CR & CR;
			}
			interceptorTestContent = replaceNoCase(
				interceptorTestContent,
				"|TestCases|",
				allTestsCases,
				"all"
			);
		} else {
			interceptorTestContent = replaceNoCase(
				interceptorTestContent,
				"|TestCases|",
				"",
				"all"
			);
		}

		// Write it out.
		var testPath = "#arguments.testsDirectory#/#listLast( arguments.path, "." )#Test.cfc";
		// Create dir if it doesn't exist
		directoryCreate( getDirectoryFromPath( testPath ), true, true );

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
		file action="write" file="#testPath#" mode="777" output="#interceptorTestContent#";
		printInfo( "Created Test [#testPath#]" );

		// open file
		if ( arguments.open ) {
			openPath( testPath );
		}
	}

}
