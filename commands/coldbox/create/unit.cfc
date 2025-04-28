/**
 * Create a new xUnit Bundle in an existing ColdBox-enabled application.  Run this command in the root
 * of your app for it to find the correct folder.  By default, your new xUnit Bundle will be created in /tests/specs but you can
 * override that with the directory param.
 * .
 * {code:bash}
 * coldbox create unit myUnit
 * {code}
 *
 **/
component extends="coldbox-cli.models.BaseCommand" {

	/**
	 * @name      Name of the xUnit Bundle to create without the .cfc. For packages, specify name as 'myPackage/MyServiceTest'
	 * @open      Open the file once it is created
	 * @directory The base directory to create your BDD spec in, defaults to 'tests/specs'
	 **/
	function run(
		required name,
		boolean open = false,
		directory    = "tests/specs"
	){
		variables.utility.ensureTestBoxModule();
		runCommand( "testbox create unit name=#arguments.name# directory=#arguments.directory# open=#arguments.open#" );
	}

}
