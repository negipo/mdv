export class TocManager {
  private container: HTMLElement;
  private tocPane: HTMLElement;

  constructor(container: HTMLElement, tocPane: HTMLElement) {
    this.container = container;
    this.tocPane = tocPane;
  }

  update() {
    this.tocPane.innerHTML = "";

    const headings = this.container.querySelectorAll<HTMLElement>("h1, h2, h3, h4, h5, h6");

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
    });
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
}
