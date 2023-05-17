/**
 * Base Command Handler
 */
component  {

	// DI
	property name="utility"  	inject="utility@coldbox-cli";
	property name="settings" 	inject="box:modulesettings:coldbox-cli";
	property name="config" 		inject="box:moduleconfig:coldbox-cli";

	function init(){
		return this;
	}

}
