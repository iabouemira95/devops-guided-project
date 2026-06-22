const client = require("prom-client");

function createMetrics(options = {}) {
  const register = new client.Registry();
  client.collectDefaultMetrics({ register, prefix: "nodejs_" });

  const appName = options.appName || process.env.APP_NAME || "devops-mini-app";
  const environment = options.environment || process.env.APP_ENV || "local";
  const version = options.version || process.env.APP_VERSION || "dev";

  const httpRequestsTotal = new client.Counter({
    name: "http_requests_total",
    help: "Total number of HTTP requests",
    labelNames: ["method", "path", "status_code"],
    registers: [register]
  });

  const httpErrorsTotal = new client.Counter({
    name: "http_errors_total",
    help: "Total number of HTTP error responses",
    labelNames: ["method", "path", "status_code"],
    registers: [register]
  });

  const httpRequestDurationSeconds = new client.Histogram({
    name: "http_request_duration_seconds",
    help: "HTTP request duration in seconds",
    labelNames: ["method", "path", "status_code"],
    buckets: [0.01, 0.05, 0.1, 0.25, 0.5, 1, 2, 5],
    registers: [register]
  });

  const appInfo = new client.Gauge({
    name: "app_info",
    help: "Static application metadata",
    labelNames: ["app_name", "version", "environment"],
    registers: [register]
  });

  const appReadyStatus = new client.Gauge({
    name: "app_ready_status",
    help: "App readiness status",
    registers: [register]
  });

  const dbReadyStatus = new client.Gauge({
    name: "db_ready_status",
    help: "Database readiness status",
    registers: [register]
  });

  const redisReadyStatus = new client.Gauge({
    name: "redis_ready_status",
    help: "Redis readiness status",
    registers: [register]
  });

  appInfo.set({ app_name: appName, version, environment }, 1);
  appReadyStatus.set(1);
  dbReadyStatus.set(0);
  redisReadyStatus.set(0);

  function observeRequest({ method, path, statusCode, durationSeconds }) {
    const labels = {
      method,
      path,
      status_code: String(statusCode)
    };

    httpRequestsTotal.inc(labels);
    httpRequestDurationSeconds.observe(labels, durationSeconds);

    if (statusCode >= 400) {
      httpErrorsTotal.inc(labels);
    }
  }

  return {
    register,
    observeRequest,
    setReadiness({ appReady = 1, dbReady = 0, redisReady = 0 }) {
      appReadyStatus.set(appReady);
      dbReadyStatus.set(dbReady);
      redisReadyStatus.set(redisReady);
    }
  };
}

module.exports = {
  createMetrics
};
