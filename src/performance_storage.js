// SPDX-License-Identifier: AGPL-3.0-only
/* Compact local persistence. Legacy keys remain untouched for recovery. */
let performanceBoot=null,performanceStorageBlocked=false;
const performanceKey='legendfolio-compact-studio-v1',performanceArtwork=new WeakMap(),performanceStyles=new WeakMap();
function performanceRead(key){return new Promise((resolve,reject)=>{const q=db.transaction('records').objectStore('records').get(key);q.onsuccess=()=>resolve(q.result);q.onerror=()=>reject(q.error);});}
async function performanceBootstrap(){
 try{db=await new Promise((resolve,reject)=>{const q=indexedDB.open(seed.storageName||'strixhaven-living-record',1);q.onupgradeneeded=()=>q.result.createObjectStore('records');q.onsuccess=()=>resolve(q.result);q.onerror=()=>reject(q.error);});
 const packed=await performanceRead(performanceKey);
 if(packed){performanceBoot=LegendfolioPerformance.unpack(packed);if(!performanceBoot?.library||performanceBoot.library.version!==1)throw Error('Compact campaign library is invalid.');return;}
 // A library contains the active record, history and DM state; loading "current" as well duplicates all of it.
 const library=await performanceRead('campaign-library');if(library){performanceBoot={library,legacy:true};$('save-state').textContent='Optimising saved records…';await LegendfolioPerformance.canonicalise(library);return;}
 const saved=await performanceRead('current');if(saved?.record?.savedAt>model.savedAt){await LegendfolioPerformance.canonicalise(saved);model=validRecord(saved.record);undo=saved.undo||[];redo=saved.redo||[];}
 const recovered=await performanceRead('recovery');if(Array.isArray(recovered)){await LegendfolioPerformance.canonicalise(recovered);recoveryRecords=recovered;}
 }catch(error){performanceStorageBlocked=true;db=null;$('save-state').textContent='Saved records could not be loaded. Storage is paused; original saves are retained.';}
}
function performanceCapture(){
 if(!campaignLibrary)return;const c=CampaignLibrary.campaign(campaignLibrary),r=CampaignLibrary.character(campaignLibrary);if(!c)return;
 if(r)r.snapshot={record:model,undo,redo,recovery:recoveryRecords};c.dm={state:dmState,undo:dmUndo};
}
function performanceBundle(){return {library:campaignLibrary,player:campaignLibrary?null:{record:model,undo,redo,recovery:recoveryRecords},dm:campaignLibrary?null:{state:dmState,undo:dmUndo}};}
const performanceWriter=LegendfolioPerformance.writer(async()=>{
 if(!db||performanceStorageBlocked)throw Error('Browser storage unavailable. Export a backup.');
 const packed=LegendfolioPerformance.pack(performanceBundle());
 await new Promise((resolve,reject)=>{const tx=db.transaction('records','readwrite');tx.objectStore('records').put(packed,performanceKey);tx.oncomplete=resolve;tx.onerror=()=>reject(tx.error);tx.onabort=()=>reject(tx.error||Error('Local save aborted.'));});
 $('save-state').textContent=(performanceWriter.state().dirty?'Changes pending · ':'Saved locally · ')+new Date().toLocaleTimeString([],{hour:'2-digit',minute:'2-digit'});
});
async function performancePersist(paint=true){model.savedAt=Date.now();if(paint)refresh();performanceCapture();if(!db){$('save-state').textContent='Browser storage unavailable · export a backup.';return false;}try{$('save-state').textContent='Saving locally…';await performanceWriter.schedule();return true;}catch(error){$('save-state').textContent='Local save failed · export a backup.';return false;}}
async function performanceSaveLibrary(capture=true){if(capture)performanceCapture();if(!db)throw Error('Browser storage unavailable. Export a backup.');await performanceWriter.schedule(true);}
async function performanceLoadLibrary(){
 if(performanceBoot?.library){campaignLibrary=CampaignLibrary.validate(performanceBoot.library,validRecord);restoreCampaignSelection();const migrate=performanceBoot.legacy;performanceBoot=null;if(migrate)await performanceSaveLibrary();return;}
 campaignLibrary=CampaignLibrary.migrate(playerSnapshot(),{state:dmState,undo:dmUndo});if(db)await performanceSaveLibrary();
}
async function performanceLoadDM(){if(performanceBoot?.library){const c=CampaignLibrary.campaign(performanceBoot.library);if(c?.dm){dmState=DMCore.ensure(c.dm.state);dmUndo=c.dm.undo||[];}return;}if(!db)return;try{const saved=await performanceRead('dm-state');if(saved?.state){dmState=DMCore.ensure(saved.state);dmUndo=saved.undo||[];}}catch{}}
function performancePortrait(node,source){if(!node||performanceArtwork.get(node)===source)return;performanceArtwork.set(node,source);let art;if(source){art=document.createElement('img');art.src=source;art.alt='Character portrait';art.decoding='async';}else{art=document.createElement('div');art.className='placeholder';art.textContent='✧';}const button=document.createElement('button');button.type='button';button.className='ui-portrait-edit';button.dataset.uploadArt='portrait';button.setAttribute('aria-label',(source?'Change':'Upload')+' portrait');button.title=(source?'Change':'Upload')+' portrait';button.innerHTML='<span aria-hidden="true"><svg viewBox="0 0 24 24"><path d="M4 6h4l2-3h4l2 3h4v14H4Z"/><circle cx="12" cy="13" r="4"/></svg></span>';node.replaceChildren(art,button);}
function performanceBackground(node,property,source){if(!node)return;let map=performanceStyles.get(node);if(!map){map=new Map();performanceStyles.set(node,map);}if(map.get(property)===source)return;map.set(property,source);node.style.setProperty(property,source?'url("'+source+'")':'none');}
