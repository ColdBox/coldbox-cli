---
name: coldbox-docbox-generation
description: "Use this skill when configuring DocBox to generate API documentation, choosing output strategies (HTML, JSON, UML, CommandBox), setting up single or multiple source directories, running DocBox from BoxLang CLI or CommandBox CLI, customizing HTML themes, excluding files/folders from output, or building custom output strategies."
---

# DocBox Documentation Generation

## When to Use This Skill

Use this skill when:
- Setting up DocBox to generate API docs for a BoxLang or CFML project
- Choosing and configuring HTML, JSON, UML, or CommandBox output strategies
- Running DocBox via code, CLI, or a build task
- Excluding test/build paths from generated docs
- Creating a custom output strategy

## Language Mode Reference

Examples use **BoxLang (`.bx`)** syntax by default. Adapt for your target language:

| Concept | BoxLang (`.bx`) | CFML (`.cfc`) |
|---------|-----------------|---------------|
| Class declaration | `class [extends="..."] {` | `component [extends="..."] {` |
| DI annotation | `@inject` above `property name="svc";` | `property name="svc" inject="svc";` |
| View templates | `.bxm` suffix | `.cfm` / `.cfml` suffix |
| Tag prefix | `<bx:if>`, `<bx:output>`, `<bx:set>` | `<cfif>`, `<cfoutput>`, `<cfset>` |

> **CFML Compat Mode**: With BoxLang + CFML Compat module, `.bx` and `.cfc` files coexist freely. BoxLang-native classes use `class {}` (`.bx` files); CFML-compat classes use `component {}` (`.cfc` files).

## Installation

```bash
# BoxLang (recommended)
box install bx-docbox

# CommandBox module (for CLI usage)
box install commandbox-docbox

# CFML project dev dependency
box install docbox --saveDev
```

## Core API

```
DocBox.init( [strategy], [properties] )        → DocBox
DocBox.addStrategy( strategy, [properties] )    → DocBox (chainable)
DocBox.generate( source, mapping, [excludes], [throwOnError] ) → DocBox
DocBox.getStrategies()                          → array
```

## Basic Usage

### Single HTML Strategy

```js
new docbox.DocBox()
    .addStrategy( "HTML", {
        projectTitle       : "My App API",
        projectDescription : "Public API reference for My App",
        outputDir          : expandPath( "/docs/html" ),
        theme              : "default"   // or "frames"
    } )
    .generate(
        source  : expandPath( "/app" ),
        mapping : "app",
        excludes: "(tests|specs|build|\.git)"
    )
```

### Multiple Strategies in One Pass

```js
new docbox.DocBox()
    .addStrategy( "HTML", {
        projectTitle : "My App API",
        outputDir    : expandPath( "/docs/html" ),
        theme        : "default"
    } )
    .addStrategy( "JSON", {
        projectTitle : "My App API",
        outputDir    : expandPath( "/docs/json" )
    } )
    .addStrategy( "UML", {
        projectFile  : expandPath( "/docs/uml/myapp.uml" )
    } )
    .generate(
        source  : expandPath( "/app" ),
        mapping : "app",
        excludes: "(tests|build)"
    )
```

### Multiple Source Directories

```js
new docbox.DocBox()
    .addStrategy( "HTML", {
        projectTitle : "My App API",
        outputDir    : expandPath( "/docs" )
    } )
    .generate(
        source : [
            { dir: expandPath( "/app/models" ),   mapping: "app.models" },
            { dir: expandPath( "/app/services" ),  mapping: "app.services" },
            { dir: expandPath( "/app/handlers" ),  mapping: "app.handlers" }
        ],
        excludes: "(tests|specs)"
    )
```

## Output Strategies

### HTML Strategy

The most common output. Produces navigable HTML documentation.

| Property | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| `outputDir` | string | ✅ | — | Absolute path to the output directory |
| `projectTitle` | string | No | "Untitled" | Browser title and page heading |
| `projectDescription` | string | No | "" | Subtitle/description displayed in header |
| `theme` | string | No | "default" | `"default"` or `"frames"` |

**Default theme** — Modern Alpine.js single-page app:
- Dark/light mode toggle
- Real-time method search (Enter / Shift+Enter)
- Method tabs: All / Public / Private / Static / Abstract
- Bootstrap 5, fully responsive

**Frames theme** — Classic 3-panel frameset layout:
- Package navigation sidebar (left frame)
- Member list frame (top right)
- Detail frame (bottom right)

```js
// Default (SPA)
.addStrategy( "HTML", {
    outputDir : expandPath( "/docs" ),
    theme     : "default"
} )

// Classic frames
.addStrategy( "HTML", {
    outputDir : expandPath( "/docs" ),
    theme     : "frames"
} )
```

### JSON Strategy

Generates machine-readable JSON files for tooling integration.

Output files:
- `overview-summary.json` — index of all packages and classes
- `{package}/package-summary.json` — all classes in a package
- `{package}/{ClassName}.json` — full documentation for one class

```js
.addStrategy( "JSON", {
    projectTitle : "My API",
    outputDir    : expandPath( "/docs/json" )
} )
```

### UML Strategy

Generates an Eclipse UML2Tools-compatible `.uml` XML file.

> **Note:** UML2Tools is no longer actively developed. This strategy is primarily for legacy tooling.

```js
.addStrategy( "UML", {
    projectFile : expandPath( "/docs/myapp.uml" )
} )
```

### CommandBox Strategy

Specialized HTML output for CommandBox CLI modules — uses "namespace" / "command" terminology instead of "package" / "class".

```js
new docbox.DocBox()
    .addStrategy( "CommandBox", {
        projectTitle : "My CommandBox Module",
        outputDir    : expandPath( "/docs/commands" )
    } )
    .generate(
        source  : expandPath( "/modules/my-module/commands/" ),
        mapping : "my-module.commands"
    )
```

### Custom Strategy

Extend `AbstractTemplateStrategy` and implement `IStrategy`:

```js
// myapp/strategy/MyCustomStrategy.cfc
class extends="docbox.strategy.AbstractTemplateStrategy" {

    /**
     * Execute documentation generation.
     * @metadata  Query of all component metadata
     */
    IStrategy function run( required query metadata ) {
        // metadata columns: package, name, metadata, type, extends, implements
        for ( var row in metadata ) {
            // generate your custom output for each component
        }
        return this
    }
}
```

Register it by passing the instance directly:

```js
new docbox.DocBox()
    .addStrategy( new myapp.strategy.MyCustomStrategy( outputDir: expandPath("/docs/custom") ) )
    .generate( source: expandPath("/app"), mapping: "app" )
```

## Run from BoxLang CLI

```bash
# Minimal
boxlang module:docbox \
    --source=/path/to/code \
    --mapping=myapp

# Full options
boxlang module:docbox \
    --source=/path/to/code \
    --mapping=myapp \
    --output-dir=/docs \
    --project-title="My API" \
    --theme=default \
    --excludes="(tests|build|\.git)"

# Multiple sources (comma-separated)
boxlang module:docbox \
    --source="/app/models,/app/services" \
    --mapping=app \
    --output-dir=/docs
```

## Run from CommandBox

```bash
# Install the CommandBox module once
box install commandbox-docbox

# Basic run
box docbox generate source=/app mapping=app outputDir=/docs

# With options
box docbox generate \
    source=/app \
    mapping=app \
    outputDir=/docs \
    projectTitle="My API" \
    excludes="(tests|build)"
```

## ColdBox Build Task Example

```js
// build/GenerateDocs.cfc
class {

    function run() {

        print.line( "📚 Generating API documentation..." )

        new docbox.DocBox()
            .addStrategy( "HTML", {
                projectTitle       : "My ColdBox App",
                projectDescription : "Internal API Reference",
                outputDir          : expandPath( "/docs" ),
                theme              : "default"
            } )
            .generate(
                source   : expandPath( "/app" ),
                mapping  : "app",
                excludes : "(tests|specs|build|node_modules|\.git)"
            )

        print.greenLine( "✅ Docs generated at /docs" )
    }
}
```

## `generate()` Parameters Reference

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `source` | string \| array | ✅ | Path to source dir **or** array of `{dir, mapping}` structs |
| `mapping` | string | ✅ (when source is string) | ColdFusion/BoxLang mapping for the source root |
| `excludes` | string | No | Java regex applied to relative file paths (e.g., `"(tests\|build)"`) |
| `throwOnError` | boolean | No (`false`) | Throw on parsing errors instead of silently skipping |

## Excludes Pattern Examples

```js
// Exclude test and build directories
excludes: "(tests|specs|build)"

// Exclude dot folders and generated code
excludes: "(\.git|\.github|node_modules|generated)"

// Exclude specific packages
excludes: "(tests|mocks|stubs|util\.internal)"
```

## Troubleshooting

| Symptom | Likely Cause | Fix |
|---------|-------------|-----|
| No output generated | Wrong `source` path | Use `expandPath()` for absolute paths |
| Missing classes | Class inside excluded pattern | Review `excludes` regex |
| Blank descriptions | Comment uses `/* */` not `/** */` | Use double-star comment block |
| Strategy not found | Typo in strategy alias | Use exact strings: `"HTML"`, `"JSON"`, `"UML"`, `"CommandBox"` |
| Parse errors logged | Invalid CFML/BoxLang syntax | Set `throwOnError: true` to see details |
