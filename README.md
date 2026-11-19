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

## 发布（方案 A：GitHub 绑定）

1. 在 GitHub 建仓库（建议公开，名字 `gczygjrcbplatform`）。
2. 本地推送本目录到 `main`。
3. Cloudflare Pages → 项目设置 → 连接 Git 仓库，构建命令留空，输出目录填 `/`。
4. 生成 Deploy Hook URL，交给每日选品任务调用，实现 22:15 自动发布。

绑定后是单向锁定：**不能再切回拖拽上传**，所有改动必须先提交到 `main`。

## 每日更新流程

1. 选品任务抓取数据，整理成当日清单。
2. 覆盖写入 `product-tracking/data/products.json`（含 `updated` 字段）。
3. 提交并推送，Pages 自动重建。
4. 触发 Deploy Hook（如已配置）。

## 内容约定

- 价格一律标公开信息口径，加一句「下单前二次核实」。
- 白牌与品牌不同名不混用（例如「阿尔法」与「阿尔法蛋」）。
- 涉及医疗器械属性的助行产品，必须标注资质待核。
