# mdv

![mdv icon](resources/icon.png)

CLIから起動できるMarkdownビューア。Mermaidダイアグラムのレンダリングとファイル変更時の自動更新に対応。

## インストール

```bash
git clone https://github.com/negipo/mdv.git
cd mdv
npm install
npm run install:local
```

## 使い方

```bash
mdv path/to/file.md
```

## 機能

- Markdownのレンダリング (GitHub風スタイル)
- シンタックスハイライト (shiki)
- Mermaidダイアグラムのレンダリング
- ファイル変更時の自動更新
- セッション復元

## 開発

Xcode (Command Line Tools含む) と Node.js が必要。

```bash
npm run build:js  # JSバンドルのビルド
npm test          # テスト実行
npm run lint      # 型チェック
npm run build     # JSバンドル + Xcodeビルド
```

## License

MIT
