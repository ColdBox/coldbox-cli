---
title: CBFS File System Module Guidelines
description: File-system abstraction guidance with cbfs across local and cloud providers, including path normalization, stream operations, metadata handling, and provider portability.
---

# CBFS File System Module Guidelines

## Overview

CBFS provides a unified file system abstraction for ColdBox applications with support for multiple storage providers including Local, Amazon S3, FTP, and RAM disk.

## Installation

```bash
box install cbfs
```

## Configuration

In `config/ColdBox.cfc`:

```boxlang
moduleSettings = {
    cbfs = {
        // Default disk
        defaultDisk = "local",

        // Disk configurations
        disks = {
            local = {
                provider = "Local@cbfs",
                properties = {
                    path = expandPath( "/storage" )
                }
            },
            s3 = {
                provider = "S3@cbfs",
                properties = {
                    accessKey = getSystemSetting( "AWS_ACCESS_KEY" ),
                    secretKey = getSystemSetting( "AWS_SECRET_KEY" ),
                    bucket = "my-app-files",
                    region = "us-east-1"
                }
            },
            ram = {
                provider = "RAM@cbfs",
                properties = {}
            }
        }
    }
}
```

## Basic Operations

```boxlang
property name="cbfs\" inject="CBFS@cbfs";

// Store file
cbfs.disk( "local" ).put( "documents/file.txt", "File content" )

// Store binary
cbfs.disk( "s3" ).put( "images/photo.jpg", fileReadBinary( photoPath ) )

// Get file content
var content = cbfs.disk( "local" ).get( "documents/file.txt" )

// Check existence
if ( cbfs.disk( "local" ).exists( "file.txt" ) ) {
    // File exists
}

// Delete file
cbfs.disk( "local" ).delete( "documents/file.txt" )

// Copy file
cbfs.disk( "local" ).copy( "file.txt", "backup/file.txt" )

// Move file
cbfs.disk( "local" ).move( "temp/file.txt", "permanent/file.txt" )

// List files
var files = cbfs.disk( "local" ).files( "documents/" )

// Get file info
var info = cbfs.disk( "local" ).info( "file.txt" )
// Returns: size, lastModified, type, etc.
```

## File Uploads

```boxlang
function uploadFile( event, rc, prc ) {
    var uploadResult = fileUpload(
        getTempDirectory(),
        "upload",
        "image/jpeg,image/png",
        "makeUnique"
    )

    // Store to S3
    var filePath = "uploads/#uploadResult.serverFile#"
    cbfs.disk( "s3" ).put(
        filePath,
        fileReadBinary( uploadResult.serverDirectory & "/" & uploadResult.serverFile )
    )

    // Clean up temp file
    fileDelete( uploadResult.serverDirectory & "/" & uploadResult.serverFile )

    return filePath
}
```

## Best Practices

- **Use S3 for production** - Scalable cloud storage
- **Use local for development** - Faster local testing
- **Abstract storage** - Don't hardcode disk names
- **Validate uploads** - Check file types and sizes
- **Clean up temp files** - Remove temporary files after processing

## Documentation

For complete CBFS documentation, providers, and storage options, visit:
https://github.com/coldbox-modules/cbfs
