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
component aliases="coldbox create controller" extends="coldbox-cli.models.BaseCommand" {

	static {
		HINTS = {
			index  : "Display a listing of the resource",
			new    : "Show the form for creating a new resource",
			create : "Store a newly created resource in storage",
			show   : "Display the specified resource",
			edit   : "Show the form for editing the specified resource",
			update : "Update the specified resource in storage",
			delete : "Remove the specified resource from storage"
		}
	}

	/**
	 * @name             Name of the handler to create without the .cfc. For packages, specify name as 'myPackage/myHandler'
	 * @actions          A comma-delimited list of actions to generate, by default we generate just an index action
	 * @views            Generate a view for each action
	 * @viewsDirectory   The directory where your views are stored. Only used if views is set to true.
	 * @appMapping       The root location of the application in the web root: ex: /MyApp or / if in the root
	 * @integrationTests Generate the integration test component
	 * @testsDirectory   Your integration tests directory. Only used if integrationTests is true
	 * @directory        The base directory to create your handler in and creates the directory if it does not exist. Defaults to 'handlers'.
	 * @description      The handler hint description
	 * @open             Open the handler (and test(s) if applicable) once generated
	 * @rest             Make this a REST handler instead of a normal ColdBox Handler
	 * @force            Force overwrite of existing handler
	 * @resource         Generate a resourceful handler with all the actions
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
		boolean rest             = false,
		boolean force            = false,
		boolean resource         = false
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

		/*******************************************************************
		 * Read in Templates
		 *******************************************************************/

		// Rest or Normal
		var handlerContent = fileRead(
			arguments.rest ? "#variables.settings.templatesPath#/RestHandlerContent.txt" : "#variables.settings.templatesPath#/HandlerContent.txt"
		);
		var handlerTestContent = fileRead( "#variables.settings.templatesPath#/testing/HandlerBDDContent.txt" );

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

		// Auto Actions Determination if none passed via resource && rest, else empty handler
		if ( !len( arguments.actions ) ) {
			if ( arguments.resource && !arguments.rest ) {
				arguments.actions = "index,new,create,show,edit,update,delete";
			} else if ( ( arguments.resource && arguments.rest ) || arguments.rest ) {
				arguments.actions = "index,create,show,update,delete";
			} else {
				arguments.actions = "index";
			}
		}

		// Handle Actions
		if ( len( arguments.actions ) ) {
			var actionResults = buildActions( argumentCollection = arguments );
			handlerContent    = replaceNoCase(
				handlerContent,
				"|EventActions|",
				actionResults.actions,
				"all"
			);
			handlerTestContent = replaceNoCase(
				handlerTestContent,
				"|TestCases|",
				actionResults.tests,
				"all"
			);
		} else {
			handlerContent     = replaceNoCase( handlerContent, "|EventActions|", "", "all" );
			handlerTestContent = replaceNoCase( handlerTestContent, "|TestCases|", "", "all" );
		}

		// Create dir if it doesn't exist
		var handlerPath = resolvePath( "#arguments.directory#/#arguments.name#.cfc" );
		directoryCreate(
			getDirectoryFromPath( handlerPath ),
			true,
			true
		);

		// Confirm it or Force it
		if (
			fileExists( handlerPath ) && !arguments.force && !confirm(
				"The file '#getFileFromPath( handlerPath )#' already exists, overwrite it (y/n)?"
			)
		) {
			printWarn( "Exiting..." );
			return;
		}

		// Write out the files
		file action="write" file="#handlerPath#" mode="777" output="#handlerContent#";
		printInfo( "Created Handler [#handlerPath#]" );

		// More Tests?
		if ( arguments.integrationTests ) {
			var testPath = resolvePath( "#arguments.testsDirectory#/#arguments.name#Test.cfc" );
			// Create dir if it doesn't exist
			directoryCreate( getDirectoryFromPath( testPath ), true, true );
			// Create the tests
			file action="write" file="#testPath#" mode="777" output="#handlerTestContent#";
			printInfo( "Created Integration Spec [#testPath#]" );
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

	/**
	 * Build out the actions
	 *
	 * @return struct of { actions : "", tests : ""}
	 */
	function buildActions(
		name,
		actions,
		boolean views,
		viewsDirectory,
		boolean integrationTests,
		appMapping,
		testsDirectory,
		directory,
		description,
		boolean open,
		boolean rest,
		boolean force,
		boolean resource
	){
		var results       = { actions : "", tests : "" }
		var actionContent = fileRead(
			arguments.rest ? "#variables.settings.templatesPath#/RestActionContent.txt" : "#variables.settings.templatesPath#/ActionContent.txt"
		);
		var handlerTestCaseContent = fileRead(
			"#variables.settings.templatesPath#/testing/HandlerBDDCaseContent.txt"
		);

		// Loop Over actions generating their functions
		for ( var thisAction in listToArray( arguments.actions ) ) {
			thisAction = trim( thisAction );
			// Hint Replacement
			results.actions &= replaceNoCase(
				actionContent,
				"|hint|",
				static.HINTS[ thisAction ] ?: thisAction,
				"all"
			);
			// Action Replacement
			results.actions = replaceNoCase( results.actions, "|action|", thisAction, "all" ) & repeatString(
				variables.cr,
				1
			);

			// Are we creating views? But only if we are NOT in rest mode
			if (
				arguments.views && !arguments.rest && !listFindNoCase( "create,update,delete", thisAction )
			) {
				var camelCaseHandlerName = variables.utility.camelCase( arguments.name );
				command( "coldbox create view" )
					.params(
						name     : camelCaseHandlerName & "/" & thisAction,
						content  : "<h1>#camelCaseHandlerName#.#thisAction#</h1>",
						directory: arguments.viewsDirectory,
						force    : arguments.force,
						open     : arguments.open
					)
					.run();
			}

			// Are we creating tests cases on actions
			if ( arguments.integrationTests ) {
				var thisTestCase = replaceNoCase(
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
				results.tests &= thisTestCase & repeatString( variables.cr, 1 );
			}
		}

		// final replacements
		results.actions = replaceNoCase(
			results.actions,
			"|name|",
			arguments.name,
			"all"
		);

		return results;
	}

}
