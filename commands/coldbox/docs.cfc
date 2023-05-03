/**
 * Open the ColdBox Docs in a browser
 * .
 * {code:bash}
 * coldbox docs
 * coldbox docs --wirebox
 * coldbox docs --cachebox
 * coldbox docs --logbox
 * {code}
 * .
 * {code:bash}
 * coldbox reinit password="mypass"
 * {code}
 **/
component {

	function init(){
	}

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

		command( "browse" ).params( uri: "https://#docsType#.ortusbooks.com" ).run();
	}

}
