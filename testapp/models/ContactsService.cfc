/**
 * A nice ORM Service
 */
component extends="cborm.models.BaseORMService" singleton {

	/**
	 * Constructor
	 */
	function init(){
		// init super class
		super.init();

		// Use Query Caching
		setUseQueryCaching( false );
		// Query Cache Region
		setQueryCacheRegion( "ormservice.Contacts" );
		// EventHandling
		setEventHandling( true );

		return this;
	}

}
