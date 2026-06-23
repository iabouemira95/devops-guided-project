const test = require("node:test");
const assert = require("node:assert/strict");
const { EventEmitter } = require("node:events");
const httpMocks = require("node-mocks-http");

const { createMetrics } = require("../src/metrics");
const { createApp } = require("../src/server");

function createFakeDeps() {
  const items = [
    {
      id: 1,
      name: "Checkout API latency spike after release",
      service: "checkout-api",
      environment: "prod-sim",
      priority: "high",
      status: "investigating",
      owner_name: "platform-oncall",
      region: "sweden-central",
      source: "synthetic-alert",
      details: "Synthetic test item 1",
      created_at: "2026-06-01T10:00:00Z"
    },
    {
      id: 2,
      name: "Inventory sync backlog building up",
      service: "inventory-worker",
      environment: "staging-sim",
      priority: "medium",
      status: "monitoring",
      owner_name: "data-ops",
      region: "westeurope",
      source: "queue-monitor",
      details: "Synthetic test item 2",
      created_at: "2026-06-01T10:05:00Z"
    }
  ];

  return {
    db: {
      async isReady() {
        return true;
      },
      async getItems() {
        return items;
      },
      async createItem(itemInput) {
        const item = {
          id: items.length + 1,
          created_at: new Date().toISOString(),
          ...itemInput
        };
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
  assert.equal(response.body.simulation_profile, "operations-feed");
  assert.ok(Array.isArray(response.body.supported_services));
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
    body: { name: "from-test", service: "checkout-api", priority: "critical" }
  });

  assert.equal(response.status, 201);
  assert.equal(response.body.item.name, "from-test");
  assert.equal(response.body.item.service, "checkout-api");
  assert.equal(response.body.item.priority, "critical");
  assert.ok(response.body.summary.total_items >= 3);
});

test("GET /cache-demo returns the trainee gap response", async () => {
  const response = await invokeApp({ url: "/cache-demo" });

  assert.equal(response.status, 501);
  assert.match(response.body.error, /APP-01/);
});

test("GET /items returns a richer operational dataset summary", async () => {
  const response = await invokeApp({ url: "/items" });

  assert.equal(response.status, 200);
  assert.ok("summary" in response.body);
  assert.ok("by_status" in response.body.summary);
  assert.ok("service" in response.body.items[0]);
  assert.ok("owner_name" in response.body.items[0]);
});
