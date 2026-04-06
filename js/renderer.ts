import DOMPurify from "dompurify";
import mermaid from "mermaid";
import { getContextMenuInfo, setupContextMenu } from "./context-menu";
import { attachCopyButtons } from "./copy-button";
import { initHighlighter, renderMarkdown, setShikiTheme } from "./markdown";
import { SearchManager } from "./search";
import { TocManager } from "./toc";
import { computeZoom, isDrag } from "./zoom";

declare global {
  interface Window {
    showSearchBar: () => void;
    hideSearchBar: () => void;
    toggleToc: () => void;
    showToc: () => void;
    hideToc: () => void;
    handleEscape: () => void;
    getContextMenuInfo: () => {
      startLine: number | null;
      endLine: number | null;
    };
    setTheme: (theme: "light" | "dark") => void;
    updateMarkdown: (markdown: string, basePath?: string) => void;
    webkit?: {
      messageHandlers?: {
        ready?: { postMessage: (message: string) => void };
        contextMenu?: { postMessage: (message: unknown) => void };
      };
    };
  }
}

mermaid.initialize({ startOnLoad: false, theme: "default" });

const contentEl = document.getElementById("content") as HTMLElement;

const tocPane = document.createElement("div");
tocPane.id = "toc-pane";
document.body.insertBefore(tocPane, contentEl);

const tocManager = new TocManager(contentEl, tocPane);

const searchBar = document.createElement("div");
searchBar.id = "search-bar";
searchBar.innerHTML = `
  <input id="search-input" type="text" placeholder="Search\u2026" />
  <span id="search-count"></span>
  <button id="search-prev" class="search-nav-btn">&#9650;</button>
  <button id="search-next" class="search-nav-btn">&#9660;</button>
`;
document.body.appendChild(searchBar);

const searchInput = document.getElementById("search-input") as HTMLInputElement;
const searchCount = document.getElementById("search-count") as HTMLElement;
const searchManager = new SearchManager(contentEl);

function updateSearchCount() {
  if (searchManager.count === 0 && searchInput.value) {
    searchCount.textContent = "0 matches";
  } else if (searchManager.count > 0) {
    searchCount.textContent = `${searchManager.current + 1}/${searchManager.count}`;
  } else {
    searchCount.textContent = "";
  }
}

searchInput.addEventListener("input", () => {
  searchManager.search(searchInput.value);
  updateSearchCount();
});

searchInput.addEventListener("keydown", (e) => {
  if (e.key === "Enter") {
    if (e.shiftKey) {
      searchManager.prev();
    } else {
      searchManager.next();
    }
    updateSearchCount();
    e.preventDefault();
  }
});

document.getElementById("search-prev")?.addEventListener("click", () => {
  searchManager.prev();
  updateSearchCount();
});

document.getElementById("search-next")?.addEventListener("click", () => {
  searchManager.next();
  updateSearchCount();
});

window.showSearchBar = () => {
  searchBar.classList.add("active");
  searchInput.focus();
  searchInput.select();
};

window.hideSearchBar = () => {
  searchBar.classList.remove("active");
  searchManager.close();
  searchCount.textContent = "";
  searchInput.value = "";
};

window.toggleToc = () => {
  tocManager.toggle();
};

window.showToc = () => {
  tocManager.show();
};

window.hideToc = () => {
  tocManager.hide();
};

const overlay = document.createElement("div");
overlay.id = "mermaid-overlay";
const overlayContent = document.createElement("div");
overlayContent.id = "mermaid-overlay-content";
const overlayInner = document.createElement("div");
overlayInner.id = "mermaid-overlay-inner";
overlayContent.appendChild(overlayInner);
overlay.appendChild(overlayContent);
document.body.appendChild(overlay);

let scale = 1.0;
let minScale = 1.0;
let maxScale = 5.0;
let translateX = 0;
let translateY = 0;
let isPanning = false;

function applyTransform() {
  overlayInner.style.transform = `translate(${translateX}px, ${translateY}px) scale(${scale})`;
}

function centerOverlayInner() {
  scale = 1.0;
  translateX = 0;
  translateY = 0;
  applyTransform();
  const contentRect = overlayContent.getBoundingClientRect();
  const innerRect = overlayInner.getBoundingClientRect();
  const fitScale = Math.min(
    contentRect.width / innerRect.width,
    contentRect.height / innerRect.height,
  );
  minScale = fitScale;
  maxScale = fitScale * 20;
  scale = fitScale;
  translateX = (contentRect.width - innerRect.width * fitScale) / 2;
  translateY = (contentRect.height - innerRect.height * fitScale) / 2;
  applyTransform();
}

overlay.addEventListener("click", () => {
  overlay.classList.remove("active");
});

window.addEventListener("resize", () => {
  if (overlay.classList.contains("active")) {
    centerOverlayInner();
  }
});

overlayContent.addEventListener(
  "wheel",
  (e: WheelEvent) => {
    e.preventDefault();
    const rect = overlayContent.getBoundingClientRect();
    const cursorX = e.clientX - rect.left;
    const cursorY = e.clientY - rect.top;

    const delta = e.deltaY > 0 ? -1 : 1;
    const newScale = scale * (1 + delta * 0.1);

    const result = computeZoom(
      cursorX,
      cursorY,
      scale,
      newScale,
      translateX,
      translateY,
      minScale,
      maxScale,
    );
    if (result.scale === scale) return;

    scale = result.scale;
    translateX = result.translateX;
    translateY = result.translateY;
    applyTransform();
  },
  { passive: false },
);

let panStartX = 0;
let panStartY = 0;
let panStartTranslateX = 0;
let panStartTranslateY = 0;
let didDrag = false;

overlayContent.addEventListener("mousedown", (e: MouseEvent) => {
  if (e.button !== 0) return;
  isPanning = true;
  didDrag = false;
  panStartX = e.clientX;
  panStartY = e.clientY;
  panStartTranslateX = translateX;
  panStartTranslateY = translateY;
  overlayContent.classList.add("panning");
});

document.addEventListener("mousemove", (e: MouseEvent) => {
  if (!isPanning) return;
  const dx = e.clientX - panStartX;
  const dy = e.clientY - panStartY;
  if (isDrag(panStartX, panStartY, e.clientX, e.clientY)) {
    didDrag = true;
  }
  translateX = panStartTranslateX + dx;
  translateY = panStartTranslateY + dy;
  applyTransform();
});

document.addEventListener("mouseup", () => {
  if (!isPanning) return;
  isPanning = false;
  overlayContent.classList.remove("panning");
});

overlayContent.addEventListener("click", (e: MouseEvent) => {
  if (didDrag) {
    e.stopPropagation();
  }
});

window.handleEscape = () => {
  if (overlay.classList.contains("active")) {
    overlay.classList.remove("active");
    return;
  }
  if (searchBar.classList.contains("active")) {
    window.hideSearchBar();
  }
};

function attachMermaidClickHandlers() {
  contentEl.querySelectorAll<HTMLElement>("pre.mermaid").forEach((el) => {
    el.addEventListener("click", () => {
      overlayInner.innerHTML = el.innerHTML;
      overlay.classList.add("active");
      centerOverlayInner();
    });
  });
}

function resolveLocalPath(raw: string, basePath: string): string {
  const decoded = decodeURI(raw);
  if (decoded.startsWith("/")) {
    return `file://${encodeURI(decoded)}`;
  }
  return `file://${encodeURI(`${basePath}/${decoded}`)}`;
}

function resolveImagePaths(container: HTMLElement, basePath: string) {
  container.querySelectorAll<HTMLImageElement>("img").forEach((img) => {
    const src = img.getAttribute("src");
    if (!src) return;
    if (
      src.startsWith("http://") ||
      src.startsWith("https://") ||
      src.startsWith("data:") ||
      src.startsWith("file://")
    )
      return;
    img.src = resolveLocalPath(src, basePath);
  });
}

function resolveLinkPaths(container: HTMLElement, basePath: string) {
  container.querySelectorAll<HTMLAnchorElement>("a[href]").forEach((a) => {
    const href = a.getAttribute("href");
    if (!href) return;
    if (
      href.startsWith("http://") ||
      href.startsWith("https://") ||
      href.startsWith("data:") ||
      href.startsWith("file://") ||
      href.startsWith("#")
    )
      return;
    a.href = resolveLocalPath(href, basePath);
  });
}

async function renderContent(markdown: string, basePath?: string) {
  const html = renderMarkdown(markdown);
  contentEl.innerHTML = DOMPurify.sanitize(html);

  for (const a of contentEl.querySelectorAll("a:not([href]), a[href='']")) {
    a.replaceWith(a.textContent ?? "");
  }

  if (basePath) {
    resolveImagePaths(contentEl, basePath);
    resolveLinkPaths(contentEl, basePath);
  }

  const mermaidEls = contentEl.querySelectorAll<HTMLElement>("pre.mermaid");
  if (mermaidEls.length > 0) {
    await mermaid.run({ nodes: mermaidEls });
  }
  attachMermaidClickHandlers();
  tocManager.update();
  attachCopyButtons(contentEl);
}

let lastMarkdown: string | null = null;
let lastBasePath: string | undefined;

window.updateMarkdown = (markdown: string, basePath?: string) => {
  lastMarkdown = markdown;
  lastBasePath = basePath ?? undefined;
  renderContent(markdown, lastBasePath).catch(console.error);
};

export function setTheme(theme: "light" | "dark"): void {
  document.documentElement.dataset.theme = theme;

  const shikiTheme =
    theme === "dark" ? "github-dark-default" : "github-light-default";
  setShikiTheme(shikiTheme);

  mermaid.initialize({
    startOnLoad: false,
    theme: theme === "dark" ? "dark" : "default",
  });

  if (lastMarkdown) {
    renderContent(lastMarkdown, lastBasePath).catch(console.error);
  }
}

window.setTheme = setTheme;
window.getContextMenuInfo = getContextMenuInfo;

(async () => {
  setupContextMenu();
  if (window.webkit?.messageHandlers?.ready) {
    window.webkit.messageHandlers.ready.postMessage("initialized");
  }
  try {
    await initHighlighter();
    if (lastMarkdown) {
      renderContent(lastMarkdown, lastBasePath).catch(console.error);
    }
  } catch (e) {
    console.error(
      "shiki initialization failed, continuing without syntax highlighting:",
      e,
    );
  }
})();
