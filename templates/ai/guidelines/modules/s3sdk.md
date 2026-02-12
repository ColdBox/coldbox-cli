---
title: S3SDK - Amazon S3 Integration
description: Usage patterns for Amazon S3 storage operations, including bucket/object lifecycle management, upload/download flows, metadata handling, and secure access configuration.
---

# S3SDK - Amazon S3 Integration

> **Module**: s3sdk
> **Category**: Cloud / Storage
> **Purpose**: Comprehensive Amazon S3 client for file storage and management

## Overview

The S3SDK provides a complete interface to Amazon S3 (Simple Storage Service) for ColdBox applications, enabling cloud file storage, retrieval, and management with support for all S3 operations.

## Core Features

- Bucket creation and management
- Object upload/download
- Multipart uploads for large files
- Pre-signed URL generation
- Access control (ACLs, bucket policies)
- Lifecycle policies
- Cross-region replication
- Server-side encryption
- CloudFront integration

## Installation

```bash
box install s3sdk
```

## Configuration

```javascript
// config/ColdBox.cfc - moduleSettings
moduleSettings = {
    s3sdk: {
        accessKey: getSystemSetting( "AWS_ACCESS_KEY" ),
        secretKey: getSystemSetting( "AWS_SECRET_KEY" ),
        defaultRegion: "us-east-1",
        defaultBucket: "myapp-uploads",
        ssl: true,
        defaultACL: "public-read",
        endpoint: "" // Optional custom endpoint for S3-compatible services
    }
};
```

## Usage Patterns

### File Upload

```javascript
component {
    property name="s3" inject="AmazonS3@s3sdk";

    function uploadFile( event, rc, prc ) {
        var filePath = expandPath( "/temp/upload.pdf" );

        // Simple upload
        s3.putObject(
            bucketName = "myapp-uploads",
            key = "documents/file.pdf",
            file = filePath
        );

        // With metadata and ACL
        s3.putObject(
            bucketName = "myapp-uploads",
            key = "documents/file.pdf",
            file = filePath,
            acl = "private",
            metadata = {
                "user-id": auth().user().getId(),
                "upload-date": now()
            },
            contentType = "application/pdf"
        );
    }
}
```

### File Download

```javascript
// Download to local file
s3.getObject(
    bucketName = "myapp-uploads",
    key = "documents/file.pdf",
    file = expandPath( "/downloads/file.pdf" )
);

// Get as binary
var fileData = s3.getObjectData(
    bucketName = "myapp-uploads",
    key = "documents/file.pdf"
);

// Stream to browser
var objectData = s3.getObject( "myapp-uploads", "documents/file.pdf" );
event.renderData(
    type = "binary",
    data = object Data.data,
    contentType = objectData.contentType
);
```

### Pre-signed URLs

```javascript
// Generate temporary download URL (expires in 1 hour)
var downloadURL = s3.generatePresignedURL(
    bucketName = "myapp-uploads",
    key = "documents/file.pdf",
    expiration = 60 // minutes
);

// Generate upload URL
var uploadURL = s3.generatePresignedURL(
    bucketName = "myapp-uploads",
    key = "uploads/newfile.pdf",
    expiration = 30,
    method = "PUT"
);
```

### Multipart Upload (Large Files)

```javascript
// Initiate multipart upload
var uploadId = s3.initiateMultipartUpload(
    bucketName = "myapp-uploads",
    key = "videos/large-video.mp4"
);

// Upload parts
var parts = [];
for ( var i = 1; i <= partCount; i++ ) {
    var etag = s3.uploadPart(
        bucketName = "myapp-uploads",
        key = "videos/large-video.mp4",
        uploadId = uploadId,
        partNumber = i,
        data = readPartData( i )
    );
    parts.append( { partNumber: i, etag: etag } );
}

// Complete upload
s3.completeMultipartUpload(
    bucketName = "myapp-uploads",
    key = "videos/large-video.mp4",
    uploadId = uploadId,
    parts = parts
);
```

### Bucket Operations

```javascript
// Create bucket
s3.createBucket( "new-bucket", "us-west-2" );

// List buckets
var buckets = s3.listBuckets();

// List objects in bucket
var objects = s3.listObjects(
    bucketName = "myapp-uploads",
    prefix = "documents/",
    maxKeys = 100
);

// Delete object
s3.deleteObject( "myapp-uploads", "documents/old-file.pdf" );

// Copy object
s3.copyObject(
    sourceBucket = "myapp-uploads",
    sourceKey = "documents/file.pdf",
    destinationBucket = "myapp-backups",
    destinationKey = "backups/file.pdf"
);
```

### CBFS Integration

```javascript
// Use with CBFS for unified file storage API
moduleSettings = {
    cbfs: {
        default: {
            provider: "S3",
            properties: {
                accessKey: getSystemSetting( "AWS_ACCESS_KEY" ),
                secretKey: getSystemSetting( "AWS_SECRET_KEY" ),
                bucket: "myapp-uploads",
                region: "us-east-1"
            }
        }
    }
};

// Use CBFS abstraction
var disk = cbfs.disk();
disk.put( "path/to/file.pdf", fileContent );
var url = disk.url( "path/to/file.pdf" );
```

## Best Practices

1. **Use IAM Roles**: Prefer IAM roles over access keys when on EC2/ECS
2. **Enable Versioning**: Protect against accidental deletions
3. **Implement Lifecycle Policies**: Auto-delete or archive old files
4. **Use CloudFront**: CDN for frequently accessed files
5. **Encrypt Sensitive Data**: Enable server-side encryption
6. **Monitor Costs**: Use S3 analytics and cost tracking
7. **Use Multipart for Large Files**: Files over 100MB
8. **Implement Retry Logic**: Handle temporary S3 failures

## Additional Resources

- [AWS S3 Documentation](https://docs.aws.amazon.com/s3/)
- [S3 Best Practices](https://docs.aws.amazon.com/AmazonS3/latest/userguide/best-practices.html)
- [CBFS Module](https://forgebox.io/view/cbfs)
