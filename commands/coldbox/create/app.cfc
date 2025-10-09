/**
 *  Create a blank ColdBox app from one of our app skeletons or a skeleton using a valid Endpoint ID which can come from .
 *  FORGEBOX, HTTP/S, git, github, etc.
 *  By default it will create the application in your current directory.
 * .
 * {code:bash}
 * coldbox create app myApp
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
			"flat"     : "cbtemplate-flat",
			"boxlang"     : "cbtemplate-boxlang",
			"modern"      : "cbtemplate-modern",
			"rest"        : "cbtemplate-rest",
			"rest-hmvc"   : "cbtemplate-rest-hmvc",
			"vite"        : "cbtemplate-vite",
			"supersimple" : "cbtemplate-supersimple"
		};

		variables.defaultAppName = "My ColdBox App";
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
	 * @vite 					Setup Vite for frontend asset building (For modern/boxlang apps only)
	 * @rest        Is this a REST API project? (For modern/boxlang apps only)
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
		boolean boxlang    = isBoxLangProject( getCWD() ),
		boolean docker = true,
		boolean vite = false,
		boolean rest = false
	){
		// Check for wizard argument
		if ( arguments.wizard ) {
			command( "coldbox create app-wizard" ).params( verbose = arguments.verbose ).run();
			return;
		}

		job.start( "🧑‍🍳 Creating & Prepping Your App [#arguments.name#]" );
		if ( arguments.verbose ) {
			job.setDumpLog( arguments.verbose );
		}

		// This will make the directory canonical and absolute
		arguments.directory = resolvePath( arguments.directory );
		// Validate directory, if it doesn't exist, create it.
		if ( !directoryExists( arguments.directory ) ) {
			directoryCreate( arguments.directory );
		}

		// If the skeleton = default and this is a boxlang project, then switch the skeleton to BoxLang
		if ( arguments.skeleton == "default" && arguments.boxlang ) {
			arguments.skeleton = variables.defaultSkeleton;
		}

		// If the skeleton is one of our "shortcut" names
		if ( variables.templateMap.keyExists( arguments.skeleton ) ) {
			// Replace it with the actual ForgeBox slug name.
			arguments.skeleton = variables.templateMap[ arguments.skeleton ];
		}

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
		}

		// Prepare language
		if ( arguments.boxlang ) {
			printInfo( "Setting language to BoxLang" );
			command( "package set" ).params( language: "BoxLang" ).run();
		} else {
			printInfo( "Setting language to CFML" );
			command( "package set" ).params( language: "CFML" ).run();
		}

		// Prepare defaults on box.json so we remove template based ones
		command( "package set" )
			.params(
				name    : arguments.name,
				slug    : variables.formatterUtil.slugify( arguments.name ),
				version : "1.0.0",
				location: "forgeboxStorage",
				ignore : []
			)
			.run();

		// set the server name if the user provided one
		printInfo( "🤖 Preparing server" );
		if ( arguments.name != defaultAppName ) {
			command( "server set" ).params( name = arguments.name ).run();
		}

		// ENV File
		var envFile = arguments.directory & ".env";
		if ( !fileExists( envFile ) ) {
			printInfo( "🌿 Creating .env file" );
			if( fileExists( arguments.directory & ".env.example" ) ){
				fileCopy( arguments.directory & ".env.example", envFile );
			} else {
				fileCopy( variables.settings.templatesPath & ".env.example", envFile );
			}
		} else {
			printInfo( "⏭️  .env file already exists, skipping creation." )
		}

		// Copilot instructions
		printInfo( "🤖 Preparing GitHub Copilot configuration" );
		var githubDir = arguments.directory & ".github";
		var copilotFile = githubDir & "/copilot-instructions.md";
		if( !directoryExists( githubDir ) ){
			directoryCreate( githubDir, true )
		}
		if( !fileExists( copilotFile ) ){
			printInfo( "🥊 Creating copilot file" )
			// If the template has a copilot-instructions.md, use it, otherwise use the default one
			if( fileExists( arguments.directory & "resources/copilot-instructions.md" ) ){
				fileCopy( arguments.directory & "resources/copilot-instructions.md", copilotFile );
			} else {
				if( arguments.skeleton == "modern" ){
					fileCopy( variables.settings.templatesPath & "modern-copilot-instructions.md", copilotFile );
				}
				else {
					fileCopy( variables.settings.templatesPath & "flat-copilot-instructions.md", copilotFile );
				}
			}
		} else{
			printInfo( "⏭️  copilot-instructions.md file already exists, skipping creation." )
		}

		// Run migrations init
		if ( arguments.migrations ) {
			printInfo( "🚀 Initializing Migrations" );
			variables.utility.ensureMigrationsModule();
			command( "migrate init" ).run();
			variables.print
				.line( "👉  You can run `migrate help` to see all available migration commands." )
				.toConsole();
		}

		if( arguments.docker ){
			printInfo( "🥊 Setting up Docker for containerization" )
			if( directoryExists( arguments.directory & "docker" ) ){
				printInfo( "⏭️  Docker directory already exists, skipping creation." )
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
					"#variables.settings.templatesPath#/docker/.dockerignore",
					arguments.directory & "docker/.dockerignore"
				)
				variables.print
					.line( "✅ Docker setup complete!" )
					.line( "👉  You can run 'box run-script docker:build' to build your Docker image." )
					.line( "👉  You can run 'box run-script docker:run' to run your Docker container." )
					.line( "👉  You can run 'box run-script docker:bash' to go into the container shell." )
					.line( "👉  You can run 'box run-script docker:stack' to startup the Docker Compose Stack" )
					.toConsole();
			}
		}

		// VITE Setup
		if( arguments.vite ){
			if( arguments.skeleton != "modern" && arguments.skeleton != "boxlang" ){
				printWarn( "⚠️  Vite setup is only supported for 'modern' or 'boxlang' skeletons. Skipping Vite setup." )
			} else {
				printInfo( "🥊 Setting up Vite for your frontend build system" )
				fileCopy( "#variables.settings.templatesPath#/vite/.babelrc", arguments.directory & ".babelrc" )
				fileCopy( "#variables.settings.templatesPath#/vite/package.json", arguments.directory & "package.json" )
				fileCopy( "#variables.settings.templatesPath#/vite/vite.config.mjs", arguments.directory & "vite.config.mjs" )
				fileDelete( arguments.directory & "app/layouts/Main.bxm" )
				fileCopy( "#variables.settings.templatesPath#/vite/layouts/Main.bxm", arguments.directory & "app/layouts/Main.bxm" )
				fileCopy( "#variables.settings.templatesPath#/vite/assets", arguments.directory & "resources/assets" )

				printInfo( "🥊 Installing ColdBox Vite Helpers" )
				command( "install" )
					.params( "vite-helpers" )
					.run();

				variables.print
					.line( "✅ Vite setup complete!" )
					.line( "👉  You can run 'npm install' to install the dependencies" )
					.line( "👉  You can run 'npm run dev' to start the development server" )
					.line( "👉  You can run 'npm run build' to build the production assets" )
					.toConsole();
			}
		}

		// REST Setup
		if( arguments.rest ){
			if( arguments.skeleton != "modern" && arguments.skeleton != "boxlang" ){
				printWarn( "⚠️  REST setup is only supported for 'modern' or 'boxlang' skeletons. Skipping REST setup." )
			} else {
				printInfo( "🥊 Setting up a REST API only ColdBox application" )
				printInfo( "👉  You can always add views and layouts later if you change your mind" )

				// Router
				fileDelete( arguments.directory & "app/config/Router.bx" )
				fileCopy( "#variables.settings.templatesPath#/rest/Router.bx", arguments.directory & "app/config/Router.bx" )
				// Tests
				directoryDelete( arguments.directory & "tests/specs", true )
				directoryCopy(
					source: "#variables.settings.templatesPath#/rest/specs",
					destination: arguments.directory & "tests/specs",
					recurse: true,
					createPath: true
				)
				// Configuration
				directoryCopy(
					source: "#variables.settings.templatesPath#/rest/config/modules",
					destination: arguments.directory & "app/config/modules",
					recurse: false,
					createPath: true
				)
				// Models
				directoryDelete( arguments.directory & "app/models", true )
				directoryCopy(
					source: "#variables.settings.templatesPath#/rest/models",
					destination: arguments.directory & "app/models",
					recurse: false,
					createPath: true
				)
				// Handlers
				directoryDelete( arguments.directory & "app/handlers", true )
				directoryCopy(
					source: "#variables.settings.templatesPath#/rest/handlers",
					destination: arguments.directory & "app/handlers",
					recurse: false,
					createPath: true
				)
				// Api Docs
				directoryCopy(
					source: "#variables.settings.templatesPath#/rest/apidocs",
					destination: arguments.directory & "resources/apidocs",
					recurse: true,
					createPath: true
				)
				var newConfig = fileRead( arguments.directory & "app/config/Coldbox.bx" )
					.replace( "Main.index", "Echo.index" )
					.replace( "Main.onException", "Echo.onError" );
				fileWrite( "app/config/Coldbox.bx", newConfig );

				// Install CommandBox Modules
				printInfo( "🥊 Installing ColdBox API Production Modules: Security, Mementifier, Validation" )
				command( "install" )
					.params( "cbsecurity,mementifier,cbvalidation" )
					.run();

				printInfo( "🥊 Installing ColdBox API Development Modules: route-visualizer,relax" )
				command( "install" )
					.params( "cbsecurity,mementifier,cbvalidation", "--saveDev" )
					.run();

				printInfo( "✅ REST API only setup complete!" )
			}
		}

		// Finalize Create app Job
		job.complete();

		variables.print
			.line( "🥊  Your ColdBox BoxLang application is ready to roll!" )
			.line( "👉  Run 'box server start' to launch the development server." )
			.line( "👉  Run 'box coldbox help' to see a list of available commands from the ColdBox CLI" )
			.line( "ℹ️. You can remove the [Setup.bx] file from your project now or keep it for future reference." )
			.line( "🗳️  Happy coding!" )
			.toConsole();
	}

	/**
	 * Returns an array of coldbox skeletons available
	 */
	function skeletonComplete(){
		return variables.templateMap.keyList().listToArray();
	}

}
