// Replaces a previously installed Flutter service worker. It drops the
// cached app and does not cache anything else.
self.addEventListener('install', function () {
  self.skipWaiting();
});

self.addEventListener('activate', function (event) {
  event.waitUntil(
    caches.keys().then(function (keys) {
      return Promise.all(keys.map(function (key) {
        return caches.delete(key);
      }));
    }).then(function () {
      return self.registration.unregister();
    }).then(function () {
      return self.clients.matchAll({type: 'window'});
    }).then(function (clients) {
      return Promise.all(clients.map(function (client) {
        return client.navigate(client.url);
      }));
    })
  );
});
