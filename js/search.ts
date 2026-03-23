export class SearchManager {
  private container: HTMLElement;
  private currentIndex = -1;
  private matchCount = 0;
  private query = "";

  constructor(container: HTMLElement) {
    this.container = container;
  }

  search(query: string): number {
    this.clearHighlights();
    this.query = query;
    this.currentIndex = -1;

    if (!query) {
      this.matchCount = 0;
      return 0;
    }

    this.highlightMatches(query);
    const marks = this.container.querySelectorAll("mark.search-highlight");
    this.matchCount = marks.length;

    if (this.matchCount > 0) {
      this.currentIndex = 0;
      marks[0].classList.add("current");
      (marks[0] as HTMLElement).scrollIntoView?.({ block: "center", behavior: "smooth" });
    }

    return this.matchCount;
  }

  next() {
    this.navigate(1);
  }

  prev() {
    this.navigate(-1);
  }

  clearHighlights() {
    const marks = this.container.querySelectorAll("mark.search-highlight");
    marks.forEach((mark) => {
      const parent = mark.parentNode;
      if (parent) {
        parent.replaceChild(document.createTextNode(mark.textContent || ""), mark);
        parent.normalize();
      }
    });
    this.matchCount = 0;
    this.currentIndex = -1;
  }

  close() {
    this.clearHighlights();
    this.query = "";
  }

  get count(): number {
    return this.matchCount;
  }

  get current(): number {
    return this.currentIndex;
  }

  private navigate(direction: number) {
    if (this.matchCount === 0) return;

    const marks = this.container.querySelectorAll("mark.search-highlight");
    if (this.currentIndex >= 0 && this.currentIndex < marks.length) {
      marks[this.currentIndex].classList.remove("current");
    }

    this.currentIndex = (this.currentIndex + direction + this.matchCount) % this.matchCount;
    marks[this.currentIndex].classList.add("current");
    (marks[this.currentIndex] as HTMLElement).scrollIntoView?.({ block: "center", behavior: "smooth" });
  }

  private highlightMatches(query: string) {
    const walker = document.createTreeWalker(
      this.container,
      NodeFilter.SHOW_TEXT,
      {
        acceptNode(node) {
          const parent = node.parentElement;
          if (!parent) return NodeFilter.FILTER_REJECT;
          if (parent.closest("pre.mermaid")) return NodeFilter.FILTER_REJECT;
          if (parent.tagName === "SCRIPT" || parent.tagName === "STYLE") return NodeFilter.FILTER_REJECT;
          return NodeFilter.FILTER_ACCEPT;
        },
      }
    );

    const textNodes: Text[] = [];
    let node: Node | null;
    while ((node = walker.nextNode())) {
      textNodes.push(node as Text);
    }

    const escapedQuery = query.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
    const regex = new RegExp(escapedQuery, "gi");

    for (const textNode of textNodes) {
      const text = textNode.textContent || "";
      if (!regex.test(text)) continue;
      regex.lastIndex = 0;

      const fragment = document.createDocumentFragment();
      let lastIndex = 0;
      let match: RegExpExecArray | null;

      while ((match = regex.exec(text)) !== null) {
        if (match.index > lastIndex) {
          fragment.appendChild(document.createTextNode(text.slice(lastIndex, match.index)));
        }
        const mark = document.createElement("mark");
        mark.className = "search-highlight";
        mark.textContent = match[0];
        fragment.appendChild(mark);
        lastIndex = regex.lastIndex;
      }

      if (lastIndex < text.length) {
        fragment.appendChild(document.createTextNode(text.slice(lastIndex)));
      }

      textNode.parentNode?.replaceChild(fragment, textNode);
    }
  }
}
