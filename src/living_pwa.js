(()=>{
const button=document.getElementById('theme-toggle'),install=document.getElementById('install-app');
let theme='dark',prompt=null;
try{theme=localStorage.getItem('strixhaven-theme')||'dark'}catch{}
function setTheme(value){theme=value==='light'?'light':'dark';document.documentElement.dataset.theme=theme;button.textContent=theme==='dark'?'Light mode':'Dark mode';button.setAttribute('aria-pressed',String(theme==='dark'));try{localStorage.setItem('strixhaven-theme',theme)}catch{}}
setTheme(theme);button.onclick=()=>setTheme(theme==='dark'?'light':'dark');
const eligible=location.protocol==='https:'||['localhost','127.0.0.1'].includes(location.hostname);
window.addEventListener('beforeinstallprompt',event=>{event.preventDefault();prompt=event;install.textContent='Install app'});
window.addEventListener('appinstalled',()=>{prompt=null;install.textContent='Installed';install.disabled=true});
install.onclick=async()=>{if(prompt){await prompt.prompt();await prompt.userChoice;prompt=null;return}alert(eligible?'Use your browser menu: Install Legendfolio: TTRPG Studio, or Add to Home Screen. If installation is not available yet, reload once after the first launch.':'To install, run Start Legendfolio.cmd from the PWA folder. In the browser that opens, choose Install app. Transfer your existing character using Backup and Restore.');};
if(eligible&&document.querySelector('link[rel="manifest"]')&&'serviceWorker' in navigator){navigator.serviceWorker.register('./sw.js',{updateViaCache:'none'}).catch(()=>{install.textContent='Install help'});if(navigator.storage?.persist)navigator.storage.persist().catch(()=>{});}
})();
