import { build } from "esbuild";
import { cpSync, globSync } from "node:fs";

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
