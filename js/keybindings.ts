export function setupKeybindings(): void {
  document.addEventListener("keydown", (e: KeyboardEvent) => {
    if (e.metaKey || e.ctrlKey || e.altKey) return;

    const searchInput = document.getElementById("search-input");
    if (searchInput && document.activeElement === searchInput) return;

    const overlay = document.getElementById("mermaid-overlay");
    if (overlay?.classList.contains("active")) return;

    switch (e.key) {
      case "j":
        window.scrollBy({ top: window.innerHeight / 2, behavior: "smooth" });
        e.preventDefault();
        break;
      case "k":
        window.scrollBy({ top: -window.innerHeight / 2, behavior: "smooth" });
        e.preventDefault();
        break;
      case "g":
        window.scrollTo({ top: 0, behavior: "smooth" });
        e.preventDefault();
        break;
      case "G":
        window.scrollTo({
          top: document.body.scrollHeight,
          behavior: "smooth",
        });
        e.preventDefault();
        break;
    }
  });
}
