# mdv

macOS向けMarkdownビューアアプリ。Swift (AppKit) + TypeScript (marked, mermaid, shiki) で構成。

## ビルド・テスト

```bash
npm ci
npm run test:js    # JSテスト (vitest)
npm run test:swift # Swiftテスト (xcodegen + xcodebuild)
npm run build      # フルビルド
```

## 開発ルール

- PRを作成してmainにマージすること。mainへの直接pushは避ける。
