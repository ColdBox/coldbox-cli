/**
 * Refresh AI integration (sync with installed modules)
 * Updates guidelines and skills based on current box.json dependencies
 *
 * Examples:
 * coldbox ai refresh
 * coldbox ai update
 */
component extends="coldbox-cli.models.BaseAICommand" {

	/**
	 * Run the command
	 *
	 * @directory The target directory (defaults to current directory)
	 */
	function run( string directory = getCwd() ){
		showColdBoxBanner( "AI Integration Refresher" )
		printInfo( "Refreshing AI integration..." )
		print.line().toConsole()

		var result = variables.aiService.refresh( arguments.directory );

		if ( !result.success ) {
			printError( result.message )
			return;
		}

		// Show changes
		printSuccess( "✓ AI integration refreshed successfully!" )
		print.line()

		// Combine all changes for display
		var mcpAdded     = structKeyExists( result, "mcpServers" ) ? result.mcpServers.added.len() : 0
		var mcpRemoved   = structKeyExists( result, "mcpServers" ) ? result.mcpServers.removed.len() : 0
		var totalAdded   = result.guidelines.added.len() + result.skills.added.len() + mcpAdded
		var totalUpdated = result.guidelines.updated.len() + result.skills.updated.len()
		var totalRemoved = result.guidelines.removed.len() + result.skills.removed.len() + mcpRemoved

		if ( totalAdded ) {
			print.greenLine( "Added (#totalAdded#):" )
			result.guidelines.added.each( function( item ){
				print.indentedGreenLine( "  + #item# (guideline)" )
			} );
			result.skills.added.each( function( item ){
				print.indentedGreenLine( "  + #item# (skill)" )
			} );
			if ( structKeyExists( result, "mcpServers" ) ) {
				result.mcpServers.added.each( function( item ){
					print.indentedGreenLine( "  + #item# (MCP server)" )
				} );
			}
			print.line()
		}

		if ( totalUpdated ) {
			print.yellowLine( "Updated (#totalUpdated#):" )
			result.guidelines.updated.each( function( item ){
				print.indentedYellowLine( "  ↻ #item# (guideline)" )
			} );
			result.skills.updated.each( function( item ){
				print.indentedYellowLine( "  ↻ #item# (skill)" )
			} );
			print.line()
		}

		if ( totalRemoved ) {
			print.redLine( "Removed (#totalRemoved#):" )
			result.guidelines.removed.each( function( item ){
				print.indentedRedLine( "  - #item# (guideline)" )
			} );
			result.skills.removed.each( function( item ){
				print.indentedRedLine( "  - #item# (skill)" )
			} );
			if ( structKeyExists( result, "mcpServers" ) ) {
				result.mcpServers.removed.each( function( item ){
					print.indentedRedLine( "  - #item# (MCP server)" )
				} );
			}
			print.line()
		}

		if ( !totalAdded && !totalUpdated && !totalRemoved ) {
			printInfo( "No changes detected. Everything is up to date!" )
		}
	}

}
