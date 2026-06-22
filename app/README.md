# App

This folder contains the simple Node.js service used by the guided DevOps project.

The app is intentionally small:

- one Express service
- one server-rendered GUI
- one PostgreSQL table
- one Redis cache demo
- one metrics endpoint
- structured logs to stdout and a file

Main entrypoint:

- `src/server.js`

Tests:

```bash
cd app
npm ci
npm test
```

If `npm test` fails because `node` is not installed, install Node.js 24 LTS or later first.
