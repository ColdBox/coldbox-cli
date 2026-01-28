/**
 * Refresh AI integration (sync with installed modules)
 * Updates guidelines and skills based on current box.json dependencies
 *
 * Examples:
 * coldbox ai refresh
 * coldbox ai update
 */
component extends="coldbox-cli.models.BaseCommand" aliases="update" {

	// DI
	property name="aiService" inject="AIService@coldbox-cli";

	/**
	 * Run the command
	 *
	 * @directory The target directory (defaults to current directory)
	 */
	function run( string directory = getCwd() ){
		printInfo( "Refreshing AI integration..." );
		print.line();

		try {
			var result = variables.aiService.refresh( arguments.directory );

			if ( !result.success ) {
				printError( result.message );
				return;
			}

			// Show changes
			printSuccess( "✓ AI integration refreshed successfully!" );
			print.line();

			if ( result.added.len() ) {
				print.greenLine( "Added (#result.added.len()#):" );
				result.added.each( function( item ){
					print.indentedGreenLine( "  + #item#" );
				} );
				print.line();
			}

			if ( result.updated.len() ) {
				print.yellowLine( "Updated (#result.updated.len()#):" );
				result.updated.each( function( item ){
					print.indentedYellowLine( "  ↻ #item#" );
				} );
				print.line();
			}

			if ( result.removed.len() ) {
				print.redLine( "Removed (#result.removed.len()#):" );
				result.removed.each( function( item ){
					print.indentedRedLine( "  - #item#" );
				} );
				print.line();
			}

			if ( !result.added.len() && !result.updated.len() && !result.removed.len() ) {
				printInfo( "No changes detected. Everything is up to date!" );
			}
		} catch ( any e ) {
			printError( "Failed to refresh AI integration: #e.message#" );
			if ( shell.isDebug() ) {
				printError( e.stackTrace );
			}
		}
	}

}
