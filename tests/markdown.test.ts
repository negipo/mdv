import { describe, it, expect, beforeAll } from "vitest";
import { renderMarkdown, initHighlighter } from "../js/markdown";

beforeAll(async () => {
  await initHighlighter();
});

describe("renderMarkdown", () => {
  it("見出しをHTMLに変換する", () => {
    const result = renderMarkdown("# Hello");
    expect(result).toContain("<h1>Hello</h1>");
  });

  it("コードブロックをシンタックスハイライト付きHTMLに変換する", () => {
    const result = renderMarkdown("```js\nconst x = 1;\n```");
    expect(result).toContain("shiki");
    expect(result).toContain("const");
    expect(result).toContain("1");
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

  it("リンクをHTMLのa要素に変換する", () => {
    const result = renderMarkdown("[テスト](./other.md)");
    expect(result).toContain('<a href="./other.md"');
    expect(result).toContain("テスト</a>");
  });
});
