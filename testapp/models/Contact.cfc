/**
 * I model a Contact
 */
component
	table     =""
	persistent="true"
	extends   ="cborm.models.ActiveEntity"
{

	// Properties
	property
		name     ="id"
		fieldtype="id"
		column   =""
		generator="native"
		setter   ="false";
	property name="name" ormtype="string";


	// Validation Constraints
	this.constraints = {
		 // Example: age = { required=true, min="18", type="numeric" }
	};

	// Constraint Profiles
	this.constraintProfiles = { "update" : {} };

	// Population Control
	this.population = { include : [], exclude : [ "id" ] };

	// Mementifier
	this.memento = {
		// An array of the properties/relationships to include by default
		defaultIncludes : [ "*" ],
		// An array of properties/relationships to exclude by default
		defaultExcludes : [],
		// An array of properties/relationships to NEVER include
		neverInclude    : [],
		// A struct of defaults for properties/relationships if they are null
		defaults        : {},
		// A struct of mapping functions for properties/relationships that can transform them
		mappers         : {}
	};

	/**
	 * Constructor
	 */
	Contact function init(){
		super.init( useQueryCaching = "false" );
		return this;
	}

	/**
	 * Verify if the model has been loaded from the database
	 */
	function isLoaded(){
		return isNull( variables.id ) || !len( variables.id );
	}

}
