---
name: boxlang-interop
description: Master BoxLang interoperability with CFML, Java integration, calling Java classes, and seamless type conversions
category: boxlang
priority: high
---

# BoxLang Interoperability Skill

## When to Use This Skill

Use this skill when:
- Migrating CFML code to BoxLang
- Leveraging Java libraries in BoxLang applications
- Calling Java classes and methods from BoxLang
- Integrating with existing CFML codebases
- Using third-party Java dependencies
- Working with Java Collections and types
- Converting between BoxLang and Java types

## CFML Compatibility

### BoxLang as CFML Alternative

BoxLang provides high compatibility with CFML, allowing most CFML code to run with minimal changes.

```boxlang
// Traditional CFML style (works in BoxLang)
component {
    function getUsers() {
        return queryExecute( "SELECT * FROM users" )
    }
}

// Modern BoxLang style
class UserService {
    function getUsers(): query {
        return queryExecute( "SELECT * FROM users" )
    }
}
```

### CFML Tag Equivalents

```boxlang
// CFML tags as script functions
savecontent variable="output" {
    writeOutput( "<h1>Hello</h1>" )
}

// HTTP requests
cfhttp( url="https://api.example.com", method="GET" ) {
    cfhttpparam( type="header", name="Authorization", value="Bearer token" )
}

// File operations
fileWrite( "output.txt", "content" )
var content = fileRead( "input.txt" )

// Directory operations
directoryList( path="/path/to/dir", recurse=true, type="file" )
```

### Compatibility Layers

```boxlang
// Using CFML components in BoxLang
import cfml.legacy.OldService

class NewService {
    @inject
    property name="oldService";  // CFML component injected

    function processData( data ) {
        // Call CFML component method
        return oldService.legacyProcess( data )
    }
}

// BoxLang components in CFML
<cfset newService = new bx.NewService()>
<cfset result = newService.processData( myData )>
```

### Migration Patterns

```boxlang
// CFML style
component accessors="true" {
    property name="userDAO";

    public function init() {
        return this;
    }

    public function getUsers() {
        return userDAO.list();
    }
}

// BoxLang equivalent
@accessors=true
class UserService {
    @inject
    property name="userDAO";

    init() {
        return this
    }

    function getUsers(): array {
        return userDAO.list()
    }
}
```

## Java Interoperability

### Importing Java Classes

```boxlang
// Import Java classes
import java.util.ArrayList
import java.util.HashMap
import java.lang.System
import java.io.File
import java.nio.file.Files
import java.nio.file.Paths

// Use imported classes
var list = new ArrayList()
list.add( "item1" )
list.add( "item2" )

var map = new HashMap()
map.put( "key", "value" )

var file = new File( "/path/to/file.txt" )
```

### Fully Qualified Names

```boxlang
// Use fully qualified class names (no import needed)
var date = new java.util.Date()
var calendar = new java.util.Calendar.getInstance()
var uuid = new java.util.UUID.randomUUID()
var bigDecimal = new java.math.BigDecimal( "123.45" )
```

### Static Java Methods

```boxlang
// Call static methods
import java.lang.Math
import java.util.UUID
import java.time.LocalDate

var squared = Math.pow( 5, 2 )  // 25
var randomId = UUID.randomUUID().toString()
var today = LocalDate.now()
var date = LocalDate.of( 2024, 12, 25 )
```

## Working with Java Collections

### Java Lists

```boxlang
import java.util.ArrayList
import java.util.LinkedList
import java.util.Arrays

// Create ArrayList
var list = new ArrayList()
list.add( "apple" )
list.add( "banana" )
list.add( "cherry" )

// Access elements
var first = list.get( 0 )
var size = list.size()

// Iterate
for ( var item in list ) {
    writeOutput( item )
}

// Convert Java List to BoxLang array
var boxArray = []
list.forEach( ( item ) => boxArray.append( item ) )

// Create from array
var javaList = Arrays.asList( [ "a", "b", "c" ] )
```

### Java Maps

```boxlang
import java.util.HashMap
import java.util.TreeMap
import java.util.LinkedHashMap

// Create HashMap
var map = new HashMap()
map.put( "name", "John" )
map.put( "age", 30 )
map.put( "active", true )

// Access elements
var name = map.get( "name" )
var hasAge = map.containsKey( "age" )

// Iterate
map.forEach( ( key, value ) => {
    writeOutput( "#key#: #value#" )
})

// Convert to BoxLang struct
var boxStruct = {}
map.forEach( ( key, value ) => {
    boxStruct[ key ] = value
})
```

### Java Sets

```boxlang
import java.util.HashSet
import java.util.TreeSet

// Create HashSet
var set = new HashSet()
set.add( "apple" )
set.add( "banana" )
set.add( "apple" )  // Duplicate ignored

// Check membership
var hasApple = set.contains( "apple" )
var size = set.size()  // 2

// Iterate
for ( var item in set ) {
    writeOutput( item )
}
```

## Java Streams Integration

### Using Java Streams

```boxlang
import java.util.stream.Stream
import java.util.stream.Collectors

// Create stream from array
var numbers = [ 1, 2, 3, 4, 5 ]
var javaList = createObject( "java", "java.util.Arrays" ).asList( numbers )

var result = javaList.stream()
    .filter( ( n ) => n % 2 == 0 )
    .map( ( n ) => n * 2 )
    .collect( Collectors.toList() )

// Infinite stream
var infinite = Stream.iterate( 0, ( n ) => n + 1 )
    .limit( 10 )
    .collect( Collectors.toList() )
```

### Stream Operations

```boxlang
import java.util.stream.IntStream

// Range stream
var range = IntStream.range( 1, 11 )
    .boxed()
    .collect( Collectors.toList() )

// Parallel stream
var parallel = [ 1, 2, 3, 4, 5 ]
    .parallelStream()
    .map( ( n ) => expensiveOperation( n ) )
    .collect( Collectors.toList() )
```

## File and I/O Operations

### Java File I/O

```boxlang
import java.io.File
import java.nio.file.Files
import java.nio.file.Paths
import java.nio.charset.StandardCharsets

// Read file
var path = Paths.get( "/path/to/file.txt" )
var content = Files.readString( path )

// Write file
Files.writeString( path, "content", StandardCharsets.UTF_8 )

// Read all lines
var lines = Files.readAllLines( path )

// File operations
var file = new File( "/path/to/file.txt" )
var exists = file.exists()
var isDirectory = file.isDirectory()
var size = file.length()
var lastModified = file.lastModified()
```

### Working with Paths

```boxlang
import java.nio.file.Path
import java.nio.file.Paths
import java.nio.file.Files

// Create path
var path = Paths.get( "/Users/username/documents/file.txt" )

// Path operations
var fileName = path.getFileName()
var parent = path.getParent()
var absolute = path.toAbsolutePath()

// Check file
var exists = Files.exists( path )
var isRegularFile = Files.isRegularFile( path )
var isReadable = Files.isReadable( path )
```

## Date and Time Interop

### Java 8+ DateTime API

```boxlang
import java.time.LocalDate
import java.time.LocalDateTime
import java.time.ZonedDateTime
import java.time.format.DateTimeFormatter

// Current date/time
var now = LocalDateTime.now()
var today = LocalDate.now()
var withZone = ZonedDateTime.now()

// Create specific date
var christmas = LocalDate.of( 2024, 12, 25 )
var meeting = LocalDateTime.of( 2024, 12, 25, 14, 30 )

// Format dates
var formatter = DateTimeFormatter.ofPattern( "yyyy-MM-dd HH:mm:ss" )
var formatted = now.format( formatter )

// Parse dates
var parsed = LocalDate.parse( "2024-12-25" )
var customParsed = LocalDateTime.parse( "2024-12-25 14:30:00", formatter )

// Date arithmetic
var tomorrow = today.plusDays( 1 )
var nextWeek = today.plusWeeks( 1 )
var nextMonth = today.plusMonths( 1 )
```

### Converting Between Types

```boxlang
import java.time.Instant
import java.time.ZoneId

// BoxLang date to Java
var boxDate = now()
var instant = Instant.ofEpochMilli( boxDate.getTime() )
var javaDate = LocalDateTime.ofInstant( instant, ZoneId.systemDefault() )

// Java date to BoxLang
var javaLocal = LocalDateTime.now()
var epochMilli = javaLocal.atZone( ZoneId.systemDefault() ).toInstant().toEpochMilli()
var boxDate = createObject( "java", "java.util.Date" ).init( epochMilli )
```

## HTTP and Networking

### Java HTTP Client

```boxlang
import java.net.URI
import java.net.http.HttpClient
import java.net.http.HttpRequest
import java.net.http.HttpResponse

// Create HTTP client
var client = HttpClient.newHttpClient()

// Build request
var request = HttpRequest.newBuilder()
    .uri( URI.create( "https://api.example.com/users" ) )
    .GET()
    .build()

// Send request
var response = client.send( request, HttpResponse.BodyHandlers.ofString() )
var body = response.body()
var statusCode = response.statusCode()

// POST request
var postRequest = HttpRequest.newBuilder()
    .uri( URI.create( "https://api.example.com/users" ) )
    .header( "Content-Type", "application/json" )
    .POST( HttpRequest.BodyPublishers.ofString( '{"name":"John"}' ) )
    .build()

var postResponse = client.send( postRequest, HttpResponse.BodyHandlers.ofString() )
```

## Database JDBC Integration

### Direct JDBC Connections

```boxlang
import java.sql.DriverManager
import java.sql.Connection
import java.sql.PreparedStatement
import java.sql.ResultSet

// Load JDBC driver
Class.forName( "com.mysql.cj.jdbc.Driver" )

// Connect to database
var conn = DriverManager.getConnection(
    "jdbc:mysql://localhost:3306/mydb",
    "username",
    "password"
)

// Execute query
var stmt = conn.prepareStatement( "SELECT * FROM users WHERE id = ?" )
stmt.setInt( 1, 123 )
var rs = stmt.executeQuery()

// Process results
while ( rs.next() ) {
    var id = rs.getInt( "id" )
    var name = rs.getString( "name" )
    var email = rs.getString( "email" )
}

// Clean up
rs.close()
stmt.close()
conn.close()
```

## Type Conversions

### BoxLang to Java Type Mapping

```boxlang
// String
var boxString = "hello"
var javaString = createObject( "java", "java.lang.String" ).init( boxString )

// Numeric to Integer/Long
var boxNumber = 42
var javaInt = createObject( "java", "java.lang.Integer" ).valueOf( boxNumber )
var javaLong = createObject( "java", "java.lang.Long" ).valueOf( boxNumber )

// Numeric to Double/BigDecimal
var boxDecimal = 123.45
var javaDouble = createObject( "java", "java.lang.Double" ).valueOf( boxDecimal )

import java.math.BigDecimal
var javaBigDecimal = new BigDecimal( toString( boxDecimal ) )

// Boolean
var boxBool = true
var javaBool = createObject( "java", "java.lang.Boolean" ).valueOf( boxBool )

// Array to Java List
var boxArray = [ 1, 2, 3 ]
import java.util.Arrays
var javaList = Arrays.asList( boxArray )

// Struct to Java Map
var boxStruct = { name: "John", age: 30 }
import java.util.HashMap
var javaMap = new HashMap()
for ( var key in boxStruct ) {
    javaMap.put( key, boxStruct[ key ] )
}
```

### Java to BoxLang Type Mapping

```boxlang
import java.util.ArrayList
import java.util.HashMap

// Java List to Array
var javaList = new ArrayList()
javaList.add( "a" )
javaList.add( "b" )

var boxArray = []
javaList.forEach( ( item ) => boxArray.append( item ) )

// Java Map to Struct
var javaMap = new HashMap()
javaMap.put( "name", "John" )
javaMap.put( "age", 30 )

var boxStruct = {}
javaMap.forEach( ( key, value ) => {
    boxStruct[ key ] = value
})

// Java primitives to BoxLang
var javaInt = createObject( "java", "java.lang.Integer" ).valueOf( 42 )
var boxNumber = javaInt.intValue()

var javaDouble = createObject( "java", "java.lang.Double" ).valueOf( 123.45 )
var boxDecimal = javaDouble.doubleValue()
```

## Third-Party Java Libraries

### Using Maven Dependencies

```boxlang
// In box.json, add Java dependencies
{
    "dependencies": {
        "org.apache.commons:commons-lang3": "3.12.0",
        "com.google.guava:guava": "31.1-jre"
    }
}

// Use in code
import org.apache.commons.lang3.StringUtils
import com.google.common.collect.Lists

var trimmed = StringUtils.trim( "  hello  " )
var isEmpty = StringUtils.isEmpty( "" )

var list = Lists.newArrayList( "a", "b", "c" )
var reversed = Lists.reverse( list )
```

### JSON Processing with Jackson

```boxlang
import com.fasterxml.jackson.databind.ObjectMapper
import com.fasterxml.jackson.databind.JsonNode

// Create ObjectMapper
var mapper = new ObjectMapper()

// Parse JSON
var jsonString = '{"name":"John","age":30}'
var jsonNode = mapper.readTree( jsonString )

var name = jsonNode.get( "name" ).asText()
var age = jsonNode.get( "age" ).asInt()

// Convert to object
var user = mapper.readValue( jsonString, User )

// Serialize to JSON
var json = mapper.writeValueAsString( user )
```

### Logging with SLF4J

```boxlang
import org.slf4j.LoggerFactory

class MyService {
    private var log = LoggerFactory.getLogger( getClass() )

    function doSomething() {
        log.info( "Doing something" )

        try {
            // Operation
        } catch ( any e ) {
            log.error( "Error occurred", e )
        }
    }
}
```

## Best Practices

### ✅ DO: Use BoxLang Natives When Available

```boxlang
// Good - Use BoxLang built-ins
var users = queryExecute( "SELECT * FROM users" )
var parsed = deserializeJSON( jsonString )

// Avoid - Unnecessary Java
import java.sql.DriverManager
var conn = DriverManager.getConnection( ... )  // Use queryExecute instead
```

### ✅ DO: Handle Java Exceptions

```boxlang
import java.io.IOException
import java.nio.file.Files
import java.nio.file.Paths

// Good - Handle Java exceptions
function readFile( string path ): string {
    try {
        return Files.readString( Paths.get( path ) )
    } catch ( IOException e ) {
        throw( type="FileReadError", message="Cannot read file: #path#", detail=e.getMessage() )
    }
}
```

### ✅ DO: Close Java Resources

```boxlang
import java.io.FileInputStream

// Good - Close resources
function processFile( string path ) {
    var fis = new FileInputStream( path )
    try {
        // Process file
    } finally {
        fis.close()  // Always close
    }
}

// Better - Try-with-resources (if supported)
try ( var fis = new FileInputStream( path ) ) {
    // Process file
    // Automatically closed
}
```

### ✅ DO: Convert Collections at Boundaries

```boxlang
// Good - Convert at API boundaries
class UserService {
    function getUsers(): array {
        var javaList = javaRepository.findAll()

        // Convert to BoxLang array
        var boxArray = []
        javaList.forEach( ( item ) => boxArray.append( item ) )

        return boxArray
    }
}
```

## Common Mistakes

### ❌ Not Handling Null from Java

```boxlang
// Wrong - Java might return null
var result = javaService.getValue()
return result.toString()  // ❌ NullPointerException if null

// Right - Check for null
var result = javaService.getValue()
if ( isNull( result ) ) {
    return "default"
}
return result.toString()
```

### ❌ Mixing Collection Types

```boxlang
// Wrong - Mixing Java and BoxLang collections
var list = new java.util.ArrayList()
list.add( "item" )
list.append( "item2" )  // ❌ append() is BoxLang, not Java

// Right - Use correct methods
list.add( "item2" )
```

### ❌ Not Importing Java Classes

```boxlang
// Wrong - Class not found
var list = new ArrayList()  // ❌ Not imported

// Right - Import first
import java.util.ArrayList
var list = new ArrayList()  // ✅
```

### ❌ Assuming Type Compatibility

```boxlang
// Wrong - Types might not match
var javaList = getJavaList()
for ( var i = 1; i <= arrayLen( javaList ); i++ ) {  // ❌ Not an array
    var item = javaList[ i ]
}

// Right - Use Java methods
var javaList = getJavaList()
for ( var i = 0; i < javaList.size(); i++ ) {  // ✅ Java uses 0-based index
    var item = javaList.get( i )
}
```

## Testing Interoperability

```boxlang
component extends="testbox.system.BaseSpec" {

    function run() {
        describe( "Java Interop", () => {

            it( "should use Java collections", () => {
                import java.util.ArrayList

                var list = new ArrayList()
                list.add( "item1" )
                list.add( "item2" )

                expect( list.size() ).toBe( 2 )
                expect( list.get( 0 ) ).toBe( "item1" )
            })

            it( "should convert between types", () => {
                var boxArray = [ 1, 2, 3 ]
                import java.util.Arrays
                var javaList = Arrays.asList( boxArray )

                expect( javaList.size() ).toBe( 3 )
            })

            it( "should call static Java methods", () => {
                import java.lang.Math

                var result = Math.pow( 2, 3 )
                expect( result ).toBe( 8 )
            })

            it( "should handle Java dates", () => {
                import java.time.LocalDate

                var date = LocalDate.of( 2024, 12, 25 )
                expect( date.getYear() ).toBe( 2024 )
                expect( date.getMonthValue() ).toBe( 12 )
            })
        })
    }
}
```

## Additional Resources

- BoxLang Java Integration Guide
- CFML to BoxLang Migration Guide
- Java Interoperability Documentation
- Type Conversion Reference
- Third-Party Library Integration
- JDBC Driver Configuration
- Java Collections Framework
- Java Stream API
