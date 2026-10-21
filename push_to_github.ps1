# Pushes the main branch to GitHub. Run from a normal PowerShell window so the
# GitHub sign-in window can appear the first time.
$env:GIT_TERMINAL_PROMPT = "1"
$env:GCM_INTERACTIVE = "always"
Set-Location $PSScriptRoot
& "C:\Program Files\Git\cmd\git.exe" push -u origin main
if ($LASTEXITCODE -eq 0) {
    Write-Host "`nDone! Your code is on GitHub. You can close this window." -ForegroundColor Green
} else {
    Write-Host "`nPush failed (exit code $LASTEXITCODE). Copy the text above and send it to Claude." -ForegroundColor Red
}
Read-Host "Press Enter to close"
