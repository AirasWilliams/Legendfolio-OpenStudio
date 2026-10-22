const CampaignLibrary=(()=>{
 const copy=x=>structuredClone(x),id=()=>Date.now().toString(36)+'-'+Math.random().toString(36).slice(2,10);
 function fresh(){return{version:1,campaigns:[],activeCampaign:'',activeCharacter:''};}
 function campaign(lib,key=lib.activeCampaign){return lib.campaigns.find(c=>c.id===key);}
 function character(lib,key=lib.activeCharacter,cid=lib.activeCampaign){return campaign(lib,cid)?.characters.find(c=>c.id===key);}
 function addCampaign(lib,name,mode='General'){if(!String(name).trim())throw Error('Give your campaign a name.');const c={id:id(),name:String(name).trim(),mode:mode==='Strixhaven'?'Strixhaven':'General',characters:[],dm:{state:{calendar:{elapsedDays:0},combatants:[]},undo:[]}};lib.campaigns.push(c);return c;}
 function addCharacter(lib,cid,snapshot,sourceId){const c=campaign(lib,cid);if(!c)throw Error('Choose a campaign.');const r={id:id(),originId:sourceId||id(),snapshot:copy(snapshot)};c.characters.push(r);return r;}
 function capture(lib,snapshot,dm){const c=campaign(lib);if(!c)return;const r=character(lib);if(r&&snapshot)r.snapshot=copy(snapshot);if(dm)c.dm=copy(dm);}
 function select(lib,cid,rid){const c=campaign(lib,cid);if(!c)throw Error('Campaign not found.');if(rid&&!c.characters.some(r=>r.id===rid))throw Error('Character not found in this campaign.');lib.activeCampaign=cid;lib.activeCharacter=rid||c.characters[0]?.id||'';return{campaign:c,character:character(lib),dm:copy(c.dm)};}
 function migrate(snapshot,dm){const lib=fresh(),name=snapshot.record.campaign?.name||'My campaign';const c=addCampaign(lib,name,snapshot.record.campaign?.mode);c.dm=copy(dm);const r=addCharacter(lib,c.id,snapshot);select(lib,c.id,r.id);return lib;}
 function validate(lib,check){if(!lib||lib.version!==1||!Array.isArray(lib.campaigns)||!lib.campaigns.length)throw Error('Choose a Studio campaigns backup.');const ids=new Set();for(const c of lib.campaigns){if(!c||typeof c.id!=='string'||ids.has(c.id)||typeof c.name!=='string'||!Array.isArray(c.characters)||!c.dm?.state||!Array.isArray(c.dm.state.combatants))throw Error('Invalid campaign backup.');ids.add(c.id);const members=new Set();for(const r of c.characters){if(typeof r.id!=='string'||members.has(r.id)||!r.snapshot)throw Error('Invalid character entry.');members.add(r.id);check(r.snapshot.record);for(const old of [...(r.snapshot.undo||[]),...(r.snapshot.redo||[])])check(old);for(const old of r.snapshot.recovery||[])check(old.record);}}select(lib,lib.activeCampaign,lib.activeCharacter);return lib;}
 return{fresh,campaign,character,addCampaign,addCharacter,capture,select,migrate,validate};
})();
if(typeof module!=='undefined')module.exports=CampaignLibrary;
