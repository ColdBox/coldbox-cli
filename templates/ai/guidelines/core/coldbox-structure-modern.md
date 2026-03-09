---
title: ColdBox Modern Project Structure
description: Canonical modern ColdBox directory layout showing the separation of app source, public assets, module boundaries, tests, and supporting resources for maintainable BoxLang/CFML applications.
---

```
/app             - Application source code
  /config        - Application configuration
  /handlers      - Event handlers (controllers)
  /models        - Business logic and services
  /views         - View templates
  /layouts       - Layout wrappers
  /interceptors  - Event interceptors (AOP)
/public          - Web-accessible files
  /assets        - CSS, JS, images (processed by Vite)
  /index.cfm     - Front controller
/modules         - ColdBox modules (sub-applications)
/tests           - TestBox test suites
/resources       - Additional resources (migrations, seeders, etc.)
```
