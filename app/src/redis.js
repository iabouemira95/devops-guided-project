const { createClient } = require("redis");

function createRedis(config = {}) {
  const client = createClient({
    socket: {
      host: config.host || process.env.REDIS_HOST || "redis",
      port: Number(config.port || process.env.REDIS_PORT || 6379)
    }
  });

  client.on("error", () => {
    // Errors are handled by readiness checks and request-level error logging.
  });

  let connected = false;

  async function connect() {
    if (!connected) {
      await client.connect();
      connected = true;
    }
  }

  return {
    async isReady() {
      await connect();
      await client.ping();
      return true;
    },
    async get(key) {
      await connect();
      return client.get(key);
    },
    async setEx(key, seconds, value) {
      await connect();
      await client.setEx(key, seconds, value);
    },
    async close() {
      if (connected) {
        await client.quit();
        connected = false;
      }
    }
  };
}

module.exports = {
  createRedis
};
