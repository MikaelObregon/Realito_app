// Service Worker para Realito PWA — Soporte Offline 100% y Auto-actualización Silenciosa
const CACHE_NAME = 'realito-cache-v9';
const ASSETS_TO_CACHE = [
  '/',
  '/index.html',
  './',
  './index.html',
  'index.html',
  '/manifest.json',
  './manifest.json',
  'manifest.json',
  '/apple-touch-icon.png',
  './apple-touch-icon.png',
  '/icon-192.png',
  './icon-192.png',
  '/icon-512.png',
  './icon-512.png',
  'https://www.gstatic.com/antigravity/web/dev/tailwindcss.min.js',
  'https://cdnjs.cloudflare.com/ajax/libs/html2pdf.js/0.10.1/html2pdf.bundle.min.js'
];

self.addEventListener('install', (event) => {
  self.skipWaiting();
  event.waitUntil(
    caches.open(CACHE_NAME).then(async (cache) => {
      await Promise.allSettled(
        ASSETS_TO_CACHE.map(async (url) => {
          try {
            const res = await fetch(url, { cache: 'no-cache' });
            if (res && (res.ok || res.type === 'opaque')) {
              await cache.put(url, res);
            }
          } catch (err) {
            console.warn(`[SW] Pre-cache omitido para ${url}:`, err);
          }
        })
      );
    })
  );
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((keys) => {
      return Promise.all(
        keys.map((key) => {
          if (key !== CACHE_NAME) {
            return caches.delete(key);
          }
        })
      );
    })
  );
  self.clients.claim();
});

self.addEventListener('fetch', (event) => {
  const url = event.request.url;

  // Supabase y APIs externas pasan directo a la red (con su propio fallback offline en la app)
  if (url.includes('supabase.co') || url.includes('dolarapi.com')) {
    return;
  }

  // 1. Navegación (HTML de la app al abrir en el teléfono o recargar sin internet)
  if (event.request.mode === 'navigate') {
    event.respondWith(
      (async () => {
        const cache = await caches.open(CACHE_NAME);
        const cached = (await cache.match(event.request, { ignoreSearch: true }))
          || (await cache.match('/index.html'))
          || (await cache.match('./index.html'))
          || (await cache.match('index.html'))
          || (await cache.match('/'))
          || (await cache.match('./'));

        // En segundo plano actualiza la caché si hay conexión a internet disponible
        const fetchPromise = fetch(event.request)
          .then(async (networkResponse) => {
            if (networkResponse && networkResponse.status === 200) {
              await cache.put(event.request, networkResponse.clone());
              await cache.put('/index.html', networkResponse.clone());
              await cache.put('./index.html', networkResponse.clone());
            }
            return networkResponse;
          })
          .catch(() => null);

        if (cached) {
          return cached;
        }

        const networkResponse = await fetchPromise;
        if (networkResponse) return networkResponse;

        return (await cache.match('/index.html'))
          || (await cache.match('./index.html'))
          || (await cache.match('./'))
          || (await cache.match('/'));
      })()
    );
    return;
  }

  // 2. Recursos estáticos (scripts, estilos, imágenes): Cache-First con Stale-While-Revalidate
  event.respondWith(
    (async () => {
      const cache = await caches.open(CACHE_NAME);
      const cached = await cache.match(event.request, { ignoreSearch: true });
      if (cached) {
        // Actualizar en segundo plano si hay red
        fetch(event.request).then(async (netRes) => {
          if (netRes && (netRes.status === 200 || netRes.type === 'opaque')) {
            await cache.put(event.request, netRes.clone());
          }
        }).catch(() => {});
        return cached;
      }

      try {
        const netRes = await fetch(event.request);
        if (netRes && (netRes.status === 200 || netRes.type === 'opaque')) {
          await cache.put(event.request, netRes.clone());
        }
        return netRes;
      } catch (err) {
        return cached || null;
      }
    })()
  );
});
