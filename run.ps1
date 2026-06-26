# Build + run the Yellow Gold watch face in the Connect IQ simulator.
# Prereqs (already installed by setup):
#   - JDK 21 at "C:\Program Files\Eclipse Adoptium\jdk-21.0.11.10-hotspot"
#   - Connect IQ SDK at "$env:USERPROFILE\connectiq-sdk"
#   - Developer key at "$env:USERPROFILE\.garmin-keys\developer_key.der"
#   - Device files for $Device downloaded via the SDK Manager (Garmin login)
param(
    [string]$Device = "fenix8pro47mm"
)
$ErrorActionPreference = "Stop"

$JdkHome = "C:\Program Files\Eclipse Adoptium\jdk-21.0.11.10-hotspot"
$Sdk     = "$env:USERPROFILE\connectiq-sdk"
$Key     = "$env:USERPROFILE\.garmin-keys\developer_key.der"
$env:JAVA_HOME = $JdkHome
$env:PATH = "$JdkHome\bin;$Sdk\bin;$env:PATH"

$proj = $PSScriptRoot
$out  = Join-Path $proj "bin\YellowGold.prg"
New-Item -ItemType Directory -Force -Path (Join-Path $proj "bin") | Out-Null

Write-Host "Building for $Device ..." -ForegroundColor Cyan
& "$Sdk\bin\monkeyc.bat" -d $Device -f (Join-Path $proj "monkey.jungle") `
    -o $out -y $Key -w
if ($LASTEXITCODE -ne 0) { throw "Build failed (exit $LASTEXITCODE)" }
Write-Host "Built $out" -ForegroundColor Green

Write-Host "Launching simulator ..." -ForegroundColor Cyan
Start-Process -FilePath "$Sdk\bin\connectiq.bat"
Start-Sleep -Seconds 4
& "$Sdk\bin\monkeydo.bat" $out $Device
