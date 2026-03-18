# mdv

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
- Mermaidダイアグラムのレンダリング
- ファイル変更時の自動更新

## 開発

```bash
npm run build    # ビルド
npm test         # テスト実行
npm run lint     # 型チェック
npm run dev -- path/to/file.md  # ビルド+起動
```

## License

MIT
