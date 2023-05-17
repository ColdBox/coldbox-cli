component singleton {

	this.BREAK = chr( 13 ) & chr( 10 );
	this.TAB   = chr( 9 );

	/**
	 * Convert a plural word to a singular word
	 *
	 * @word The word to convert
	 */
	function singularize( required word ){
		var result = arguments.word;

		if ( result.endsWith( "s" ) ) {
			if ( result.endsWith( "ss" ) || result.endsWith( "us" ) ) {
				result &= "es";
			} else if ( result.endsWith( "is" ) ) {
				result = left( result, len( result ) - 2 ) & "is";
			} else if ( result.endsWith( "es" ) ) {
				if ( len( result ) > 3 && arrayFindNoCase( [ "sh", "ch" ], right( result, 2 ) ) ) {
					result = left( result, len( result ) - 2 );
				} else {
					result = left( result, len( result ) - 1 );
				}
			} else {
				result = left( result, len( result ) - 1 );
			}
		}

		return result;
	}

	/**
	 * Convert a singular word to a plural word
	 *
	 * @word The word to convert
	 */
	function pluralize( required word ){
		var result = arguments.word;

		if ( result.endsWith( "s" ) ) {
			if ( result.endsWith( "ss" ) || result.endsWith( "us" ) ) {
				result &= "es";
			} else {
				result &= "s";
			}
		} else if ( result.endsWith( "y" ) ) {
			if ( arrayFindNoCase( [ "ay", "ey", "iy", "oy", "uy" ], right( result, 2 ) ) ) {
				result &= "s";
			} else {
				result = left( result, len( result ) - 1 ) & "ies";
			}
		} else if ( arrayFindNoCase( [ "x", "s", "z", "ch", "sh" ], right( result, 1 ) ) ) {
			result &= "es";
		} else {
			result &= "s";
		}

		return result;
	}

	/**
	 * Camel case a string using lower case for the first letter
	 */
	function camelCase( required target ){
		var results = arguments.target.left( 1 ).lCase();
		if ( arguments.target.len() > 1 ) {
			results &= arguments.target.right( -1 );
		}
		return results;
	}

}
