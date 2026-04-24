# imweb-cli-release

[English](README.md) | [한국어](README.ko.md) | [日本語](README.ja.md)

这是 `imweb-cli` 的公开二进制分发仓库。

此仓库包含公开 release asset、channel pointer，以及官方 installer entrypoint（macOS/Linux 使用 `install/latest.sh`，Windows 使用 `install/latest.ps1`）。
此仓库不包含 CLI 源代码。

## 安装

- macOS/Linux: `https://raw.githubusercontent.com/imwebme/imweb-cli-release/main/install/latest.sh`
- Windows PowerShell: `https://raw.githubusercontent.com/imwebme/imweb-cli-release/main/install/latest.ps1`

macOS/Linux 仅使用 `install/latest.sh`，Windows 仅使用 `install/latest.ps1`。

```bash
curl -fsSL https://raw.githubusercontent.com/imwebme/imweb-cli-release/main/install/latest.sh | bash
```

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -Command "iex ((Invoke-WebRequest -UseBasicParsing 'https://raw.githubusercontent.com/imwebme/imweb-cli-release/main/install/latest.ps1').Content)"
```

Windows installer 支持 Windows PowerShell 5.1 和 PowerShell 7+。默认 launcher path 是所选 `-InstallRoot` 下的 `<InstallRoot>\bin\imweb.exe`。

Homebrew、Scoop、npm、npx 不是此仓库的官方分发渠道。macOS/Linux 请仅使用上面的 shell installer，Windows 请仅使用上面的 PowerShell installer。

## 渠道

- `channels/stable.json`: 指向最新公开 stable release manifest 的 pointer
- `channels/edge.json`: 指向最新公开 edge release manifest 的 pointer

## 许可证

此仓库中的二进制文件、installer script 和 release metadata 根据 [Imweb CLI Binary License](LICENSE) 分发。
此许可证不授予 CLI 源代码或 Imweb 商标的使用权。

## 备注

- 此仓库不包含源代码或内部运维文档。
- release 和 install 文件由 `imweb-cli` publish workflow 管理。
