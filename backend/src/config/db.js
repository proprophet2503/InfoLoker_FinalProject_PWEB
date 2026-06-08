const mysql = require('mysql2/promise');

const pool = mysql.createPool({
  host:     process.env.DB_HOST     || 'localhost',
  port:     parseInt(process.env.DB_PORT || '3306'),
  user:     process.env.DB_USER     || 'root',
  password: process.env.DB_PASSWORD || '',
  database: process.env.DB_NAME     || 'infoloker_db',
  waitForConnections: true,
  connectionLimit:    10,
  charset: 'utf8mb4',
});

async function testConnection() {
  const conn = await pool.getConnection();
  await conn.ping();
  conn.release();
  console.log('[DB] MySQL connected —', process.env.DB_NAME);
}

module.exports = { pool, testConnection };
