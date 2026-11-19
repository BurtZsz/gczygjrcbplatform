# 走 API + SSH(443) 完成方案 A：登录、加公钥、建仓、推送
# 前提：同目录上一级存在 token.txt（单行 classic PAT，勾选 repo 与 admin:public_key）

$ErrorActionPreference = 'Stop'
$repoDir  = $PSScriptRoot
$repoName = 'gczygjrcbplatform'
$tokenFile = 'C:\Users\diahlei\token.txt'
$gh = 'C:\Program Files\GitHub CLI\gh.exe'
$pubKey = Join-Path $env:USERPROFILE '.ssh\id_ed25519.pub'

Set-Location -LiteralPath $repoDir

if (-not (Test-Path -LiteralPath $tokenFile)) {
    Write-Host "缺少令牌文件：$tokenFile" -ForegroundColor Red
    Write-Host "到 https://github.com/settings/tokens 生成 classic token，勾 repo 与 admin:public_key，单行存进该文件" -ForegroundColor Yellow
    exit 1
}

Write-Host "== 1/5 用令牌登录（走 api.github.com）==" -ForegroundColor Cyan
$token = (Get-Content -LiteralPath $tokenFile -Raw).Trim()
$token | & $gh auth login --hostname github.com --git-protocol ssh --with-token
if ($LASTEXITCODE -ne 0) { Write-Host "登录失败" -ForegroundColor Red; exit 1 }
& $gh auth status 2>&1 | Out-Host
$user = (& $gh api user --jq '.login').Trim()
Write-Host "登录账号: $user" -ForegroundColor Green

Write-Host "== 2/5 上传 SSH 公钥 ==" -ForegroundColor Cyan
$keys = & $gh ssh-key list --json key 2>$null | ConvertFrom-Json
$have = $false
foreach ($k in $keys) { if ($k.key -eq (Get-Content -LiteralPath $pubKey -Raw).Trim()) { $have = $true } }
if ($have) {
    Write-Host "公钥已在账号中，跳过" -ForegroundColor Yellow
} else {
    & $gh ssh-key add $pubKey --title "Doubao-Desktop-20261119"
    if ($LASTEXITCODE -ne 0) { Write-Host "上传公钥失败" -ForegroundColor Red; exit 1 }
}

Write-Host "== 3/5 建仓 ==" -ForegroundColor Cyan
$exists = (& $gh repo view "$user/$repoName" --json name 2>$null)
if ($exists) {
    Write-Host "仓库已存在，直接绑定远端" -ForegroundColor Yellow
    if (-not ((git remote) -match 'origin')) {
        git remote add origin "git@ssh.github.com:$user/$repoName.git"
    }
} else {
    & $gh repo create $repoName --public
    if ($LASTEXITCODE -ne 0) { Write-Host "建仓失败" -ForegroundColor Red; exit 1 }
    git remote remove origin 2>$null
    git remote add origin "git@ssh.github.com:$user/$repoName.git"
}

Write-Host "== 4/5 让 git 走 ssh.github.com:443 ==" -ForegroundColor Cyan
git config core.sshCommand "ssh -o HostName=ssh.github.com -o Port=443 -o StrictHostKeyChecking=accept-new"

Write-Host "== 5/5 推送 main ==" -ForegroundColor Cyan
git push -u origin main
if ($LASTEXITCODE -ne 0) { Write-Host "推送失败" -ForegroundColor Red; exit 1 }

Write-Host ""
Write-Host "完成：https://github.com/$user/$repoName" -ForegroundColor Green
Write-Host "下一步 Cloudflare Pages 绑定该仓库（Build command 留空，输出目录 /）"
Write-Host "令牌文件已保留在 $tokenFile，确认成功后请自行删除"
