/* auth.js — State autentikasi + tombol akun (pojok kanan atas).
 *
 * Mengisi setiap elemen .nav-auth:
 *   - belum login : tautan "Masuk" + "Daftar"
 *   - sudah login : nama user + menu (Akun Saya / Dashboard / Keluar)
 *
 * Butuh api.js dimuat lebih dulu.
 */
(function () {
  let currentUser = null;

  // Promise yang selesai setelah sesi dicek (dipakai halaman terproteksi).
  const ready = (window.api ? window.api.me() : Promise.resolve({ user: null }))
    .then(data => {
      currentUser = data.user || null;
      renderNav();
      return currentUser;
    });

  function escapeHtml(s) {
    return String(s == null ? '' : s)
      .replace(/&/g, '&amp;').replace(/</g, '&lt;')
      .replace(/>/g, '&gt;').replace(/"/g, '&quot;');
  }

  function injectStyles() {
    if (document.getElementById('nav-auth-styles')) return;
    const css = `
      .nav-auth{display:flex;align-items:center;gap:10px}
      .nav-auth a.na-login{font-weight:600;color:var(--text,#1f2937);text-decoration:none}
      .nav-auth a.na-register{font-weight:700;text-decoration:none;background:var(--brand,#0A66C2);
        color:#fff;padding:8px 16px;border-radius:8px}
      .na-menu{position:relative}
      .na-trigger{display:flex;align-items:center;gap:8px;background:none;border:1.5px solid #e5e7eb;
        padding:6px 12px;border-radius:999px;cursor:pointer;font-weight:600;color:var(--text,#1f2937)}
      .na-avatar{width:28px;height:28px;border-radius:50%;background:var(--brand,#0A66C2);color:#fff;
        display:flex;align-items:center;justify-content:center;font-weight:700;font-size:.85rem}
      .na-dropdown{position:absolute;right:0;top:calc(100% + 8px);background:#fff;border:1px solid #e5e7eb;
        border-radius:10px;box-shadow:0 8px 28px rgba(0,0,0,.12);min-width:200px;padding:6px;display:none;z-index:50}
      .na-dropdown.open{display:block}
      .na-dropdown .na-head{padding:10px 12px;border-bottom:1px solid #f1f5f9;margin-bottom:4px}
      .na-dropdown .na-head strong{display:block;font-size:.92rem;color:#111827}
      .na-dropdown .na-head span{font-size:.78rem;color:#6b7280}
      .na-dropdown a,.na-dropdown button{display:block;width:100%;text-align:left;padding:9px 12px;
        border:none;background:none;border-radius:7px;font-size:.9rem;color:#1f2937;cursor:pointer;text-decoration:none}
      .na-dropdown a:hover,.na-dropdown button:hover{background:#f3f4f6}
      .na-dropdown button.na-logout{color:#c62828}
    `;
    const tag = document.createElement('style');
    tag.id = 'nav-auth-styles';
    tag.textContent = css;
    document.head.appendChild(tag);
  }

  function renderNav() {
    injectStyles();
    document.querySelectorAll('.nav-auth').forEach(el => {
      if (currentUser) {
        const initial = escapeHtml((currentUser.nama || '?').charAt(0).toUpperCase());
        const dashLink = currentUser.role === 'pelamar'
          ? `<a href="dashboard.html">Dashboard</a>`
          : (currentUser.role === 'perusahaan'
            ? `<a href="admin.html">Dashboard HR</a>` : '');
        el.innerHTML = `
          <div class="na-menu">
            <button class="na-trigger" type="button" aria-haspopup="true" aria-expanded="false">
              <span class="na-avatar">${initial}</span>
              <span class="na-name">${escapeHtml(currentUser.nama)}</span>
              <span aria-hidden="true">▾</span>
            </button>
            <div class="na-dropdown" role="menu">
              <div class="na-head">
                <strong>${escapeHtml(currentUser.nama)}</strong>
                <span>${escapeHtml(currentUser.email)}</span>
              </div>
              <a href="account.html">Akun Saya</a>
              ${dashLink}
              <button type="button" class="na-logout">Keluar</button>
            </div>
          </div>`;
        const trigger = el.querySelector('.na-trigger');
        const dropdown = el.querySelector('.na-dropdown');
        trigger.addEventListener('click', e => {
          e.stopPropagation();
          const open = dropdown.classList.toggle('open');
          trigger.setAttribute('aria-expanded', open ? 'true' : 'false');
        });
        el.querySelector('.na-logout').addEventListener('click', logout);
      } else {
        el.innerHTML = `
          <a href="login.html" class="na-login">Masuk</a>
          <a href="register.html" class="na-register">Daftar</a>`;
      }
    });
  }

  // Tutup dropdown saat klik di luar.
  document.addEventListener('click', () => {
    document.querySelectorAll('.na-dropdown.open').forEach(d => {
      d.classList.remove('open');
      const t = d.parentElement.querySelector('.na-trigger');
      if (t) t.setAttribute('aria-expanded', 'false');
    });
  });

  async function logout() {
    try { await window.api.post('/auth/logout.php', {}); } catch (_) {}
    window.api.resetSession();
    currentUser = null;
    window.location.href = 'index.html';
  }

  /** Untuk halaman terproteksi. Redirect bila belum login / role salah. */
  async function requireAuth(role) {
    const user = await ready;
    if (!user) {
      window.location.href = 'login.html?next=' + encodeURIComponent(location.pathname.split('/').pop());
      return null;
    }
    if (role && user.role !== role) {
      window.location.href = 'index.html';
      return null;
    }
    return user;
  }

  function getUser() { return currentUser; }

  window.authUtils = { ready, requireAuth, getUser, logout, renderNav };
})();
