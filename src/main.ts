import { app, BrowserWindow, ipcMain } from "electron";
import { watch } from "chokidar";
import { readFileSync } from "node:fs";
import { resolve, join } from "node:path";
import { renderMarkdown } from "./markdown";

let mainWindow: BrowserWindow | null = null;
let currentHtml = "";

function getFilePath(): string {
  const args = process.argv.slice(app.isPackaged ? 1 : 2);
  const filePath = args.find((arg) => !arg.startsWith("-") && !arg.startsWith("--"));
  if (!filePath) {
    console.error("Usage: mdv <file.md>");
    process.exit(1);
  }
  return resolve(filePath);
}

function loadAndRender(filePath: string): string {
  const markdown = readFileSync(filePath, "utf-8");
  return renderMarkdown(markdown);
}

function createWindow() {
  mainWindow = new BrowserWindow({
    width: 900,
    height: 700,
    title: "mdv",
    webPreferences: {
      preload: join(__dirname, "preload.js"),
      contextIsolation: true,
      nodeIntegration: false,
    },
  });

  mainWindow.loadFile(join(__dirname, "renderer", "index.html"));
  mainWindow.on("closed", () => {
    mainWindow = null;
  });
}

app.whenReady().then(() => {
  const filePath = getFilePath();
  currentHtml = loadAndRender(filePath);

  createWindow();

  ipcMain.on("markdown:request-initial", (event) => {
    event.sender.send("markdown:update", currentHtml);
  });

  const watcher = watch(filePath, {
    persistent: true,
    awaitWriteFinish: { stabilityThreshold: 100, pollInterval: 50 },
  });

  watcher.on("change", () => {
    currentHtml = loadAndRender(filePath);
    mainWindow?.webContents.send("markdown:update", currentHtml);
  });

  const basename = filePath.split("/").pop() || "mdv";
  mainWindow!.setTitle(`mdv - ${basename}`);
});

app.on("window-all-closed", () => {
  app.quit();
});
