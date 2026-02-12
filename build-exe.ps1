param(
  [string]$NodeVersion = "20.11.1"
)

$ErrorActionPreference = "Stop"

function Info($m){ Write-Host "[TriggerFinder] $m" -ForegroundColor Cyan }
function Warn($m){ Write-Host "[TriggerFinder] $m" -ForegroundColor Yellow }

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $root

$tools = Join-Path $root ".tools"
$nodeDir = Join-Path $tools ("node-v{0}-win-x64" -f $NodeVersion)
$nodeZip = Join-Path $tools ("node-v{0}-win-x64.zip" -f $NodeVersion)
$nodeUrl = ("https://nodejs.org/dist/v{0}/node-v{0}-win-x64.zip" -f $NodeVersion)

New-Item -ItemType Directory -Force -Path $tools | Out-Null

if (!(Test-Path (Join-Path $nodeDir "node.exe"))) {
  Info "Downloading Node.js v$NodeVersion (Windows x64)…"
  Info $nodeUrl
  Invoke-WebRequest -Uri $nodeUrl -OutFile $nodeZip

  Info "Extracting Node.js…"
  Expand-Archive -Path $nodeZip -DestinationPath $tools -Force
} else {
  Info "Node.js already present in .tools/"
}

$env:PATH = ($nodeDir + ";" + (Join-Path $nodeDir "node_modules\npm\bin") + ";" + $env:PATH)

Info "Node: $(node -v)"
Info "NPM : $(npm -v)"

Info "Installing dependencies (npm ci)…"
if (Test-Path (Join-Path $root "package-lock.json")) {
  npm ci
} else {
  npm install
}

Info "Building Windows Portable EXE…"
npm run dist

Info "Done ✅"
Warn "Check the dist/ folder for the portable .exe"
