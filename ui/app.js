const bridge = {
  trigger(eventName, ...args){
    try{
      if (window.mta && typeof window.mta.triggerEvent === "function"){
        window.mta.triggerEvent(eventName, ...args);
      } else if (window.mta && typeof window.mta.triggerServerEvent === "function"){
        window.mta.triggerServerEvent(eventName, ...args);
      } else {
        console.log("No MTA bridge:", eventName, args);
      }
    }catch(e){ console.log(e); }
  }
};

window.MDT = {
  setUser(name, job){
    document.getElementById("userLine").innerText = `${name} • ${job}`;
  },
  setCitizenResults(rows){
    const box = document.getElementById("citizenList");
    box.innerHTML = "";
    if (!rows || rows.length === 0){
      box.innerHTML = `<div class="muted">No results.</div>`;
      return;
    }
    rows.forEach(r=>{
      const div = document.createElement("div");
      div.className = "row";
      div.textContent = `#${r.id} • ${r.name} • Age ${r.age} • ${r.phone}`;
      box.appendChild(div);
    });
  }
};

document.getElementById("btnClose").addEventListener("click", ()=>{
  bridge.trigger("mdt:close");
});

function doSearch(){
  const q = document.getElementById("searchInput").value || "";
  bridge.trigger("mdt:searchCitizen", q);
}
document.getElementById("btnSearch").addEventListener("click", doSearch);
document.getElementById("searchInput").addEventListener("keydown", (e)=>{
  if (e.key === "Enter") doSearch();
});
