import { describe, expect, it } from "vitest";
import { computeZoom, isDrag } from "../js/zoom";

describe("computeZoom", () => {
  it("カーソル位置に応じたtranslate補正が計算される", () => {
    const result = computeZoom(400, 300, 1.0, 1.1, 0, 0);
    expect(result.scale).toBeCloseTo(1.1);
    expect(result.translateX).toBeCloseTo(400 - 400 * 1.1);
    expect(result.translateY).toBeCloseTo(300 - 300 * 1.1);
  });

  it("ズームアウトが下限1.0でクランプされる", () => {
    const result = computeZoom(400, 300, 1.0, 0.9, 0, 0);
    expect(result.scale).toBe(1.0);
    expect(result.translateX).toBe(0);
    expect(result.translateY).toBe(0);
  });

  it("ズームインが上限5.0でクランプされる", () => {
    const result = computeZoom(400, 300, 4.8, 5.5, 0, 0);
    expect(result.scale).toBe(5.0);
  });

  it("スケールが変化しない場合はtranslateもそのまま返す", () => {
    const result = computeZoom(400, 300, 1.0, 0.5, 10, 20);
    expect(result.scale).toBe(1.0);
    expect(result.translateX).toBe(10);
    expect(result.translateY).toBe(20);
  });

  it("連続ズームでカーソル位置が固定される", () => {
    let s = 1.0,
      tx = 0,
      ty = 0;
    const cx = 200,
      cy = 150;
    for (let i = 0; i < 5; i++) {
      const r = computeZoom(cx, cy, s, s * 1.1, tx, ty);
      s = r.scale;
      tx = r.translateX;
      ty = r.translateY;
    }
    const pointX = (cx - tx) / s;
    const pointY = (cy - ty) / s;
    expect(pointX).toBeCloseTo(200);
    expect(pointY).toBeCloseTo(150);
  });
});

describe("isDrag", () => {
  it("5px以下の移動はドラッグではない", () => {
    expect(isDrag(100, 100, 103, 104)).toBe(false);
  });

  it("5px超の移動はドラッグ", () => {
    expect(isDrag(100, 100, 110, 100)).toBe(true);
  });

  it("移動なしはドラッグではない", () => {
    expect(isDrag(100, 100, 100, 100)).toBe(false);
  });
});
