// @vitest-environment jsdom
import { describe, expect, it } from "vitest";
import { findSourceLine, getContextMenuInfo } from "../js/context-menu";

describe("findSourceLine", () => {
  it("data-source-line属性を持つ要素の行番号を返す", () => {
    document.body.innerHTML = '<p data-source-line="5">hello</p>';
    const p = document.querySelector("p");
    const node = p?.firstChild;
    expect(node).toBeTruthy();
    expect(findSourceLine(node as Node)).toBe(5);
  });

  it("ネストされた要素から親のdata-source-lineを取得する", () => {
    document.body.innerHTML =
      '<p data-source-line="10"><strong>bold</strong></p>';
    const strong = document.querySelector("strong");
    const node = strong?.firstChild;
    expect(node).toBeTruthy();
    expect(findSourceLine(node as Node)).toBe(10);
  });

  it("data-source-lineを持たない要素ではnullを返す", () => {
    document.body.innerHTML = "<div>no attr</div>";
    const div = document.querySelector("div");
    const node = div?.firstChild;
    expect(node).toBeTruthy();
    expect(findSourceLine(node as Node)).toBeNull();
  });

  it("コードブロック内でオフセットを加算して正確な行番号を返す", () => {
    document.body.innerHTML =
      '<pre data-source-line="5" data-source-line-end="10"><code>line1\nline2\nline3</code></pre>';
    const codeEl = document.querySelector("code");
    const textNode = codeEl?.firstChild;
    expect(textNode).toBeTruthy();
    // charOffset=12 は "line1\nline2\n" の長さ → 3行目 → startLine(5) + 1(fence) + 2(改行数) = 8
    expect(findSourceLine(textNode as Node, 12)).toBe(8);
  });
});

describe("getContextMenuInfo", () => {
  it("コードブロック内の選択範囲からオフセットを計算して正確な行番号を返す", () => {
    document.body.innerHTML =
      '<pre data-source-line="5" data-source-line-end="10"><code><span>line1\n</span><span>line2\n</span><span>line3</span></code></pre>';
    const codeEl = document.querySelector("code");
    expect(codeEl).toBeTruthy();
    const spans = codeEl?.querySelectorAll("span");
    const thirdTextNode = spans?.[2].firstChild;
    expect(thirdTextNode).toBeTruthy();

    const range = document.createRange();
    range.setStart(thirdTextNode as Node, 2);
    range.setEnd(thirdTextNode as Node, 4);

    const selection = window.getSelection();
    selection?.removeAllRanges();
    selection?.addRange(range);

    const info = getContextMenuInfo();
    // offset = 6("line1\n") + 6("line2\n") + 2 = 14 → 2改行 → startLine(5)+1+2 = 8
    expect(info.startLine).toBe(8);
    expect(info.endLine).toBe(8);
  });
});
