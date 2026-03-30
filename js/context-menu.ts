export interface ContextMenuInfo {
  startLine: number | null;
  endLine: number | null;
}

export function findSourceLine(node: Node, charOffset?: number): number | null {
  let current: Node | null = node;
  while (current) {
    if (current instanceof HTMLElement) {
      const pre = current.closest("pre[data-source-line-end]");
      if (pre) {
        const startLine = Number(pre.getAttribute("data-source-line"));
        const codeEl = pre.querySelector("code");
        if (codeEl && charOffset != null) {
          const text = codeEl.textContent ?? "";
          const linesBeforeOffset =
            text.slice(0, charOffset).split("\n").length - 1;
          return startLine + 1 + linesBeforeOffset;
        }
        return startLine + 1;
      }
      const attr = current.getAttribute("data-source-line");
      if (attr) {
        return Number(attr);
      }
    }
    current = current.parentNode;
  }
  return null;
}

function computeCodeOffset(
  node: Node,
  offsetInNode: number,
): number | undefined {
  const element = node instanceof HTMLElement ? node : node.parentElement;
  if (!element) return undefined;
  const pre = element.closest("pre[data-source-line-end]");
  if (!pre) return undefined;
  const codeEl = pre.querySelector("code");
  if (!codeEl) return undefined;

  const walker = document.createTreeWalker(codeEl, NodeFilter.SHOW_TEXT);
  let offset = 0;
  for (let current = walker.nextNode(); current; current = walker.nextNode()) {
    if (current === node) {
      return offset + offsetInNode;
    }
    offset += (current.textContent ?? "").length;
  }
  return undefined;
}

export function getContextMenuInfo(): ContextMenuInfo {
  const selection = window.getSelection();
  if (selection && selection.rangeCount > 0 && !selection.isCollapsed) {
    const range = selection.getRangeAt(0);
    const startOffset = computeCodeOffset(
      range.startContainer,
      range.startOffset,
    );
    const endOffset = computeCodeOffset(range.endContainer, range.endOffset);
    const startLine = findSourceLine(range.startContainer, startOffset);
    const endLine = findSourceLine(range.endContainer, endOffset);
    if (startLine !== null && endLine !== null && startLine !== endLine) {
      return { startLine, endLine };
    }
    if (startLine !== null) {
      return { startLine, endLine: startLine };
    }
  }
  return { startLine: null, endLine: null };
}

let lastContextMenuEvent: MouseEvent | null = null;

export function getContextMenuInfoWithCaret(): ContextMenuInfo {
  const selectionInfo = getContextMenuInfo();
  if (selectionInfo.startLine !== null) {
    return selectionInfo;
  }
  if (lastContextMenuEvent) {
    const range = document.caretRangeFromPoint(
      lastContextMenuEvent.clientX,
      lastContextMenuEvent.clientY,
    );
    if (range) {
      const caretOffset = computeCodeOffset(
        range.startContainer,
        range.startOffset,
      );
      const line = findSourceLine(range.startContainer, caretOffset);
      if (line !== null) {
        return { startLine: line, endLine: line };
      }
    }
  }
  return { startLine: null, endLine: null };
}

export function setupContextMenu(): void {
  document.addEventListener("contextmenu", (event: MouseEvent) => {
    lastContextMenuEvent = event;
    const info = getContextMenuInfoWithCaret();
    if (window.webkit?.messageHandlers?.contextMenu) {
      window.webkit.messageHandlers.contextMenu.postMessage(info);
    }
  });
}
