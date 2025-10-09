/**
 *  Create a blank ColdBox app from one of our app skeletons by following our lovely wizard.
 **/
component extends="app" aliases="" {

	/**
	 * @name     The name of the app you want to create
	 * @skeleton The application skeleton you want to use
	 * @init     Init this as a package
	 * @boxlang  Is this a BoxLang project?
	 **/
	function run(
		required name,
		skeleton,
		boolean boxlang = isBoxLangProject( getCWD() )
	){
		arguments.directory = getCWD();
		if ( !confirm( "Are you currently inside the ""/#name#"" folder (if ""No"" we will create it)? [y/n]" ) ) {
			arguments.directory = getCWD() & name & "/";
			if ( !directoryExists( arguments.directory ) ) {
				directoryCreate( arguments.directory );
			}
			shell.cd( arguments.directory );
		}

		print.boldgreenline(
			"------------------------------------------------------------------------------------------"
		);
		print.boldgreenline( "Files will be installed in the " & arguments.directory & " directory" );
		print.boldgreenline(
			"------------------------------------------------------------------------------------------"
		);

		if ( confirm( "Are you creating an API? [y/n]" ) ) {
			print.boldgreenline(
				"------------------------------------------------------------------------------------------"
			);
			print.boldgreenline( "We have 2 different API template options" );
			print.boldgreenline(
				"Both include the modules: cbsecurity, cbvalidation, mementifier, relax, & route-visualizer"
			);
			print.boldgreenline(
				"------------------------------------------------------------------------------------------"
			);

			arguments.skeleton = multiselect( "Which template would you like to use?" )
				.options( [
					{
						accessKey : 1,
						display   : "Modular (API/REST) Template - provides an ""api"" module with a ""v1"" sub-module within it",
						value     : "rest-hmvc",
						selected  : true
					},
					{
						accessKey : 2,
						display   : "Simple (API/REST) Template - provides api endpoints via the handlers/ folder",
						value     : "rest"
					}
				] )
				.required()
				.ask();
		} else {
			print.boldgreenline(
				"------------------------------------------------------------------------------------------",
				true
			);
			print.greenline( "We have a few different Non-API template options" );
			print.greenline( "No default modules are installed for these templates" );
			print.boldgreenline(
				"------------------------------------------------------------------------------------------"
			);

			arguments.skeleton = multiselect( "Which template would you like to use?" )
				.options( [
					{
						accessKey : 1,
						value     : "boxlang",
						display   : "BoxLang ColdBox Template - Default ColdBox App with BoxLang",
						selected  : true
					},
					{
						accessKey : 2,
						value     : "modern",
						display   : "Modern Template - Security-first CFML and BoxLang template with /app outside webroot"
					},
					{
						accessKey : 3,
						value     : "flat",
						display   : "Flat Template - Traditional flat structure with everything in webroot"
					},
					{
						accessKey : 4,
						value     : "vite",
						display   : "Vite Template - Traditional flat structure development with Vite, Vue 3, and Tailwind CSS"
					},
					{
						accessKey : 5,
						value     : "supersimple",
						display   : "Super Simple Template - Bare bones, minimal starting point"
					}
				] )
				.required()
				.ask();
		}
		print.line( "Creating your site..." ).toConsole();

		var skeletons        = skeletonComplete();
		// turn off wizard
		arguments.wizard     = false;
		arguments.initWizard = true;

		if ( !arguments.skeleton.len() ) {
			// Remove if empty so it can default correctly
			arguments.delete( "skeleton" );
		}

		super.run( argumentCollection = arguments );
	}

}
