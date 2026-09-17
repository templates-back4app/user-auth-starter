// Stack: vanilla JavaScript (browser) | File: web/app.js
// Six REST calls do all of "auth": POST /users, POST /login, GET /users/me, POST /requestPasswordReset,
// POST /verificationEmailRequest, POST /logout. The session token is the only state the page keeps.

const BASE = window.BACKEND_URL ?? "https://parseapi.back4app.com";
const HEADERS = {
  "X-Parse-Application-Id": window.APP_ID,
  "X-Parse-JavaScript-Key": window.JS_KEY,      // a client key: it identifies the app, not the user
  "X-Parse-Revocable-Session": "1",
  "Content-Type": "application/json",
};

// The token lives in sessionStorage: gone when the tab closes, unreachable from other origins.
const session = {
  get: () => sessionStorage.getItem("sessionToken"),
  set: (t) => sessionStorage.setItem("sessionToken", t),
  clear: () => sessionStorage.removeItem("sessionToken"),
};

async function api(method, path, body, token) {
  const headers = { ...HEADERS };
  if (token) headers["X-Parse-Session-Token"] = token;
  const r = await fetch(BASE + path, { method, headers, body: body ? JSON.stringify(body) : undefined });
  const data = r.status === 204 ? {} : await r.json();
  if (!r.ok) throw Object.assign(new Error(data.error ?? r.statusText), { code: data.code, status: r.status });
  return data;
}

const $ = (s) => document.querySelector(s);
const status = (msg, kind = "") => { $("#status").textContent = msg; $("#status").className = kind; };
const fields = (form) => Object.fromEntries(new FormData(form));

async function showMe() {
  const token = session.get();
  if (!token) { $("#anon").hidden = false; $("#me").hidden = true; return; }
  try {
    const me = await api("GET", "/users/me", null, token);     // validates the token on every call
    $("#user").textContent = JSON.stringify({ username: me.username, email: me.email, emailVerified: me.emailVerified ?? false, createdAt: me.createdAt }, null, 2);
    $("#anon").hidden = true; $("#me").hidden = false;
  } catch (err) {
    session.clear(); $("#anon").hidden = false; $("#me").hidden = true;
    status(`session rejected: ${err.code} ${err.message}`, "err");
  }
}

$("#signup").addEventListener("submit", async (e) => {
  e.preventDefault();
  try {
    const t0 = performance.now();
    const u = await api("POST", "/users", fields(e.target));       // 201 {objectId, createdAt, sessionToken}
    session.set(u.sessionToken);
    status(`signed up in ${Math.round(performance.now() - t0)} ms — check your inbox for the verification e-mail`, "ok");
    e.target.reset(); showMe();
  } catch (err) { status(`${err.code} ${err.message}`, "err"); }
});

$("#login").addEventListener("submit", async (e) => {
  e.preventDefault();
  try {
    const t0 = performance.now();
    const u = await api("POST", "/login", fields(e.target));        // 200 {…, sessionToken}
    session.set(u.sessionToken);
    status(`logged in in ${Math.round(performance.now() - t0)} ms`, "ok");
    e.target.reset(); showMe();
  } catch (err) { status(`${err.code} ${err.message}`, "err"); }
});

$("#reset").addEventListener("submit", async (e) => {
  e.preventDefault();
  try {
    await api("POST", "/requestPasswordReset", fields(e.target));   // 200 {} whether or not the e-mail exists
    status("if that address has an account, a reset e-mail is on its way", "ok");
  } catch (err) { status(`${err.code} ${err.message}`, "err"); }
});

$("#verify").addEventListener("click", async () => {
  try {
    const me = await api("GET", "/users/me", null, session.get());
    await api("POST", "/verificationEmailRequest", { email: me.email });
    status("verification e-mail sent again", "ok");
  } catch (err) { status(`${err.code} ${err.message}`, "err"); }
});

$("#refresh").addEventListener("click", showMe);

$("#logout").addEventListener("click", async () => {
  try { await api("POST", "/logout", null, session.get()); } catch {}   // revokes the token server-side
  session.clear(); status("logged out — the token is revoked, not just forgotten", "ok"); showMe();
});

showMe();
