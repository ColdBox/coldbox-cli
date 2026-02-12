---
title: CBDebugger Module Guidelines
description: Visual debugger and profiler with request tracking, SQL logging, and performance metrics
---

# CBDebugger Module Guidelines

## Overview

CBDebugger provides a comprehensive debugging panel for ColdBox applications with performance profiling, SQL query tracking, cache monitoring, and request visualization.

## Installation

```bash
box install cbdebugger
```

## Configuration

Enable in development only:

```boxlang
moduleSettings = {
    cbdebugger = {
        // Enable debugger
        enabled = getSetting( "environment" ) == "development",
        
        // Render debug panel
        renderDebugPanel = true,
        
        // Expand by default
        expanded = false
    }
}
```

## Features

- **Performance Profiling** - Track request timings and execution paths
- **SQL Query Tracking** - See all database queries with execution time
- **Cache Monitoring** - View cache statistics and operations
- **Request Inspection** - Examine RC/PRC/CGI scopes and form/URL data
- **Variable Dumps** - Debug variables inline during development
- **Exception Tracking** - Detailed exception information

## Usage

Debugger panel appears automatically at bottom of HTML pages in development mode.

## Documentation

For complete CBDebugger documentation and configuration options, visit:
https://coldbox-debugger.ortusbooks.com
