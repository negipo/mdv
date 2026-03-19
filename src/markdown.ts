import { Marked, Renderer, type Tokens } from "marked";
import { bundledLanguages, createHighlighter, type Highlighter } from "shiki";

let highlighter: Highlighter;

export async function initHighlighter() {
  highlighter = await createHighlighter({
    themes: ["github-light-default"],
    langs: Object.keys(bundledLanguages),
  });
}

const renderer = new Renderer();
const defaultCodeRenderer = renderer.code.bind(renderer);

const marked = new Marked({
  renderer: {
    code(token: Tokens.Code) {
      if (token.lang === "mermaid") {
        return `<pre class="mermaid">${token.text}</pre>`;
      }
      if (highlighter && token.lang) {
        const loadedLangs = highlighter.getLoadedLanguages();
        if (loadedLangs.includes(token.lang)) {
          return highlighter.codeToHtml(token.text, {
            lang: token.lang,
            theme: "github-light-default",
          });
        }
      }
      return defaultCodeRenderer(token);
    },
  },
});

export function renderMarkdown(markdown: string): string {
  return marked.parse(markdown) as string;
}
