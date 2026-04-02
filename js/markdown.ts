import katex from "katex";
import { Marked, type Token, type Tokens } from "marked";
import { bundledLanguages, createHighlighter, type Highlighter } from "shiki";

let highlighter: Highlighter | null = null;
let currentTheme = "github-light-default";

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
    themes: ["github-light-default", "github-dark-default"],
    langs: initialLangs,
  });
}

export function setShikiTheme(theme: string): void {
  currentTheme = theme;
}

export function getCurrentShikiTheme(): string {
  return currentTheme;
}

export async function loadLanguageOnDemand(lang: string): Promise<boolean> {
  if (!highlighter) return false;
  if (highlighter.getLoadedLanguages().includes(lang)) return true;
  if (!(lang in bundledLanguages)) return false;
  await highlighter.loadLanguage(lang as keyof typeof bundledLanguages);
  return true;
}

interface SourceLineToken {
  sourceLine?: number;
  sourceLineEnd?: number;
}

function annotateSourceLines(tokens: Token[]): void {
  let line = 1;
  for (const token of tokens) {
    (token as Token & SourceLineToken).sourceLine = line;
    const rawLines = token.raw.split("\n").length - 1;
    if (token.type === "code") {
      (token as Token & SourceLineToken).sourceLineEnd = line + rawLines;
    }
    if (token.type === "blockMath") {
      (token as Token & SourceLineToken).sourceLineEnd = line + rawLines;
    }
    line += rawLines;
  }
}

function injectAttr(html: string, tag: string, attr: string): string {
  const openTag = `<${tag}`;
  const idx = html.indexOf(openTag);
  if (idx === -1) return html;
  return (
    html.slice(0, idx + openTag.length) +
    ` ${attr}` +
    html.slice(idx + openTag.length)
  );
}

function sourceLineAttr(token: SourceLineToken): string | null {
  const sl = token.sourceLine;
  if (sl == null) return null;
  return `data-source-line="${sl}"`;
}

const blockMathExtension = {
  name: "blockMath",
  level: "block" as const,
  start(src: string) {
    return src.indexOf("$$");
  },
  tokenizer(src: string) {
    const match = src.match(/^\$\$\n?([\s\S]+?)\n?\$\$/);
    if (match) {
      return {
        type: "blockMath",
        raw: match[0],
        text: match[1],
      };
    }
  },
  renderer(token: { text: string }) {
    const sl = (token as unknown as SourceLineToken).sourceLine;
    const slEnd = (token as unknown as SourceLineToken).sourceLineEnd;
    let attr = "";
    if (sl != null) {
      attr += ` data-source-line="${sl}"`;
      if (slEnd != null) attr += ` data-source-line-end="${slEnd}"`;
    }
    return `<div class="katex-block"${attr}>${katex.renderToString(token.text, {
      throwOnError: false,
      displayMode: true,
      output: "html",
    })}</div>\n`;
  },
};

const inlineMathExtension = {
  name: "inlineMath",
  level: "inline" as const,
  start(src: string) {
    return src.indexOf("$");
  },
  tokenizer(src: string) {
    const match = src.match(/^\$([^$\n]+?)\$/);
    if (match) {
      return {
        type: "inlineMath",
        raw: match[0],
        text: match[1],
      };
    }
  },
  renderer(token: { text: string }) {
    return katex.renderToString(token.text, {
      throwOnError: false,
      output: "html",
    });
  },
};

const marked = new Marked({
  extensions: [blockMathExtension, inlineMathExtension],
  renderer: {
    heading(
      this: { parser: { parseInline: (t: Token[]) => string } },
      token: Tokens.Heading,
    ) {
      const html = `<h${token.depth}>${this.parser.parseInline(token.tokens)}</h${token.depth}>\n`;
      const attr = sourceLineAttr(token as Tokens.Heading & SourceLineToken);
      if (!attr) return html;
      return injectAttr(html, `h${token.depth}`, attr);
    },
    paragraph(
      this: { parser: { parseInline: (t: Token[]) => string } },
      token: Tokens.Paragraph,
    ) {
      const html = `<p>${this.parser.parseInline(token.tokens)}</p>\n`;
      const attr = sourceLineAttr(token as Tokens.Paragraph & SourceLineToken);
      if (!attr) return html;
      return injectAttr(html, "p", attr);
    },
    code(token: Tokens.Code) {
      if (token.lang === "mermaid") {
        const sl = (token as Tokens.Code & SourceLineToken).sourceLine;
        if (sl == null) return `<pre class="mermaid">${token.text}</pre>`;
        const slEnd = (token as Tokens.Code & SourceLineToken).sourceLineEnd;
        let attr = `data-source-line="${sl}"`;
        if (slEnd != null) attr += ` data-source-line-end="${slEnd}"`;
        return `<pre class="mermaid" ${attr}>${token.text}</pre>`;
      }
      if (token.lang === "math") {
        const sl = (token as Tokens.Code & SourceLineToken).sourceLine;
        const slEnd = (token as Tokens.Code & SourceLineToken).sourceLineEnd;
        let attr = "";
        if (sl != null) {
          attr += ` data-source-line="${sl}"`;
          if (slEnd != null) attr += ` data-source-line-end="${slEnd}"`;
        }
        return `<div class="katex-block"${attr}>${katex.renderToString(
          token.text,
          {
            throwOnError: false,
            displayMode: true,
            output: "html",
          },
        )}</div>\n`;
      }
      const sl = (token as Tokens.Code & SourceLineToken).sourceLine;
      const slEnd = (token as Tokens.Code & SourceLineToken).sourceLineEnd;
      let html: string;
      if (highlighter && token.lang) {
        const loadedLangs = highlighter.getLoadedLanguages();
        if (loadedLangs.includes(token.lang)) {
          html = highlighter.codeToHtml(token.text, {
            lang: token.lang,
            theme: currentTheme,
          });
        } else {
          html = defaultCodeHtml(token);
        }
      } else {
        html = defaultCodeHtml(token);
      }
      if (sl == null) return html;
      let attr = `data-source-line="${sl}"`;
      if (slEnd != null) {
        attr += ` data-source-line-end="${slEnd}"`;
      }
      return injectAttr(html, "pre", attr);
    },
    list(
      this: { parser: { parse: (t: Token[]) => string } },
      token: Tokens.List,
    ) {
      const tag = token.ordered ? "ol" : "ul";
      const startAttr =
        token.ordered && token.start !== 1 ? ` start="${token.start}"` : "";
      let body = "";
      for (const item of token.items) {
        body += listitem(item, this.parser);
      }
      const html = `<${tag}${startAttr}>\n${body}</${tag}>\n`;
      const attr = sourceLineAttr(token as Tokens.List & SourceLineToken);
      if (!attr) return html;
      return injectAttr(html, tag, attr);
    },
    blockquote(
      this: { parser: { parse: (t: Token[]) => string } },
      token: Tokens.Blockquote,
    ) {
      const body = this.parser.parse(token.tokens);
      const html = `<blockquote>\n${body}</blockquote>\n`;
      const attr = sourceLineAttr(token as Tokens.Blockquote & SourceLineToken);
      if (!attr) return html;
      return injectAttr(html, "blockquote", attr);
    },
    table(
      this: { parser: { parseInline: (t: Token[]) => string } },
      token: Tokens.Table,
    ) {
      const html = buildTableHtml(token, this.parser);
      const attr = sourceLineAttr(token as Tokens.Table & SourceLineToken);
      if (!attr) return html;
      return injectAttr(html, "table", attr);
    },
    hr(token: Tokens.Hr) {
      const html = "<hr>\n";
      const attr = sourceLineAttr(token as Tokens.Hr & SourceLineToken);
      if (!attr) return html;
      return injectAttr(html, "hr", attr);
    },
  },
});

function escapeHtml(text: string): string {
  return text
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#39;");
}

function defaultCodeHtml(token: Tokens.Code): string {
  const langClass = token.lang
    ? ` class="language-${escapeHtml(token.lang)}"`
    : "";
  return `<pre><code${langClass}>${escapeHtml(token.text)}\n</code></pre>\n`;
}

function listitem(
  item: Tokens.ListItem,
  parser: { parse: (t: Token[]) => string },
): string {
  const itemBody = parser.parse(item.tokens);
  return `<li>${itemBody}</li>\n`;
}

function buildTableHtml(
  token: Tokens.Table,
  parser: { parseInline: (t: Token[]) => string },
): string {
  let header = "<tr>\n";
  for (let j = 0; j < token.header.length; j++) {
    const cell = token.header[j];
    const align = cell.align ? ` align="${cell.align}"` : "";
    header += `<th${align}>${parser.parseInline(cell.tokens)}</th>\n`;
  }
  header += "</tr>\n";

  let body = "";
  for (const row of token.rows) {
    body += "<tr>\n";
    for (let j = 0; j < row.length; j++) {
      const cell = row[j];
      const align = cell.align ? ` align="${cell.align}"` : "";
      body += `<td${align}>${parser.parseInline(cell.tokens)}</td>\n`;
    }
    body += "</tr>\n";
  }

  let html = `<table>\n<thead>\n${header}</thead>\n`;
  if (body) {
    html += `<tbody>${body}</tbody>`;
  }
  html += "</table>\n";
  return html;
}

export function renderMarkdown(markdown: string): string {
  const tokens = marked.lexer(markdown);
  annotateSourceLines(tokens);
  return marked.parser(tokens);
}
