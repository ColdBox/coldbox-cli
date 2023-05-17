/**
 * Open the ColdBox API Docs in a browser
 * .
 * {code:bash}
 * coldbox apidocs
 * coldbox apidocs --wirebox
 * coldbox apidocs --cachebox
 * coldbox apidocs --logbox
 * {code}
 **/
component {

	/**
	 * Run the command
	 *
	 * @wirebox  A boolean flag to open the WireBox docs
	 * @cachebox A boolean flag to open the CacheBox docs
	 * @logbox   A boolean flag to open the LogBox docs
	 **/
	function run(
		boolean wirebox  = false,
		boolean cachebox = false,
		boolean logbox   = false
	){
		var docsType = "coldbox";
		if ( wirebox ) {
			docsType = "wirebox";
		}
		if ( cachebox ) {
			docsType = "cachebox";
		}
		if ( logbox ) {
			docsType = "logbox";
		}

		var docsUri = "https://apidocs.ortussolutions.com/##/#docsType#";

		command( "browse" ).params( uri: docsUri ).run();
	}

}
