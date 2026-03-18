# リンクテスト

## 通常のリンク（デフォルトブラウザで開くべき）

- [Google](https://www.google.com)
- [GitHub](https://github.com)

## 危険なリンク（ブロックされるべき）

- [javascript攻撃](javascript:alert('XSS'))
- [fileプロトコル](file:///etc/passwd)
- [dataプロトコル](data:text/html,<h1>evil</h1>)

## 生HTML（DOMPurifyでサニタイズされるべき）

<a href="javascript:alert('raw-html-xss')">生HTMLのjavascriptリンク</a>

<img src=x onerror="alert('img-xss')">

<a href="https://example.com">生HTMLの通常リンク</a>

## 画像リンク

![alt text](https://via.placeholder.com/150)
