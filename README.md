# imweb-cli-release

Public distribution repo for `imweb-cli`.

This repository contains public release assets, channel pointers, and the canonical installer entrypoint (`install/latest.sh` for macOS/Linux, `install/latest.ps1` for Windows).
It does not contain CLI source code.

## Install

- macOS/Linux: `https://raw.githubusercontent.com/imwebme/imweb-cli-release/main/install/latest.sh`
- Windows PowerShell: `https://raw.githubusercontent.com/imwebme/imweb-cli-release/main/install/latest.ps1`

macOS/Linux에서는 `install/latest.sh`, Windows에서는 `install/latest.ps1`만 사용합니다.

```bash
curl -fsSL https://raw.githubusercontent.com/imwebme/imweb-cli-release/main/install/latest.sh | bash
```

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -Command "iex ((Invoke-WebRequest -UseBasicParsing 'https://raw.githubusercontent.com/imwebme/imweb-cli-release/main/install/latest.ps1').Content)"
```

Windows installer는 Windows PowerShell 5.1 / PowerShell 7+에서 동작하며, 기본 launcher path는 선택된 `-InstallRoot` 기준 `<InstallRoot>\bin\imweb.exe`입니다.

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
