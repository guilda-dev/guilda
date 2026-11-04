// Side menus for the developer pages on wide screens, loaded by doc-lang.js.
// Builds a page list from database/list_developer.js and an "On this page" list
// from the page's <nav class="dev-toc">. style.css shows them only where there is
// room beside the main column; narrower screens keep the inline .dev-toc.
(function () {
  'use strict';

  if (window.GuildaDocNav) return;
  window.GuildaDocNav = {};

  const docRoot = new URL('.', document.currentScript?.src || window.location.href).href;

  function escapeHtml(value) {
    return String(value ?? '')
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;');
  }

  function bilingual(en, ja) {
    return `<span lang="en">${escapeHtml(en)}</span><span lang="ja">${escapeHtml(ja || en)}</span>`;
  }

  // list_developer.js declares a global const, so it is loaded at most once.
  function loadPages() {
    if (typeof developerData !== 'undefined') return Promise.resolve(developerData);
    return new Promise((resolve) => {
      const script = document.createElement('script');
      script.src = new URL('database/list_developer.js', docRoot).href;
      script.onload = () => resolve(typeof developerData !== 'undefined' ? developerData : null);
      script.onerror = () => resolve(null);
      document.head.appendChild(script);
    });
  }

  // "Coding: Naming Conventions" -> group "Coding", title "Naming Conventions".
  function splitTitle(value) {
    const match = /^([^:]+):\s*(.*)$/.exec(value || '');
    return match ? { group: match[1].trim(), title: match[2] } : { group: '', title: value || '' };
  }

  function samePage(href) {
    const target = new URL(href, docRoot);
    return target.origin === window.location.origin && target.pathname === window.location.pathname;
  }

  // Groups are keyed on the English prefix, as on the For Developer tab.
  function pageListHtml(pages) {
    const groups = [];
    pages.forEach((item) => {
      const en = splitTitle(item.title);
      const ja = splitTitle(item.title_ja || item.title);
      let group = groups.find((g) => g.key === en.group);
      if (!group) { group = { key: en.group, en: en.group, ja: ja.group, items: [] }; groups.push(group); }
      group.items.push({ link: item.link, en: en.title, ja: ja.title });
    });
    return groups.map((group) => `
      <div class="doc-side-group">
        ${group.key ? `<p class="doc-side-label">${bilingual(group.en, group.ja)}</p>` : ''}
        <ul>
          ${group.items.map((item) => {
            const href = new URL(item.link, docRoot).href;
            const current = samePage(href) ? ' class="is-current" aria-current="page"' : '';
            return `<li><a href="${escapeHtml(href)}"${current}>${bilingual(item.en, item.ja)}</a></li>`;
          }).join('')}
        </ul>
      </div>`).join('');
  }

  function buildToc(sourceToc) {
    const nav = document.createElement('nav');
    nav.className = 'doc-side-toc';
    nav.setAttribute('aria-label', 'On this page');
    nav.innerHTML = `<p class="doc-side-label">${bilingual('On this page', '目次')}</p><ul></ul>`;
    const list = nav.querySelector('ul');
    sourceToc.querySelectorAll('a[href^="#"]').forEach((link) => {
      const item = document.createElement('li');
      const copy = link.cloneNode(true);
      copy.removeAttribute('id');
      item.appendChild(copy);
      list.appendChild(item);
    });
    return list.children.length ? nav : null;
  }

  // Highlight the last section whose heading has scrolled past the top band.
  function trackSections(toc) {
    const entries = [...toc.querySelectorAll('a')].map((link) => {
      let target = null;
      try { target = document.getElementById(decodeURIComponent(link.hash.slice(1))); } catch (e) { /* bad hash */ }
      return { link, target };
    }).filter((entry) => entry.target);
    if (!entries.length) return;

    let scheduled = false;
    const update = () => {
      scheduled = false;
      const band = Math.min(160, window.innerHeight * 0.3);
      let active = entries[0];
      entries.forEach((entry) => {
        if (entry.target.getBoundingClientRect().top <= band) active = entry;
      });
      const atEnd = window.innerHeight + window.scrollY >= document.documentElement.scrollHeight - 2;
      if (atEnd) active = entries[entries.length - 1];
      entries.forEach((entry) => {
        entry.link.classList.toggle('is-active', entry === active);
        if (entry === active) entry.link.setAttribute('aria-current', 'location');
        else entry.link.removeAttribute('aria-current');
      });
    };
    const schedule = () => {
      if (!scheduled) { scheduled = true; window.requestAnimationFrame(update); }
    };
    window.addEventListener('scroll', schedule, { passive: true });
    window.addEventListener('resize', schedule);
    update();
  }

  async function mount() {
    const main = document.querySelector('body.developer-layout main');
    if (!main || document.querySelector('.doc-side')) return;

    const aside = document.createElement('aside');
    aside.className = 'doc-side';
    aside.setAttribute('aria-label', 'For Developer');

    const pages = await loadPages();
    if (Array.isArray(pages) && pages.length) {
      const nav = document.createElement('nav');
      nav.className = 'doc-side-pages';
      nav.setAttribute('aria-label', 'For Developer pages');
      nav.innerHTML = `
        <a class="doc-side-home" href="${escapeHtml(new URL('index.html#tab-developer', docRoot).href)}">${bilingual('For Developer', '開発者向け')}</a>
        ${pageListHtml(pages)}`;
      aside.appendChild(nav);
    }

    const sourceToc = main.querySelector('.dev-toc');
    const toc = sourceToc ? buildToc(sourceToc) : null;
    if (toc) aside.appendChild(toc);
    if (!aside.children.length) return;

    document.body.appendChild(aside);
    document.body.classList.add('has-doc-side');
    if (toc) trackSections(toc);
    // Bring the current page into view inside the list without scrolling the page.
    const pagesNav = aside.querySelector('.doc-side-pages');
    const current = pagesNav?.querySelector('.is-current');
    if (current && pagesNav.scrollHeight > pagesNav.clientHeight) {
      pagesNav.scrollTop = current.offsetTop - pagesNav.clientHeight / 3;
    }
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', mount);
  } else {
    mount();
  }
})();
