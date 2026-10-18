# T-20261016 Pages to Markdown sync

- 状态：`review`
- 授权依据：用户明确要求把 `/Users/24g/Documents/AGENTS.pages` 和 `/Users/24g/Documents/design.pages` 转换为 Markdown，并替换项目中原有的 AGENTS 与 design 文档。
- 目标：以两份 Pages 文稿的当前正文为唯一转换来源，分别替换 `AGENTS.md` 和 `truth/design.md`，不把旧文档中已被删除的内容自行合并回来。

## 范围

- `AGENTS.md`
- `truth/design.md`
- `CHANGELOG.md`

## 来源

- `AGENTS.pages` SHA-256：`110407b9efbcc3b2020d447f9433e79cbe797d4b3a8c01757c8e04b542f3c8ac`
- `design.pages` SHA-256：`443db0ebd9fdf707d7410e6402d71dea9c4e5bd98312106c236bb74da4985257`
- 转换方式：使用 Pages 的“导出为纯文本”，保留正文中的 Markdown 标记，再写入稳定的项目路径。

## 验收方法

1. `AGENTS.md` 正文与 `AGENTS.pages` 导出正文一致。
2. `truth/design.md` 正文与 `design.pages` 导出正文一致。
3. 两个目标文件均为 UTF-8 Markdown，并以换行结尾。
4. 全仓 Markdown 相对链接存在，代码围栏成对。
5. `CHANGELOG.md` 记录本次权威文档替换。

## 自验结果

- `AGENTS.md` 与 Pages 导出正文一致（仅规范化文件末尾换行），共 98 行、8248 字节。
- `truth/design.md` 与 Pages 导出正文一致（仅规范化文件末尾换行），共 115 行、6445 字节。
- Markdown 相对链接断链数：0。
- Markdown 代码围栏均成对。
- Pages 原文件未删除或改名。

以上为执行者自验，未独立验证；等待用户审阅与验收。
