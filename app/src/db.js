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
      const result = await pool.query(
        `SELECT
           id,
           name,
           book_title,
           member_name,
           membership_tier,
           item_format,
           shelf_code,
           due_date,
           service,
           environment,
           priority,
           status,
           owner_name,
           region,
           source,
           details,
           created_at
         FROM items
         ORDER BY created_at DESC, id DESC`
      );
      return result.rows;
    },
    async createItem(item) {
      const result = await pool.query(
        `INSERT INTO items (
           name,
           book_title,
           member_name,
           membership_tier,
           item_format,
           shelf_code,
           due_date,
           service,
           environment,
           priority,
           status,
           owner_name,
           region,
           source,
           details
         ) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15)
         RETURNING
           id,
           name,
           book_title,
           member_name,
           membership_tier,
           item_format,
           shelf_code,
           due_date,
           service,
           environment,
           priority,
           status,
           owner_name,
           region,
           source,
           details,
           created_at`,
        [
          item.name,
          item.book_title,
          item.member_name,
          item.membership_tier,
          item.item_format,
          item.shelf_code,
          item.due_date,
          item.service,
          item.environment,
          item.priority,
          item.status,
          item.owner_name,
          item.region,
          item.source,
          item.details
        ]
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
