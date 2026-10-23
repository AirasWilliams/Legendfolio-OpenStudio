// SPDX-License-Identifier: AGPL-3.0-only
/* Coalesce repeated presentation work and flush local edits at lifecycle boundaries. */
let performanceFrame=null,performanceRefreshArgs=[];
const performanceOriginalModernRefresh=modernRefresh;
function performanceFlushPresentation(){if(performanceFrame!==null){cancelAnimationFrame(performanceFrame);performanceFrame=null;}return performanceOriginalModernRefresh(...performanceRefreshArgs);}
modernRefresh=function(...args){performanceRefreshArgs=args;if(performanceFrame===null)performanceFrame=requestAnimationFrame(()=>{performanceFrame=null;performanceOriginalModernRefresh(...performanceRefreshArgs);});};
document.addEventListener('visibilitychange',()=>{if(document.visibilityState==='hidden')performanceWriter.flush().catch(()=>{});});
window.addEventListener('pagehide',()=>{performanceWriter.flush().catch(()=>{});});
// Old layout rules target every aside; this inspector is content-sized, not a second full-height side rail.
