component {

    function up( schema, qb ) {
		schema.create( "contacts", function( table ) {
			table.increments( "id" );
			table.timestamps();
		} );
    }

    function down( schema, qb ) {
		schema.dropIfExists( "contacts" );
    }

}

