---
name: BoxLang File Handling
description: Complete guide to file operations in BoxLang with file reading, writing, copying, moving, and directory management
category: boxlang
priority: high
triggers:
  - boxlang file
  - file read
  - file write
  - file operations
  - directory operations
---

# BoxLang File Handling

## Overview

BoxLang provides comprehensive file system operations for reading, writing, and managing files and directories. Supports text and binary files with various encoding options.

## Core Concepts

### File Operations

- **Read**: Read file content
- **Write**: Create or update files
- **Copy**: Duplicate files
- **Move**: Relocate files
- **Delete**: Remove files
- **Directory**: Manage folders

## Reading Files

### Read Text Files

```boxlang
// Read entire file
var content = fileRead( "/path/to/file.txt" )

// Read with encoding
var content = fileRead( "/path/to/file.txt", "UTF-8" )

// Read line by line
fileOpen( "/path/to/file.txt", "read", (file) => {
    while ( !fileIsEOF( file ) ) {
        var line = fileReadLine( file )
        println( line )
    }
} )

// Read as array of lines
var lines = fileReadLines( "/path/to/file.txt" )
for ( var line in lines ) {
    println( line )
}
```

### Read Binary Files

```boxlang
// Read binary data
var binaryData = fileReadBinary( "/path/to/image.jpg" )

// Get file info
var fileInfo = getFileInfo( "/path/to/file.txt" )
println( fileInfo.size )
println( fileInfo.lastModified )
println( fileInfo.mode )
```

### Streaming Large Files

```boxlang
/**
 * Process large file line by line
 */
function processLargeFile( filePath ) {
    var file = fileOpen( filePath, "read" )

    try {
        while ( !fileIsEOF( file ) ) {
            var line = fileReadLine( file )

            // Process line
            processLine( line )
        }
    } finally {
        fileClose( file )
    }
}
```

## Writing Files

### Write Text Files

```boxlang
// Write string to file
fileWrite( "/path/to/file.txt", "Hello World" )

// Write with encoding
fileWrite( "/path/to/file.txt", content, "UTF-8" )

// Append to file
fileWrite( "/path/to/file.txt", "New line\n", "UTF-8", true )

// Write line by line
var lines = [ "Line 1", "Line 2", "Line 3" ]
fileWrite( "/path/to/file.txt", lines.toList( chr(10) ) )
```

### Write Binary Files

```boxlang
// Write binary data
fileWriteBinary( "/path/to/image.jpg", binaryData )

// Copy uploaded file
if ( form.keyExists( "uploadField" ) ) {
    var uploadedFile = form.uploadField

    fileWrite(
        expandPath( "/uploads/#uploadedFile.serverFile#" ),
        fileReadBinary( uploadedFile.serverFile )
    )
}
```

### Buffered Writing

```boxlang
/**
 * Write large content efficiently
 */
function writeLargeFile( filePath, dataArray ) {
    var file = fileOpen( filePath, "write" )

    try {
        dataArray.each( ( line ) => {
            fileWriteLine( file, line )
        } )
    } finally {
        fileClose( file )
    }
}
```

## File Operations

### Copy Files

```boxlang
// Copy file
fileCopy( "/source/file.txt", "/destination/file.txt" )

// Copy and overwrite
fileCopy( "/source/file.txt", "/destination/file.txt", true )

// Copy uploaded file
fileUpload(
    destination: expandPath( "/uploads" ),
    fileField: "uploadField",
    nameConflict: "makeUnique"
)
```

### Move/Rename Files

```boxlang
// Move file
fileMove( "/old/path/file.txt", "/new/path/file.txt" )

// Rename file
fileMove( "/path/oldname.txt", "/path/newname.txt" )
```

### Delete Files

```boxlang
// Delete file
if ( fileExists( "/path/to/file.txt" ) ) {
    fileDelete( "/path/to/file.txt" )
}

// Force delete (ignore errors)
try {
    fileDelete( "/path/to/file.txt" )
} catch ( any e ) {
    // Handle error
    writeLog( "Could not delete file: #e.message#" )
}
```

## Directory Operations

### List Directories

```boxlang
// List files in directory
var files = directoryList( "/path/to/dir" )

// List with filter
var txtFiles = directoryList(
    path: "/path/to/dir",
    filter: "*.txt"
)

// List recursively
var allFiles = directoryList(
    path: "/path/to/dir",
    recurse: true,
    listInfo: "query"
)

// Filter results
for ( var file in allFiles ) {
    if ( file.type == "file" && file.size > 1024 ) {
        println( file.name & " - " & file.size & " bytes" )
    }
}
```

### Create Directories

```boxlang
// Create directory
if ( !directoryExists( "/path/to/dir" ) ) {
    directoryCreate( "/path/to/dir" )
}

// Create nested directories
directoryCreate( "/path/to/nested/dir", createPath: true )

// Create with permissions (Unix)
directoryCreate( "/path/to/dir", mode: "755" )
```

### Copy/Move Directories

```boxlang
// Copy directory
directoryCopy( "/source/dir", "/destination/dir" )

// Copy

 recursively
directoryCopy(
    "/source/dir",
    "/destination/dir",
    recurse: true
)

// Move directory
directoryRename( "/old/path", "/new/path" )
```

### Delete Directories

```boxlang
// Delete empty directory
directoryDelete( "/path/to/dir" )

// Delete recursively
if ( directoryExists( "/path/to/dir" ) ) {
    directoryDelete( "/path/to/dir", recurse: true )
}
```

## File Information

### File Attributes

```boxlang
// Check existence
if ( fileExists( "/path/to/file.txt" ) ) {
    println( "File exists" )
}

// Get file info
var info = getFileInfo( "/path/to/file.txt" )

println( "Name: #info.name#" )
println( "Size: #info.size# bytes" )
println( "Type: #info.type#" )
println( "Modified: #info.lastModified#" )
println( "Mode: #info.mode#" )
println( "Path: #info.path#" )
println( "Directory: #info.directory#" )
```

### File Paths

```boxlang
// Expand relative path
var absolutePath = expandPath( "/uploads/file.txt" )

// Get directory name
var dir = getDirectoryFromPath( "/path/to/file.txt" )  // /path/to/

// Get file name
var fileName = getFileFromPath( "/path/to/file.txt" )  // file.txt

// Get file extension
var ext = listLast( fileName, "." )  // txt

// Build path
var path = "/uploads" & "/" & "file.txt"
```

## Advanced Patterns

### File Upload Handler

```boxlang
/**
 * Handle file upload
 */
function uploadFile( fileField, destination ) {
    // Validate file exists
    if ( !form.keyExists( fileField ) ) {
        return {
            success: false,
            message: "No file uploaded"
        }
    }

    try {
        // Ensure destination exists
        if ( !directoryExists( destination ) ) {
            directoryCreate( destination, createPath: true )
        }

        // Upload file
        var upload = fileUpload(
            destination: destination,
            fileField: fileField,
            nameConflict: "makeUnique",
            accept: "image/jpeg,image/png,image/gif"
        )

        return {
            success: true,
            serverFile: upload.serverFile,
            clientFile: upload.clientFile,
            fileSize: upload.fileSize
        }

    } catch ( any e ) {
        return {
            success: false,
            message: "Upload failed: #e.message#"
        }
    }
}
```

### CSV Processing

```boxlang
/**
 * Read CSV file
 */
function readCSV( filePath ) {
    var data = []
    var lines = fileReadLines( filePath )
    var headers = []

    lines.each( ( line, index ) => {
        var columns = listToArray( line, "," )

        if ( index == 1 ) {
            // First row is headers
            headers = columns
        } else {
            // Build struct from row
            var row = {}
            columns.each( ( value, colIndex ) => {
                row[ headers[colIndex] ] = value
            } )
            data.append( row )
        }
    } )

    return data
}

/**
 * Write CSV file
 */
function writeCSV( filePath, data, headers ) {
    var lines = []

    // Add header row
    lines.append( headers.toList() )

    // Add data rows
    data.each( ( row ) => {
        var values = headers.map( ( header ) => row[header] ?: "" )
        lines.append( values.toList() )
    } )

    fileWrite( filePath, lines.toList( chr(10) ) )
}
```

### JSON File Operations

```boxlang
/**
 * Read JSON file
 */
function readJSON( filePath ) {
    var content = fileRead( filePath )
    return deserializeJSON( content )
}

/**
 * Write JSON file
 */
function writeJSON( filePath, data ) {
    var json = serializeJSON( data )
    fileWrite( filePath, json )
}

/**
 * Update JSON file
 */
function updateJSON( filePath, updates ) {
    var data = readJSON( filePath )
    data.append( updates )
    writeJSON( filePath, data )
}
```

### Log File Management

```boxlang
/**
 * Rotate log file
 */
function rotateLogFile( logFile, maxSize = 10485760 ) {  // 10MB
    if ( !fileExists( logFile ) ) {
        return
    }

    var info = getFileInfo( logFile )

    if ( info.size > maxSize ) {
        // Create backup with timestamp
        var timestamp = dateFormat( now(), "yyyymmdd_HHnnss" )
        var backupFile = logFile & "." & timestamp

        // Move current log to backup
        fileMove( logFile, backupFile )

        // Create new log file
        fileWrite( logFile, "" )
    }
}
```

## Best Practices

### Design Guidelines

1. **Check Existence**: Verify files/dirs exist
2. **Error Handling**: Wrap in try/catch
3. **Close Files**: Always close open files
4. **Validate Uploads**: Check file types
5. **Use Absolute Paths**: Avoid relative paths
6. **Set Permissions**: Appropriate file modes
7. **Limit Size**: Check file sizes
8. **Clean Up**: Delete temporary files
9. **Encoding**: Specify encoding
10. **Security**: Validate file paths

### Common Patterns

```boxlang
// ✅ Good: Check before operations
if ( fileExists( path ) ) {
    var content = fileRead( path )
}

// ✅ Good: Error handling
try {
    fileWrite( path, content )
} catch ( any e ) {
    writeLog( "File write failed: #e.message#" )
}

// ✅ Good: Always close files
var file = fileOpen( path, "read" )
try {
    var content = fileRead( file )
} finally {
    fileClose( file )
}
```

## Common Pitfalls

### Pitfalls to Avoid

1. **No Error Handling**: Unhandled exceptions
2. **File Leaks**: Not closing files
3. **Path Traversal**: Security vulnerability
4. **No Validation**: Accepting any file type
5. **Large Files**: Memory issues
6. **Wrong Encoding**: Character corruption
7. **Hardcoded Paths**: Not portable
8. **No Cleanup**: Accumulating temp files
9. **Overwrite**: Lost data
10. **Permissions**: Access denied errors

### Anti-Patterns

```boxlang
// ❌ Bad: No error handling
var content = fileRead( path )  // Could fail

// ✅ Good: Handle errors
try {
    var content = fileRead( path )
} catch ( any e ) {
    // Handle error
}

// ❌ Bad: Not closing file
var file = fileOpen( path, "read" )
var content = fileRead( file )
// File never closed

// ✅ Good: Always close
var file = fileOpen( path, "read" )
try {
    var content = fileRead( file )
} finally {
    fileClose( file )
}

// ❌ Bad: Path traversal vulnerability
var file = form.fileName
fileRead( "/uploads/#file#" )  // Could access ../../../etc/passwd

// ✅ Good: Validate and sanitize
var file = form.fileName
if ( !isValid( "fileName", file ) ) {
    throw( "Invalid file name" )
}
var safePath = expandPath( "/uploads" ) & "/" & getFileFromPath( file )
fileRead( safePath )
```

## Related Skills

- [BoxLang Syntax](boxlang-syntax.md) - Language fundamentals
- [BoxLang Zip Utilities](boxlang-zip.md) - Archive operations
- [CBFS Integration](../coldbox/cbfs-integration.md) - File system abstraction

## References

- [BoxLang File Documentation](https://boxlang.ortusbooks.com/)
- [File Security Best Practices](https://owasp.org/www-community/vulnerabilities/Unrestricted_File_Upload)
- [Path Traversal Prevention](https://owasp.org/www-community/attacks/Path_Traversal)
