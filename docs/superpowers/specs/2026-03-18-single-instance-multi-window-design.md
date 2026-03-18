# 単一インスタンス・複数ウィンドウ対応

## 概要

CLIから `mdv file.md` を実行したとき、既に同じファイルを開いているウィンドウがあれば新しいウィンドウを開かずにそのウィンドウをフォアグラウンドに出す。同じファイルを開いていなければ新しいウィンドウで開く。

## 背景

現状、CLIから `mdv` を実行するたびに独立したElectronプロセスが起動する。同じファイルを何度も開くと複数のウィンドウ（プロセス）が生まれる。

## 設計

### 単一インスタンス制御

`app.requestSingleInstanceLock()` でプロセスの単一性を保証する。

- 最初のプロセスがロックを取得する
- 2回目以降の起動はロック取得に失敗し、即 `app.quit()` する
- 既存プロセス側で `second-instance` イベントが発火し、渡された引数を処理する

### 複数ウィンドウ管理

現在の `mainWindow` 単一変数を `Map` に変更する。

```typescript
const windows = new Map<BrowserWindow, string | null>();
```

各ウィンドウにはファイルパス（絶対パス）が紐づく。ファイルを開いていないウィンドウは `null`。

ウィンドウごとの状態（ファイルパス、レンダリング済みHTML、ファイルウォッチャー）をまとめて管理する。

```typescript
interface WindowState {
  filePath: string | null;
  html: string;
  watcher: FSWatcher | null;
}
const windows = new Map<BrowserWindow, WindowState>();
```

ウィンドウの `closed` イベントで Map からエントリを削除し、ウォッチャーを `close()` する。

### パス正規化

ファイルパスの同一性判定には `realpathSync` で symlink を解決した上で比較する。

### second-instance イベントの処理フロー

`second-instance` コールバックは `(event, argv, workingDirectory)` を受け取る。

1. `argv` からファイルパスを抽出（オフセットは `app.isPackaged ? 1 : 2` と同様）し、`workingDirectory` を基底に `resolve` で絶対パスに変換。さらに `realpathSync` で正規化する
2. `windows` を走査して同じパスを開いているウィンドウを探す
3. 見つかった場合: `window.restore()`（minimizedの場合）→ `window.focus()`
4. 見つからなかった場合: `createWindow()` して `openFile()` で表示
5. 引数なしの場合: ファイルダイアログを表示（デフォルトディレクトリ `/`）

### ファイルダイアログ（メニューの Open 含む）

ファイルダイアログでファイルを選択したとき、既存ウィンドウが同じパスを開いていればそのウィンドウをフォーカスする。開いていなければ新しいウィンドウで開く。

### open-file イベント (macOS)

macOS のファイル関連付けで開かれた場合も同一パス検出を行い、既存ウィンドウがあればフォーカスする。

## 変更対象

`src/main.ts` のみ。

### 変更点

1. `mainWindow` 単一変数 → `Map` ベースのウィンドウ管理
2. ファイルウォッチャーをウィンドウ単位で管理
3. `app.requestSingleInstanceLock()` + `second-instance` イベント追加
4. `createWindow()` がウィンドウを返すように変更、Map に登録
5. `openFile()` がウィンドウを引数に取るように変更
6. 引数なし起動時はファイルダイアログを表示（デフォルトディレクトリ `/`）
7. メニューの `open-file-dialog` でも同一パス検出を行う
8. `open-file` イベントでも同一パス検出を行う
9. `currentHtml` グローバル変数 → `WindowState` 内で管理。`markdown:request-initial` IPC は `event.sender` から対応するウィンドウを特定し、そのウィンドウのHTMLを返す
10. `activate` イベント（Dockクリック時）はウィンドウが0個の場合のみファイルダイアログを表示

### 変更しないもの

- `resources/bin/mdv`（CLIスクリプト）
- `preload.ts`、`renderer.ts`、`markdown.ts`
- ウィンドウ状態の永続化（最後に閉じたウィンドウの状態を保存する現行動作を維持）

## Current Status

Not started.
