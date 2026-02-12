---
title: CBMarkdown Module Guidelines
description: Guidance for Markdown rendering pipelines, including parser configuration, extension usage, syntax highlighting, sanitization, and safe output practices for user-generated content.
---

# CBMarkdown Module Guidelines

## Overview

CBMarkdown provides Markdown parsing and rendering for ColdBox applications using the Flexmark Java library. Convert Markdown to HTML with support for GitHub Flavored Markdown, tables, and code highlighting.

## Installation

```bash
box install cbmarkdown
```

## Usage

```boxlang
property name="markdown" inject="Processor@cbmarkdown";

// Convert markdown to HTML
var html = markdown.toHTML( "# Hello **World**" )

// With code highlighting
var markdown = "```javascript
function hello() {
    console.log('Hello');
}
```"

var html = markdown.toHTML( markdown )
```

## In Views

```cfml
<!--- Render blog post body --->
<article>
    <h1>#prc.post.getTitle()#</h1>
    <div class="content">
        #markdown.toHTML( prc.post.getBody() )#
    </div>
</article>

<!--- Render comment --->
<div class="comment">
    #markdown.toHTML( comment.getBody() )#
</div>
```

## Common Patterns

```boxlang
// Blog post service
component {
    property name="markdown" inject="Processor@cbmarkdown";
    property name="postDAO" inject;

    function renderPost( required post ) {
        return {
            id: post.getId(),
            title: post.getTitle(),
            body: markdown.toHTML( post.getBody() ),
            excerpt: markdown.toHTML( post.getExcerpt() )
        }
    }
}
```

## Supported Markdown

- **Headers** - # H1, ## H2, ### H3
- **Bold** - **bold** or **bold**
- **Italic** - *italic* or *italic*
- **Lists** - Ordered and unordered
- **Links** - [text](url)
- **Images** - ![alt](url)
- **Code blocks** - ```lang
- **Inline code** - `code`
- **Tables** - GitHub style tables
- **Blockquotes** - > quote
- **Horizontal rules** - ---

## Documentation

https://github.com/coldbox-modules/cbmarkdown
