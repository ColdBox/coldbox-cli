# CBPlaywright - End-to-End Browser Testing

> **Module**: cbplaywright  
> **Category**: Testing / E2E  
> **Purpose**: Browser automation and end-to-end testing using Microsoft Playwright

## Overview

CBPlaywright integrates Microsoft Playwright into ColdBox applications for automated browser testing, enabling cross-browser E2E tests, visual regression testing, and automated browser tasks.

## Core Features

- Multi-browser support (Chromium, Firefox, WebKit)
- Headless and headed modes
- Screenshot and video recording
- Network interception and mocking
- Mobile device emulation
- Geolocation and permissions
- File upload/download testing
- Accessibility testing
- Visual regression testing

## Installation

```bash
box install cbplaywright

# Install browsers
playwright install
```

## Configuration

```javascript
// config/ColdBox.cfc - moduleSettings
moduleSettings = {
    cbplaywright: {
        // Browser type: chromium, firefox, webkit
        browser: "chromium",
        
        // Headless mode
        headless: true,
        
        // Base URL for tests
        baseURL: "http://localhost:8080",
        
        // Screenshot on failure
        screenshotOnFailure: true,
        
        // Video recording
        recordVideo: false,
        
        // Viewport size
        viewport: {
            width: 1280,
            height: 720
        },
        
        // Timeout settings (milliseconds)
        timeout: 30000
    }
};
```

## Usage Patterns

### Basic E2E Test

```javascript
component extends="testbox.system.BaseSpec" {
    
    function beforeAll() {
        playwright = getInstance( "PlaywrightService@cbplaywright" );
        browser = playwright.launch();
        page = browser.newPage();
    }
    
    function afterAll() {
        browser.close();
    }
    
    function run() {
        describe( "Login Flow", function() {
            
            it( "can login successfully", function() {
                // Navigate to login page
                page.goto( "/login" );
                
                // Fill login form
                page.fill( "#username", "testuser" );
                page.fill( "#password", "password123" );
                
                // Submit form
                page.click( "button[type='submit']" );
                
                // Wait for navigation
                page.waitForURL( "/dashboard" );
                
                // Assert redirected to dashboard
                expect( page.url() ).toInclude( "/dashboard" );
                
                // Assert welcome message
                var welcomeText = page.textContent( "h1" );
                expect( welcomeText ).toInclude( "Welcome" );
            });
            
            it( "shows error for invalid credentials", function() {
                page.goto( "/login" );
                
                page.fill( "#username", "invalid" );
                page.fill( "#password", "wrong" );
                page.click( "button[type='submit']" );
                
                // Wait for error message
                page.waitForSelector( ".alert-danger" );
                
                var errorMsg = page.textContent( ".alert-danger" );
                expect( errorMsg ).toInclude( "Invalid credentials" );
            });
        });
    }
}
```

### Page Object Pattern

```javascript
// /tests/resources/pages/LoginPage.cfc
component {
    
    variables.page = "";
    
    function init( required page ) {
        variables.page = arguments.page;
        return this;
    }
    
    function navigate() {
        variables.page.goto( "/login" );
        return this;
    }
    
    function login( required string username, required string password ) {
        variables.page.fill( "#username", arguments.username );
        variables.page.fill( "#password", arguments.password );
        variables.page.click( "button[type='submit']" );
        return this;
    }
    
    function getErrorMessage() {
        return variables.page.textContent( ".alert-danger" );
    }
    
    function isOnLoginPage() {
        return variables.page.url().find( "/login" );
    }
}

// In test
function run() {
    describe( "Login Tests", function() {
        
        beforeEach( function() {
            loginPage = new pages.LoginPage( page );
        });
        
        it( "can login with valid credentials", function() {
            loginPage
                .navigate()
                .login( "testuser", "password123" );
            
            page.waitForURL( "/dashboard" );
            expect( page.url() ).toInclude( "/dashboard" );
        });
    });
}
```

### Screenshot Testing

```javascript
it( "matches visual baseline", function() {
    page.goto( "/products" );
    
    // Take screenshot
    var screenshot = page.screenshot();
    
    // Compare with baseline (visual regression)
    playwright.compareScreenshot( 
        actual = screenshot,
        baseline = "/tests/baseline/products-page.png",
        threshold = 0.1 // 10% difference allowed
    );
});

// Screenshot on failure
it( "handles errors gracefully", function() {
    try {
        page.click( ".non-existent-element" );
    } catch ( any e ) {
        page.screenshot( path = "/tests/failures/error-state.png" );
        rethrow;
    }
});
```

### Network Mocking

```javascript
it( "handles API failures gracefully", function() {
    // Mock API response
    page.route( "**/api/users", function( route ) {
        route.fulfill( {
            status = 500,
            contentType = "application/json",
            body = serializeJSON( {
                error = "Internal Server Error"
            } )
        } );
    } );
    
    page.goto( "/users" );
    
    // Assert error message displayed
    var errorMsg = page.textContent( ".error-message" );
    expect( errorMsg ).toInclude( "Unable to load users" );
});

it( "uses mocked data", function() {
    page.route( "**/api/products", function( route ) {
        route.fulfill( {
            status = 200,
            contentType = "application/json",
            body = serializeJSON( {
                products = [
                    { id = 1, name = "Test Product" }
                ]
            } )
        } );
    } );
    
    page.goto( "/products" );
    
    var productName = page.textContent( ".product:first-child" );
    expect( productName ).toBe( "Test Product" );
});
```

### Mobile Device Emulation

```javascript
it( "works on mobile devices", function() {
    // Emulate iPhone 12
    var context = browser.newContext(
        viewport = { width = 390, height = 844 },
        userAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 14_0 like Mac OS X) AppleWebKit/605.1.15",
        isMobile = true,
        hasTouch = true
    );
    
    var mobilePage = context.newPage();
    mobilePage.goto( "/" );
    
    // Test mobile menu
    mobilePage.click( ".mobile-menu-toggle" );
    expect( mobilePage.isVisible( ".mobile-menu" ) ).toBeTrue();
    
    context.close();
});
```

### Form Testing

```javascript
it( "validates form inputs", function() {
    page.goto( "/register" );
    
    // Fill form
    page.fill( "#email", "test@example.com" );
    page.fill( "#password", "pass123" );
    page.fill( "#confirm-password", "different" );
    
    page.click( "button[type='submit']" );
    
    // Assert validation error
    var error = page.textContent( ".password-error" );
    expect( error ).toInclude( "Passwords do not match" );
});

it( "handles file uploads", function() {
    page.goto( "/profile/settings" );
    
    // Upload file
    page.setInputFiles( "#avatar", "/tests/fixtures/avatar.jpg" );
    page.click( "#save-button" );
    
    page.waitForSelector( ".success-message" );
    expect( page.textContent( ".success-message" ) ).toInclude( "Profile updated" );
});
```

### Accessibility Testing

```javascript
it( "meets accessibility standards", function() {
    page.goto( "/" );
    
    // Check for accessibility violations
    var violations = playwright.checkAccessibility( page );
    
    expect( violations).toBeEmpty();
    
    // Or specific checks
    expect( page.getAttribute( "html", "lang" ) ).toBe( "en" );
    expect( page.locator( 'input:not([aria-label]):not([aria-labelledby])' ).count() ).toBe( 0 );
});
```

### Waiting Strategies

```javascript
// Wait for element
page.waitForSelector( ".product-list" );

// Wait for navigation
page.click( "a[href='/about']" );
page.waitForLoadState( "networkidle" );

// Wait for API call
page.waitForResponse( "**/api/products" );

// Custom wait
page.waitForFunction( "document.querySelectorAll('.product').length > 0" );

// Timeout
page.waitForSelector( ".slow-element", { timeout = 10000 } );
```

## Best Practices

1. **Use Page Objects**: Encapsulate page logic for reusability
2. **Wait Appropriately**: Use explicit waits, avoid sleep()
3. **Independent Tests**: Each test should be able to run alone
4. **Clean State**: Reset state between tests
5. **Descriptive Selectors**: Use data-testid attributes
6. **Screenshot Failures**: Capture state on test failure
7. **Run in CI/CD**: Automate E2E tests in pipeline
8. **Test Critical Paths**: Focus on user journeys

## Common Patterns

### Authentication Flow

```javascript
function loginAsUser() {
    page.goto( "/login" );
    page.fill( "#username", "testuser" );
    page.fill( "#password", "password" );
    page.click( "button[type='submit']" );
    page.waitForURL( "/dashboard" );
}
```

### Data Setup

```javascript
beforeEach( function() {
    // Create test data via API
    http url="http://localhost:8080/api/setup" 
        method="POST" 
        result="local.response";
    
    variables.testData = deserializeJSON( response.fileContent );
});
```

## Additional Resources

- [Playwright Documentation](https://playwright.dev/)
- [E2E Testing Best Practices](https://martinfowler.com/articles/practical-test-pyramid.html)
- [TestBox Framework](https://testbox.ortusbooks.com)
