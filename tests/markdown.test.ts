import { beforeAll, describe, expect, it } from "vitest";
import { initHighlighter, renderMarkdown } from "../js/markdown";

beforeAll(async () => {
  await initHighlighter();
});

describe("renderMarkdown", () => {
  it("見出しをHTMLに変換する", () => {
    const result = renderMarkdown("# Hello");
    expect(result).toContain(">Hello</h1>");
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

describe("data-source-line attributes", () => {
  it("見出しにdata-source-line属性を付与する", () => {
    const result = renderMarkdown("# Hello");
    expect(result).toContain('<h1 data-source-line="1"');
  });

  it("段落にdata-source-line属性を付与する", () => {
    const result = renderMarkdown("# Title\n\nparagraph");
    expect(result).toContain('<p data-source-line="3"');
  });

  it("コードブロックにdata-source-lineとdata-source-line-end属性を付与する", () => {
    const result = renderMarkdown(
      "text\n\n```js\nconst x = 1;\nconst y = 2;\n```",
    );
    expect(result).toMatch(/pre [^>]*data-source-line="3"/);
    expect(result).toMatch(/pre [^>]*data-source-line-end="6"/);
  });

  it("リストにdata-source-line属性を付与する", () => {
    const result = renderMarkdown("text\n\n- item1\n- item2");
    expect(result).toContain('<ul data-source-line="3"');
  });

  it("blockquoteにdata-source-line属性を付与する", () => {
    const result = renderMarkdown("text\n\n> quoted");
    expect(result).toContain('<blockquote data-source-line="3"');
  });

  it("tableにdata-source-line属性を付与する", () => {
    const result = renderMarkdown("text\n\n| a | b |\n| - | - |\n| 1 | 2 |");
    expect(result).toContain('<table data-source-line="3"');
  });

  it("hrにdata-source-line属性を付与する", () => {
    const result = renderMarkdown("text\n\n---");
    expect(result).toContain('<hr data-source-line="3"');
  });

  it("mermaidブロックにはdata-source-line属性を付与しない", () => {
    const result = renderMarkdown("```mermaid\ngraph TD\n```");
    expect(result).toContain('class="mermaid"');
    expect(result).not.toMatch(/data-source-line/);
  });
});
