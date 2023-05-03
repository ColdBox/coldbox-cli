component {

    function up( schema, qb ) {
		schema.create( "Contact", function( table ) {
			table.increments( "id" );
			table.timestamps();
		} );
    }

    function down( schema, qb ) {
		schema.dropIfExists( "Contact" );
    }

}

