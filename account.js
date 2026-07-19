/* ==========================================================================
   Pnyx — Compte partagé (à inclure sur toutes les pages avec la CDN Supabase)
   Requiert dans la page :
     • <span id="nav-account" class="nav-account"></span> dans la barre du haut
     • <script src="https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2"></script>
     • <link rel="stylesheet" href="account.css">
   Rend le bouton Connexion / Créer un compte (déconnecté) ou le menu du pseudo
   (stats, changer pseudo, changer mot de passe, déconnexion, supprimer profil).
   La session est commune à toutes les pages (même projet Supabase).
   ========================================================================== */
(function () {
  "use strict";
  var SUPABASE_URL = "https://wdxjlbsnqmybcdpzwnhs.supabase.co";
  var SUPABASE_ANON_KEY = "sb_publishable_F9beVTRpaUTKtZNjYHrhSw_hq4Obiv7";
  var REDIRECT = location.origin + location.pathname;

  var box = document.getElementById("nav-account");
  if (!box || !window.supabase) return;
  var sb = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
  window.pnyxSB = sb;

  var me = null, profile = null, stats = { posts: 0, received: 0, given: 0 }, mode = "login";

  function lang() { return document.documentElement.getAttribute("data-lang") === "en" ? "en" : "fr"; }
  var T = {
    fr: { login: "Connexion", signup: "Créer un compte", logout: "Déconnexion",
      email: "Courriel", password: "Mot de passe", pseudo: "Pseudo (affiché publiquement)",
      newPassword: "Nouveau mot de passe", setPassword: "Enregistrer le mot de passe",
      forgot: "Mot de passe oublié ?", send: "Envoyer le lien",
      enterEmailReset: "Entre ton courriel : tu recevras un lien pour choisir un nouveau mot de passe.",
      resetSent: "Courriel envoyé ✓ — vérifie ta boîte de réception.", pwChanged: "Mot de passe modifié ✓",
      changePw: "Changer le mot de passe", changePseudo: "Changer le pseudo", save: "Enregistrer", saved: "Enregistré ✓",
      delProfile: "Supprimer mon profil", profileDeleted: "Profil supprimé. À bientôt !",
      confirmDelProfile: "Supprimer ton compte et TOUTES tes demandes, réponses et votes ? C'est irréversible.",
      haveAccount: "Déjà un compte ? Connexion", noAccount: "Pas de compte ? Créer un compte",
      checkEmail: "Compte créé ! Vérifie ton courriel pour confirmer, puis connecte-toi.",
      dev: "Développeur", fill: "Remplis tous les champs.", pwLen: "Le mot de passe doit faire au moins 6 caractères.",
      statPosts: "demandes publiées", statReceived: "votes reçus ❤", statGiven: "votes donnés",
      welcome: "Bienvenue !", welcomeBack: "Content de te revoir !", signedOut: "Déconnecté" },
    en: { login: "Log in", signup: "Create account", logout: "Log out",
      email: "Email", password: "Password", pseudo: "Nickname (shown publicly)",
      newPassword: "New password", setPassword: "Save password",
      forgot: "Forgot password?", send: "Send link",
      enterEmailReset: "Enter your email: you'll get a link to choose a new password.",
      resetSent: "Email sent ✓ — check your inbox.", pwChanged: "Password changed ✓",
      changePw: "Change password", changePseudo: "Change nickname", save: "Save", saved: "Saved ✓",
      delProfile: "Delete my account", profileDeleted: "Account deleted. See you soon!",
      confirmDelProfile: "Delete your account and ALL your posts, replies and votes? This cannot be undone.",
      haveAccount: "Already have an account? Log in", noAccount: "No account? Create one",
      checkEmail: "Account created! Check your email to confirm, then log in.",
      dev: "Developer", fill: "Fill in every field.", pwLen: "Password must be at least 6 characters.",
      statPosts: "requests posted", statReceived: "votes received ❤", statGiven: "votes given",
      welcome: "Welcome!", welcomeBack: "Welcome back!", signedOut: "Signed out" }
  };
  function tr(k) { return T[lang()][k]; }

  function el(tag, attrs) {
    var n = document.createElement(tag), i, k;
    if (attrs) for (k in attrs) {
      if (k === "class") n.className = attrs[k];
      else if (k === "text") n.textContent = attrs[k];
      else if (k.slice(0, 2) === "on") n.addEventListener(k.slice(2), attrs[k]);
      else if (attrs[k] != null) n.setAttribute(k, attrs[k]);
    }
    for (i = 2; i < arguments.length; i++) {
      var c = arguments[i]; if (c == null) continue;
      n.appendChild(typeof c === "string" ? document.createTextNode(c) : c);
    }
    return n;
  }

  var toastEl;
  function toast(msg) {
    if (!toastEl) { toastEl = el("div", { class: "pnyx-toast" }); document.body.appendChild(toastEl); }
    toastEl.textContent = msg; toastEl.classList.add("show");
    setTimeout(function () { toastEl.classList.remove("show"); }, 2200);
  }

  /* --- Fenêtre modale --- */
  var overlay = el("div", { class: "pnyx-modal", hidden: true });
  var cardEl = el("div", { class: "pnyx-modal-card" });
  overlay.appendChild(cardEl);
  overlay.addEventListener("click", function (e) { if (e.target === overlay) closeModal(); });
  document.body.appendChild(overlay);
  function openModal() { overlay.hidden = false; }
  function closeModal() { overlay.hidden = true; }

  function pwField(id) {
    var wrap = el("div", { class: "pw-wrap" });
    var inp = el("input", { type: "password", id: id, autocomplete: "current-password" });
    wrap.appendChild(inp);
    var eye = el("button", { class: "pw-eye", type: "button", "aria-label": "Afficher / masquer",
      onclick: function () { var h = inp.type === "password"; inp.type = h ? "text" : "password"; eye.textContent = h ? "🙈" : "👁"; } }, "👁");
    wrap.appendChild(eye);
    var lab = el("label", { class: "acct-fld" }, el("span", { text: tr("password") }));
    lab.appendChild(wrap); return lab;
  }
  function txtField(id, type, label, val) {
    var lab = el("label", { class: "acct-fld" }, el("span", { text: label }));
    var inp = el("input", { type: type, id: id, maxlength: type === "text" ? "40" : null });
    if (val) inp.value = val;
    lab.appendChild(inp); return lab;
  }

  function renderForm() {
    cardEl.textContent = "";
    cardEl.appendChild(el("button", { class: "pnyx-modal-x", "aria-label": "Fermer", onclick: closeModal }, "×"));
    var title = mode === "signup" ? tr("signup") : mode === "forgot" ? tr("forgot")
      : mode === "setpw" ? tr("newPassword") : mode === "pseudo" ? tr("changePseudo") : tr("login");
    cardEl.appendChild(el("h2", { text: title }));

    if (mode === "setpw") {
      var np = el("input", { type: "password", id: "ac-newpass", autocomplete: "new-password" });
      var w = el("div", { class: "pw-wrap" }); w.appendChild(np);
      var ey = el("button", { class: "pw-eye", type: "button",
        onclick: function () { var h = np.type === "password"; np.type = h ? "text" : "password"; ey.textContent = h ? "🙈" : "👁"; } }, "👁");
      w.appendChild(ey);
      var l = el("label", { class: "acct-fld" }, el("span", { text: tr("newPassword") })); l.appendChild(w);
      cardEl.appendChild(l);
    } else if (mode === "pseudo") {
      cardEl.appendChild(txtField("ac-pseudo2", "text", tr("pseudo"), profile ? profile.pseudo : ""));
    } else if (mode === "forgot") {
      cardEl.appendChild(el("p", { class: "acct-muted", text: tr("enterEmailReset") }));
      cardEl.appendChild(txtField("ac-email", "email", tr("email")));
    } else {
      if (mode === "signup") cardEl.appendChild(txtField("ac-pseudo", "text", tr("pseudo")));
      cardEl.appendChild(txtField("ac-email", "email", tr("email")));
      cardEl.appendChild(pwField("ac-pass"));
      if (mode === "login")
        cardEl.appendChild(el("button", { class: "acct-link", text: tr("forgot"), onclick: function () { mode = "forgot"; renderForm(); } }));
    }

    var err = el("p", { class: "acct-err", id: "ac-err", hidden: true });
    cardEl.appendChild(err);
    var submitLabel = mode === "signup" ? tr("signup") : mode === "forgot" ? tr("send")
      : mode === "setpw" ? tr("setPassword") : mode === "pseudo" ? tr("save") : tr("login");
    var actions = el("div", { class: "acct-actions" });
    actions.appendChild(el("button", { class: "acct-submit", id: "ac-submit", text: submitLabel, onclick: doAuth }));
    if (mode === "login" || mode === "signup")
      actions.appendChild(el("button", { class: "acct-link", text: mode === "signup" ? tr("haveAccount") : tr("noAccount"), onclick: function () { mode = mode === "login" ? "signup" : "login"; renderForm(); } }));
    cardEl.appendChild(actions);
  }
  function showErr(m) { var e = document.getElementById("ac-err"); if (e) { e.textContent = m; e.hidden = false; } }

  async function doAuth() {
    var e = document.getElementById("ac-err"); if (e) e.hidden = true;
    var btn = document.getElementById("ac-submit"); if (btn) btn.disabled = true;
    try {
      if (mode === "setpw") {
        var np = (document.getElementById("ac-newpass") || {}).value || "";
        if (np.length < 6) { showErr(tr("pwLen")); return; }
        var r1 = await sb.auth.updateUser({ password: np });
        if (r1.error) throw r1.error;
        history.replaceState(null, "", location.pathname); closeModal(); toast(tr("pwChanged")); return;
      }
      if (mode === "pseudo") {
        var nps = ((document.getElementById("ac-pseudo2") || {}).value || "").trim();
        if (!nps) { showErr(tr("fill")); return; }
        var r2 = await sb.from("profiles").update({ pseudo: nps }).eq("id", me.id);
        if (r2.error) throw r2.error;
        profile.pseudo = nps; closeModal(); renderNav(); toast(tr("saved"));
        window.dispatchEvent(new CustomEvent("pnyx-auth", { detail: { me: me, profile: profile } })); return;
      }
      var email = ((document.getElementById("ac-email") || {}).value || "").trim();
      if (mode === "forgot") {
        if (!email) { showErr(tr("fill")); return; }
        var r3 = await sb.auth.resetPasswordForEmail(email, { redirectTo: REDIRECT });
        if (r3.error) throw r3.error;
        toast(tr("resetSent")); mode = "login"; renderForm(); return;
      }
      var pass = (document.getElementById("ac-pass") || {}).value || "";
      if (!email || !pass) { showErr(tr("fill")); return; }
      if (mode === "signup") {
        var pseudo = ((document.getElementById("ac-pseudo") || {}).value || "").trim() || email.split("@")[0];
        var r4 = await sb.auth.signUp({ email: email, password: pass, options: { data: { pseudo: pseudo }, emailRedirectTo: REDIRECT } });
        if (r4.error) throw r4.error;
        if (!r4.data.session) { toast(tr("checkEmail")); mode = "login"; renderForm(); } else { closeModal(); toast(tr("welcome")); }
      } else {
        var r5 = await sb.auth.signInWithPassword({ email: email, password: pass });
        if (r5.error) throw r5.error;
        closeModal(); toast(tr("welcomeBack"));
      }
    } catch (ex) { showErr(humanErr(ex)); }
    finally { var b = document.getElementById("ac-submit"); if (b) b.disabled = false; }
  }
  function humanErr(ex) {
    var m = (ex && ex.message || "").toLowerCase();
    if (m.indexOf("already registered") >= 0) return lang() === "en" ? "This email already has an account." : "Ce courriel a déjà un compte.";
    if (m.indexOf("invalid login") >= 0) return lang() === "en" ? "Wrong email or password." : "Courriel ou mot de passe incorrect.";
    if (m.indexOf("at least 6") >= 0 || m.indexOf("password") >= 0) return tr("pwLen");
    return ex && ex.message ? ex.message : (lang() === "en" ? "Something went wrong." : "Une erreur est survenue.");
  }

  async function deleteMyProfile() {
    if (!confirm(tr("confirmDelProfile"))) return;
    var r = await sb.rpc("delete_my_account");
    if (r.error) { toast(r.error.message); return; }
    await sb.auth.signOut(); toast(tr("profileDeleted"));
  }

  /* --- Menu du compte --- */
  function toggleMenu() { var m = document.getElementById("ac-menu"); if (m) m.hidden = !m.hidden; }
  function closeMenu() { var m = document.getElementById("ac-menu"); if (m) m.hidden = true; }
  document.addEventListener("click", closeMenu);

  function renderNav() {
    box.textContent = "";
    if (me && profile) {
      var btn = el("button", { class: "acct-btn", "aria-haspopup": "true",
        onclick: function (e) { e.stopPropagation(); toggleMenu(); } });
      btn.appendChild(el("strong", { text: profile.pseudo }));
      if (profile.is_admin) btn.appendChild(el("span", { class: "acct-badge-dev", text: tr("dev") }));
      btn.appendChild(document.createTextNode(" ▾"));
      box.appendChild(btn);
      var menu = el("div", { class: "acct-menu", id: "ac-menu", hidden: true });
      var st = el("div", { class: "acct-stats" });
      st.appendChild(el("div", null, el("strong", { text: String(stats.posts) }), tr("statPosts")));
      st.appendChild(el("div", null, el("strong", { text: String(stats.received) }), tr("statReceived")));
      st.appendChild(el("div", null, el("strong", { text: String(stats.given) }), tr("statGiven")));
      menu.appendChild(st);
      menu.appendChild(el("div", { class: "sep" }));
      menu.appendChild(el("button", { text: tr("changePseudo"), onclick: function () { closeMenu(); mode = "pseudo"; renderForm(); openModal(); } }));
      menu.appendChild(el("button", { text: tr("changePw"), onclick: function () { closeMenu(); mode = "setpw"; renderForm(); openModal(); } }));
      menu.appendChild(el("div", { class: "sep" }));
      menu.appendChild(el("button", { text: tr("logout"), onclick: async function () { closeMenu(); await sb.auth.signOut(); toast(tr("signedOut")); } }));
      menu.appendChild(el("button", { class: "danger", text: tr("delProfile"), onclick: function () { closeMenu(); deleteMyProfile(); } }));
      box.appendChild(menu);
    } else {
      box.appendChild(el("button", { class: "acct-btn", text: tr("login"), onclick: function () { mode = "login"; renderForm(); openModal(); } }));
      box.appendChild(el("button", { class: "acct-btn primary", text: tr("signup"), onclick: function () { mode = "signup"; renderForm(); openModal(); } }));
    }
  }

  async function fetchStats() {
    if (!me) { stats = { posts: 0, received: 0, given: 0 }; return; }
    try {
      var mine = await sb.from("posts").select("votes(count)").eq("author_id", me.id);
      var rows = mine.data || [];
      var received = rows.reduce(function (s, p) { return s + (p.votes && p.votes[0] ? p.votes[0].count : 0); }, 0);
      var given = await sb.from("votes").select("post_id", { count: "exact", head: true }).eq("user_id", me.id);
      stats = { posts: rows.length, received: received, given: given.count || 0 };
    } catch (e) { stats = { posts: 0, received: 0, given: 0 }; }
  }

  async function onSession(session) {
    me = session ? session.user : null; profile = null;
    if (me) {
      var p = await sb.from("profiles").select("id,pseudo,is_admin").eq("id", me.id).maybeSingle();
      profile = p.data || { id: me.id, pseudo: (me.email || "").split("@")[0], is_admin: false };
      await fetchStats();
    }
    renderNav();
    window.pnyxAuth = { me: me, profile: profile };
    window.dispatchEvent(new CustomEvent("pnyx-auth", { detail: { me: me, profile: profile } }));
  }

  sb.auth.onAuthStateChange(function (e, s) { if (e === "PASSWORD_RECOVERY") { mode = "setpw"; renderForm(); openModal(); } onSession(s); });
  sb.auth.getSession().then(function (r) { onSession(r.data.session); });
  if (/type=recovery/.test(location.hash)) { mode = "setpw"; renderForm(); openModal(); }

  new MutationObserver(function () { renderNav(); }).observe(document.documentElement, { attributes: true, attributeFilter: ["data-lang"] });
})();
