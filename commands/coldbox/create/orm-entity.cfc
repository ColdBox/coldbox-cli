/**
 * Create a new CFML ORM entity.  You can pass in extra attributes like making it an enhanced ColdBox ORM Active Entity, or generating
 * primary keys and properties.
 * .
 * You can pass a primary key value or use the default of 'id'. You can then pass also an optional primary key table name and generator.
 * The default generator used is 'native'
 * .
 * To generate properties you will pass a list of property names to the 'properties' argument.  You can also add
 * ORM types to the properties by separating them with a colon.  For example:
 * {code:bash}
 * properties=name,createDate:timestamp,age:numeric
 * {code}
 * .
 * Make sure you are running this command in the root of your app for it to find the correct folder.
 * .
 * {code:bash}
 * // Basic
 * coldbox create orm-entity User --open
 *
 * // Active Entity
 * coldbox create orm-entity User --open --activeEntity
 *
 * // With Some Specifics
 * coldbox create orm-entity entityName=User table=users primaryKey=userID generator=uuid
 *
 * // With some properties
 * coldbox create orm-entity entityName=User properties=firstname,lastname,email,createDate:timestamp,updatedate:timestamp,age:numeric
 * {code}
 *
 **/
component {

	// DI
	property name="utility"  inject="utility@coldbox-cli";
	property name="settings" inject="box:modulesettings:coldbox-cli";

	/**
	 * @entityName        The name of the entity without .cfc
	 * @table             The name of the mapped table or empty to use the same name as the entity
	 * @directory         The base directory to create your model in and creates the directory if it does not exist.
	 * @activeEntity      Generate a ColdBox ORM Active entity instead of a Normal CFML entity.
	 * @primaryKey        Enter the name of the primary key, defaults to 'id'
	 * @primaryKeyColumn  Enter the name of the primary key column. Leave empty if same as the primaryKey value
	 * @generator         Enter the ORM key generator to use, defaults to 'native'
	 * @generator.options increment,identity,sequence,native,assigned,foreign,seqhilo,uuid,guid,select,sequence-identity
	 * @properties        Enter a list of properties to generate. You can add the ORM type via colon separator, default type is string. Ex: firstName,age:numeric,createdate:timestamp
	 * @tests             Generate the unit test BDD component
	 * @testsDirectory    Your unit tests directory. Only used if tests is true
	 * @open              Open the file(s) once generated
	 * @force             Force overwrite of existing files
	 * @migration         Generate a migration file for this entity
	 * @seeder            Generate a seeder file for this entity
	 * @handler           Generate a handler for this entity
	 * @rest              Generate a REST handler for this entity
	 * @resource          Generate a REST resource for this entity
	 * @all               Generate all the things! (tests, migration, seeder, handler, rest, resource)
	 * @methods           Generate methods for the entity
	 **/
	function run(
		required entityName,
		table                = "",
		directory            = "models",
		boolean activeEntity = false,
		primaryKey           = "id",
		primaryKeyColumn     = "",
		generator            = "native",
		properties           = "",
		boolean tests        = true,
		testsDirectory       = "tests/specs/unit",
		boolean open         = false,
		boolean force        = false,
		boolean migration    = false,
		boolean seeder       = false,
		boolean handler      = false,
		boolean rest         = false,
		boolean resource     = false,
		boolean all          = false,
		methods              = ""
	){
		// Defaults
		arguments.table = len( arguments.table ) ? arguments.table : variables.utility.pluralize(
			arguments.entityName.lcase()
		);
		arguments.primaryKeyColumn = len( arguments.primaryKeyColumn ) ? arguments.primaryKeyColumn : arguments.primaryKey;

		// Persistence data
		var componentAnnotations = " table=""#arguments.table#"" persistent=""true""";

		// Active Entity?
		if ( arguments.activeEntity ) {
			componentAnnotations &= " extends=""cborm.models.ActiveEntity""";
		}

		var propertyContent = "property name=""#arguments.primaryKey#"" fieldtype=""id"" column=""#arguments.primaryKeyColumn#"" generator=""#arguments.generator#"" setter=""false"";";

		command( "coldbox create model" )
			.params(
				name                : ucFirst( arguments.entityName ),
				methods             : arguments.methods,
				tests               : arguments.tests,
				testsDirectory      : arguments.testsDirectory & "/unit",
				directory           : arguments.directory,
				description         : "I model a #arguments.entityName#",
				open                : arguments.open,
				accessors           : false,
				properties          : arguments.properties,
				force               : arguments.force,
				migration           : arguments.migration,
				seeder              : arguments.seeder,
				handler             : arguments.handler,
				rest                : arguments.rest,
				resource            : arguments.resource,
				all                 : arguments.all,
				componentAnnotations: componentAnnotations,
				ormTypes            : true,
				propertyContent     : propertyContent & variables.cr & variables.utility.TAB,
				initContent         : "super.init( useQueryCaching=""false"" );"
			)
			.run();
	}

}
