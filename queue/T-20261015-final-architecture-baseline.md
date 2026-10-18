# T-20261015 Final architecture baseline

- 状态：`review`
- 授权依据：用户先要求将 Level 1-3 合并图设为基线，随后提供多次修订图；最终确认 Level 3 以同色边界展开 Level 2 的 App 与 Music Processing，三个外部项因排版采用编号简化，蓝绿跨框详细连线可省略但运行逻辑必须保留。
- 目标：把最终修订图设为唯一现行架构图，归档旧图，校正文档引用，并把省略连线的运行逻辑写为正式事实。

## 范围

- `truth/diagrams/`
- `truth/architecture.md`
- `truth/engineering.md`
- `AGENTS.md`
- `CHANGELOG.md`
- `reference/superseded-diagrams/`

## 验收方法

1. 新图与用户提供文件的 SHA-256 一致。
2. `truth/diagrams/` 只保留一张现行图。
3. 旧图移入 `reference/`，不再被 truth 文档引用。
4. 所有 Markdown 相对链接存在，代码围栏成对。
5. 架构与工程文档使用最终图中的边界和组件名称，并明确记录图面省略但实现必须保留的数据流。

## 自验结果

- 最新图源文件与目标文件 SHA-256 均为 `e38eceaab3c1bbb9f83b1619a7b842e155756d14167037f8e471164511dfd8b6`。
- 当前图片尺寸为 2172 × 942，RGBA PNG。
- `truth/diagrams/` 现有文件数：1。
- Markdown 断链数：0。
- 文档代码围栏均成对。
- `Instrument Recognition` 与 `Result Integration` 的容器归属已同步；图面省略的跨容器数据流已在 `truth/architecture.md` 第 10 节正式定义，无剩余架构图勘误。
- 第一版合并图已归档到 `reference/superseded-diagrams/2026-10-15-revision-1/`。
- 定稿前一版合并图已归档到 `reference/superseded-diagrams/2026-10-16-revision-2/`。

以上为执行者自验，未独立验证；等待用户审阅与验收。
