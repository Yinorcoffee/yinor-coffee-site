// Yinor Coffee - lightweight visitor counter (Netlify Function + Blobs)
import { getStore } from '@netlify/blobs';

export default async (req) => {
  const store = getStore('visits');
  const method = req.method;
  const url = new URL(req.url);

  // POST: record a page view
  if (method === 'POST') {
    try {
      const body = await req.json();
      const today = new Date().toISOString().slice(0, 10);
      const key = 'd:' + today;
      const existing = (await store.get(key, { type: 'json' })) || { views: 0, pages: {} };
      existing.views += 1;
      const p = (body.path || '/').split('?')[0];
      existing.pages[p] = (existing.pages[p] || 0) + 1;
      await store.setJSON(key, existing);
      return new Response(JSON.stringify({ ok: true }), { status: 200, headers: { 'Content-Type': 'application/json' } });
    } catch (e) {
      return new Response(JSON.stringify({ ok: false, error: String(e && e.message ? e.message : e) }), { status: 400, headers: { 'Content-Type': 'application/json' } });
    }
  }

  // GET: return last 30 days summary
  if (method === 'GET') {
    const days = [];
    for (let i = 0; i < 30; i++) {
      const d = new Date(Date.now() - i * 86400000).toISOString().slice(0, 10);
      const data = await store.get('d:' + d, { type: 'json' });
      if (data && data.views > 0) days.push({ date: d, views: data.views, pages: data.pages });
    }
    return new Response(JSON.stringify({ site: 'yinorcoffee.com', days }), {
      status: 200,
      headers: { 'Content-Type': 'application/json' }
    });
  }

  return new Response('Method not allowed', { status: 405 });
};
