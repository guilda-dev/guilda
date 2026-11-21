// Update log list, shared by the Home tab (index.html, latest entries) and
// updatelog.html (every entry). Data: database/list_UpdateLog.js (updateLogData).
// Rules for the entries: developer/project-management.html#update-log.
(function (root) {
  'use strict';

  const bilingual = (en, ja) => `<span lang="en">${en}</span><span lang="ja">${ja}</span>`;
  const esc = (value) => String(value ?? '')
    .replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');

  // The three user-facing types; anything else renders neutral with no label.
  const TYPES = {
    model: bilingual('Model', 'モデル'),
    feature: bilingual('Feature', '機能'),
    fix: bilingual('Fix', 'バグ修正')
  };

  function entries() {
    const data = typeof updateLogData !== 'undefined' ? updateLogData : null;
    if (!Array.isArray(data)) return [];
    data.forEach((u) => {
      if (u.type !== undefined && !Object.hasOwn(TYPES, u.type)) console.warn(`Update log: unknown type "${u.type}" in "${u.title}"`);
    });
    // Newest first; entries of the same date keep their order in the file.
    return data.map((u, i) => [u, i])
      .sort((a, b) => String(b[0].date || '').localeCompare(String(a[0].date || '')) || a[1] - b[1])
      .map(([u]) => u);
  }

  function legendHtml() {
    return `<ul class="ulog-legend">${Object.keys(TYPES).map((t) => `<li class="is-${t}">${TYPES[t]}</li>`).join('')}</ul>`;
  }

  function itemHtml(u) {
    const type = Object.hasOwn(TYPES, u.type) ? u.type : null;
    return `
      <li class="ulog-item${type ? ` is-${type}` : ''}">
        <div class="ulog-meta">
          <time class="ulog-date" datetime="${esc(u.date)}">${esc(u.date)}</time>
          ${type ? `<span class="ulog-type">${TYPES[type]}</span>` : ''}
        </div>
        <div class="ulog-body">
          <h3 class="ulog-title">${esc(u.title)}</h3>
          <p class="ulog-text">${esc(u.content)}</p>
        </div>
      </li>`;
  }

  // Render the legend and the list into container. options.limit: show only
  // the newest entries. Returns the total number of entries.
  function render(container, options = {}) {
    if (!container) return 0;
    const items = entries();
    if (items.length === 0) {
      container.innerHTML = `<p class="ulog-empty">${bilingual('No update log data found.', '更新履歴のデータがありません。')}</p>`;
      return 0;
    }
    const shown = options.limit ? items.slice(0, options.limit) : items;
    container.innerHTML = `${legendHtml()}<ol class="ulog-list">${shown.map(itemHtml).join('')}</ol>`;
    return items.length;
  }

  root.GuildaUpdateLog = { render, types: Object.keys(TYPES) };
})(window);
