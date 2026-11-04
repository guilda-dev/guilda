// Japanese/English switch for the developer docs.
// Load in <head> so the language is set before first paint. Translatable content
// is written as sibling elements with lang="en" and lang="ja"; style.css hides the
// inactive one based on <html data-lang>. See developer/project-management.html#bilingual.
(function () {
  'use strict';

  const STORAGE_KEY = 'guilda-doc-lang';
  const LANGS = ['en', 'ja'];
  const root = document.documentElement;
  let englishTitle = null;

  function normalize(value) {
    return LANGS.includes(value) ? value : null;
  }

  function readStored() {
    try { return normalize(window.localStorage.getItem(STORAGE_KEY)); } catch (e) { return null; }
  }

  function store(lang) {
    try { window.localStorage.setItem(STORAGE_KEY, lang); } catch (e) { /* storage unavailable */ }
  }

  function readQuery() {
    try { return normalize(new URLSearchParams(window.location.search).get('lang')); } catch (e) { return null; }
  }

  // <title data-title-ja="..."> gives the Japanese title; the original text is the English one.
  // A page that sets its title from data also sets data-title-en.
  function applyTitle(lang) {
    const titleEl = document.querySelector('head > title');
    if (!titleEl) return;
    if (englishTitle === null) englishTitle = titleEl.textContent;
    const en = titleEl.getAttribute('data-title-en') || englishTitle;
    const ja = titleEl.getAttribute('data-title-ja');
    document.title = lang === 'ja' && ja ? ja : en;
  }

  function syncToggle(lang) {
    document.querySelectorAll('.doc-lang-toggle [data-set-lang]').forEach((button) => {
      button.setAttribute('aria-pressed', String(button.getAttribute('data-set-lang') === lang));
    });
  }

  function apply(lang) {
    root.dataset.lang = lang;
    root.lang = lang;
    applyTitle(lang);
    syncToggle(lang);
  }

  function set(value) {
    const lang = normalize(value);
    if (!lang) return;
    store(lang);
    if (lang === root.dataset.lang) return;
    apply(lang);
    document.dispatchEvent(new CustomEvent('guilda-langchange', { detail: { lang } }));
  }

  function insertToggle() {
    if (document.querySelector('.doc-lang-toggle')) return;
    const toggle = document.createElement('div');
    toggle.className = 'doc-lang-toggle';
    toggle.setAttribute('role', 'group');
    toggle.setAttribute('aria-label', 'Language / 言語');
    toggle.innerHTML =
      '<button type="button" data-set-lang="en">EN</button>' +
      '<span class="doc-lang-sep" aria-hidden="true">|</span>' +
      '<button type="button" data-set-lang="ja">日本語</button>';
    toggle.addEventListener('click', (event) => {
      const button = event.target.closest('[data-set-lang]');
      if (button) set(button.getAttribute('data-set-lang'));
    });
    document.body.appendChild(toggle);
    syncToggle(root.dataset.lang);
  }

  const queryLang = readQuery();
  if (queryLang) store(queryLang);
  apply(queryLang || readStored() || 'en');

  window.GUILDA_LANG = {
    get: () => root.dataset.lang,
    set
  };

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', () => { applyTitle(root.dataset.lang); insertToggle(); });
  } else {
    insertToggle();
  }

  // Keep other open tabs in step with the saved choice.
  window.addEventListener('storage', (event) => {
    if (event.key !== STORAGE_KEY) return;
    const lang = normalize(event.newValue);
    if (lang && lang !== root.dataset.lang) {
      apply(lang);
      document.dispatchEvent(new CustomEvent('guilda-langchange', { detail: { lang } }));
    }
  });
})();
