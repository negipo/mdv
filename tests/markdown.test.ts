import { beforeAll, describe, expect, it } from "vitest";
import { initHighlighter, renderMarkdown, setShikiTheme } from "../js/markdown";

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

  it("mermaidブロックにもdata-source-line属性を付与する", () => {
    const result = renderMarkdown("```mermaid\ngraph TD\n```");
    expect(result).toContain('class="mermaid"');
    expect(result).toMatch(/data-source-line="1"/);
  });
});

describe("math rendering", () => {
  it("インライン数式をKaTeXのHTMLに変換する", () => {
    const result = renderMarkdown("text $E=mc^2$ end");
    expect(result).toContain("katex");
    expect(result).not.toContain("$E=mc^2$");
  });

  it("エスケープされたドル記号は数式として処理しない", () => {
    const result = renderMarkdown("price is \\$100");
    expect(result).toContain("$100");
    expect(result).not.toContain("katex");
  });

  it("ブロック数式をKaTeXのHTMLに変換する", () => {
    const result = renderMarkdown("$$\n\\int_0^1 f(x)dx\n$$");
    expect(result).toContain("katex");
    expect(result).toContain("katex-display");
  });

  it("ブロック数式にdata-source-line属性を付与する", () => {
    const result = renderMarkdown("text\n\n$$\nx^2\n$$");
    expect(result).toMatch(/div [^>]*data-source-line="3"/);
  });

  it("mathコードブロックをKaTeXのブロック数式として変換する", () => {
    const result = renderMarkdown("```math\n\\sum_{i=1}^n i\n```");
    expect(result).toContain("katex");
    expect(result).toContain("katex-display");
  });

  it("mathコードブロックにdata-source-line属性を付与する", () => {
    const result = renderMarkdown("text\n\n```math\nx^2\n```");
    expect(result).toMatch(/div [^>]*data-source-line="3"/);
  });
});

describe("frontmatter rendering", () => {
  it("基本的なfrontmatterを水平テーブルとしてレンダリングする", () => {
    const result = renderMarkdown(
      "---\ntitle: Hello\ndate: 2026-01-01\n---\n\n# Content",
    );
    expect(result).toContain('<table class="frontmatter"');
    expect(result).toContain("<th>title</th>");
    expect(result).toContain("<th>date</th>");
    expect(result).toContain("<td>Hello</td>");
    expect(result).toContain("<td>2026-01-01</td>");
    expect(result).toContain(">Content</h1>");
  });

  it("配列値をカンマ区切りで表示する", () => {
    const result = renderMarkdown(
      "---\ntags:\n  - markdown\n  - mdv\n---\n\ntext",
    );
    expect(result).toContain("<td>markdown, mdv</td>");
  });

  it("ネストされたオブジェクトをJSON文字列で表示する", () => {
    const result = renderMarkdown("---\nmeta:\n  key: value\n---\n\ntext");
    expect(result).toContain("<td>{&quot;key&quot;:&quot;value&quot;}</td>");
  });

  it("不正なYAMLをコードブロックとして表示する", () => {
    const result = renderMarkdown("---\n: invalid\n  yaml: [\n---\n\ntext");
    expect(result).toContain("<pre>");
    expect(result).toContain("language-yaml");
    expect(result).not.toContain('<table class="frontmatter"');
  });

  it("frontmatterがないMarkdownは従来通りレンダリングする", () => {
    const result = renderMarkdown("# Hello\n\nworld");
    expect(result).not.toContain('<table class="frontmatter"');
    expect(result).toContain(">Hello</h1>");
  });

  it("ドキュメント先頭以外の---はfrontmatterとして認識しない", () => {
    const result = renderMarkdown(
      "# Title\n\n---\ntitle: Not frontmatter\n---",
    );
    expect(result).not.toContain('<table class="frontmatter"');
  });

  it("frontmatterテーブルにdata-source-lineとdata-source-line-end属性を付与する", () => {
    const result = renderMarkdown("---\ntitle: Hello\n---\n\n# Content");
    expect(result).toMatch(/table [^>]*data-source-line="1"/);
    expect(result).toMatch(/table [^>]*data-source-line-end="5"/);
  });
});

describe("dark theme rendering", () => {
  it("setShikiThemeでダークテーマに切り替えるとコードブロックがgithub-dark-defaultでレンダリングされる", async () => {
    setShikiTheme("github-dark-default");
    const result = renderMarkdown("```js\nconst x = 1;\n```");
    expect(result).toContain("github-dark-default");
    setShikiTheme("github-light-default");
  });
});
