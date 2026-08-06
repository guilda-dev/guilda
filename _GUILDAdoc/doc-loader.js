(function (root) {
  'use strict';

  const SUPPORTED_INDEX_VERSION = 3;
  const SUPPORTED_CLASS_VERSION = 3;
  const pendingLoads = new Map();
  const loaderScriptUrl = document.currentScript?.src || root.location.href;
  const documentationRootUrl = new URL('.', loaderScriptUrl);

  function schemaVersion(value) {
    const version = Number(value?.schema?.version ?? 0);
    return Number.isFinite(version) ? version : 0;
  }

  function validateIndex(index) {
    if (!index || !Array.isArray(index.classes)) {
      throw new Error('The documentation class index is invalid.');
    }
    const version = schemaVersion(index);
    if (version > SUPPORTED_INDEX_VERSION) {
      throw new Error(`Unsupported class index schema version: ${version}`);
    }
    return index;
  }

  function validateClassDocument(className, data) {
    if (!data || data.ClassName !== className) {
      throw new Error(`Class data was not registered: ${className}`);
    }
    const version = schemaVersion(data);
    if (version > SUPPORTED_CLASS_VERSION) {
      throw new Error(`Unsupported class document schema version: ${version}`);
    }
    return data;
  }

  function getIndex() {
    if (root.GUILDA_DOC_INDEX && Array.isArray(root.GUILDA_DOC_INDEX.classes)) {
      return validateIndex(root.GUILDA_DOC_INDEX);
    }
    const legacyClasses = Array.isArray(root.classListData)
      ? root.classListData
      : (typeof class_list !== 'undefined' && Array.isArray(class_list) ? class_list : []);
    return validateIndex({
      schema: {
        name: 'GUILDA documentation class index (legacy)',
        version: 0,
        classDocumentVersion: 0,
        pathBase: '_GUILDAdoc'
      },
      classes: legacyClasses
    });
  }

  function getClasses() {
    return getIndex().classes;
  }

  function getRouteParams() {
    const queryParams = new URLSearchParams(root.location.search || '');
    const hashText = (root.location.hash || '').replace(/^#/, '');
    const hashParams = new URLSearchParams(hashText);
    return {
      get: (name) => queryParams.get(name) || hashParams.get(name)
    };
  }

  function pageUrl(pageName, params) {
    const currentPageUrl = root.location.href.split(/[?#]/)[0];
    const targetUrl = new URL(pageName, currentPageUrl);
    if (typeof params === 'string') {
      targetUrl.hash = params;
    } else if (params && typeof params === 'object') {
      targetUrl.hash = new URLSearchParams(params).toString();
    }
    return targetUrl.href;
  }

  function navigate(pageName, params) {
    root.location.assign(pageUrl(pageName, params));
  }

  function findClass(className) {
    const target = (className || '').toLowerCase();
    return getClasses().find((item) => (item.Name || item.name || '').toLowerCase() === target) || null;
  }

  function normalizeClassPath(path) {
    const normalized = (path || '').replace(/\\/g, '/');
    const databasePosition = normalized.toLowerCase().lastIndexOf('/database/');
    if (databasePosition >= 0) return `.${normalized.slice(databasePosition)}`;
    if (normalized.startsWith('database/')) return `./${normalized}`;
    return normalized;
  }

  function resolveClassPath(className) {
    const meta = findClass(className);
    if (!meta) return '';
    const relativePath = normalizeClassPath(meta.path);
    if (relativePath) {
      return new URL(relativePath.replace(/^\.\//, ''), documentationRootUrl).href;
    }
    return '';
  }

  function registeredClass(className) {
    return root.GUILDA_DOC_CLASSES?.[className] || null;
  }

  function loadClass(className) {
    const cached = registeredClass(className);
    if (cached) {
      return Promise.resolve({
        meta: findClass(className),
        data: validateClassDocument(className, cached)
      });
    }
    if (pendingLoads.has(className)) return pendingLoads.get(className);

    const meta = findClass(className);
    const path = resolveClassPath(className);
    if (!meta || !path) {
      return Promise.reject(new Error(`Class metadata was not found: ${className}`));
    }

    const promise = new Promise((resolve, reject) => {
      const script = document.createElement('script');
      script.src = path;
      script.onload = () => {
        const data = registeredClass(className)
          || root.classData
          || (typeof classData !== 'undefined' ? classData : null);
        try {
          resolve({ meta, data: validateClassDocument(className, data) });
        } catch (error) {
          reject(error);
        }
      };
      script.onerror = () => reject(new Error(`Class data could not be loaded: ${path}`));
      document.head.appendChild(script);
    }).finally(() => pendingLoads.delete(className));

    pendingLoads.set(className, promise);
    return promise;
  }

  root.GuildaDocLoader = Object.freeze({
    getIndex,
    getSchema: () => getIndex().schema,
    getValidation: () => getIndex().validation || { warningCount: 0, errorCount: 0, classes: [] },
    getClasses,
    getRouteParams,
    pageUrl,
    navigate,
    findClass,
    resolveClassPath,
    loadClass
  });
})(window);
