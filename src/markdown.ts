import { Marked, Renderer, type Tokens } from "marked";

const renderer = new Renderer();
const defaultCodeRenderer = renderer.code.bind(renderer);

const marked = new Marked({
  renderer: {
    code(token: Tokens.Code) {
      if (token.lang === "mermaid") {
        return `<pre class="mermaid">${token.text}</pre>`;
      }
      return defaultCodeRenderer(token);
    },
  },
});

export function renderMarkdown(markdown: string): string {
  return marked.parse(markdown) as string;
}
