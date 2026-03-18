import { app, BrowserWindow, ipcMain } from "electron";
import { watch } from "chokidar";
import { readFileSync, writeFileSync, mkdirSync, existsSync } from "node:fs";
import { resolve, join } from "node:path";
import { renderMarkdown } from "./markdown";

let mainWindow: BrowserWindow | null = null;
let currentHtml = "";

const configDir = join(app.getPath("userData"), "mdv");
const configPath = join(configDir, "window-state.json");

interface WindowState {
  width: number;
  height: number;
  x?: number;
  y?: number;
}

function loadWindowState(): WindowState {
  try {
    if (existsSync(configPath)) {
      return JSON.parse(readFileSync(configPath, "utf-8"));
    }
  } catch {}
  return { width: 900, height: 700 };
}

function saveWindowState() {
  if (!mainWindow) return;
  const bounds = mainWindow.getBounds();
  const state: WindowState = {
    width: bounds.width,
    height: bounds.height,
    x: bounds.x,
    y: bounds.y,
  };
  try {
    if (!existsSync(configDir)) {
      mkdirSync(configDir, { recursive: true });
    }
    writeFileSync(configPath, JSON.stringify(state));
  } catch {}
}

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
  const state = loadWindowState();
  mainWindow = new BrowserWindow({
    width: state.width,
    height: state.height,
    x: state.x,
    y: state.y,
    title: "mdv",
    webPreferences: {
      preload: join(__dirname, "preload.js"),
      contextIsolation: true,
      nodeIntegration: false,
    },
  });

  mainWindow.loadFile(join(__dirname, "renderer", "index.html"));
  mainWindow.on("resize", saveWindowState);
  mainWindow.on("move", saveWindowState);
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
