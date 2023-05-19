/**
 * Create a new layout in an existing ColdBox application.  Run this command in the root
 * of your app for it to find the correct folder.  By default, your new layout will be created in /layouts but you can
 * override that with the directory param.
 * .
 * {code:bash}
 * coldbox create layout myLayout
 * {code}
 *
 **/
component extends="coldbox-cli.models.BaseCommand" {

	/**
	 * @arguments.name Name of the layout to create without the .cfm.
	 * @helper         Generate a helper file for this layout
	 * @directory      The base directory to create your layout in and creates the directory if it does not exist.
	 * @open           Open the view in your default editor
	 * @force          Force overwrite of existing files
	 * @content        The content to put in the layout
	 **/
	function run(
		required name,
		boolean helper = false,
		directory      = "layouts",
		boolean open   = false,
		boolean force  = false,
		content        = "<h1>#arguments.name# Layout</h1>#variables.utility.BREAK#"
	){
		// This will make each directory canonical and absolute
		arguments.directory = resolvePath( arguments.directory );

		// Validate directory
		if ( !directoryExists( arguments.directory ) ) {
			directoryCreate( arguments.directory );
		}

		// This help readability so the success messages aren't up against the previous command line
		print.line();

		savecontent variable="local.layoutContent" {
			writeOutput( "<cfoutput>#variables.utility.BREAK#" )
			writeOutput( arguments.content )
			writeOutput( "<div>##view()##</div>#variables.utility.BREAK#" )
			writeOutput( "</cfoutput>" )
		};

		// Write out layout
		var layoutPath = "#arguments.directory#/#arguments.name#.cfm";

		// Confirm it
		if (
			fileExists( layoutPath ) && !arguments.force && !confirm(
				"The file '#getFileFromPath( layoutPath )#' already exists, overwrite it (y/n)?"
			)
		) {
			printWarn( "Exiting..." );
			return;
		}

		file action="write" file="#layoutPath#" mode="777" output="#layoutContent#";
		printInfo( "Created Layout [#layoutPath#]" );

		// Open the view?
		if ( arguments.open ) {
			openPath( layoutPath );
		}

		if ( arguments.helper ) {
			var layoutHelperContent= "<!--- #arguments.name# Layout Helper --->";
			var layoutHelperPath   = "#arguments.directory#/#arguments.name#Helper.cfm";
			file action            ="write" file="#layoutHelperPath#" mode="777" output="#layoutHelperContent#";
			printInfo( "Created Layout Helper [#layoutHelperPath#]" );

			// Open the view helper?
			if ( arguments.open ) {
				openPath( layoutHelperPath );
			}
		}
	}

}
