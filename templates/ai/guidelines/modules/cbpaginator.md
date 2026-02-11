# CBPaginator - Pagination Helpers

> **Module**: cbpaginator
> **Category**: Utility
> **Purpose**: Provides pagination helpers and utilities for ColdBox applications

## Overview

CBPaginator simplifies pagination implementation in ColdBox applications by providing reusable pagination logic, HTML generation, and data handling. It supports various data sources and rendering styles.

## Core Features

- Automatic pagination calculation
- Multiple rendering styles (Bootstrap, Foundation, Custom)
- ORM and Query pagination
- API pagination support
- Flexible page window calculations
- Offset and cursor-based pagination
- SEO-friendly URLs
- Customizable templates

## Installation

```bash
box install cbpaginator
```

## Configuration

```javascript
// config/ColdBox.cfc - moduleSettings
moduleSettings = {
    cbpaginator: {
        // Default records per page
        perPage: 25,

        // Page parameter name in URL
        pageParameter: "page",

        // Maximum records per page
        maxPerPage: 100,

        // Pages to show on each side of current
        adjacentPages: 3,

        // Rendering style: bootstrap3, bootstrap4, bootstrap5, foundation, custom
        style: "bootstrap5",

        // Custom template path
        templatePath: "/views/pagination/",

        // Enable query string pagination
        useQueryString: true
    }
};
```

## Usage Patterns

### Basic Pagination

```javascript
component {
    property name="paginator" inject="Paginator@cbpaginator";

    function list( event, rc, prc ) {
        var page = rc.page ?: 1;
        var perPage = 25;

        // Get total records
        var totalRecords = userService.count();

        // Calculate offset
        var offset = (page - 1) * perPage;

        // Get paginated results
        prc.users = userService.list(
            offset = offset,
            max = perPage
        );

        // Create pagination
        prc.pagination = paginator.create(
            totalRecords = totalRecords,
            page = page,
            perPage = perPage,
            baseURL = event.buildLink( "users.list" )
        );

        event.setView( "users/list" );
    }
}
```

### ORM Entity Pagination

```javascript
component {
    property name="paginator" inject="Paginator@cbpaginator";

    function list( event, rc, prc ) {
        // ORM pagination with criteria
        var results = paginator.paginate(
            entityName = "User",
            criteria = {
                isActive = true
            },
            sortOrder = "lastName ASC",
            page = rc.page ?: 1,
            perPage = 25
        );

        prc.users = results.data;
        prc.pagination = results.pagination;

        event.setView( "users/list" );
    }
}
```

### QB Query Builder Pagination

```javascript
component {
    property name="paginator" inject="Paginator@cbpaginator";
    property name="qb" inject="QueryBuilder@qb";

    function list( event, rc, prc ) {
        // Build query
        var query = qb.from( "users" )
            .where( "isActive", 1 )
            .orderBy( "lastName" );

        // Paginate query
        var results = paginator.paginateQuery(
            query = query,
            page = rc.page ?: 1,
            perPage = 25
        );

        prc.users = results.data;
        prc.pagination = results.pagination;

        event.setView( "users/list" );
    }
}
```

### View Rendering

```html
<!-- In view -->
<div class="users-list">
    <cfloop array="#prc.users#" index="user">
        <div class="user-item">
            <h3>#user.getName()#</h3>
            <p>#user.getEmail()#</p>
        </div>
    </cfloop>
</div>

<!-- Render pagination controls -->
#prc.pagination.renderHTML()#

<!-- Or with custom options -->
#prc.pagination.renderHTML(
    style = "bootstrap5",
    showEnds = true,
    showPrevNext = true
)#
```

### API Pagination

```javascript
component extends="coldbox.system.RestHandler" {
    property name="paginator" inject="Paginator@cbpaginator";

    function index( event, rc, prc ) {
        var results = paginator.paginate(
            entityName = "Product",
            page = rc.page ?: 1,
            perPage = rc.perPage ?: 25
        );

        prc.response = {
            data: results.data,
            pagination: {
                current_page: results.pagination.currentPage,
                per_page: results.pagination.perPage,
                total: results.pagination.totalRecords,
                total_pages: results.pagination.totalPages,
                has_next: results.pagination.hasNext(),
                has_previous: results.pagination.hasPrevious(),
                next_url: results.pagination.getNextURL(),
                prev_url: results.pagination.getPrevURL()
            }
        };
    }
}
```

### Cursor-Based Pagination

```javascript
// For infinite scroll or real-time feeds
component {
    property name="paginator" inject="Paginator@cbpaginator";

    function feed( event, rc, prc ) {
        var results = paginator.cursorPaginate(
            entityName = "Post",
            cursorField = "id",
            cursor = rc.cursor ?: 0,
            direction = "after", // or "before"
            limit = 20,
            sortOrder = "id DESC"
        );

        prc.posts = results.data;
        prc.nextCursor = results.nextCursor;
        prc.hasMore = results.hasMore;
    }
}
```

## Pagination Object API

```javascript
// Get pagination info
var totalPages = pagination.getTotalPages();
var currentPage = pagination.getCurrentPage();
var perPage = pagination.getPerPage();
var totalRecords = pagination.getTotalRecords();

// Navigation checks
var hasNext = pagination.hasNext();
var hasPrevious = pagination.hasPrevious();
var isFirstPage = pagination.isFirstPage();
var isLastPage = pagination.isLastPage();

// Get page URLs
var firstURL = pagination.getFirstURL();
var lastURL = pagination.getLastURL();
var nextURL = pagination.getNextURL();
var prevURL = pagination.getPrevURL();
var pageURL = pagination.getPageURL( 5 );

// Get page ranges
var startRecord = pagination.getStartRecord(); // e.g., 26 (on page 2, perPage 25)
var endRecord = pagination.getEndRecord();     // e.g., 50
var pageRange = pagination.getPageRange();     // [ 1, 2, 3, 4, 5 ]

// Convert to struct for API responses
var paginationData = pagination.toStruct();
```

## Custom Templates

```html
<!-- /views/pagination/custom.cfm -->
<nav aria-label="Page navigation">
    <ul class="pagination">
        <!-- First page -->
        <cfif pagination.hasPrevious()>
            <li class="page-item">
                <a class="page-link" href="#pagination.getFirstURL()#">
                    &laquo; First
                </a>
            </li>
        </cfif>

        <!-- Previous page -->
        <cfif pagination.hasPrevious()>
            <li class="page-item">
                <a class="page-link" href="#pagination.getPrevURL()#">
                    &lsaquo; Previous
                </a>
            </li>
        </cfif>

        <!-- Page numbers -->
        <cfloop array="#pagination.getPageRange()#" index="pageNum">
            <li class="page-item #pagination.getCurrentPage() == pageNum ? 'active' : ''#">
                <a class="page-link" href="#pagination.getPageURL( pageNum )#">
                    #pageNum#
                </a>
            </li>
        </cfloop>

        <!-- Next page -->
        <cfif pagination.hasNext()>
            <li class="page-item">
                <a class="page-link" href="#pagination.getNextURL()#">
                    Next &rsaquo;
                </a>
            </li>
        </cfif>

        <!-- Last page -->
        <cfif pagination.hasNext()>
            <li class="page-item">
                <a class="page-link" href="#pagination.getLastURL()#">
                    Last &raquo;
                </a>
            </li>
        </cfif>
    </ul>
</nav>

<!-- Pagination info -->
<div class="pagination-info">
    Showing #pagination.getStartRecord()# to #pagination.getEndRecord()#
    of #pagination.getTotalRecords()# results
</div>
```

## HTMX Integration

```html
<!-- Infinite scroll with HTMX -->
<div id="users-list">
    <cfloop array="#prc.users#" index="user">
        <div class="user-item">
            <h3>#user.getName()#</h3>
        </div>
    </cfloop>
</div>

<cfif prc.pagination.hasNext()>
    <div
        hx-get="#prc.pagination.getNextURL()#"
        hx-trigger="revealed"
        hx-swap="afterend"
        hx-select="#users-list > *"
    >
        <div class="loading">Loading more...</div>
    </div>
</cfif>
```

## Testing

```javascript
describe( "User Pagination", function() {

    beforeEach( function() {
        paginator = getInstance( "Paginator@cbpaginator" );
    });

    it( "paginates users correctly", function() {
        var results = paginator.paginate(
            entityName = "User",
            page = 1,
            perPage = 25
        );

        expect( results.data ).toBeArray();
        expect( results.data.len() ).toBeLTE( 25 );
        expect( results.pagination.getTotalPages() ).toBeGTE( 1 );
    });

    it( "calculates correct page ranges", function() {
        var pagination = paginator.create(
            totalRecords = 100,
            page = 5,
            perPage = 10
        );

        expect( pagination.getTotalPages() ).toBe( 10 );
        expect( pagination.getStartRecord() ).toBe( 41 );
        expect( pagination.getEndRecord() ).toBe( 50 );
    });

    it( "generates correct URLs", function() {
        var pagination = paginator.create(
            totalRecords = 100,
            page = 2,
            perPage = 25,
            baseURL = "/users"
        );

        expect( pagination.getNextURL() ).toInclude( "page=3" );
        expect( pagination.getPrevURL() ).toInclude( "page=1" );
    });
});
```

## Best Practices

1. **Validate Page Numbers**: Always validate and sanitize page input
2. **Set Max Per Page**: Limit maximum records to prevent performance issues
3. **Use Index Columns**: Ensure paginated queries use indexed columns
4. **Cache Count Queries**: Cache total record counts when possible
5. **Consider Cursor Pagination**: Use cursor-based for real-time or large datasets
6. **Provide Page Info**: Always show "X to Y of Z results"
7. **SEO-Friendly URLs**: Use clean URLs with page numbers
8. **Mobile-Friendly Controls**: Ensure pagination works on small screens

## Common Patterns

### Quick ORM Pagination

```javascript
// One-liner for ORM entities
var results = getInstance( "Paginator@cbpaginator" )
    .paginate( "User", rc.page ?: 1, 25 );
```

### Search Results Pagination

```javascript
function search( event, rc, prc ) {
    var searchTerm = rc.q ?: "";

    // Search with criteria
    var results = paginator.paginate(
        entityName = "Product",
        criteria = {
            name = { condition = "LIKE", value = "%#searchTerm#%" }
        },
        page = rc.page ?: 1,
        perPage = 20
    );

    prc.results = results.data;
    prc.pagination = results.pagination;
    prc.searchTerm = searchTerm;
}
```

### Per-Page Selection

```html
<!-- Allow users to choose records per page -->
<select onchange="location.href=this.value">
    <option value="?perPage=25" #rc.perPage == 25 ? 'selected' : ''#>25</option>
    <option value="?perPage=50" #rc.perPage == 50 ? 'selected' : ''#>50</option>
    <option value="?perPage=100" #rc.perPage == 100 ? 'selected' : ''#>100</option>
</select>
```

## Additional Resources

- [Pagination Best Practices](https://www.nngroup.com/articles/pagination-ux/)
- [ColdBox Query Building](https://qb.ortusbooks.com)
- [ORM Pagination](https://helpx.adobe.com/coldfusion/developing-applications/coldfusion-orm/retrieve-data-from-database/pagination-in-hibernate.html)
