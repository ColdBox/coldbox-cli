/**
 * Welcome to the Contacts module configuration file.
 *
 * @see https://coldbox.ortusbooks.com/hmvc/modules/moduleconfig
 **/
component {

	// Module Properties
	this.title              = "Contacts";
	this.author             = "";
	this.webURL             = "";
	this.description        = "";
	this.version            = "1.0.0";
	// If true, looks for views in the parent first, if not found, then in the module. Else vice-versa
	this.viewParentLookup   = true;
	// If true, looks for layouts in the parent first, if not found, then in module. Else vice-versa
	this.layoutParentLookup = true;
	// Module Entry Point
	this.entryPoint         = "Contacts";
	// Inherit Entry Point
	this.inheritEntryPoint  = false;
	// Model Namespace
	this.modelNamespace     = "Contacts";
	// CF Mapping
	this.cfmapping          = "Contacts";
	// Auto-map models
	this.autoMapModels      = true;
	// Module Dependencies
	this.dependencies       = [];
	// Application Helpers
	this.applicationHelper  = [];
	// Module Awareness : If true, the module's injector will not need @moduleName in the DSL
	this.moduleAwareness    = false;


	/**
	 * Configure the module
	 */
	function configure(){
		// module settings - stored in modules.name.settings
		settings = {};

		// Layout Settings
		layoutSettings = { defaultLayout : "" };

		// Custom Declared Points
		interceptorSettings = { customInterceptionPoints : [] };

		// Custom Declared Interceptors
		interceptors = [];

		// Binder Mappings
		// binder.map("Alias").to("#moduleMapping#.models.MyService");
	}

	/**
	 * Fired when the module is registered and activated.
	 */
	function onLoad(){
	}

	/**
	 * Fired when the module is unregistered and unloaded
	 */
	function onUnload(){
	}

}
