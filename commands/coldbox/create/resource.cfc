/**
 * Generate resourceful routing by generating a handler, model, services and even modularizing it.
 * .
 * Make sure you are running this command in the root of your app for it to find the correct folder.
 * .
 * The following would create a `photos` handler with the following actions:
 * - `/photos` : `GET` -> `photos.index` Display a list of photos
 * - `/photos/new` : `GET` -> `photos.new` Returns an HTML form for creating a new photo
 * - `/photos` : `POST` -> `photos.create` Create a new photo
 * - `/photos/:id` : `GET` -> `photos.show` Display a specific photo
 * - `/photos/:id/edit` : `GET` -> `photos.edit` Return an HTML form for editing a photo
 * - `/photos/:id` : `POST/PUT/PATCH` -> `photos.update` Update a specific photo
 * - `/photos/:id` : `DELETE` -> `photos.delete` Delete a specific photo
 * {code:bash}
 * // Basic
 * coldbox create resource photos
 * // Many resource
 * coldbox create resource photos,users,categories
 * // Custom Handler
 * coldbox create resource photos myPhoto
 * coldbox create resource resource=photos handler=myPhoto
 * // ORM Enabled
 * coldbox create resource resource=photos singularName=Photo --persistent
 * {code}
 *
 */
component extends="coldbox-cli.models.BaseCommand"{

	// STATIC Actions we use in the resources
	variables.ACTIONS = [
		"index",
		"new",
		"create",
		"show",
		"edit",
		"update",
		"delete"
	];

	// STATIC Actions we use in the resources
	variables.API_ACTIONS = [ "index", "create", "show", "update", "delete" ];

	/**
	 * @resource          The name of a single resource or a list of resources to generate
	 * @handler           The handler for the resource. Defaults to the resource name, only works when using one resource
	 * @singularName      The singular name of the resource, else we use the resource name
	 * @parameterName     The name of the id/parameter for the resource. Defaults to `id`.
	 * @module            If passed, the module these resources will be created in.
	 * @appMapping        The root location of the application in the web root: ex: /MyApp or / if in the root
	 * @model             The name of the model to generate that models the resource
	 * @persistent        If true, then the model will be created as an ORM entity
	 * @table             The table name of the entity
	 * @activeEntity      Generate a ColdBox ORM Active entity instead of a Normal CFML entity.
	 * @primaryKey        Enter the name of the primary key, defaults to 'id'
	 * @primaryKeyColumn  Enter the name of the primary key column. Leave empty if same as the primaryKey value
	 * @generator         Enter the ORM key generator to use, defaults to 'native'
	 * @generator.options increment,identity,sequence,native,assigned,foreign,seqhilo,uuid,guid,select,sequence-identity
	 * @properties        Enter a list of properties to generate. You can add the ORM type via colon separator, default type is string. Ex: firstName,age:numeric,createdate:timestamp
	 * @modulesDirectory  The location of the modules. Defaults to 'modules'
	 * @handlersDirectory The location of the handlers. Defaults to 'handlers'
	 * @viewsDirectory    The location of the views. Defaults to 'views'
	 * @modelsDirectory   The location of the models. Defaults to 'models'
	 * @tests             Generate the integration and unit tests for this generation
	 * @specsDirectory    Your specs directory. Only used if tests is true
	 * @api               If true, this will generate api resources, else normal html resources
	 * @force             Force the generation of the resource, even if it exists
	 */
	function run(
		required resource,
		handler              = arguments.resource,
		singularName         = "",
		parameterName        = "id",
		module               = "",
		appMapping           = "/",
		model                = arguments.resource,
		persistent           = false,
		table                = "",
		boolean activeEntity = false,
		primaryKey           = "id",
		primaryKeyColumn     = "",
		generator            = "native",
		properties           = "",
		modulesDirectory     = "modules_app",
		handlersDirectory    = "handlers",
		viewsDirectory       = "views",
		modelsDirectory      = "models",
		boolean tests        = true,
		specsDirectory       = "tests/specs",
		boolean api          = false,
		boolean force        = false,
		boolean migration    = false,
		boolean seeder       = false
	){
		// Normalize paths
		arguments.specsDirectory   = resolvePath( arguments.specsDirectory );
		arguments.modulesDirectory = resolvePath( arguments.modulesDirectory );
		var configPath             = resolvePath( "config" );

		// Convert plural to singluar if not passed, resources are always plural
		if ( !arguments.singularName.len() ) {
			arguments.singularName = variables.utility.singularize( arguments.resource );
		}

		/********************** Verify Module pathing or global app pathing ************************/

		var modulePath = arguments.modulesDirectory & arguments.module;
		if ( arguments.module.len() ) {
			// Check if module exists, if not, ask to create it first.
			if (
				!directoryExists( modulePath ) && !arguments.force && confirm(
					"The module '#arguments.module#' does not exist, should we create it for you?"
				)
			) {
				printInfo( "Generating (#arguments.module#) module..." );
				command( "coldbox create module" )
					.params( name = arguments.module, directory = arguments.modulesDirectory )
					.run();
			}
			arguments.handlersDirectory = modulePath & "/" & arguments.handlersDirectory & "/";
			arguments.viewsDirectory    = modulePath & "/" & arguments.viewsDirectory & "/";
			arguments.modelsDirectory   = modulePath & "/" & arguments.modelsDirectory & "/";
		} else {
			arguments.handlersDirectory = resolvePath( arguments.handlersDirectory );
			arguments.viewsDirectory    = resolvePath( arguments.viewsDirectory );
			arguments.modelsDirectory   = resolvePath( arguments.modelsDirectory );
		}

		/********************** GENERATE HANDLER ************************/

		printInfo( "Generating (#arguments.resource#) resources..." );

		// Read in Template
		var hContent = arguments.api ? fileRead(
			"#variables.settings.templatesPath#/resources/ApiHandlerContent.txt"
		) : fileRead( "#variables.settings.templatesPath#/resources/HandlerContent.txt" );
		// Token replacement
		hContent = replaceNoCase(
			hContent,
			"|resource|",
			arguments.resource,
			"all"
		);
		hContent = replaceNoCase(
			hContent,
			"|singularName|",
			arguments.singularName,
			"all"
		);
		hContent = replaceNoCase(
			hContent,
			"|parameterName|",
			arguments.parameterName,
			"all"
		);
		// Module Injection
		if ( arguments.module.len() ) {
			hContent = replaceNoCase(
				hContent,
				"inject",
				"inject=""#arguments.resource#Service@#arguments.module#""",
				"all"
			);
		}

		// Write Out Handler
		var hpath = "#arguments.handlersDirectory#/#arguments.handler#.cfc";
		// Create dir if it doesn't exist
		directoryCreate( getDirectoryFromPath( hpath ), true, true );

		// Confirm it
		if (
			fileExists( hpath ) && !arguments.force && !confirm(
				"The file '#getFileFromPath( hpath )#' already exists, overwrite it (y/n)?"
			)
		) {
			printWarn( "Exiting..." );
			return;
		}
		file action="write" file="#hpath#" mode="777" output="#hContent#";
		printInfo( "--> Generated (#arguments.resource#) Handler: [#hPath#]" );

		// ********************** generate views ************************************//

		if ( !arguments.api ) {
			var views = [ "new", "edit", "show", "index" ].each( ( view ) => {
				command( "coldbox create view" )
					.params(
						name     : resource & "/" & arguments.view,
						content  : "<h1>#resource#.#arguments.view#</h1>",
						directory: viewsDirectory,
						force    : force,
						open     : open
					)
					.run();
			} );
		}

		// ********************** generate test cases ************************************//

		printInfo( "--> Generating integration tests..." );
		command( "coldbox create integration-test" )
			.params(
				handler   : arguments.handler,
				actions   : arguments.api ? variables.API_ACTIONS.toList() : variables.ACTIONS.toList(),
				appMapping: arguments.appMapping,
				directory : arguments.specsDirectory & "/integration",
				force     : arguments.force
			)
			.run();

		// ********************** generate model ************************************//

		// Generate an ORM Entity
		if ( arguments.persistent ) {
			printInfo( "--> Generating ORM resource model (#arguments.singularName#)" );
			command( "coldbox create orm-entity" )
				.params(
					entityName      : ucFirst( arguments.singularName ),
					table           : arguments.table,
					activeEntity    : arguments.activeEntity,
					primaryKey      : arguments.primaryKey,
					primaryKeyColumn: arguments.primaryKeyColumn,
					generator       : arguments.generator,
					properties      : arguments.properties,
					directory       : arguments.modelsDirectory,
					testsDirectory  : arguments.specsDirectory & "/unit",
					migration       : arguments.migration,
					seeder          : arguments.seeder,
					force           : arguments.force
				)
				.run();

			printInfo( "--> Generating ORM Virtual Service (#arguments.singularName#)" );
			command( "coldbox create orm-virtual-service" )
				.params(
					entityName    : arguments.singularName,
					directory     : arguments.modelsDirectory,
					testsDirectory: arguments.specsDirectory & "/unit",
					force         : arguments.force
				)
				.run();
		} else {
			printInfo( "--> Generating resource model (#arguments.singularName#)" );
			// Generate model
			command( "coldbox create model" )
				.params(
					name          : ucFirst( arguments.singularName ),
					description   : "I model a #arguments.singularName#",
					properties    : arguments.properties,
					directory     : arguments.modelsDirectory,
					testsDirectory: arguments.specsDirectory & "/unit",
					migration     : arguments.migration,
					seeder        : arguments.seeder,
					force         : arguments.force
				)
				.run();

			// Generate Service
			printInfo( "--> Generating resource service (#arguments.resource#Service)" );
			command( "coldbox create model" )
				.params(
					name          : ucFirst( arguments.resource ) & "Service",
					persistence   : "singleton",
					description   : "I manage #arguments.singularName#",
					methods       : "save,delete,list,get",
					directory     : arguments.modelsDirectory,
					testsDirectory: arguments.specsDirectory & "/unit",
					force         : arguments.force
				)
				.run();
		}

		// ********************** generate resources ************************************//

		// Generate code
		var routerCode = "// @app_routes@#variables.utility.BREAK##variables.utility.BREAK#";
		if ( arguments.resource == arguments.handler ) {
			if ( arguments.parameterName == "id" ) {
				routerCode &= repeatString( variables.utility.TAB, 2 ) & (
					arguments.api ? "apiResources" : "resources"
				) & "( ""#arguments.resource#"" )";
			} else {
				routerCode &= repeatString( variables.utility.TAB, 2 ) & (
					arguments.api ? "apiResources" : "resources"
				) & "( resource=""#arguments.resource#"", parameterName=""#arguments.parameterName#"" )";
			}
		} else {
			if ( arguments.parameterName == "id" ) {
				routerCode &= repeatString( variables.utility.TAB, 2 ) & (
					arguments.api ? "apiResources" : "resources"
				) & "( resource=""#arguments.resource#"", handler=""#arguments.handler#"" )";
			} else {
				routerCode &= repeatString( variables.utility.TAB, 2 ) & (
					arguments.api ? "apiResources" : "resources"
				) & "( resource=""#arguments.resource#"", handler=""#arguments.handler#"", parameterName=""#arguments.parameterName#"" )";
			}
		}

		// Router Path
		var routerPath = ( arguments.module.len() ? modulePath : configPath ) & "/Router.cfc";
		if ( fileExists( routerPath ) ) {
			// Add Resource routes
			var routerContent = fileRead( routerPath ).replaceNoCase(
				"// @app_routes@",
				routerCode & variables.break
			);
			fileWrite( routerPath, routerContent );
			openPath( routerPath );
		} else {
			printError( "Router.cfc not found, please add the following to your router:" );
			printInfo( routerCode );
		}
	}

}
