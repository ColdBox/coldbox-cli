/**
 * Create a new view in an existing ColdBox application.  Run this command in the root
 * of your app for it to find the correct folder.  By default, your new view will be created in /views but you can
 * override that with the directory param.
 * .
 * {code:bash}
 * coldbox create view myView
 * {code}
 *
 **/
component extends="coldbox-cli.models.BaseCommand" {

	/**
	 * @name      Name of the view to create without the .cfm.
	 * @helper    Generate a helper file for this view
	 * @directory The base directory to create your view in and creates the directory if it does not exist.
	 * @open      Open the view in your default editor
	 * @content   The content to put in the view
	 * @force     Force overwrite of existing view
	 * @boxlang  Is this a boxlang project?
	 **/
	function run(
		required name,
		boolean helper = false,
		directory      = "views",
		boolean open   = false,
		content        = "<h1>#arguments.name# view</h1>",
		boolean force  = false,
		boolean boxlang = isBoxLangProject( getCWD() )
	){
		// Allow dot-delimited paths
		arguments.name = replace( arguments.name, ".", "/", "all" );

		// Check if the name is actually a path
		var nameArray       = arguments.name.listToArray( "/" );
		var nameArrayLength = nameArray.len();
		if ( nameArrayLength > 1 ) {
			// If it is a path, split the path from the name
			arguments.name   = nameArray[ nameArrayLength ];
			var extendedPath = nameArray.slice( 1, nameArrayLength - 1 ).toList( "/" );
			arguments.directory &= "/#extendedPath#";
		}

		// This will make each directory canonical and absolute
		arguments.directory = resolvePath( arguments.directory );

		// Validate directory
		if ( !directoryExists( arguments.directory ) ) {
			directoryCreate( arguments.directory );
		}

		if( arguments.boxlang ){
			savecontent variable="local.viewContent" {
				writeOutput( "<bx:output>#variables.utility.BREAK#" )
				writeOutput( "#arguments.content##variables.utility.BREAK#" )
				writeOutput( "</bx:output>" )
			};
		} else {
			savecontent variable="local.viewContent" {
				writeOutput( "<cfoutput>#variables.utility.BREAK#" )
				writeOutput( "#arguments.content##variables.utility.BREAK#" )
				writeOutput( "</cfoutput>" )
			};
		}

		// Write out view
		var viewPath = "#arguments.directory#/#arguments.name#.#arguments.boxlang ? "bxm" : "cfm"#";

		// Confirm it
		if (
			fileExists( viewPath ) && !arguments.force && !confirm(
				"The file '#getFileFromPath( viewPath )#' already exists, overwrite it (y/n)?"
			)
		) {
			printWarn( "Exiting..." );
			return;
		}

		file action="write" file="#viewPath#" mode="777" output="#viewContent#";
		printInfo( "Created View [#viewPath#]" );

		// Open the view?
		if ( arguments.open ) {
			openPath( viewPath );
		}

		// Write out view helper
		if ( arguments.helper ) {
			var viewHelperContent= "<!--- #arguments.name# view Helper --->";
			var viewHelperPath   = "#arguments.directory#/#arguments.name#Helper.#arguments.boxlang ? "bxm" : "cfm"#";
			file action          ="write" file="#viewHelperPath#" mode="777" output="#viewHelperContent#";
			printInfo( "Created View Helper [#viewHelperPath#]" );

			// Open the view helper?
			if ( arguments.open ) {
				openPath( viewHelperPath );
			}
		}
	}

}
