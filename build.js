#!/usr/bin/env node
// Yinor Coffee - static site builder (Node version, runs on Netlify build)
// Usage: node build.js   (set BASE_PATH env for GitHub Pages project sites)
'use strict';
const fs = require('fs');
const path = require('path');

const root = __dirname;
const src = path.join(root, 'src');
const out = path.join(root, 'docs');
const domain = 'https://yinorcoffee.com';
const today = new Date().toISOString().slice(0, 10);

// ---------- clean output ----------
fs.rmSync(out, { recursive: true, force: true });
fs.mkdirSync(out, { recursive: true });

// ---------- copy assets ----------
fs.cpSync(path.join(root, 'assets'), path.join(out, 'assets'), { recursive: true });

const read = (p) => fs.readFileSync(p, 'utf8');
const write = (p, c) => { fs.mkdirSync(path.dirname(p), { recursive: true }); fs.writeFileSync(p, c, 'utf8'); };

// ---------- front matter helpers ----------
function parseFrontMatter(content) {
  const m = content.match(/^<!--\s*([\s\S]*?)\s*-->/);
  const fields = {};
  if (m) {
    for (const line of m[1].split('\n')) {
      const mm = line.match(/^\s*([A-Za-z0-9_]+)\s*:\s*(.*?)\s*$/);
      if (mm) fields[mm[1]] = mm[2].trim();
    }
  }
  return fields;
}
const stripFrontMatter = (c) => c.replace(/^<!--\s*[\s\S]*?\s*-->\s*/, '').trim();

// ---------- collect products ----------
const products = fs.readdirSync(path.join(src, 'products'))
  .filter(f => f.endsWith('.body.html'))
  .sort()
  .map(f => {
    const fm = parseFrontMatter(read(path.join(src, 'products', f)));
    return Object.assign({ slug: f.replace(/\.body\.html$/, '') }, fm);
  });

const catLabel = { regular: 'Regular Espresso Blend', premium: 'Premium Espresso Blend', soe: 'Single Origin Espresso' };
const productCard = (p) => {
  const imgs = (galleryMap && galleryMap[p.slug]) || [];
  const img2 = imgs.length > 1 ? imgs[1] : null;
  const hoverImg = img2
    ? `\n  <img src="${img2}" alt="${p.pname} - alternate image" class="pc-img2" loading="lazy">`
    : '';
  return [
    `<a class="product-card" href="/${p.slug}">`,
    '  <div class="pc-images">',
    `    <img src="${p.ogimage}" alt="${p.pname} - wholesale coffee beans - Yinor Coffee" loading="lazy">`,
    hoverImg,
    '  </div>',
    '  <div class="body">',
    `    <h3>${p.pname}</h3>`,
    `    <p class="flavor">${p.flavor}</p>`,
    '    <span class="pc-btn">View Product</span>',
    '  </div>',
    '</a>'
  ].join('\n');
};
const productGrid = (which) => products.filter(p => which === 'all' || p.category === which).map(productCard).join('\n');

const featured = [
  'fruit-sugar-signature-espresso-medium-roast-sidama-and-yirgacheffe-blend-naturally-sweet-coffee-bean',
  'high-quality-espresso-blends-coffee-beans-dark-roastedmalt-creamy-chocolate-toast-hazelnut-flavor',
  'kenya-nyeri-aa-soe-espresso-coffeeberry-brown-sugar-medium-aciditymedium-roast-coffee-bean',
  'yirgacheffe-natural-soe-espresso-coffee-ethiopia-g1-2400m-heirloom-lemon-and-tropical-fruit-flavor-coffee-bean',
  'sunshine-orchard-whole-bean-coffee-454g-medium-dark-roast-espresso-blend',
  'wholesale-high-quality-yunnan-ethiopia-coffee-beans-grizzly-basque-10-series-espresso-coffee-beans-454gbag-oem-customizable'
];
const homeProducts = featured.map(slug => {
  const p = products.find(x => x.slug === slug);
  return p ? productCard(p) : '';
}).join('\n');

// ---------- collect posts ----------
const posts = fs.readdirSync(path.join(src, 'posts'))
  .filter(f => f.endsWith('.body.html'))
  .map(f => {
    const fm = parseFrontMatter(read(path.join(src, 'posts', f)));
    return Object.assign({ slug: f.replace(/\.body\.html$/, '') }, fm);
  })
  .sort((a, b) => (b.date || '').localeCompare(a.date || ''));
const postList = posts.map(p => [
  `<a class="post-list-item" href="/${p.slug}">`,
  `  <div class="post-meta">${p.date} &middot; Yinor Coffee</div>`,
  `  <h3>${p.title}</h3>`,
  `  <p>${p.desc}</p>`,
  '</a>'
].join('\n')).join('\n');

// ---------- templates ----------
const headerTpl = read(path.join(src, 'partials', 'header.html'));
const footerTpl = read(path.join(src, 'partials', 'footer.html'));
const basePath = (process.env.BASE_PATH || '').replace(/\/+$/, '');

// ---------- sitemap ----------
const sitemap = [];

// ---------- product gallery map (old-site images) ----------
let galleryMap = {};
const galleryMapFile = path.join(root, 'assets', 'img', 'gallery', 'gallery-map.json');
if (fs.existsSync(galleryMapFile)) {
  try { galleryMap = JSON.parse(fs.readFileSync(galleryMapFile, 'utf8')); } catch (e) { galleryMap = {}; }
}

function galleryHtml(slug, pname) {
  const imgs = galleryMap[slug] || [];
  if (!imgs.length) {
    return '<img src="/assets/img/hero-products.jpg" alt="' + (pname || 'Yinor Coffee') + '" style="border-radius:var(--radius);box-shadow:var(--shadow);">';
  }
  const slides = imgs.map(function (src, i) {
    const alt = i === 0 ? (pname + ' - wholesale coffee beans - Yinor Coffee') : (pname + ' - product image ' + (i + 1));
    return '      <img src="' + src + '" alt="' + alt + '" class="gallery-slide' + (i === 0 ? ' active' : '') + '" data-i="' + i + '" loading="lazy">';
  }).join('\n');
  const thumbs = imgs.map(function (src, i) {
    return '      <img src="' + src + '" alt="Thumbnail ' + (i + 1) + '" class="gallery-thumb' + (i === 0 ? ' active' : '') + '" data-i="' + i + '" loading="lazy">';
  }).join('\n');
  return '<div class="gallery" data-gallery>\n    <div class="gallery-slides">\n' + slides + '\n    </div>\n    <button class="gallery-btn gallery-prev" type="button" aria-label="Previous image">&#10094;</button>\n    <button class="gallery-btn gallery-next" type="button" aria-label="Next image">&#10095;</button>\n    <div class="gallery-thumbs">\n' + thumbs + '\n    </div>\n  </div>';
}

function buildPage(bodyFile, slug, isIndex, priority, excludeFromSitemap) {
  const content = read(bodyFile);
  const fm = parseFrontMatter(content);
  const body = stripFrontMatter(content);
  const canonical = isIndex ? domain + '/' : domain + '/' + slug + '/';
  const ogImage = fm.ogimage || '/assets/img/hero-home.jpg';

  let html = headerTpl
    .replace('{{TITLE}}', fm.title || '')
    .replace('{{DESC}}', fm.desc || '')
    .replace('{{CANONICAL}}', canonical)
    .replace('{{OG_TITLE}}', fm.title || 'Yinor Coffee - Wholesale Specialty Coffee Beans')
    .replace('{{OG_DESC}}', fm.desc || 'Wholesale specialty coffee beans from China. Custom roasting, private label & OEM for cafes and roasters.')
    .replace('{{OG_IMAGE}}', ogImage)
    + '\n' + body + '\n' + footerTpl;

  html = html.replace(/\{\{PRODUCT_GRID:all\}\}/g, productGrid('all'));
  html = html.replace(/\{\{PRODUCT_GRID:regular\}\}/g, productGrid('regular'));
  html = html.replace(/\{\{PRODUCT_GRID:premium\}\}/g, productGrid('premium'));
  html = html.replace(/\{\{PRODUCT_GRID:soe\}\}/g, productGrid('soe'));
  html = html.replace(/\{\{HOME_PRODUCTS\}\}/g, homeProducts);
  html = html.replace(/\{\{POST_LIST\}\}/g, postList);
  if (html.indexOf('{{GALLERY}}') !== -1) {
    html = html.replace(/\{\{GALLERY\}\}/g, galleryHtml(slug, fm.pname || fm.title || 'Yinor Coffee'));
  }

  if (basePath) html = html.replace(/(href|src)="\//g, `$1="${basePath}/`);

  const dir = isIndex ? out : path.join(out, slug);
  write(path.join(dir, 'index.html'), html);

  if (!excludeFromSitemap) {
    sitemap.push(`  <url><loc>${isIndex ? domain + '/' : domain + '/' + slug + '/'}</loc><lastmod>${today}</lastmod><priority>${priority}</priority></url>`);
  }
  console.log('built:', path.join(dir, 'index.html'));
}

// ---------- build pages ----------
const pages = [
  { f: 'index.body.html', s: 'index', i: true, p: '1.0' },
  { f: 'premium-espresso-blends-coffee-beans.body.html', s: 'premium-espresso-blends-coffee-beans', i: false, p: '0.9' },
  { f: 'regular-espresso-blends-coffee-beans.body.html', s: 'regular-espresso-blends-coffee-beans', i: false, p: '0.8' },
  { f: 'premium-espresso-coffee-beans.body.html', s: 'premium-espresso-coffee-beans', i: false, p: '0.8' },
  { f: 'single-origin-espresso-soe-coffee-beans.body.html', s: 'single-origin-espresso-soe-coffee-beans', i: false, p: '0.8' },
  { f: 'about-us-coffee-beans.body.html', s: 'about-us-coffee-beans', i: false, p: '0.6' },
  { f: 'request-a-consultation-coffee-wholesale-inquiry.body.html', s: 'request-a-consultation-coffee-wholesale-inquiry', i: false, p: '0.6' },
  { f: 'blog.body.html', s: 'blog', i: false, p: '0.6' },
  { f: 'privacy-policy.body.html', s: 'privacy-policy', i: false, p: '0.3' },
  { f: 'terms-and-conditions.body.html', s: 'terms-and-conditions', i: false, p: '0.3' },
  { f: 'product-catalog.body.html', s: 'product-catalog', i: false, p: '0.0', x: true },
  { f: 'stats.body.html', s: 'stats', i: false, p: '0.0', x: true }
];
for (const pg of pages) {
  buildPage(path.join(src, 'pages', pg.f), pg.s, pg.i, pg.p, pg.x);
}

// ---------- build products & posts ----------
for (const p of products) buildPage(path.join(src, 'products', p.slug + '.body.html'), p.slug, false, '0.7');
for (const p of posts) buildPage(path.join(src, 'posts', p.slug + '.body.html'), p.slug, false, '0.6');

// ---------- 404 ----------
{
  const c = read(path.join(src, 'pages', '404.body.html'));
  const fm = parseFrontMatter(c);
  const html = headerTpl
    .replace('{{TITLE}}', fm.title).replace('{{DESC}}', fm.desc)
    .replace('{{CANONICAL}}', domain + '/404.html')
    .replace('{{OG_TITLE}}', fm.title).replace('{{OG_DESC}}', fm.desc)
    .replace('{{OG_IMAGE}}', '/assets/img/hero-home.jpg')
    + '\n' + stripFrontMatter(c) + '\n' + footerTpl;
  write(path.join(out, '404.html'), html);
}

// ---------- robots.txt ----------
write(path.join(out, 'robots.txt'), `User-agent: *\nAllow: /\n\nSitemap: ${domain}/sitemap.xml\n`);

// ---------- sitemap.xml ----------
write(path.join(out, 'sitemap.xml'),
  '<?xml version="1.0" encoding="UTF-8"?>\n<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n' +
  sitemap.join('\n') + '\n</urlset>\n');

// ---------- _redirects (Netlify) ----------
write(path.join(out, '_redirects'),
  '/product-catalog  /premium-espresso-blends-coffee-beans  301\n/home  /  301\n');

// ---------- GitHub Pages helper ----------
write(path.join(out, '.nojekyll'), '');
write(path.join(out, 'CNAME'), 'yinorcoffee.com\n');

// ---------- Decap CMS admin ----------
if (fs.existsSync(path.join(src, 'admin'))) {
  fs.cpSync(path.join(src, 'admin'), path.join(out, 'admin'), { recursive: true });
  console.log('built: docs/admin (Decap CMS)');
}

console.log('\n=== Build complete ===');
console.log(`Pages: ${sitemap.length} URLs in sitemap, ${products.length} products, ${posts.length} posts`);
