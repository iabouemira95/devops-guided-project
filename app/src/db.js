const { Pool } = require("pg");

function createDb(config = {}) {
  const pool = new Pool({
    host: config.host || process.env.POSTGRES_HOST || "postgres",
    port: Number(config.port || process.env.POSTGRES_PORT || 5432),
    database: config.database || process.env.POSTGRES_DB || "devops_app",
    user: config.user || process.env.POSTGRES_USER || "appuser",
    password: config.password || process.env.POSTGRES_PASSWORD || "apppassword"
  });

  return {
    async isReady() {
      await pool.query("SELECT 1");
      return true;
    },
    async getItems() {
      const result = await pool.query("SELECT id, name, created_at FROM items ORDER BY id ASC");
      return result.rows;
    },
    async createItem(name) {
      const result = await pool.query(
        "INSERT INTO items (name) VALUES ($1) RETURNING id, name, created_at",
        [name]
      );
      return result.rows[0];
    },
    async close() {
      await pool.end();
    }
  };
}

module.exports = {
  createDb
};
