// @vitest-environment jsdom
import { describe, it, expect, beforeEach } from "vitest";
import { TocManager } from "../js/toc";

describe("TocManager", () => {
  let container: HTMLElement;
  let tocPane: HTMLElement;
  let manager: TocManager;

  beforeEach(() => {
    document.body.innerHTML = '<div id="toc-pane"></div><div id="content"></div>';
    document.body.className = "";
    container = document.getElementById("content")!;
    tocPane = document.getElementById("toc-pane")!;
    manager = new TocManager(container, tocPane);
  });

  it("見出し要素からToC項目を生成する", () => {
    container.innerHTML = "<h1>Title</h1><h2>Section</h2><h3>Subsection</h3>";
    manager.update();
    const items = tocPane.querySelectorAll(".toc-item");
    expect(items.length).toBe(3);
  });

  it("見出しレベルに応じたdata-level属性を付与する", () => {
    container.innerHTML = "<h1>A</h1><h2>B</h2><h3>C</h3>";
    manager.update();
    const items = tocPane.querySelectorAll(".toc-item");
    expect(items[0].getAttribute("data-level")).toBe("1");
    expect(items[1].getAttribute("data-level")).toBe("2");
    expect(items[2].getAttribute("data-level")).toBe("3");
  });

  it("見出しがない場合はToCを空にする", () => {
    container.innerHTML = "<p>No headings here</p>";
    manager.update();
    const items = tocPane.querySelectorAll(".toc-item");
    expect(items.length).toBe(0);
  });

  it("トグルでbodyのtoc-visibleクラスを切り替える", () => {
    manager.toggle();
    expect(document.body.classList.contains("toc-visible")).toBe(true);
    manager.toggle();
    expect(document.body.classList.contains("toc-visible")).toBe(false);
  });

  it("show/hideでbodyのtoc-visibleクラスを制御する", () => {
    manager.show();
    expect(document.body.classList.contains("toc-visible")).toBe(true);
    manager.hide();
    expect(document.body.classList.contains("toc-visible")).toBe(false);
  });

  it("update後もトグル状態が維持される", () => {
    manager.show();
    container.innerHTML = "<h1>Title</h1>";
    manager.update();
    expect(document.body.classList.contains("toc-visible")).toBe(true);
  });
});
