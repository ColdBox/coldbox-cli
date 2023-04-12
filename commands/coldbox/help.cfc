component excludeFromHelp=true {

	function run(){
		print.line();
		print.blue( "The " );
		print.boldGreen( "coldbox" );
		print.blueLine(
			" namespace is designed to help developers easily build applications using the ColdBox MVC platform."
		);
		print.blueLine(
			"Use these commands to stub out placeholder handlers, models, views, modules and much more."
		);
		print.blueLine(
			"There are commands to install ColdBox integrations into your IDE, run your application from the command line, "
		);
		print.blueLine( "and even generate reports on various aspects of your application structure." );
		print.blueLine(
			"Type help before any command name to get additional information on how to call that specific command."
		);

		print.line();
		print.line();
	}

}
