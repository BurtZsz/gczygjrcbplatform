# 把当日选品 JSON 写进站点并推送（触发 Cloudflare Pages 自动重建）
# 用法： .\同步选品到站点.ps1 -JsonPath 'C:\path\to\new-products.json'
# 说明： new-products.json 必须含 date/name/desc/price/cat/tags/verdict/source 字段

param(
    [Parameter(Mandatory = $true)][string]$JsonPath,
    [switch]$KeepHistory
)

$ErrorActionPreference = 'Stop'
$repo = $PSScriptRoot
$target = Join-Path $repo 'product-tracking\data\products.json'
$gh = 'C:\Program Files\GitHub CLI\gh.exe'
if (-not (Test-Path -LiteralPath $gh)) {
    $c = Get-Command gh -ErrorAction SilentlyContinue
    if ($c) { $gh = $c.Source } else { Write-Host '找不到 gh.exe' -ForegroundColor Red; exit 1 }
}

if (-not (Test-Path -LiteralPath $JsonPath)) { Write-Host "找不到 $JsonPath" -ForegroundColor Red; exit 1 }

Set-Location -LiteralPath $repo

Write-Host '== 1/4 校验新数据 ==' -ForegroundColor Cyan
$new = Get-Content -LiteralPath $JsonPath -Raw -Encoding UTF8 | ConvertFrom-Json
if (-not $new.items -or $new.items.Count -eq 0) { Write-Host 'items 为空，拒绝推送' -ForegroundColor Red; exit 1 }
$need = 'date','name','cat','price','desc','verdict','source'
foreach ($it in $new.items) {
    foreach ($f in $need) {
        if (-not $it.$f) { Write-Host "条目缺字段 $f : $($it.name)" -ForegroundColor Red; exit 1 }
    }
}
Write-Host ("新数据 {0} 条，日期 {1}" -f $new.items.Count, $new.updated) -ForegroundColor Green

Write-Host '== 2/4 合并历史 ==' -ForegroundColor Cyan
if ($KeepHistory -and (Test-Path -LiteralPath $target)) {
    $old = Get-Content -LiteralPath $target -Raw -Encoding UTF8 | ConvertFrom-Json
    $seen = @{}
    foreach ($o in $old.items) { $seen["$($o.date)|$($o.name)"] = $true }
    $merged = New-Object System.Collections.ArrayList
    foreach ($it in $new.items) {
        $k = "$($it.date)|$($it.name)"
        if (-not $seen.ContainsKey($k)) { [void]$merged.Add($it) }
    }
    foreach ($o in $old.items) { [void]$merged.Add($o) }
    $payload = [pscustomobject]@{ updated = $new.updated; note = $new.note; items = $merged.ToArray() }
    $json = $payload | ConvertTo-Json -Depth 8
} else {
    $json = Get-Content -LiteralPath $JsonPath -Raw -Encoding UTF8
}
[System.IO.File]::WriteAllText($target, $json, (New-Object System.Text.UTF8Encoding($false)))

Write-Host '== 3/4 提交 ==' -ForegroundColor Cyan
git add -- 'product-tracking/data/products.json'
git -c core.quotepath=false commit -m ("选品更新 " + $new.updated)
if ($LASTEXITCODE -ne 0) { Write-Host '无改动或提交失败，检查 git 状态' -ForegroundColor Yellow }

Write-Host '== 4/4 推送（触发 Pages 自动重建）==' -ForegroundColor Cyan
git push origin main
if ($LASTEXITCODE -ne 0) { Write-Host '推送失败，稍后重试一次（DNS 轮询偶发不通）' -ForegroundColor Red; exit 1 }

Write-Host ''
Write-Host '已推送。约 1 分钟后访问 https://gczygjrcbplatform.pages.dev/product-tracking/ 查看' -ForegroundColor Green
