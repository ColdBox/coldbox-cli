component excludeFromHelp=true {

	function run(){
		variables.print
			.line()
			.blue( "The " )
			.boldblue( "coldbox create" )
			.blueLine( " namespace allows you to quickly scaffold applications " )
			.blueLine( "and individual app pieces.  Use these commands to stub out placeholder files" )
			.blue( "as you plan your application.  Most commands create a single file, but """ )
			.boldblue( "coldbox create app" )
			.blueLine( """" )
			.blueLine( "will generate an entire, working application into an empty folder for you. Type help before" )
			.blueLine( "any command name to get additional information on how to call that specific command." )
			.line()
			.line();
	}

}
