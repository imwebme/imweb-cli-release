# imweb-cli-release

[한국어](README.ko.md) | [日本語](README.ja.md) | [中文](README.zh-CN.md)

Public binary distribution repo for `imweb-cli`.

This repository contains public release assets, channel pointers, and the canonical installer entrypoint (`install/latest.sh` for macOS/Linux, `install/latest.ps1` for Windows).
It does not contain CLI source code.

## Install

- macOS/Linux: `https://raw.githubusercontent.com/imwebme/imweb-cli-release/main/install/latest.sh`
- Windows PowerShell: `https://raw.githubusercontent.com/imwebme/imweb-cli-release/main/install/latest.ps1`

Use `install/latest.sh` on macOS/Linux and `install/latest.ps1` on Windows.

```bash
curl -fsSL https://raw.githubusercontent.com/imwebme/imweb-cli-release/main/install/latest.sh | bash
```

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -Command "iex ((Invoke-WebRequest -UseBasicParsing 'https://raw.githubusercontent.com/imwebme/imweb-cli-release/main/install/latest.ps1').Content)"
```

The Windows installer works with Windows PowerShell 5.1 and PowerShell 7+. The default launcher path is `<InstallRoot>\bin\imweb.exe` under the selected `-InstallRoot`.

Homebrew, Scoop, npm, and npx are not official distribution channels for this repo. Use only the shell installer above for macOS/Linux and the PowerShell installer above for Windows.

## Channels

- `channels/stable.json`: pointer to the latest public stable release manifest
- `channels/edge.json`: pointer to the latest public edge release manifest

## License

The binaries, installer scripts, and release metadata in this repository are distributed under the [Imweb CLI Binary License](LICENSE).
This license does not grant rights to CLI source code or Imweb trademarks.

## Notes

- This repo does not contain source code or internal operating docs.
- Release and install files are managed by the `imweb-cli` publish workflow.
