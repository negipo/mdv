import { build } from "esbuild";
import { cpSync } from "node:fs";

cpSync("src/renderer/index.html", "dist/renderer/index.html");
cpSync("src/renderer/style.css", "dist/renderer/style.css");

await build({
  entryPoints: ["src/renderer/renderer.ts"],
  bundle: true,
  outfile: "dist/renderer/renderer.js",
  platform: "browser",
  format: "iife",
  sourcemap: true,
  target: "es2022",
});
