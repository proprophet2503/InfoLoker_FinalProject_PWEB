/* auth.js — Auth state management */
const AUTH_KEY  = 'il_token';
const USER_KEY  = 'il_user';

function saveAuth(token, user) {
  localStorage.setItem(AUTH_KEY, token);
  localStorage.setItem(USER_KEY, JSON.stringify(user));
}

function clearAuth() {
  localStorage.removeItem(AUTH_KEY);
  localStorage.removeItem(USER_KEY);
}

function getUser()  { try { return JSON.parse(localStorage.getItem(USER_KEY)); } catch { return null; } }
function getToken() { return localStorage.getItem(AUTH_KEY); }
function isLoggedIn() { return !!getToken(); }

function requireAuth(role) {
  if (!isLoggedIn()) { window.location.href = '/frontend/login.html'; return false; }
  if (role && getUser()?.role !== role) { window.location.href = '/frontend/index.html'; return false; }
  return true;
}

function updateNavbar() {
  const user = getUser();
  const loginLinks = document.querySelectorAll('.nav-login');
  const userMenu   = document.getElementById('nav-user-menu');
  const userName   = document.getElementById('nav-user-name');
  if (user && isLoggedIn()) {
    loginLinks.forEach(el => el.style.display = 'none');
    if (userMenu) userMenu.style.display = 'flex';
    if (userName) userName.textContent = user.nama;
  } else {
    loginLinks.forEach(el => el.style.display = '');
    if (userMenu) userMenu.style.display = 'none';
  }
}

window.authUtils = { saveAuth, clearAuth, getUser, getToken, isLoggedIn, requireAuth, updateNavbar };
