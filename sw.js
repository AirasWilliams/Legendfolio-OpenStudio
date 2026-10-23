// SPDX-License-Identifier: AGPL-3.0-only
/* Bounded, lazy offline cache. Never cache authenticated APIs or private map assets. */
const CACHE='legendfolio-release-953d3f27b763ec9d4d6437cbf0992f28037cb124639fdfa0be54ac92ba9c9e7b';
const BASE=new URL('./',self.location.href),ENTRY=new URL('index.html',BASE).href;
const SHELL=['index.html','manifest.webmanifest','legendfolio-favicon-v2.svg','legendfolio-icon-v2-192.png','legendfolio-icon-v2-512.png'];
let writes=0;
function publicAsset(url){
 if(url.origin===BASE.origin){const relative=url.pathname.slice(BASE.pathname.length);return url.pathname.startsWith(BASE.pathname)&&(/^(?:portraits\/[a-zA-Z0-9_-]+\.webp|portraits\/catalog\.json|rules\/[a-zA-Z0-9_-]+\.(?:pdf|json)|vendor\/[a-zA-Z0-9_.-]+\.(?:js|mjs)|(?:legendfolio-)?(?:favicon[^/]*\.(?:svg|ico)|icon[^/]*\.png)|manifest\.webmanifest)$/.test(relative));}
 return url.origin==='https://cdnjs.cloudflare.com'&&url.pathname.startsWith('/ajax/libs/pdf.js/4.10.38/')&&/\.(mjs|js)$/.test(url.pathname);
}
function cacheKey(url){const key=new URL(url.href);key.search='';key.hash='';return key.href;}
function storeLater(event,cache,key,response){
 if(!response.ok||response.type==='opaque'||writes>=2||Number(response.headers.get('content-length')||0)>20*1024*1024)return;
 writes++;const copy=response.clone();event.waitUntil(cache.put(key,copy).catch(()=>{}).finally(()=>{writes--;}));
}
self.addEventListener('install',event=>event.waitUntil((async()=>{
 const cache=await caches.open(CACHE);
 // Two small worker lanes, no eager portrait library or rulebook downloads.
 let next=0;async function lane(){while(next<SHELL.length){const path=SHELL[next++],url=new URL(path,BASE);const response=await fetch(url.href,{cache:'reload'});if(!response.ok)throw Error('Shell unavailable');await cache.put(url.href,response);}}
 await Promise.all([lane(),lane()]);await self.skipWaiting();
})()));
self.addEventListener('message',event=>{if(event.data?.type==='ACTIVATE_UPDATE')self.skipWaiting();});
self.addEventListener('activate',event=>event.waitUntil((async()=>{
 for(const key of await caches.keys())if(key!==CACHE&&(key.startsWith('legendfolio-release-')||key.startsWith('strixhaven-shell-')||key.startsWith('ttrpg-')))await caches.delete(key);
 await self.clients.claim();
})()));
self.addEventListener('fetch',event=>{
 const request=event.request;if(request.method!=='GET')return;const url=new URL(request.url),local=url.origin===BASE.origin;
 if(local&&(/\/(?:release\.json|sw\.js|cloud-config\.json)$/.test(url.pathname)||url.pathname.startsWith(BASE.pathname+'api/'))){event.respondWith(fetch(request,{cache:'no-store'}));return;}
 const html=local&&(url.pathname===BASE.pathname||url.pathname===new URL('index.html',BASE).pathname);
 if(request.mode==='navigate'&&html){event.respondWith((async()=>{const cache=await caches.open(CACHE);try{const response=await fetch(request,{cache:'no-store'});if(response.ok)storeLater(event,cache,ENTRY,response);return response;}catch(error){const saved=await cache.match(ENTRY);if(saved)return saved;throw error;}})());return;}
 // An update probe must verify server HTML, not an old cached document.
 if(html){event.respondWith(fetch(request,{cache:'no-store'}));return;}
 if(!publicAsset(url))return;
 event.respondWith((async()=>{const cache=await caches.open(CACHE),key=cacheKey(url),saved=await cache.match(key);if(saved)return saved;const response=await fetch(request);storeLater(event,cache,key,response);return response;})());
});
