/* Bundled artwork and personal uploads. No generation service or external image requests. */
const PortraitGallery=(()=>{
 const items=__PORTRAIT_CATALOG__;
 const ancestries=[...new Set(items.map(p=>p.ancestry))].sort();
 function list(ancestry){return ancestries.includes(ancestry)?items.filter(p=>p.ancestry===ancestry):items;}
 function selected(draft,q){return items.find(p=>p.id===q.portraitId)||list(draft.ancestry)[0];}
 function image(value){return typeof value==='string'&&value.length<=4000000&&/^data:image\/(?:png|jpeg|webp);base64,[A-Za-z0-9+/]+={0,2}$/.test(value)?value:'';}
 return {items,ancestries,list,selected,image};
})();
let portraitFilter='',portraitGender='All',portraitFilterAncestry='',portraitUploadBusy=false;
function qbPortrait(){return './portraits/'+PortraitGallery.selected(launchDraft,qbState()).file;}
function qbCurrentPortrait(){return PortraitGallery.image(qbState().portraitImage)||qbPortrait();}
function portraitGalleryMarkup(){
 const q=qbState(),selected=PortraitGallery.selected(launchDraft,q),uploaded=!!PortraitGallery.image(q.portraitImage);
 if(portraitFilterAncestry!==launchDraft.ancestry){portraitFilterAncestry=launchDraft.ancestry;portraitFilter=PortraitGallery.ancestries.includes(launchDraft.ancestry)?launchDraft.ancestry:'All';}
 const visible=PortraitGallery.list(portraitFilter).filter(p=>portraitGender==='All'||p.gender===portraitGender);
 return `<section class="portrait-studio" aria-label="Portrait gallery"><header><div><h3>Give your character a face</h3><p>Choose a portrait or upload your own artwork.</p></div><label class="portrait-upload button">Upload artwork<input type="file" accept="image/png,image/jpeg,image/webp" data-portrait-upload ${portraitUploadBusy?'disabled':''}></label></header><div class="portrait-toolbar"><label>Browse ancestry<select data-portrait-filter>${['All',...PortraitGallery.ancestries].map(a=>`<option ${a===portraitFilter?'selected':''}>${esc(a)}</option>`).join('')}</select></label><label>Presentation<select data-portrait-gender>${['All','Male','Female','Androgynous'].map(g=>`<option ${g===portraitGender?'selected':''}>${g}</option>`).join('')}</select></label><p role="status">${portraitUploadBusy?'Preparing artwork…':uploaded?'Your uploaded artwork is selected.':esc(selected.name)+' · '+selected.ancestry+' · '+selected.gender+' selected'} · ${visible.length} portraits</p>${uploaded?'<button class="button" type="button" data-portrait-gallery>Use gallery portrait</button>':''}</div>${uploaded?`<div class="portrait-upload-preview"><img src="${esc(q.portraitImage)}" alt="Your uploaded portrait"><p>Your artwork stays in this private draft. A portable copy is included when you save your character.</p></div>`:''}<div class="portrait-grid">${visible.map(p=>`<button type="button" data-portrait-id="${p.id}" aria-pressed="${!uploaded&&selected.id===p.id}" aria-label="Choose ${esc(p.name)} · ${p.ancestry} · ${p.gender}"><img src="./portraits/${p.file}" alt="${esc(p.description)}" loading="lazy" width="320" height="400"><span><strong>${esc(p.name)}</strong><small>${p.ancestry} · ${p.gender}</small></span>${!uploaded&&selected.id===p.id?'<i aria-hidden="true">✓</i>':''}</button>`).join('')}</div>${visible.length?'':'<p class="portrait-empty">No portraits match these filters. Choose another presentation or browse all ancestries.</p>'}<p class="hint">Artwork changes appearance only. Browse any ancestry without changing your character’s rules or choices. PNG, JPEG or WebP uploads, up to 15 MB.</p></section>`;
}
async function portraitPrepareUpload(blob){
 if(!['image/jpeg','image/png','image/webp'].includes(blob.type)||blob.size>15*1024*1024)throw Error('Choose a PNG, JPEG or WebP image smaller than 15 MB.');
 const image=await createImageBitmap(blob);
 try{
  if(image.width*image.height>25000000)throw Error('Choose artwork smaller than 25 megapixels.');
  const canvas=document.createElement('canvas');canvas.width=320;canvas.height=400;const context=canvas.getContext('2d');
  if(!context)throw Error('This browser could not prepare the portrait.');
  const scale=Math.max(320/image.width,400/image.height),w=image.width*scale,h=image.height*scale;
  context.fillStyle='#17232b';context.fillRect(0,0,320,400);context.drawImage(image,(320-w)/2,(400-h)/2,w,h);
  for(const quality of [.82,.65,.48,.3,.18]){const data=canvas.toDataURL('image/jpeg',quality);if(data.length<=52000)return data;}
  throw Error('This artwork could not fit the private builder draft. Try a smaller portrait.');
 }finally{image.close();}
}
document.addEventListener('click',e=>{
 const b=e.target.closest?.('[data-portrait-id],[data-portrait-gallery]');if(!b||portraitUploadBusy)return;
 const q=qbState();if(b.dataset.portraitId&&!PortraitGallery.items.some(p=>p.id===b.dataset.portraitId))return;
 if(b.dataset.portraitId)q.portraitId=b.dataset.portraitId;
 delete q.portraitImage;q.portraitSource='gallery';qbSave();launchPaint();
});
document.addEventListener('change',async e=>{
 if(e.target.hasAttribute?.('data-portrait-filter')){portraitFilter=e.target.value;launchPaint();return;}
 if(e.target.hasAttribute?.('data-portrait-gender')){portraitGender=e.target.value;launchPaint();return;}
 if(!e.target.hasAttribute?.('data-portrait-upload')||portraitUploadBusy)return;
 const file=e.target.files?.[0];if(!file)return;
 const draft=launchDraft,extra=builderExtra,q=qbState();portraitUploadBusy=true;e.target.disabled=true;
 try{const image=await portraitPrepareUpload(file);if(draft!==launchDraft||extra!==builderExtra)throw Error('The draft changed while preparing artwork. Choose your file again.');q.portraitImage=image;q.portraitSource='upload';qbSave();}
 catch(error){notify(error.message);}finally{portraitUploadBusy=false;if(launchScreen==='draft')launchPaint();}
});
if(typeof module!=='undefined')module.exports=PortraitGallery;

