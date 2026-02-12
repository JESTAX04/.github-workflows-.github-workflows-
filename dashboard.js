import { initializeApp } from "https://www.gstatic.com/firebasejs/9.23.0/firebase-app.js";
import {
  getFirestore, doc, getDoc, collection, query, where, getDocs, addDoc, setDoc, updateDoc, serverTimestamp, orderBy, limit, Timestamp
} from "https://www.gstatic.com/firebasejs/9.23.0/firebase-firestore.js";
import {
  getAuth, onAuthStateChanged, signOut, setPersistence, browserLocalPersistence
} from "https://www.gstatic.com/firebasejs/9.23.0/firebase-auth.js";

const cfg = window.APP_CONFIG;
const app = initializeApp(cfg.firebase);
const auth = getAuth(app);
const db = getFirestore(app);

// Persist auth across pages
await setPersistence(auth, browserLocalPersistence);

// ===== UI refs =====
const who = document.getElementById("who");
const goTrigger = document.getElementById("goTrigger");
const dashDownloadBtn = document.getElementById("dashDownloadBtn");
const logoutBtn = document.getElementById("logout");

const statusDot = document.getElementById("statusDot");
const statusText = document.getElementById("statusText");

const dAvatar = document.getElementById("dAvatar");
const dName = document.getElementById("dName");
const dMeta = document.getElementById("dMeta");
const appInfo = document.getElementById("appInfo");

// Admin
const adminBtn = document.getElementById("adminBtn");
const adminModal = document.getElementById("adminModal");
const adminClose = document.getElementById("adminClose");
const adminX = document.getElementById("adminX");

// Admin tabs
const tabLic = document.getElementById("tabLic");
const tabUsers = document.getElementById("tabUsers");
const tabAudit = document.getElementById("tabAudit");
const panelLic = document.getElementById("panelLic");
const panelUsers = document.getElementById("panelUsers");
const panelAudit = document.getElementById("panelAudit");

// License controls
const licEmail = document.getElementById("licEmail");
const licSearchBtn = document.getElementById("licSearchBtn");
const licResults = document.getElementById("licResults");

// License generation
const genEmail = document.getElementById("genEmail");
const genPlan = document.getElementById("genPlan");
const genKeyBtn = document.getElementById("genKeyBtn");
const genKeyOut = document.getElementById("genKeyOut");
const copyKeyBtn = document.getElementById("copyKeyBtn");
const mailKeyBtn = document.getElementById("mailKeyBtn");

// User controls
const userEmail = document.getElementById("userEmail");
const userSearchBtn = document.getElementById("userSearchBtn");
const userResults = document.getElementById("userResults");

// Audit
const auditRefreshBtn = document.getElementById("auditRefreshBtn");
const auditList = document.getElementById("auditList");

const TRIGGER_FILE = "./triggerfinder.html";
const ADMIN_DISCORD_ID = "469346764432867328";

// ===== Helpers =====
function setStatus(text, kind="") {
  if (statusText) statusText.textContent = text;
  if (!statusDot) return;
  statusDot.classList.remove("ok","bad");
  if (kind === "ok") statusDot.classList.add("ok");
  if (kind === "bad") statusDot.classList.add("bad");
}

function getDiscordAvatarUrl(u){
  if (!u?.id) return "https://cdn.discordapp.com/embed/avatars/0.png";
  if (!u.avatar) return "https://cdn.discordapp.com/embed/avatars/0.png";
  return `https://cdn.discordapp.com/avatars/${u.id}/${u.avatar}.png?size=128`;
}

function showModal(show){
  if (!adminModal) return;
  adminModal.classList.toggle("show", !!show);
}

function switchTab(which){
  const active = (btn, on) => btn?.classList.toggle("active", on);
  active(tabLic, which==="lic");
  active(tabUsers, which==="users");
  active(tabAudit, which==="audit");
  panelLic?.classList.toggle("hide", which!=="lic");
  panelUsers?.classList.toggle("hide", which!=="users");
  panelAudit?.classList.toggle("hide", which!=="audit");
}

function fmtTs(ts){
  try{
    const d = ts?.toDate ? ts.toDate() : (ts instanceof Date ? ts : null);
    if (!d) return "-";
    return d.toLocaleString();
  }catch{ return "-"; }
}

function genLicenseKey(){
  // Format: NO-XXXX-XXXX-XXXX (A-Z0-9)
  const alphabet = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
  const randChar = () => alphabet[Math.floor(Math.random() * alphabet.length)];
  const chunk = () => Array.from({length:4}, randChar).join("");
  return `NO-${chunk()}-${chunk()}-${chunk()}`;
}

function mailtoLicense(email, key, days){
  const to = (email || "").trim();
  if (!to) return;
  const subject = encodeURIComponent("Your License Key");
  const body = encodeURIComponent(
    `Hello,\n\nYour license key: ${key}\nExpiry: ${days} day(s)\n\nThanks.`
  );
  window.open(`mailto:${to}?subject=${subject}&body=${body}`, "_blank");
}

async function logAudit(actor, action, details={}){
  try{
    await addDoc(collection(db, "audit_logs"), {
      ts: serverTimestamp(),
      actorUid: actor?.uid || null,
      actorEmail: actor?.email || null,
      action,
      details
    });
  }catch(e){
    console.warn("audit log failed", e);
  }
}

function el(tag, cls, text){
  const n = document.createElement(tag);
  if (cls) n.className = cls;
  if (text !== undefined) n.textContent = text;
  return n;
}

function pill(text, kind=""){
  const p = el("span", "pill " + kind, text);
  return p;
}

async function getUserDoc(uid){
  const s = await getDoc(doc(db, "users", uid));
  return s.exists() ? s.data() : null;
}

async function enforceForceLogout(user){
  // If admin forced logout, sign out and redirect
  try{
    const udoc = await getUserDoc(user.uid);
    const f = udoc?.forceLogoutAt;
    if (!f) return;
    const key = `forceLogoutSeen:${user.uid}`;
    // avoid infinite loop: store last seen timestamp
    const fMillis = f?.toMillis ? f.toMillis() : null;
    const seen = Number(localStorage.getItem(key) || 0);
    if (fMillis && fMillis > seen){
      localStorage.setItem(key, String(fMillis));
      await signOut(auth);
      alert("You have been logged out by admin.");
      location.href = "./index.html";
    }
  }catch(e){
    console.warn("force logout check failed", e);
  }
}

// ===== Admin actions =====
async function searchLicensesByEmail(actor){
  const email = (licEmail?.value || "").trim().toLowerCase();
  licResults.innerHTML = "";
  if (!email) {
    licResults.appendChild(el("div","muted","Type an email to search."));
    return;
  }
  let qs;
  // Prefer emailLower, fallback to email if older docs don't have it.
  const q1 = query(collection(db, "licenses"), where("emailLower","==", email));
  qs = await getDocs(q1);
  if (qs.empty){
    const q2 = query(collection(db, "licenses"), where("email","==", email));
    qs = await getDocs(q2);
  }

  if (qs.empty){
    licResults.appendChild(el("div","muted","No licenses found."));
    await logAudit(actor, "license.search.email", { email, found: 0 });
    return;
  }

  const list = el("div","licList");
  qs.forEach((d)=>{
    const data = d.data() || {};
    const row = el("div","licRow");
    const left = el("div","licLeft");
    left.appendChild(el("div","licKey", d.id));
    const meta = el("div","licMeta");
    meta.appendChild(pill(data.active === false || data.revoked ? "REVOKED" : "ACTIVE", (data.active === false || data.revoked) ? "bad":"ok"));
    meta.appendChild(pill(data.used ? "USED" : "UNUSED", data.used ? "warn":""));
    meta.appendChild(pill("EXP: " + fmtTs(data.expiresAt), ""));
    meta.appendChild(pill("HWID: " + (data.hwidHash ? "BOUND" : "NONE"), data.hwidHash ? "warn": ""));
    left.appendChild(meta);

    const right = el("div","licRight");

    const revokeBtn = el("button","btn small danger", (data.active === false || data.revoked) ? "UNREVOKE" : "REVOKE");
    revokeBtn.onclick = async ()=>{
      const nextRevoked = !(data.active === false || data.revoked);
      await updateDoc(doc(db,"licenses",d.id), {
        revoked: nextRevoked,
        active: !nextRevoked
      });
      await logAudit(actor, "license.revoke.toggle", { licenseKey: d.id, revoked: nextRevoked });
      await searchLicensesByEmail(actor);
    };

    const resetHwidBtn = el("button","btn small", "RESET HWID");
    resetHwidBtn.onclick = async ()=>{
      await updateDoc(doc(db,"licenses",d.id), {
        hwidHash: null,
        hwidBoundAt: null,
        allowRebind: true
      });
      await logAudit(actor, "license.hwid.reset", { licenseKey: d.id });
      await searchLicensesByEmail(actor);
    };

    const setExpBtn = el("button","btn small", "SET EXPIRY (DAYS)");
    setExpBtn.onclick = async ()=>{
      const days = prompt("Expiry days from now (e.g. 30). Leave blank to cancel.");
      if (!days) return;
      const n = Number(days);
      if (!Number.isFinite(n) || n <= 0) return alert("Invalid number.");
      const ms = n * 24 * 60 * 60 * 1000;
      const exp = new Date(Date.now() + ms);
      await updateDoc(doc(db,"licenses",d.id), {
        expiresAt: exp
      });
      await logAudit(actor, "license.expiry.set", { licenseKey: d.id, days: n });
      await searchLicensesByEmail(actor);
    };

    right.appendChild(revokeBtn);
    right.appendChild(resetHwidBtn);
    right.appendChild(setExpBtn);

    row.appendChild(left);
    row.appendChild(right);
    list.appendChild(row);
  });

  licResults.appendChild(list);
  await logAudit(actor, "license.search.email", { email, found: qs.size });
}

async function searchUsersByEmail(actor){
  const email = (userEmail?.value || "").trim().toLowerCase();
  userResults.innerHTML = "";
  if (!email){
    userResults.appendChild(el("div","muted","Type an email to search."));
    return;
  }

  let qs;
  const q1 = query(collection(db,"users"), where("emailLower","==", email));
  qs = await getDocs(q1);
  if (qs.empty){
    const q2 = query(collection(db,"users"), where("email","==", email));
    qs = await getDocs(q2);
  }

  if (qs.empty){
    userResults.appendChild(el("div","muted","No users found."));
    await logAudit(actor, "user.search.email", { email, found: 0 });
    return;
  }

  const wrap = el("div","userList");
  qs.forEach((d)=>{
    const data = d.data() || {};
    const row = el("div","userRow");
    const left = el("div","userLeft");
    left.appendChild(el("div","userTitle", data.email || email));
    const meta = el("div","userMeta");
    meta.appendChild(pill("UID: " + d.id, ""));
    if (data.discordId) meta.appendChild(pill("Discord: " + data.discordId, ""));
    if (data.forceLogoutAt) meta.appendChild(pill("ForceLogout: " + fmtTs(data.forceLogoutAt), "warn"));
    left.appendChild(meta);

    const right = el("div","userRight");
    const forceBtn = el("button","btn small danger","FORCE LOGOUT");
    forceBtn.onclick = async ()=>{
      await updateDoc(doc(db,"users", d.id), {
        forceLogoutAt: serverTimestamp(),
        forceLogoutReason: "admin"
      });
      await logAudit(actor, "user.forceLogout", { targetUid: d.id, targetEmail: data.email || email });
      alert("Force logout set. User will be logged out on next check.");
      await searchUsersByEmail(actor);
    };

    right.appendChild(forceBtn);
    row.appendChild(left);
    row.appendChild(right);
    wrap.appendChild(row);
  });

  userResults.appendChild(wrap);
  await logAudit(actor, "user.search.email", { email, found: qs.size });
}

async function loadAudit(){
  auditList.innerHTML = "";
  const q = query(collection(db, "audit_logs"), orderBy("ts","desc"), limit(50));
  const qs = await getDocs(q);
  if (qs.empty){
    auditList.appendChild(el("div","muted","No audit logs yet."));
    return;
  }
  const list = el("div","auditItems");
  qs.forEach((d)=>{
    const a = d.data() || {};
    const item = el("div","auditItem");
    const top = el("div","auditTop");
    top.appendChild(el("div","auditAction", a.action || "action"));
    top.appendChild(el("div","auditTs", fmtTs(a.ts)));
    const sub = el("div","auditSub", `${a.actorEmail || "unknown"} (${a.actorUid || "-"})`);
    const det = el("pre","auditDetails", JSON.stringify(a.details || {}, null, 2));
    item.appendChild(top);
    item.appendChild(sub);
    item.appendChild(det);
    list.appendChild(item);
  });
  auditList.appendChild(list);
}

// ===== Main =====
goTrigger?.addEventListener("click", ()=> location.href = TRIGGER_FILE);
dashDownloadBtn?.addEventListener("click", ()=>{
  // Keep original behavior: open downloads section/page if exists
  const url = "./downloads.html";
  window.open(url, "_blank");
});
logoutBtn?.addEventListener("click", async ()=>{
  await signOut(auth);
  location.href = "./index.html";
});

adminBtn?.addEventListener("click", ()=>{
  switchTab("lic");
  showModal(true);
});
adminClose?.addEventListener("click", ()=> showModal(false));
adminX?.addEventListener("click", ()=> showModal(false));

tabLic?.addEventListener("click", ()=> switchTab("lic"));
tabUsers?.addEventListener("click", ()=> switchTab("users"));
tabAudit?.addEventListener("click", ()=> switchTab("audit"));

licSearchBtn?.addEventListener("click", ()=> {
  if (window.__dashUser) searchLicensesByEmail(window.__dashUser);
});

genKeyBtn?.addEventListener("click", async()=>{
  if (!isAdmin){ toast("Admin only", "err"); return; }
  const email = (genEmail.value || "").trim().toLowerCase();
  const plan = (genPlan?.value || "1m");
  const key = genLicenseKey();
  let expiresAt = null;
  let expiresPlan = plan;
  if (plan === "lifetime"){
    expiresAt = null;
  } else if (plan === "3m"){
    expiresAt = Timestamp.fromDate(new Date(Date.now() + 90 * 86400000));
  } else {
    // 1 month default
    expiresAt = Timestamp.fromDate(new Date(Date.now() + 30 * 86400000));
    expiresPlan = "1m";
  }

  try{
    await setDoc(doc(db, "licenses", key), {
      key,
      email: email || null,
      status: "active",
      revoked: false,
      hwid: null,
      createdAt: serverTimestamp(),
      expiresAt
    });

    genKeyOut.value = key;
    toast("License generated", "ok");
    try{ await addAudit("license_generate", { key, email: email || null, days }); }catch{}
  }catch(e){
    console.error(e);
    toast("Generate failed", "err");
  }
});

copyKeyBtn?.addEventListener("click", async()=>{
  const k = (genKeyOut.value || "").trim();
  if (!k) return toast("No key", "warn");
  try{ await navigator.clipboard.writeText(k); toast("Copied", "ok"); }catch{ toast("Copy failed", "err"); }
});

mailKeyBtn?.addEventListener("click", ()=>{
  const email = (genEmail.value || "").trim();
  const key = (genKeyOut.value || "").trim();
  if (!email) return toast("Enter email", "warn");
  if (!key) return toast("Generate key first", "warn");
  const subj = encodeURIComponent("Your license key");
  const body = encodeURIComponent(`Here is your license key:\n\n${key}\n\nThank you.`);
  window.open(`mailto:${encodeURIComponent(email)}?subject=${subj}&body=${body}`, "_blank");
});
userSearchBtn?.addEventListener("click", ()=> {
  if (window.__dashUser) searchUsersByEmail(window.__dashUser);
});
auditRefreshBtn?.addEventListener("click", loadAudit);

onAuthStateChanged(auth, async (user)=>{
  if (!user){
    location.href = "./index.html";
    return;
  }
  window.__dashUser = user;

  // Force logout check
  await enforceForceLogout(user);

  // Load profile doc
  const udoc = await getUserDoc(user.uid);
  const email = (user.email || udoc?.email || "").toString();
  who.textContent = email ? `Logged in: ${email}` : "Logged in";
  appInfo.textContent = email ? `Logged in: ${email}` : "";
  setStatus("Ready.", "ok");

  try{
    const si = document.getElementById('sessionInfo');
    if(si){
      const exp = udoc?.licenseExpiresAt;
      let line = email ? `Session: ${email}` : 'Session ready';
      if(exp){
        const ms = (exp.toMillis ? exp.toMillis() : Number(exp)) || 0;
        if(ms){
          const days = Math.max(0, Math.ceil((ms - Date.now())/86400000));
          line += ` • License: ACTIVE (${days}d)`;
        }
      }
      si.textContent = line;
    }
  }catch(_){}


  // Discord info (support two shapes: udoc.discord object or fields)
  const discord = udoc?.discord || null;
  const discordId = udoc?.discordId || discord?.id || "";
  const discordName = discord?.username ? `${discord.username}` : (udoc?.discordName || "Discord");
  const discordAvatar = discord?.avatar ? getDiscordAvatarUrl({id: discordId, avatar: discord.avatar}) : (udoc?.discordAvatar || null);

  if (dName) dName.textContent = discordName || "Discord";
  if (dMeta) dMeta.textContent = discordId ? `ID: ${discordId} • ${email}` : email;
  if (dAvatar && discordAvatar) dAvatar.src = discordAvatar;

  // Topbar profile + role
  try{
    const roles = (cfg && cfg.roles) ? cfg.roles : {owners:[], admins:[]};
    const did = String(discordId || "");
    let role = "USER";
    if (roles.owners && roles.owners.map(String).includes(did)) role = "OWNER";
    else if (roles.admins && roles.admins.map(String).includes(did)) role = "ADMIN";
    if (window.h89SetProfile) window.h89SetProfile(discordAvatar || "", role);
  }catch(_){}


  // Admin visible only for your ID
  const tileAdmin = document.getElementById('tileAdmin');
  isAdmin = (discordId && String(discordId) === ADMIN_DISCORD_ID);
  if (adminBtn){
    adminBtn.style.display = (discordId && String(discordId) === ADMIN_DISCORD_ID) ? "block" : "none";
  }
});
