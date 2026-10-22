const CACHE='legendfolio-release-__RELEASE_ID__';
const SHELL=['./','./index.html','./release.json','./manifest.webmanifest','./icon-192.png','./icon-512.png','./favicon.svg','./legendfolio-favicon-v2.svg','./favicon.ico','./vendor/supabase-2.117.3.js','./vendor/pdf-lib-1.17.1.min.js','./legendfolio-icon-v2-192.png','./legendfolio-icon-v2-512.png','./rules/srd-2014.pdf','./rules/srd-2024.pdf'];
self.addEventListener('install',event=>event.waitUntil(caches.open(CACHE).then(cache=>cache.addAll([...SHELL,...__PORTRAIT_ASSETS__])).then(()=>self.skipWaiting())));
self.addEventListener('message',event=>{if(event.data?.type==='ACTIVATE_UPDATE')self.skipWaiting();});
self.addEventListener('activate',event=>event.waitUntil(caches.keys().then(keys=>Promise.all(keys.filter(key=>(key.startsWith('strixhaven-shell-')||key.startsWith('ttrpg-')||key.startsWith('legendfolio-'))&&key!==CACHE).map(key=>caches.delete(key)))).then(()=>self.clients.claim())));
self.addEventListener('fetch',event=>{if(event.request.method!=='GET')return;const url=new URL(event.request.url),local=url.origin===self.location.origin,pdf=url.origin==='https://cdnjs.cloudflare.com'&&url.pathname.startsWith('/ajax/libs/pdf.js/4.10.38/');if(!local&&!pdf)return;
 // Update discovery must never be answered from an old app cache.
 if(local&&(/\/(release\.json|sw\.js|cloud-config\.json)$/.test(url.pathname)||url.pathname.startsWith('/api/'))){event.respondWith(fetch(event.request,{cache:'no-store'}));return;}
 event.respondWith((async()=>{const cache=await caches.open(CACHE);try{const response=await fetch(event.request,event.request.mode==='navigate'?{cache:'no-store'}:undefined);if(response.ok)await cache.put(event.request,response.clone());return response;}catch(error){const saved=await cache.match(event.request);if(saved)return saved;if(event.request.mode==='navigate'){const shell=await cache.match('./index.html');if(shell)return shell;}throw error;}})());
});
