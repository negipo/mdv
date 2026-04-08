// @vitest-environment jsdom
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

describe("keybindings", () => {
  let searchInput: HTMLInputElement;
  let overlay: HTMLElement;

  beforeEach(() => {
    vi.resetModules();

    document.body.innerHTML = `
      <div id="mermaid-overlay"></div>
      <div id="search-bar">
        <input id="search-input" type="text" />
      </div>
      <div id="content"><p>test content</p></div>
    `;
    searchInput = document.getElementById("search-input") as HTMLInputElement;
    overlay = document.getElementById("mermaid-overlay") as HTMLElement;

    window.showSearchBar = vi.fn();
    window.toggleToc = vi.fn();
    window.scrollBy = vi.fn();
    window.scrollTo = vi.fn();
    Object.defineProperty(window, "innerHeight", {
      value: 800,
      writable: true,
    });
  });

  afterEach(() => {
    document.body.innerHTML = "";
  });

  function pressKey(key: string) {
    document.dispatchEvent(
      new KeyboardEvent("keydown", { key, bubbles: true }),
    );
  }

  it("j scrolls half-page down", async () => {
    const { setupKeybindings } = await import("../js/keybindings");
    setupKeybindings();
    pressKey("j");
    expect(window.scrollBy).toHaveBeenCalledWith({
      top: 400,
      behavior: "smooth",
    });
  });

  it("k scrolls half-page up", async () => {
    const { setupKeybindings } = await import("../js/keybindings");
    setupKeybindings();
    pressKey("k");
    expect(window.scrollBy).toHaveBeenCalledWith({
      top: -400,
      behavior: "smooth",
    });
  });

  it("g scrolls to top", async () => {
    const { setupKeybindings } = await import("../js/keybindings");
    setupKeybindings();
    pressKey("g");
    expect(window.scrollTo).toHaveBeenCalledWith({
      top: 0,
      behavior: "smooth",
    });
  });

  it("G scrolls to bottom", async () => {
    const { setupKeybindings } = await import("../js/keybindings");
    setupKeybindings();
    pressKey("G");
    expect(window.scrollTo).toHaveBeenCalledWith({
      top: document.body.scrollHeight,
      behavior: "smooth",
    });
  });

  it("ignores keys when search input is focused", async () => {
    const { setupKeybindings } = await import("../js/keybindings");
    setupKeybindings();
    searchInput.focus();
    pressKey("j");
    expect(window.scrollBy).not.toHaveBeenCalled();
  });

  it("ignores keys when mermaid overlay is active", async () => {
    const { setupKeybindings } = await import("../js/keybindings");
    setupKeybindings();
    overlay.classList.add("active");
    pressKey("j");
    expect(window.scrollBy).not.toHaveBeenCalled();
  });
});
