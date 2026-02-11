# CBFeeds Module Guidelines

## Overview

CBFeeds provides RSS and Atom feed parsing and generation for ColdBox applications. Consume external feeds or create your own.

## Installation

```bash
box install cbfeeds
```

## Usage

### Parsing Feeds

```boxlang
property name="feedReader" inject="FeedReader@cbfeeds";

// Parse RSS/Atom feed
var feed = feedReader.parseFeed( "https://example.com/feed.xml" )

// Get feed metadata
var title = feed.getTitle()
var description = feed.getDescription()
var link = feed.getLink()

// Iterate items
for ( var entry in feed.getItems() ) {
    writeOutput( "<h2>#entry.getTitle()#</h2>" )
    writeOutput( "<p>#entry.getDescription()#</p>" )
    writeOutput( "<a href='#entry.getLink()#'>Read More</a>" )
}
```

### Generating Feeds

```boxlang
property name="feedGenerator" inject="FeedGenerator@cbfeeds";

// Create RSS feed
var feed = feedGenerator.createFeed(
    title = "My Blog",
    link = "https://myblog.com",
    description = "Latest posts from my blog"
)

// Add items
feed.addItem(
    title = "First Post",
    link = "https://myblog.com/posts/1",
    description = "This is my first post",
    pubDate = now()
)

// Generate XML
var xml = feed.render()
```

## Documentation

https://github.com/coldbox-modules/cbfeeds
