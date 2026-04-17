/**
 *********************************************************************************
 * Copyright Since 2014 CommandBox by Ortus Solutions, Corp
 * www.coldbox.org | www.ortussolutions.com
 ********************************************************************************
 *
 * @author Brad Wood, Luis Majano
 */
component {

	this.name      = "ColdBox CLI";
	this.version   = "@build.version@+@build.number@";
	this.cfmapping = "coldbox-cli";

	function configure(){
		variables.settings = {
			templatesPath     : modulePath & "/templates",
			skillsRegistryUrl : "https://skills.boxlang.io",
			coldboxSkillsRepo : { owner : "coldbox", repo : "skills" },
			boxlangSkillsRepo : {
				owner : "ortus-boxlang",
				repo  : "skills"
			},
			ortusSkillsRepo : {
				owner : "ortus-solutions",
				repo  : "skills"
			}
		}
	}

	function onLoad(){
		// log.info('Module loaded successfully.' );
	}

	function onUnLoad(){
		// log.info('Module unloaded successfully.' );
	}

}
