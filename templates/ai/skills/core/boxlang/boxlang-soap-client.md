---
name: BoxLang SOAP Client
description: Comprehensive guide to consuming SOAP web services with BoxLang's fluent soap() BIF, including WSDL discovery, operation invocation, type conversion, and service management
category: boxlang
priority: medium
triggers:
  - soap
  - SOAP web service
  - WSDL
  - soap()
  - web service
  - SOAP client
  - XML web service
  - enterprise integration
---

# BoxLang SOAP Client

## Overview

BoxLang 1.8.0+ provides a powerful, fluent `soap()` BIF for consuming SOAP 1.1 and SOAP 1.2 web services. The client automatically parses WSDL documents, discovers available operations, and provides intelligent type conversion between SOAP XML and BoxLang types with a clean, intuitive API.

## Core Concepts

### SOAP vs REST

**Use SOAP When:**
- ✅ Integrating with enterprise/legacy systems
- ✅ WSDL-defined services with strict contracts
- ✅ Complex operations requiring transactions
- ✅ WS-Security and advanced security features needed
- ✅ Formal service definitions are required

**Use REST (http() BIF) When:**
- ✅ Building modern web APIs
- ✅ Lightweight, fast communication needed
- ✅ JSON is preferred over XML
- ✅ Stateless operations are sufficient
- ✅ HTTP caching and standard methods beneficial

### SOAP Client Features

- 🔍 **Automatic WSDL Discovery** - Parse and understand services automatically
- 🎯 **Fluent Invocation** - Call SOAP operations like native BoxLang methods
- 🔄 **Intelligent Type Conversion** - SOAP XML types automatically become BoxLang types
- 📦 **Smart Unwrapping** - Clean, intuitive response structures
- 🔒 **Authentication Support** - HTTP Basic Auth built-in
- ⏱️ **Configurable Behavior** - Timeouts, headers, SOAP versions
- 📊 **Service Inspection** - Discover operations and parameters programmatically
- ⚠️ **Error Handling** - SOAP faults become BoxLang exceptions
- 📈 **Statistics Tracking** - Monitor usage and performance

## Creating SOAP Clients

### Basic Client Creation

```boxlang
// Create client from WSDL URL
ws = soap( "http://example.com/service.wsdl" )

// Invoke operation
result = ws.invoke( "myOperation", { param1: "value1", param2: "value2" } )
```

### Client with Configuration

```boxlang
// Create client with authentication and timeout
ws = soap( "http://example.com/service.wsdl" )
    .withBasicAuth( "username", "password" )
    .timeout( 30 )

// Invoke operation
result = ws.invoke( "getCustomer", { customerId: 12345 } )
```

### Client with Custom Headers

```boxlang
// Add custom headers
ws = soap( "http://example.com/service.wsdl" )
    .header( "X-API-Key", "secret123" )
    .header( "X-Tenant-ID", "tenant001" )
    .timeout( 45 )

result = ws.invoke( "getData" )
```

## Service Inspection

### Discovering Operations

```boxlang
// Get all available operations
ws = soap( "http://example.com/service.wsdl" )
operations = ws.getOperations()

// List all operations
operations.each( ( operationName ) => {
    println( "Operation: #operationName#" )
} )

// Check if operation exists
if ( operations.contains( "getCustomer" ) ) {
    println( "getCustomer operation is available" )
}
```

### Operation Information

```boxlang
// Get detailed operation info
operationInfo = ws.getOperationInfo( "getCustomer" )

println( "Operation: #operationInfo.name#" )
println( "Input Parameters:" )
operationInfo.inputParameters.each( ( param ) => {
    println( "  - #param.name# (#param.type#)" )
} )

println( "Output Type: #operationInfo.outputType#" )
```

### Complete Service Inspection Example

```boxlang
/**
 * Inspect and document SOAP service
 */
function inspectSOAPService( wsdlUrl ) {
    ws = soap( wsdlUrl )
    
    documentation = {
        serviceUrl: wsdlUrl,
        operations: [],
        totalOperations: 0
    }
    
    // Get all operations
    operations = ws.getOperations()
    documentation.totalOperations = operations.len()
    
    // Document each operation
    operations.each( ( operationName ) => {
        opInfo = ws.getOperationInfo( operationName )
        
        documentation.operations.append( {
            name: operationName,
            inputParameters: opInfo.inputParameters.map( ( p ) => {
                return {
                    name: p.name,
                    type: p.type,
                    required: p.required
                }
            } ),
            outputType: opInfo.outputType,
            description: opInfo.description ?: "No description available"
        } )
    } )
    
    return documentation
}

// Usage
docs = inspectSOAPService( "http://example.com/service.wsdl" )
writeDump( docs )
```

## Invoking Operations

### Basic Operation Invocation

```boxlang
// Simple operation call
ws = soap( "http://example.com/calculator.wsdl" )
result = ws.invoke( "Add", { a: 5, b: 3 } )
println( "Result: #result#" ) // 8
```

### Named Arguments (Struct)

```boxlang
// Using struct for named arguments (recommended)
ws = soap( "http://example.com/service.wsdl" )

result = ws.invoke( "getCustomer", {
    customerId: 12345,
    includeOrders: true,
    includeAddress: true
} )

println( "Customer: #result.name#" )
```

### Positional Arguments (Array)

```boxlang
// Using array for positional arguments
result = ws.invoke( "Add", [ 5, 3 ] )

// More complex example
result = ws.invoke( "createOrder", [
    12345,                    // customerId
    [ "ITEM001", "ITEM002" ], // items
    "STANDARD",               // shippingMethod
    "123 Main St"             // address
] )
```

### Complex Data Types

```boxlang
// Passing complex objects
customer = {
    firstName: "John",
    lastName: "Doe",
    email: "john@example.com",
    address: {
        street: "123 Main St",
        city: "Springfield",
        state: "IL",
        zip: "62701"
    },
    preferences: {
        newsletter: true,
        smsAlerts: false
    }
}

ws = soap( "http://example.com/crm.wsdl" )
result = ws.invoke( "createCustomer", { customer: customer } )
```

## Real-World Examples

### Weather Service Client

```boxlang
/**
 * WeatherServiceClient.bx
 * Client for weather SOAP service
 */
class {
    property name="client"
    property name="logger"
    property name="apiKey"
    
    function init( wsdlUrl, apiKey ) {
        variables.logger = getLogger()
        variables.apiKey = apiKey
        
        // Create SOAP client
        variables.client = soap( wsdlUrl )
            .withBasicAuth( "api", apiKey )
            .timeout( 30 )
        
        logger.info( "WeatherService initialized with #client.getOperations().len()# operations" )
        
        return this
    }
    
    /**
     * Get current weather for zip code
     */
    function getCurrentWeather( zipCode ) {
        try {
            return client.invoke( "GetCurrentWeather", { zipCode: zipCode } )
        } catch ( any e ) {
            logger.error( "Failed to get weather for #zipCode#: #e.message#" )
            throw( 
                type = "WeatherServiceError",
                message = "Unable to retrieve weather data"
            )
        }
    }
    
    /**
     * Get forecast
     */
    function getForecast( zipCode, days = 5 ) {
        return client.invoke( "GetForecast", {
            zipCode: zipCode,
            days: days
        } )
    }
    
    /**
     * Get service statistics
     */
    function getStatistics() {
        return client.getStatistics()
    }
}

// Usage
weatherService = new WeatherServiceClient(
    "http://api.weather.com/service.wsdl",
    "your-api-key"
)

current = weatherService.getCurrentWeather( "90210" )
println( "Temperature: #current.temperature#°F" )
println( "Conditions: #current.conditions#" )

forecast = weatherService.getForecast( "90210", 7 )
forecast.days.each( ( day ) => {
    println( "#day.date#: High #day.high#°F, Low #day.low#°F" )
} )
```

### Payment Gateway Integration

```boxlang
/**
 * PaymentGatewayService.bx
 * SOAP integration with payment gateway
 */
class {
    property name="client"
    property name="merchantId"
    property name="logger"
    
    function init( wsdlUrl, merchantId, merchantKey ) {
        variables.merchantId = merchantId
        variables.logger = getLogger()
        
        variables.client = soap( wsdlUrl )
            .withBasicAuth( merchantId, merchantKey )
            .timeout( 45 )
            .header( "X-Merchant-ID", merchantId )
        
        return this
    }
    
    /**
     * Process payment
     */
    function processPayment( amount, cardNumber, cardExpiry, cardCVV ) {
        try {
            result = client.invoke( "ProcessPayment", {
                merchantId: variables.merchantId,
                amount: amount,
                currency: "USD",
                card: {
                    number: cardNumber,
                    expiry: cardExpiry,
                    cvv: cardCVV
                },
                transactionId: createUUID()
            } )
            
            logger.info( "Payment processed: #result.transactionId#" )
            
            return {
                success: result.approved,
                transactionId: result.transactionId,
                authCode: result.authorizationCode,
                message: result.message
            }
        } catch ( any e ) {
            logger.error( "Payment processing failed: #e.message#" )
            return {
                success: false,
                message: "Payment processing error",
                error: e.message
            }
        }
    }
    
    /**
     * Refund transaction
     */
    function refundTransaction( transactionId, amount ) {
        return client.invoke( "RefundTransaction", {
            merchantId: variables.merchantId,
            transactionId: transactionId,
            amount: amount
        } )
    }
    
    /**
     * Get transaction status
     */
    function getTransactionStatus( transactionId ) {
        return client.invoke( "GetTransactionStatus", {
            merchantId: variables.merchantId,
            transactionId: transactionId
        } )
    }
}
```

### Shipping Service Integration

```boxlang
/**
 * ShippingServiceClient.bx
 * SOAP integration with shipping provider
 */
class {
    property name="client"
    property name="accountNumber"
    
    function init( wsdlUrl, accountNumber, apiKey ) {
        variables.accountNumber = accountNumber
        
        variables.client = soap( wsdlUrl )
            .header( "X-Account-Number", accountNumber )
            .header( "X-API-Key", apiKey )
            .timeout( 30 )
        
        return this
    }
    
    /**
     * Get shipping rates
     */
    function getRates( shipFrom, shipTo, package ) {
        return client.invoke( "CalculateRates", {
            accountNumber: variables.accountNumber,
            shipFrom: {
                address: shipFrom.address,
                city: shipFrom.city,
                state: shipFrom.state,
                zip: shipFrom.zip,
                country: shipFrom.country
            },
            shipTo: {
                address: shipTo.address,
                city: shipTo.city,
                state: shipTo.state,
                zip: shipTo.zip,
                country: shipTo.country
            },
            package: {
                weight: package.weight,
                length: package.length,
                width: package.width,
                height: package.height,
                weightUnit: "LBS",
                dimensionUnit: "IN"
            }
        } )
    }
    
    /**
     * Create shipment
     */
    function createShipment( shipFrom, shipTo, package, service ) {
        return client.invoke( "CreateShipment", {
            accountNumber: variables.accountNumber,
            service: service,
            shipFrom: shipFrom,
            shipTo: shipTo,
            package: package
        } )
    }
    
    /**
     * Track shipment
     */
    function trackShipment( trackingNumber ) {
        return client.invoke( "TrackShipment", {
            accountNumber: variables.accountNumber,
            trackingNumber: trackingNumber
        } )
    }
}
```

## Error Handling

### SOAP Faults

```boxlang
// SOAP faults become BoxLang exceptions
try {
    ws = soap( "http://example.com/service.wsdl" )
    result = ws.invoke( "getCustomer", { customerId: -1 } )
} catch ( any e ) {
    // Exception contains fault information
    logger.error( "SOAP Fault Code: #e.faultCode#" )
    logger.error( "SOAP Fault String: #e.faultString#" )
    logger.error( "SOAP Fault Detail: #e.faultDetail#" )
}
```

### Comprehensive Error Handling

```boxlang
/**
 * Robust SOAP call with error handling
 */
function robustSOAPCall( ws, operation, params ) {
    try {
        result = ws.invoke( operation, params )
        return { success: true, data: result }
    } catch ( any e ) {
        // Handle different error types
        if ( e.type == "SOAPFault" ) {
            logger.error( "SOAP Fault in #operation#: #e.faultString#" )
            
            // Handle specific fault codes
            switch ( e.faultCode ) {
                case "Client":
                    return { 
                        success: false,
                        error: "Invalid request parameters",
                        detail: e.faultDetail
                    }
                case "Server":
                    return {
                        success: false,
                        error: "Service error - please try again",
                        detail: e.faultString
                    }
                default:
                    return {
                        success: false,
                        error: "SOAP fault",
                        detail: e.message
                    }
            }
        } else if ( e.type == "TimeoutException" ) {
            logger.error( "SOAP timeout for #operation#" )
            return {
                success: false,
                error: "Service timeout - please try again"
            }
        } else {
            logger.error( "SOAP error for #operation#: #e.message#" )
            return {
                success: false,
                error: "Service unavailable",
                detail: e.message
            }
        }
    }
}
```

## Service Management

### Multi-Service Manager

```boxlang
/**
 * SOAPServiceManager.bx
 * Manage multiple SOAP services efficiently
 */
class {
    property name="services" type="struct"
    property name="logger"
    
    function init() {
        variables.services = {}
        variables.logger = getLogger()
        return this
    }
    
    /**
     * Register SOAP service
     */
    function registerService( name, wsdlUrl, config = {} ) {
        client = soap( wsdlUrl )
        
        // Apply authentication
        if ( structKeyExists( config, "username" ) && structKeyExists( config, "password" ) ) {
            client.withBasicAuth( config.username, config.password )
        }
        
        // Apply timeout
        if ( structKeyExists( config, "timeout" ) ) {
            client.timeout( config.timeout )
        }
        
        // Apply custom headers
        if ( structKeyExists( config, "headers" ) ) {
            config.headers.each( ( headerName, value ) => {
                client.header( headerName, value )
            } )
        }
        
        variables.services[ name ] = {
            client: client,
            config: config,
            registeredAt: now()
        }
        
        logger.info( "Registered service '#name#' with #client.getOperations().len()# operations" )
        
        return this
    }
    
    /**
     * Get service client
     */
    function getService( name ) {
        if ( !structKeyExists( variables.services, name ) ) {
            throw( 
                type = "ServiceNotFound",
                message = "Service '#name#' not registered"
            )
        }
        return variables.services[ name ].client
    }
    
    /**
     * Invoke operation on named service
     */
    function invoke( serviceName, operation, params = {} ) {
        service = getService( serviceName )
        return service.invoke( operation, params )
    }
    
    /**
     * Get statistics for all services
     */
    function getAllStatistics() {
        stats = {}
        
        variables.services.each( ( name, serviceData ) => {
            stats[ name ] = serviceData.client.getStatistics()
        } )
        
        return stats
    }
    
    /**
     * List all registered services
     */
    function listServices() {
        return variables.services.keyArray().map( ( name ) => {
            service = variables.services[ name ]
            return {
                name: name,
                operations: service.client.getOperations(),
                registeredAt: service.registeredAt
            }
        } )
    }
}

// Usage
manager = new SOAPServiceManager()
    .registerService( "weather", "http://api.weather.com/service.wsdl", {
        username: "api",
        password: "key123",
        timeout: 30
    } )
    .registerService( "shipping", "http://shipping.example.com/service.wsdl", {
        username: "account",
        password: "secret",
        timeout: 45,
        headers: { "X-API-Version": "2.0" }
    } )

// Call services
weather = manager.invoke( "weather", "GetCurrentWeather", { zipCode: "90210" } )
rates = manager.invoke( "shipping", "GetShippingRates", shippingDetails )

// Monitor all services
dump( manager.getAllStatistics() )
```

## Performance and Monitoring

### Client Statistics

```boxlang
// Get client usage statistics
ws = soap( "http://example.com/service.wsdl" )

// Make some calls
ws.invoke( "operation1", {} )
ws.invoke( "operation2", {} )

// Get statistics
stats = ws.getStatistics()

println( "Total Invocations: #stats.totalInvocations#" )
println( "Total Failures: #stats.totalFailures#" )
println( "Success Rate: #stats.successRate#%" )
println( "Average Response Time: #stats.avgResponseTime#ms" )
```

### Caching SOAP Clients

```boxlang
// ✅ Good: Cache and reuse SOAP clients
// WSDL parsing is expensive - create once, use many times

// Singleton pattern
component singleton {
    property name="weatherClient"
    
    function init() {
        variables.weatherClient = soap( "http://api.weather.com/service.wsdl" )
            .withBasicAuth( "api", "key" )
            .timeout( 30 )
        return this
    }
    
    function getWeather( zipCode ) {
        return variables.weatherClient.invoke( "GetCurrentWeather", { zipCode: zipCode } )
    }
}

// ❌ Bad: Creating client on every call
function getWeather( zipCode ) {
    ws = soap( "http://api.weather.com/service.wsdl" ) // Expensive!
    return ws.invoke( "GetCurrentWeather", { zipCode: zipCode } )
}
```

## Testing SOAP Clients

### Mocking SOAP Services

```boxlang
/**
 * SOAPServiceSpec.bx
 */
component extends="testbox.system.BaseSpec" {
    
    function beforeAll() {
        mockSOAPClient = createMock( "SOAPClient" )
        service = new MyService()
        service.soapClient = mockSOAPClient
    }
    
    function run() {
        describe( "SOAP Service Integration", () => {
            
            it( "should fetch customer data", () => {
                // Mock SOAP response
                mockSOAPClient
                    .$( "invoke" )
                    .$args( "getCustomer", { customerId: 123 } )
                    .$results( {
                        id: 123,
                        name: "John Doe",
                        email: "john@example.com"
                    } )
                
                customer = service.getCustomer( 123 )
                
                expect( customer.id ).toBe( 123 )
                expect( customer.name ).toBe( "John Doe" )
                expect( mockSOAPClient.$once( "invoke" ) ).toBeTrue()
            } )
            
            it( "should handle SOAP faults", () => {
                mockSOAPClient
                    .$( "invoke" )
                    .$throws( 
                        type = "SOAPFault",
                        message = "Customer not found",
                        faultCode = "Client"
                    )
                
                expect( () => service.getCustomer( 999 ) )
                    .toThrow( "SOAPFault" )
            } )
        } )
    }
}
```

## Best Practices

### Design Guidelines

1. **Cache Clients**: Create SOAP clients once and reuse (WSDL parsing is expensive)
2. **Set Timeouts**: SOAP calls can be slow, adjust timeouts accordingly
3. **Handle Faults**: Always wrap SOAP calls in try-catch blocks
4. **Inspect First**: Use `getOperations()` to see available operations
5. **Check Operation Info**: Use `getOperationInfo()` to understand parameters
6. **Named Arguments**: Struct arguments are clearer than positional arrays
7. **Monitor Statistics**: Track invocations and failures with `getStatistics()`
8. **Secure Credentials**: Use environment variables or config files for credentials
9. **Test with Public WSDLs**: Start with known working services for testing
10. **Log SOAP Requests**: Enable debug logging for troubleshooting

### Security Considerations

```boxlang
// ✅ Good: Secure credential management
apiKey = getApplicationSetting( "secure:soapApiKey" )
ws = soap( wsdlUrl ).withBasicAuth( accountId, apiKey )

// ❌ Bad: Hardcoded credentials
ws = soap( wsdlUrl ).withBasicAuth( "user123", "password123" ) // NEVER!

// ✅ Good: Validate responses
result = ws.invoke( "getData", params )
if ( !isStruct( result ) || !structKeyExists( result, "data" ) ) {
    throw( "Invalid SOAP response structure" )
}

// ✅ Good: Sanitize inputs
customerId = val( customerId ) // Ensure numeric
customerName = htmlEditFormat( customerName ) // Prevent injection
```

## Common Pitfalls

### Pitfalls to Avoid

1. **Re-creating Clients**: WSDL parsing is expensive, reuse clients
2. **Missing Timeouts**: SOAP services can be slow, always set timeouts
3. **Ignoring Faults**: SOAP faults contain valuable debugging information
4. **Case Sensitivity**: SOAP operation names are case-sensitive
5. **Null Values**: Some services don't handle null/empty values well
6. **Namespace Issues**: WSDL namespace definitions can cause operation discovery failures
7. **Authentication**: Some services require API keys in headers, not just basic auth
8. **SOAP Version**: Mismatched SOAP versions (1.1 vs 1.2) cause errors
9. **No Logging**: Log SOAP operations for debugging and monitoring
10. **No Error Recovery**: Implement retry logic for transient failures

### Troubleshooting

```boxlang
// Debug SOAP client
try {
    ws = soap( wsdlUrl )
    
    // Check available operations
    operations = ws.getOperations()
    logger.debug( "Available operations: #operations.toList()#" )
    
    // Check operation details
    info = ws.getOperationInfo( "myOperation" )
    logger.debug( "Operation info: #serializeJSON( info )#" )
    
    // Invoke with logging
    logger.debug( "Invoking operation with params: #serializeJSON( params )#" )
    result = ws.invoke( "myOperation", params )
    logger.debug( "Result: #serializeJSON( result )#" )
    
} catch ( any e ) {
    logger.error( "SOAP Error Type: #e.type#" )
    logger.error( "Message: #e.message#" )
    logger.error( "Detail: #e.detail#" )
    
    if ( structKeyExists( e, "faultCode" ) ) {
        logger.error( "Fault Code: #e.faultCode#" )
        logger.error( "Fault String: #e.faultString#" )
    }
}
```

## Related Skills

- [BoxLang HTTP Client](boxlang-http-client.md) - REST API and HTTP requests
- [BoxLang Futures](boxlang-futures.md) - Async programming for non-blocking SOAP calls

## References

- [BoxLang SOAP Web Services](https://boxlang.ortusbooks.com/boxlang-framework/soap)
- [BoxLang 1.8.0 Release](https://boxlang.ortusbooks.com/readme/release-history/1.8.0)
