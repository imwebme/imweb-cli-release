#!/usr/bin/env bash
set -euo pipefail

CHANNEL_URL="https://raw.githubusercontent.com/imwebme/imweb-cli-release/main/channels/stable.json"
INSTALL_ROOT="${HOME}/.local/share/imweb-cli"
BIN_DIR="${HOME}/.local/bin"
FORCE=0

usage() {
  cat <<'USAGE'
imweb CLI public stable installer

Usage:
  ./latest.sh [--install-root PATH] [--bin-dir PATH] [--force]
  ./latest.sh --help

Options:
  --install-root  CLI 설치 루트. 기본값: $HOME/.local/share/imweb-cli
  --bin-dir       실행 파일 링크를 둘 디렉터리. 기본값: $HOME/.local/bin
  --force         이미 같은 버전이 있어도 다시 설치
  --help          도움말 출력

동작 원칙:
  - public stable channel pointer를 읽고 release-manifest -> install-manifest -> platform archive 순서로 해석합니다.
  - private GitHub repo 권한이나 gh auth를 요구하지 않습니다.
  - 현재 플랫폼용 archive 하나만 내려받아 checksum 검증 후 설치합니다.
  - Unix self-update canonical launcher contract는 현재 사용자 home 기준 기본 `~/.local/bin/imweb`만 포함하며, custom `--install-root`와 조합돼도 이 실제 home launcher를 쓰면 동일하게 인식합니다.
  - custom `--bin-dir`는 설치 편의용 manual path일 뿐이며 direct detection / self-update contract에는 포함되지 않습니다.
USAGE
}

fail() {
  printf '오류: %s\n' "$1" >&2
  exit 1
}

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || fail "필수 명령을 찾지 못했습니다: $1"
}

detect_platform() {
  local os arch
  os=$(uname -s)
  arch=$(uname -m)

  case "$os" in
    Darwin) os="macos" ;;
    Linux) os="linux" ;;
    *)
      fail "지원하지 않는 운영체제입니다: $os"
      ;;
  esac

  case "$arch" in
    x86_64|amd64) arch="x86_64" ;;
    i386|i486|i586|i686) arch="i686" ;;
    arm64|aarch64) arch="arm64" ;;
    armv7l|armv7*) arch="armv7" ;;
    *)
      fail "지원하지 않는 아키텍처입니다: $arch"
      ;;
  esac

  printf '%s-%s' "$os" "$arch"
}

fetch_url() {
  local url="$1"
  curl -fsSL "$url"
}

sha256_file() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | awk '{print $1}'
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$1" | awk '{print $1}'
  else
    openssl dgst -sha256 "$1" | awk '{print $2}'
  fi
}

extract_archive() {
  local archive="$1"
  local destination="$2"

  mkdir -p "$destination"

  case "$archive" in
    *.tar.gz)
      tar -xzf "$archive" -C "$destination"
      ;;
    *.zip)
      need_cmd unzip
      unzip -q "$archive" -d "$destination"
      ;;
    *)
      fail "지원하지 않는 archive 형식입니다: $archive"
      ;;
  esac
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --install-root)
      [[ $# -ge 2 ]] || fail '--install-root 값이 필요합니다.'
      INSTALL_ROOT="$2"
      shift 2
      ;;
    --bin-dir)
      [[ $# -ge 2 ]] || fail '--bin-dir 값이 필요합니다.'
      BIN_DIR="$2"
      shift 2
      ;;
    --force)
      FORCE=1
      shift
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      fail "알 수 없는 옵션입니다: $1"
      ;;
  esac
done

need_cmd python3
need_cmd curl
need_cmd tar

PLATFORM=$(detect_platform)

CHANNEL_JSON="$(fetch_url "$CHANNEL_URL")" || fail "stable channel pointer를 읽지 못했습니다: $CHANNEL_URL"
RELEASE_MANIFEST_URL="$(
  CHANNEL_JSON="$CHANNEL_JSON" python3 - <<'PY'
import json
import os

data = json.loads(os.environ["CHANNEL_JSON"])
value = data.get("release_manifest_url") or ""
print(value)
PY
)"
[[ -n "$RELEASE_MANIFEST_URL" ]] || fail "stable channel pointer에 release_manifest_url이 없습니다."

RELEASE_MANIFEST_JSON="$(fetch_url "$RELEASE_MANIFEST_URL")" || fail "release-manifest를 읽지 못했습니다: $RELEASE_MANIFEST_URL"
release_values=()
while IFS= read -r line; do
  release_values+=("$line")
done < <(
  RELEASE_MANIFEST_JSON="$RELEASE_MANIFEST_JSON" python3 - <<'PY'
import json
import os

data = json.loads(os.environ["RELEASE_MANIFEST_JSON"])
print(data.get("version", ""))
print(data.get("tag", ""))
print(((data.get("metadata_assets") or {}).get("curl_install_manifest") or {}).get("url", ""))
PY
)

VERSION="${release_values[0]:-}"
TAG="${release_values[1]:-}"
INSTALL_MANIFEST_URL="${release_values[2]:-}"
[[ -n "$VERSION" ]] || fail 'release-manifest에서 version을 읽지 못했습니다.'
[[ -n "$INSTALL_MANIFEST_URL" ]] || fail 'release-manifest에서 install-manifest URL을 읽지 못했습니다.'

INSTALL_MANIFEST_JSON="$(fetch_url "$INSTALL_MANIFEST_URL")" || fail "install-manifest를 읽지 못했습니다: $INSTALL_MANIFEST_URL"
asset_values=()
while IFS= read -r line; do
  asset_values+=("$line")
done < <(
  INSTALL_MANIFEST_JSON="$INSTALL_MANIFEST_JSON" python3 - "$PLATFORM" <<'PY'
import json
import os
import sys

platform = sys.argv[1]
data = json.loads(os.environ["INSTALL_MANIFEST_JSON"])
platforms = data.get("platforms") or {}
match = platforms.get(platform) or {}
print(match.get("url", ""))
print(match.get("sha256", ""))
PY
)

ASSET_URL="${asset_values[0]:-}"
ASSET_SHA="${asset_values[1]:-}"
[[ -n "$ASSET_URL" ]] || fail "install-manifest에 현재 플랫폼 자산이 없습니다: $PLATFORM"
[[ -n "$ASSET_SHA" ]] || fail "install-manifest에 현재 플랫폼 checksum이 없습니다: $PLATFORM"

RELEASE_DIR="$INSTALL_ROOT/releases/$VERSION/$PLATFORM"
CURRENT_LINK="$INSTALL_ROOT/current"
VERSION_FILE="$INSTALL_ROOT/current-version.txt"
BIN_LINK="$BIN_DIR/imweb"
CURRENT_VERSION=""

if [[ -f "$VERSION_FILE" ]]; then
  CURRENT_VERSION="$(cat "$VERSION_FILE")"
fi

if [[ "$CURRENT_VERSION" == "$VERSION" && "$FORCE" -eq 0 && -x "$BIN_LINK" ]]; then
  printf '이미 최신 stable 버전이 설치되어 있어 건너뜁니다.\n'
  printf '  version: %s\n' "$VERSION"
  printf '  bin: %s\n' "$BIN_LINK"
  exit 0
fi

WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR"' EXIT

ASSET_BASENAME="$(basename "${ASSET_URL%%\?*}")"
ASSET_PATH="$WORK_DIR/${ASSET_BASENAME:-archive}"
curl -fsSL "$ASSET_URL" -o "$ASSET_PATH" || fail "platform archive를 내려받지 못했습니다: $ASSET_URL"

DOWNLOADED_SHA="$(sha256_file "$ASSET_PATH")"
if [[ "$DOWNLOADED_SHA" != "$ASSET_SHA" ]]; then
  fail "checksum 검증에 실패했습니다. expected=$ASSET_SHA actual=$DOWNLOADED_SHA"
fi

TMP_RELEASE_DIR="$WORK_DIR/release"
extract_archive "$ASSET_PATH" "$TMP_RELEASE_DIR"

[[ -f "$TMP_RELEASE_DIR/imweb" ]] || fail "archive 안에 실행 파일이 없습니다: $ASSET_BASENAME"

mkdir -p "$INSTALL_ROOT/releases/$VERSION" "$BIN_DIR"
if [[ -d "$RELEASE_DIR" ]]; then
  STAGED_BINARY="$WORK_DIR/imweb"
  cp "$TMP_RELEASE_DIR/imweb" "$STAGED_BINARY"
  chmod +x "$STAGED_BINARY"
  mv -f "$STAGED_BINARY" "$RELEASE_DIR/imweb"
else
  mv "$TMP_RELEASE_DIR" "$RELEASE_DIR"
fi

ln -sfn "$RELEASE_DIR" "$CURRENT_LINK"
ln -sfn "$CURRENT_LINK/imweb" "$BIN_LINK"
printf '%s' "$VERSION" > "$VERSION_FILE"

INSTALLED_VERSION="$("$BIN_LINK" --version 2>/dev/null || true)"
INSTALLED_VERSION="${INSTALLED_VERSION%%$'\n'*}"

printf 'CLI 설치 완료\n'
printf '  version: %s\n' "$VERSION"
printf '  tag: %s\n' "${TAG:-unknown}"
printf '  platform: %s\n' "$PLATFORM"
printf '  install_root: %s\n' "$INSTALL_ROOT"
printf '  bin: %s\n' "$BIN_LINK"
if [[ -n "$INSTALLED_VERSION" ]]; then
  printf '  version_check: %s\n' "$INSTALLED_VERSION"
fi
if [[ ":$PATH:" != *":$BIN_DIR:"* ]]; then
  printf '  note: PATH에 %s를 추가해야 바로 실행할 수 있습니다.\n' "$BIN_DIR"
fi
