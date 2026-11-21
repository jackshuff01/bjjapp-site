# Publishes this folder to GitHub Pages as a public repo. Safe to run again.
param([string]$Repo = "bjjapp-site")
Set-Location $PSScriptRoot
if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
  winget install --id GitHub.cli -e --accept-source-agreements --accept-package-agreements
  $env:Path = [Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [Environment]::GetEnvironmentVariable("Path","User")
}
gh auth status *> $null
if ($LASTEXITCODE -ne 0) { gh auth login --web --git-protocol https; if ($LASTEXITCODE -ne 0) { throw "GitHub login failed" } }
gh auth setup-git
$owner = gh api user --jq .login
gh repo view "$owner/$Repo" *> $null
if ($LASTEXITCODE -ne 0) { gh repo create $Repo --public --source . --remote origin --push; if ($LASTEXITCODE -ne 0) { throw "repo create failed" } }
else { git push -u origin main; if ($LASTEXITCODE -ne 0) { throw "push failed" } }
gh api "repos/$owner/$Repo/pages" *> $null
if ($LASTEXITCODE -ne 0) { gh api -X POST "repos/$owner/$Repo/pages" -f "source[branch]=main" -f "source[path]=/" | Out-Null; if ($LASTEXITCODE -ne 0) { throw "enabling Pages failed" } }
gh api -X PUT "repos/$owner/$Repo/pages" -f cname=bjjapp.uk
Write-Host "`nPublished from $owner/$Repo. Now add these records in Cloudflare DNS for bjjapp.uk, all DNS only (grey cloud):"
"185.199.108.153","185.199.109.153","185.199.110.153","185.199.111.153" | ForEach-Object { Write-Host "  A      @    $_" }
Write-Host "  CNAME  www  $($owner.ToLower()).github.io"
Write-Host "`nOnce the certificate is ready, turn on HTTPS:"
Write-Host "  gh api -X PUT repos/$owner/$Repo/pages -F https_enforced=true"
