[CmdletBinding()]
param(
    [Parameter()]
    [string]$InstallRoot,

    [Parameter()]
    [string]$BinDir,

    [Parameter()]
    [switch]$Force,

    [Parameter()]
    [switch]$Help
)

$ChannelUrl = 'https://raw.githubusercontent.com/imwebme/imweb-cli-release/main/channels/stable.json'

function Show-Usage {
    @"
imweb CLI public stable installer

Usage:
  ./latest.ps1 [-InstallRoot PATH] [-BinDir PATH] [-Force]
  ./latest.ps1 -Help

Options:
  -InstallRoot  Windows CLI 설치 루트
  -BinDir       Windows 실행 파일을 둘 디렉터리 (manual path 전용)
  -Force        이미 같은 버전이 있어도 다시 설치
  -Help         도움말 출력

동작 원칙:
  - `latest.ps1`는 Windows 전용 installer입니다. macOS/Linux에서는 `install/latest.sh`를 사용하세요.
  - public stable channel pointer를 읽고 release-manifest -> install-manifest -> platform archive 순서로 해석합니다.
  - private GitHub repo 권한이나 gh auth를 요구하지 않습니다.
  - Windows platform archive 하나만 내려받아 checksum 검증 후 설치합니다.
  - Windows canonical launcher contract는 `<InstallRoot>\bin\imweb.exe`로 고정됩니다.
  - Windows custom `-BinDir`는 설치 편의용 manual path일 뿐이며 direct detection / self-update contract에는 포함되지 않습니다.
"@
}

function Fail([string]$Message) {
    Write-Error $Message
    exit 1
}

function Get-PlatformKey {
    switch ([System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture.ToString().ToLowerInvariant()) {
        'x64' { $arch = 'x86_64' }
        'x86' { $arch = 'i686' }
        'arm64' { $arch = 'arm64' }
        default { Fail '지원하지 않는 아키텍처입니다.' }
    }

    return "windows-$arch"
}

function Get-DefaultInstallRoot {
    return (Join-Path $env:LOCALAPPDATA 'imweb-cli')
}

function Get-DefaultBinDir {
    param(
        [Parameter(Mandatory = $true)]
        [string]$SelectedInstallRoot
    )

    return (Join-Path $SelectedInstallRoot 'bin')
}

function Test-IsWindows {
    return [System.Environment]::OSVersion.Platform -eq [System.PlatformID]::Win32NT
}

function Get-JsonFromUrl([string]$Url) {
    return (Invoke-WebRequest -Uri $Url -UseBasicParsing).Content | ConvertFrom-Json
}

function Get-FileSha256([string]$Path) {
    return (Get-FileHash -Algorithm SHA256 -LiteralPath $Path).Hash.ToLowerInvariant()
}

function Expand-ReleaseArchive([string]$Archive, [string]$Destination) {
    New-Item -ItemType Directory -Force -Path $Destination | Out-Null

    if ($Archive.EndsWith('.zip')) {
        Expand-Archive -LiteralPath $Archive -DestinationPath $Destination -Force
        return
    }

    if ($Archive.EndsWith('.tar.gz')) {
        tar -xzf $Archive -C $Destination
        return
    }

    Fail "지원하지 않는 archive 형식입니다: $Archive"
}

function Write-PathNote([string]$SelectedBinDir) {
    $CurrentPath = [Environment]::GetEnvironmentVariable('Path', 'User')
    if (-not $CurrentPath) {
        $CurrentPath = ''
    }

    if (-not ($CurrentPath -split ';' | Where-Object { $_ -eq $SelectedBinDir })) {
        Write-Host "  note: PowerShell을 새로 열고 '$SelectedBinDir' 디렉터리를 사용자 PATH에 추가해야 바로 imweb를 실행할 수 있습니다."
    }
}

if ($Help) {
    Show-Usage
    exit 0
}

if (-not (Test-IsWindows)) {
    Fail "`latest.ps1`는 Windows 전용 installer입니다. macOS/Linux에서는 `install/latest.sh`를 사용하세요."
}

if (-not $InstallRoot) {
    $InstallRoot = Get-DefaultInstallRoot
}

if (-not $BinDir) {
    $BinDir = Get-DefaultBinDir -SelectedInstallRoot $InstallRoot
}

$DefaultBinDir = Get-DefaultBinDir -SelectedInstallRoot $InstallRoot
$ResolvedDefaultBinDir = [System.IO.Path]::GetFullPath($DefaultBinDir)
$ResolvedSelectedBinDir = [System.IO.Path]::GetFullPath($BinDir)
$WindowsCanonicalBinPath = Join-Path $ResolvedDefaultBinDir 'imweb.exe'

$WindowsCustomBinDir = $ResolvedSelectedBinDir -ne $ResolvedDefaultBinDir
if ($WindowsCustomBinDir) {
    Write-Warning "Windows canonical launcher contract는 '$WindowsCanonicalBinPath'만 인식합니다."
    Write-Warning "지정한 -BinDir '$ResolvedSelectedBinDir'는 manual path로만 설치되며 direct detection / self-update 대상이 아닙니다."
}

$Platform = Get-PlatformKey

try {
    $Channel = Get-JsonFromUrl -Url $ChannelUrl
}
catch {
    Fail "stable channel pointer를 읽지 못했습니다: $ChannelUrl"
}

if (-not $Channel.release_manifest_url) {
    Fail 'stable channel pointer에 release_manifest_url이 없습니다.'
}

try {
    $ReleaseManifest = Get-JsonFromUrl -Url $Channel.release_manifest_url
}
catch {
    Fail "release-manifest를 읽지 못했습니다: $($Channel.release_manifest_url)"
}

$Version = [string]$ReleaseManifest.version
$Tag = [string]$ReleaseManifest.tag
$InstallManifestUrl = [string]$ReleaseManifest.metadata_assets.curl_install_manifest.url

if (-not $Version) {
    Fail 'release-manifest에서 version을 읽지 못했습니다.'
}

if (-not $InstallManifestUrl) {
    Fail 'release-manifest에서 install-manifest URL을 읽지 못했습니다.'
}

try {
    $InstallManifest = Get-JsonFromUrl -Url $InstallManifestUrl
}
catch {
    Fail "install-manifest를 읽지 못했습니다: $InstallManifestUrl"
}

$Asset = $InstallManifest.platforms.$Platform
if (-not $Asset) {
    Fail "install-manifest에 현재 플랫폼 자산이 없습니다: $Platform"
}

$AssetUrl = [string]$Asset.url
$AssetSha = [string]$Asset.sha256
if (-not $AssetUrl -or -not $AssetSha) {
    Fail "install-manifest에 현재 플랫폼 asset 정보가 불완전합니다: $Platform"
}

$BinaryName = if ($Platform.StartsWith('windows-')) { 'imweb.exe' } else { 'imweb' }
$VersionFile = Join-Path $InstallRoot 'current-version.txt'
$ReleaseDir = Join-Path $InstallRoot "releases/$Version/$Platform"
$BinPath = Join-Path $BinDir $BinaryName
$CurrentVersion = if (Test-Path -LiteralPath $VersionFile -PathType Leaf) { (Get-Content -LiteralPath $VersionFile -Raw).Trim() } else { '' }

if (-not $Force -and $CurrentVersion -eq $Version -and (Test-Path -LiteralPath $BinPath -PathType Leaf)) {
    Write-Host '이미 최신 stable 버전이 설치되어 있어 건너뜁니다.'
    Write-Host "  version: $Version"
    Write-Host "  bin: $BinPath"
    Write-PathNote -SelectedBinDir $BinDir
    exit 0
}

$WorkDir = Join-Path ([System.IO.Path]::GetTempPath()) ("imweb-cli-public-install-" + [System.Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force -Path $WorkDir | Out-Null

try {
    $AssetFileName = [System.IO.Path]::GetFileName(([System.Uri]$AssetUrl).AbsolutePath)
    if (-not $AssetFileName) {
        $AssetFileName = 'archive'
    }
    $ArchivePath = Join-Path $WorkDir $AssetFileName
    Invoke-WebRequest -Uri $AssetUrl -OutFile $ArchivePath -UseBasicParsing | Out-Null

    $ActualSha = Get-FileSha256 -Path $ArchivePath
    if ($ActualSha -ne $AssetSha.ToLowerInvariant()) {
        Fail "checksum 검증에 실패했습니다. expected=$AssetSha actual=$ActualSha"
    }

    $ExtractDir = Join-Path $WorkDir 'release'
    Expand-ReleaseArchive -Archive $ArchivePath -Destination $ExtractDir

    $ExtractedBinary = Join-Path $ExtractDir $BinaryName
    if (-not (Test-Path -LiteralPath $ExtractedBinary -PathType Leaf)) {
        Fail "archive 안에 실행 파일이 없습니다: $AssetFileName"
    }

    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $ReleaseDir) | Out-Null
    if (Test-Path -LiteralPath $ReleaseDir) {
        Copy-Item -LiteralPath $ExtractedBinary -Destination (Join-Path $ReleaseDir $BinaryName) -Force
    }
    else {
        Move-Item -LiteralPath $ExtractDir -Destination $ReleaseDir
    }

    New-Item -ItemType Directory -Force -Path $BinDir | Out-Null
    Copy-Item -LiteralPath (Join-Path $ReleaseDir $BinaryName) -Destination $BinPath -Force
    [System.IO.File]::WriteAllText($VersionFile, $Version)

    $InstalledVersion = (& $BinPath --version 2>$null | Select-Object -First 1)

    Write-Host 'CLI 설치 완료'
    Write-Host "  version: $Version"
    Write-Host "  tag: $(if ($Tag) { $Tag } else { 'unknown' })"
    Write-Host "  platform: $Platform"
    Write-Host "  install_root: $InstallRoot"
    Write-Host "  bin: $BinPath"
    if ($InstalledVersion) {
        Write-Host "  version_check: $InstalledVersion"
    }
    Write-PathNote -SelectedBinDir $BinDir
}
finally {
    if (Test-Path -LiteralPath $WorkDir) {
        Remove-Item -LiteralPath $WorkDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}
