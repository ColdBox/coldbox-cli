---
name: BoxLang Zip Utilities
description: Complete guide to ZIP archive operations in BoxLang with compression, extraction, and archive management
category: boxlang
priority: medium
triggers:
  - boxlang zip
  - zip file
  - compress
  - extract
  - archive
---

# BoxLang Zip Utilities

## Overview

BoxLang provides comprehensive ZIP archive utilities for creating, extracting, and managing ZIP files. Supports compression, encryption, and file filtering.

## Core Concepts

### ZIP Operations

- **Create**: Build ZIP archives
- **Extract**: Unpack archives
- **List**: View archive contents
- **Add**: Append files to archives
- **Delete**: Remove files from archives

## Creating ZIP Archives

### Basic Compression

```boxlang
// Create ZIP from directory
zip action="zip"
    file="#expandPath( '/temp/archive.zip' )#"
    source="#expandPath( '/files/documents' )#"

// Create ZIP from multiple files
zip action="zip" file="#expandPath( '/temp/files.zip' )#" {
    zipparam source="#expandPath( '/files/doc1.pdf' )#"
    zipparam source="#expandPath( '/files/doc2.pdf' )#"
    zipparam source="#expandPath( '/files/doc3.pdf' )#"
}

// Overwrite existing
zip action="zip"
    file="#expandPath( '/temp/archive.zip' )#"
    source="#expandPath( '/files' )#"
    overwrite="true"
```

### Selective Compression

```boxlang
// Filter files
zip action="zip"
    file="#expandPath( '/temp/pdfs.zip' )#"
    source="#expandPath( '/documents' )#"
    filter="*.pdf"
    recurse="true"

// Prefix for archive structure
zip action="zip"
    file="#expandPath( '/temp/backup.zip' )#"
    source="#expandPath( '/app' )#"
    prefix="backup"
```

## Extracting Archives

### Basic Extraction

```boxlang
// Extract entire archive
zip action="unzip"
    file="#expandPath( '/temp/archive.zip' )#"
    destination="#expandPath( '/extracted' )#"

// Extract with overwrite
zip action="unzip"
    file="#expandPath( '/temp/archive.zip' )#"
    destination="#expandPath( '/extracted' )#"
    overwrite="true"

// Extract specific file
zip action="unzip"
    file="#expandPath( '/temp/archive.zip' )#"
    destination="#expandPath( '/extracted' )#"
    entryPath="docs/report.pdf"
```

### Filtered Extraction

```boxlang
// Extract only PDFs
zip action="unzip"
    file="#expandPath( '/temp/archive.zip' )#"
    destination="#expandPath( '/pdfs' )#"
    filter="*.pdf"

// Extract from subdirectory
zip action="unzip"
    file="#expandPath( '/temp/archive.zip' )#"
    destination="#expandPath( '/images' )#"
    entryPath="assets/images/*"
```

## Reading Archive Contents

### List Files

```boxlang
// List all entries
zip action="list"
    file="#expandPath( '/temp/archive.zip' )#"
    name="zipContents"

<cfloop query="zipContents">
    <cfoutput>
        #name# - #size# bytes - #dateLastModified#<br>
    </cfoutput>
</cfloop>

// Filter listing
zip action="list"
    file="#expandPath( '/temp/archive.zip' )#"
    filter="*.pdf"
    name="pdfFiles"
```

### Read Single File

```boxlang
// Read file content without extracting
zip action="read"
    file="#expandPath( '/temp/archive.zip' )#"
    entryPath="config.json"
    variable="configContent"

var config = deserializeJSON( configContent )
```

## Modifying Archives

### Add Files

```boxlang
// Add files to existing ZIP
zip action="zip"
    file="#expandPath( '/temp/archive.zip' )#" {
    zipparam source="#expandPath( '/newfile.txt' )#"
}

// Add directory
zip action="zip"
    file="#expandPath( '/temp/archive.zip' )#"
    source="#expandPath( '/newdocs' )#"
    prefix="documents"
```

### Delete from Archive

```boxlang
// Delete entry
zip action="delete"
    file="#expandPath( '/temp/archive.zip' )#"
    entryPath="oldfile.txt"

// Delete multiple files
zip action="delete"
    file="#expandPath( '/temp/archive.zip' )#" {
    zipparam entryPath="temp/*"
    zipparam entryPath="logs/*.log"
}
```

## Advanced Operations

### ZIP with Encryption

```boxlang
// Create encrypted ZIP
zip action="zip"
    file="#expandPath( '/temp/secure.zip' )#"
    source="#expandPath( '/sensitive' )#"
    password="SecurePassword123"

// Extract encrypted ZIP
zip action="unzip"
    file="#expandPath( '/temp/secure.zip' )#"
    destination="#expandPath( '/extracted' )#"
    password="SecurePassword123"
```

### Compression Levels

```boxlang
// Maximum compression
zip action="zip"
    file="#expandPath( '/temp/compressed.zip' )#"
    source="#expandPath( '/files' )#"
    compressionLevel="9"

// No compression (store only)
zip action="zip"
    file="#expandPath( '/temp/stored.zip' )#"
    source="#expandPath( '/files' )#"
    compressionLevel="0"
```

## Utility Functions

### ZIP Helper Service

```boxlang
/**
 * models/ZipService.cfc
 */
class singleton {

    /**
     * Create ZIP archive
     */
    function create(
        required zipFile,
        required source,
        overwrite = false,
        filter = "*",
        password = ""
    ) {
        if ( !overwrite && fileExists( zipFile ) ) {
            throw( "ZIP file already exists: #zipFile#" )
        }

        zip action="zip"
            file="#zipFile#"
            source="#source#"
            overwrite="#overwrite#"
            filter="#filter#"
            password="#password#"

        return getFileInfo( zipFile )
    }

    /**
     * Extract ZIP archive
     */
    function extract(
        required zipFile,
        required destination,
        overwrite = false,
        filter = "*",
        password = ""
    ) {
        if ( !fileExists( zipFile ) ) {
            throw( "ZIP file not found: #zipFile#" )
        }

        if ( !directoryExists( destination ) ) {
            directoryCreate( destination, createPath: true )
        }

        zip action="unzip"
            file="#zipFile#"
            destination="#destination#"
            overwrite="#overwrite#"
            filter="#filter#"
            password="#password#"
    }

    /**
     * List ZIP contents
     */
    function list( required zipFile, filter = "*" ) {
        if ( !fileExists( zipFile ) ) {
            throw( "ZIP file not found: #zipFile#" )
        }

        zip action="list"
            file="#zipFile#"
            filter="#filter#"
            name="local.contents"

        var files = []

        for ( var row in contents ) {
            files.append( {
                name: row.name,
                size: row.size,
                compressed: row.compressedSize,
                type: row.type,
                modified: row.dateLastModified
            } )
        }

        return files
    }

    /**
     * Read file from ZIP
     */
    function readEntry( required zipFile, required entryPath ) {
        if ( !fileExists( zipFile ) ) {
            throw( "ZIP file not found: #zipFile#" )
        }

        zip action="read"
            file="#zipFile#"
            entryPath="#entryPath#"
            variable="local.content"

        return content
    }

    /**
     * Check if entry exists
     */
    function hasEntry( required zipFile, required entryPath ) {
        var contents = list( zipFile )

        return contents.some( ( entry ) => entry.name == entryPath )
    }

    /**
     * Get ZIP info
     */
    function getInfo( required zipFile ) {
        if ( !fileExists( zipFile ) ) {
            throw( "ZIP file not found: #zipFile#" )
        }

        var fileInfo = getFileInfo( zipFile )
        var contents = list( zipFile )

        return {
            path: zipFile,
            size: fileInfo.size,
            modified: fileInfo.lastModified,
            entryCount: contents.len(),
            entries: contents
        }
    }
}
```

### Backup System

```boxlang
/**
 * Create application backup
 */
function createBackup() {
    var timestamp = dateFormat( now(), "yyyymmdd_HHnnss" )
    var backupFile = expandPath( "/backups/app_#timestamp#.zip" )

    // Create backup directory if needed
    var backupDir = getDirectoryFromPath( backupFile )
    if ( !directoryExists( backupDir ) ) {
        directoryCreate( backupDir )
    }

    // Create ZIP with multiple sources
    zip action="zip" file="#backupFile#" {
        // Application code (exclude certain directories)
        zipparam source="#expandPath( '/app' )#" prefix="app" filter="!.git,!node_modules"

        // Configuration
        zipparam source="#expandPath( '/config' )#" prefix="config"

        // Uploads
        zipparam source="#expandPath( '/uploads' )#" prefix="uploads"
    }

    return {
        file: backupFile,
        size: getFileInfo( backupFile ).size,
        created: now()
    }
}

/**
 * Restore from backup
 */
function restoreBackup( required backupFile ) {
    if ( !fileExists( backupFile ) ) {
        throw( "Backup file not found" )
    }

    var restoreDir = expandPath( "/temp/restore_#createUUID()#" )

    // Extract backup
    zip action="unzip"
        file="#backupFile#"
        destination="#restoreDir#"

    // Restore files
    // ... copy files to appropriate locations

    // Cleanup
    directoryDelete( restoreDir, true )
}
```

### File Download as ZIP

```boxlang
/**
 * Handler action to download files as ZIP
 */
function downloadMultiple( event, rc, prc ) {
    var fileIDs = rc.fileIDs ?: []

    if ( fileIDs.len() == 0 ) {
        return "No files selected"
    }

    // Create temporary ZIP
    var tempZip = getTempFile( getTempDirectory(), "download" ) & ".zip"

    // Add files to ZIP
    zip action="zip" file="#tempZip#" {
        fileIDs.each( ( fileID ) => {
            var file = fileService.find( fileID )
            zipparam source="#file.path#" entryPath="#file.name#"
        } )
    }

    // Send to browser
    cfheader( name: "Content-Disposition", value: "attachment; filename=files.zip" )
    cfcontent(
        file: tempZip,
        type: "application/zip",
        deleteFile: true
    )
}
```

## Best Practices

### Design Guidelines

1. **Temp Files**: Use temp directory for processing
2. **Error Handling**: Wrap in try/catch
3. **Cleanup**: Delete temporary files
4. **Validation**: Check file existence
5. **Passwords**: Store securely
6. **Compression**: Choose appropriate level
7. **File Size**: Monitor archive size
8. **Permissions**: Set appropriate access
9. **Testing**: Verify archive integrity
10. **Documentation**: Document archive structure

### Common Patterns

```boxlang
// ✅ Good: Error handling
try {
    zip action="unzip"
        file="#zipFile#"
        destination="#dest#"
} catch ( any e ) {
    writeLog( "ZIP extraction failed: #e.message#" )
}

// ✅ Good: Cleanup temp files
var tempZip = getTempFile( getTempDirectory(), "archive" ) & ".zip"
try {
    // Create and use ZIP
} finally {
    if ( fileExists( tempZip ) ) {
        fileDelete( tempZip )
    }
}

// ✅ Good: Validate before operations
if ( fileExists( zipFile ) ) {
    zip action="unzip" file="#zipFile#" destination="#dest#"
}
```

## Common Pitfalls

### Pitfalls to Avoid

1. **No Error Handling**: Unhandled exceptions
2. **Temp File Leaks**: Not cleaning up
3. **Missing Validation**: File existence checks
4. **Path Issues**: Hardcoded paths
5. **Large Files**: Memory issues
6. **No Overwrite Check**: Data loss
7. **Weak Passwords**: Security risk
8. **Missing Cleanup**: Disk space issues
9. **No Progress**: Long operations
10. **Corrupt Archives**: No verification

### Anti-Patterns

```boxlang
// ❌ Bad: No error handling
zip action="unzip" file="#zipFile#" destination="#dest#"

// ✅ Good: Handle errors
try {
    zip action="unzip" file="#zipFile#" destination="#dest#"
} catch ( any e ) {
    // Handle error
}

// ❌ Bad: Temp file leak
var temp = getTempFile( getTempDirectory(), "zip" ) & ".zip"
zip action="zip" file="#temp#" source="#source#"
// Never deleted

// ✅ Good: Cleanup
var temp = getTempFile( getTempDirectory(), "zip" ) & ".zip"
try {
    zip action="zip" file="#temp#" source="#source#"
    // Use ZIP
} finally {
    if ( fileExists( temp ) ) {
        fileDelete( temp )
    }
}

// ❌ Bad: Weak password
zip action="zip" file="#file#" source="#source#" password="123"

// ✅ Good: Strong password
var password = generateSecurePassword()
zip action="zip" file="#file#" source="#source#" password="#password#"
```

## Related Skills

- [BoxLang File Handling](boxlang-file-handling.md) - File operations
- [BoxLang Streams](boxlang-streams.md) - Stream processing
- [ColdBox File System](../coldbox/cbfs-integration.md) - File system abstraction

## References

- [BoxLang ZIP Documentation](https://boxlang.ortusbooks.com/)
- [ZIP File Format](https://en.wikipedia.org/wiki/ZIP_(file_format))
- [Compression Best Practices](https://www.winzip.com/en/learn/tips/compression/)
