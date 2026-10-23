// SPDX-License-Identifier: AGPL-3.0-only
/* Immutable strings are shared; mutable metadata is always copied. */
const LegendfolioPerformance=(()=>{
 const nativeClone=globalThis.structuredClone;
 function clone(value,seen=new WeakMap()){
  if(value===null||typeof value!=='object')return value;
  if(seen.has(value))return seen.get(value);
  if(Array.isArray(value)){const out=[];seen.set(value,out);for(const v of value)out.push(clone(v,seen));return out;}
  if(Object.getPrototypeOf(value)!==Object.prototype&&Object.getPrototypeOf(value)!==null)return nativeClone(value);
  const out={};seen.set(value,out);for(const key of Object.keys(value))Object.defineProperty(out,key,{value:clone(value[key],seen),enumerable:true,writable:true,configurable:true});return out;
 }
 function pack(value){
  const strings=[],nodes=[],seen=new WeakMap(),intern=new Map();
  function encode(v){
   if(typeof v==='string'&&v.length>=32768){let id=intern.get(v);if(id===undefined){id=strings.length;strings.push(v);intern.set(v,id);}return ['s',id];}
   if(v===null||typeof v!=='object')return v;
   if(seen.has(v))return ['r',seen.get(v)];const id=nodes.length;seen.set(v,id);nodes.push(null);
   if(Array.isArray(v))nodes[id]={kind:'array',value:v.map(encode)};
   else if(Object.getPrototypeOf(v)===Object.prototype||Object.getPrototypeOf(v)===null)nodes[id]={kind:'object',value:Object.keys(v).map(k=>[k,encode(v[k])])};
   else nodes[id]={kind:'native',value:nativeClone(v)};
   return ['r',id];
  }
  const root=encode(value);return {legendfolioCompactStorage:1,root,nodes,strings};
 }
 function unpack(data){
  if(data?.legendfolioCompactStorage!==1||!Array.isArray(data.nodes)||!Array.isArray(data.strings)||data.strings.some(s=>typeof s!=='string'))throw Error('Saved compact record is invalid. Original saves have been retained.');
  const out=data.nodes.map(n=>{if(n?.kind==='array'&&Array.isArray(n.value))return [];if(n?.kind==='object'&&Array.isArray(n.value))return {};if(n?.kind==='native')return nativeClone(n.value);throw Error('Invalid saved node.');});
  function decode(v){if(!Array.isArray(v)){if(v!==null&&typeof v==='object')throw Error('Invalid saved value.');return v;}if(v.length!==2||!Number.isInteger(v[1])||v[1]<0)throw Error('Invalid saved reference.');if(v[0]==='s'&&v[1]<data.strings.length)return data.strings[v[1]];if(v[0]==='r'&&v[1]<out.length)return out[v[1]];throw Error('Missing saved reference.');}
  data.nodes.forEach((n,i)=>{if(n.kind==='array')for(const v of n.value)out[i].push(decode(v));else if(n.kind==='object')for(const entry of n.value){if(!Array.isArray(entry)||entry.length!==2||typeof entry[0]!=='string')throw Error('Invalid saved property.');Object.defineProperty(out[i],entry[0],{value:decode(entry[1]),enumerable:true,writable:true,configurable:true});}});
  return decode(data.root);
 }
 async function canonicalise(value,yieldTask=()=>new Promise(resolve=>setTimeout(resolve,0))){
  const stack=[value],seen=new WeakSet(),strings=new Map();let count=0;
  while(stack.length){const obj=stack.pop();if(!obj||typeof obj!=='object'||seen.has(obj))continue;seen.add(obj);
   if(Array.isArray(obj)||Object.getPrototypeOf(obj)===Object.prototype||Object.getPrototypeOf(obj)===null)for(const k of Object.keys(obj)){const v=obj[k];if(typeof v==='string'&&v.length>=32768){const old=strings.get(v);if(old===undefined)strings.set(v,v);else obj[k]=old;}else if(v&&typeof v==='object')stack.push(v);}
   if(++count%300===0)await yieldTask();
  }return value;
 }
 function writer(write,{delay=300,maxWait=1200,setTimer=setTimeout,clearTimer=clearTimeout}={}){
  let timer=null,deadline=null,running=null,dirty=false,version=0,saved=0,waiters=[];
  function settle(error,target){const done=waiters.filter(w=>w.target<=target);waiters=waiters.filter(w=>w.target>target);for(const w of done)error?w.reject(error):w.resolve();}
  function cancel(){if(timer!==null)clearTimer(timer);if(deadline!==null)clearTimer(deadline);timer=deadline=null;}
  function flush(){cancel();if(running)return running;if(!dirty)return Promise.resolve();
   running=Promise.resolve().then(async()=>{while(dirty){cancel();const target=version;dirty=false;try{await write();saved=target;settle(null,target);}catch(e){settle(e,version);dirty=false;cancel();throw e;}}}).finally(()=>{running=null;});
   return running;
  }
  function schedule(immediate=false){const target=++version;dirty=true;const p=new Promise((resolve,reject)=>waiters.push({target,resolve,reject}));if(timer!==null)clearTimer(timer);timer=setTimer(()=>flush().catch(()=>{}),immediate?0:delay);if(deadline===null)deadline=setTimer(()=>flush().catch(()=>{}),maxWait);return p;}
  return {schedule,flush,state:()=>({running:!!running,dirty,version,saved,waiting:waiters.length})};
 }
 return {clone,pack,unpack,canonicalise,writer};
})();
if(typeof module!=='undefined')module.exports=LegendfolioPerformance;
