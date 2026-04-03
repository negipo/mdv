const COPY_ICON = `<svg viewBox="0 0 16 16" fill="currentColor"><path d="M0 6.75C0 5.784.784 5 1.75 5h1.5a.75.75 0 0 1 0 1.5h-1.5a.25.25 0 0 0-.25.25v7.5c0 .138.112.25.25.25h7.5a.25.25 0 0 0 .25-.25v-1.5a.75.75 0 0 1 1.5 0v1.5A1.75 1.75 0 0 1 9.25 16h-7.5A1.75 1.75 0 0 1 0 14.25Z"/><path d="M5 1.75C5 .784 5.784 0 6.75 0h7.5C15.216 0 16 .784 16 1.75v7.5A1.75 1.75 0 0 1 14.25 11h-7.5A1.75 1.75 0 0 1 5 9.25Zm1.75-.25a.25.25 0 0 0-.25.25v7.5c0 .138.112.25.25.25h7.5a.25.25 0 0 0 .25-.25v-7.5a.25.25 0 0 0-.25-.25Z"/></svg>`;

const CHECK_ICON = `<svg viewBox="0 0 16 16" fill="currentColor"><path d="M13.78 4.22a.75.75 0 0 1 0 1.06l-7.25 7.25a.75.75 0 0 1-1.06 0L2.22 9.28a.751.751 0 0 1 .018-1.042.751.751 0 0 1 1.042-.018L6 10.94l6.72-6.72a.75.75 0 0 1 1.06 0Z"/></svg>`;

const FEEDBACK_DURATION_MS = 2000;

export function attachCopyButtons(container: HTMLElement): void {
  const pres = container.querySelectorAll<HTMLPreElement>("pre:not(.mermaid)");
  for (const pre of pres) {
    if (pre.querySelector(".copy-button")) continue;

    const btn = document.createElement("button");
    btn.className = "copy-button";
    btn.type = "button";
    btn.innerHTML = COPY_ICON;

    const tooltip = document.createElement("span");
    tooltip.className = "copy-tooltip";
    tooltip.textContent = "Copied!";

    const getText = (): string => {
      let text: string;
      const code = pre.querySelector("code");
      if (code) {
        text = code.textContent ?? "";
      } else {
        text = Array.from(pre.childNodes)
          .filter((n) => n !== btn && n !== tooltip)
          .map((n) => n.textContent ?? "")
          .join("");
      }
      return text.endsWith("\n") ? text : `${text}\n`;
    };

    btn.addEventListener("click", () => {
      const text = getText();
      navigator.clipboard
        .writeText(text)
        .then(() => {
          btn.innerHTML = CHECK_ICON;
          tooltip.classList.add("visible");
          setTimeout(() => {
            btn.innerHTML = COPY_ICON;
            tooltip.classList.remove("visible");
          }, FEEDBACK_DURATION_MS);
        })
        .catch(() => {});
    });

    pre.appendChild(tooltip);
    pre.appendChild(btn);
  }
}
