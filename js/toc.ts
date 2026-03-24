export class TocManager {
  private container: HTMLElement;
  private tocPane: HTMLElement;
  private observer: IntersectionObserver | null = null;
  private visibleHeadings: Set<HTMLElement> = new Set();

  constructor(container: HTMLElement, tocPane: HTMLElement) {
    this.container = container;
    this.tocPane = tocPane;
  }

  update() {
    this.teardownObserver();
    this.tocPane.innerHTML = "";

    const headings = this.container.querySelectorAll<HTMLElement>("h1, h2, h3, h4, h5, h6");
    const items: HTMLElement[] = [];

    headings.forEach((heading) => {
      const item = document.createElement("div");
      item.className = "toc-item";
      const level = parseInt(heading.tagName[1], 10);
      item.setAttribute("data-level", String(level));
      item.textContent = heading.textContent;
      item.addEventListener("click", () => {
        heading.scrollIntoView({ behavior: "smooth", block: "start" });
      });
      this.tocPane.appendChild(item);
      items.push(item);
    });

    this.setupObserver(headings, items);
  }

  toggle() {
    document.body.classList.toggle("toc-visible");
  }

  show() {
    document.body.classList.add("toc-visible");
  }

  hide() {
    document.body.classList.remove("toc-visible");
  }

  private setupObserver(headings: NodeListOf<HTMLElement>, items: HTMLElement[]) {
    if (headings.length === 0) return;

    this.visibleHeadings = new Set();
    const headingToItem = new Map<HTMLElement, HTMLElement>();
    headings.forEach((h, i) => headingToItem.set(h, items[i]));

    this.observer = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (entry.isIntersecting) {
            this.visibleHeadings.add(entry.target as HTMLElement);
          } else {
            this.visibleHeadings.delete(entry.target as HTMLElement);
          }
        });
        this.highlightCurrent(headingToItem);
      },
      { root: null, threshold: 0 }
    );

    headings.forEach((h) => this.observer!.observe(h));
  }

  private highlightCurrent(headingToItem: Map<HTMLElement, HTMLElement>) {
    this.tocPane.querySelectorAll(".toc-item.active").forEach((el) => {
      el.classList.remove("active");
    });

    let topmost: HTMLElement | null = null;
    let topmostTop = Infinity;

    this.visibleHeadings.forEach((h) => {
      const rect = h.getBoundingClientRect();
      if (rect.top < topmostTop) {
        topmostTop = rect.top;
        topmost = h;
      }
    });

    if (!topmost) return;

    const item = headingToItem.get(topmost);
    if (item) {
      item.classList.add("active");
    }
  }

  private teardownObserver() {
    if (this.observer) {
      this.observer.disconnect();
      this.observer = null;
    }
    this.visibleHeadings.clear();
  }
}
