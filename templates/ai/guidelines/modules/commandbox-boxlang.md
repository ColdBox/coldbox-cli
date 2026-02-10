# CommandBox BoxLang Module Guideline

## Overview

The CommandBox BoxLang module provides seamless integration between CommandBox and BoxLang, enabling you to run BoxLang servers, execute BoxLang scripts, and manage BoxLang development environments directly from CommandBox CLI. It automatically configures BoxLang server instances with proper JVM settings and module loading.

**Benefits:**
- Automatic BoxLang server configuration
- BoxLang REPL access from CommandBox
- JVM optimization for BoxLang runtime
- Module and dependency management
- Development and production ready
- Multi-runtime support (BoxLang + CFML)

## Installation

```bash
box install commandbox-boxlang
```

The module automatically activates when you start a BoxLang server.

## Starting BoxLang Servers

### Basic Server Start

```bash
## Start BoxLang server in current directory
box server start cfengine=boxlang

## Start with specific port
box server start cfengine=boxlang port=8080

## Start with custom name
box server start name=myapp cfengine=boxlang
```

### Server Configuration

Create a `server.json` in your project root:

```json
{
    "name": "my-boxlang-app",
    "openBrowser": true,
    "web": {
        "http": {
            "port": 8080
        }
    },
    "app": {
        "cfengine": "boxlang"
    },
    "jvm": {
        "heapSize": 512
    }
}
```

Then simply:
```bash
box server start
```

### BoxLang-Specific Settings

```json
{
    "app": {
        "cfengine": "boxlang@1.0.0", // Specific version
        "cfengineVersion": "1.0.0" // Or use this
    },
    "jvm": {
        "heapSize": 1024,
        "args": "-Dboxlang.debug=true"
    }
}
```

## BoxLang Commands

### Version Management

```bash
## List available BoxLang versions
box server versions boxlang

## Install specific version
box install boxlang@1.0.0

## Check installed version
box boxlang version
```

### BoxLang REPL

Access BoxLang REPL directly:

```bash
## Start BoxLang REPL
box boxlang repl

## Execute BoxLang code
box boxlang run myScript.bx

## Execute inline
box boxlang run "println( 'Hello BoxLang!' )"
```

### BoxLang Task Runner

Run BoxLang task runners:

```bash
## Run task
box task run mytask.bx

## With BoxLang runtime
box boxlang task run mytask.bx
```

## Module Configuration

The module automatically handles:

### JVM Configuration

Auto-configures JVM for optimal BoxLang performance:
- InvokeDynamic support
- Garbage collection tuning
- Memory settings
- Class loading optimization

### Module Loading

Automatically loads BoxLang modules from:
- `boxlang_modules/` directory
- `modules/` directory (BoxLang-compatible)
- Module dependencies from `box.json`

### Java Library Management

```javascript
// Application.cfc or Application.bx
this.javaSettings = {
    loadPaths = [ "./lib", "./boxlang_modules" ],
    loadColdFusionClassPath = true,
    reloadOnChange = true
}
```

The CommandBox module ensures paths are correctly loaded.

## Development Workflow

### Project Setup

```bash
## Create new directory
mkdir myapp && cd myapp

## Initialize box.json
box init

## Set BoxLang as engine
box set app.cfengine=boxlang

## Install dependencies
box install

## Start server
box server start
```

### Hot Reload Configuration

```json
{
    "web": {
        "rewrites": {
            "enable": true
        }
    },
    "app": {
        "cfengine": "boxlang"
    },
    "runwar": {
        "args": "--reload-on-class-path-change=true"
    }
}
```

### Multi-Runtime Setup

Run BoxLang alongside CFML:

```bash
## BoxLang server
box server start name=boxlang-app cfengine=boxlang port=8080

## Lucee server
box server start name=lucee-app cfengine=lucee port=8081

## Adobe server
box server start name=adobe-app cfengine=adobe port=8082
```

## BoxLang Project Patterns

### ColdBox Application

```bash
## Create ColdBox app with BoxLang
box coldbox create app name=MyApp skeleton=boxlang

## Start server (automatically uses BoxLang)
box server start
```

### Standalone BoxLang Application

```boxlang
// index.bx
class {
    function main() {
        println( "BoxLang Standalone Application" )
        
        // Your application logic
        var server = new Server()
        server.start( port=8080 )
    }
}
```

Run with:
```bash
box boxlang run index.bx
```

### BoxLang Module Development

```bash
## Create module structure
box coldbox create module name=MyModule

## Set BoxLang as target
box set engines.boxlang="^1.0.0"

## Start test harness with BoxLang
cd test-harness
box server start cfengine=boxlang
```

## Testing with BoxLang

### TestBox Integration

```bash
## Run tests with BoxLang
box testbox run cfengine=boxlang

## Run with coverage
box testbox run cfengine=boxlang --coverage
```

### Server Testing

```json
{
    "testbox": {
        "runner": [
            {
                "cfengine": "boxlang@1.0.0",
                "bundles": ["tests.specs"]
            }
        ]
    }
}
```

Run:
```bash
box testbox run
```

## Debugging BoxLang Servers

### Enable Debug Mode

```bash
box server start cfengine=boxlang --debug

## Or in server.json:
{
    "app": {
        "cfengine": "boxlang"
    },
    "jvm": {
        "args": "-Dboxlang.debug=true -Dboxlang.debugLog=true"
    }
}
```

### View Server Logs

```bash
## Tail server logs
box server log --follow

## View specific log
box server log name=myapp
```

### JVM Monitoring

```bash
## Show JVM stats
box server info

## Show detailed JVM info
box server info --verbose
```

## Production Deployment

### Optimized Server Config

```json
{
    "name": "production-app",
    "app": {
        "cfengine": "boxlang@1.0.0"
    },
    "web": {
        "http": {
            "port": 80
        },
        "ssl": {
            "enable": true,
            "port": 443,
            "cert": "/path/to/cert.pem",
            "key": "/path/to/key.pem"
        }
    },
    "jvm": {
        "heapSize": 2048,
        "minHeapSize": 512,
        "args": "-XX:+UseG1GC -XX:MaxGCPauseMillis=200"
    },
    "runwar": {
        "args": "--background=true"
    }
}
```

### Background Server

```bash
## Start in background
box server start --!openBrowser

## Or configure in server.json
{
    "openBrowser": false,
    "runwar": {
        "args": "--background=true"
    }
}
```

### Server Management

```bash
## List running servers
box server list

## Stop server
box server stop

## Restart server
box server restart

## Server status
box server status
```

## Best Practices

### Version Pinning

```json
{
    "app": {
        "cfengine": "boxlang@1.0.0" // Pin specific version
    },
    "engines": {
        "boxlang": "^1.0.0" // In box.json
    }
}
```

### Environment-Specific Config

```bash
## Development
box server start cfengine=boxlang --console

## Production
box server start cfengine=boxlang --!openBrowser

## Use profiles
box server start serverConfigFile=server-production.json
```

### Module Management

```json
{
    "dependencies": {
        "coldbox": "^7.0.0",
        "cborm": "^3.0.0"
    },
    "devDependencies": {
        "testbox": "^5.0.0",
        "mockdatacfc": "^4.0.0"
    },
    "engines": {
        "boxlang": ">=1.0.0"
    }
}
```

### Memory Configuration

```json
{
    "jvm": {
        "heapSize": 2048, // Max heap (MB)
        "minHeapSize": 512, // Min heap (MB)
        "args": [
            "-XX:+UseG1GC",
            "-XX:MaxGCPauseMillis=200",
            "-XX:+HeapDumpOnOutOfMemoryError"
        ]
    }
}
```

## Troubleshooting

### Server Won't Start

**Check:**
```bash
## View server logs
box server log --follow

## Check server status
box server status

## Verify BoxLang installed
box list | grep boxlang
```

### Module Loading Issues

**Verify paths:**
```bash
## Check server info
box server info --verbose

## Examine classpath
box server show app.javaSettings
```

### Port Conflicts

```bash
## Find available port
box server start cfengine=boxlang --force port=0

## Or specify different port
box server start cfengine=boxlang port=8081
```

### Memory Issues

**Increase heap size:**
```bash
box server start cfengine=boxlang jvm.heapSize=2048
```

**Or in server.json:**
```json
{
    "jvm": {
        "heapSize": 4096,
        "args": "-XX:MaxRAM=8g"
    }
}
```

## Common Patterns

### Docker Deployment

```dockerfile
FROM ortussolutions/commandbox:latest

COPY . /app
WORKDIR /app

RUN box install && box server start cfengine=boxlang --!openBrowser

EXPOSE 8080
CMD ["box", "server", "start", "cfengine=boxlang"]
```

### CI/CD Integration

```bash
## GitHub Actions / GitLab CI
box install
box testbox run cfengine=boxlang
box server start cfengine=boxlang --!openBrowser
```

### Multi-Server Development

```bash
## API server (BoxLang)
box server start name=api cfengine=boxlang port=8080

## Admin server (CFML)
box server start name=admin cfengine=lucee port=8081

## Public server (BoxLang)
box server start name=public cfengine=boxlang port=8082
```

## Module Information

- **Repository:** github.com/ortus-boxlang/commandbox-boxlang
- **BoxLang Docs:** boxlang.ortusbooks.com/getting-started/running-boxlang/commandbox
- **CommandBox Docs:** commandbox.ortusbooks.com
- **ForgeBox:** forgebox.io/view/commandbox-boxlang
- **Requirements:** CommandBox 6+
