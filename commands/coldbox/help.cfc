component excludeFromHelp=true {

	property name="config" inject="box:moduleconfig:coldbox-cli";

	function run(){
		print.line();
		print.blue( "The " );
		print.boldGreen( "coldbox" );
		print
			.blueLine(
				" namespace is designed to help developers easily build applications using the ColdBox MVC platform."
			)
			.line()
			.blue( "Use these commands to stub out placeholder handlers, models, views, modules and much more." )
			.blue(
				"There are commands to install ColdBox integrations into your IDE, run your application from the command line, "
			)
			.blue( "and even generate reports on various aspects of your application structure." )
			.blue(
				"  Type help or (--help) before any command name to get additional information on how to call that specific command."
			)
			.line()
			.line()
			.greenLine( "ColdBox CLI Version: #config.version#" )
			.line();
	}

}
