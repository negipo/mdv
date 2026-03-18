import { app, BrowserWindow, ipcMain, Menu, dialog } from "electron";
import { watch, type FSWatcher } from "chokidar";
import { readFileSync, writeFileSync, mkdirSync, existsSync } from "node:fs";
import { resolve, join, basename } from "node:path";
import { renderMarkdown } from "./markdown";

let mainWindow: BrowserWindow | null = null;
let currentHtml = "";
let currentWatcher: FSWatcher | null = null;

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

function getFilePathFromArgs(): string | null {
  const args = process.argv.slice(app.isPackaged ? 1 : 2);
  const filePath = args.find((arg) => !arg.startsWith("-") && !arg.startsWith("--"));
  return filePath ? resolve(filePath) : null;
}

function loadAndRender(filePath: string): string {
  const markdown = readFileSync(filePath, "utf-8");
  return renderMarkdown(markdown);
}

function openFile(filePath: string) {
  if (currentWatcher) {
    currentWatcher.close();
    currentWatcher = null;
  }

  currentHtml = loadAndRender(filePath);
  mainWindow?.webContents.send("markdown:update", currentHtml);
  mainWindow?.setTitle(`mdv - ${basename(filePath)}`);

  currentWatcher = watch(filePath, {
    persistent: true,
    awaitWriteFinish: { stabilityThreshold: 100, pollInterval: 50 },
  });

  currentWatcher.on("change", () => {
    currentHtml = loadAndRender(filePath);
    mainWindow?.webContents.send("markdown:update", currentHtml);
  });
}

async function showOpenDialog() {
  const result = await dialog.showOpenDialog({
    properties: ["openFile"],
    filters: [{ name: "Markdown", extensions: ["md", "markdown", "txt"] }],
  });
  if (!result.canceled && result.filePaths.length > 0) {
    openFile(result.filePaths[0]);
  }
}

function buildMenu() {
  const template: Electron.MenuItemConstructorOptions[] = [
    {
      label: app.name,
      submenu: [
        { role: "about" },
        { type: "separator" },
        { role: "hide" },
        { role: "hideOthers" },
        { role: "unhide" },
        { type: "separator" },
        { role: "quit" },
      ],
    },
    {
      label: "File",
      submenu: [
        {
          label: "Open...",
          accelerator: "CmdOrCtrl+O",
          click: () => showOpenDialog(),
        },
        { type: "separator" },
        { role: "close" },
      ],
    },
    {
      label: "Edit",
      submenu: [
        { role: "copy" },
        { role: "selectAll" },
      ],
    },
    {
      label: "View",
      submenu: [
        { role: "reload" },
        { role: "toggleDevTools" },
        { type: "separator" },
        { role: "resetZoom" },
        { role: "zoomIn" },
        { role: "zoomOut" },
        { type: "separator" },
        { role: "togglefullscreen" },
      ],
    },
    {
      label: "Window",
      submenu: [
        { role: "minimize" },
        { role: "zoom" },
      ],
    },
  ];
  Menu.setApplicationMenu(Menu.buildFromTemplate(template));
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

app.on("open-file", (event, path) => {
  event.preventDefault();
  if (mainWindow) {
    openFile(path);
  } else {
    app.whenReady().then(() => {
      if (!mainWindow) {
        createWindow();
      }
      openFile(path);
    });
  }
});

app.whenReady().then(() => {
  buildMenu();
  createWindow();

  ipcMain.on("markdown:request-initial", (event) => {
    event.sender.send("markdown:update", currentHtml);
  });

  const filePath = getFilePathFromArgs();
  if (filePath) {
    openFile(filePath);
  }

  app.on("activate", () => {
    if (BrowserWindow.getAllWindows().length === 0) {
      createWindow();
    }
  });
});

app.on("window-all-closed", () => {
  if (process.platform !== "darwin") {
    app.quit();
  }
});
