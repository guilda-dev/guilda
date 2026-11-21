(function (root) {
  'use strict';

  // Column widths of the reference tables (class.html member tables,
  // method.html argument tables) that the reader sets by dragging the right
  // edge of a header cell, as in a spreadsheet.
  //
  // A table opts in with data-colresize="<kind>"; each header cell names its
  // column with a col-<key> class. Until a column of that kind has been
  // resized, the table keeps its automatic layout. After that the table
  // switches to a fixed layout: the resized columns take their saved width,
  // the others the width the automatic layout gave them. The widths live in
  // CSS variables that reference.css applies on wide screens only, so phones
  // keep the stacked rows. Widths are saved per table kind in localStorage.

  const MIN_CH = 4;
  const KEY_STEP = 8;
  const KEY_STEP_LARGE = 40;
  const STORE_PREFIX = 'guilda-doc-colwidths-';
  // Same breakpoint as the stacked rows in reference.css.
  const stackedQuery = root.matchMedia('(max-width: 600px)');

  const tr = (en, ja) => (root.GUILDA_LANG?.get() === 'ja' ? ja : en);

  // Widths per kind: { key: px }. The in-memory copy keeps them for the
  // page's lifetime when storage is unavailable.
  const memory = new Map();
  function loadWidths(kind) {
    if (memory.has(kind)) return memory.get(kind);
    let widths = {};
    try {
      const saved = JSON.parse(root.localStorage.getItem(STORE_PREFIX + kind) || 'null');
      if (saved && typeof saved === 'object' && !Array.isArray(saved)) {
        Object.entries(saved).forEach(([key, value]) => {
          if (Number.isFinite(value) && value > 0) widths[key] = Math.round(value);
        });
      }
    } catch (error) {
      widths = {};
    }
    memory.set(kind, widths);
    return widths;
  }
  function saveWidths(kind) {
    const widths = memory.get(kind) || {};
    try {
      if (Object.keys(widths).length) root.localStorage.setItem(STORE_PREFIX + kind, JSON.stringify(widths));
      else root.localStorage.removeItem(STORE_PREFIX + kind);
    } catch (error) {
      // The widths last until the page is left.
    }
  }

  const headerCells = (table) => [...(table.tHead?.rows[0]?.cells || [])];
  const columnKey = (th) => (th.className.match(/(?:^|\s)col-(\S+)/) || [])[1] || '';

  function minWidth(th) {
    const probe = document.createElement('span');
    probe.style.cssText = `position:absolute;visibility:hidden;width:${MIN_CH}ch;`;
    th.appendChild(probe);
    const width = probe.getBoundingClientRect().width || MIN_CH * 8;
    probe.remove();
    return Math.ceil(width);
  }

  function clearFixed(table) {
    table.classList.remove('is-col-resized');
    table.style.removeProperty('--ref-table-width');
    headerCells(table).forEach((th) => th.style.removeProperty('--ref-col-w'));
  }

  // Lay the table out again: automatic when no column of its kind has a saved
  // width, otherwise fixed with the saved widths over the measured ones.
  // Nothing is measured while the rows are stacked (phones).
  function layout(table) {
    if (stackedQuery.matches) return;
    const widths = loadWidths(table.dataset.colresize);
    const cells = headerCells(table);
    const hasSaved = cells.some((th) => widths[columnKey(th)]);
    clearFixed(table);
    if (!hasSaved) {
      cells.forEach((th) => updateHandle(th));
      return;
    }
    const measured = cells.map((th) => th.getBoundingClientRect().width);
    // A hidden table has nothing to measure; it is laid out on the next resize.
    if (!measured.some((w) => w > 0)) return;
    const finalWidths = cells.map((th, index) => Math.max(widths[columnKey(th)] || measured[index], minWidth(th)));
    applyFixed(table, cells, finalWidths);
  }

  function applyFixed(table, cells, finalWidths) {
    cells.forEach((th, index) => {
      th.style.setProperty('--ref-col-w', `${finalWidths[index]}px`);
      updateHandle(th, finalWidths[index]);
    });
    table.style.setProperty('--ref-table-width', `${finalWidths.reduce((sum, w) => sum + w, 0)}px`);
    table.classList.add('is-col-resized');
  }

  // Current widths of all header cells, switching to the fixed layout first
  // so that one column can change without moving the others.
  function freeze(table) {
    const cells = headerCells(table);
    const current = cells.map((th) => th.getBoundingClientRect().width);
    applyFixed(table, cells, current.map((w, i) => Math.max(w, minWidth(cells[i]))));
    return cells;
  }

  function setWidth(table, th, width, save) {
    const kind = table.dataset.colresize;
    const value = Math.round(Math.max(width, minWidth(th)));
    const cells = table.classList.contains('is-col-resized') ? headerCells(table) : freeze(table);
    const finalWidths = cells.map((cell) => (cell === th ? value : parseFloat(cell.style.getPropertyValue('--ref-col-w')) || cell.getBoundingClientRect().width));
    applyFixed(table, cells, finalWidths);
    loadWidths(kind)[columnKey(th)] = value;
    if (save) saveWidths(kind);
  }

  function resetWidth(table, th) {
    const kind = table.dataset.colresize;
    delete loadWidths(kind)[columnKey(th)];
    saveWidths(kind);
    layout(table);
  }

  function updateHandle(th, width) {
    const handle = th.querySelector(':scope > .ref-col-handle');
    if (!handle) return;
    const value = Math.round(width ?? th.getBoundingClientRect().width);
    if (value > 0) handle.setAttribute('aria-valuenow', String(value));
    else handle.removeAttribute('aria-valuenow');
  }

  function addHandle(table, th) {
    const label = th.textContent.replace(/\s*↕\s*$/, '').trim();
    const handle = document.createElement('span');
    handle.className = 'ref-col-handle';
    handle.tabIndex = 0;
    handle.setAttribute('role', 'separator');
    handle.setAttribute('aria-orientation', 'vertical');
    handle.setAttribute('aria-valuemin', String(minWidth(th)));
    handle.setAttribute('aria-label', tr(
      `Resize the ${label} column. Double-click to reset it.`,
      `「${label}」列の幅を変更します。ダブルクリックで既定の幅に戻します。`
    ));
    handle.title = tr('Drag to resize. Double-click to reset.', 'ドラッグで幅を変更します。ダブルクリックで元に戻します。');

    // The header cell sorts on click; nothing on the handle reaches it.
    ['click', 'mousedown'].forEach((type) => handle.addEventListener(type, (event) => event.stopPropagation()));

    handle.addEventListener('pointerdown', (event) => {
      if (event.button !== 0 || stackedQuery.matches) return;
      event.preventDefault();
      event.stopPropagation();
      const startX = event.clientX;
      const startWidth = th.getBoundingClientRect().width;
      let moved = false;
      handle.setPointerCapture(event.pointerId);
      handle.classList.add('is-dragging');
      const onMove = (moveEvent) => {
        const dx = moveEvent.clientX - startX;
        if (!moved && Math.abs(dx) < 2) return;
        moved = true;
        setWidth(table, th, startWidth + dx, false);
      };
      const onEnd = () => {
        handle.removeEventListener('pointermove', onMove);
        handle.removeEventListener('pointerup', onEnd);
        handle.removeEventListener('pointercancel', onEnd);
        handle.classList.remove('is-dragging');
        if (moved) saveWidths(table.dataset.colresize);
      };
      handle.addEventListener('pointermove', onMove);
      handle.addEventListener('pointerup', onEnd);
      handle.addEventListener('pointercancel', onEnd);
    });

    handle.addEventListener('dblclick', (event) => {
      event.preventDefault();
      event.stopPropagation();
      resetWidth(table, th);
    });

    handle.addEventListener('keydown', (event) => {
      const step = event.shiftKey ? KEY_STEP_LARGE : KEY_STEP;
      const delta = { ArrowLeft: -step, ArrowDown: -step, ArrowRight: step, ArrowUp: step }[event.key];
      if (delta === undefined || stackedQuery.matches) return;
      event.preventDefault();
      event.stopPropagation();
      setWidth(table, th, th.getBoundingClientRect().width + delta, true);
    });

    th.appendChild(handle);
  }

  // Tables on the page that have handles; laid out again when the window
  // width changes, since the measured columns follow it.
  const tables = new Set();

  function attach(table, kind) {
    if (!table || table.dataset.colresizeBound) return;
    if (kind) table.dataset.colresize = kind;
    if (!table.dataset.colresize) return;
    table.dataset.colresizeBound = '1';
    headerCells(table).forEach((th) => addHandle(table, th));
    tables.add(table);
    layout(table);
  }

  // Attach every opted-in table under `scope` (default: the document).
  function attachAll(scope = document) {
    scope.querySelectorAll('table[data-colresize]').forEach((table) => attach(table));
  }

  let pending = 0;
  function relayoutAll() {
    pending = 0;
    tables.forEach((table) => {
      if (!table.isConnected) tables.delete(table);
      else layout(table);
    });
  }
  const scheduleRelayout = () => {
    if (!pending) pending = root.requestAnimationFrame(relayoutAll);
  };
  root.addEventListener('resize', scheduleRelayout);
  stackedQuery.addEventListener('change', () => {
    if (stackedQuery.matches) tables.forEach((table) => clearFixed(table));
    scheduleRelayout();
  });

  root.GuildaColResize = Object.freeze({ attach, attachAll });
})(window);
