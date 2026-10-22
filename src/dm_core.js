const DMCore=(()=>{
 const days=['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'];
 function ensure(s={}){s.calendar=s.calendar||{elapsedDays:0};s.calendar.elapsedDays=Math.max(0,Math.floor(Number(s.calendar.elapsedDays)||0));s.campaign=String(s.campaign||'My campaign');s.combat={round:1,activeId:'',running:false,order:[],...(s.combat||{})};s.combatants=Array.isArray(s.combatants)?s.combatants:[];if(typeof DMWorkspace!=='undefined')DMWorkspace.ensure(s);return s;}
 function date(s){ensure(s);const n=s.calendar.elapsedDays;return{day:days[n%7],dayIndex:n%7,dayOfMonth:n%28+1,week:Math.floor(n%28/7)+1,month:Math.floor(n/28)%12+1,year:Math.floor(n/336)+1,totalDays:n,totalWeeks:Math.floor(n/7),currentTotalWeek:Math.floor(n/7)+1};}
 function endDay(s){ensure(s);s.calendar.elapsedDays++;return date(s);}
 function setDate(s,year,month,week,day){const values=[year,month,week,day].map(Number);if(values.some(n=>!Number.isInteger(n))||year<1||month<1||month>12||week<1||week>4||day<0||day>6)throw Error('Use year 1+, month 1–12, week 1–4 and Monday–Sunday.');ensure(s);s.calendar.elapsedDays=(year-1)*336+(month-1)*28+(week-1)*7+day;return date(s);}
 function sorted(s){ensure(s);return s.combatants.map((r,i)=>({...r,index:i})).sort((a,b)=>b.initiative-a.initiative||a.index-b.index);}
 function start(s){ensure(s);if(!s.combatants.length)throw Error('Add at least one combatant.');const order=sorted(s).map(r=>r.id);s.combat.order=order;s.combat.activeId=s.combat.order[0];s.combat.round=1;s.combat.running=true;}
 function next(s){ensure(s);if(!s.combat.running)throw Error('Start the encounter first.');s.combat.order=s.combat.order.filter(id=>s.combatants.some(r=>r.id===id));if(!s.combat.order.length){s.combat.running=false;s.combat.activeId='';return;}const i=s.combat.order.indexOf(s.combat.activeId),j=(i+1)%s.combat.order.length;if(j===0)s.combat.round++;s.combat.activeId=s.combat.order[j];}
 function health(s,id,amount,kind){ensure(s);const r=s.combatants.find(r=>r.id===id);if(!r||!r.hpTracked)throw Error('Set this combatant’s maximum HP before tracking damage.');const n=Math.max(0,Math.floor(Number(amount)||0));if(kind==='damage'){const temp=Math.min(r.temp||0,n);r.temp=(r.temp||0)-temp;r.hp=Math.max(0,r.hp-(n-temp));}else if(kind==='heal')r.hp=Math.min(r.maxHP,r.hp+n);else if(kind==='temp')r.temp=Math.max(r.temp||0,n);}
 return{days,ensure,date,endDay,setDate,sorted,start,next,health};
})();
if(typeof module!=='undefined')module.exports=DMCore;
