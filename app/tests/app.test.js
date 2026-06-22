const test = require("node:test");
const assert = require("node:assert/strict");
const { EventEmitter } = require("node:events");
const httpMocks = require("node-mocks-http");

const { createMetrics } = require("../src/metrics");
const { createApp } = require("../src/server");

function createFakeDeps() {
  const items = [
    { id: 1, name: "seed-item-1", created_at: "2026-06-01T10:00:00Z" },
    { id: 2, name: "seed-item-2", created_at: "2026-06-01T10:05:00Z" }
  ];

  return {
    db: {
      async isReady() {
        return true;
      },
      async getItems() {
        return items;
      },
      async createItem(name) {
        const item = { id: items.length + 1, name, created_at: new Date().toISOString() };
        items.push(item);
        return item;
      }
    },
    cache: {
      cacheValue: null,
      async isReady() {
        return true;
      },
      async get() {
        return this.cacheValue;
      },
      async setEx(_key, _seconds, value) {
        this.cacheValue = value;
      }
    },
    logger: {
      info() {},
      warn() {},
      error() {}
    },
    metrics: createMetrics({ appName: "test-app", environment: "test", version: "test" })
  };
}

async function invokeApp({ method = "GET", url, headers = {}, body } = {}) {
  const app = createApp(createFakeDeps());
  const req = httpMocks.createRequest({
    method,
    url,
    headers,
    body
  });
  const res = httpMocks.createResponse({ eventEmitter: EventEmitter });

  await new Promise((resolve, reject) => {
    res.on("end", resolve);
    app.handle(req, res, reject);
  });

  return {
    status: res.statusCode,
    headers: res._getHeaders(),
    text: res._getData(),
    body: res._isJSON() ? JSON.parse(res._getData()) : null
  };
}

test("GET /health returns process health", async () => {
  const response = await invokeApp({ url: "/health" });

  assert.equal(response.status, 200);
  assert.equal(response.body.status, "ok");
});

test("GET /api returns service metadata", async () => {
  const response = await invokeApp({ url: "/api" });

  assert.equal(response.status, 200);
  assert.equal(typeof response.body.service_name, "string");
  assert.equal(typeof response.body.environment, "string");
});

test("GET /version returns build metadata", async () => {
  const response = await invokeApp({ url: "/version" });

  assert.equal(response.status, 200);
  assert.ok("app_version" in response.body);
  assert.ok("git_sha" in response.body);
  assert.ok("image_tag" in response.body);
});

test("GET /ui-config returns observability shortcut metadata", async () => {
  const response = await invokeApp({ url: "/ui-config" });

  assert.equal(response.status, 200);
  assert.ok("observability_mode" in response.body);
  assert.ok("grafana_url" in response.body);
  assert.ok("prometheus_url" in response.body);
  assert.equal(typeof response.body.hint, "string");
});

test("GET /metrics returns Prometheus text", async () => {
  const response = await invokeApp({ url: "/metrics" });

  assert.equal(response.status, 200);
  assert.match(response.headers["content-type"], /text\/plain/);
  assert.match(response.text, /http_requests_total|app_info/);
});

test("POST /items creates a new item", async () => {
  const response = await invokeApp({
    method: "POST",
    url: "/items",
    headers: { "content-type": "application/json" },
    body: { name: "from-test" }
  });

  assert.equal(response.status, 201);
  assert.equal(response.body.item.name, "from-test");
});
