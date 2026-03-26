import { Marked, Renderer, type Tokens } from "marked";
import { bundledLanguages, createHighlighter, type Highlighter } from "shiki";

let highlighter: Highlighter | null = null;

const initialLangs = [
  "javascript",
  "typescript",
  "python",
  "ruby",
  "bash",
  "shell",
  "json",
  "yaml",
  "html",
  "css",
  "swift",
  "sql",
  "markdown",
  "go",
  "rust",
  "java",
  "c",
  "cpp",
  "diff",
  "toml",
];

export async function initHighlighter(): Promise<void> {
  highlighter = await createHighlighter({
    themes: ["github-light-default"],
    langs: initialLangs,
  });
}

export async function loadLanguageOnDemand(lang: string): Promise<boolean> {
  if (!highlighter) return false;
  if (highlighter.getLoadedLanguages().includes(lang)) return true;
  if (!(lang in bundledLanguages)) return false;
  await highlighter.loadLanguage(lang as keyof typeof bundledLanguages);
  return true;
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
