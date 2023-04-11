/**
 *  Create a new handler (controller) in an existing ColdBox application.  Make sure you are running this command in the root
 *  of your app for it to find the correct folder.  You can optionally create the views as well as the integration tests for your
 *  new handler at the same time.  By default, your new handler will be created in /handlers but you can override that with the directory param.
 * .
 * {code:bash}
 * coldbox create handler myHandler index,foo,bar --open
 * {code}
 *
 **/
component aliases="coldbox create controller" {

	/**
	 * @name             Name of the handler to create without the .cfc. For packages, specify name as 'myPackage/myHandler'
	 * @actions          A comma-delimited list of actions to generate
	 * @views            Generate a view for each action
	 * @viewsDirectory   The directory where your views are stored. Only used if views is set to true.
	 * @appMapping       The root location of the application in the web root: ex: /MyApp or / if in the root
	 * @integrationTests Generate the integration test component
	 * @testsDirectory   Your integration tests directory. Only used if integrationTests is true
	 * @directory        The base directory to create your handler in and creates the directory if it does not exist. Defaults to 'handlers'.
	 * @description      The handler hint description
	 * @open             Open the handler (and test(s) if applicable) once generated
	 * @rest             Make this a REST handler instead of a normal ColdBox Handler
	 **/
	function run(
		required name,
		actions                  = "",
		boolean views            = true,
		viewsDirectory           = "views",
		boolean integrationTests = true,
		appMapping               = "/",
		testsDirectory           = "tests/specs/integration",
		directory                = "handlers",
		description              = "I am a new handler",
		boolean open             = false,
		boolean rest             = false
	){
		// This will make each directory canonical and absolute
		arguments.directory      = resolvePath( arguments.directory );
		arguments.viewsDirectory = resolvePath( arguments.viewsDirectory );
		arguments.testsDirectory = resolvePath( arguments.testsDirectory );

		// Validate directory
		if ( !directoryExists( arguments.directory ) ) {
			directoryCreate( arguments.directory );
		}

		// Allow dot-delimited paths
		arguments.name = replace( arguments.name, ".", "/", "all" );
		// This help readability so the success messages aren't up against the previous command line
		print.line();

		/*******************************************************************
		 * Read in Templates
		 *******************************************************************/

		// Rest or Normal
		var handlerContent = fileRead(
			arguments.rest ? "/coldbox-commands/templates/RestHandlerContent.txt" : "/coldbox-commands/templates/HandlerContent.txt"
		);
		var actionContent = fileRead(
			arguments.rest ? "/coldbox-commands/templates/RestActionContent.txt" : "/coldbox-commands/templates/ActionContent.txt"
		);
		var handlerTestContent     = fileRead( "/coldbox-commands/templates/testing/HandlerBDDContent.txt" );
		var handlerTestCaseContent = fileRead( "/coldbox-commands/templates/testing/HandlerBDDCaseContent.txt" );

		// Start text replacements
		handlerContent = replaceNoCase(
			handlerContent,
			"|handlerName|",
			arguments.name,
			"all"
		);
		handlerTestContent = replaceNoCase(
			handlerTestContent,
			"|appMapping|",
			arguments.appMapping,
			"all"
		);
		handlerTestContent = replaceNoCase(
			handlerTestContent,
			"|handlerName|",
			arguments.name,
			"all"
		);
		handlerContent = replaceNoCase(
			handlerContent,
			"|Description|",
			arguments.description,
			"all"
		);

		// Handle Actions if passed
		if ( len( arguments.actions ) ) {
			var allActions    = "";
			var allTestsCases = "";
			var thisTestCase  = "";

			// Loop Over actions generating their functions
			for ( var thisAction in listToArray( arguments.actions ) ) {
				thisAction = trim( thisAction );
				allActions = allActions & replaceNoCase( actionContent, "|action|", thisAction, "all" ) & cr & cr;

				// Are we creating views? But only if we are NOT in rest mode
				if ( arguments.views && !arguments.rest ) {
					var camelCaseHandlerName = arguments.name.left( 1 ).lCase();
					if ( arguments.name.len() > 1 ) {
						camelCaseHandlerName &= arguments.name.right( -1 );
					}

					var viewPath = resolvePath(
						arguments.viewsDirectory & "/" & camelCaseHandlerName & "/" & thisAction & ".cfm"
					);
					// Create dir if it doesn't exist
					directoryCreate( getDirectoryFromPath( viewPath ), true, true );
					// Create View Stub
					fileWrite( viewPath, "<cfoutput>#cr#<h1>#arguments.name#.#thisAction#</h1>#cr#</cfoutput>" );
					print.greenLine( "Created " & viewPath );
				}

				// Are we creating tests cases on actions
				if ( arguments.integrationTests ) {
					thisTestCase = replaceNoCase(
						handlerTestCaseContent,
						"|action|",
						thisAction,
						"all"
					);
					thisTestCase = replaceNoCase(
						thisTestCase,
						"|event|",
						listChangeDelims( arguments.name, ".", "/\" ) & "." & thisAction,
						"all"
					);
					allTestsCases &= thisTestCase & CR & CR;
				}
			}

			// final replacements
			allActions     = replaceNoCase( allActions, "|name|", arguments.name, "all" );
			handlerContent = replaceNoCase(
				handlerContent,
				"|EventActions|",
				allActions,
				"all"
			);
			handlerTestContent = replaceNoCase(
				handlerTestContent,
				"|TestCases|",
				allTestsCases,
				"all"
			);
		} else {
			handlerContent     = replaceNoCase( handlerContent, "|EventActions|", "", "all" );
			handlerTestContent = replaceNoCase( handlerTestContent, "|TestCases|", "", "all" );
		}

		var handlerPath = resolvePath( "#arguments.directory#/#arguments.name#.cfc" );
		// Create dir if it doesn't exist
		directoryCreate(
			getDirectoryFromPath( handlerPath ),
			true,
			true
		);

		// Confirm it
		if (
			fileExists( handlerPath ) && !confirm(
				"The file '#getFileFromPath( handlerPath )#' already exists, overwrite it (y/n)?"
			)
		) {
			print.redLine( "Exiting..." );
			return;
		}

		// Write out the files
		file action="write" file="#handlerPath#" mode="777" output="#handlerContent#";
		print.greenLine( "Created #handlerPath#" );

		if ( arguments.integrationTests ) {
			var testPath = resolvePath( "#arguments.testsDirectory#/#arguments.name#Test.cfc" );
			// Create dir if it doesn't exist
			directoryCreate( getDirectoryFromPath( testPath ), true, true );
			// Create the tests
			file action="write" file="#testPath#" mode="777" output="#handlerTestContent#";
			print.greenLine( "Created #testPath#" );
			// open file
			if ( arguments.open ) {
				openPath( testPath );
			}
		}

		// open file
		if ( arguments.open ) {
			openPath( handlerPath );
		}
	}

}
