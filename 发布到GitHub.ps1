# 一键把站点集群推到 GitHub（方案 A 的第一步）
# 用法：先在本机 PowerShell 里跑一次  gh auth login
#      再运行本脚本

$ErrorActionPreference = 'Stop'
$repoName = 'gczygjrcbplatform'
Set-Location -LiteralPath $PSScriptRoot

# 本机 PATH 里可能没有 gh，优先用完整路径
$gh = 'C:\Program Files\GitHub CLI\gh.exe'
if (-not (Test-Path -LiteralPath $gh)) {
    $c = Get-Command gh -ErrorAction SilentlyContinue
    if ($c) { $gh = $c.Source } else { Write-Host "找不到 gh.exe，请先装 GitHub CLI" -ForegroundColor Red; exit 1 }
}

Write-Host "== 1/4 检查 gh 登录状态 ==" -ForegroundColor Cyan
& $gh auth status 2>&1 | Out-Host
if ($LASTEXITCODE -ne 0) {
    Write-Host "尚未登录。请先运行： & `"$gh`" auth login" -ForegroundColor Yellow
    Write-Host "（选 GitHub.com → HTTPS → Login with a web browser）" -ForegroundColor Yellow
    exit 1
}

Write-Host "== 2/4 检查远端 ==" -ForegroundColor Cyan
$remotes = git remote
if ($remotes -match 'origin') {
    Write-Host "已存在 origin，跳过创建仓库" -ForegroundColor Yellow
} else {
    Write-Host "== 3/4 创建仓库并推送 ==" -ForegroundColor Cyan
    & $gh repo create $repoName --public --source=. --remote=origin --push
    if ($LASTEXITCODE -ne 0) {
        Write-Host "创建失败：可能是仓库名已被占用，改个名字再试" -ForegroundColor Red
        exit 1
    }
}

Write-Host "== 4/4 推送 main ==" -ForegroundColor Cyan
git push -u origin main
Write-Host ""
Write-Host "完成。接下来去 Cloudflare Pages 绑定：" -ForegroundColor Green
Write-Host "  控制台 → Workers & Pages → 项目 $repoName → Settings → Builds & deployments"
Write-Host "  → Connect to Git → 选这个仓库 → Framework preset: None"
Write-Host "  → Build command 留空 → Build output directory: /"
