/**
 * Manages AI guidelines (framework conventions and reference documentation)
 * Guidelines are always loaded by AI agents and provide foundational knowledge
 */
component singleton {

	// DI
	property name="print"          inject="PrintBuffer";
	property name="fileSystemUtil" inject="fileSystem";
	property name="packageService" inject="PackageService";
	property name="wirebox"        inject="wirebox";

	/**
	 * Install core guidelines for a project
	 *
	 * @directory The project directory
	 * @language Project language mode (boxlang, cfml, hybrid)
	 * @manifest The manifest struct to update
	 */
	function installCoreGuidelines(
		required string directory,
		required string language,
		required struct manifest
	){
		var installed = [];

		// Always install BoxLang guideline unless language is cfml-only
		if ( arguments.language != "cfml" ) {
			installGuideline( arguments.directory, "boxlang-core", "coldbox-cli", manifest );
			installed.append( "boxlang-core" );
		}

		// Always install CFML guideline unless language is boxlang-only
		if ( arguments.language != "boxlang" ) {
			installGuideline( arguments.directory, "cfml-core", "coldbox-cli", manifest );
			installed.append( "cfml-core" );
		}

		// Always install ColdBox core guideline
		installGuideline( arguments.directory, "coldbox-core", "coldbox-cli", manifest );
		installed.append( "coldbox-core" );

		// Always install TestBox guideline
		installGuideline( arguments.directory, "testbox-core", "coldbox-cli", manifest );
		installed.append( "testbox-core" );

		// Always install WireBox guideline
		installGuideline( arguments.directory, "wirebox-core", "coldbox-cli", manifest );
		installed.append( "wirebox-core" );

		return installed;
	}

	/**
	 * Refresh guidelines based on installed modules
	 *
	 * @directory The project directory
	 * @manifest The manifest struct to update
	 */
	function refresh( required string directory, required struct manifest ){
		var changes = {
			"added"   : [],
			"updated" : [],
			"removed" : []
		};

		// Get installed modules from box.json
		var boxJson        = variables.packageService.readPackageDescriptor( arguments.directory );
		var dependencies   = boxJson.dependencies ?: {};
		var devDependencies = boxJson.devDependencies ?: {};
		var allDependencies = {};
		allDependencies.append( dependencies );
		allDependencies.append( devDependencies );

		// Map of module slugs to guideline names
		var guidelineMap = getGuidelineModuleMap();

		// Install/update guidelines for installed modules
		for ( var moduleSlug in allDependencies ) {
			if ( structKeyExists( guidelineMap, moduleSlug ) ) {
				var guidelineName = guidelineMap[ moduleSlug ];
				var moduleVersion = allDependencies[ moduleSlug ];

				// Check if already in manifest
				var existing = manifest.guidelines.filter( ( g ) => {
					return g.name == guidelineName
				} )

				if ( existing.len() ) {
					// Update if version changed
					if ( existing[ 1 ].installedVersion != moduleVersion ) {
						installGuideline( directory, guidelineName, moduleSlug, manifest );
						changes.updated.append( guidelineName );
					}
				} else {
					// New guideline
					installGuideline( directory, guidelineName, moduleSlug, manifest );
					changes.added.append( guidelineName );
				}
			}
		}

		// Remove guidelines for uninstalled modules
		var toRemove = [];
		for ( var guideline in manifest.guidelines ) {
			if ( guideline.source != "coldbox-cli" && !structKeyExists( allDependencies, guideline.source ) ) {
				toRemove.append( guideline.name );
			}
		}

		toRemove.each( ( name ) => {
			removeGuideline( directory, name, manifest )
			changes.removed.append( name )
		} )

		return changes;
	}

	/**
	 * Diagnose guideline health
	 *
	 * @directory The project directory
	 * @manifest The manifest struct
	 */
	function diagnose( required string directory, required struct manifest ){
		var issues = {
			"warnings"        : [],
			"recommendations" : []
		};

		// Check for missing core guidelines
		var coreGuidelines = [ "coldbox-core", "testbox-core", "wirebox-core" ];
		coreGuidelines.each( ( name ) => {
			var found = manifest.guidelines.filter( ( g ) => {
				return g.name == name
			} )
			if ( !found.len() ) {
				issues.warnings.append( "Missing core guideline: #name#" )
				issues.recommendations.append( "Run 'coldbox ai refresh' to install missing guidelines" )
			}
		} )

		// Check guideline files exist
		for ( var guideline in manifest.guidelines ) {
			var guidelineFile = "#arguments.directory#/.ai/guidelines/core/#guideline.name#.md";
			if ( !fileExists( guidelineFile ) ) {
				guidelineFile = "#arguments.directory#/.ai/guidelines/modules/#guideline.name#.md";
				if ( !fileExists( guidelineFile ) ) {
					issues.warnings.append( "Guideline file missing: #guideline.name#.md" );
					issues.recommendations.append( "Run 'coldbox ai refresh' to regenerate missing files" );
				}
			}
		}

		return issues;
	}

	// ========================================
	// Private Helpers
	// ========================================

	/**
	 * Install a single guideline
	 *
	 * @directory The project directory
	 * @guidelineName The name of the guideline to install
	 * @source The source of the guideline (coldbox-cli or module slug)
	 * @manifest The manifest struct to update
	 */
	private function installGuideline(
		required string directory,
		required string guidelineName,
		required string source,
		required struct manifest
	){
		// Get guideline content (stub for now - will be filled with actual content)
		var content = getGuidelineContent( arguments.guidelineName );

		// Determine target directory
		var targetDir = arguments.source == "coldbox-cli" ? "core" : "modules";
		var targetFile = "#arguments.directory#/.ai/guidelines/#targetDir#/#arguments.guidelineName#.md";

		// Write guideline file
		fileWrite( targetFile, content );

		// Update manifest
		var existingIndex = 0;
		for ( var i = 1; i <= arguments.manifest.guidelines.len(); i++ ) {
			if ( arguments.manifest.guidelines[ i ].name == arguments.guidelineName ) {
				existingIndex = i;
				break;
			}
		}

		var guidelineEntry = {
			"name"             : arguments.guidelineName,
			"source"           : arguments.source,
			"installedVersion" : getColdboxCliVersion(),
			"syncedAt"         : now().toIsoString()
		};

		if ( existingIndex ) {
			arguments.manifest.guidelines[ existingIndex ] = guidelineEntry;
		} else {
			arguments.manifest.guidelines.append( guidelineEntry );
		}
	}

	/**
	 * Remove a guideline
	 *
	 * @directory The project directory
	 * @guidelineName The name of the guideline to remove
	 * @manifest The manifest struct to update
	 */
	private function removeGuideline(
		required string directory,
		required string guidelineName,
		required struct manifest
	){
		// Remove file
		var possiblePaths = [
			"#arguments.directory#/.ai/guidelines/core/#arguments.guidelineName#.md",
			"#arguments.directory#/.ai/guidelines/modules/#arguments.guidelineName#.md"
		];

		possiblePaths.each( ( path ) => {
			if ( fileExists( path ) ) {
				fileDelete( path )
			}
		} )

		// Remove from manifest
		arguments.manifest.guidelines = arguments.manifest.guidelines.filter( ( g ) => {
			return g.name != guidelineName
		} )
	}

	/**
	 * Get guideline content (reads from template files)
	 *
	 * @guidelineName The name of the guideline to retrieve content for
	 */
	private function getGuidelineContent( required string guidelineName ){
		var templatePath = getTemplatesPath() & "/ai/guidelines/#arguments.guidelineName#.md";

		if ( fileExists( templatePath ) ) {
			return fileRead( templatePath );
		}

		// Fallback for unknown guidelines
		return "## #arguments.guidelineName# Guidelines

This guideline will be populated with actual content.";
	}

	/**
	 * Get templates path from settings
	 */
	private function getTemplatesPath(){
		// Get from module settings - same pattern as other commands
		var moduleSettings = wirebox.getInstance( "box:modulesettings:coldbox-cli" );
		return moduleSettings.templatesPath;
	}

	/**
	 * Get map of module slugs to guideline names
	 */
	private function getGuidelineModuleMap(){
		return {
			"cbsecurity"            : "cbsecurity-core",
			"cbvalidation"          : "cbvalidation-core",
			"cbauth"                : "cbauth-core",
			"cbsso"                 : "cbsso-core",
			"cbwire"                : "cbwire-core",
			"quick"                 : "quick-core",
			"qb"                    : "qb-core",
			"commandbox-migrations" : "migrations-core",
			"hyper"                 : "hyper-core",
			"cbq"                   : "cbq-core",
			"cachebox"              : "cachebox-core",
			"logbox"                : "logbox-core"
		};
	}

	/**
	 * Get current coldbox-cli version
	 */
	private function getColdboxCliVersion(){
		// Stub - will get from actual package
		return "1.0.0";
	}

}
