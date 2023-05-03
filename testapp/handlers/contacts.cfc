/**
 * I am a new handler
 * Implicit Functions: preHandler, postHandler, aroundHandler, onMissingAction, onError, onInvalidHTTPMethod
 */
component extends="coldbox.system.RestHandler"{

	this.prehandler_only 	= "";
	this.prehandler_except 	= "";
	this.posthandler_only 	= "";
	this.posthandler_except = "";
	this.aroundHandler_only = "";
	this.aroundHandler_except = "";

	/**
	 * index
	 */
	function index( event, rc, prc ){
        event.getResponse()
            .setData( {} )
            .addMessage( "Calling contacts/index" );
	}
	/**
	 * create
	 */
	function create( event, rc, prc ){
        event.getResponse()
            .setData( {} )
            .addMessage( "Calling contacts/create" );
	}
	/**
	 * show
	 */
	function show( event, rc, prc ){
        event.getResponse()
            .setData( {} )
            .addMessage( "Calling contacts/show" );
	}
	/**
	 * update
	 */
	function update( event, rc, prc ){
        event.getResponse()
            .setData( {} )
            .addMessage( "Calling contacts/update" );
	}
	/**
	 * delete
	 */
	function delete( event, rc, prc ){
        event.getResponse()
            .setData( {} )
            .addMessage( "Calling contacts/delete" );
	}


}

