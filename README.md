# 实干型共产主义 · 共建平台（站点集群）

静态站点，无构建步骤。绑定 GitHub 后由 Cloudflare Pages 自动构建发布。

## 目录结构

```
/
├── index.html                      主官网：定位、三轨、硬件方向、内容入口
├── product-tracking/               选品追踪站
│   ├── index.html
│   └── data/products.json          选品数据（每日覆盖更新，历史条目保留）
├── socratic-pbl/                   课程与导学包站
│   ├── index.html
│   └── downloads/daoxuebao-v1.md   五层追问导学包模板（可直接下载）
├── hardware-lab/                   硬件实验室：方向、状态、研发日志
├── novel/                          共创小说站：《三十而从心所欲》
├── assets/
│   ├── style.css                   全站共享样式
│   └── tracking.js                 选品页筛选与渲染
└── 404.html
```

## 公开区 / 内部区

- 公开：上述全部页面、选品数据、导学包模板、章节连载。
- 内部（不进本仓库）：BOM、成本核算、工厂对接资料、货源报价、陪审团议事区。

## 发布（已落地）

- 仓库：`BurtZsz/gczygjrcbplatform`（公开，默认分支 `main`）
- 托管：Cloudflare Pages，项目名 `gczygjrcbplatform`，构建命令留空，输出目录 `/`
- 触发：推送到 `main` 即自动构建，**不需要 Deploy Hook**
- 绑定后是单向锁定：**不能再切回拖拽上传**，所有改动必须先提交到 `main`

## 网络注意事项（重要）

本机到 GitHub 的连通性不稳定，实测：

| 目标 | 状态 |
|---|---|
| `github.com:443`（网页域名） | 时通时断，常被 TCP 重置 |
| `api.github.com` | 稳定 |
| `ssh.github.com:443` | 稳定 |

所以本仓库的远端固定为 SSH 443，仓库内已配置：

```bash
git remote -v
# origin ssh://git@ssh.github.com:443/BurtZsz/gczygjrcbplatform.git
git config core.sshCommand
# ssh -o HostName=ssh.github.com -o Port=443 -o StrictHostKeyChecking=accept-new
```

换机器时记得照上面两条重设一次，否则会卡在 `github.com:443` 连不上。

## 每日更新流程（手动发布模式）

1. 选品任务在云端抓取数据，整理成当日清单，追加进飞书文档。
2. 当日条目整理成符合 `products.json` 结构的 JSON（含 `updated` 字段）。
3. 确认后执行：

```powershell
.\同步选品到站点.ps1 -JsonPath '.\当日.json' -KeepHistory
```

脚本会校验必填字段、按「日期 + 名称」去重合并历史、提交并推送，Pages 随即自动重建。

未加 `-KeepHistory` 时会整表覆盖，只在需要重建全量数据时用。

## 内容约定

- 价格一律标公开信息口径，加一句「下单前二次核实」。
- 白牌与品牌不同名不混用（例如「阿尔法」与「阿尔法蛋」）。
- 涉及医疗器械属性的助行产品，必须标注资质待核。

