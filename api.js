/* api.js — Pembungkus fetch ke backend PHP (same-origin + session cookie).
 *
 * Tidak ada token di localStorage: autentikasi memakai session cookie PHP.
 * Token CSRF diambil dari /api/auth/me.php lalu dikirim di header pada
 * setiap request yang mengubah data (POST).
 */
const API_BASE = '/api';

let _csrf = null;
let _mePromise = null;

/** Ambil sesi saat ini (user + csrf). Di-cache agar tidak berulang. */
function fetchMe() {
  if (!_mePromise) {
    _mePromise = fetch(`${API_BASE}/auth/me.php`, { credentials: 'same-origin' })
      .then(r => r.json())
      .then(d => {
        _csrf = d?.data?.csrf || null;
        return d?.data || { user: null, csrf: null };
      })
      .catch(() => ({ user: null, csrf: null }));
  }
  return _mePromise;
}

async function ensureCsrf() {
  if (_csrf) return _csrf;
  await fetchMe();
  return _csrf;
}

/** Reset cache sesi (dipanggil setelah login/logout). */
function resetSession() {
  _csrf = null;
  _mePromise = null;
}

async function apiFetch(path, options = {}) {
  const opts = { credentials: 'same-origin', ...options };
  opts.headers = { ...(options.headers || {}) };

  const method = (opts.method || 'GET').toUpperCase();

  if (method !== 'GET') {
    const token = await ensureCsrf();
    if (token) opts.headers['X-CSRF-Token'] = token;
  }

  // Body: JSON object -> string; FormData dibiarkan apa adanya.
  if (opts.body && !(opts.body instanceof FormData)) {
    if (typeof opts.body !== 'string') opts.body = JSON.stringify(opts.body);
    opts.headers['Content-Type'] = 'application/json';
  }

  const res = await fetch(`${API_BASE}${path}`, opts);
  const data = await res.json().catch(() => ({ success: false, error: 'Respons server tidak valid.' }));
  if (!res.ok || data.success === false) {
    throw new Error(data.error || `HTTP ${res.status}`);
  }
  return data;
}

const api = {
  get:      (path)       => apiFetch(path),
  post:     (path, body) => apiFetch(path, { method: 'POST', body }),
  postForm: (path, fd)   => apiFetch(path, { method: 'POST', body: fd }),
  me:       fetchMe,
  resetSession,
};

window.api = api;
