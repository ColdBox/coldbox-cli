/**
 * Display AI integration information
 * Shows current configuration, installed guidelines, skills, and agents
 *
 * Examples:
 * coldbox ai info
 */
component extends="coldbox-cli.models.BaseAICommand" {

	/**
	 * Run the command
	 *
	 * @directory The target directory (defaults to current directory)
	 */
	function run( string directory = getCwd() ){
		showColdBoxBanner( "AI Integration Info" );

		try {
			var info = variables.aiService.getInfo( arguments.directory );

			if ( !info.installed ) {
				printWarn( "AI integration is not installed." );
				print.line();
				printInfo( "Run 'coldbox ai install' to set up AI integration." );
				return;
			}

			// Load manifest to get active agent
			var manifest    = loadManifest( arguments.directory );
			var activeAgent = manifest.activeAgent ?: "none";

			// Print configuration in a table
			print.line();
			print.table(
				headerNames = [ "Setting", "Value" ],
				data        = [
					[
						"ColdBox CLI Version",
						info.coldboxCliVersion
					],
					[ "Language Mode", info.language ],
					[ "App Type", info.templateType ],
					[ "Active Agent", activeAgent ],
					[ "Last Sync", info.lastSync ]
				]
			);
			print.line();

			// Guidelines (sorted alphabetically)
			printInfo( "Guidelines (#info.guidelines.len()#):" );
			if ( info.guidelines.len() ) {
				var sortedGuidelines = info.guidelines.sort( function( a, b ){
					return compare( a.name, b.name );
				} );
				sortedGuidelines.each( function( guideline ){
					print.indentedLine( "  🦮  #guideline.name# (from #guideline.source#)" );
				} );
			} else {
				print.indentedLine( "  No guidelines installed" );
			}
			print.line();

			// Skills (sorted alphabetically within groups)
			printInfo( "Skills (#info.skills.len()#):" );
			if ( info.skills.len() ) {
				// Group by source
				var coreSkills = info.skills.filter( function( s ){
					return s.source == "core";
				} );
				var moduleSkills = info.skills.filter( function( s ){
					return s.source != "core";
				} );

				if ( coreSkills.len() ) {
					print.indentedCyanLine( "  Core:" );
					coreSkills
						.sort( function( a, b ){
							return compare( a.name, b.name );
						} )
						.each( function( skill ){
							print.indentedLine( "    ⭐ #skill.name#" );
						} );
				}

				if ( moduleSkills.len() ) {
					print.indentedCyanLine( "  Modules:" );
					moduleSkills
						.sort( function( a, b ){
							return compare( a.name, b.name );
						} )
						.each( function( skill ){
							print.indentedLine( "    • #skill.name# (from #skill.source#)" );
						} );
				}
			} else {
				print.indentedLine( "  No skills installed" );
			}
			print.line();

			// Agents
			printInfo( "Configured Agents (#info.agents.len()#):" );
			if ( info.agents.len() ) {
				info.agents.each( function( agent ){
					if ( agent == activeAgent ) {
						print.indentedGreenLine( "  ▶ #agent# (active)" );
					} else {
						print.indentedLine( "  ⊕ #agent#" );
					}
				} );
			} else {
				print.indentedLine( "  No agents configured" );
			}
			print.line();
			// Quick health check
			printTip( "Run 'coldbox ai doctor' for a detailed health check" );
		} catch ( any e ) {
			printError( "Failed to get AI integration info: #e.message#" )
			printError( e.stackTrace )
		}
	}

}
