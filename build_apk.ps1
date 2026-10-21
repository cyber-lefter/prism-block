# Builds a signed debug APK into build\PrismBlocks.apk.
# Godot needs Java on PATH so it can run Android's apksigner.
# Set $env:GODOT to your Godot 4.3 .exe if it isn't in one of the places below.
$ErrorActionPreference = "Stop"
$env:JAVA_HOME = "C:\Program Files\Eclipse Adoptium\jdk-17.0.20.101-hotspot"
$env:Path = "$env:JAVA_HOME\bin;" + $env:Path

$candidates = @(
    $env:GODOT,
    "$env:USERPROFILE\Desktop\Godot_v4.3-stable_win64.exe",
    "$env:USERPROFILE\Downloads\Godot_v4.3-stable_win64.exe\Godot_v4.3-stable_win64.exe",
    "$env:USERPROFILE\Downloads\Godot_v4.3-stable_win64.exe"
)
$godot = $candidates | Where-Object { $_ -and (Test-Path $_ -PathType Leaf) } | Select-Object -First 1
if (-not $godot) { throw "Godot 4.3 not found. Set `$env:GODOT to its .exe path." }

$project = $PSScriptRoot
$apk = "$project\build\PrismBlocks.apk"
New-Item -ItemType Directory -Force "$project\build" | Out-Null
$before = if (Test-Path $apk) { (Get-Item $apk).LastWriteTime } else { [datetime]::MinValue }
$proc = Start-Process -FilePath $godot -ArgumentList "--headless", "--path", "`"$project`"", "--export-debug", "Android", "`"$apk`"" -NoNewWindow -Wait -PassThru
if (-not (Test-Path $apk) -or (Get-Item $apk).LastWriteTime -le $before) { throw "Export failed (exit code $($proc.ExitCode))." }
Write-Host "APK: $apk"
