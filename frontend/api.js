/* api.js — Fetch wrapper ke InfoLoker REST API */
const API_BASE = 'http://localhost:3000/api';

function getToken() { return localStorage.getItem('il_token'); }

async function apiFetch(path, options = {}) {
  const token = getToken();
  const headers = { 'Content-Type': 'application/json', ...(options.headers || {}) };
  if (token) headers['Authorization'] = `Bearer ${token}`;
  if (options.body instanceof FormData) delete headers['Content-Type'];

  const res = await fetch(`${API_BASE}${path}`, { ...options, headers });
  const data = await res.json().catch(() => ({ success: false, error: 'Server error' }));
  if (!res.ok && !data.success) throw new Error(data.error || `HTTP ${res.status}`);
  return data;
}

const api = {
  get:    (path)         => apiFetch(path),
  post:   (path, body)   => apiFetch(path, { method: 'POST', body: body instanceof FormData ? body : JSON.stringify(body) }),
  put:    (path, body)   => apiFetch(path, { method: 'PUT',  body: JSON.stringify(body) }),
  delete: (path)         => apiFetch(path, { method: 'DELETE' }),
  postForm: (path, fd)   => apiFetch(path, { method: 'POST', body: fd }),
};

window.api = api;
