/* Character identity is a projection of the current sheet; never an approval or gameplay write. */
const CharacterPanel=(()=>{
 function project(record={}){
  const fields=record.fields||{},text=k=>String(fields[k]||'').trim(),campus=record.campaign?.mode==='Strixhaven',college=String(record.college||'').trim(),background=text('Background');
  return{className:text('ClassLevel'),player:text('PlayerName'),kicker:background?(campus&&college&&!background.toLowerCase().includes(college.toLowerCase())?college+' · '+background:background):(campus&&college?college+' student':'Character overview'),origin:[text('Race '),text('Alignment')].filter(Boolean),campaign:String(record.campaign?.name||'').trim(),session:record.campaign?.session?'Session '+String(record.campaign.session):'',ideal:text('Ideals').replace(/\s+/g,' ')};
 }
 function fit(viewportHeight,top,otherHeight){const minimum=viewportHeight<850?180:210,available=Math.floor(viewportHeight-top-otherHeight-16);return{height:Math.max(minimum,Math.min(420,available)),flow:available<minimum};}
 return{project,fit};
})();
function characterPanelRefresh(){
 if(typeof modernHasDOM!=='function'||!modernHasDOM())return;
 document.querySelectorAll('.studio-tabs>button,.studio-tabs>.ui-nav-document').forEach(button=>{for(const node of [...button.childNodes])if(node.nodeType===3&&node.textContent.trim()){const label=document.createElement('span');label.className='character-nav-label';label.textContent=node.textContent.trim();node.replaceWith(label);}});
 if(appRole!=='Player')return;
 const hero=document.querySelector('.ui-character-anchor>.hero');if(!hero)return;
 const toggle=$('device-profile-toggle'),anchor=hero.parentElement;if(toggle&&toggle.parentElement===hero)anchor.insertBefore(toggle,$('hero-scores'));
 if(toggle){toggle.setAttribute('aria-controls','hero-scores');toggle.setAttribute('aria-expanded',String(document.body.dataset.deviceProfileOpen==='true'));}
 let context=hero.querySelector('.character-profile-context');if(!context){context=document.createElement('div');context.className='character-profile-context';hero.appendChild(context);}
 const meta=$('hero-meta'),details=$('hero-details');if(meta&&meta.parentElement!==context)context.appendChild(meta);if(details&&details.parentElement!==context)context.appendChild(details);
 const p=CharacterPanel.project(model),subtitle=$('character-subtitle');
 if($('hero-kicker'))$('hero-kicker').textContent=p.kicker;
 if(subtitle){const html=`<span class="character-class">${esc(p.className||(model.loaded?'Class not recorded':'Create or import your character'))}</span>${p.player?`<span class="character-player">Played by ${esc(p.player)}</span>`:''}${approvedMarker(model)}`;if(subtitle.innerHTML!==html)subtitle.innerHTML=html;}
 if(meta){const html=`${p.origin.length?`<div class="character-origin-line">${p.origin.map(x=>`<span>${esc(x)}</span>`).join('')}</div>`:''}${p.campaign||p.session?`<div class="character-campaign-line">${p.campaign?`<span class="character-campaign-name" title="${esc(p.campaign)}">${esc(p.campaign)}</span>`:''}${p.session?`<span class="character-session">${esc(p.session)}</span>`:''}</div>`:''}`;if(meta.innerHTML!==html)meta.innerHTML=html;meta.hidden=!html;}
 if(details){details.hidden=!p.ideal;const html=p.ideal?`<div class="hero-quote">“${esc(p.ideal)}”</div>`:'';if(details.innerHTML!==html)details.innerHTML=html;}
 context.hidden=!p.origin.length&&!p.campaign&&!p.session&&!p.ideal;
 const portrait=$('hero-art');if(portrait&&window.innerWidth>=950){const remaining=anchor.getBoundingClientRect().height-portrait.getBoundingClientRect().height,top=(document.querySelector('.toolbar')?.offsetHeight||76)+18,fit=CharacterPanel.fit(window.innerHeight,top,remaining);const value=fit.height+'px';if(anchor.style.getPropertyValue('--character-portrait-height')!==value)anchor.style.setProperty('--character-portrait-height',value);anchor.classList.toggle('is-tall-profile',fit.flow);}else{anchor.style.removeProperty('--character-portrait-height');anchor.classList.remove('is-tall-profile');}
}
const characterPanelPreviousRefresh=modernRefresh;
modernRefresh=function(...args){const result=characterPanelPreviousRefresh(...args);characterPanelRefresh();return result;};
if(typeof module!=='undefined')module.exports=CharacterPanel;

const characterPanelPreviousAbout=uiAbout;
uiAbout=function(...args){const result=characterPanelPreviousAbout(...args);const content=$('modal-content');if(content?.insertAdjacentHTML)content.insertAdjacentHTML('afterbegin','<section class="control-tools-section"><h3>Build 58 · Character panel & interface review</h3><p>A clean portrait surface, aligned character identity, accessible mobile abilities and responsive profile sizing. Existing campaign and character data is unchanged.</p></section>');return result;};
