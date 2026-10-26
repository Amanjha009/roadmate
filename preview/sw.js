/**
 * RoadMate India — Service Worker (Offline Cache & PWA Support).
 * Caches application shell, dark map tiles, and handles offline fallbacks.
 */

const CACHE_NAME = 'roadmate-india-v4';
const STATIC_ASSETS = [
  '/',
  '/index.html',
  '/style.css',
  '/app.js',
  '/manifest.json',
  '/assets/images/roadmate_icon.svg',
  '/assets/images/roadmate_brand_lockup.svg',
];

self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => {
      return cache.addAll(STATIC_ASSETS);
    })
  );
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((keys) => {
      return Promise.all(
        keys.filter((key) => key !== CACHE_NAME && key !== 'roadmate-tiles-v1').map((key) => caches.delete(key))
      );
    })
  );
  self.clients.claim();
});

self.addEventListener('fetch', (event) => {
  if (event.request.method !== 'GET') return;

  const url = new URL(event.request.url);

  // Cache CartoDB Dark Matter & OpenStreetMap tiles aggressively
  if (url.hostname.includes('basemaps.cartocdn.com') || url.hostname.includes('tile.openstreetmap.org')) {
    event.respondWith(
      caches.open('roadmate-tiles-v1').then((tileCache) => {
        return tileCache.match(event.request).then((cachedTile) => {
          if (cachedTile) return cachedTile;
          return fetch(event.request).then((networkResp) => {
            if (networkResp.status === 200) {
              tileCache.put(event.request, networkResp.clone());
            }
            return networkResp;
          }).catch(() => cachedTile);
        });
      })
    );
    return;
  }

  // Network-first for index.html, app.js, style.css to ensure instant Vercel deploys
  const isCoreAsset = url.pathname === '/' ||
    url.pathname.endsWith('.html') ||
    url.pathname.endsWith('.js') ||
    url.pathname.endsWith('.css');

  if (isCoreAsset) {
    event.respondWith(
      fetch(event.request)
        .then((networkResponse) => {
          if (networkResponse && networkResponse.status === 200) {
            const responseClone = networkResponse.clone();
            caches.open(CACHE_NAME).then((cache) => cache.put(event.request, responseClone));
          }
          return networkResponse;
        })
        .catch(() => caches.match(event.request).then((cached) => cached || (url.pathname.endsWith('.html') || url.pathname === '/' ? caches.match('/index.html') : null)))
    );
    return;
  }

  // Cache-first for images, fonts, and static media
  event.respondWith(
    caches.match(event.request).then((cached) => {
      if (cached) return cached;
      return fetch(event.request).then((networkResp) => {
        if (networkResp && networkResp.status === 200) {
          const respClone = networkResp.clone();
          caches.open(CACHE_NAME).then((cache) => cache.put(event.request, respClone));
        }
        return networkResp;
      }).catch(() => {
        if (event.request.headers.get('accept')?.includes('text/html')) {
          return caches.match('/index.html');
        }
      });
    })
  );
});
