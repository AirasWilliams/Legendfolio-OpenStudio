// SPDX-License-Identifier: AGPL-3.0-only
import fs from 'node:fs';import path from 'node:path';import crypto from 'node:crypto';import {fileURLToPath} from 'node:url';import {createRequire} from 'node:module';import {sourceArchive} from './source-archive.mjs';
const require=createRequire(import.meta.url),Config=require('../src/backend_config.js');
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..'),read=p=>fs.readFileSync(path.join(root,p),'utf8').replace(/\r\n?/g,'\n'),json=p=>JSON.parse(read(p));
const name=process.argv.find(x=>x.startsWith('--out='))?.slice(6)||'dist';
if(!/^dist(?:-[a-z0-9-]+)?$/.test(name))throw Error('Build output must be dist or a dist-name folder inside the project.');
const dest=path.resolve(root,name);if(!dest.startsWith(root+path.sep)||dest===root)throw Error('Unsafe output path.');
const config=Config.fromEnvironment(json('cloud-config.json'),process.env),manifest=json('src/build-manifest.json');
function walk(relative){const p=path.join(root,relative);if(!fs.existsSync(p))return [];if(fs.lstatSync(p).isSymbolicLink())throw Error('Source symlinks are not supported.');if(fs.statSync(p).isFile())return [relative];return fs.readdirSync(p).sort().flatMap(x=>walk(path.join(relative,x)));}
const sourceRoots=['src','scripts','tests','supabase/migrations','vendor','portraits','rules','docs','licenses','.github'];
const sourceFiles=[...sourceRoots.flatMap(walk),...['README.md','CONTRIBUTING.md','SECURITY.md','LICENSE','LICENSES.md','BRANDING.md','CHANGELOG.md','package.json','.gitignore','.env.example','cloud-config.json','cloud-config.example.json','cloud_core.js','vercel.json','server.py','Start Legendfolio.cmd','Start Legendfolio.ps1','favicon.svg','favicon.ico','legendfolio-favicon-v2.svg','icon-192.png','icon-512.png','legendfolio-icon-v2-192.png','legendfolio-icon-v2-512.png'].flatMap(walk)].sort();
sourceFiles.push('.gitattributes');sourceFiles.sort();
if(sourceFiles.some(p=>/(^|[/\\])(\.env$|node_modules|dist|\.git)([/\\]|$)/.test(p)))throw Error('Unexpected private/generated source input.');
const fingerprint=crypto.createHash('sha256');for(const p of sourceFiles){fingerprint.update(p.replaceAll(path.sep,'/'));fingerprint.update('\0');fingerprint.update(fs.readFileSync(path.join(root,p)));fingerprint.update('\0');}fingerprint.update(JSON.stringify(config));const id=fingerprint.digest('hex');
const release={schema:1,version:manifest.version,id};
const catalog=json('portraits/catalog.json'),seed={...json('src/data/seed.json'),rulesLibrary:json('src/data/rules-library.json')};
if(seed.record.loaded||Object.keys(seed.record.fields).length||Object.keys(seed.record.art).length||seed.environment)throw Error('The public seed must be blank and contain no private backdrop.');
let features=manifest.features.map(read).join('\n').replaceAll('__PORTRAIT_CATALOG__',JSON.stringify(catalog)).replaceAll('__LEGENDFOLIO_RELEASE_ID__',id);
let app=read('src/app.js');if(app.split('/*__PUBLIC_FEATURE_MODULES__*/').length!==2)throw Error('Feature insertion marker missing or duplicated.');app=app.replace('/*__PUBLIC_FEATURE_MODULES__*/',()=>features);
let html=read('src/index.template.html');for(const [marker,files]of Object.entries(manifest.placeholders))html=html.split(marker).join(files.map(read).join('\n'));
html=html.replace('__SCRIPT__',()=>app).replace('__DATA__',()=>JSON.stringify(seed).replaceAll('<','\\u003c'));
if(/__[A-Z0-9_]+__/.test(html))throw Error('Unresolved source placeholder.');
const hashes=[...html.matchAll(/<script\b[^>]*>([\s\S]*?)<\/script>/g)].map(m=>"'sha256-"+crypto.createHash('sha256').update(m[1]).digest('base64')+"'");
const connect=["'self'",'https://cdnjs.cloudflare.com',...(config.enabled?[new URL(config.supabaseUrl).origin]:[])];
const csp="default-src 'self'; script-src 'self' "+hashes.join(' ')+" https://cdnjs.cloudflare.com; style-src 'self' 'unsafe-inline'; img-src 'self' data: blob: https:; connect-src "+connect.join(' ')+"; worker-src 'self' blob: https://cdnjs.cloudflare.com; base-uri 'self'; object-src 'none'; form-action 'self'";
html=html.replace('<meta charset="UTF-8">','<meta charset="UTF-8"><meta http-equiv="Content-Security-Policy" content="'+csp.replaceAll('&','&amp;').replaceAll('"','&quot;')+'">');
const assets=walk('portraits').filter(p=>/\.(webp|json)$/i.test(p)).map(p=>'./'+p.replaceAll(path.sep,'/'));
const sw=read('src/service-worker.js').replaceAll('__RELEASE_ID__',id).replaceAll('__PORTRAIT_ASSETS__',JSON.stringify(assets));
const pwa={id:'./',name:'Legendfolio Open Studio',short_name:'Legendfolio',start_url:'./index.html',scope:'./',display:'standalone',background_color:'#111b19',theme_color:'#203e35',icons:[192,512].map(n=>({src:`legendfolio-icon-v2-${n}.png`,sizes:`${n}x${n}`,type:'image/png',purpose:'any maskable'}))};
// This path has been resolved and constrained above to a generated dist[-name] folder.
fs.rmSync(dest,{recursive:true,force:true});fs.mkdirSync(dest,{recursive:true});
const copy=(from,to)=>{fs.mkdirSync(path.dirname(to),{recursive:true});fs.copyFileSync(path.join(root,from),to);};
for(const p of [...['rules','portraits','vendor','docs','licenses'].flatMap(walk),...['README.md','CONTRIBUTING.md','SECURITY.md','LICENSE','LICENSES.md','BRANDING.md','CHANGELOG.md','favicon.svg','favicon.ico','legendfolio-favicon-v2.svg','icon-192.png','icon-512.png','legendfolio-icon-v2-192.png','legendfolio-icon-v2-512.png'].flatMap(walk)])copy(p,path.join(dest,p));
const generated={'index.html':html,'release.json':JSON.stringify(release,null,2),'manifest.webmanifest':JSON.stringify(pwa,null,2),'sw.js':sw};
for(const [p,data]of Object.entries(generated)){fs.writeFileSync(path.join(dest,p),data);if(name==='dist')fs.writeFileSync(path.join(root,p),data);}
fs.writeFileSync(path.join(dest,'cloud-config.json'),JSON.stringify(config,null,2));
const archive=sourceArchive(root,sourceFiles);fs.writeFileSync(path.join(dest,'legendfolio-source.zip'),archive);if(name==='dist')fs.writeFileSync(path.join(root,'legendfolio-source.zip'),archive);
fs.writeFileSync(path.join(dest,'_headers'),`/*\n  X-Content-Type-Options: nosniff\n  Referrer-Policy: strict-origin-when-cross-origin\n  X-Frame-Options: DENY\n  Content-Security-Policy: frame-ancestors 'none'; object-src 'none'; base-uri 'self'\n/index.html\n  Cache-Control: no-cache\n/sw.js\n  Cache-Control: no-store\n/release.json\n  Cache-Control: no-store\n/cloud-config.json\n  Cache-Control: no-store\n`);
console.log('Build '+manifest.version+' ready in '+name+'; online '+(config.enabled?'configured for the supplied instance':'disabled by default')+'. Source archive and matching CSP generated.');
