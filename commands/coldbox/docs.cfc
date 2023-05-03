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
 * coldbox docs search=handlers
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
	 * @search   A string to search in the docs
	 **/
	function run(
		boolean wirebox  = false,
		boolean cachebox = false,
		boolean logbox   = false,
		string search    = ""
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

		var docsUri = "https://#docsType#.ortusbooks.com" & ( search.len() ? "?q=#search#" : "" );

		command( "browse" ).params( uri: docsUri ).run();
	}

}
