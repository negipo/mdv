import mermaid from "mermaid";
import DOMPurify from "dompurify";

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

async function renderContent(html: string) {
  contentEl.innerHTML = DOMPurify.sanitize(html);

  const mermaidEls = contentEl.querySelectorAll<HTMLElement>("pre.mermaid");
  if (mermaidEls.length > 0) {
    await mermaid.run({ nodes: mermaidEls });
  }
  attachMermaidClickHandlers();
}

(window as any).electronAPI.onMarkdownUpdate((_event: any, html: string) => {
  renderContent(html);
});

(window as any).electronAPI.requestInitialContent();
