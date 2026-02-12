import { initializeApp } from "https://www.gstatic.com/firebasejs/9.23.0/firebase-app.js";
import {
 getAuth,
 setPersistence,
 browserLocalPersistence,
 signInWithEmailAndPassword,
 createUserWithEmailAndPassword,
 sendPasswordResetEmail,
 signOut,
 onAuthStateChanged
} from "https://www.gstatic.com/firebasejs/9.23.0/firebase-auth.js";

import {
 getFirestore,
 doc,
 collection,
 addDoc,
 getDoc,
 setDoc,
 updateDoc,
 deleteField,
 serverTimestamp,
 Timestamp
} from "https://www.gstatic.com/firebasejs/9.23.0/firebase-firestore.js";

const cfg = window.APP_CONFIG;
const app = initializeApp(cfg.firebase);
const auth = getAuth(app);
const db = getFirestore(app);

// -------------------- Audit helpers (queue until user is authenticated) --------------------
const PENDING_AUDIT_KEY = "pending_audit_logs";

function queueAudit(action, details = {}) {
  try {
    const arr = JSON.parse(localStorage.getItem(PENDING_AUDIT_KEY) || "[]");
    arr.push({ action, details, ts: Date.now() });
    // keep it small
    while (arr.length > 50) arr.shift();
    localStorage.setItem(PENDING_AUDIT_KEY, JSON.stringify(arr));
  } catch (_) {}
}

async function flushQueuedAudit(user) {
  if (!user) return;
  let arr = [];
  try {
    arr = JSON.parse(localStorage.getItem(PENDING_AUDIT_KEY) || "[]");
  } catch (_) {
    arr = [];
  }
  if (!arr.length) return;

  // write in-order; if one fails, keep remaining
  const keep = [];
  for (const item of arr) {
    try {
      await addDoc(collection(db, "audit_logs"), {
        action: item.action,
        actorUid: user.uid,
        actorEmail: user.email || null,
        details: item.details || {},
        createdAt: serverTimestamp(),
        clientTs: item.ts || Date.now()
      });
    } catch (e) {
      keep.push(item);
    }
  }
  try {
    if (keep.length) localStorage.setItem(PENDING_AUDIT_KEY, JSON.stringify(keep));
    else localStorage.removeItem(PENDING_AUDIT_KEY);
  } catch (_) {}
}


// ===== License Key Gate (PRO) =====
const ADMIN_DISCORD_ID = "469346764432867328";

// ===== Device Fingerprint (browser-based) =====
// NOTE: Web apps cannot read real "HWID". This uses a stable browser fingerprint + stored device id.
function getOrCreateDeviceId(){
  const k = "tf_device_id";
  let id = localStorage.getItem(k);
  if (!id){
    id = (crypto.randomUUID ? crypto.randomUUID() : (Date.now().toString(36) + Math.random().toString(36).slice(2)));
    localStorage.setItem(k, id);
  }
  return id;
}

async function sha256Hex(str){
  try{
    const enc = new TextEncoder().encode(str);
    const buf = await crypto.subtle.digest("SHA-256", enc);
    return Array.from(new Uint8Array(buf)).map(b=>b.toString(16).padStart(2,"0")).join("");
  } catch(e){
    // Fallback (non-crypto) - still gives a stable-ish hash
    let h = 0;
    for (let i=0;i<str.length;i++){ h = ((h<<5)-h) + str.charCodeAt(i); h|=0; }
    return "x"+(h>>>0).toString(16);
  }
}

async function getDeviceHwidHash(){
  const id = getOrCreateDeviceId();
  const fp = [
    id,
    navigator.userAgent || "",
    navigator.platform || "",
    String(screen?.width||0)+"x"+String(screen?.height||0),
    String(new Date().getTimezoneOffset())
  ].join("|");
  return await sha256Hex(fp);
}



async function verifyLicenseKey(licenseKey, email) {
  try {
    if (!licenseKey) return { ok: false, reason: "License key required" };
    const key = String(licenseKey).trim();
    const ref = doc(db, "licenses", key);
    const snap = await getDoc(ref);
    if (!snap.exists()) return { ok: false, reason: "Invalid license key" };
    const data = snap.data() || {};

    if (data.revokedAt) return { ok: false, reason: "License revoked" };
    if (data.active === false) return { ok: false, reason: "License key disabled" };

    // Email lock (optional)
    if (data.email && String(data.email).toLowerCase() !== String(email||"").toLowerCase()) {
      return { ok: false, reason: "License key not for this email" };
    }

    // Expiry
    const exp = data.expiresAt?.toDate ? data.expiresAt.toDate() : (data.expiresAt ? new Date(data.expiresAt) : null);
    if (exp && Date.now() > exp.getTime()) {
      return { ok: false, reason: "License expired" };
    }

    // HWID / device bind
    const hwid = await getDeviceHwidHash();
    if (data.hwidHash && String(data.hwidHash) !== String(hwid)) {
      return { ok: false, reason: "License bound to another device" };
    }

    if (data.used === true) return { ok: false, reason: "License key already used" };

    return { ok: true, key, hwid };
  } catch (e) {
    console.error("verifyLicenseKey error", e);
    return { ok: false, reason: "License verification error" };
  }
}

async function consumeLicenseKey(key, uid, email, hwidHash) {
  try {
    const ref = doc(db, "licenses", key);
    await updateDoc(ref, {
      used: true,
      usedBy: uid,
      usedEmail: email || null,
      usedAt: serverTimestamp(),
      hwidHash: hwidHash || null,
      lastSeenAt: serverTimestamp()
    });
  } catch (e) {
    console.error("consumeLicenseKey error", e);
  }
}

function updateAdminVisibility(profile) {
  try {
    const adminBtn = document.getElementById("adminBtn");
    if (!adminBtn) return;
    const did = profile && (profile.discordId || profile.discord_id);
    adminBtn.style.display = (String(did||"") === ADMIN_DISCORD_ID) ? "inline-flex" : "none";
  } catch(_){}
}

await setPersistence(auth, browserLocalPersistence);

// UI
const tabLogin = document.getElementById("tabLogin");
const tabCreate = document.getElementById("tabCreate");
const authForm = document.getElementById("authForm");
const emailEl = document.getElementById("email");
const passEl = document.getElementById("password");
const btnPrimary = document.getElementById("btnPrimary");
const btnForgot = document.getElementById("btnForgot");
const btnDiscord = document.getElementById("btnDiscord");
const btnLogout = document.getElementById("btnLogout");
const errEl = document.getElementById("err");
const discordLabel = document.getElementById("discordLabel");
const statusDot = document.getElementById("statusDot");
const statusText = document.getElementById("statusText");
const discordDot = document.querySelector(".discordDot");

let mode = "login";

function setStatus(text, kind="") {
 statusText.textContent = text;
 try{ if(window.h89SetStatus) window.h89SetStatus(`● ${text}`); }catch(_){ }
 try{ if(window.h89Notify && kind==="bad") window.h89Notify("err", text); }catch(_){ }
 try{ if(window.h89Notify && kind==="ok") window.h89Notify("ok", text); }catch(_){ }
 statusDot.classList.remove("ok","bad");
 if (kind === "ok") statusDot.classList.add("ok");
 if (kind === "bad") statusDot.classList.add("bad");
}
function showError(msg="") {
 errEl.textContent = msg || "";
 if (msg) setStatus("Error.", "bad");
}
function clearError(){ errEl.textContent = ""; }
function isValidEmail(s){ return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(String(s||"").trim()); }
function getEmail(){ return (emailEl?.value || "").trim(); }
function getPass(){ return (passEl?.value || "").trim(); }

// Discord session (PKCE)
const DISCORD = { verifierKey:"discord_pkce_verifier", sessionKey:"discord_session", stateKey:"discord_oauth_state" };

function base64url(bytes){
 const bin = String.fromCharCode(...new Uint8Array(bytes));
 return btoa(bin).replace(/\+/g,"-").replace(/\//g,"_").replace(/=+$/,"");
}
function randomString(len=64){
 const a = new Uint8Array(len);
 crypto.getRandomValues(a);
 return base64url(a);
}
async function sha256(str){
 const data = new TextEncoder().encode(str);
 const hash = await crypto.subtle.digest("SHA-256", data);
 return new Uint8Array(hash);
}
function getDiscordSession(){
 try { return JSON.parse(sessionStorage.getItem(DISCORD.sessionKey) || "null"); }
 catch { return null; }
}
function isDiscordSessionValid(sess){
 if (!sess?.access_token || !sess?.obtained_at || !sess?.expires_in) return false;
 const expiresAt = sess.obtained_at + (Number(sess.expires_in) * 1000) - 10_000;
 return Date.now() < expiresAt;
}
function saveDiscordSession(session){
 sessionStorage.setItem(DISCORD.sessionKey, JSON.stringify(session));
 refreshCreateGateUI();
}
function clearDiscordSession(){
 sessionStorage.removeItem(DISCORD.sessionKey);
 sessionStorage.removeItem(DISCORD.verifierKey);
 sessionStorage.removeItem(DISCORD.stateKey);
 refreshCreateGateUI();
}
function refreshCreateGateUI(){
 const s = getDiscordSession();
 if (s && !isDiscordSessionValid(s)) clearDiscordSession();

 const discord = getDiscordSession();
 const isConnected = Boolean(discord?.user?.id && isDiscordSessionValid(discord));
 discordLabel.textContent = isConnected ? `DISCORD ✓ ${discord.user.username ?? "connected"}` : "CONNECT DISCORD";
 discordDot.style.background = isConnected ? "rgba(27,217,106,.9)" : "rgba(255,255,255,.35)";

 if (mode === "create") {
 btnPrimary.disabled = !isConnected;
 setStatus(isConnected ? "Discord connected. You can CREATE now." : "Discord required for CREATE. Connect Discord first.", isConnected ? "ok" : "bad");
 } else {
 btnPrimary.disabled = false;
 setStatus("Ready.", "");
 }
}
function setMode(newMode) {
 mode = newMode;// fixed undefined var
 const isLogin = mode === "login";
 tabLogin.classList.toggle("active", isLogin);
 tabCreate.classList.toggle("active", !isLogin);
 btnPrimary.textContent = isLogin ? "LOGIN" : "CREATE";
 clearError();
 
  // License key only required for Create
  if (licenseWrap) licenseWrap.style.display = (mode === "create") ? "block" : "none";
  if (mode !== "create" && licenseKeyEl) licenseKeyEl.value = "";
  refreshCreateGateUI();
}
tabLogin.addEventListener("click", () => setMode("login"));
tabCreate.addEventListener("click", () => setMode("create"));

// Discord OAuth2 PKCE
async function startDiscordLogin(){
 clearError();
 setStatus("Opening Discord login...", "");
 const verifier = randomString(64);
 const challenge = base64url(await sha256(verifier));
 const state = randomString(16);

 sessionStorage.setItem(DISCORD.stateKey, state);
 sessionStorage.setItem(DISCORD.verifierKey, verifier);

 const url = new URL("https://discord.com/api/oauth2/authorize");
 url.searchParams.set("client_id", cfg.discord.clientId);
 url.searchParams.set("response_type", "code");
 url.searchParams.set("redirect_uri", cfg.discord.redirectUri);
 url.searchParams.set("scope", cfg.discord.scope || "identify email");
 url.searchParams.set("state", state);
 url.searchParams.set("code_challenge_method", "S256");
 url.searchParams.set("code_challenge", challenge);

 window.location.href = url.toString();
}
async function exchangeCodeForToken(code){
 const verifier = sessionStorage.getItem(DISCORD.verifierKey);
 if (!verifier) throw new Error("PKCE verifier missing. Try again.");

 const body = new URLSearchParams({
 client_id: cfg.discord.clientId,
 grant_type: "authorization_code",
 code,
 redirect_uri: cfg.discord.redirectUri,
 code_verifier: verifier
 });

 const res = await fetch("https://discord.com/api/oauth2/token", {
 method:"POST",
 headers:{ "Content-Type":"application/x-www-form-urlencoded" },
 body
 });

 if (!res.ok) throw new Error("Discord token exchange failed.");
 return res.json();
}
async function fetchDiscordUser(accessToken){
 const res = await fetch("https://discord.com/api/users/@me", { headers:{ Authorization:`Bearer ${accessToken}` } });
 if (!res.ok) throw new Error("Failed to fetch Discord user.");
 return res.json();
}
async function handleDiscordRedirectIfAny(){
 const url = new URL(window.location.href);
 const code = url.searchParams.get("code");
 const state = url.searchParams.get("state");
 const oauthErr = url.searchParams.get("error");

 if (oauthErr) {
 showError("Discord login canceled/failed.");
 url.searchParams.delete("error");
 window.history.replaceState({}, "", url.toString());
 return;
 }
 if (!code) return;

 const expectedState = sessionStorage.getItem(DISCORD.stateKey);
 if (!expectedState || state !== expectedState) {
 showError("Discord state mismatch. Try again.");
 return;
 }

 try {
 setStatus("Finishing Discord connect...", "");
 const token = await exchangeCodeForToken(code);
 const user = await fetchDiscordUser(token.access_token);
 saveDiscordSession({ access_token: token.access_token, token_type: token.token_type, scope: token.scope, expires_in: token.expires_in, obtained_at: Date.now(), user });
 
 // Queue audit: Discord linked (will flush after Firebase auth)
 queueAuditLog("discord_link", {
  discordId: user.id,
  username: user.username || null,
  globalName: user.global_name || null,
  discriminator: user.discriminator || null
 });

 setStatus("Discord connected.", "ok");
 } catch(e) {
 console.error(e);
 showError(e?.message || "Discord connect failed.");
 } finally {
 url.searchParams.delete("code");
 url.searchParams.delete("state");
 url.searchParams.delete("error");
 window.history.replaceState({}, "", url.toString());
 }
}

// Firebase actions
async function doLogin(email, pass){
 setStatus("Logging in...", "");
 const cred = await signInWithEmailAndPassword(auth, email, pass);
 return cred.user;
}
async function doCreate(email, pass){
 const discord = getDiscordSession();
 if (!isDiscordSessionValid(discord) || !discord?.user?.id) throw new Error("Discord login required. Click CONNECT DISCORD first.");

 setStatus("Creating account...", "");
 const cred = await createUserWithEmailAndPassword(auth, email, pass);

 await setDoc(doc(db, "users", cred.user.uid), {
 email: cred.user.email,
 emailLower: (cred.user.email||'').toLowerCase(),
 createdAt: serverTimestamp(),
 discordId: String(discord.user.id),
 discord: {
 id: String(discord.user.id),
 username: discord.user.username ?? null,
 global_name: discord.user.global_name ?? null,
 email: discord.user.email ?? null,
 verified: discord.user.verified ?? null,
 avatar: discord.user.avatar ?? null
 }
 }, { merge:true });

 return cred.user;
}
async function doForgot(email){
 setStatus("Sending reset email...", "");
 await sendPasswordResetEmail(auth, email);
}

// Events
btnDiscord.addEventListener("click", async () => {
 const s = getDiscordSession();
 const connected = isDiscordSessionValid(s) && s?.user?.id;
 if (connected) {
 if (confirm("Disconnect Discord?")) {
   queueAuditLog("discord_unlink", {
     discordId: s?.user?.id || null,
     username: s?.user?.username || null,
     discriminator: s?.user?.discriminator || null
   });
   clearDiscordSession();
 }
 return;
 }
 await startDiscordLogin();
});
btnForgot.addEventListener("click", async () => {
 clearError();
 const email = getEmail();
 if (!isValidEmail(email)) return showError("Enter a valid email to reset password.");
 try { await doForgot(email); setStatus("Password reset email sent.", "ok"); }
 catch(e){ console.error(e); showError(e?.message || "Failed to send reset email."); }
});
authForm.addEventListener("submit", async (ev) => {
 ev.preventDefault();
 clearError();

 const emailRaw = getEmail();
 const passRaw = getPass();
 if (!isValidEmail(emailRaw)) return showError("Enter a valid email.");
 if (!passRaw || passRaw.length < 6) return showError("Password must be at least 6 characters.");
 const email = emailRaw.toLowerCase();

 try {
  let licRes = null;
  if (mode === "create") {
    const lk = (licenseKeyEl?.value || "").trim();
    if (!lk) { setStatus("License key required"); return; }
    licRes = await verifyLicenseKey(lk, email);
    if (!licRes.ok) { setStatus(licRes.reason || "License invalid"); return; }
  }
  const user = mode === "login" ? await doLogin(email, passRaw) : await doCreate(email, passRaw);
  if (mode === "create" && user && licRes?.ok) {
    await consumeLicenseKey(licRes.key, user.uid, email, licRes.hwid);
  }

  // Flush any queued audit logs (e.g., Discord link/unlink)
  try { await flushPendingAuditLogs(user); } catch (e) { console.warn("Audit flush failed", e); }

 setStatus(`Success. Logged in as ${user.email}`, "ok");
 // ✅ go to dashboard
 window.location.href = "./dashboard.html";
 } catch(e) {
 console.error(e);
 showError(e?.message || "Auth failed.");
 }
});
btnLogout.addEventListener("click", async () => {
 await signOut(auth);
 clearDiscordSession();
 setStatus("Logged out.", "");
});
onAuthStateChanged(auth, (user) => {
 btnLogout.style.display = user ? "inline-block" : "none";
});

// Init
setMode("login");
btnLogout.style.display = "none";
await handleDiscordRedirectIfAny();
refreshCreateGateUI();