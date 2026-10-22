/* Presentation tokens only. Campaign authority remains in authenticated backend workflows. */
const LegendfolioPresentation=(()=>{
 function rgb(hex){return hex.replace('#','').match(/../g).map(v=>parseInt(v,16));}
 function luminance(hex){return rgb(hex).map(v=>{v/=255;return v<=.04045?v/12.92:((v+.055)/1.055)**2.4;}).reduce((s,v,i)=>s+v*[.2126,.7152,.0722][i],0);}
 function contrast(a,b){const x=luminance(a),y=luminance(b);return (Math.max(x,y)+.05)/(Math.min(x,y)+.05);}
 function readable(accent,background){let value=rgb(accent),hex=accent;const light=luminance(background)>.5;for(let i=0;i<80&&contrast(hex,background)<4.8;i++){value=value.map(v=>Math.round(light?v*.94:v+(255-v)*.07));hex='#'+value.map(v=>v.toString(16).padStart(2,'0')).join('');}return hex;}
 function tokens(accent,dark){const background=dark?'#1c232d':'#e5e9ef',ink=readable(accent,background);return{ink,fill:accent,onFill:contrast(accent,'#101820')>=contrast(accent,'#ffffff')?'#101820':'#ffffff',rgb:rgb(ink).join(',')};}
 return{contrast,tokens};
})();
function studioPresentationRefresh(){
 if(typeof launchHasDOM==='function'&&!launchHasDOM())return;
 if(typeof document==='undefined'||!document.documentElement?.style||typeof LaunchPreferences==='undefined')return;
 const t=LegendfolioPresentation.tokens(LaunchPreferences.accent(launchPreferences),document.documentElement.dataset?.theme==='dark'),style=document.documentElement.style;
 for(const [name,value] of Object.entries({'--house':t.ink,'--house-rgb':t.rgb,'--accent':t.ink,'--studio-accent-fill':t.fill,'--studio-accent-ink':t.onFill}))style.setProperty(name,value);
 const campaign=$('open-campaigns');if(campaign){campaign.title=campaign.textContent.trim();campaign.setAttribute('aria-label',campaign.title);}
 document.querySelectorAll('.studio-tabs button,.studio-tabs .ui-nav-document').forEach(b=>{if(!b.title)b.title=b.textContent.trim();});
 const save=document.querySelector('.toolbar [data-ui-command="save-character"]');if(save)save.hidden=appRole==='DM';
}
const studioPreviousPreferences=launchApplyPreferences;
launchApplyPreferences=function(...args){const result=studioPreviousPreferences(...args);studioPresentationRefresh();return result;};
const studioPreviousModernRefresh=modernRefresh;
modernRefresh=function(...args){const result=studioPreviousModernRefresh(...args);studioPresentationRefresh();return result;};
if(typeof module!=='undefined')module.exports=LegendfolioPresentation;

if(typeof paintCampaignLauncher==='function'){
 const studioPreviousCampaignLauncher=paintCampaignLauncher;
 paintCampaignLauncher=function(...args){const result=studioPreviousCampaignLauncher(...args);if(appRole==='DM'&&launchHasDOM()){const region=$('campaign-launcher-content');region?.querySelectorAll('details.launcher-tools').forEach(details=>{if(details.querySelector('summary')?.textContent.trim()==='Create campaign'){const button=document.createElement('button');button.type='button';button.className='button primary';button.dataset.openCampaignBuilder='';button.textContent='Create campaign';details.replaceWith(button);}});}return result;};
}

const studioPreviousAbout=uiAbout;
uiAbout=function(...args){const result=studioPreviousAbout(...args);const content=$('modal-content');if(content?.insertAdjacentHTML)content.insertAdjacentHTML('beforeend','<section class="control-tools-section"><h3>Build 57 · Campaign Studio</h3><p>A focused DM workspace, guided campaign setup, clearer approval states and consistent colour presets across your devices.</p><p>Existing characters, portraits and campaign approvals stay with their owners.</p></section>');return result;};
