// @vitest-environment jsdom
import { afterEach, describe, expect, it, vi } from "vitest";
import { attachCopyButtons } from "../js/copy-button";

describe("attachCopyButtons", () => {
  afterEach(() => {
    document.body.innerHTML = "";
    vi.restoreAllMocks();
  });

  it("preブロックにコピーボタンを追加する", () => {
    document.body.innerHTML = "<pre><code>hello</code></pre>";
    const container = document.body;
    attachCopyButtons(container);
    const btn = container.querySelector(".copy-button");
    expect(btn).toBeTruthy();
  });

  it("pre.mermaidにはコピーボタンを追加しない", () => {
    document.body.innerHTML = '<pre class="mermaid">graph TD</pre>';
    const container = document.body;
    attachCopyButtons(container);
    const btn = container.querySelector(".copy-button");
    expect(btn).toBeNull();
  });

  it("既存のコピーボタンがあれば重複追加しない", () => {
    document.body.innerHTML = "<pre><code>hello</code></pre>";
    const container = document.body;
    attachCopyButtons(container);
    attachCopyButtons(container);
    const buttons = container.querySelectorAll(".copy-button");
    expect(buttons.length).toBe(1);
  });

  it("code要素のtextContentをコピーする", async () => {
    document.body.innerHTML = "<pre><code>const x = 1;</code></pre>";
    const container = document.body;

    const writeText = vi.fn().mockResolvedValue(undefined);
    Object.assign(navigator, {
      clipboard: { writeText },
    });

    attachCopyButtons(container);
    const btn = container.querySelector(".copy-button") as HTMLButtonElement;
    btn.click();
    await vi.waitFor(() => {
      expect(writeText).toHaveBeenCalledWith("const x = 1;");
    });
  });

  it("code要素がない場合preのtextContentをコピーする", async () => {
    document.body.innerHTML = "<pre>raw text</pre>";
    const container = document.body;

    const writeText = vi.fn().mockResolvedValue(undefined);
    Object.assign(navigator, {
      clipboard: { writeText },
    });

    attachCopyButtons(container);
    const btn = container.querySelector(".copy-button") as HTMLButtonElement;
    btn.click();
    await vi.waitFor(() => {
      expect(writeText).toHaveBeenCalledWith("raw text");
    });
  });

  it("コピー後にCopied!ツールチップが表示される", async () => {
    document.body.innerHTML = "<pre><code>hello</code></pre>";
    const container = document.body;

    Object.assign(navigator, {
      clipboard: { writeText: vi.fn().mockResolvedValue(undefined) },
    });

    attachCopyButtons(container);
    const btn = container.querySelector(".copy-button") as HTMLButtonElement;
    btn.click();
    await vi.waitFor(() => {
      const tooltip = container.querySelector(".copy-tooltip");
      expect(tooltip).toBeTruthy();
      expect(tooltip?.classList.contains("visible")).toBe(true);
      expect(tooltip?.textContent).toBe("Copied!");
    });
  });
});
