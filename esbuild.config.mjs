import { cpSync, globSync } from "node:fs";
import { build } from "esbuild";

await build({
  entryPoints: ["js/renderer.ts"],
  bundle: true,
  outfile: "mdv/Resources/renderer.js",
  platform: "browser",
  format: "iife",
  sourcemap: true,
  target: "es2022",
});

const wasmFiles = globSync("node_modules/shiki/dist/*.wasm");
for (const wasm of wasmFiles) {
  const filename = wasm.split("/").pop();
  cpSync(wasm, `mdv/Resources/${filename}`);
}

import { readFileSync, writeFileSync } from "node:fs";

const katexCss = readFileSync(
  "node_modules/katex/dist/katex.min.css",
  "utf8",
).replace(/fonts\//g, "");
writeFileSync("mdv/Resources/katex.min.css", katexCss);

const katexFonts = globSync("node_modules/katex/dist/fonts/*.woff2");
for (const font of katexFonts) {
  const filename = font.split("/").pop();
  cpSync(font, `mdv/Resources/${filename}`);
}
