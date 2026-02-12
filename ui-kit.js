
/* H89 UI KIT - shared helpers (no build required) */
(function(){
  const LS_KEY = "h89_notify_log_v1";

  function nowStr(){
    try{ return new Date().toLocaleString(); }catch{ return ""; }
  }

  function loadLog(){
    try{ return JSON.parse(localStorage.getItem(LS_KEY) || "[]") || []; }catch{ return []; }
  }
  function saveLog(arr){
    try{ localStorage.setItem(LS_KEY, JSON.stringify(arr.slice(-200))); }catch(_){}
  }

  function renderDrawer(){
    const drawer = document.getElementById("h89NotifyDrawer");
    if(!drawer) return;
    const items = loadLog().slice().reverse();
    if(items.length === 0){
      drawer.innerHTML = `<div class="h89-nrow"><span class="h89-ntag ok">INFO</span><div><div class="h89-nmsg">No notifications yet.</div></div></div>`;
      return;
    }
    drawer.innerHTML = items.map(it=>{
      const tag = (it.type || "info").toLowerCase();
      const cls = tag === "warn" ? "warn" : (tag === "err" ? "err" : (tag === "ok" ? "ok" : ""));
      const label = tag.toUpperCase();
      const msg = String(it.msg || "");
      const time = String(it.time || "");
      return `
        <div class="h89-nrow">
          <span class="h89-ntag ${cls}">${label}</span>
          <div style="min-width:0">
            <div class="h89-nmsg">${escapeHtml(msg)}</div>
            <div class="h89-ntime">${escapeHtml(time)}</div>
          </div>
        </div>
      `;
    }).join("");
  }

  function updateBell(){
    const btn = document.getElementById("h89BellBtn");
    const badge = document.getElementById("h89BellCount");
    if(!btn || !badge) return;
    const count = loadLog().length;
    if(count > 0){
      badge.style.display = "grid";
      badge.textContent = String(Math.min(count, 99));
    }else{
      badge.style.display = "none";
      badge.textContent = "0";
    }
  }

  function toggleDrawer(force){
    const drawer = document.getElementById("h89NotifyDrawer");
    if(!drawer) return;
    const wantOpen = typeof force === "boolean" ? force : drawer.classList.contains("hidden");
    drawer.classList.toggle("hidden", !wantOpen);
    drawer.setAttribute("aria-hidden", wantOpen ? "false" : "true");
    if(wantOpen){
      renderDrawer();
    }
  }

  function escapeHtml(s){
    return String(s)
      .replaceAll("&","&amp;")
      .replaceAll("<","&lt;")
      .replaceAll(">","&gt;")
      .replaceAll('"',"&quot;")
      .replaceAll("'","&#039;");
  }

  // Public API: notifications
  window.h89Notify = function(type, msg){
    const t = (type || "info").toLowerCase();
    const entry = { type: t, msg: String(msg || ""), time: nowStr() };
    const arr = loadLog();
    arr.push(entry);
    saveLog(arr);
    updateBell();
  };

  // Public API: topbar status/profile
  window.h89SetStatus = function(text){
    const el = document.getElementById("h89TopStatus");
    if(!el) return;
    el.textContent = text || "● READY";
  };
  window.h89SetProfile = function(avatarUrl, role){
    const ava = document.getElementById("h89TopAvatar");
    const r = document.getElementById("h89TopRole");
    if(ava){
      ava.src = avatarUrl || "https://cdn.discordapp.com/embed/avatars/0.png";
    }
    if(r){
      r.textContent = (role || "USER").toUpperCase();
    }
  };

  // Bell click
  document.addEventListener("click", (e)=>{
    const t = e.target;
    const btn = t && (t.closest ? t.closest("#h89BellBtn") : null);
    if(btn){
      toggleDrawer();
      return;
    }
    // click outside closes
    const drawer = document.getElementById("h89NotifyDrawer");
    if(drawer && !drawer.classList.contains("hidden")){
      if(!t.closest("#h89NotifyDrawer") && !t.closest("#h89BellBtn")){
        toggleDrawer(false);
      }
    }
  });

  // Command palette (Ctrl+K)
  function ensurePalette(){
    if(document.getElementById("h89CmdBackdrop")) return;
    const html = `
      <div id="h89CmdBackdrop" style="position:fixed;inset:0;background:rgba(0,0,0,.55);backdrop-filter:blur(6px);display:none;z-index:10001;">
        <div style="width:min(720px,calc(100% - 24px));margin:80px auto;border-radius:18px;border:1px solid rgba(255,45,45,.25);background:rgba(0,0,0,.88);box-shadow:0 25px 80px rgba(0,0,0,.65);overflow:hidden;">
          <div style="padding:12px;border-bottom:1px solid rgba(255,255,255,.10);display:flex;gap:10px;align-items:center;">
            <i class="fa-solid fa-magnifying-glass" style="opacity:.8"></i>
            <input id="h89CmdInput" placeholder="Type a command..." style="flex:1;padding:12px;border-radius:12px;border:1px solid rgba(255,255,255,.12);background:rgba(255,255,255,.06);color:#fff;outline:none;font-family:inherit;">
            <button id="h89CmdClose" class="btn small" type="button">ESC</button>
          </div>
          <div id="h89CmdList" style="max-height:min(50vh,520px);overflow:auto;padding:10px;"></div>
        </div>
      </div>
    `;
    document.body.insertAdjacentHTML("beforeend", html);

    document.getElementById("h89CmdClose").onclick = ()=> hidePalette();
    document.getElementById("h89CmdBackdrop").addEventListener("click",(e)=>{
      if(e.target && e.target.id==="h89CmdBackdrop") hidePalette();
    });
  }

  function commands(){
    const cmds = [];
    const byId = (id)=>document.getElementById(id);

    if(byId("goTrigger") || byId("tileTrigger")) cmds.push({k:"Open TriggerFinder", run:()=> (byId("goTrigger")||byId("tileTrigger")).click()});
    if(byId("dashDownloadBtn") || byId("tileDownloads")) cmds.push({k:"Open Downloads", run:()=> (byId("dashDownloadBtn")||byId("tileDownloads")).click()});
    if(byId("adminBtn") || byId("tileAdmin")) cmds.push({k:"Open Admin Panel", run:()=> (byId("adminBtn")||byId("tileAdmin")).click()});
    if(byId("logout") || byId("tileLogout") || byId("btnLogout")) cmds.push({k:"Logout", run:()=> (byId("logout")||byId("tileLogout")||byId("btnLogout")).click()});
    if(byId("btnDiscord")) cmds.push({k:"Connect Discord", run:()=> byId("btnDiscord").click()});
    if(byId("btnForgot")) cmds.push({k:"Forgot Password", run:()=> byId("btnForgot").click()});

    return cmds;
  }

  function renderCmdList(filter=""){
    const list = document.getElementById("h89CmdList");
    const q = (filter||"").toLowerCase().trim();
    const rows = commands().filter(c=> !q || c.k.toLowerCase().includes(q));
    if(rows.length===0){
      list.innerHTML = `<div class="h89-nrow"><span class="h89-ntag warn">NONE</span><div><div class="h89-nmsg">No matching commands.</div></div></div>`;
      return;
    }
    list.innerHTML = rows.map((c,idx)=>`
      <button class="h89-tile" data-cmd="${idx}" type="button" style="width:100%;justify-content:flex-start;">
        <i class="fa-solid fa-terminal"></i><span>${escapeHtml(c.k)}</span>
      </button>
    `).join("");
    list.querySelectorAll("[data-cmd]").forEach(btn=>{
      btn.onclick = ()=>{
        const id = Number(btn.getAttribute("data-cmd"));
        const cmd = rows[id];
        hidePalette();
        try{ cmd.run(); }catch(_){}
      };
    });
  }

  function showPalette(){
    ensurePalette();
    const b = document.getElementById("h89CmdBackdrop");
    const inp = document.getElementById("h89CmdInput");
    b.style.display = "block";
    renderCmdList("");
    setTimeout(()=>{ inp.value=""; inp.focus(); }, 0);
    inp.oninput = ()=> renderCmdList(inp.value);
    inp.onkeydown = (e)=>{
      if(e.key==="Escape") hidePalette();
      if(e.key==="Enter"){
        const first = document.querySelector("#h89CmdList [data-cmd]");
        if(first) first.click();
      }
    };
  }
  function hidePalette(){
    const b = document.getElementById("h89CmdBackdrop");
    if(b) b.style.display = "none";
  }

  window.addEventListener("keydown",(e)=>{
    if((e.ctrlKey || e.metaKey) && e.key.toLowerCase()==="k"){
      e.preventDefault();
      showPalette();
    }
    if(e.key==="Escape") hidePalette();
  });

  // Password show/hide + strength (login page)
  function initPasswordUI(){
    const pw = document.getElementById("password");
    const toggle = document.getElementById("pwToggle");
    const bar = document.getElementById("pwBar");
    const meta = document.getElementById("pwMeta");
    if(!pw || !toggle || !bar || !meta) return;

    toggle.addEventListener("click", ()=>{
      const isPw = pw.getAttribute("type")==="password";
      pw.setAttribute("type", isPw ? "text" : "password");
      toggle.innerHTML = isPw ? '<i class="fa-solid fa-eye-slash"></i>' : '<i class="fa-solid fa-eye"></i>';
    });

    function score(p){
      let s = 0;
      if(p.length>=8) s+=1;
      if(p.length>=12) s+=1;
      if(/[A-Z]/.test(p)) s+=1;
      if(/[a-z]/.test(p)) s+=1;
      if(/[0-9]/.test(p)) s+=1;
      if(/[^A-Za-z0-9]/.test(p)) s+=1;
      return Math.min(s,6);
    }
    function update(){
      const p = pw.value || "";
      const s = score(p);
      const pct = Math.round((s/6)*100);
      bar.style.width = pct+"%";
      // no hardcoded colors; use gradients via existing vars
      bar.style.background = "linear-gradient(90deg, rgba(255,45,45,.25), rgba(180,0,0,.20))";
      meta.textContent = "Strength: " + (s<=1 ? "Weak" : (s<=3 ? "Medium" : (s<=5 ? "Strong" : "Very strong")));
    }
    pw.addEventListener("input", update);
    update();
  }

  // Dashboard tiles bind
  function bindTiles(){
    const link = (tileId, btnId)=>{
      const t = document.getElementById(tileId);
      const b = document.getElementById(btnId);
      if(t && b){
        t.addEventListener("click", ()=> b.click());
      }
    };
    link("tileTrigger","goTrigger");
    link("tileDownloads","dashDownloadBtn");
    link("tileAdmin","adminBtn");
    link("tileLogout","logout");
  }

  // init
  updateBell();
  initPasswordUI();
  bindTiles();
})();
