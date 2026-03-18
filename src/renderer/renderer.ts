import mermaid from "mermaid";

mermaid.initialize({ startOnLoad: false, theme: "default" });

const contentEl = document.getElementById("content")!;

async function renderContent(html: string) {
  contentEl.innerHTML = html;

  const mermaidEls = contentEl.querySelectorAll<HTMLElement>("pre.mermaid");
  if (mermaidEls.length > 0) {
    await mermaid.run({ nodes: mermaidEls });
  }
}

(window as any).electronAPI.onMarkdownUpdate((_event: any, html: string) => {
  renderContent(html);
});

(window as any).electronAPI.requestInitialContent();
