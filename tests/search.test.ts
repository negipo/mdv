// @vitest-environment jsdom
import { afterEach, beforeEach, describe, expect, it } from "vitest";
import { SearchManager } from "../js/search";

describe("SearchManager", () => {
  let container: HTMLElement;
  let searchManager: SearchManager;

  beforeEach(() => {
    document.body.innerHTML = `
      <div id="content"><p>Hello world. Hello again.</p></div>
    `;
    container = document.getElementById("content")!;
    searchManager = new SearchManager(container);
  });

  afterEach(() => {
    searchManager.close();
    document.body.innerHTML = "";
  });

  it("wraps matching text in mark tags", () => {
    searchManager.search("Hello");
    const marks = container.querySelectorAll("mark.search-highlight");
    expect(marks.length).toBe(2);
    expect(marks[0].textContent).toBe("Hello");
  });

  it("adds current class to first match", () => {
    searchManager.search("Hello");
    const marks = container.querySelectorAll("mark.search-highlight");
    expect(marks[0].classList.contains("current")).toBe(true);
    expect(marks[1].classList.contains("current")).toBe(false);
  });

  it("navigates to next match", () => {
    searchManager.search("Hello");
    searchManager.next();
    const marks = container.querySelectorAll("mark.search-highlight");
    expect(marks[0].classList.contains("current")).toBe(false);
    expect(marks[1].classList.contains("current")).toBe(true);
  });

  it("navigates to previous match", () => {
    searchManager.search("Hello");
    searchManager.next();
    searchManager.prev();
    const marks = container.querySelectorAll("mark.search-highlight");
    expect(marks[0].classList.contains("current")).toBe(true);
  });

  it("wraps around at end", () => {
    searchManager.search("Hello");
    searchManager.next();
    searchManager.next();
    const marks = container.querySelectorAll("mark.search-highlight");
    expect(marks[0].classList.contains("current")).toBe(true);
  });

  it("clears highlights restoring original text", () => {
    searchManager.search("Hello");
    searchManager.clearHighlights();
    const marks = container.querySelectorAll("mark.search-highlight");
    expect(marks.length).toBe(0);
    expect(container.textContent).toBe("Hello world. Hello again.");
  });

  it("returns zero matches for non-existent query", () => {
    searchManager.search("xyz");
    const marks = container.querySelectorAll("mark.search-highlight");
    expect(marks.length).toBe(0);
  });

  it("searches case-insensitively", () => {
    searchManager.search("hello");
    const marks = container.querySelectorAll("mark.search-highlight");
    expect(marks.length).toBe(2);
  });

  it("skips text inside pre.mermaid", () => {
    container.innerHTML = `<p>Hello</p><pre class="mermaid">Hello diagram</pre>`;
    searchManager.search("Hello");
    const marks = container.querySelectorAll("mark.search-highlight");
    expect(marks.length).toBe(1);
  });
});
