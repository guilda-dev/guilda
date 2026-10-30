(function (root) {
  'use strict';

  // Folder tree of the source files (GuildaDocLoader.getTree()) for the
  // sidebar of class.html, method.html and the Reference tab of index.html.
  // Folders are <details> elements, files link to their class or method page.

  const WIDE_SCREEN = '(min-width: 900px)';

  const escapeHtml = (text) => (text ?? '').toString()
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');

  const children = (node) => (Array.isArray(node?.Children) ? node.Children : []);

  // Path from a root to the file of the page on screen, or [] when it is not in the tree.
  // A method page prefers the method's own file, then the classdef file of the
  // class that defines it, then the classdef file of the class on screen.
  function findCurrentPath(tree, current) {
    if (!current?.className) return [];
    const search = (nodes, matches) => {
      for (const node of nodes) {
        if (node.Kind === 'file' && matches(node)) return [node];
        const below = search(children(node), matches);
        if (below.length) return [node, ...below];
      }
      return [];
    };
    const owners = [current.definingClass, current.className].filter(Boolean);
    if (current.methodName) {
      for (const owner of owners) {
        const path = search(tree, (node) => node.Class === owner && node.Method === current.methodName);
        if (path.length) return path;
      }
    }
    for (const owner of current.methodName ? owners : [current.className]) {
      const path = search(tree, (node) => node.Class === owner && !node.Method);
      if (path.length) return path;
    }
    return [];
  }

  function fileUrl(node) {
    const loader = root.GuildaDocLoader;
    if (!node.Class) return '';
    return node.Method
      ? loader.pageUrl('method.html', { class: node.Class, method: node.Method })
      : loader.pageUrl('class.html', { class: node.Class });
  }

  function renderNodes(nodes, openSet, currentNode, depth) {
    return nodes.map((node) => {
      const label = escapeHtml(node.Name);
      const search = escapeHtml(`${node.Name} ${node.Class || ''} ${node.Method || ''}`.toLowerCase());
      if (node.Kind === 'folder') {
        const open = depth === 0 || openSet.has(node);
        return `<li class="ref-tree-folder" data-search="${search}">
          <details${open ? ' open' : ''} data-default-open="${open}">
            <summary title="${escapeHtml(node.Path || node.Name)}">${label}</summary>
            <ul>${renderNodes(children(node), openSet, currentNode, depth + 1)}</ul>
          </details>
        </li>`;
      }
      const url = fileUrl(node);
      const isCurrent = node === currentNode;
      const title = escapeHtml(node.Path || node.Name);
      const content = url
        ? `<a href="${url}" title="${title}"${isCurrent ? ' class="is-current" aria-current="page"' : ''}>${label}</a>`
        : `<span class="ref-muted" title="${title}">${label}</span>`;
      return `<li class="ref-tree-file" data-search="${search}">${content}</li>`;
    }).join('');
  }

  // Show only the files whose name, class or method contains the term, with
  // their folders opened. An empty term restores the initial open state.
  function applyFilter(list, term) {
    const visit = (li) => {
      const own = !term || li.dataset.search.includes(term);
      const details = li.querySelector(':scope > details');
      let anyChild = false;
      if (details) {
        details.querySelectorAll(':scope > ul > li').forEach((child) => {
          if (visit(child)) anyChild = true;
        });
        details.open = term ? anyChild : details.dataset.defaultOpen === 'true';
      }
      const visible = !term || own || anyChild;
      li.hidden = !visible;
      if (term && own && details) {
        // A matching folder shows all of its contents.
        details.querySelectorAll('li').forEach((item) => { item.hidden = false; });
      }
      return visible;
    };
    list.querySelectorAll(':scope > li').forEach(visit);
  }

  // Arrow keys move between the visible folders and files; Right/Left open
  // and close a folder, or go to its first child / parent folder.
  function bindKeys(list) {
    list.addEventListener('keydown', (event) => {
      const items = [...list.querySelectorAll('summary, a')].filter((el) => el.offsetParent !== null);
      const index = items.indexOf(document.activeElement);
      if (index < 0) return;
      const item = items[index];
      const details = item.tagName === 'SUMMARY' ? item.parentElement : null;
      let target = null;
      if (event.key === 'ArrowDown') target = items[index + 1];
      else if (event.key === 'ArrowUp') target = items[index - 1];
      else if (event.key === 'Home') target = items[0];
      else if (event.key === 'End') target = items[items.length - 1];
      else if (event.key === 'ArrowRight' && details) {
        if (!details.open) details.open = true;
        else target = items[index + 1];
      } else if (event.key === 'ArrowLeft') {
        if (details?.open) details.open = false;
        else target = item.closest('li')?.parentElement?.closest('details')?.querySelector(':scope > summary');
      } else return;
      event.preventDefault();
      target?.focus();
    });
  }

  // Scroll the tree, not the page, so that the current file is in view.
  function scrollToCurrent(scroller) {
    const current = scroller.querySelector('a.is-current');
    if (!current || !scroller.clientHeight) return;
    const top = current.getBoundingClientRect().top - scroller.getBoundingClientRect().top + scroller.scrollTop;
    scroller.scrollTop = Math.max(0, top - scroller.clientHeight / 3);
  }

  // Render the tree into `container`. `current` names the page on screen:
  // { className, methodName, definingClass }.
  function mount(container, current) {
    const loader = root.GuildaDocLoader;
    if (!container || !loader?.hasIndex()) return;
    const tree = loader.getTree();
    if (!tree.length) return;

    const path = findCurrentPath(tree, current);
    const currentNode = path[path.length - 1] || null;
    const openSet = new Set(path.slice(0, -1));
    const wide = root.matchMedia ? root.matchMedia(WIDE_SCREEN).matches : true;

    container.innerHTML = `
      <details class="ref-tree-panel"${wide ? ' open' : ''}>
        <summary class="ref-tree-title">Source files</summary>
        <input type="search" class="search-box ref-tree-filter" placeholder="Filter files..." autocomplete="off" aria-label="Filter source files">
        <nav class="ref-tree-scroll" aria-label="Source files">
          <ul class="ref-tree">${renderNodes(tree, openSet, currentNode, 0)}</ul>
        </nav>
      </details>`;

    const panel = container.querySelector('.ref-tree-panel');
    const list = container.querySelector('.ref-tree');
    const scroller = container.querySelector('.ref-tree-scroll');
    container.querySelector('.ref-tree-filter').addEventListener('input', (event) => {
      applyFilter(list, event.target.value.trim().toLowerCase());
    });
    bindKeys(list);
    panel.addEventListener('toggle', () => { if (panel.open) scrollToCurrent(scroller); });
    scrollToCurrent(scroller);
  }

  root.GuildaDocTree = Object.freeze({ mount, findCurrentPath });
})(window);
