(() => {
 const shell=document.querySelector('.admin-shell');
 const toggle=document.querySelector('[data-admin-toggle]');
 if(!shell||!toggle)return;
 const setOpen=open=>{shell.classList.toggle('sidebar-open',open);toggle.setAttribute('aria-expanded',String(open));};
 toggle.addEventListener('click',()=>setOpen(!shell.classList.contains('sidebar-open')));
 document.querySelector('[data-admin-close]')?.addEventListener('click',()=>setOpen(false));
 document.addEventListener('keydown',event=>{if(event.key==='Escape'){setOpen(false);toggle.focus();}});
})();
