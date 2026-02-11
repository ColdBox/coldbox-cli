/**
 *  Create a blank ColdBox app from one of our app skeletons or a skeleton using a valid Endpoint ID which can come from .
 *  FORGEBOX, HTTP/S, git, github, etc.
 *  By default it will create a ColdBox BoxLang application in your current directory.
 * .
 * {code:bash}
 * coldbox create app myApp
 * // Same as
 * coldbox create app MyApp --boxlang
 * {code}
 * .
 *  Here are the basic skeletons that are available for you that come from FORGEBOX
 *
 *  - BoxLang (Default)
 *  - Modern (CFML + BoxLang Default)
 *  - flat (CFML + BoxLang Flat)
 *  - rest (CFML + BoxLang RESTful API)
 *  - rest-hmvc (HMVC + REST)
 *  - supersimple (bare bones)
 *  - vite (flat + vite)
 * .
 * {code:bash}
 * coldbox create app skeleton=modern
 * // Same as
 * coldbox create app --cfml
 * {code}
 * .
 * The skeleton parameter can also be any valid FORGEBOX Endpoint ID, which includes a Git repo or HTTP URL pointing to a package.
 * .
 * {code:bash}
 * coldbox create app skeleton=http://site.com/myCustomAppTemplate.zip
 * coldbox create app skeleton=coldbox-templates/rest
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
			"flat"        : "cbtemplate-flat",
			"boxlang"     : "cbtemplate-boxlang",
			"modern"      : "cbtemplate-modern",
			"rest"        : "cbtemplate-rest",
			"rest-hmvc"   : "cbtemplate-rest-hmvc",
			"vite"        : "cbtemplate-vite",
			"supersimple" : "cbtemplate-supersimple"
		};

		variables.defaultAppName  = "My ColdBox App";
		variables.defaultSkeleton = "boxlang";

		return this;
	}

	/**
	 * Create a new ColdBox application
	 *
	 * @name                The name of the app you want to create
	 * @skeleton            The name of the app skeleton to generate (or an endpoint ID like a forgebox slug)
	 * @skeleton.optionsUDF skeletonComplete
	 * @directory           The directory to create the app in
	 * @init                "init" the directory as a package if it isn't already
	 * @wizard              Run the ColdBox Creation wizard
	 * @initWizard          Run the init creation package wizard
	 * @verbose             Verbose output
	 * @migrations          Run migration init after creation
	 * @boxlang            Set the language to BoxLang
	 * @docker              Include Docker files and setup Docker configuration
	 * @vite 					Setup Vite for frontend asset building (For BoxLang or Modern apps only)
	 * @rest        Is this a REST API project? (For BoxLang apps only)
	 * @cfml        Set the language to CFML explicitly (overrides boxlang)
	 * @ai                  Enable AI integration for the application
	 * @aiAgent             The AI agent(s) to configure (claude, copilot, cursor, etc.), this can be a comma separated list for multiple agents, default is "claude"
	 **/
	function run(
		name               = defaultAppName,
		skeleton           = variables.defaultSkeleton,
		directory          = getCWD(),
		boolean init       = true,
		boolean wizard     = false,
		boolean initWizard = false,
		boolean verbose    = false,
		boolean migrations = false,
		boolean boxlang    = true,
		boolean docker     = false,
		boolean vite       = false,
		boolean rest       = false,
		boolean cfml       = false,
		boolean ai         = false,
		string aiAgent     = "claude"
	){
		// Check for wizard argument
		if ( arguments.wizard ) {
			command( "coldbox create app-wizard" ).params( verbose = arguments.verbose ).run();
			return;
		}

		// Show Big Colorful COLDBOX Banner
		showColdBoxBanner()

		// Start the job
		variables.print
			.boldGreenLine( "🔥 Starting to cookup your ColdBox App [#arguments.name#]..." )
			.line()
			.toConsole()

		// Determine language via cfml or boxlang flags
		if ( arguments.cfml ) {
			arguments.boxlang = false;
			if ( arguments.skeleton == variables.defaultSkeleton ) {
				arguments.skeleton = "modern";
			}
			printInfo( "⚡Language set to CFML" )
		} else {
			arguments.boxlang = true;
			printInfo( "🥊 Language set to BoxLang" )
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

		printInfo( "⬇️  Downloading [#arguments.skeleton#] template..." )

		variables.print.line().toConsole();

		// Install the skeleton from ForgeBox or other endpoint
		packageService.installPackage(
			ID                     : arguments.skeleton,
			directory              : arguments.directory,
			save                   : false,
			saveDev                : false,
			production             : false,
			currentWorkingDirectory: arguments.directory
		);

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
			printInfo( "🚀 ColdBox Application initialized as a CommandBox Package" )
		}

		printSuccess( "✅  Application scaffolded successfully!" )
		printInfo( "✏️  Setting Up Your box.json" )

		if ( arguments.boxlang ) {
			command( "package set" ).params( language: "BoxLang" ).run( returnOutput: true );
		} else {
			command( "package set" ).params( language: "CFML" ).run( returnOutput: true );
		}

		// Prepare defaults on box.json so we remove template based ones
		command( "package set" )
			.params(
				name       : arguments.name,
				slug       : variables.formatterUtil.slugify( arguments.name ),
				version    : "1.0.0",
				location   : "forgeboxStorage",
				ignore     : "[]",
				description: "A ColdBox Application created with the ColdBox CLI"
			)
			.run( returnOutput: true );

		// set the server name if the user provided one
		variables.print.line().toConsole();
		printInfo( "📡  Preparing server and support files" );
		command( "server set" ).params( name: arguments.name ).run( returnOutput:true );

		// ENV File
		var envFile = arguments.directory & ".env";
		if ( !fileExists( envFile ) ) {
			printInfo( "🌿 Creating your .env file" );
			if ( fileExists( arguments.directory & ".env.example" ) ) {
				fileCopy(
					arguments.directory & ".env.example",
					envFile
				);
			} else {
				fileCopy(
					variables.settings.templatesPath & "env.example",
					envFile
				);
			}
		} else {
			printWarn( "⏭️  .env file already exists, skipping creation." )
		}

		// Run migrations init
		if ( arguments.migrations ) {
			printInfo( "🚀 Initializing Migrations" );
			variables.utility.ensureMigrationsModule();
			command( "migrate init" ).run();
			printHelp( "👉  You can run `migrate help` to see all available migration commands" )
		}

		if ( arguments.docker ) {
			printInfo( "🥊 Setting up Docker for containerization" )
			if ( directoryExists( arguments.directory & "docker" ) ) {
				printWarn( "⏭️  Docker directory already exists, skipping creation." )
			} else {
				directoryCreate( arguments.directory & "docker", true )
				fileCopy(
					"#variables.settings.templatesPath#/docker/Dockerfile",
					arguments.directory & "docker/Dockerfile"
				)
				fileCopy(
					"#variables.settings.templatesPath#/docker/docker-compose.yml",
					arguments.directory & "docker/docker-compose.yml"
				)
				fileCopy(
					"#variables.settings.templatesPath#/docker/dockerignore",
					arguments.directory & "docker/.dockerignore"
				)

				printSuccess( "✅ Docker setup complete!" )
				printHelp( "👉  You can run 'box run-script docker:build' to build your Docker image." )
				printHelp( "👉  You can run 'box run-script docker:run' to run your Docker container." )
				printHelp( "👉  You can run 'box run-script docker:bash' to go into the container shell." )
				printHelp( "👉  You can run 'box run-script docker:stack' to startup the Docker Compose Stack" )
				variables.print.line().toConsole()
			}
		}

		// VITE Setup
		if ( arguments.vite ) {
			if ( !arguments.skeleton.reFindNoCase( "(modern|boxlang)" ) ) {
				printWarn( "⚠️  Vite setup is only supported for 'modern' or 'boxlang' skeletons. Skipping Vite setup." )
			} else {
				printInfo( "🥊 Setting up Vite for your frontend build system" )
				fileCopy(
					"#variables.settings.templatesPath#/vite/babelrc",
					arguments.directory & ".babelrc"
				)
				fileCopy(
					"#variables.settings.templatesPath#/vite/package.json",
					arguments.directory & "package.json"
				)
				fileCopy(
					"#variables.settings.templatesPath#/vite/vite.config.mjs",
					arguments.directory & "vite.config.mjs"
				)

				// BoxLang Layout
				// Detect if they ar in BoxLang or CFML mode
				if ( fileExists( arguments.directory & "app/layouts/Main.bxm" ) ) {
					fileDelete( arguments.directory & "app/layouts/Main.bxm" )
					fileCopy(
						"#variables.settings.templatesPath#/vite/layouts/Main.bxm",
						arguments.directory & "app/layouts/Main.bxm"
					)
				}

				// CFML Layout
				// Detect if they ar in BoxLang or CFML mode
				if ( fileExists( arguments.directory & "app/layouts/Main.cfm" ) ) {
					fileDelete( arguments.directory & "app/layouts/Main.cfm" )
					fileCopy(
						"#variables.settings.templatesPath#/vite/layouts/Main.cfm",
						arguments.directory & "app/layouts/Main.cfm"
					)
				}

				directoryCopy(
					"#variables.settings.templatesPath#/vite/assets",
					arguments.directory & "resources/assets",
					true
				)

				printInfo( "🥊 Installing ColdBox Vite Helpers" )
				command( "install" ).params( "vite-helpers" ).run();
				printSuccess( "✅ Vite setup complete!" )
				printHelp( "👉  You can run 'npm install' to install the dependencies" )
				printHelp( "👉  You can run 'npm run dev' to start the development server" )
				printHelp( "👉  You can run 'npm run build' to build the production assets" )
				variables.print.line().toConsole();
			}
		}
		// REST Setup
		if ( arguments.rest ) {
			if ( !arguments.skeleton.reFindNoCase( "(boxlang)" ) ) {
				printWarn( "⚠️  REST setup is only supported for 'boxlang' skeletons. Skipping REST setup." )
			} else {
				printInfo( "🥊 Setting up a REST API only ColdBox application" )
				// Router
				fileDelete( arguments.directory & "app/config/Router.bx" )
				fileCopy(
					"#variables.settings.templatesPath#/rest/Router.bx",
					arguments.directory & "app/config/Router.bx"
				)
				// Tests
				directoryDelete(
					arguments.directory & "tests/specs",
					true
				)
				directoryCopy(
					source     : "#variables.settings.templatesPath#/rest/specs",
					destination: arguments.directory & "tests/specs",
					recurse    : true,
					createPath : true
				)
				// Configuration
				directoryCopy(
					source     : "#variables.settings.templatesPath#/rest/config/modules",
					destination: arguments.directory & "app/config/modules",
					recurse    : false,
					createPath : true
				)
				// Models
				directoryDelete(
					arguments.directory & "app/models",
					true
				)
				directoryCopy(
					source     : "#variables.settings.templatesPath#/rest/models",
					destination: arguments.directory & "app/models",
					recurse    : false,
					createPath : true
				)
				// Handlers
				directoryDelete(
					arguments.directory & "app/handlers",
					true
				)
				directoryCopy(
					source     : "#variables.settings.templatesPath#/rest/handlers",
					destination: arguments.directory & "app/handlers",
					recurse    : false,
					createPath : true
				)
				// Api Docs
				directoryCopy(
					source     : "#variables.settings.templatesPath#/rest/apidocs",
					destination: arguments.directory & "resources/apidocs",
					recurse    : true,
					createPath : true
				)
				var newConfig = fileRead( arguments.directory & "app/config/Coldbox.bx" )
					.replace( "Main.index", "Echo.index" )
					.replace( "Main.onException", "Echo.onError" );
				fileWrite(
					arguments.directory & "app/config/Coldbox.bx",
					newConfig
				);

				// Get the server.json : server show scripts.onServerInitialInstall so we can append to it and set it back
				var originalServerInstall = command( "server show" )
					.params( property: "scripts.onServerInitialInstall" )
					.run( returnOutput=true  )

				printInfo( "🥊  Original " & originalServerInstall )
				// Now call server set to append: ,bx-compat-cfml
				command( "server set" )
					.params(
						"scripts.onServerInitialInstall" : originalServerInstall & ",bx-compat-cfml"
					)
					.run();

				// Install CommandBox Modules
				printInfo( "🥊 Installing ColdBox API Production Modules: Security, Mementifier, Validation" )
				command( "install" ).params( "cbsecurity,mementifier,cbvalidation" ).run();

				printInfo( "🥊 Installing ColdBox API Development Modules: route-visualizer,relax" )
				command( "install" )
					.params( "route-visualizer,relax" )
					.flags( "saveDev" )
					.run();

				printSuccess( "✅ REST API setup complete!" )
			}
		}

		// REST Cleanup
		if ( directoryExists( arguments.directory & "resources/rest" ) ) {
			directoryDelete(
				arguments.directory & "resources/rest",
				true
			)
		}

		// Vite Cleanup
		if ( !arguments.vite && directoryExists( arguments.directory & "resources/assets" ) ) {
			directoryDelete(
				arguments.directory & "resources/assets",
				true
			)
		}

		if ( directoryExists( arguments.directory & "resources/vite" ) ) {
			directoryDelete(
				arguments.directory & "resources/vite",
				true
			)
		}

		// Docker Cleanup
		if ( directoryExists( arguments.directory & "resources/docker" ) ) {
			directoryDelete(
				arguments.directory & "resources/docker",
				true
			)
		}

		// AI Integration Setup
		if ( arguments.ai ) {
			printInfo( "🤖 Setting up AI integration..." )

			// Determine language from skeleton and flags
			var language = arguments.boxlang ? "boxlang" : "cfml"

			command( "coldbox ai install" )
				.params(
					agent    = arguments.aiAgent,
					language  = language,
					directory = arguments.directory,
					showBanner = false
				)
				.run()
		}

	}

	/**
	 * Returns an array of coldbox skeletons available
	 */
	function skeletonComplete(){
		return variables.templateMap.keyList().listToArray();
	}

}
