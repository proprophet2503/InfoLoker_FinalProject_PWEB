require('dotenv').config();
const express     = require('express');
const cors        = require('cors');
const rateLimit   = require('express-rate-limit');
const path        = require('path');
const { testConnection } = require('./config/db');

const app = express();

// ── CORS ──────────────────────────────────────────────────────────────────────
const allowedOrigins = (process.env.ALLOWED_ORIGINS || '').split(',').map(s => s.trim()).filter(Boolean);
app.use(cors({
  origin: (origin, cb) => {
    if (!origin || allowedOrigins.includes(origin)) return cb(null, true);
    cb(new Error('Not allowed by CORS'));
  },
  credentials: true,
}));

// ── Body parsing ──────────────────────────────────────────────────────────────
app.use(express.json({ limit: '1mb' }));
app.use(express.urlencoded({ extended: true, limit: '1mb' }));

// ── Static: serve uploaded files ──────────────────────────────────────────────
app.use('/uploads', express.static(path.join(__dirname, '../uploads')));

// ── Rate limit: login ─────────────────────────────────────────────────────────
const loginLimiter = rateLimit({ windowMs: 15 * 60 * 1000, max: 5,
  message: { success: false, error: 'Terlalu banyak percobaan login. Coba lagi 15 menit lagi.' } });
app.use('/api/auth/login', loginLimiter);

// ── Routes ────────────────────────────────────────────────────────────────────
app.use('/api/auth',     require('./routes/authRoutes'));
app.use('/api/lowongan', require('./routes/lowonganRoutes'));
app.use('/api/lamaran',  require('./routes/lamaranRoutes'));
app.use('/api/profil',   require('./routes/profilRoutes'));
app.use('/api/admin',    require('./routes/adminRoutes'));

// ── Health check ──────────────────────────────────────────────────────────────
app.get('/api/health', (_req, res) => res.json({ success: true, message: 'InfoLoker API v2.0 running' }));

// ── 404 ───────────────────────────────────────────────────────────────────────
app.use((_req, res) => res.status(404).json({ success: false, error: 'Endpoint tidak ditemukan' }));

// ── Error handler ─────────────────────────────────────────────────────────────
app.use((err, _req, res, _next) => {
  if (process.env.NODE_ENV !== 'production') console.error(err);
  res.status(err.status || 500).json({ success: false, error: err.message || 'Internal Server Error' });
});

// ── Start ─────────────────────────────────────────────────────────────────────
const PORT = parseInt(process.env.PORT || '3000');
testConnection()
  .then(() => app.listen(PORT, () => console.log(`[Server] http://localhost:${PORT}`)))
  .catch(err => { console.error('[DB] Connection failed:', err.message); process.exit(1); });
