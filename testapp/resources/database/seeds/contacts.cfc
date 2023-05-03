component {

    function run( qb, mockdata ) {
		// Generate |modelName| mock data
		qb.table( "|modelName|" )
			.insert(
				mockdata.mock(
					$num : 25,
					"id" : "autoincrement",
					"createdDate" : "datetime",
					"updatedDate" : "datetime
				)
			)
    }

}
