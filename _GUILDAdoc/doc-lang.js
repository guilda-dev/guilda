// Japanese/English switch for the developer docs.
// Load in <head> so the language is set before first paint. Translatable content
// is written as sibling elements with lang="en" and lang="ja"; style.css hides the
// inactive one based on <html data-lang>. See developer/project-management.html#bilingual.
//
// The choice is kept in three places, because none of them works everywhere:
// - the ?lang= query of the page URL, which links to other doc pages carry
//   (Safari and Firefox keep a separate localStorage per file:// page);
// - window.name, which stays with the tab across pages, also over file://;
// - localStorage, shared by all pages of one http origin.
// Back/forward and reload trust the last choice over the (possibly stale) query.
(function () {
  'use strict';

  const STORAGE_KEY = 'guilda-doc-lang';
  const NAME_KEY = 'guilda-doc-lang=';
  const LANGS = ['en', 'ja'];
  const root = document.documentElement;
  // Folder of this script = documentation root; only links inside it carry ?lang=.
  const docRoot = new URL('.', document.currentScript?.src || window.location.href).href;
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

  // window.name may hold other ";"-separated entries; only ours is touched.
  function readWindowName() {
    try {
      const entry = (window.name || '').split(';').find((part) => part.startsWith(NAME_KEY));
      return entry ? normalize(entry.slice(NAME_KEY.length)) : null;
    } catch (e) { return null; }
  }

  function storeWindowName(lang) {
    try {
      const others = (window.name || '').split(';').filter((part) => part && !part.startsWith(NAME_KEY));
      window.name = others.concat(NAME_KEY + lang).join(';');
    } catch (e) { /* window.name unavailable */ }
  }

  // Keep ?lang= of the current URL equal to the shown language, so reload,
  // bookmarks and the history entry left behind open in the same language.
  function syncUrl(lang) {
    try {
      const url = new URL(window.location.href);
      if (url.searchParams.get('lang') === lang) return;
      url.searchParams.set('lang', lang);
      window.history.replaceState(window.history.state, '', url.href);
    } catch (e) { /* history unavailable */ }
  }

  function remember(lang) {
    store(lang);
    storeWindowName(lang);
    syncUrl(lang);
  }

  function navigationType() {
    try { return window.performance.getEntriesByType('navigation')[0]?.type || 'navigate'; } catch (e) { return 'navigate'; }
  }

  function resolve(fromHistory) {
    return fromHistory
      ? readWindowName() || readStored() || readQuery() || 'en'
      : readQuery() || readWindowName() || readStored() || 'en';
  }

  // URL of a doc page link with ?lang= set, or null when the link stays as it
  // is: outside the doc root, not an HTML page, or already right. A link to
  // this same page without a query gets the current one, so following it
  // only moves to the fragment instead of reloading the page.
  function langUrl(href, lang) {
    let url;
    try { url = new URL(href, window.location.href); } catch (e) { return null; }
    if (!url.href.startsWith(docRoot)) return null;
    if (!/\.html?$/i.test(url.pathname) && !url.pathname.endsWith('/')) return null;
    const here = new URL(window.location.href);
    if (url.origin === here.origin && url.pathname === here.pathname && !url.search) url.search = here.search;
    url.searchParams.set('lang', lang);
    return url.href === href ? null : url.href;
  }

  // Links are rewritten just before they are followed, so links that page
  // scripts add later are covered too. pointerdown/focusin also cover
  // middle-click, "open in new tab" and keyboard activation.
  function rewriteLink(event) {
    const link = event.target?.closest?.('a[href]');
    if (!link || typeof link.href !== 'string' || link.hasAttribute('download')) return;
    const href = langUrl(link.href, root.dataset.lang);
    if (href) link.href = href;
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
    remember(lang);
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

  function onReady() {
    applyTitle(root.dataset.lang);
    insertToggle();
  }

  const initial = resolve(['back_forward', 'reload'].includes(navigationType()));
  apply(initial);
  remember(initial);

  window.GUILDA_LANG = {
    get: () => root.dataset.lang,
    set,
    // Same-site page URL with the current language, for scripts that navigate.
    url: (href) => langUrl(href, root.dataset.lang) || new URL(href, window.location.href).href
  };

  ['click', 'auxclick', 'contextmenu', 'pointerdown', 'focusin'].forEach((type) => {
    document.addEventListener(type, rewriteLink, true);
  });

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', onReady);
  } else {
    onReady();
  }

  // A page restored from the back/forward cache still shows the language it
  // had when it was left; switch it to the last choice.
  window.addEventListener('pageshow', (event) => {
    if (!event.persisted) return;
    const lang = resolve(true);
    remember(lang);
    if (lang !== root.dataset.lang) {
      apply(lang);
      document.dispatchEvent(new CustomEvent('guilda-langchange', { detail: { lang } }));
    }
  });

  // Back/forward within the page lands on an entry whose URL may hold an older ?lang=.
  window.addEventListener('popstate', () => syncUrl(root.dataset.lang));

  // Keep other open tabs in step with the saved choice.
  window.addEventListener('storage', (event) => {
    if (event.key !== STORAGE_KEY) return;
    const lang = normalize(event.newValue);
    if (lang && lang !== root.dataset.lang) {
      storeWindowName(lang);
      syncUrl(lang);
      apply(lang);
      document.dispatchEvent(new CustomEvent('guilda-langchange', { detail: { lang } }));
    }
  });
})();
