// @vitest-environment jsdom
import { beforeEach, describe, expect, it } from "vitest";
import { toggleWideContent } from "../js/wide-content";

describe("toggleWideContent", () => {
  beforeEach(() => {
    document.body.className = "";
    document.body.innerHTML = '<div id="content"></div>';
  });

  // 呼ぶたびにbodyのwide-contentクラスが付け外しされる
  it("bodyのwide-contentクラスをトグルする", () => {
    expect(toggleWideContent()).toBe(true);
    expect(document.body.classList.contains("wide-content")).toBe(true);
    expect(toggleWideContent()).toBe(false);
    expect(document.body.classList.contains("wide-content")).toBe(false);
  });

  // contentの中身を差し替えてもクラスは残る(ライブリロード相当)
  it("contentの中身を差し替えても状態が残る", () => {
    toggleWideContent();
    const content = document.getElementById("content") as HTMLElement;
    content.innerHTML = "<p>reloaded</p>";
    expect(document.body.classList.contains("wide-content")).toBe(true);
  });
});
