/**
 * Generate some CRUD goodness out of an ORM entity.
 * .
 * Make sure you are running this command in the root of your app for it to find the correct folder.
 * .
 * {code:bash}
 * coldbox create crud models.Contact
 * {code}
 *
 **/
component extends="coldbox-cli.models.BaseCommand" {

	/**
	 * @entity            The name and dot location path of the entity to create the CRUD for, starting from the root of your application. For example: models.Contact, models.security.User
	 * @pluralName        The plural name of the entity. Used for display purposes. Defaults to 'entityName' + s
	 * @handlersDirectory The location of the handlers. Defaults to 'handlers'
	 * @viewsDirectory    The location of the views. Defaults to 'views'
	 * @tests             Generate the BDD tests for this CRUD operation
	 * @testsDirectory    Your integration tests directory. Only used if tests is true
	 * @boxlang         Is this a boxlang project?
	 **/
	function run(
		required entity,
		pluralName        = "",
		handlersDirectory = "handlers",
		viewsDirectory    = "views",
		boolean tests     = true,
		testsDirectory    = "tests/specs/integration",
		boolean boxlang   = isBoxLangProject( getCWD() )
	){
		// This will make each directory canonical and absolute
		arguments.handlersDirectory = resolvePath( arguments.handlersDirectory );
		arguments.viewsDirectory    = resolvePath( arguments.viewsDirectory );
		arguments.testsDirectory    = resolvePath( arguments.testsDirectory );

		// entity defaults
		var entityName  = listLast( arguments.entity, "." );
		var entityClass = fileSystemUtil.makePathRelative( resolvePath( replace( arguments.entity, ".", "/", "all" ) ) );
		var entityPath  = entityClass & ".#arguments.boxlang ? "bx" : "cfc"#";

		// verify it
		if ( !fileExists( entityPath ) ) {
			return error( "The entity #entityPath# does not exist, cannot continue, ciao!" );
		}
		// Get content
		var entityContent = fileRead( entityPath );
		// property Map
		var metadata      = { properties : [], pk : "" };
		var md            = getComponentMetadata( entityClass );

		// argument defaults
		if ( !len( arguments.pluralname ) ) {
			arguments.pluralName = variables.utility.pluralize( entityName );
		}

		// build property maps
		if ( arrayLen( md.properties ) ) {
			// iterate and build metadata map
			for ( var thisProperty in md.properties ) {
				// convert string to property representation
				entityDefaults( thisProperty );
				// store the pk for convenience
				if ( compareNoCase( thisProperty.fieldType, "id" ) EQ 0 ) {
					metadata.pk = thisProperty.name;
				}

				// Store only persistable columns
				if ( thisProperty.isPersistable ) {
					arrayAppend( metadata.properties, thisProperty );
				}
			}

			// ********************** generate handler ************************************//

			// Read Handler Content
			var hContent = fileRead( "#variables.settings.templatesPath#/crud/#arguments.boxlang ? "bx" : "cfml"#/HandlerContent.txt" );
			// Token replacement
			hContent     = replaceNoCase(
				hContent,
				"|entity|",
				entityName,
				"all"
			);
			hContent = replaceNoCase(
				hContent,
				"|entityPlural|",
				arguments.pluralName,
				"all"
			);
			hContent = replaceNoCase( hContent, "|pk|", metadata.pk, "all" );
			if ( arguments.boxlang ) {
				hContent = toBoxLangClass( hContent );
			}

			// Write Out Handler
			var hpath = "#arguments.handlersDirectory#/#arguments.pluralName#.#arguments.boxlang ? "bx" : "cfc"#";
			// Create dir if it doesn't exist
			directoryCreate(
				getDirectoryFromPath( hpath ),
				true,
				true
			);
			file action="write" file="#hpath#" mode="777" output="#hContent#";
			printInfo( "Generated Handler: [#hPath#]" );

			// ********************** generate views ************************************//

			// Create Views Path
			directoryCreate(
				arguments.viewsDirectory & "/#arguments.pluralName#",
				true,
				true
			);
			var views = [ "edit", "editor", "new" ];
			for ( var thisView in views ) {
				var vContent = fileRead( "#variables.settings.templatesPath#/crud/#arguments.boxlang ? "bx" : "cfml"#/#thisView#.txt" );
				vContent     = replaceNoCase(
					vContent,
					"|entity|",
					entityName,
					"all"
				);
				vContent = replaceNoCase(
					vContent,
					"|entityPlural|",
					arguments.pluralName,
					"all"
				);
				fileWrite(
					arguments.viewsDirectory & "/#arguments.pluralName#/#thisView#.#arguments.boxlang ? ".bxm" : "cfm"#",
					vContent
				);
				printInfo( "Generated View: [" & arguments.viewsDirectory & "/#arguments.pluralName#/#thisView#.#arguments.boxlang ? ".bxm" : "cfm"#]" );
			}

			// ********************** generate table output ************************************//

			// Build table output for index
			savecontent variable="local.tableData" {
				include "#variables.settings.templatesPath#/crud/#arguments.boxlang ? "bx" : "cfml"#/table.#arguments.boxlang ? ".bxm" : "cfm"#";
			}
			tableData = replaceNoCase(
				tableData,
				"%cf",
				"#chr( 60 )#cf",
				"all"
			);
			tableData = replaceNoCase(
				tableData,
				"%/cf",
				"#chr( 60 )#/cf",
				"all"
			);
			// index data
			var vContent = fileRead( "#variables.settings.templatesPath#/crud/#arguments.boxlang ? "bx" : "cfml"#/index.txt" );
			vContent     = replaceNoCase(
				vContent,
				"|entity|",
				entityName,
				"all"
			);
			vContent = replaceNoCase(
				vContent,
				"|entityPlural|",
				arguments.pluralName,
				"all"
			);
			vContent = replaceNoCase(
				vContent,
				"|tableListing|",
				tableData,
				"all"
			);
			fileWrite(
				arguments.viewsDirectory & "/#arguments.pluralName#/index.#arguments.boxlang ? ".bxm" : "cfm"#",
				vContent
			);
			printInfo( "Generated View: [" & arguments.viewsDirectory & "/#arguments.pluralName#/index.#arguments.boxlang ? ".bxm" : "cfm"#]" );
		} else {
			return error( "The entity: #entityName# has no properties, so I have no clue what to CRUD on dude!" );
		}
	}

	/**
	 * Get entity property metadata
	 *
	 * @target The target metadata struc
	 */
	private function entityDefaults( required target ){
		// add defaults to it
		if ( NOT structKeyExists( arguments.target, "fieldType" ) ) {
			arguments.target.fieldType = "column";
		}
		if ( NOT structKeyExists( arguments.target, "persistent" ) ) {
			arguments.target.persistent = true;
		}
		if ( NOT structKeyExists( arguments.target, "formula" ) ) {
			arguments.target.formula = "";
		}
		if ( NOT structKeyExists( arguments.target, "readonly" ) ) {
			arguments.target.readonly = false;
		}

		// Add column isValid depending if it is persistable
		arguments.target.isPersistable = true;
		if ( NOT arguments.target.persistent OR len( arguments.target.formula ) OR arguments.target.readonly ) {
			arguments.target.isPersistable = false;
		}

		return arguments.target;
	}

}
