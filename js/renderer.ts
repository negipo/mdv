import mermaid from "mermaid";
import DOMPurify from "dompurify";
import { initHighlighter, renderMarkdown, loadLanguageOnDemand } from "./markdown";

mermaid.initialize({ startOnLoad: false, theme: "default" });

const contentEl = document.getElementById("content")!;

const overlay = document.createElement("div");
overlay.id = "mermaid-overlay";
const overlayContent = document.createElement("div");
overlayContent.id = "mermaid-overlay-content";
overlay.appendChild(overlayContent);
document.body.appendChild(overlay);

overlay.addEventListener("click", () => {
  overlay.classList.remove("active");
});

document.addEventListener("keydown", (e) => {
  if (e.key === "Escape" && overlay.classList.contains("active")) {
    overlay.classList.remove("active");
  }
});

function attachMermaidClickHandlers() {
  contentEl.querySelectorAll<HTMLElement>("pre.mermaid").forEach((el) => {
    el.addEventListener("click", () => {
      overlayContent.innerHTML = el.innerHTML;
      overlay.classList.add("active");
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
