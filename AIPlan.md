# ColdBox CLI AI Integration - Implementation Plan

> **Status**: Phase 4 - 100% Complete 🎉
> **Last Updated**: February 10, 2026

## Implementation Phases

### ✅ Phase 1: Foundation (100% Complete)

**Core Services:**
- ✅ AIService.cfc - Central orchestration service
- ✅ GuidelineManager.cfc - Guidelines discovery and management
- ✅ SkillManager.cfc - Skills discovery and management
- ✅ AgentRegistry.cfc - Agent configuration and file generation
- ✅ BaseAICommand.cfc - Common command functionality

**Template System:**
- ✅ Guideline templates (core, custom, override, fallback)
- ✅ Skill templates (core, custom)
- ✅ Agent instruction templates (fallback)
- ✅ Layout-specific templates (modern, flat, boxlang)

**Manifest System:**
- ✅ `.ai/.manifest.json` schema and versioning
- ✅ Installed guidelines tracking
- ✅ Discovered skills registry
- ✅ Agent configuration tracking
- ✅ Language mode tracking

---

### ✅ Phase 2: CLI Commands (100% Complete - excluding MCP)

**Core Commands (4/4):**
- ✅ `coldbox ai install` - Set up AI integration
- ✅ `coldbox ai refresh` - Sync with installed modules (syncs custom & override guidelines from filesystem)
- ✅ `coldbox ai info` - Display current configuration
- ✅ `coldbox ai doctor` - Diagnose health and issues

**Guideline Management (5/5):**
- ✅ `coldbox ai guidelines list` - Show installed guidelines (with type grouping)
- ✅ `coldbox ai guidelines add` - Install specific guideline
- ✅ `coldbox ai guidelines remove` - Remove guideline (with explicit --core|--module|--custom|--override flags)
- ✅ `coldbox ai guidelines create` - Create custom guideline
- ✅ `coldbox ai guidelines override` - Override core/module guideline (template-based)

**Skills Management (3/3):**
- ✅ `coldbox ai skills list` - Show available skills
- ✅ `coldbox ai skills refresh` - Sync with modules
- ✅ `coldbox ai skills create` - Create custom skill

**Agent Management (4/4):**
- ✅ `coldbox ai agents list` - Show configured agents
- ✅ `coldbox ai agents add` - Add agent configuration(s)
- ✅ `coldbox ai agents remove` - Remove agent
- ✅ `coldbox ai agents active` - Show/set active agent

**MCP Commands (0/2 - DEFERRED):**
- ⬜ `coldbox ai mcp list` - Show available MCP servers
- ⬜ `coldbox ai mcp search` - Search across documentation

---

### ⬜ Phase 3: Application Integration

**Integration Points:**
- ⬜ Add to `coldbox create app` wizard
- ⬜ Add to `coldbox create app-wizard` flow
- ⬜ Add `--ai` flag support
- ⬜ Detect existing app structure
- ⬜ Analyze project patterns
- ⬜ Generate project-specific context
- ⬜ Auto-populate custom guidelines
- ⬜ Add AI support to `coldbox create module`

---

### ✅ Phase 4: Core Guidelines Content (100% Complete - 40/40)

**Core Frameworks (9/9 - 100%):**
- ✅ `coldbox.md` - Core conventions, handlers, routing, events, modules, layouts, interceptors
- ✅ `coldbox-cli.md` - CLI commands, application creation, scaffolding, AI integration
- ✅ `boxlang.md` - Language fundamentals, syntax, classes, modern features
- ✅ `cfml.md` - Language fundamentals, syntax, component-based development
- ✅ `cachebox.md` - Caching strategies, providers, events
- ✅ `wirebox.md` - DI patterns, binder DSL, providers, AOP
- ✅ `logbox.md` - Logger usage, appenders, configuration
- ✅ `testbox.md` - BDD/xUnit testing, specs, mocking, integration
- ✅ `docbox.md` - Documentation generation and standards

**Security & Auth (6/6 - 100%):**
- ✅ `cbsecurity.md` - Security rules, authentication, authorization
- ✅ `cbauth.md` - User authentication patterns
- ✅ `cbsecurity-passkeys.md` - WebAuthn/Passkeys integration
- ✅ `cbsso.md` - Single sign-on integration
- ✅ `cbcsrf.md` - CSRF protection
- ✅ `cbantisamy.md` - XSS prevention

**Validation & Data (6/6 - 100%):**
- ✅ `cbvalidation.md` - Validation rules and constraints
- ✅ `cbi18n.md` - Internationalization and localization
- ✅ `cbmailservices.md` - Email protocols and templating
- ✅ `cbmessagebox.md` - Flash messaging
- ✅ `cbpaginator.md` - Pagination helpers
- ✅ `cbfeeds.md` - RSS/Atom feed parsing

**ORM & Database (4/4 - 100%):**
- ✅ `cborm.md` - ORM utilities and event handling
- ✅ `qb.md` - Query builder fluent API
- ✅ `quick.md` - Active Record ORM patterns
- ✅ `cfmigrations.md` - Database migrations

**API & Integration (5/5 - 100%):**
- ✅ `hyper.md` - HTTP client for REST APIs
- ✅ `cbproxies.md` - Proxy patterns and AOP
- ✅ `cbswagger.md` - OpenAPI/Swagger documentation
- ✅ `cbelasticsearch.md` - Elasticsearch integration
- ✅ `s3sdk.md` - AWS S3 integration

**Utility & Development (8/8 - 100%):**
- ✅ `cbdebugger.md` - Debugging tools and profiler
- ✅ `cbfs.md` - File system abstraction
- ✅ `cbstorages.md` - Storage abstractions (session, cookie, cache)
- ✅ `stachebox.md` - Mustache/Handlebars templating
- ✅ `cbjavaloader.md` - Java class loading
- ✅ `cbmarkdown.md` - Markdown processing
- ✅ `cbmockdata.md` - Test data generation
- ✅ `docbox.md` - Documentation generation (listed in Core)

**Modern Development (6/6 - 100%):**
- ✅ `cbwire.md` - LiveWire-style reactive components
- ✅ `cbq.md` - Job queues and background processing
- ✅ `socketbox.md` - WebSocket real-time communication
- ✅ `mementifier.md` - DTO/memento pattern
- ✅ `unleashsdk.md` - Feature flags and A/B testing
- ✅ `cbplaywright.md` - E2E browser testing with Playwright

**Additional Guidelines (7):**
- ✅ `bcrypt.md` - Password hashing
- ✅ `cors.md` - CORS handling
- ✅ `rulebox.md` - Business rules engine
- ✅ `commandbox-migrations.md` - CommandBox migration commands
- ✅ `commandbox-boxlang.md` - BoxLang CLI tools
- ✅ `route-visualizer.md` - Route visualization
- ✅ `relax.md` - REST API documentation

**Total: 40/40 guidelines complete (100%)** 🎉

---

### ⬜ Phase 5: Core Skills Content

**BoxLang Development (8 skills - 20%):**
- ⬜ `boxlang-syntax` - Class syntax, properties, methods
- ⬜ `boxlang-classes` - Class definition patterns
- ⬜ `boxlang-functions` - Function types and patterns
- ⬜ `boxlang-lambdas` - Lambda expressions
- ⬜ `boxlang-modules` - Module system
- ⬜ `boxlang-streams` - Stream API
- ⬜ `boxlang-types` - Type system
- ⬜ `boxlang-interop` - CFML/Java interop

**ColdBox Development (9 skills - 22%):**
- ⬜ `handler-development` - Handler patterns
- ⬜ `rest-api-development` - REST APIs
- ⬜ `module-development` - ColdBox modules
- ⬜ `interceptor-development` - Interceptors
- ⬜ `layout-development` - Layouts and views
- ⬜ `routing-development` - Route configuration
- ⬜ `event-model` - Event-driven architecture
- ⬜ `view-rendering` - View patterns
- ⬜ `cache-integration` - CacheBox integration

**Testing (8 skills - 20%):**
- ⬜ `testing-bdd` - BDD testing with TestBox
- ⬜ `testing-unit` - Unit testing patterns
- ⬜ `testing-integration` - Integration testing
- ⬜ `testing-handler` - Handler testing
- ⬜ `testing-mocking` - MockBox patterns
- ⬜ `testing-fixtures` - Test fixtures
- ⬜ `testing-coverage` - Coverage analysis
- ⬜ `testing-ci` - CI/CD integration

**Security (9 skills - 22%):**
- ⬜ `security-implementation` - CBSecurity setup
- ⬜ `authentication` - CBAuth patterns
- ⬜ `authorization` - Security rules
- ⬜ `sso-integration` - CBSSO setup
- ⬜ `jwt-development` - JWT tokens
- ⬜ `passkeys-integration` - WebAuthn
- ⬜ `csrf-protection` - CSRF handling
- ⬜ `api-authentication` - API auth
- ⬜ `rbac-patterns` - Role-based access

**ORM & Database (4 skills - 10%):**
- ⬜ `orm-quick` - Quick ORM patterns
- ⬜ `query-builder` - QB fluent queries
- ⬜ `database-migrations` - Migrations
- ⬜ `orm-relationships` - Relationships

**Modern Development (3 skills - 7%):**
- ⬜ `cbwire-development` - CBWire components
- ⬜ `queue-development` - CBQ queues
- ⬜ `websocket-development` - SocketBox

**Total: 41 skills (34 high priority = 83%)**

---

### ⬜ Phase 6: MCP Server Integration

**MCP Client:**
- ⬜ MCP protocol communication
- ⬜ stdio-based connections
- ⬜ Connection pooling
- ⬜ Error handling and retries

**Ortus MCP Servers (25 total):**
- ⬜ CFML in 100 Minutes
- ⬜ BoxLang
- ⬜ CommandBox
- ⬜ TestBox
- ⬜ ColdBox
- ⬜ CacheBox, LogBox, WireBox
- ⬜ CBQ, QB, Quick
- ⬜ CBSecurity, CBAuth, CBSSO
- ⬜ CBMailservices, CBValidation, CBI18N
- ⬜ CBFS, CBORM
- ⬜ CBDebugger, CBElasticsearch
- ⬜ CBStreams, DocBox
- ⬜ BXORM, RuleBox
- ⬜ BoxLang IDE
- ⬜ CBWire, Megaphone

**MCP Tools:**
- ⬜ Search documentation
- ⬜ Get code examples
- ⬜ Query API references
- ⬜ Get module information
- ⬜ Search best practices

**Configuration:**
- ⬜ Generate `.mcp.json`
- ⬜ Auto-configure based on packages
- ⬜ Support custom MCP servers

---

### ⬜ Phase 7: Multi-Agent Support

**Agent Detection:**
- ⬜ Agent detection logic
- ⬜ Agent capability detection
- ⬜ Auto-detect from environment

**Agent Support (6 agents):**
- ⬜ Claude - `CLAUDE.md`
- ⬜ GitHub Copilot - `.github/copilot-instructions.md`
- ⬜ Codex - Codex-specific config
- ⬜ Gemini - Gemini-specific files
- ⬜ OpenCode - `.opencode/` config
- ⬜ Universal - `AGENTS.md` fallback

**Agent Integration:**
- ⬜ MCP configuration per agent
- ⬜ Agent-specific formatting
- ⬜ Test with each agent platform

---

### ⬜ Phase 8: Custom Guidelines & Overrides

**Custom Guidelines:**
- ⬜ `.ai/guidelines/custom/` structure
- ⬜ Guidelines discovery
- ⬜ Validation
- ⬜ Documentation

**Core Overrides:**
- ⬜ Override mechanism
- ⬜ Priority system (custom > override > core)
- ⬜ Copy core as starting point
- ⬜ Override warnings
- ⬜ Documentation

**Custom Skills:**
- ⬜ `.ai/skills/custom/` structure
- ⬜ Skill validation (YAML)
- ⬜ Discovery and registration
- ⬜ Documentation

---

### ⬜ Phase 9: Third-Party Module Support

**Module Guidelines:**
- ⬜ Scan `resources/coldbox-cli/ai/guidelines/`
- ⬜ Auto-register discovered guidelines
- ⬜ Version matching
- ⬜ Priority handling

**Module Skills:**
- ⬜ Scan `resources/coldbox-cli/ai/skills/`
- ⬜ Auto-register discovered skills
- ⬜ Activation based on module presence

**Module Author Docs:**
- ⬜ Guidelines for including AI files
- ⬜ Example module structure
- ⬜ Best practices
- ⬜ Template files

---

### ⬜ Phase 10: Documentation & Examples

**User Documentation:**
- ⬜ Command reference
- ⬜ Configuration guide
- ⬜ Best practices
- ⬜ Troubleshooting

**Writing Guides:**
- ⬜ Guideline writing guide
- ⬜ Skill writing guide
- ⬜ Module author guide

**Examples:**
- ⬜ Sample app with AI configured
- ⬜ Sample module with AI support
- ⬜ Agent configuration examples

---

## Progress Summary

**Phase Status:**
- ✅ Phase 1: Foundation - **100% Complete**
- ✅ Phase 2: CLI Commands - **100% Complete** (MCP deferred)
- ⬜ Phase 3: Application Integration - **0% Complete**
- ⬜ Phase 4: Guidelines Content - **0% Complete** (40+ guidelines)
- ⬜ Phase 5: Skills Content - **0% Complete** (41 skills)
- ⬜ Phase 6: MCP Integration - **0% Complete** (25 servers)
- ⬜ Phase 7: Multi-Agent - **0% Complete** (6 agents)
- ⬜ Phase 8: Custom Support - **0% Complete**
- ⬜ Phase 9: Module Support - **0% Complete**
- ⬜ Phase 10: Documentation - **0% Complete**

**Overall Progress:** 20% (2/10 phases complete)

---

## Success Metrics

- **Guidelines:** 40+ covering entire ColdBox ecosystem
- **Skills:** 41 total (34 high priority = 83%)
  - BoxLang: 8 skills (20%)
  - ColdBox: 9 skills (22%)
  - Testing: 8 skills (20%)
  - Security: 9 skills (22%)
  - ORM/Database: 4 skills (10%)
  - Modern: 3 skills (7%)
- **MCP Servers:** 25 Ortus documentation servers
- **Agents:** 6 AI agents supported
- **Module Support:** Zero-config auto-discovery
- **Languages:** BoxLang, CFML, and hybrid projects
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
