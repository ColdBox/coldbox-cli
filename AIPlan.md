# ColdBox CLI AI Integration Plan

> **Status**: Planning Phase
> **Last Updated**: January 26, 2026

## Overview

Implement AI-assisted development capabilities in ColdBox CLI to accelerate AI-assisted development by providing essential guidelines and agent skills that help AI agents write high-quality ColdBox applications following best practices.

## Key Features

- ✅ **AI Guidelines**: Composable instruction files loaded upfront for AI agents
- ✅ **Agent Skills**: On-demand, task-specific knowledge modules
- ✅ **MCP Server Integration**: Connect to all Ortus MCP documentation servers
- ✅ **Multi-Agent Support**: Claude, Copilot, Codex, Gemini, OpenCode
- ✅ **Custom Guidelines**: User-defined guidelines and overrides
- ✅ **Third-Party Module Support**: Module authors can include guidelines/skills

---

## Quick Overview - What We're Building

### 🎯 The Goal

Enable AI agents (Claude, Copilot, etc.) to write high-quality ColdBox applications by providing them with framework knowledge, best practices, and live documentation access.

### 📦 What Gets Installed

**For Developers:**

```bash
coldbox ai install --agent=claude,copilot
```

Creates:

- `.ai/guidelines/` - Framework conventions (always loaded by AI)
- `.ai/skills/` - On-demand implementation patterns
- `CLAUDE.md`, `.github/copilot-instructions.md` - Agent-specific config
- `.mcp.json` - Live documentation server connections

**Result:** AI agents know your framework, modules, and coding standards

### 🛠️ CLI Commands (11 Main Commands)

```bash
# Setup & Management
coldbox ai install              # Set up AI for project
coldbox ai refresh               # Refresh skills/guidelines when modules change
coldbox ai info                 # Show current AI configuration
coldbox ai doctor               # Diagnose AI configuration and health

# Guidelines (Framework Conventions)
coldbox ai guidelines list      # See available guidelines
coldbox ai guidelines create    # Add custom team conventions

# Skills (Implementation Patterns)
coldbox ai skills list          # See auto-discovered skills
coldbox ai skills refresh       # Sync skills with installed modules
coldbox ai skills create        # Add custom implementation pattern

# Agent Management
coldbox ai agents list          # See supported/configured agents
coldbox ai agents add           # Enable agent(s) for project
coldbox ai agents remove        # Disable agent(s)

# MCP Servers (Live Documentation)
coldbox ai mcp list             # Show available doc servers
coldbox ai mcp search "query"   # Search across all documentation
```

### 📚 What Gets Auto-Discovered

**Guidelines** (40+ frameworks/modules):

- ColdBox, BoxLang, CFML, TestBox, WireBox, LogBox, CacheBox
- CBSecurity, CBValidation, CBAuth, CBSSO, CBWire
- Quick ORM, QB, cfmigrations, Hyper, and more

**Skills** (30+ patterns organized by priority):

- **BoxLang** (8 skills): Syntax, Classes, Functions, Lambdas, Modules, Streams, Type system, Interop
- **ColdBox** (9 skills): Handlers, REST APIs, Modules, Interceptors, Routing, Event model, Layouts, View rendering, Cache integration
- **Testing** (8 skills): BDD specs, Unit tests, Integration tests, Handler tests, Mocking, Test fixtures, Coverage, CI integration
- **Security** (9 skills): CBSecurity setup, CBAuth integration, Authorization rules, JWT tokens, Passkeys, SSO, CSRF, API authentication, Role-based access
- ORM/Database (4 skills): Quick patterns, QB usage, Migrations, Relationships
- Modern (3 skills): CBWire components, Queue processing, WebSockets

**MCP Servers** (25 documentation sources):

- All Ortus product documentation with live search
- CFML in 100 Minutes, BoxLang, ColdBox, and all modules

### 🔄 The Developer Experience

**Before AI Integration:**

```
1. Google "ColdBox validation"
2. Read docs
3. Copy example
4. Adapt to your code
5. Debug issues
6. Repeat for each feature
```

**After AI Integration:**

```
1. Ask AI: "Add validation to user registration"
2. AI generates correct code following your conventions
3. Done! ✅
```

**The AI automatically:**

- Follows ColdBox conventions
- Uses your installed modules (CBValidation, Quick, etc.)
- Generates BoxLang or CFML based on project language
- Includes proper error handling
- Applies your team's custom guidelines

### 🎨 Multi-Agent Support

Same configuration works for all team members:

- **Claude users** → Uses `CLAUDE.md`
- **Copilot users** → Uses `.github/copilot-instructions.md`
- **Gemini users** → Uses `.gemini/` config
- **Others** → Codex, OpenCode supported

### 📈 For Module Authors

Add AI support to your module:

```
your-module/
└── resources/
    └── coldbox-cli/
        └── ai/
            ├── guidelines/
            │   └── core.md          # Your module conventions
            └── skills/
                └── your-feature/
                    └── SKILL.md     # Implementation patterns
```

When users `box install your-module` → AI automatically knows how to use it!

### 🚀 Implementation Phases

1. **Foundation** - Core services, directory structure, config schema
2. **CLI Commands** - 10 commands for managing AI integration
3. **App Integration** - Add to `coldbox create app` wizard
4. **Guidelines Content** - 40+ framework/module guidelines
5. **Skills Content** - 15+ implementation patterns
6. **MCP Integration** - 25 documentation servers
7. **Multi-Agent** - 6 agent support (Claude, Copilot, Codex, Gemini, OpenCode)
8. **Custom Support** - User overrides and custom content
9. **Module Support** - Third-party module guidelines/skills
10. **Documentation** - Complete user and author guides

### 📊 Success Metrics

- 40+ guidelines covering entire ColdBox ecosystem
- **41 skills** prioritizing BoxLang (8), ColdBox (9), Testing (8), and Security (9)
- 25 MCP servers for live documentation access
- 6 AI agents supported
- Zero-config for module installation (auto-discovery)
- Works with BoxLang, CFML, and hybrid projects

---

## Guidelines vs Skills - Understanding the Difference

### 📘 **Guidelines** (Always Loaded - Reference Documentation)

**What**: Foundational knowledge loaded when AI starts
**When**: Always present in AI's context
**Purpose**: Framework syntax, conventions, and API reference

**Think of it as**: The AI's "permanent reference manual" - what exists and how it works

**Examples:**

- BoxLang syntax and features
- ColdBox HMVC structure and naming conventions
- How handlers work and extend EventHandler
- Standard dependency injection patterns
- Configuration file locations and structure
- Basic routing patterns

**File Location:** `.ai/guidelines/coldbox/core.md`

```markdown
# ColdBox Framework Core

## Handler Conventions

- Handlers extend `coldbox.system.EventHandler`
- Located in `/handlers/` directory
- Use dependency injection via `property` declarations
- Event handlers receive: event, rc, prc

## Example Handler Structure

class extends="coldbox.system.EventHandler" {

	@inject( "UserService")
	property name="userService";

    function index( event, rc, prc ){
        // Handler code
    }
}
```

---

### 🎯 **Skills** (On-Demand Loading)


**What**: Detailed patterns activated only when needed
**When**: Loaded on-demand for specific tasks
**Purpose**: Deep, focused knowledge for particular domains

**Think of it as**: The AI's "reference manual" pulled up when working on specific features

**Examples:**

- Step-by-step REST API creation with all HTTP methods
- Complete CRUD implementation with validation
- Advanced ORM relationships and eager loading
- WebSocket connection handling
- Testing patterns with setup/teardown

**File Location:** `.ai/skills/rest-api-development/SKILL.md`

```yaml
---
name: rest-api-development
description: Build RESTful APIs in ColdBox with proper HTTP methods, validation, and error handling
---

## When to use this skill
Use when building REST APIs, resource handlers, or API endpoints

## Creating a REST Resource Handler

1. Handler structure for REST resources
2. Implementing all HTTP methods (GET, POST, PUT, PATCH, DELETE)
3. Input validation for API endpoints
4. Response formatting (JSON, XML)
5. Error handling and HTTP status codes
6. Authentication and rate limiting
7. API documentation patterns

[Detailed code examples for each...]
```

---

### 📊 **Comparison Table**


| Aspect | Guidelines | Skills |
|--------|-----------|--------|
| **Loading** | Loaded upfront when AI starts | Loaded on-demand when relevant |
| **Scope** | Broad, foundational | Focused, task-specific |
| **Size** | Concise (~200-500 lines) | Detailed (~500-2000 lines) |
| **Purpose** | "What ColdBox is" | "How to build X in ColdBox" |
| **Example** | "Handlers extend EventHandler" | "Complete CRUD handler with all methods" |
| **Context Usage** | Always in AI context | Only when activated |
| **Use Case** | Framework conventions | Implementation patterns |

---

### 🔄 **How They Work Together**


**Scenario**: Building a REST API for users

**Guidelines provide:**
- ✅ Handler conventions
- ✅ Routing basics
- ✅ Dependency injection
- ✅ Event object usage

**Skills provide (when activated):**
- ✅ Complete REST resource pattern
- ✅ All CRUD operations with proper HTTP methods
- ✅ Input validation implementation
- ✅ JSON response formatting
- ✅ Error handling patterns
- ✅ Authentication integration
- ✅ Rate limiting setup

**Without Skills:**
```
You: "Create a REST API for users"
AI: [Uses guidelines] "Here's a basic handler structure..."
```

**With Skills Activated:**
```
You: "Create a REST API for users"
AI: [Uses guidelines + rest-api-development skill]
"Here's a complete REST resource with:
- GET /users (list with pagination)
- GET /users/:id (show single)
- POST /users (create with validation)
- PUT /users/:id (update)
- DELETE /users/:id (delete)
- Proper error handling
- JSON responses
- Authentication checks"
```

---

### 💡 **Why This Split?**


**Context Window Limits**: AI agents have limited context. Loading everything upfront wastes space.

**Relevance**: When working on a handler, you don't need deep WebSocket patterns. When building WebSockets, you don't need ORM relationship details.

**Performance**: Smaller context = faster AI responses and better focus.

**Example Context Usage:**

**Without Skills (Guidelines Only):**
```
AI Context: 15KB of guidelines
- ColdBox core: 5KB
- TestBox: 3KB
- WireBox: 2KB
- Other: 5KB
Remaining for your code: 85KB
```

**With All Skills Loaded:**
```
AI Context: 50KB (guidelines + all skills)
- Guidelines: 15KB
- 10 skills × 3.5KB each: 35KB
Remaining for your code: 50KB ⚠️ Too much!
```

**With On-Demand Skills:**
```
AI Context: 20KB (guidelines + 1 active skill)
- Guidelines: 15KB
- Active skill: 5KB
Remaining for your code: 80KB ✅ Perfect!
```

---

### 🎬 **Practical Example**


**Day 1 - Creating Basic Handlers:**
```bash
coldbox create handler Users --ai
# AI uses: ColdBox guidelines (always loaded)
# Generates: Basic handler structure
```

**Day 2 - Building REST API:**
```bash
# REST skill already auto-discovered from ColdBox
# Ask: "Convert Users handler to REST API"
# AI automatically uses rest-api-development skill
# Generates: Complete REST resource with all methods
```

**Day 3 - Adding Tests:**
```bash
# Testing skill already auto-discovered from TestBox
# Ask: "Create BDD tests for Users REST API"
# AI automatically uses testing-bdd skill
# Generates: Complete test suite
```

**Day 4 - Back to Regular Handlers:**
```bash
coldbox create handler Orders --ai
# All skills auto-available based on project
# AI intelligently picks relevant skills
# Uses rest-api-development only if REST context detected
```

---

### 📝 **Summary**


**Use Guidelines for:**
- ✅ Framework conventions everyone should know
- ✅ Core patterns used in every app
- ✅ Essential best practices
- ✅ Basic structure and organization

**Use Skills for:**
- ✅ Detailed implementation guides
- ✅ Step-by-step patterns
- ✅ Domain-specific knowledge
- ✅ Advanced techniques
- ✅ Complete code examples

**Guidelines = "ColdBox 101"**
**Skills = "Advanced ColdBox Cookbook"**

---

## Practical Usage Examples

### Example 1: New ColdBox App with AI


```bash
# Create new app with AI support
coldbox create app myapp --ai --agent=claude

# Or use the wizard
coldbox create app-wizard
# Select: Enable AI assistance? Yes
# Select: Which agent? Claude Code
# Select: Install recommended guidelines? Yes
# Select: Install recommended skills? Yes
```

**Generated Structure:**

```
myapp/
├── .ai/
│   ├── guidelines/
│   │   ├── coldbox/
│   │   │   ├── core.md
│   │   │   └── 8.x.md
│   │   ├── testbox/
│   │   │   └── core.md
│   │   └── wirebox/
│   │       └── core.md
│   └── skills/
│       ├── handler-development/
│       │   └── SKILL.md
│       └── testing-bdd/
│           └── SKILL.md
├── CLAUDE.md              # AI agent instructions
├── .mcp.json              # MCP server configuration
└── box.json               # Includes AI config
```

**box.json includes:**

```json
{
  "name": "myapp",
  "version": "1.0.0",
  "language": "boxlang",
  "dependencies": {
    "coldbox": "^8.0.0",
    "testbox": "^5.0.0",
    "cbvalidation": "^3.0.0",
    "quick": "^5.0.0"
  },
  "ai": {
    "enabled": true,
    "agent": "claude",
    "autoDiscoverSkills": true,
    "coreSkills": ["coldbox-development", "boxlang-development", "cfml-development"],
    "discoveredSkills": ["handler-development", "testing-bdd", "validation", "orm-quick"],
    "mcpServers": ["coldbox", "testbox", "cbvalidation", "quick"]
  }
}
```

**Now when you ask Claude Code:**
> "Create a new handler called Users with CRUD actions"

**Claude generates the following if their project is a CFML project:**

```cfml
component extends="coldbox.system.EventHandler" {

    property name="userService" inject="UserService";

    function index( event, rc, prc ){
        prc.users = userService.list()
        event.setView( "users/index" )
    }

    function create( event, rc, prc ){
        event.setView( "users/create" )
    }

    function store( event, rc, prc ){
        var user = userService.create( rc )
        relocate( uri="/users/#user.getId()#" )
    }
    // ... more CRUD actions
}
```

If the project is a BoxLang Project, Claude generates:

```js
class extends="coldbox.system.EventHandler" {

	@inject( "UserService" )
	property name="userService";

    function index( event, rc, prc ){
        prc.users = userService.list()
        event.setView( "users/index" )
    }

    function create( event, rc, prc ){
        event.setView( "users/create" )
    }

    function store( event, rc, prc ){
        var user = userService.create( rc )
        relocate( uri="/users/#user.getId()#" )
    }
    // ... more CRUD actions
}
```

---

### Example 2: Adding AI to Existing Project


```bash
cd /path/to/existing-coldbox-app

# Install AI support
coldbox ai install --agent=cursor

# The CLI detects your installed modules from box.json
# Detected: ColdBox 8.2.0, TestBox 5.x, CBSecurity 3.x, Quick 4.x

# Generated guidelines for:
# - coldbox/8.x
# - testbox/core
# - cbsecurity/core
# - quick/core

# Configured MCP servers:
# - ColdBox MCP
# - TestBox MCP
# - CBSecurity MCP
# - Quick MCP
```

**Generated .cursorrules:**
```markdown
# ColdBox Development with Cursor

You are an expert ColdBox CFML/BoxLang developer...

## Project Context
- ColdBox Framework 8.2.0
- Using Quick ORM for database
- CBSecurity for authentication/authorization
- TestBox for testing

## Guidelines
[Includes content from all detected guidelines]

## Available MCP Servers
- coldbox: Query ColdBox documentation and examples
- testbox: Query testing patterns and examples
- cbsecurity: Query security implementation patterns
- quick: Query ORM usage and patterns
```

---

### Example 3: Working with AI Agent


**Ask AI:**
> "How do I validate user input in ColdBox?"

**AI uses MCP to search CBValidation docs, then responds:**
```java
// Install cbvalidation if not already installed
// box install cbvalidation

// In your handler (BoxLang)
class extends="coldbox.system.EventHandler" {
    property name="validationManager" inject="ValidationManager@cbvalidation";

    store( event, rc, prc ){
        var constraints = {
            email: { required: true, type: "email" },
            password: { required: true, min: 8 }
        }

        var result = validationManager.validate(
            target = rc,
            constraints = constraints
        )

        if( result.hasErrors() ){
            flash.put( "errors", result.getAllErrors() )
            relocate( "users.create" )
}
```

---

### Example 4: Auto-Discovered Skills

```bash
# Install a new module
box install cbwire

# Skills are auto-discovered! Just refresh to sync.
coldbox ai refresh

# List all discovered skills
coldbox ai skills list

# Discovered Skills:
# ⭐ coldbox-development      (core - always installed)
# ⭐ boxlang-development      (core - always installed)
# ⭐ cfml-development         (core - always installed)
# ✓ handler-development      (from coldbox)
# ✓ rest-api-development     (from coldbox)
# ✓ cbwire-development       (from cbwire) ⬅️ NEW!
# ✓ orm-quick                (from quick)
# ✓ validation               (from cbvalidation)
# ✓ testing-bdd              (from testbox)
```

**Now ask AI:**
> "Create a CBWire component for live search"

**AI automatically uses the cbwire-development skill and generates (BoxLang):**
```java
class extends="cbwire.models.Component" {
    property name="userService" inject="UserService";

    data = {
        "searchTerm": "",
        "results": []
    }

    search(){
        if( len( data.searchTerm ) >= 3 ){
            data.results = userService.search( data.searchTerm )
        } else {
            data.results = []
```

---

### Example 5: Querying Documentation


```bash
# Search MCP servers for information
coldbox ai mcp search "event object methods"

# Results from ColdBox MCP:
# 1. Event.getValue() - Get a value from the request collection
# 2. Event.setValue() - Set a value in the private request collection
# 3. Event.setView() - Set the view to render
# 4. Event.setLayout() - Set the layout to use
# [Links to full documentation]

# Get specific API docs
coldbox ai mcp search "Quick ORM relationships"

# Results from Quick MCP:
# 1. hasOne() - Define a one-to-one relationship
# 2. hasMany() - Define a one-to-many relationship
# 3. belongsTo() - Define an inverse relationship
# [Code examples and documentation links]
```

---

### Example 6: Custom Guidelines


```bash
# Create custom guideline for your team
coldbox ai guidelines create team-conventions

# Generates: .ai/guidelines/custom/team-conventions/core.md
```

**Edit the file with your team's conventions:**
```markdown
# Team Development Conventions

## Handler Naming
- Use plural nouns: `Users.cfc`, `Orders.cfc`
- RESTful actions: index, show, create, store, edit, update, delete
Language Choice
**Use BoxLang for all new development** 🌟
- Modern syntax
- Better IDE support
- Future-proof

## Handler Naming (BoxLang)
- Use plural nouns: `Users.bx`, `Orders.bx`
- RESTful actions: index, show, create, store, edit, update, delete
- Use `class` not `component`

## Service Layer (BoxLang)
- All business logic in services
- Services in `/models/services/`
- Inject via WireBox: `property name="userService" inject="UserService";`
- No `function` keyword needed

## Testing
- 100% handler coverage required
- Integration tests for critical workflows
- Use MockData for test fixtures
- BoxLang syntax in testentions!**

---

### Example 7: Module Author Including Guidelines


**Your module: `cbpayments`**

```
modules/cbpayments/
├── ModuleConfig.cfc
├── models/
└── resources/
    └── coldbox-cli/
        └── ai/
            ├── guidelines/
            │   └── core.md
            └── skills/
                └── payment-processing/
```

---

### Example 7.5: How AI Actually Uses Guidelines vs Skills

**Scenario**: User asks: *"Create a secure user registration handler with validation"*

**Step 1 - AI Consults Guidelines** (always in memory):
- `.ai/guidelines/boxlang/core.md` → "Use `class` syntax, properties with `inject`"
- `.ai/guidelines/coldbox/core.md` → "Handlers go in `/handlers/`, extend `EventHandler`"
- `.ai/guidelines/cbsecurity/core.md` → "Use `secured` annotation on actions"
- `.ai/guidelines/cbvalidation/core.md` → "Available constraints: required, type, minLength..."

**Step 2 - AI Requests Skills** (fetched on-demand):
- AI thinks: "I need the IMPLEMENTATION PATTERN for this"
- Loads: `.ai/skills/handler-development/SKILL.md`
- Gets: Complete code template, validation flow pattern, error handling structure

**Step 3 - AI May Query MCP** (if needs latest docs):
- Searches: CBValidation MCP server
- Finds: Current validation constraint API and examples

**Step 4 - AI Generates Code**:

```boxlang
class RegistrationHandler extends coldbox.system.EventHandler {
    property name="validationService" inject;
    property name="userService" inject;

    function register( event, rc, prc ) secured="none" {
        var validationResult = validationService.validate(
            target = rc,
            constraints = {
                email: { required: true, type: "email" },
                password: { required: true, minLength: 8 }
            }
        )

        if ( validationResult.hasErrors() ) {
            return event.renderData(
                type = "json",
                data = validationResult.getAllErrors(),
                statusCode = 400
            )
        }

        var user = userService.create( rc )
        return event.renderData( data = user, statusCode = 201 )
    }
}
```

**Why Each Piece Matters**:
- **Guidelines** = AI knows the vocabulary ("secured", "inject", "renderData" exist)
- **Skills** = AI knows the recipe (validation → service → response pattern)
- **MCP** = AI gets current details ("minLength" not "minlength" in latest version)

**Think of it like cooking**:
- **Guidelines** = Ingredient list (what exists: flour, eggs, sugar)
- **Skills** = Recipe (how to combine: mix, bake at 350°F, frost)
- **MCP** = Ask a chef (is vanilla extract still 1 tsp or did that change?)

## Language Support

Works with both BoxLang and CFML. Examples shown in BoxLang (preferred).

## Configuration
Configure in `config/ColdBox.cfc`:

```java
// BoxLang
moduleSettings = {
    cbpayments = {
        provider = "stripe",
        apiKey = getSystemSetting( "STRIPE_KEY" )
    }
}
```

## Processing Payments (BoxLang)

```java
class extends="coldbox.system.EventHandler" {
    property name="paymentService" inject="PaymentService@cbpayments";

    charge( event, rc, prc ){
        var result = paymentService.charge(
            amount = rc.amount,
            currency = "USD",
            source = rc.token
        )

        if( result.success ){
            // Handle success
        }

    if( result.success ){
        // Handle success
    }
}
```

**When users install your module:**

```bash
box install cbpayments
coldbox ai refresh

# AI now knows about cbpayments!
# Guidelines automatically discovered and installed
```

---

### Example 7.5: How AI Uses Guidelines vs Skills (Concrete Workflow)

**User Request:** "Create a secure user registration handler with validation"

**AI's Internal Workflow:**

1. **Consults Guidelines** (always loaded in memory):
   - `.ai/guidelines/boxlang/core.md` → BoxLang class syntax
   - `.ai/guidelines/coldbox/core.md` → Handler naming, file locations
   - `.ai/guidelines/cbsecurity/core.md` → Security event model
   - `.ai/guidelines/cbvalidation/core.md` → Validation constraints available

2. **Requests Skill** (fetched on-demand):
   - AI thinks: "I need to know the PATTERN for implementing this"
   - Requests: `.ai/skills/handler-development/SKILL.md`
   - Skill provides: Complete handler template, validation setup, security integration

3. **May Query MCP Server** (if needs current docs):
   - Searches CBValidation MCP for constraint examples
   - Gets latest validation rule syntax

4. **Generates Code**:
   - Uses **guideline** knowledge: Correct BoxLang syntax, ColdBox conventions
   - Follows **skill** pattern: Handler structure, security setup, validation flow
   - References **MCP** data: Up-to-date API methods

**Result:**
```boxlang
class RegistrationHandler extends coldbox.system.EventHandler {
    property name="validationService" inject;
    property name="userService" inject;

    function register( event, rc, prc ) secured="none" {
        var validationResult = validationService.validate(
            target = rc,
            constraints = {
                email: { required: true, type: "email" },
                password: { required: true, minLength: 8 }
            }
        );

        if ( validationResult.hasErrors() ) {
            return event.renderData(
                type = "json",
                data = validationResult.getAllErrors(),
                statusCode = 400
            );
        }

        var user = userService.create( rc );
        return event.renderData( data = user, statusCode = 201 );
    }
}
```

**Why It Works:**
- **Guidelines** taught AI the framework vocabulary ("secured", "inject", "renderData")
- **Skill** provided the implementation pattern (validation → service → response)
- **MCP** gave latest constraint options ("minLength" vs old "minlength")

---

### Example 8: Multi-Agent Support

**For Claude Code:**

```bash
coldbox ai install --agent=claude
# Generates: CLAUDE.md with guidelines
```

**Switch to Cursor:**

```bash
coldbox ai install --agent=cursor --force
# Generates: .cursorrules with same guidelines
```

**Support multiple agents:**

```bash
# Install for your whole team
coldbox ai install --agent=claude
coldbox ai install --agent=cursor
coldbox ai install --agent=copilot

# Now team members using different AI tools
# all get the same project guidance!
```

---

### Example 9: Project Lifecycle


**Day 1 - Start new project:**

```bash
coldbox create app myapp --ai --agent=claude
cd myapp
```

**Week 2 - Add security:**

```bash
box install cbsecurity
coldbox ai refresh
# Auto-discovers cbsecurity skills and guidelines
# Adds cbsecurity MCP server automatically
# Security skills now available to AI
```

**Week 4 - Add ORM:**

```bash
box install quick
coldbox ai refresh
# Auto-discovers Quick skills automatically!
# orm-quick skill now available - no activation needed
# AI now understands Quick ORM patterns
```

**Month 2 - Team customization:**

```bash
coldbox ai guidelines create company-standards
# Edit with your patterns
# AI now follows company standards
```

**Month 6 - Maintenance:**

```bash
coldbox ai update
# Refreshes all guidelines to latest versions
# Re-scans dependencies for new/removed modules
# Auto-updates skills based on current packages
# New module features automatically available
```

**Any Time - Check health:**

```bash
coldbox ai doctor
# Diagnoses AI configuration
# ✓ Guidelines loaded: 12 files
# ✓ Skills available: 18 patterns
# ✓ MCP servers: 8 connected, 2 offline
# ✓ Agents configured: Claude, Copilot
# ⚠ Warning: cbsecurity guideline outdated (update available)
# ❌ Error: .mcp.json missing required field "servers"
```

---

### Example 10: AI-Driven Development Flow

**Traditional Flow:**

1. Google "ColdBox validation"
2. Read docs
3. Copy example
4. Adapt to your code
5. Debug issues
6. Repeat for each feature

**With ColdBox AI:**

1. Ask AI: "Add validation to user registration"
2. AI queries CBValidation MCP server
3. AI generates correct code following your conventions
4. AI includes proper error handling
5. Done!

---

## Phase 1: Foundation & Core Structure ✅

**Status**: Completed

### 1.1 Directory Structure ✅

- [x] Create `.ai/` directory structure
- [x] Create `guidelines/` subdirectory
- [x] Create `skills/` subdirectory
- [x] Create `templates/ai/` for agent-specific files
- [ ] Add `.gitignore` entries for AI files

### 1.2 Core Service Components ✅

- [x] Create `AIService.cfc` - Central AI operations service
- [x] Create `GuidelineManager.cfc` - Guideline generation and management
- [x] Create `SkillManager.cfc` - Agent skills management (auto-discovery + core skills)
- [ ] Create `MCPClient.cfc` - MCP server communication
- [x] Create `AgentRegistry.cfc` - Multi-agent support registry
- [ ] Create `utility` methods in `Utility.cfc` for AI operations

### 1.3 AI Manifest System ✅

**Purpose**: Track what guidelines/skills are installed and when, enabling version detection

- [x] **Manifest File**: `.ai/.manifest.json`
  - [ ] `coldboxCliVersion` - coldbox-cli version used during last sync
  - [ ] `lastSync` - ISO timestamp of last `coldbox ai refresh`
  - [ ] `guidelines[]` - Array of installed guidelines with metadata:
    - `name` - Guideline name (e.g., "coldbox-core", "cbsecurity")
    - `source` - Source module/package
    - `installedVersion` - Module version when guideline was installed
    - `syncedAt` - When this guideline was last synced
  - [ ] `skills[]` - Array of installed skills with metadata:
    - `name` - Skill name (e.g., "handler-development")
    - `source` - "core" or module name
    - `installedVersion` - Module version
    - `syncedAt` - When synced
  - [ ] `agents[]` - Configured agents
  - [ ] `language` - Project language mode

- [x] **Manifest Operations**:
  - [x] Create manifest during `coldbox ai install`
  - [x] Update manifest during `coldbox ai refresh`
  - [x] Read manifest in `coldbox ai doctor` for version comparison
  - [x] Track each guideline/skill installation individually

- [x] **Version Detection Logic**:
  - [x] Compare `manifest.coldboxCliVersion` vs current coldbox-cli version
  - [x] If mismatch → recommend `coldbox ai refresh`
  - [x] Compare guideline `installedVersion` vs current module versions in box.json
  - [x] Detect orphaned entries (module uninstalled but guideline remains)

**Example `.ai/.manifest.json`**:
```json
{
  "coldboxCliVersion": "5.2.0",
  "lastSync": "2026-01-27T10:30:00Z",
  "language": "boxlang",
  "guidelines": [
    {
      "name": "coldbox-core",
      "source": "coldbox-cli",
      "installedVersion": "5.2.0",
      "syncedAt": "2026-01-27T10:30:00Z"
    },
    {
      "name": "cbsecurity",
      "source": "cbsecurity",
      "installedVersion": "3.2.1",
      "syncedAt": "2026-01-20T15:00:00Z"
    }
  ],
  "skills": [
    {
      "name": "handler-development",
      "source": "core",
      "installedVersion": "5.2.0",
      "syncedAt": "2026-01-27T10:30:00Z"
    },
    {
      "name": "security-implementation",
      "source": "cbsecurity",
      "installedVersion": "3.2.1",
      "syncedAt": "2026-01-20T15:00:00Z"
    }
  ],
  "agents": ["claude", "copilot"]
}
```

### 1.4 Configuration ✅

- [x] Design `box.json` AI configuration schema
  - [x] `language` - Project language mode: "boxlang", "cfml", "hybrid" (default: "boxlang")
  - [x] `coreSkills` - Always-installed skills based on language mode
  - [x] `autoDiscoverSkills` - Enable automatic skill discovery
  - [x] `discoveredSkills` - Skills found from installed modules
  - [x] `agent` - Configured AI agent(s)
- [x] Create default configuration templates
- [x] Implement configuration validation

### 1.5 Template Files ✅

- [x] Create agent instructions template (generic)
- [x] Create guideline templates (boxlang-core, cfml-core, coldbox-core, testbox-core, wirebox-core)
- [x] Create skill templates (handler-development, skill-template)
- [x] Agent-specific config paths (Claude, Copilot, Cursor, Codex, Gemini, OpenCode)

---

## Phase 2: Command Structure (`coldbox ai` namespace) ⏳

**Status**: In Progress (4 of 11 commands complete)

### 2.1 Installation & Setup Commands ⏳


#### `coldbox ai install` ✅

- [x] Detect project type (ColdBox app, module, standalone)
- [x] Read `language` property from box.json (set by `coldbox create app`)
- [x] If no language property exists, prompt user:
  - [x] "Select project language: (1) BoxLang (default), (2) CFML, (3) Hybrid"
  - [x] Save selected language to box.json
- [x] Scan `box.json` for installed dependencies
- [x] Generate `.ai/` directory structure
- [x] Install core guidelines based on detected packages and language
- [x] Install core skills based on language (boxlang, cfml, or hybrid)
- [x] Optionally install discovered skills
- [x] Generate agent-specific files
- [x] Interactive mode with prompts
- [x] Flags:
  - `--agent=claude,copilot,codex,gemini,opencode` (comma-separated for multiple)
  - [ ] `--guidelines-only`
  - [ ] `--skills-only`
  - `--force` (overwrite existing)
  - [ ] `--no-mcp` (skip MCP configuration)

#### `coldbox ai update` ✅  (alias: `refresh`)

- [x] Re-scan `box.json` dependencies
- [x] Auto-discover skills from installed modules
- [x] Add new guidelines for newly installed packages
- [x] Remove guidelines/skills for uninstalled packages
- [x] Update existing guidelines to latest versions
- [ ] Sync MCP server configurations
- [ ] Re-generate agent files
- [x] **Update `.ai/.manifest.json`**:
  - [x] Set `coldboxCliVersion` to current module version
  - [x] Update `lastSync` timestamp
  - [x] Add/update guideline entries with current versions
  - [x] Add/update skill entries with current versions
  - [x] Remove entries for uninstalled modules
- [x] Report what was added/removed/updated

#### `coldbox ai info` ✅

- [x] Display project AI configuration
- [x] Show detected project language (from box.json)
- [ ] Show detected ColdBox/BoxLang version
- [ ] List installed modules with AI support
- [x] Show installed guidelines
- [x] Show active skills
- [ ] Display project statistics (handlers, models, tests)
- [ ] Show configured MCP servers

### 2.2 Guideline Management Commands ⬜


#### `coldbox ai guidelines list` ⬜

- [ ] List all available guidelines
- [ ] Show installed vs available
- [ ] Group by framework/module
- [ ] Show versions
- [ ] Indicate custom vs core guidelines

#### `coldbox ai guidelines add [name]` ⬜

- [ ] Add specific guideline by name
- [ ] Auto-detect version from box.json
- [ ] Support version override: `coldbox ai guidelines add coldbox@8.x`
- [ ] Download from registry if not available locally

#### `coldbox ai guidelines remove [name]` ⬜

- [ ] Remove specific guideline
- [ ] Confirm before deletion
- [ ] Update agent files

#### `coldbox ai guidelines create [name]` ⬜

- [ ] Scaffold custom guideline template
- [ ] Create in `.ai/guidelines/custom/[name]/`
- [ ] Generate template with proper structure
- [ ] Provide examples and documentation

#### `coldbox ai guidelines override [name]` ⬜

- [ ] Create override for core guideline
- [ ] Copy core guideline as starting point
- [ ] Place in custom location with higher priority
- [ ] Document override in comments

### 2.3 Skills Management Commands ⬜


#### `coldbox ai skills list` ⬜

- [ ] Show core skills first (coldbox, boxlang, cfml - always installed) marked with ⭐
- [ ] Show all auto-discovered skills from installed modules
- [ ] Show source module for each skill
- [ ] Show skill descriptions
- [ ] Group by category (core, framework, testing, ORM, security, modern)
- [ ] Indicate if skill files are available locally vs need download

#### `coldbox ai skills refresh` ⬜

- [ ] Ensure core skills (coldbox, boxlang, cfml) are always present
- [ ] Re-scan box.json dependencies
- [ ] Auto-discover available skills from all installed modules
- [ ] Download/update skill files from module sources
- [ ] Remove skills from uninstalled modules (except core)
- [ ] Preserve custom/project-specific skills
- [ ] Update agent configuration files
- [ ] Report changes: added, removed, updated

#### `coldbox ai skills create [name]` ⬜

- [ ] Scaffold new custom/project-specific skill
- [ ] Generate `SKILL.md` with proper YAML frontmatter
- [ ] Provide template with examples and triggers
- [ ] Create in `.ai/skills/custom/[name]/`
- [ ] Custom skills marked to persist across refreshes
- [ ] Add to project's skill registry

### 2.4 MCP Server Commands ⬜

#### `coldbox ai mcp list` ⬜

- [ ] Show all available MCP servers
- [ ] Display connection status (connected/offline)
- [ ] Show server capabilities
- [ ] Group by category (Ortus docs, third-party, custom)

#### `coldbox ai mcp search [query]` ⬜

- [ ] Search across all connected MCP servers
- [ ] Return relevant documentation snippets
- [ ] Show source server for each result
- [ ] Support filtering by server/category

### 2.5 AI Configuration Commands ⬜

#### `coldbox ai info` ⬜

- [ ] Display current AI configuration summary
- [ ] Show configured agents
- [ ] List loaded guidelines (count + sources)
- [ ] List available skills (count + categories)
- [ ] Show MCP server count and status
- [ ] Display project language mode (boxlang/cfml/hybrid)
- [ ] Show custom guideline/skill status

#### `coldbox ai doctor` ⬜

**Purpose**: Comprehensive diagnostic tool for AI integration health

- [ ] **Configuration Validation**:
  - [ ] Check `.ai/` directory structure
  - [ ] Validate `box.json` AI configuration
  - [ ] Verify agent config files (CLAUDE.md, .github/copilot-instructions.md, etc.)
  - [ ] Check `.mcp.json` format and required fields
  - [ ] **Verify `.ai/.manifest.json` exists and is valid**

- [ ] **Guideline Health**:
  - [ ] Count and list loaded guidelines
  - [ ] Verify guideline file formats (valid markdown)
  - [ ] **Read `.ai/.manifest.json` to get installed versions**
  - [ ] **Compare `manifest.coldboxCliVersion` vs current coldbox-cli version**
  - [ ] **Compare guideline `installedVersion` vs current module versions in box.json**
  - [ ] **Detect orphaned guidelines** (in manifest but module uninstalled)
  - [ ] Detect missing core guidelines
  - [ ] Validate custom guideline structure
  - [ ] Recommend `coldbox ai refresh` if any version mismatches found

- [ ] **Skills Status**:
  - [ ] Verify core skills present (coldbox, boxlang, cfml)
  - [ ] Count auto-discovered skills by category
  - [ ] **Compare skill versions in manifest vs current module versions**
  - [ ] Check for orphaned skills (module uninstalled but skill remains)
  - [ ] Validate SKILL.md frontmatter and structure
  - [ ] Detect skill conflicts or duplicates

- [ ] **MCP Server Connectivity**:
  - [ ] Ping all configured MCP servers
  - [ ] Report connection status (online/offline/timeout)
  - [ ] Test search capability on each server
  - [ ] Verify server capabilities match expected
  - [ ] Check for unreachable servers and suggest removal

- [ ] **Module Integration**:
  - [ ] Compare installed modules vs available guidelines
  - [ ] Suggest missing guidelines for installed modules
  - [ ] Detect modules with AI support not yet synced
  - [ ] Recommend `coldbox ai refresh` if discrepancies found

- [ ] **Report Format**:
  - [ ] Use color-coded output (✓ green, ⚠ yellow, ❌ red)
  - [ ] Provide actionable recommendations
  - [ ] Summary statistics at end
  - [ ] Optional `--json` flag for programmatic use
  - [ ] Optional `--verbose` for detailed diagnostics

**Example Output**:
```
AI Integration Health Check
===========================

✓ Configuration
  ✓ .ai/ directory structure valid
  ✓ box.json AI config present
  ✓ Language: boxlang
  ⚠ .mcp.json missing "timeout" field (using default)

✓ Guidelines (12 loaded)
  ✓ Core: coldbox, boxlang, testbox
  ✓ Security: cbsecurity, cbauth
  ⚠ cbvalidation guideline outdated (v2.1.0 available, you have v2.0.5)
  ⚠ coldbox-cli v5.2.0 installed, but guidelines are from v5.1.0
     → Run 'coldbox ai refresh' to update guidelines/skills

✓ Skills (18 patterns)
  ✓ Core skills: coldbox-development, boxlang-development, cfml-development
  ✓ ColdBox: 9 skills
  ✓ Testing: 8 skills
  ❌ Missing: orm-quick skill (Quick module installed but skill not synced)

⚠ MCP Servers (8/10 connected)
  ✓ ColdBox, BoxLang, TestBox, CBSecurity
  ✓ Quick, QB, WireBox, LogBox
  ❌ CBValidation server offline (check network/firewall)
  ❌ CFML in 100 Minutes timeout (server may be down)

✓ Agents (2 configured)
  ✓ Claude: CLAUDE.md valid
  ✓ Copilot: .github/copilot-instructions.md valid

Recommendations:
• Run 'coldbox ai refresh' to sync orm-quick skill
• Run 'coldbox ai refresh' to update guidelines/skills to coldbox-cli v5.2.0
• Check connectivity to CBValidation MCP server
• Consider removing offline MCP servers if persistently unavailable

Overall Status: 🟡 Good (3 warnings, 4 recommendations)
```

### 2.6 Agent Management Commands ⬜


#### `coldbox ai mcp list` ⬜

- [ ] List all available Ortus MCP servers
- [ ] Show connection status
- [ ] Display enabled vs available

#### `coldbox ai mcp test [server]` ⬜

- [ ] Test connection to specific MCP server
- [ ] Show available tools/resources
- [ ] Validate configuration

#### `coldbox ai mcp search [query]` ⬜

- [ ] Search across all configured MCP servers
- [ ] Return relevant documentation
- [ ] Show source server and links
- [ ] Support semantic search

### 2.5 Agent Management Commands ⬜

#### `coldbox ai agents list` ⬜

- [ ] Show all supported agents (Claude, Copilot, Codex, Gemini,, OpenCode)
- [ ] Indicate which agents are configured/active in project
- [ ] Show agent-specific configuration files present
- [ ] Display agent capabilities

#### `coldbox ai agents add [name,name,...]` ⬜

- [ ] Add one or more agents to project
- [ ] Generate agent-specific configuration files
- [ ] Support comma-separated list: `coldbox ai agents add claude,copilot,gemini`
- [ ] Update box.json with configured agents
- [ ] Generate MCP configuration for each agent
- [ ] Flags:
  - `--force` (overwrite existing agent files)

#### `coldbox ai agents remove [name,name,...]` ⬜

- [ ] Remove one or more agents from project
- [ ] Delete agent-specific configuration files
- [ ] Support comma-separated list: `coldbox ai agents remove codex`
- [ ] Update box.json
- [ ] Confirm before deletion (unless `--force`)

#### `coldbox ai agents active` ⬜

- [ ] Show only configured/active agents in current project
- [ ] Display configuration file paths
- [ ] Show last modified dates

---

## Phase 3: App Generation Integration ⬜

**Status**: Not Started

### 3.1 Enhance `coldbox create app` ⬜

- [ ] Add `--ai` flag
- [ ] Add `--agent=[name]` flag
- [ ] Generate AI files during app creation
- [ ] Add AI configuration to box.json
- [ ] Install recommended guidelines
- [ ] Install recommended skills

### 3.2 Enhance `coldbox create app-wizard` ⬜

- [ ] Add AI setup section to wizard
- [ ] Question: "Enable AI assistance? (Y/n)"
- [ ] Question: "Which AI agent do you use?"
- [ ] Question: "Install recommended guidelines? (Y/n)"
- [ ] Question: "Install recommended skills? (Y/n)"
- [ ] Generate files based on selections

### 3.3 Module Creation Integration ⬜

- [ ] Add AI support to `coldbox create module`
- [ ] Generate module-specific guidelines structure
- [ ] Document how module authors can include guidelines

---

## Phase 4: Core Guidelines Content ⬜

**Status**: Not Started

### 4.1 ColdBox Framework Guidelines ⬜

- [ ] **ColdBox Framework**
  - [ ] `coldbox/core.md` - Core conventions
  - [ ] `coldbox/7.x.md` - Version 7 specific
  - [ ] `coldbox/8.x.md` - Version 8 specific
  - [ ] Handler patterns and routing
  - [ ] Event object usage
  - [ ] Module structure
  - [ ] Layouts and views
  - [ ] Interceptors
  - [ ] Configuration patterns

### 4.2 Core Framework Guidelines ⬜


- [ ] **BoxLang** ⭐ (PRIMARY LANGUAGE)
  - [ ] `boxlang/core.md` - BoxLang language fundamentals
  - [ ] `boxlang/syntax.md` - BoxLang vs CFML syntax differences
  - [ ] `boxlang/classes.md` - Class-based development patterns
  - [ ] `boxlang/modern-features.md` - Modern language features
  - [ ] BoxLang-specific ColdBox patterns
  - [ ] Reference: https://boxlang.ortusbooks.com/getting-started/overview/syntax-style-guide/cfml

- [ ] **CFML**
  - [ ] `cfml/core.md` - CFML language fundamentals and syntax
  - [ ] CFML-specific patterns
  - [ ] Component-based development
  - [ ] Function syntax patterns
  - [ ] Reference: https://modern-cfml.ortusbooks.com
  - [ ] Note: Available for CFML and hybrid projects (excluded only in BoxLang-only mode)

- [ ] **CacheBox**
  - [ ] `cachebox/core.md`
  - [ ] Caching strategies
  - [ ] Provider patterns
  - [ ] Cache event handling

- [ ] **WireBox**
  - [ ] `wirebox/core.md`
  - [ ] Dependency injection patterns
  - [ ] Binder DSL
  - [ ] Provider patterns
  - [ ] AOP usage

- [ ] **LogBox**
  - [ ] `logbox/core.md`
  - [ ] Logger usage
  - [ ] Appender configuration
  - [ ] Custom appenders

- [ ] **TestBox**
  - [ ] `testbox/core.md`
  - [ ] BDD vs xUnit testing
  - [ ] Spec structure
  - [ ] Mocking patterns
  - [ ] Integration testing

- [ ] **CommandBox**
  - [ ] `commandbox/core.md`
  - [ ] Command development
  - [ ] Package development
  - [ ] Task runners

### 4.3 Security & Auth Guidelines ⬜

- [ ] **cbsecurity** - `cbsecurity/core.md`
- [ ] **cbauth** - `cbauth/core.md`
- [ ] **cbsecurity-passkeys** - `cbsecurity-passkeys/core.md`
- [ ] **cbsso** - `cbsso/core.md`
- [ ] **cbcsrf** - `cbcsrf/core.md`
- [ ] **cbantisamy** - `cbantisamy/core.md`

### 4.4 Validation & Data Guidelines ⬜

- [ ] **cbvalidation** - `cbvalidation/core.md`
- [ ] **cbi18n** - `cbi18n/core.md`
- [ ] **cbmailservices** - `cbmailservices/core.md`
- [ ] **cbmessagebox** - `cbmessagebox/core.md`
- [ ] **cbpaginator** - `cbpaginator/core.md`
- [ ] **cbfeeds** - `cbfeeds/core.md`

### 4.5 ORM & Database Guidelines ⬜

- [ ] **cborm** - `cborm/core.md`
- [ ] **qb** (Query Builder) - `qb/core.md`
- [ ] **quick** (ORM) - `quick/core.md`
- [ ] **cfmigrations** - `cfmigrations/core.md`

### 4.6 API & Integration Guidelines ⬜

- [ ] **hyper** - `hyper/core.md`
- [ ] **cbproxies** - `cbproxies/core.md`
- [ ] **cbswagger** - `cbswagger/core.md`
- [ ] **cbelasticsearch** - `cbelasticsearch/core.md`
- [ ] **s3sdk** - `s3sdk/core.md`

### 4.7 Utility & Development Guidelines ⬜

- [ ] **docbox** - `docbox/core.md`
- [ ] **cbdebugger** - `cbdebugger/core.md`
- [ ] **cbfs** - `cbfs/core.md`
- [ ] **cbstorages** - `cbstorages/core.md`
- [ ] **stachebox** - `stachebox/core.md`
- [ ] **cbjavaloader** - `cbjavaloader/core.md`
- [ ] **cbmarkdown** - `cbmarkdown/core.md`
- [ ] **cbmockdata** - `cbmockdata/core.md`

### 4.8 Modern Development Guidelines ⬜

- [ ] **cbwire** (Livewire-style) - `cbwire/core.md`
- [ ] **cbq** (Queue) - `cbq/core.md`
- [ ] **socketbox** - `socketbox/core.md`
- [ ] **mementifier** - `mementifier/core.md`
- [ ] **unleashsdk** - `unleashsdk/core.md`
- [ ] **cbplaywright** - `cbplaywright/core.md`

### 4.9 Guideline Template Structure ⬜

- [ ] Define standard guideline format
- [ ] YAML frontmatter schema
- [ ] Markdown structure conventions
- [ ] Code example patterns
- [ ] Best practices documentation

---

## Phase 5: Core Skills Content ⬜

**Status**: Not Started

### 5.1 Core Skills (Always Installed) ⬜

- [ ] **coldbox-development** ⭐ - ColdBox framework patterns (ALWAYS INSTALLED)
- [ ] **boxlang-development** ⭐ - BoxLang language features and patterns (language mode = boxlang|hybrid)
- [ ] **cfml-development** ⭐ - CFML language fundamentals and syntax (language mode = cfml|hybrid)
  - [ ] Based on "CFML in 100 Minutes" content
  - [ ] CFML syntax and conventions
  - [ ] Component-based development
  - [ ] Function syntax patterns
  - [ ] Reference: https://modern-cfml.ortusbooks.com
  - [ ] Note: Available for all projects unless explicitly BoxLang-only mode

### 5.2 BoxLang Development Skills ⬜

- [ ] **boxlang-syntax** - BoxLang class syntax, properties, methods
- [ ] **boxlang-classes** - Class definition patterns and inheritance
- [ ] **boxlang-functions** - Function types (class methods, lambdas, closures)
- [ ] **boxlang-lambdas** - Lambda expressions and functional patterns
- [ ] **boxlang-modules** - BoxLang module system and imports
- [ ] **boxlang-streams** - Stream API and functional data processing
- [ ] **boxlang-types** - Type system and type checking
- [ ] **boxlang-interop** - CFML/Java interoperability patterns

### 5.3 ColdBox Development Skills ⬜

**Priority: HIGHEST** - Core framework deserves extensive coverage

- [ ] **handler-development** - Creating and managing handlers (BoxLang first)
- [ ] **rest-api-development** - Building REST APIs (BoxLang examples)
- [ ] **module-development** - Creating ColdBox modules (BoxLang preferred)
- [ ] **interceptor-development** - Building interceptors and event interception
- [ ] **layout-development** - Creating layouts and views
- [ ] **routing-development** - Route configuration and URL management
- [ ] **event-model** - Event-driven architecture and event handlers
- [ ] **view-rendering** - View rendering patterns and helpers
- [ ] **cache-integration** - CacheBox integration and caching strategies

**Total: 9 skills**

### 5.4 Testing Skills ⬜

**Priority: HIGHEST** - Testing is critical

- [ ] **testing-bdd** - BDD testing with TestBox specs and suites
- [ ] **testing-unit** - Unit testing patterns and assertions
- [ ] **testing-integration** - Integration testing strategies
- [ ] **testing-handler** - Handler test patterns and HTTP testing
- [ ] **testing-mocking** - MockBox mocking and stubbing
- [ ] **testing-fixtures** - Test data fixtures and factories
- [ ] **testing-coverage** - Code coverage analysis and reporting
- [ ] **testing-ci** - CI/CD integration and automated testing

**Total: 8 skills**

### 5.5 Security Skills ⬜

**Priority: HIGHEST** - Security needs comprehensive coverage

- [ ] **security-implementation** - CBSecurity setup and configuration
- [ ] **authentication** - CBAuth user authentication patterns
- [ ] **authorization** - Security rules, permissions, and firewall
- [ ] **sso-integration** - CBSSO single sign-on setup
- [ ] **jwt-development** - JWT token generation and validation
- [ ] **passkeys-integration** - Passkeys/WebAuthn implementation
- [ ] **csrf-protection** - CSRF token handling and validation
- [ ] **api-authentication** - API key and token authentication
- [ ] **rbac-patterns** - Role-based access control implementation

**Total: 9 skills**

### 5.6 ORM & Database Skills ⬜

**Priority: MEDIUM**

- [ ] **orm-quick** - Quick ORM entities and relationships
- [ ] **query-builder** - QB fluent query building
- [ ] **database-migrations** - Database migrations and schema management
- [ ] **orm-relationships** - Complex relationships and eager loading

**Total: 4 skills**

### 5.7 Modern Development Skills ⬜

**Priority: MEDIUM**

- [ ] **cbwire-development** - Building reactive CBWire components
- [ ] **queue-development** - CBQ queue processing and async jobs
- [ ] **websocket-development** - SocketBox real-time communication

**Total: 3 skills**

---

**Skill Summary:**
- BoxLang: 8 skills (20%) - HIGHEST PRIORITY
- ColdBox: 9 skills (22%) - HIGHEST PRIORITY
- Testing: 8 skills (20%) - HIGHEST PRIORITY
- Security: 9 skills (22%) - HIGHEST PRIORITY
- ORM/Database: 4 skills (10%) - MEDIUM
- Modern: 3 skills (7%) - MEDIUM

**Grand Total: 41 skills**
**High Priority Skills: 34 (83%)**

### 5.8 Skill Template Structure ⬜

- [ ] Define Agent Skills format (YAML + Markdown)
- [ ] Required frontmatter fields
- [ ] Skill structure conventions
- [ ] When to use guidelines vs skills documentation

---

## Phase 6: MCP Server Integration ⬜

**Status**: Not Started

### 6.1 MCP Client Implementation ⬜

- [ ] Implement MCP protocol communication
- [ ] Handle stdio-based MCP connections
- [ ] Support multiple concurrent MCP servers
- [ ] Connection pooling and management
- [ ] Error handling and retries

### 6.2 Ortus MCP Server Registry ⬜

- [ ] Define MCP server registry structure
- [ ] Register all Ortus MCP servers:
  - [ ] CFML in 100 Minutes - https://modern-cfml.ortusbooks.com/~gitbook/mcp
  - [ ] BoxLang - https://boxlang.ortusbooks.com/~gitbook/mcp
  - [ ] CommandBox - https://commandbox.ortusbooks.com/~gitbook/mcp
  - [ ] TestBox - https://testbox.ortusbooks.com/~gitbook/mcp
  - [ ] ColdBox - https://coldbox.ortusbooks.com/~gitbook/mcp
  - [ ] CacheBox - https://cachebox.ortusbooks.com/~gitbook/mcp
  - [ ] LogBox - https://logbox.ortusbooks.com/~gitbook/mcp
  - [ ] WireBox - https://wirebox.ortusbooks.com/~gitbook/mcp
  - [ ] CBQ - https://cbq.ortusbooks.com/~gitbook/mcp
  - [ ] QB - https://qb.ortusbooks.com/~gitbook/mcp
  - [ ] Quick - https://quick.ortusbooks.com/~gitbook/mcp
  - [ ] CBSecurity - https://coldbox-security.ortusbooks.com/~gitbook/mcp
  - [ ] CBMailservices - https://coldbox-mailservices.ortusbooks.com/~gitbook/mcp
  - [ ] CBValidation - https://coldbox-validation.ortusbooks.com/~gitbook/mcp
  - [ ] CBI18N - https://coldbox-i18n.ortusbooks.com/~gitbook/mcp
  - [ ] CBFS - https://cbfs.ortusbooks.com/~gitbook/mcp
  - [ ] CBORM - https://coldbox-orm.ortusbooks.com/~gitbook/mcp
  - [ ] CBAuth - https://cbauth.ortusbooks.com/~gitbook/mcp
  - [ ] CBDebugger - https://cbdebugger.ortusbooks.com/~gitbook/mcp
  - [ ] CBElasticsearch - https://cbelasticsearch.ortusbooks.com/~gitbook/mcp
  - [ ] CBSSO - https://cbsso.ortusbooks.com/~gitbook/mcp
  - [ ] CBStreams - https://cbstreams.ortusbooks.com/~gitbook/mcp
  - [ ] DocBox - https://docbox.ortusbooks.com/~gitbook/mcp
  - [ ] BXORM - https://bxorm.ortusbooks.com/~gitbook/mcp
  - [ ] RuleBox - https://rulebox.ortusbooks.com/~gitbook/mcp
  - [ ] BoxLang IDE - https://boxlang-ide.ortusbooks.com/~gitbook/mcp
  - [ ] CBWire - https://cbwire.ortusbooks.com/~gitbook/mcp
  - [ ] Megaphone - https://megaphone.ortusbooks.com/~gitbook/mcp

### 6.3 MCP Tool Integration ⬜

- [ ] Search documentation tool
- [ ] Get code examples tool
- [ ] Query API references tool
- [ ] Get module information tool
- [ ] Search best practices tool

### 6.4 Documentation Search Features ⬜

- [ ] Semantic search across MCP servers
- [ ] Keyword-based search
- [ ] Filter by framework/module
- [ ] Filter by version
- [ ] Return formatted results with links
- [ ] Cache search results locally

### 6.5 MCP Configuration Generation ⬜

- [ ] Generate `.mcp.json` for agent configuration
- [ ] Include all relevant MCP servers based on installed packages
- [ ] Auto-configure connection details
- [ ] Support custom MCP servers

---

## Phase 7: Multi-Agent Support ⬜

**Status**: Not Started

### 7.1 Agent Detection ⬜

- [ ] Implement agent detection logic
- [ ] Registry for supported agents:
  - [ ] Claude
  - [ ] GitHub Copilot
  - [ ] Codex
  - [ ] Gemini
  - [ ] OpenCode
- [ ] Agent capability detection
- [ ] Auto-detect agent from environment

### 7.2 Agent-Specific File Generation ⬜


#### Claude Support ⬜

- [ ] Generate `CLAUDE.md` with guidelines
- [ ] Include MCP configuration
- [ ] Format skills for Claude
- [ ] Test with Claude (Code, Projects, etc.)

#### GitHub Copilot Support ⬜

- [ ] Generate `.github/copilot-instructions.md`
- [ ] Support Copilot-specific formatting
- [ ] Include MCP server configuration
- [ ] Test with VS Code Copilot

#### Codex Support ⬜

- [ ] Generate Codex-specific configuration
- [ ] MCP integration for Codex
- [ ] Test with Codex

#### Gemini Support ⬜

- [ ] Generate Gemini-specific files
- [ ] MCP server configuration
- [ ] Test with Gemini

#### OpenCode Support ⬜

- [ ] Generate `.opencode/` configuration
- [ ] Skills directory structure
- [ ] MCP integration
- [ ] Test with OpenCode

### 7.3 Universal Agent Support ⬜

- [ ] Generate `AGENTS.md` (generic guidelines)
- [ ] Support for unknown/future agents
- [ ] Fallback configuration

---

## Phase 8: Custom Guidelines & Overrides ⬜

**Status**: Not Started

### 8.1 Custom Guidelinines directory structure

- [ ] Custom guidelines in `.ai/guidelines/custom/`
- [ ] Guidelines discovery mechanism
- [ ] Validation of custom guidelines
- [ ] Documentation for creating custom guidelines

### 8.2 Core Guideline Overrides ⬜

- [ ] Override mechanism for core guidelines
- [ ] Priority system (custom > override > core)
- [ ] Copy core guideline as starting point
- [ ] Warning when overriding core guidelines
- [ ] Documentation for override patterns

### 8.3 Custom Skills Support ⬜

- [ ] Custom skills in `.ai/skills/custom/`
- [ ] Skill validation (YAML frontmatter)
- [ ] Skill discovery and registration
- [ ] Documentation for creating custom skills

---

## Phase 9: Third-Party Module Support ⬜

**Status**: Not Started

### 9.1 Module Guidelinsources/coldbox-cli/ai/guidelines/`

- [ ] Auto-register discovered guidelines
- [ ] Version matching for module guidelines
- [ ] Priority handling (module vs core)

### 9.2 Module Skills Discovery ⬜

- [ ] Scan modules for `resources/coldbox-cli/ai/skills/`
- [ ] Auto-register discovered skills
- [ ] Skill activation based on module presence

### 9.3 Module Author Documentation ⬜

- [ ] Guidelines for including AI files in modules
- [ ] Example module structure
- [ ] Best practices for module guidelines
- [ ] Template files for module authors

---

## Phase 10: Documentation & Examples ⬜

**Status**: Not Started

### 10.1 User Documenta

- [ ] Command reference
- [ ] Configuration guide
- [ ] Best practices
- [ ] Troubleshooting guide

### 10.2 Guideline Writing Guide ⬜

- [ ] How to write effective guidelines
- [ ] Structure and format
- [ ] Code example patterns
- [ ] Version-specific guidelines

### 10.3 Skill Writing Guide ⬜

- [ ] Agent Skills format
- [ ] When to use skills vs guidelines
- [ ] YAML frontmatter reference
- [ ] Best practices

### 10.4 Module Author Guide ⬜

- [ ] Including guidelines in modules
- [ ] Including skills in modules
- [ ] Testing and validation
- [ ] Examples

### 10.5 Example Projects ⬜

- [ ] Sample app with AI configured
- [ ] Sample module with AI support
- [ ] Various agent configurations

---

## Phase 11: Testing & Quality Assurance ⬜

- [ ] Number of guidelines created: **Target: 40+**
- [ ] Number of skills created: **Target: 20-25+**
- [ ] Number of MCP servers integrated: **Target: 25** (added CFML in 100 Minutes)
- [ ] Number of agents supported: **Target: 6** (Claude, Copilot, Codex, Gemini, OpenCode)
- [ ] Documentation coverage: **Target: 100%**
- [ ] Community adoption rate
- [ ] AI-generated code quality improvement
- [ ] Developer productivity improvement

## Quick Reference

**Total Phases**: 12
**Completed**: 0
**In Progress**: 0
**Not Started**: 12

**Overall Progress**: ⬜⬜⬜⬜⬜⬜⬜⬜⬜⬜ 0%
0
**Completed**: 0
**In Progress**: 0
**Not Started**: 10
