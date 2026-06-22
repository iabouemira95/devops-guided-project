const crypto = require("crypto");
const express = require("express");
const path = require("path");

const { createDb } = require("./db");
const { createRedis } = require("./redis");
const { createLogger } = require("./logger");
const { createMetrics } = require("./metrics");

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

function getMetadata() {
  return {
    service_name: process.env.APP_NAME || "devops-mini-app",
    version: process.env.APP_VERSION || "dev",
    environment: process.env.APP_ENV || "local",
    git_sha: process.env.GIT_SHA || "unknown",
    image_tag: process.env.IMAGE_TAG || "local"
  };
}

function isLocalHostname(hostname = "") {
  return hostname === "localhost" || hostname === "127.0.0.1" || hostname === "::1";
}

function getUiConfig(req) {
  const hostname = req.hostname || "localhost";
  const protocol = req.protocol || "http";
  const isLocal = isLocalHostname(hostname);
  const explicitGrafanaUrl = process.env.GRAFANA_PUBLIC_URL || "";
  const explicitGrafanaLogsUrl = process.env.GRAFANA_LOGS_PUBLIC_URL || "";
  const explicitPrometheusUrl = process.env.PROMETHEUS_PUBLIC_URL || "";

  if (explicitGrafanaUrl || explicitGrafanaLogsUrl || explicitPrometheusUrl) {
    return {
      observability_mode: "explicit-public-links",
      grafana_url: explicitGrafanaUrl || null,
      grafana_logs_url: explicitGrafanaLogsUrl || `${explicitGrafanaUrl}/explore`,
      prometheus_url: explicitPrometheusUrl || null,
      hint:
        process.env.OBSERVABILITY_HINT ||
        "These observability links were provided explicitly by the runtime configuration."
    };
  }

  if (isLocal) {
    return {
      observability_mode: "local-direct",
      grafana_url: `${protocol}://${hostname}:3000`,
      grafana_logs_url: `${protocol}://${hostname}:3000/explore`,
      prometheus_url: `${protocol}://${hostname}:9090`,
      hint: "Grafana and Prometheus are available directly on this machine."
    };
  }

  return {
    observability_mode: "ssh-tunnel",
    grafana_url: "http://localhost:3000",
    grafana_logs_url: "http://localhost:3000/explore",
    prometheus_url: "http://localhost:9090",
    hint:
      process.env.OBSERVABILITY_HINT ||
      "This app is running on a VM. Create the SSH tunnel first, then these shortcuts will open your local tunnel endpoints."
  };
}

function createApp(deps = {}) {
  const app = express();
  const db = deps.db;
  const cache = deps.cache;
  const logger = deps.logger;
  const metrics = deps.metrics;

  app.set("trust proxy", true);
  app.use(express.json());
  app.use("/static", express.static(path.join(__dirname, "public")));

  app.use((req, res, next) => {
    const start = process.hrtime.bigint();
    const requestId = crypto.randomUUID();
    req.requestId = requestId;
    res.setHeader("X-Request-Id", requestId);

    logger.info("request started", {
      request_id: requestId,
      method: req.method,
      path: req.path,
      host: req.get("host") || "unknown",
      user_agent: req.get("user-agent") || "unknown"
    });

    res.on("finish", () => {
      const durationMs = Number(process.hrtime.bigint() - start) / 1_000_000;
      const pathLabel = req.path === "/" ? "/" : req.path;

      logger.info("request completed", {
        request_id: requestId,
        method: req.method,
        path: req.path,
        status_code: res.statusCode,
        duration_ms: Number(durationMs.toFixed(2)),
        user_agent: req.get("user-agent") || "unknown"
      });

      metrics.observeRequest({
        method: req.method,
        path: pathLabel,
        statusCode: res.statusCode,
        durationSeconds: durationMs / 1000
      });
    });

    next();
  });

  app.get("/", (_req, res) => {
    res.sendFile(path.join(__dirname, "public", "index.html"));
  });

  app.get("/api", (_req, res) => {
    res.json(getMetadata());
  });

  app.get("/ui-config", (req, res) => {
    res.json({
      ...getMetadata(),
      ...getUiConfig(req)
    });
  });

  app.get("/health", (_req, res) => {
    res.json({
      status: "ok",
      service_name: getMetadata().service_name
    });
  });

  app.get("/ready", async (_req, res) => {
    let dbReady = false;
    let redisReady = false;

    try {
      await db.isReady();
      dbReady = true;
    } catch (_error) {
      dbReady = false;
    }

    try {
      await cache.isReady();
      redisReady = true;
    } catch (_error) {
      redisReady = false;
    }

    metrics.setReadiness({
      appReady: 1,
      dbReady: dbReady ? 1 : 0,
      redisReady: redisReady ? 1 : 0
    });

    const statusCode = dbReady && redisReady ? 200 : 503;

    logger.info("dependency readiness checked", {
      request_id: _req.requestId,
      db_ready: dbReady,
      redis_ready: redisReady,
      status_code: statusCode
    });

    res.status(statusCode).json({
      status: dbReady && redisReady ? "ready" : "degraded",
      db_ready: dbReady,
      redis_ready: redisReady
    });
  });

  app.get("/version", (_req, res) => {
    const metadata = getMetadata();
    res.json({
      app_version: metadata.version,
      git_sha: metadata.git_sha,
      image_tag: metadata.image_tag,
      environment: metadata.environment
    });
  });

  app.get("/metrics", async (_req, res) => {
    res.set("Content-Type", metrics.register.contentType);
    res.send(await metrics.register.metrics());
  });

  app.get("/items", async (_req, res, next) => {
    try {
      const items = await db.getItems();
      logger.info("postgres items loaded", {
        request_id: _req.requestId,
        item_count: items.length
      });
      res.json({
        source: "postgres",
        count: items.length,
        items
      });
    } catch (error) {
      next(error);
    }
  });

  app.post("/items", async (req, res, next) => {
    try {
      const name = req.body?.name || `demo-item-${Date.now()}`;
      const item = await db.createItem(name);
      logger.info("postgres item created", {
        request_id: req.requestId,
        item_id: item.id,
        item_name: item.name
      });
      res.status(201).json({
        message: "Item created",
        item
      });
    } catch (error) {
      next(error);
    }
  });

  app.get("/cache-demo", async (_req, res, next) => {
    logger.warn("training gap: cache demo is not implemented yet", {
      request_id: _req.requestId,
      gap_id: "APP-01",
      route: "/cache-demo"
    });

    return res.status(501).json({
      error: "Training gap APP-01: implement the Redis cache demo route.",
      next_step: "Read docs/13-trainee-gap-map.md and complete the APP-01 instructions.",
      request_id: _req.requestId
    });
  });

  app.get("/slow", async (_req, res) => {
    logger.warn("slow request simulation started", {
      request_id: _req.requestId,
      delay_ms: 2500
    });
    await sleep(2500);
    logger.warn("slow request simulation completed", {
      request_id: _req.requestId,
      delay_ms: 2500
    });
    res.json({
      status: "ok",
      note: "This route was intentionally slow.",
      delay_ms: 2500
    });
  });

  app.get("/error", (_req, _res, next) => {
    const error = new Error("Intentional training error");
    error.statusCode = 500;
    next(error);
  });

  app.use((error, req, res, _next) => {
    const statusCode = error.statusCode || 500;

    logger.error("request failed", {
      request_id: req.requestId,
      method: req.method,
      path: req.path,
      status_code: statusCode,
      error_message: error.message
    });

    res.status(statusCode).json({
      error: error.message,
      request_id: req.requestId
    });
  });

  return app;
}

async function start() {
  const logger = createLogger();
  const metrics = createMetrics();
  const db = createDb();
  const cache = createRedis();
  const app = createApp({ db, cache, logger, metrics });
  const port = Number(process.env.PORT || 3000);

  process.on("SIGTERM", async () => {
    await cache.close();
    await db.close();
    process.exit(0);
  });

  process.on("SIGINT", async () => {
    await cache.close();
    await db.close();
    process.exit(0);
  });

  app.listen(port, () => {
    logger.info("server started", {
      port,
      service_name: getMetadata().service_name
    });
  });
}

if (require.main === module) {
  start().catch((error) => {
    process.stderr.write(`${error.stack}\n`);
    process.exit(1);
  });
}

module.exports = {
  createApp,
  getMetadata
};
