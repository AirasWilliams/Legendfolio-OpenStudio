// SPDX-License-Identifier: AGPL-3.0-only
/* Synthetic benchmark: does not measure the installed browser's working set. */
import {createRequire} from 'node:module';import {performance} from 'node:perf_hooks';
const require=createRequire(import.meta.url),Core=require('../src/performance_core.js');
const image='data:image/webp;base64,'+'p'.repeat(256*1024),record={fields:Object.fromEntries(Array.from({length:30},(_,i)=>['Field'+i,'Text '+i])),art:{portrait:image},notes:{story:'Test character'}};
const source={record,undo:Array.from({length:70},(_,i)=>({...record,fields:{...record.fields,revision:i}})),redo:[],recovery:[]};
function baseline(){const player={record:structuredClone(source.record),undo:structuredClone(source.undo),redo:[],recovery:[]},library={campaigns:[{snapshot:structuredClone(player)}]};return structuredClone({current:source,library});}
function compact(){const snapshot=Core.clone(source),library={campaigns:[{snapshot}]};return structuredClone(Core.pack({library}));}
function timing(fn){const start=performance.now();let result;for(let i=0;i<5;i++)result=fn();return {ms:Math.round((performance.now()-start)*10)/10,bytes:Buffer.byteLength(JSON.stringify(result))};}
const before=timing(baseline),after=timing(compact);
console.log(JSON.stringify({scope:'Synthetic Node workload, 70 undo states, one repeated 256 KiB portrait; NOT measured browser RAM',iterations:5,baseline:before,compact:after,payloadReductionPercent:Math.round((1-after.bytes/before.bytes)*10000)/100,ratio:Math.round(before.ms/after.ms*10)/10},null,2));
