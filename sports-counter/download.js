/* Bouton « Télécharger » : lien direct vers l'installateur de la dernière
   version publiée sur GitHub, et son numéro affiché sous le bouton.
   Sans réponse de GitHub, le bouton garde son lien vers la page des versions. */
(function () {
  var buttons = document.querySelectorAll('[data-download]');
  var version = document.querySelectorAll('[data-version]');
  if (!buttons.length || !window.fetch) return;
  fetch('https://api.github.com/repos/Mede2026/Sports-Counter/releases/latest', {
    headers: { Accept: 'application/vnd.github+json' },
  })
    .then(function (r) { return r.ok ? r.json() : null; })
    .then(function (rel) {
      if (!rel) return;
      var exe = (rel.assets || []).filter(function (a) { return /-setup\.exe$/i.test(a.name); })[0];
      if (exe) buttons.forEach(function (b) { b.href = exe.browser_download_url; });
      var tag = String(rel.tag_name || '').replace(/^v/, '');
      if (tag) version.forEach(function (v) { v.textContent = ' · version ' + tag; });
    })
    .catch(function () { /* pas de réseau : lien vers la page des versions */ });
})();
