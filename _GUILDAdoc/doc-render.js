(function (root) {
  'use strict';

  // HTML helpers shared by class.html and method.html.

  const escapeHtml = (text) => (text ?? '').toString()
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');

  const nl2br = (text) => escapeHtml(text).replace(/\n/g, '<br>');

  // A fixed UI string in the language chosen by doc-lang.js. Pages that use it
  // render again on the guilda-langchange event.
  const tr = (en, ja) => (root.GUILDA_LANG?.get() === 'ja' ? ja : en);

  // Title of a page whose name comes from data (see applyTitle in doc-lang.js).
  const setPageTitle = (en, ja) => {
    const titleEl = document.querySelector('head > title');
    if (titleEl) Object.assign(titleEl.dataset, { titleEn: en, titleJa: ja });
    document.title = tr(en, ja);
  };

  const firstText = (...values) => values.map((v) => (v ?? '').toString().trim()).find(Boolean) || '';

  const toList = (raw) => Array.isArray(raw)
    ? raw.map((value) => (value ?? '').toString().trim()).filter(Boolean)
    : ((raw ?? '').toString().trim() ? [(raw ?? '').toString().trim()] : []);

  // LaTeX math through KaTeX (vendor/katex, loaded by the page). Without it
  // the source is shown as code. Errors in the source show in red.
  const renderMath = (tex, displayMode) => {
    if (root.katex?.renderToString) {
      try {
        return root.katex.renderToString(tex, { displayMode, throwOnError: false, output: 'htmlAndMathml' });
      } catch (error) {
        // Fall through to the source.
      }
    }
    return `<code class="doc-math-source">${escapeHtml(tex)}</code>`;
  };

  // $...$ outside code spans: no space just inside the dollars, so that
  // "$5 and $6" stays text. Returns the text with placeholders.
  const takeInlineMath = (text, store) => text.replace(/`[^`]*`|\$(?=\S)([^$\n]*?\S)\$/g, (match, tex) => {
    if (tex === undefined) return match;
    store.push(renderMath(tex, false));
    return `@@MATH${store.length - 1}@@`;
  });

  const formatInlineMarkdown = (text) => {
    const math = [];
    let output = escapeHtml(takeInlineMath((text ?? '').toString(), math));
    output = output.replace(/`([^`]+)`/g, '<code>$1</code>');
    output = output.replace(/\*\*([^*]+)\*\*/g, '<strong>$1</strong>');
    output = output.replace(/\*([^*]+)\*/g, '<em>$1</em>');
    output = output.replace(/\[([^\]]+)\]\(([^)]+)\)/g, '<a href="$2" target="_blank" rel="noopener noreferrer">$1</a>');
    return output.replace(/@@MATH(\d+)@@/g, (_, index) => math[Number(index)] || '');
  };

  const renderMarkdown = (input) => {
    const rawText = (input ?? '').toString().replace(/\r\n?/g, '\n').trim();
    if (!rawText) return '<p style="margin: 0;">N/A</p>';

    const sourceLines = rawText.split('\n');
    const textArtLineCount = sourceLines.filter((line) =>
      /[┌┐└┘│─]/.test(line) || /(?:={6,}|-{6,}|~{3,}|\/{3,})/.test(line)
    ).length;
    if (textArtLineCount >= 2) {
      return `<pre class="doc-text-art">${escapeHtml(rawText)}</pre>`;
    }

    // ```math blocks are display math; other fenced blocks are code.
    const codeBlocks = [];
    const text = rawText.replace(/```([^\n]*)\n?([\s\S]*?)```/g, (_, info, code) => {
      const token = `@@CODEBLOCK_${codeBlocks.length}@@`;
      codeBlocks.push(info.trim() === 'math'
        ? `<div class="doc-math">${renderMath(code.trim(), true)}</div>`
        : `<pre><code>${escapeHtml(code.trimEnd())}</code></pre>`);
      return token;
    });

    const htmlParts = [];
    let paragraphLines = [];
    let listType = '';
    let listItems = [];
    const flushParagraph = () => {
      if (!paragraphLines.length) return;
      const paragraph = paragraphLines.map((line) => formatInlineMarkdown(line)).join('<br>');
      if (paragraph) htmlParts.push(`<p>${paragraph}</p>`);
      paragraphLines = [];
    };
    const flushList = () => {
      if (!listType || !listItems.length) return;
      htmlParts.push(`<${listType}>${listItems.map((item) => `<li>${formatInlineMarkdown(item)}</li>`).join('')}</${listType}>`);
      listType = '';
      listItems = [];
    };

    for (const line of text.split('\n')) {
      const trimmed = line.trim();
      const unorderedMatch = trimmed.match(/^[-*+]\s+(.*)$/);
      const orderedMatch = trimmed.match(/^\d+\.\s+(.*)$/);
      if (!trimmed) {
        flushParagraph();
        flushList();
        continue;
      }
      if (/^@@CODEBLOCK_\d+@@$/.test(trimmed)) {
        flushParagraph();
        flushList();
        htmlParts.push(trimmed);
        continue;
      }
      const headingMatch = trimmed.match(/^(#{1,6})\s+(.*)$/);
      if (headingMatch) {
        flushParagraph();
        flushList();
        const headingLevel = headingMatch[1].length;
        htmlParts.push(`<h${headingLevel}>${formatInlineMarkdown(headingMatch[2])}</h${headingLevel}>`);
        continue;
      }
      // An indented line inside a list continues the last item.
      if (listType && listItems.length && /^\s+\S/.test(line) && !unorderedMatch && !orderedMatch) {
        listItems[listItems.length - 1] += ` ${trimmed}`;
        continue;
      }
      if (unorderedMatch || orderedMatch) {
        flushParagraph();
        const nextListType = unorderedMatch ? 'ul' : 'ol';
        if (listType && listType !== nextListType) flushList();
        listType = nextListType;
        listItems.push((unorderedMatch || orderedMatch)[1]);
        continue;
      }
      flushList();
      paragraphLines.push(line);
    }
    flushParagraph();
    flushList();
    return htmlParts.join('').replace(/@@CODEBLOCK_(\d+)@@/g, (_, index) => codeBlocks[Number(index)] || '');
  };

  // Link to a class page when the class is in the reference, plain text otherwise
  // (e.g. MATLAB's handle class).
  const classLink = (name) => {
    const loader = root.GuildaDocLoader;
    const value = (name ?? '').toString();
    if (!value) return '';
    return loader.findClass(value)
      ? `<a href="${loader.pageUrl('class.html', { class: value })}">${escapeHtml(value)}</a>`
      : `<span class="ref-chain-external">${escapeHtml(value)}</span>`;
  };

  // One "See also" entry: a class name, Class.method, or a method of `ownerClass`
  // listed in `ownerMethods` (method names). Other entries stay plain code.
  const seeAlsoLink = (entry, ownerClass, ownerMethods = []) => {
    const loader = root.GuildaDocLoader;
    const text = (entry ?? '').toString().trim();
    if (loader.findClass(text)) return classLink(text);
    const dot = text.lastIndexOf('.');
    const target = dot > 0 && loader.findClass(text.slice(0, dot))
      ? { class: loader.findClass(text.slice(0, dot)).Name, method: text.slice(dot + 1) }
      : (ownerClass && ownerMethods.includes(text) ? { class: ownerClass, method: text } : null);
    return target
      ? `<a href="${loader.pageUrl('method.html', target)}"><code>${escapeHtml(text)}</code></a>`
      : `<code>${escapeHtml(text)}</code>`;
  };

  // Source location as "path:line" (line omitted when unknown).
  const sourceLocation = (file, line) => {
    const path = (file ?? '').toString();
    if (!path) return '';
    return Number(line) > 0 ? `${path}:${Number(line)}` : path;
  };

  // Examples are Markdown in v5 and a list of strings in v4.
  const examplesText = (raw) => toList(raw).join('\n\n');

  // Split rows by group, keeping the rows' order inside each group. Groups
  // follow their first appearance in `orderRows` (the source order; defaults
  // to `rows`), with "Constructor" first and "Other" last. Rows without a
  // group fall into `fallback`.
  const groupRows = (rows, fallback, orderRows = rows) => {
    const groupOf = (row) => row.group || fallback;
    const order = [...new Set(orderRows.map(groupOf))];
    const groups = new Map();
    rows.forEach((row) => {
      if (!groups.has(groupOf(row))) groups.set(groupOf(row), []);
      groups.get(groupOf(row)).push(row);
    });
    const rank = (name) => (name === 'Constructor' ? -1 : (name === 'Other' || name === fallback ? 1 : 0));
    return [...groups.entries()]
      .map(([name, items]) => ({ name, items, index: order.indexOf(name) }))
      .sort((a, b) => (rank(a.name) - rank(b.name)) || (a.index - b.index));
  };

  root.GuildaDocRender = Object.freeze({
    tr,
    setPageTitle,
    escapeHtml,
    nl2br,
    firstText,
    toList,
    formatInlineMarkdown,
    renderMarkdown,
    renderMath,
    classLink,
    seeAlsoLink,
    sourceLocation,
    examplesText,
    groupRows
  });
})(window);
