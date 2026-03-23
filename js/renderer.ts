import mermaid from "mermaid";
import DOMPurify from "dompurify";
import { initHighlighter, renderMarkdown, loadLanguageOnDemand } from "./markdown";
import { SearchManager } from "./search";
import { computeZoom, isDrag } from "./zoom";

mermaid.initialize({ startOnLoad: false, theme: "default" });

const contentEl = document.getElementById("content")!;

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
const searchCount = document.getElementById("search-count")!;
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

document.getElementById("search-prev")!.addEventListener("click", () => {
  searchManager.prev();
  updateSearchCount();
});

document.getElementById("search-next")!.addEventListener("click", () => {
  searchManager.next();
  updateSearchCount();
});

(window as any).showSearchBar = () => {
  searchBar.classList.add("active");
  searchInput.focus();
  searchInput.select();
};

(window as any).hideSearchBar = () => {
  searchBar.classList.remove("active");
  searchManager.close();
  searchCount.textContent = "";
  searchInput.value = "";
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
const maxScale = 5.0;
let translateX = 0;
let translateY = 0;
let isPanning = false;

function applyTransform() {
  overlayInner.style.transform =
    `translate(${translateX}px, ${translateY}px) scale(${scale})`;
}

function centerOverlayInner() {
  scale = 1.0;
  translateX = 0;
  translateY = 0;
  applyTransform();
  const contentRect = overlayContent.getBoundingClientRect();
  const innerRect = overlayInner.getBoundingClientRect();
  translateX = (contentRect.width - innerRect.width) / 2;
  translateY = (contentRect.height - innerRect.height) / 2;
  applyTransform();
}

overlay.addEventListener("click", () => {
  overlay.classList.remove("active");
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

    const result = computeZoom(cursorX, cursorY, scale, newScale, translateX, translateY);
    if (result.scale === scale) return;

    scale = result.scale;
    translateX = result.translateX;
    translateY = result.translateY;
    applyTransform();
  },
  { passive: false }
);

(window as any).handleEscape = () => {
  if (overlay.classList.contains("active")) {
    overlay.classList.remove("active");
    return;
  }
  if (searchBar.classList.contains("active")) {
    (window as any).hideSearchBar();
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
    return "file://" + encodeURI(decoded);
  }
  return "file://" + encodeURI(basePath + "/" + decoded);
}

function resolveImagePaths(container: HTMLElement, basePath: string) {
  container.querySelectorAll<HTMLImageElement>("img").forEach((img) => {
    const src = img.getAttribute("src");
    if (!src) return;
    if (src.startsWith("http://") || src.startsWith("https://") || src.startsWith("data:") || src.startsWith("file://")) return;
    img.src = resolveLocalPath(src, basePath);
  });
}

function resolveLinkPaths(container: HTMLElement, basePath: string) {
  container.querySelectorAll<HTMLAnchorElement>("a[href]").forEach((a) => {
    const href = a.getAttribute("href");
    if (!href) return;
    if (href.startsWith("http://") || href.startsWith("https://") || href.startsWith("data:") || href.startsWith("file://") || href.startsWith("#")) return;
    a.href = resolveLocalPath(href, basePath);
  });
}

async function renderContent(markdown: string, basePath?: string) {
  const html = renderMarkdown(markdown);
  contentEl.innerHTML = DOMPurify.sanitize(html);

  if (basePath) {
    resolveImagePaths(contentEl, basePath);
    resolveLinkPaths(contentEl, basePath);
  }

  const mermaidEls = contentEl.querySelectorAll<HTMLElement>("pre.mermaid");
  if (mermaidEls.length > 0) {
    await mermaid.run({ nodes: mermaidEls });
  }
  attachMermaidClickHandlers();
}

let lastMarkdown: string | null = null;
let lastBasePath: string | undefined;
let highlighterReady = false;

(window as any).updateMarkdown = (markdown: string, basePath?: string) => {
  lastMarkdown = markdown;
  lastBasePath = basePath ?? undefined;
  renderContent(markdown, lastBasePath).catch(console.error);
};

(async () => {
  if ((window as any).webkit?.messageHandlers?.ready) {
    (window as any).webkit.messageHandlers.ready.postMessage("initialized");
  }
  try {
    await initHighlighter();
    highlighterReady = true;
    if (lastMarkdown) {
      renderContent(lastMarkdown, lastBasePath).catch(console.error);
    }
  } catch (e) {
    console.error("shiki initialization failed, continuing without syntax highlighting:", e);
  }
})();
