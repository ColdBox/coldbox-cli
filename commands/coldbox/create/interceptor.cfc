/**
 * Create a new interceptor in an existing ColdBox application.  Make sure you are running this command in the root
 * of your app for it to find the correct folder.  You can optionally create unit tests for your new interceptor at the same time.
 * By default, your new interceptor will be created in /interceptors but you can override that with the directory param.
 * Note, even though this command creates the interceptor CFC, you will still need to register it in the interceptors array
 * in your ColdBox.cfc config file.
 * .
 * {code:bash}
 * coldbox create interceptor myInterceptor preProcess,postEvent
 * {code}
 *
 **/
component extends="coldbox-cli.models.BaseCommand" {

	/**
	 * @name           Name of the interceptor to create without the .cfc
	 * @points         A comma-delimited list of interception points to generate
	 * @description    A description for the interceptor hint
	 * @tests          Generate the unit test component
	 * @testsDirectory Your unit tests directory. Only used if tests is true
	 * @directory      The base directory to create your interceptor in and creates the directory if it does not exist.
	 * @open           Open the interceptor once generated
	 * @force          Force overwrite of the interceptor if it exists
	 **/
	function run(
		required name,
		points         = "",
		description    = "I am a new interceptor",
		boolean tests  = true,
		testsDirectory = "tests/specs/interceptors",
		directory      = "interceptors",
		boolean open   = false,
		boolean force  = false
	){
		// This will make each directory canonical and absolute
		var relativeDirectory    = arguments.directory;
		arguments.directory      = resolvePath( arguments.directory );
		arguments.testsDirectory = resolvePath( arguments.testsDirectory );

		// Validate directory
		if ( !directoryExists( arguments.directory ) ) {
			directoryCreate( arguments.directory );
		}

		// This help readability so the success messages aren't up against the previous command line
		print.line();

		// Read in Template
		var interceptorContent     = fileRead( "#variables.settings.templatesPath#/InterceptorContent.txt" );
		var interceptorMethod      = fileRead( "#variables.settings.templatesPath#/InterceptorMethod.txt" );
		var interceptorTestContent = fileRead( "#variables.settings.templatesPath#/testing/InterceptorBDDContent.txt" );
		var interceptorTestCase    = fileRead( "#variables.settings.templatesPath#/testing/InterceptorBDDCaseContent.txt" );

		// Start Replacing
		interceptorContent = replaceNoCase(
			interceptorContent,
			"|Name|",
			arguments.name,
			"all"
		);
		var interceptorPath    = listChangeDelims( relativeDirectory, ".", "/\" ).listAppend( arguments.name, "." );
		interceptorTestContent = replaceNoCase(
			interceptorTestContent,
			"|name|",
			interceptorPath,
			"all"
		);

		// Placeholder in case we add this in
		interceptorContent = replaceNoCase(
			interceptorContent,
			"|Description|",
			arguments.description,
			"all"
		);

		// Interception Points
		if ( len( arguments.points ) ) {
			var methodContent = "";
			var allTestsCases = "";
			var thisTestCase  = "";

			for ( var thisPoint in listToArray( arguments.points ) ) {
				methodContent = methodContent & replaceNoCase(
					interceptorMethod,
					"|interceptionPoint|",
					thisPoint,
					"all"
				) & CR & CR;

				// Are we creating tests cases
				if ( arguments.tests ) {
					thisTestCase = replaceNoCase(
						interceptorTestCase,
						"|point|",
						thisPoint,
						"all"
					);
					allTestsCases &= thisTestCase & CR & CR;
				}
			}
			interceptorContent = replaceNoCase(
				interceptorContent,
				"|interceptionPoints|",
				methodContent,
				"all"
			);
			interceptorTestContent = replaceNoCase(
				interceptorTestContent,
				"|TestCases|",
				allTestsCases,
				"all"
			);
		} else {
			interceptorContent = replaceNoCase(
				interceptorContent,
				"|interceptionPoints|",
				"",
				"all"
			);
			interceptorTestContent = replaceNoCase(
				interceptorTestContent,
				"|TestCases|",
				"",
				"all"
			);
		}

		// Write it out.
		var interceptorPath = "#arguments.directory#/#arguments.name#.cfc";

		// Confirm it
		if (
			fileExists( interceptorPath ) && !arguments.force && !confirm(
				"The file '#getFileFromPath( interceptorPath )#' already exists, overwrite it (y/n)?"
			)
		) {
			printWarn( "Exiting..." );
			return;
		}

		file action="write" file="#interceptorPath#" mode="777" output="#interceptorContent#";
		print.greenLine( "#interceptorPath#" );

		if ( tests ) {
			var testPath = "#TestsDirectory#/#arguments.name#Test.cfc";
			// Create dir if it doesn't exist
			directoryCreate(
				getDirectoryFromPath( testPath ),
				true,
				true
			);
			// Create the tests
			file action="write" file="#testPath#" mode="777" output="#interceptorTestContent#";
			printInfo( "Created #testPath#" );
			// open file
			if ( arguments.open ) {
				openPath( testPath );
			}
		}

		// open file
		if ( arguments.open ) {
			openPath( interceptorPath );
		}
	}

}
