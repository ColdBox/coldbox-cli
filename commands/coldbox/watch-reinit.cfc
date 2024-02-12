/**
 * Watch the files in a directory and run the default Coldbox reinit on any file change.
 *
 * {code}
 * coldbox watch-reinit
 * {code}
 *
 * In order for this command to work, you need to have started your server.
 *
 * {code}
 * server start
 * coldbox watch-reinit password="mypass"
 * {code}
 *
 * If you need more control over what files reinit the framework, you can set additional options in your box.json
 * which will be picked up automatically by "coldbox watch-reinit" when it fires.
 *
 * {code}
 * package set reinitWatchDelay=1000
 * package set reinitWatchPaths= "config/**.cfc,handlers/**.cfc,models/**.cfc,ModuleConfig.cfc"
 * {code}
 *
 * This command will run in the foreground until you stop it.  When you are ready to shut down the watcher, press Ctrl+C.
 *
 **/
component {

	// DI
	property name="packageService" inject="PackageService";
	property name="serverService"  inject="ServerService";

	variables.WATCH_DELAY = 500;
	variables.PATHS       = "/config/**.cfc,/handlers/**.cfc,/models/**.cfc,/modules_app/**/*.cfc";

	/**
	 * @paths    Command delimited list of file globbing paths to watch relative to the working directory, defaults to **.cfc
	 * @delay    How may milliseconds to wait before polling for changes, defaults to 500 ms
	 * @password Reinit password
	 **/
	function run(
		string paths,
		number delay,
		string password = "1"
	){
		// Get watch options from package descriptor
		var boxOptions   = packageService.readPackageDescriptor( getCWD() );
		var initPassword = arguments.password;

		var getOptionsWatchers = function(){
			// Return to List
			if ( boxOptions.keyExists( "reinitWatchPaths" ) && boxOptions.reinitWatchPaths.len() ) {
				return (
					isArray( boxOptions.reinitWatchPaths ) ? boxOptions.reinitWatchPaths.toList() : boxOptions.reinitWatchPaths
				);
			}
			// should return null if not found
			return;
		}

		// Determine watching patterns, either from arguments or boxoptions or defaults
		var globbingPaths = arguments.paths ?: getOptionsWatchers() ?: variables.PATHS;
		// handle non numeric config and put a floor of 150ms
		var delayMs       = max(
			val( arguments.delay ?: boxOptions.reinitWatchDelay ?: variables.WATCH_DELAY ),
			150
		);
		var statusColors = {
			"added"   : "green",
			"removed" : "red",
			"changed" : "yellow"
		}
		var serverDetails = serverService.resolveServerDetails( {} );
		var serverStatus  = serverService.isServerRunning( serverDetails.serverInfo );

		// Tabula rasa
		command( "cls" ).run();


		// Check if the server is up, prompt if not to start it
		if ( !serverStatus ) {
			print
				.redBoldText( "Server Status: Stopped" )
				.line()
				.toConsole();
			var startServer = confirm( "Would you like to start it [y/n]?" );
			if ( startServer ) {
				command( "start" ).run();
			} else {
				return;
			}
		}

		// General Message about the globbing paths and its purpose
		print
			.greenLine( "---------------------------------------------------" )
			.greenLine( "Watching the following files for a framework reinit" )
			.greenLine( "---------------------------------------------------" )
			.greenLine( " " & globbingPaths )
			.greenLine( " Press Ctrl-C to exit " )
			.greenLine( "---------------------------------------------------" )
			.toConsole();

		// Start watcher
		watch()
			.paths( globbingPaths.listToArray() )
			.inDirectory( getCWD() )
			.withDelay( delayMs )
			.onChange( function( changeData ){
				// output file changes
				var changetime = "[" & timeFormat( now(), "HH:mm:ss" ) & "] ";
				for ( status in changeData ) {
					changeData[ status ].map( function( filePath ){
						print
							.text( changetime, statusColors[ status ] )
							.text(
								filePath,
								statusColors[ status ] & "Bold"
							)
							.text(
								" " & status & " ",
								statusColors[ status ]
							)
							.toConsole();
					} )
				}

				// reinit the framework
				command( "coldbox reinit password=""#initPassword#"" showUrl=""false""" ).run();
			} )
			.start();
	}

}
