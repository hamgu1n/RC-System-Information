# RC System Information - Windows Build Setup
# Run this script from the project root

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  RC System Information - Windows Build" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# ── 1. Check Node.js ──────────────────────────────────────────
Write-Host "Checking for Node.js..." -ForegroundColor Yellow

if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
    Write-Host "Node.js not found. Installing via winget..." -ForegroundColor Yellow
    winget install OpenJS.NodeJS.LTS --silent --accept-source-agreements --accept-package-agreements
    # Refresh PATH
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")

    if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
        Write-Host "Node.js install failed. Please install manually from https://nodejs.org and re-run this script." -ForegroundColor Red
        pause
        exit 1
    }
}

$nodeVersion = node --version
Write-Host "Node.js $nodeVersion found." -ForegroundColor Green

# ── 2. Check .env ─────────────────────────────────────────────
Write-Host ""
Write-Host "Checking for .env file..." -ForegroundColor Yellow

if (-not (Test-Path ".env")) {
    if (Test-Path "scripts\env-values.txt") {
        Write-Host "Loading values from scripts\env-values.txt..." -ForegroundColor Yellow
        Copy-Item "scripts\env-values.txt" ".env"
        Write-Host ".env created from env-values.txt." -ForegroundColor Green
    } else {
        Write-Host ".env not found. Please enter the required values:" -ForegroundColor Yellow
        Write-Host ""

        $publicIp = Read-Host "PUBLIC_IP_ENDPOINT"
        $sendReport = Read-Host "SEND_REPORT_ENDPOINT"
        $authToken = Read-Host "AUTH_TOKEN"

        @"
PUBLIC_IP_ENDPOINT=$publicIp
SEND_REPORT_ENDPOINT=$sendReport
AUTH_TOKEN=$authToken
"@ | Set-Content ".env"

        Write-Host ".env created." -ForegroundColor Green
    }
} else {
    Write-Host ".env already exists, skipping." -ForegroundColor Green
}

# ── 3. Install dependencies ───────────────────────────────────
Write-Host ""
Write-Host "Installing dependencies..." -ForegroundColor Yellow
npm install
Write-Host "Dependencies installed." -ForegroundColor Green

# ── 4. Build ──────────────────────────────────────────────────
Write-Host ""
Write-Host "Building Windows app..." -ForegroundColor Yellow
npm run dist:win

# ── 5. Done ───────────────────────────────────────────────────
Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  Build complete! Output is in release/" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""

# Open the release folder
Start-Process explorer.exe -ArgumentList "release"

pause
