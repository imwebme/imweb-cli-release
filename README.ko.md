# imweb-cli-release

[English](README.md) | [日本語](README.ja.md) | [中文](README.zh-CN.md)

`imweb-cli`의 공개 바이너리 배포 저장소입니다.

이 저장소에는 공개 release asset, channel pointer, 공식 installer entrypoint(`install/latest.sh`: macOS/Linux, `install/latest.ps1`: Windows)가 들어 있습니다.
CLI 소스 코드는 포함하지 않습니다.

## imweb-cli란?

`imweb-cli`는 아임웹 고객사가 터미널, 스크립트, 자동화 도구에서 아임웹 OpenAPI를 사용할 수 있게 하는 공식 CLI 앱입니다.

- 인증은 아임웹 OAuth와 아임웹 앱 설치 동의 절차를 사용합니다.
- 런타임 API 호출은 공개 아임웹 OpenAPI 스펙에 정의된 endpoint만 사용합니다.
- CLI 기능 구현을 위해 관리자 화면을 scraping하거나 비공개/internal API를 사용하지 않습니다.
- 프로덕션과 테스트 환경은 아임웹 사이트/API host와 OAuth 설정 기준으로 분리됩니다.

## 설치

- macOS/Linux: `https://raw.githubusercontent.com/imwebme/imweb-cli-release/main/install/latest.sh`
- Windows PowerShell: `https://raw.githubusercontent.com/imwebme/imweb-cli-release/main/install/latest.ps1`

macOS/Linux에서는 `install/latest.sh`, Windows에서는 `install/latest.ps1`만 사용합니다.

```bash
curl -fsSL https://raw.githubusercontent.com/imwebme/imweb-cli-release/main/install/latest.sh | bash
```

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -Command "iex ((Invoke-WebRequest -UseBasicParsing 'https://raw.githubusercontent.com/imwebme/imweb-cli-release/main/install/latest.ps1').Content)"
```

Windows installer는 Windows PowerShell 5.1과 PowerShell 7+에서 동작합니다. 기본 launcher path는 선택한 `-InstallRoot` 아래의 `<InstallRoot>\bin\imweb.exe`입니다.

Homebrew, Scoop, npm, npx는 이 저장소의 공식 배포 채널이 아닙니다. macOS/Linux는 위 shell installer만, Windows는 위 PowerShell installer만 사용합니다.

## 채널

- `channels/stable.json`: 최신 공개 stable release manifest pointer
- `channels/edge.json`: 최신 공개 edge release manifest pointer

## 라이선스

이 저장소의 바이너리, installer script, release metadata는 [Imweb CLI Binary License](LICENSE)에 따라 배포됩니다.
이 라이선스는 CLI 소스 코드나 Imweb 상표 사용권을 부여하지 않습니다.

## 참고

- 이 저장소에는 소스 코드나 내부 운영 문서가 없습니다.
- release 및 install 파일은 `imweb-cli` publish workflow가 관리합니다.
