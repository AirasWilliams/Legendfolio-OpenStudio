// SPDX-License-Identifier: AGPL-3.0-only
// Package the tested, default-disabled application together with its preferred source and notices.
import fs from 'node:fs';import path from 'node:path';import crypto from 'node:crypto';import {fileURLToPath} from 'node:url';import {sourceArchive} from './source-archive.mjs';
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');
const release=JSON.parse(fs.readFileSync(path.join(root,'release.json'),'utf8'));
if(!/^\d+(?:\.\d+)*$/.test(release.version))throw Error('Invalid release version.');
if(JSON.parse(fs.readFileSync(path.join(root,'cloud-config.json'),'utf8')).enabled!==false)throw Error('Public distribution requires disabled backend defaults.');
const names=[],zip=fs.readFileSync(path.join(root,'legendfolio-source.zip'));let at=0;
while(zip.readUInt32LE(at)===0x04034b50){const compressed=zip.readUInt32LE(at+18),length=zip.readUInt16LE(at+26),extra=zip.readUInt16LE(at+28),name=zip.subarray(at+30,at+30+length).toString('utf8');const resolved=path.resolve(root,name);if(name.includes('\\')||name.startsWith('/')||!resolved.startsWith(root+path.sep)||!fs.statSync(resolved).isFile())throw Error('Unsafe source archive path.');names.push(name);at+=30+length+extra+compressed;}
const files=[...new Set([...names,'index.html','sw.js','manifest.webmanifest','release.json','legendfolio-source.zip'])].sort();
const output=path.join(root,'artifacts');fs.mkdirSync(output,{recursive:true});const filename='Legendfolio_Open_Studio_Public_Build'+release.version+'.zip',bytes=sourceArchive(root,files);fs.writeFileSync(path.join(output,filename),bytes);const sha=crypto.createHash('sha256').update(bytes).digest('hex');fs.writeFileSync(path.join(output,filename+'.sha256'),sha+'  '+filename+'\n');console.log(JSON.stringify({file:'artifacts/'+filename,sha256:sha,files:files.length,bytes:bytes.length,release}));
