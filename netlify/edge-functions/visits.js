// Yinor Coffee - visitor tracking edge function (country + device + pages)
import { getStore } from '@netlify/blobs';

export default async (req, context) => {
  const store = getStore('visits');
  const url = new URL(req.url);

  // POST: record a page view
  if (req.method === 'POST') {
    try {
      const body = await req.json();
      const today = new Date().toISOString().slice(0, 10);
      const key = 'd:' + today;
      const existing = (await store.get(key, { type: 'json' })) || { views: 0, pages: {}, countries: {}, devices: {} };

      existing.views += 1;
      const p = (body.path || '/').split('?')[0];
      existing.pages[p] = (existing.pages[p] || 0) + 1;

      // country + city from Netlify edge geo data
      const geo = context.geo || {};
      const country = (geo.country && geo.country.code) || 'Unknown';
      const city = geo.city || '';
      existing.countries[country] = (existing.countries[country] || 0) + 1;
      if (city) {
        existing.cities = existing.cities || {};
        const ck = country + '-' + city;
        existing.cities[ck] = (existing.cities[ck] || 0) + 1;
      }

      // device type from user agent
      const ua = (req.headers.get('user-agent') || '').toLowerCase();
      let device = 'desktop';
      if (/mobile|android|iphone|ipad|tablet/i.test(ua)) device = 'mobile';
      existing.devices[device] = (existing.devices[device] || 0) + 1;

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
