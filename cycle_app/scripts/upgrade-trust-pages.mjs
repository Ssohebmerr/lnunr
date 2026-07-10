import fs from 'fs';
import path from 'path';

const publicDir = path.resolve('public');
const files = [
  'security.html', 'cookies.html', 'ip-address.html', 'privacy-faq.html',
  'your-body-your-data.html', 'your-data-ends.html', 'accessibility.html',
];

const nav = `<nav class="site-nav">
  <div class="container">
    <a href="index.html" class="nav-brand"><span class="nav-mark">L</span><span>Lune</span></a>
    <div class="nav-links">
      <a href="index.html">Home</a>
      <a href="trust-hub.html">Trust</a>
      <a href="privacy-policy.html">Privacy</a>
      <a href="index.html#download" class="btn btn-primary" style="padding:10px 20px;font-size:0.85rem;">Get the app</a>
    </div>
    <button class="nav-toggle" id="navToggle" aria-label="Menu"><svg class="icon" viewBox="0 0 24 24"><path d="M4 7h16M4 12h16M4 17h16"/></svg></button>
  </div>
</nav>
<div class="nav-drawer" id="navDrawer">
  <div class="nav-drawer-panel">
    <button class="nav-drawer-close" id="navClose" aria-label="Close">×</button>
    <a href="index.html">Home</a>
    <a href="trust-hub.html">Trust hub</a>
    <a href="privacy-policy.html">Privacy Policy</a>
    <a href="terms-of-service.html">Terms</a>
  </div>
</div>`;

const footer = `<footer class="site-footer">
  <div class="container">
    <div class="footer-grid">
      <div class="footer-col"><h4>Trust</h4><a href="trust-hub.html">Trust hub</a><a href="privacy-faq.html">FAQ</a><a href="security.html">Security</a></div>
      <div class="footer-col"><h4>Legal</h4><a href="privacy-policy.html">Privacy Policy</a><a href="terms-of-service.html">Terms</a></div>
      <div class="footer-col"><h4>Contact</h4><a href="mailto:merrsoheb@gmail.com">merrsoheb@gmail.com</a><a href="index.html">Home</a></div>
    </div>
    <div class="footer-bottom">&copy; 2026 Lune</div>
  </div>
</footer>`;

const drawerScript = `  const drawer = document.getElementById('navDrawer');
  document.getElementById('navToggle')?.addEventListener('click', () => drawer.classList.add('open'));
  document.getElementById('navClose')?.addEventListener('click', () => drawer.classList.remove('open'));
  drawer?.addEventListener('click', (e) => { if (e.target === drawer) drawer.classList.remove('open'); });
`;

for (const file of files) {
  const fp = path.join(publicDir, file);
  let html = fs.readFileSync(fp, 'utf8');
  const title = html.match(/<h1 id="pageTitle">([^<]*)<\/h1>/)?.[1] ?? 'Lune';
  const subtitle = html.match(/<p id="pageSubtitle">([^<]*)<\/p>/)?.[1] ?? '';

  html = html.replace(/<link rel="stylesheet" href="trust\.css">/, '<link rel="stylesheet" href="site.css">');

  const hero = `${nav}
<section class="page-hero">
  <div class="container">
    <a href="trust-hub.html" class="breadcrumb">← Trust & Privacy</a>
    <h1 id="pageTitle">${title}</h1>
    <p class="lead" id="pageSubtitle">${subtitle}</p>
    <div class="lang-bar">
      <button class="lang-btn active" onclick="setLang('en')">English</button>
      <button class="lang-btn" onclick="setLang('ar')">العربية</button>
    </div>
  </div>
</section>

<div class="content-wrap">`;

  html = html.replace(/<body>\s*<div class="trust-header">[\s\S]*?<\/div>\s*<div class="container">/, `<body>\n${hero}`);
  html = html.replace(/class="card"/g, 'class="content-card"');
  html = html.replace(/ class="section-start"/g, '');
  html = html.replace(/<div class="footer">[\s\S]*?<\/div>\s*(?=<script>)/, `${footer}\n\n`);
  if (!html.includes("getElementById('navToggle')")) {
    html = html.replace(/\n<\/script>\n<\/body>/, `\n${drawerScript}\n</script>\n</body>`);
  }
  fs.writeFileSync(fp, html);
  console.log('OK', file);
}
