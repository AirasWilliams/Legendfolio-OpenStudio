// SPDX-License-Identifier: AGPL-3.0-only
import fs from 'node:fs';
import path from 'node:path';
export function performanceBuild(original,root){
 const read=p=>fs.readFileSync(path.join(root,p),'utf8').replace(/^\uFEFF/,'').replace(/\r\n?/g,'\n');
 // Replace only executable inline JavaScript, never the embedded JSON or imported vendor code.
 let html=original.replace(/<script\b([^>]*)>([\s\S]*?)<\/script>/g,(all,attrs,code)=>{
  if(/\bsrc\s*=|\btype\s*=\s*["']application\/json/i.test(attrs))return all;
  return '<script'+attrs+'>'+code.replace(/(?<![\w.$])structuredClone\(/g,'LegendfolioPerformance.clone(')+'</script>';
 });
 function line(start,replacement){const lines=html.split('\n'),matches=lines.map((s,i)=>s.startsWith(start)?i:-1).filter(i=>i>=0);if(matches.length!==1)throw Error('Performance assembly contract changed: '+start);lines[matches[0]]=replacement;html=lines.join('\n');}
 line('try{db=await new Promise',read('src/performance_storage.js')+'\nawait performanceBootstrap();');
 line('async function persist(){','async function persist(paint=true){return performancePersist(paint);}');
 line('async function persistDM(){',"async function persistDM(){performanceCapture();if(!db){notify('Browser storage unavailable. Export a DM backup.');return false;}try{await performanceWriter.schedule();return true;}catch(error){notify('DM save failed. Export a backup to keep this state.');return false;}}");
 line('function captureCampaigns(){','function captureCampaigns(){performanceCapture();}');
 line('async function saveCampaignLibrary(){','async function saveCampaignLibrary(){return performanceSaveLibrary(true);}');
 // Selection is committed BEFORE globals are restored. Capturing here would overwrite the destination character.
 line('async function saveCampaignLibrarySelection(){','async function saveCampaignLibrarySelection(){return performanceSaveLibrary(false);}');
 line('async function switchCampaign(cid,rid,role=appRole){',"async function switchCampaign(cid,rid,role=appRole){if(busy)throw Error('Finish or cancel the current upload first.');captureLegacy();captureCampaigns();await performanceWriter.flush();const previous={campaign:campaignLibrary.activeCampaign,character:campaignLibrary.activeCharacter};CampaignLibrary.select(campaignLibrary,cid,rid);try{await saveCampaignLibrarySelection();}catch(error){campaignLibrary.activeCampaign=previous.campaign;campaignLibrary.activeCharacter=previous.character;throw error;}restoreCampaignSelection();setRole(role,{savePrevious:false});$('campaign-launcher').close();campaignHeader();await persist(false);}");
 line('async function loadDMState(){','async function loadDMState(){return performanceLoadDM();}');
 line('async function loadCampaignLibrary(){','async function loadCampaignLibrary(){return performanceLoadLibrary();}');
 line("if($('hero-art'))$('hero-art').innerHTML=", "performancePortrait($('hero-art'),model.art.portrait||'');");
 line("if($('hero-backdrop'))$('hero-backdrop').style.backgroundImage=", "performanceBackground($('hero-backdrop'),'background-image',model.art.banner||seed.environment||'');");
 line("document.documentElement.style.setProperty('--campus-art',", "performanceBackground(document.documentElement,'--campus-art',seed.environment||'');");
 const commit='if(rerender){last=null;render()}persist()';if(html.split(commit).length!==2)throw Error('Commit rendering contract changed.');html=html.replace(commit,'if(rerender){last=null;render()}persist(!rerender)');
 // This helper is installed before any module that uses it; its native fallback is intentionally not rewritten.
 html=html.replace(/<script\b/,'<script>\n'+read('src/performance_core.js')+'\n</script><script');
 return html;
}
