# imweb-cli-release

[English](README.md) | [한국어](README.ko.md) | [中文](README.zh-CN.md)

`imweb-cli` の公開バイナリ配布リポジトリです。

このリポジトリには、公開 release asset、channel pointer、公式 installer entrypoint（macOS/Linux は `install/latest.sh`、Windows は `install/latest.ps1`）が含まれます。
CLI のソースコードは含まれません。

## インストール

- macOS/Linux: `https://raw.githubusercontent.com/imwebme/imweb-cli-release/main/install/latest.sh`
- Windows PowerShell: `https://raw.githubusercontent.com/imwebme/imweb-cli-release/main/install/latest.ps1`

macOS/Linux では `install/latest.sh`、Windows では `install/latest.ps1` のみを使用します。

```bash
curl -fsSL https://raw.githubusercontent.com/imwebme/imweb-cli-release/main/install/latest.sh | bash
```

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -Command "iex ((Invoke-WebRequest -UseBasicParsing 'https://raw.githubusercontent.com/imwebme/imweb-cli-release/main/install/latest.ps1').Content)"
```

Windows installer は Windows PowerShell 5.1 と PowerShell 7+ で動作します。既定の launcher path は、選択した `-InstallRoot` 配下の `<InstallRoot>\bin\imweb.exe` です。

Homebrew、Scoop、npm、npx はこのリポジトリの公式配布チャネルではありません。macOS/Linux では上記の shell installer のみ、Windows では上記の PowerShell installer のみを使用してください。

## チャネル

- `channels/stable.json`: 最新の公開 stable release manifest pointer
- `channels/edge.json`: 最新の公開 edge release manifest pointer

## ライセンス

このリポジトリのバイナリ、installer script、release metadata は [Imweb CLI Binary License](LICENSE) に基づいて配布されます。
このライセンスは CLI ソースコードまたは Imweb 商標の権利を付与しません。

## 備考

- このリポジトリにはソースコードや内部運用文書は含まれません。
- release と install ファイルは `imweb-cli` publish workflow によって管理されます。
