/**
 * Display AI integration information
 * Shows current configuration, installed guidelines, skills, and agents
 *
 * Examples:
 * coldbox ai info
 */
component extends="coldbox-cli.models.BaseCommand" {

	// DI
	property name="aiService" inject="AIService@coldbox-cli";

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

			// Print info
			print.line();
			printInfo( "═══════════════════════════════════════════" );
			printInfo( "   AI Integration Info" );
			printInfo( "═══════════════════════════════════════════" );
			print.line();

			print.line( "coldbox-cli Version: #info.coldboxCliVersion#" );
			print.line( "Language Mode: #info.language#" );
			print.line( "Last Sync: #info.lastSync#" );
			print.line();

			// Guidelines
			printInfo( "Guidelines (#info.guidelines.len()#):" );
			if ( info.guidelines.len() ) {
				info.guidelines.each( function( guideline ){
					print.indentedLine( "  • #guideline.name# (from #guideline.source#)" );
				} );
			} else {
				print.indentedLine( "  No guidelines installed" );
			}
			print.line();

			// Skills
			printInfo( "Skills (#info.skills.len()#):" );
			if ( info.skills.len() ) {
				// Group by source
				var coreSkills   = info.skills.filter( function( s ){ return s.source == "core"; } );
				var moduleSkills = info.skills.filter( function( s ){ return s.source != "core"; } );

				if ( coreSkills.len() ) {
					print.indentedCyanLine( "  Core:" );
					coreSkills.each( function( skill ){
						print.indentedLine( "    ⭐ #skill.name#" );
					} );
				}

				if ( moduleSkills.len() ) {
					print.indentedCyanLine( "  Modules:" );
					moduleSkills.each( function( skill ){
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
					print.indentedLine( "  • #agent#" );
				} );
			} else {
				print.indentedLine( "  No agents configured" );
			}
			print.line();

			// Quick health check
			printInfo( "💡 Tip: Run 'coldbox ai doctor' for a detailed health check" );
			print.line();
		} catch ( any e ) {
			printError( "Failed to get AI integration info: #e.message#" );
			if ( shell.isDebug() ) {
				printError( e.stackTrace );
			}
		}
	}

}
