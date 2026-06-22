const fs = require("fs");
const path = require("path");

function ensureParentDir(filePath) {
  fs.mkdirSync(path.dirname(filePath), { recursive: true });
}

function writeLine(filePath, line) {
  if (!filePath) {
    return;
  }

  ensureParentDir(filePath);
  fs.appendFileSync(filePath, `${line}\n`, "utf8");
}

function createLogger(options = {}) {
  const appName = options.appName || process.env.APP_NAME || "devops-mini-app";
  const environment = options.environment || process.env.APP_ENV || "local";
  const logFile = options.logFile || process.env.APP_LOG_FILE || "";

  function log(level, message, extra = {}) {
    const payload = {
      timestamp: new Date().toISOString(),
      level,
      app_name: appName,
      environment,
      message,
      ...extra
    };

    const line = JSON.stringify(payload);
    process.stdout.write(`${line}\n`);
    writeLine(logFile, line);
  }

  return {
    info(message, extra) {
      log("info", message, extra);
    },
    warn(message, extra) {
      log("warn", message, extra);
    },
    error(message, extra) {
      log("error", message, extra);
    }
  };
}

module.exports = {
  createLogger
};
