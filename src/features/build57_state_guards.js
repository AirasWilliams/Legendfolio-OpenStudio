/* Approval determines shared-gameplay eligibility; the review panel still shows pending requests. */
const build57OriginalLivePartyContext=livePartyContext;
livePartyContext=function(){
 const context=build57OriginalLivePartyContext();
 if(!context||appRole!=='Player')return context;
 const requests=campaignDashboardRequests(campaignDashboardCurrent()?.data);
 return requests.some(request=>request.campaign_id===context.campaign&&request.status==='approved')?context:null;
};
function build57PendingCampaign(){
 if(appRole!=='Player'||!cloudStore?.user)return null;
 const data=campaignDashboardCurrent()?.data;if(!data)return null;
 const selected=campaignDashboardSelection(data,'Player');
 return campaignDashboardRequests(data).find(request=>request.campaign_id===selected&&request.status==='pending')||null;
}
function build57WaitingCampaignMarkup(){
 const request=build57PendingCampaign();if(!request)return '';const hasApproved=campaignDashboardRequests(campaignDashboardCurrent()?.data).some(row=>row.status==='approved');
 return `<section class="connection-panel build57-campaign-waiting" role="status"><div class="connection-heading"><span class="connection-tag">Awaiting DM approval</span><strong>${esc(request.campaign||'Campaign joining request')}</strong></div><p>Your character has been submitted. Shared encounters and party status become available after your DM approves it. You can keep using your personal character tools.</p>${hasApproved?livePartyChoiceMarkup():''}<button type="button" class="button" data-dashboard-manage>View joining request</button></section>`;
}
const build57OriginalLivePartyMarkup=livePartyMarkup;
livePartyMarkup=function(kind){return build57PendingCampaign()?(kind==='indicator'?'':build57WaitingCampaignMarkup()):build57OriginalLivePartyMarkup(kind);};
const build57OriginalEncounterMarkup=encounterMarkup;
encounterMarkup=function(){return build57PendingCampaign()?build57WaitingCampaignMarkup():build57OriginalEncounterMarkup();};
