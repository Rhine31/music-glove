# T-20261017 Stage A MIDI export

- 状态：`review`
- 授权依据：用户要求继续开发。
- 目标：把分析服务生成的真实 MIDI 从 Edit 乐器轨导出到用户选择的位置。

## 范围

- `object/ios/`：资产下载端口、MIDI 文件文档和 Edit 轨道导出入口。
- `object/ios/MusicGloveTests/`：下载契约、大小限制和应用层轨道测试。
- `object/ios/README.md`、`CHANGELOG.md` 与本任务记录。

## 验收方法

1. 只有具有 MIDI 资产地址的乐器轨显示导出入口，Vocal 轨不显示。
2. 下载走网络端口并验证 HTTP 状态，单个资产最多 10 MB。
3. 下载成功后使用系统文件导出器，不擅自写入固定用户目录。
4. 下载、文件准备或导出失败时显示可读错误，不泄露内部数据。

## 自验结果

- iPhone 18 Pro / iOS 27 模拟器 XCTest：14 项通过，其中 2 项覆盖 MIDI 下载与 10 MB 大小限制。
- 应用层测试确认 Add to Track 后的乐器轨保留真实 MIDI URL，并通过网络端口取得 MIDI 数据；Vocal 轨没有 MIDI URL。
- 完整 `gate/check.sh`：通过（Python 10 项、iOS 14 项、Markdown 链接、代码围栏与 Info.plist 检查均通过）。
- 系统文件导出器属于 iOS 平台组件；真实点击保存到外部位置尚未在自动化 UI 测试中覆盖。

以上为执行者自验，尚未构成用户验收。
