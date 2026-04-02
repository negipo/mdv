// @vitest-environment jsdom
import { beforeEach, describe, expect, it } from "vitest";

describe("setTheme", () => {
  beforeEach(() => {
    document.documentElement.removeAttribute("data-theme");
  });

  it("data-theme属性をdarkに設定する", async () => {
    const { setTheme } = await import("../js/renderer");
    setTheme("dark");
    expect(document.documentElement.dataset.theme).toBe("dark");
  });

  it("data-theme属性をlightに設定する", async () => {
    const { setTheme } = await import("../js/renderer");
    setTheme("dark");
    setTheme("light");
    expect(document.documentElement.dataset.theme).toBe("light");
  });
});
