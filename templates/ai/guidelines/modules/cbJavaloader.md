---
title: CBJavaloader Module Guidelines
description: Integration patterns for loading Java libraries with cbJavaloader, including classpath management, dependency isolation, object creation, and interop troubleshooting.
---

# CBJavaloader Module Guidelines

## Overview

CBJavaloader provides dynamic Java class loading for ColdBox applications. Load external JAR files at runtime without server restarts.

## Installation

```bash
box install cbjavaloader
```

## Configuration

In `config/ColdBox.cfc`:

```boxlang
moduleSettings = {
    cbjavaloader = {
        // Paths to load JARs from
        loadPaths = [ "lib", "jars", "libs/external" ],

        // Load ColdFusion classpath
        loadColdFusionClassPath = false,

        // Reload on each request (dev only)
        reloadOnEveryRequest = false
    }
}
```

## Usage

```boxlang
property name="javaloader" inject="loader@cbjavaloader";

// Create Java object from loaded JARs
var pdfLib = javaloader.create( "com.lowagie.text.pdf.PdfReader" )

// Create with constructor args
var httpclient = javaloader.create(
    "org.apache.http.impl.client.DefaultHttpClient"
).init()

// Get class version
var version = javaloader.getVersion( "com.example.MyClass" )
```

## Common Use Cases

```boxlang
// PDF processing
var pdfReader = javaloader.create( "com.lowagie.text.pdf.PdfReader" )
    .init( pdfPath )

// Image manipulation
var bufferedImage = javaloader.create( "java.awt.image.BufferedImage" )

// Excel processing (Apache POI)
var workbook = javaloader.create( "org.apache.poi.xssf.usermodel.XSSFWorkbook" )
```

## Documentation

https://github.com/coldbox-modules/cbjavaloader
