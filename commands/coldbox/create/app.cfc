/**
 *  Create a blank ColdBox app from one of our app skeletons or a skeleton using a valid Endpoint ID which can come from .
 *  ForgeBox, HTTP/S, git, github, etc.
 *  By default it will create the application in your current directory.
 * .
 * {code:bash}
 * coldbox create app myApp
 * {code}
 * .
 *  Here are the basic skeletons that are available for you that come from ForgeBox
 *  - BoxLang
 *  - Default (default)
 *  - Elixir
 *  - Modern
 *  - rest
 *  - rest-hmvc
 *  - SuperSimple
 *  - Vite
 * .
 * {code:bash}
 * coldbox create app skeleton=rest
 * {code}
 * .
 * The skeleton parameter can also be any valid FORGEBOX Endpoint ID, which includes a Git repo or HTTP URL pointing to a package.
 * .
 * {code:bash}
 * coldbox create app skeleton=http://site.com/myCustomAppTemplate.zip
 * coldbox create app skeleton=coldbox-templates/modern
 * {code}
 *
 **/
component extends="coldbox-cli.models.BaseCommand" {

	// DI
	property name="packageService" inject="PackageService";

	/**
	 * Constructor
	 */
	function init(){
		// Map these shortcut names to the actual ForgeBox slugs
		variables.templateMap = {
			"Default"     : "cbtemplate-advanced-script",
			"BoxLang"     : "cbtemplate-bx-default",
			"Elixir"      : "cbtemplate-elixir",
			"modern"      : "cbtemplate-modern",
			"rest"        : "cbtemplate-rest",
			"rest-hmvc"   : "cbtemplate-rest-hmvc",
			"Vite"        : "cbtemplate-vite",
			"SuperSimple" : "cbtemplate-supersimple"
		};

		variables.defaultAppName = "My ColdBox App";

		return this;
	}

	/**
	 * @name                The name of the app you want to create
	 * @skeleton            The name of the app skeleton to generate (or an endpoint ID like a forgebox slug)
	 * @skeleton.optionsUDF skeletonComplete
	 * @directory           The directory to create the app in
	 * @init                "init" the directory as a package if it isn't already
	 * @wizard              Run the ColdBox Creation wizard
	 * @initWizard          Run the init creation package wizard
	 * @verbose             Verbose output
	 * @migrations          Run migration init after creation
	 **/
	function run(
		name               = defaultAppName,
		skeleton           = "default",
		directory          = getCWD(),
		boolean init       = true,
		boolean wizard     = false,
		boolean initWizard = false,
		boolean verbose    = false,
		boolean migrations = false
	){
		// Check for wizard argument
		if ( arguments.wizard ) {
			command( "coldbox create app-wizard" ).params( verbose = arguments.verbose ).run();
			return;
		}

		job.start( "Creating App [#arguments.name#]" );

		if ( arguments.verbose ) {
			job.setDumpLog( arguments.verbose );
		}

		// This will make the directory canonical and absolute
		arguments.directory = resolvePath( arguments.directory );

		// Validate directory, if it doesn't exist, create it.
		if ( !directoryExists( arguments.directory ) ) {
			directoryCreate( arguments.directory );
		}

		// If the skeleton is one of our "shortcut" names
		if ( variables.templateMap.keyExists( arguments.skeleton ) ) {
			// Replace it with the actual ForgeBox slug name.
			arguments.skeleton = variables.templateMap[ arguments.skeleton ];
		}

		// Install the skeleton
		packageService.installPackage(
			ID                     : arguments.skeleton,
			directory              : arguments.directory,
			save                   : false,
			saveDev                : false,
			production             : false,
			currentWorkingDirectory: arguments.directory
		);

		job.start( "Preparing box.json" );

		// Init, if not a package as a Box Package
		if ( arguments.init && !packageService.isPackage( arguments.directory ) ) {
			var originalPath = getCWD();
			// init must be run from CWD
			shell.cd( arguments.directory );
			command( "init" )
				.params(
					name  : arguments.name,
					slug  : replace( arguments.name, " ", "", "all" ),
					wizard: arguments.initWizard
				)
				.run();
			shell.cd( originalPath );
		}

		// Prepare language
		if ( arguments.boxlang ) {
			command( "package set" ).params( language: "BoxLang" ).run();
		}

		// Prepare defaults on box.json so we remove template based ones
		command( "package set" )
			.params(
				name    : arguments.name,
				slug    : variables.formatterUtil.slugify( arguments.name ),
				version : "1.0.0",
				location: "forgeboxStorage"
			)
			.run();

		job.complete();

		// set the server name if the user provided one
		if ( arguments.name != defaultAppName ) {
			job.start( "Preparing server.json" );
			command( "server set" ).params( name = arguments.name ).run();
			job.complete();
		}

		// Finalize Create app Job
		job.complete();

		// Run migrations init
		if ( arguments.migrations ) {
			variables.utility.ensureMigrationsModule();
			command( "migrate init" ).run();
		}
	}

	/**
	 * Returns an array of coldbox skeletons available
	 */
	function skeletonComplete(){
		return variables.templateMap.keyList().listToArray();
	}

}
