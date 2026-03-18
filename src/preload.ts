import { contextBridge, ipcRenderer } from "electron";

contextBridge.exposeInMainWorld("electronAPI", {
  onMarkdownUpdate: (callback: (event: any, html: string) => void) => {
    ipcRenderer.on("markdown:update", callback);
  },
  requestInitialContent: () => {
    ipcRenderer.send("markdown:request-initial");
  },
});
