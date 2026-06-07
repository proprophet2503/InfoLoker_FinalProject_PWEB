const DATA_URL = './job_portal_50_data.json';

const CAT_ICONS = [
  'IT', 'Design', 'Marketing', 'Data',
  'Finance', 'Management', 'HR',
  'Operations', 'Support'
];

function esc(s) {
  return String(s).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;');
}

function shuffle(arr) {
  const a = [...arr];
  for (let i = a.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [a[i], a[j]] = [a[j], a[i]];
  }
  return a;
}

function logoPath(company) {
  return `./assets/logos/${company}.png`;
}

function logoImg(company, cls, fbCls) {
  return `
    <img src="${logoPath(company)}" alt="${esc(company)}" class="${cls}"
    onerror="this.onerror=null; this.replaceWith(createFallback('${esc(company)}','${fbCls}'))">
  `;
}

function createFallback(company, fbCls) {
  const div = document.createElement('div');
  div.className = fbCls;
  div.textContent = company[0];
  return div;
}

function fmtDate(s) {
  return new Date(s).toLocaleDateString('id-ID', { day: 'numeric', month: 'short', year: 'numeric' });
}

function fmtDateLong(s) {
  return new Date(s).toLocaleDateString('id-ID', { day: 'numeric', month: 'long', year: 'numeric' });
}

function daysAgo(dateStr) {
  const diff = Math.floor((Date.now() - new Date(dateStr)) / 86400000);
  if (diff === 0) return 'Hari ini';
  if (diff === 1) return 'Kemarin';
  return `${diff} hari lalu`;
}

async function fetchJobs() {
  const r = await fetch(DATA_URL, { cache: 'no-store' });
  if (!r.ok) throw new Error(`HTTP ${r.status}`);
  const data = await r.json();
  if (!Array.isArray(data)) throw new Error('Format data tidak valid');
  return data;
}
