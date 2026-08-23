// Yinor Coffee - visitor tracking (Netlify Function + Blobs)
// Records: date, page views, country (via ip-api.com), device type, referrer
import { getStore } from '@netlify/blobs';

const COUNTRY_CACHE = {};

async function getCountry(req) {
  try {
    const ip = req.headers.get('x-nf-client-connection-ip') || req.headers.get('x-forwarded-for') || '';
    const clean = ip.split(',')[0].trim();
    if (!clean || clean === '::1' || clean === '127.0.0.1') return 'Unknown';
    if (COUNTRY_CACHE[clean]) return COUNTRY_CACHE[clean];
    const res = await fetch('http://ip-api.com/json/' + encodeURIComponent(clean) + '?fields=countryCode,city&lang=en');
    const data = await res.json();
    const cc = (data && data.countryCode) || 'Unknown';
    COUNTRY_CACHE[clean] = cc;
    return cc;
  } catch (e) {
    return 'Unknown';
  }
}

export default async (req) => {
  const store = getStore('visits');
  const url = new URL(req.url);

  // POST: record a page view
  if (req.method === 'POST') {
    try {
      const body = await req.json();
      const today = new Date().toISOString().slice(0, 10);
      const key = 'd:' + today;
      const existing = (await store.get(key, { type: 'json' })) || { views: 0, pages: {}, countries: {}, devices: {}, referrers: {} };

      existing.views += 1;
      const p = (body.path || '/').split('?')[0];
      existing.pages[p] = (existing.pages[p] || 0) + 1;

      // country
      const country = await getCountry(req);
      existing.countries[country] = (existing.countries[country] || 0) + 1;

      // device
      const ua = (req.headers.get('user-agent') || '').toLowerCase();
      let device = 'desktop';
      if (/mobile|android|iphone|ipad|tablet/i.test(ua)) device = 'mobile';
      existing.devices[device] = (existing.devices[device] || 0) + 1;

      // referrer
      const ref = (body.referrer || '').replace(/^https?:\/\//, '').replace(/^www\./, '').toLowerCase();
      if (ref) {
        existing.referrers[ref] = (existing.referrers[ref] || 0) + 1;
      }

      await store.setJSON(key, existing);
      return new Response(JSON.stringify({ ok: true }), { status: 200, headers: { 'Content-Type': 'application/json' } });
    } catch (e) {
      return new Response(JSON.stringify({ ok: false, error: String(e && e.message ? e.message : e) }), { status: 400, headers: { 'Content-Type': 'application/json' } });
    }
  }

  // GET: last 30 days summary
  if (req.method === 'GET') {
    const days = [];
    for (let i = 0; i < 30; i++) {
      const d = new Date(Date.now() - i * 86400000).toISOString().slice(0, 10);
      const data = await store.get('d:' + d, { type: 'json' });
      if (data && data.views > 0) days.push(Object.assign({ date: d }, data));
    }
    return new Response(JSON.stringify({ site: 'yinorcoffee.com', days }), {
      status: 200,
      headers: { 'Content-Type': 'application/json' }
    });
  }

  return new Response('Method not allowed', { status: 405 });
};
