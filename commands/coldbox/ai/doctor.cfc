/**
 * Diagnose AI integration health
 * Checks configuration, guidelines, skills, and agent files for issues
 *
 * Examples:
 * coldbox ai doctor
 * coldbox ai doctor --verbose
 * coldbox ai doctor --json
 */
component extends="coldbox-cli.models.BaseAICommand" {

	/**
	 * Run the command
	 *
	 * @verbose Show detailed diagnostic information
	 * @json Output results as JSON
	 * @directory The target directory (defaults to current directory)
	 */
	function run(
		boolean verbose  = false,
		boolean json     = false,
		string directory = getCwd()
	){
		showColdBoxBanner( "🏥 AI Doctor 🏥" );
		try {
			var diagnosis = variables.aiService.diagnose( arguments.directory )

			// JSON output
			if ( arguments.json ) {
				print.line( serializeJSON( diagnosis ) )
				return
			}

			// Pretty console output
			printDiagnosisReport( diagnosis, arguments.verbose )
		} catch ( any e ) {
			printError( "Failed to diagnose AI integration: #e.message#" )
			printError( e.stackTrace )
		}
	}

	/**
	 * Print diagnosis report to console
	 *
	 * @diagnosis The diagnosis struct
	 * @verbose Show detailed diagnostic information
	 */
	private function printDiagnosisReport( required struct diagnosis, boolean verbose = false ){
		// Errors
		if ( diagnosis.errors.len() ) {
			print.redLine( "❌ Errors (#diagnosis.errors.len()#)" );
			diagnosis.errors.each( function( error ){
				print.indentedRedLine( "  • #error#" );
			} );
			print.line();
		} else {
			print.greenLine( "✓ No Errors" );
			print.line();
		}

		// Warnings
		if ( diagnosis.warnings.len() ) {
			print.yellowLine( "⚠ Warnings (#diagnosis.warnings.len()#)" );
			diagnosis.warnings.each( function( warning ){
				print.indentedYellowLine( "  • #warning#" );
			} );
			print.line();
		} else {
			print.greenLine( "✓ No Warnings" );
			print.line();
		}

		// Recommendations
		if ( diagnosis.recommendations.len() ) {
			print.cyanLine( "💡 Recommendations:" );
			diagnosis.recommendations.each( function( recommendation ){
				print.indentedLine( "  • #recommendation#" );
			} );
			print.line();
		}

		// Ensure summary exists with default values
		if ( !structKeyExists( diagnosis, "summary" ) || !structKeyExists( diagnosis.summary, "status" ) ) {
			diagnosis.summary = {
				"status"              : diagnosis.errors.len() ? "error" : ( diagnosis.warnings.len() ? "warning" : "good" ),
				"errorCount"          : diagnosis.errors.len(),
				"warningCount"        : diagnosis.warnings.len(),
				"recommendationCount" : diagnosis.recommendations.len()
			}
		}
		var status = diagnosis.summary.status;
		var statusEmoji = {
			"good"    : "🟢",
			"warning" : "🟡",
			"error"   : "🔴"
		};

		var statusText = {
			"good"    : "Good",
			"warning" : "Needs Attention",
			"error"   : "Critical"
		};

		var statusColor = {
			"good"    : "green",
			"warning" : "yellow",
			"error"   : "red"
		};

		print.table(
			headerNames = [ "Metric", "Value" ],
			data = [
				[
					"Overall Status",
					{ value : "#statusEmoji[ status ]# #statusText[ status ]#", options : statusColor[ status ] }
				],
				[ "Errors", diagnosis.summary.errorCount ],
				[ "Warnings", diagnosis.summary.warningCount ],
				[ "Recommendations", diagnosis.summary.recommendationCount ]
			]
		);
		print.line();

		// Status-based message
		if ( status == "good" ) {
			printSuccess( "✓ Your AI integration is healthy!" );
		} else if ( status == "warning" ) {
			printWarn( "⚠ Your AI integration has some issues that should be addressed." );
		} else {
			printError( "❌ Your AI integration has critical errors that must be fixed." );
		}

		print.line();
	}

}
