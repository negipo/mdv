import { app, BrowserWindow, ipcMain, Menu, dialog, shell } from "electron";
import { watch, type FSWatcher } from "chokidar";
import { readFileSync, writeFileSync, mkdirSync, existsSync, realpathSync } from "node:fs";
import { resolve, join, basename } from "node:path";
import { renderMarkdown } from "./markdown";

interface PersistedWindowState {
  width: number;
  height: number;
  x?: number;
  y?: number;
}

interface WindowContext {
  html: string;
  watcher: FSWatcher | null;
  filePath: string | null;
}

const windows = new Map<BrowserWindow, WindowContext>();

const configDir = join(app.getPath("userData"), "mdv");
const configPath = join(configDir, "window-state.json");
const sessionPath = join(configDir, "session.json");

function loadWindowState(): PersistedWindowState {
  try {
    if (existsSync(configPath)) {
      return JSON.parse(readFileSync(configPath, "utf-8"));
    }
  } catch {}
  return { width: 900, height: 700 };
}

function saveWindowState(win: BrowserWindow) {
  if (win.isDestroyed()) return;
  const bounds = win.getBounds();
  const state: PersistedWindowState = {
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

function saveSession() {
  const filePaths: string[] = [];
  for (const [, ctx] of windows) {
    if (ctx.filePath) filePaths.push(ctx.filePath);
  }
  try {
    if (!existsSync(configDir)) {
      mkdirSync(configDir, { recursive: true });
    }
    writeFileSync(sessionPath, JSON.stringify(filePaths));
  } catch {}
}

function loadSession(): string[] {
  try {
    if (existsSync(sessionPath)) {
      return JSON.parse(readFileSync(sessionPath, "utf-8"));
    }
  } catch {}
  return [];
}

function getFilePathFromArgv(argv: string[], workingDirectory: string): string | null {
  const args = argv.slice(app.isPackaged ? 1 : 2);
  const filePath = args.find((arg) => !arg.startsWith("-") && !arg.startsWith("--"));
  return filePath ? resolve(workingDirectory, filePath) : null;
}

function loadAndRender(filePath: string): string {
  const markdown = readFileSync(filePath, "utf-8");
  return renderMarkdown(markdown);
}

function openFile(win: BrowserWindow, filePath: string) {
  const ctx = windows.get(win);
  if (!ctx) return;

  if (ctx.watcher) {
    ctx.watcher.close();
    ctx.watcher = null;
  }

  ctx.filePath = filePath;
  ctx.html = loadAndRender(filePath);
  win.webContents.send("markdown:update", ctx.html);
  win.setTitle(`mdv - ${basename(filePath)}`);
  saveSession();

  ctx.watcher = watch(filePath, {
    persistent: true,
    awaitWriteFinish: { stabilityThreshold: 100, pollInterval: 50 },
  });

  ctx.watcher.on("change", () => {
    if (win.isDestroyed()) return;
    ctx.html = loadAndRender(filePath);
    win.webContents.send("markdown:update", ctx.html);
  });
}

function findWindowByPath(filePath: string): BrowserWindow | null {
  for (const [win, ctx] of windows) {
    if (ctx.filePath === filePath) return win;
  }
  return null;
}

function focusWindow(win: BrowserWindow) {
  if (win.isMinimized()) win.restore();
  app.focus({ steal: true });
  win.focus();
}

function openOrFocusFile(filePath: string) {
  let normalized: string;
  try {
    normalized = realpathSync(filePath);
  } catch {
    dialog.showErrorBox("ファイルを開けません", `${filePath} が見つかりません`);
    return;
  }
  const existing = findWindowByPath(normalized);
  if (existing) {
    focusWindow(existing);
    return;
  }
  const win = createWindow();
  openFile(win, normalized);
}

async function showOpenDialog() {
  app.focus({ steal: true });
  const result = await dialog.showOpenDialog({
    properties: ["openFile"],
    defaultPath: "/",
    filters: [{ name: "Markdown", extensions: ["md", "markdown", "txt"] }],
  });
  if (!result.canceled && result.filePaths.length > 0) {
    openOrFocusFile(result.filePaths[0]);
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

function createWindow(): BrowserWindow {
  const state = loadWindowState();
  const win = new BrowserWindow({
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

  windows.set(win, { html: "", watcher: null, filePath: null });

  win.loadFile(join(__dirname, "renderer", "index.html"));

  win.webContents.on("will-navigate", (event, url) => {
    event.preventDefault();
    try {
      const parsed = new URL(url);
      if (parsed.protocol === "https:" || parsed.protocol === "http:") {
        shell.openExternal(url);
      }
    } catch {}
  });

  win.webContents.setWindowOpenHandler(({ url }) => {
    try {
      const parsed = new URL(url);
      if (parsed.protocol === "https:" || parsed.protocol === "http:") {
        shell.openExternal(url);
      }
    } catch {}
    return { action: "deny" };
  });

  win.on("resize", () => saveWindowState(win));
  win.on("move", () => saveWindowState(win));
  win.on("closed", () => {
    const ctx = windows.get(win);
    if (ctx?.watcher) {
      ctx.watcher.close();
    }
    windows.delete(win);
  });

  return win;
}

const pendingFilePaths: string[] = [];

app.on("open-file", (event, path) => {
  event.preventDefault();
  if (app.isReady()) {
    openOrFocusFile(path);
  } else {
    pendingFilePaths.push(path);
  }
});

const gotTheLock = app.requestSingleInstanceLock();

if (!gotTheLock) {
  app.quit();
} else {
  app.on("second-instance", (_event, argv, workingDirectory) => {
    const filePath = getFilePathFromArgv(argv, workingDirectory);
    if (filePath) {
      openOrFocusFile(filePath);
    } else {
      showOpenDialog();
    }
  });

  app.whenReady().then(() => {
    buildMenu();

    ipcMain.on("markdown:request-initial", (event) => {
      const win = BrowserWindow.fromWebContents(event.sender);
      if (!win) return;
      const ctx = windows.get(win);
      if (ctx) {
        event.sender.send("markdown:update", ctx.html);
      }
    });

    if (pendingFilePaths.length > 0) {
      for (const p of pendingFilePaths) {
        openOrFocusFile(p);
      }
      pendingFilePaths.length = 0;
    } else {
      const filePath = getFilePathFromArgv(process.argv, process.cwd());
      if (filePath) {
        openOrFocusFile(filePath);
      } else {
        const sessionFiles = loadSession();
        if (sessionFiles.length > 0) {
          for (const p of sessionFiles) {
            if (existsSync(p)) {
              openOrFocusFile(p);
            }
          }
        }
        if (BrowserWindow.getAllWindows().length === 0) {
          showOpenDialog();
        }
      }
    }

    app.on("activate", () => {
      if (BrowserWindow.getAllWindows().length === 0) {
        showOpenDialog();
      }
    });
  });

  app.on("before-quit", () => {
    saveSession();
  });

  app.on("window-all-closed", () => {
    if (process.platform !== "darwin") {
      app.quit();
    }
  });
}
