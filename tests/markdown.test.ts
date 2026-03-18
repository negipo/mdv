import { describe, it, expect } from "vitest";
import { renderMarkdown } from "../src/markdown";

describe("renderMarkdown", () => {
  it("見出しをHTMLに変換する", () => {
    const result = renderMarkdown("# Hello");
    expect(result).toContain("<h1>Hello</h1>");
  });

  it("コードブロックをHTMLに変換する", () => {
    const result = renderMarkdown("```js\nconst x = 1;\n```");
    expect(result).toContain("<code");
    expect(result).toContain("const x = 1;");
  });

  it("mermaidコードブロックをmermaidクラス付きpre要素に変換する", () => {
    const result = renderMarkdown("```mermaid\ngraph TD\n    A-->B\n```");
    expect(result).toContain('class="mermaid"');
    expect(result).toContain("graph TD");
  });

  it("通常のコードブロックにはmermaidクラスが付かない", () => {
    const result = renderMarkdown("```js\nconst x = 1;\n```");
    expect(result).not.toContain('class="mermaid"');
  });
});
