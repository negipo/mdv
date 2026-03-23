export function computeZoom(
  cursorX: number,
  cursorY: number,
  oldScale: number,
  newScale: number,
  translateX: number,
  translateY: number,
  minScale: number = 1.0,
  maxScale: number = 5.0
): { scale: number; translateX: number; translateY: number } {
  const clampedScale = Math.max(minScale, Math.min(maxScale, newScale));
  if (clampedScale === oldScale) {
    return { scale: oldScale, translateX, translateY };
  }
  const ratio = clampedScale / oldScale;
  const newTranslateX = cursorX - (cursorX - translateX) * ratio;
  const newTranslateY = cursorY - (cursorY - translateY) * ratio;
  return { scale: clampedScale, translateX: newTranslateX, translateY: newTranslateY };
}

export function isDrag(
  startX: number,
  startY: number,
  endX: number,
  endY: number,
  threshold: number = 5
): boolean {
  const dx = endX - startX;
  const dy = endY - startY;
  return Math.sqrt(dx * dx + dy * dy) > threshold;
}
