---
title: CBElasticsearch - Elasticsearch Integration
description: Elasticsearch integration guidance for indexing, search relevance tuning, query design, bulk operations, and resilient document lifecycle management.
---

# CBElasticsearch - Elasticsearch Integration

> **Module**: cbelasticsearch
> **Category**: Search / Integration
> **Purpose**: Full-featured Elasticsearch client for ColdBox applications

## Overview

CBElasticsearch provides a comprehensive client for integrating Elasticsearch into ColdBox applications, offering document indexing, searching, aggregations, and cluster management.

## Core Features

- Index and document management
- Full-text search with query DSL
- Aggregations and analytics
- Bulk operations
- Cluster administration
- Mapping and analyzer configuration
- Result highlighting
- Geospatial queries

## Installation

```bash
box install cbelasticsearch
```

## Configuration

```javascript
// config/ColdBox.cfc - moduleSettings
moduleSettings = {
    cbelasticsearch: {
        hosts: [
            {
                serverProtocol: "http",
                serverName: "127.0.0.1",
                serverPort: 9200
            }
        ],
        defaultIndex: "myapp",
        defaultCredentials: {
            username: "elastic",
            password: "changeme"
        }
    }
};
```

## Usage Patterns

### Basic Search

```javascript
component {
    property name="elasticsearch" inject="Client@cbelasticsearch";

    function search( event, rc, prc ) {
        var results = elasticsearch
            .newSearch( "products" )
            .match( "name", rc.q ?: "" )
            .execute();

        prc.products = results.getHits();
        prc.total = results.getHitCount();
    }
}
```

### Document Indexing

```javascript
// Index single document
elasticsearch
    .newDocument( index="products", id="123" )
    .setMemento( {
        name: "Product Name",
        description: "Product description",
        price: 99.99,
        category: "electronics"
    } )
    .save();

// Bulk indexing
var documents = [];
products.each( function( product ) {
    documents.append( {
        _index: "products",
        _id: product.id,
        _source: product.getMemento()
    } );
} );

elasticsearch.bulk( documents );
```

### Advanced Search

```javascript
var results = elasticsearch
    .newSearch( "products" )
    .mustMatch( "category", "electronics" )
    .shouldMatch( "brand", "Apple" )
    .filterRange( "price", { gte: 100, lte: 1000 } )
    .sort( "price", "asc" )
    .setFrom( 0 )
    .setSize( 20 )
    .execute();
```

### Aggregations

```javascript
var results = elasticsearch
    .newSearch( "products" )
    .aggregation( "categories", {
        "terms": { "field": "category.keyword" }
    } )
    .aggregation( "price_stats", {
        "stats": { "field": "price" }
    } )
    .execute();

var categories = results.getAggregation( "categories" );
var priceStats = results.getAggregation( "price_stats" );
```

## Best Practices

1. **Use Bulk Operations**: Batch multiple operations for performance
2. **Design Mappings Carefully**: Plan field types and analyzers upfront
3. **Monitor Cluster Health**: Regular health checks
4. **Use Aliases**: Enable zero-downtime reindexing
5. **Implement Backups**: Regular snapshots of indices
6. **Optimize Queries**: Use filters over queries when possible

## Additional Resources

- [Elasticsearch Guide](https://www.elastic.co/guide/en/elasticsearch/reference/current/index.html)
- [Query DSL](https://www.elastic.co/guide/en/elasticsearch/reference/current/query-dsl.html)
