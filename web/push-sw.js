// Minimal push-only service worker registered at /push-scope/
// No fetch listener — Flutter's flutter_service_worker.js handles asset caching.

self.addEventListener('push', (event) => {
  if (!event.data) return;
  const data = event.data.json();
  event.waitUntil(
    self.registration.showNotification(data.title || 'Worship Lamal', {
      body: data.body || 'A shared setlist was updated.',
      icon: data.icon || '/icons/Icon-192.png',
      badge: data.badge || '/icons/Icon-192.png',
      data: data.data || {},
    })
  );
});

self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  const targetUrl = event.notification.data?.url || '/';
  event.waitUntil(
    clients
      .matchAll({ type: 'window', includeUncontrolled: true })
      .then((windowClients) => {
        for (const client of windowClients) {
          if (client.url.includes(targetUrl) && 'focus' in client) {
            return client.focus();
          }
        }
        return clients.openWindow(targetUrl);
      })
  );
});
