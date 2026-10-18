# Changelog

本文件记录 Music Glove 项目中面向协作者可见的重要变化。

## 2026-10-18

- 将完整项目发布到公开 GitHub 仓库 `Rhine31/music-glove`，默认分支为 `main`；克隆后可直接打开共享的 `MusicGlove.xcodeproj` 在 Xcode 中构建运行。
- 保持现有“保留所有权利”许可证声明，不因公开可下载而自动授予复制、修改或再分发许可。

## 2026-10-17

- 新增仓库级 `.gitignore` 和面向 GitHub 克隆者的 Xcode 启动说明，排除虚拟环境、缓存、本地数据、Xcode 用户状态和构建产物；项目许可证仍保持未决定状态。
- My Music Glove 页的程序化手套插图替换为用户提供的透明 PNG，并复用现有正式手套图片资产。
- Create 页顶部的程序化设备状态卡及其内部内容替换为用户提供的完整 PNG 卡片，并保留设备名称、连接状态与电量的无障碍描述。
- Glove Connected 页的程序化手套插图替换为用户提供的透明 PNG，并复用 Onboarding 与 Search Glove 页的同一正式图片资产。
- Glove Connected 页中部设备信息按最终视觉稿改为 “Device Name / Music Glove 01 / Connected / Battery 82%”，并以绿色状态点和电池图标提供非纯文字提示。
- Select Glove 页将居中的 Rescan 移至页面底部，并在下方增加居中的 “can't find your device?” 辅助说明。
- Select Glove 页的三个程序化卡片及其内部内容按 01–03 顺序替换为用户提供的完整 PNG 卡片，整张图片保留原有选择与模拟配对行为。
- Search Glove 页将 “Development device discovery” 移至扫描卡片上方并左对齐，卡片内的旋转指示器及其下方按钮改为整体居中。
- Search Glove 页的程序化手套替换为用户提供的透明 PNG 正式视觉资源，并复用与 Onboarding 第 1 页内容完全一致的图片资产。
- Onboarding 五步骤页标题改为居中的 “From Inspiration” 与 “to a Complete Song” 两行，并下移步骤列表、增加标题与内容之间的安全间距。
- Onboarding 第 3 页的五个程序化步骤圆形及内部 SF Symbols 按 1–5 顺序替换为用户提供的蓝、粉交替透明 PNG 视觉资源。
- Onboarding 第 2 页的程序化蓝色、粉色圆形与内部 SF Symbols 替换为用户提供的两张透明 PNG 正式视觉资源，原有说明文字和流程保持不变。
- Onboarding 第 1 页的程序化手套插图替换为用户提供的透明 PNG 正式视觉资源；分页、文案、按钮和其他页面的手套图形保持不变。
- Welcome 页声纹由 SwiftUI 程序化波形替换为用户提供的透明 PNG 正式视觉资源，并保留原有布局、交互和无障碍标签。
- 以 `truth/design-screens/` 为视觉基线重建 iOS 前端：新增 Welcome/认证预览/Onboarding/配对流程，并将 Create、Quick Adjust、Analysis Result、Edit、Track Detail、Melody Edit、Instrument、Mixer、Me、Projects、Glove、Gesture Test、Share 与 Community 页面改为高保真设计方向。
- 未接入的账号、真实 BLE、社区发布和 SoundFont 试听继续显示为开发预览或不可用状态，不伪造外部服务结果。
- Edit 乐器轨新增真实 MIDI 下载与系统文件导出；下载使用临时文件并限制响应大小，避免无界内存读取。

## 2026-10-16

- 新增客户端分析服务能力检查与 API 契约测试，区分完整可用、仅转录可用和不可用状态。
- 修复失败任务的幂等重试：可重试失败复用同一 `job_id` 重新分析，不创建重复任务。
- 区分可重试故障与“未识别到旋律”验证失败；更换音频时创建新录制会话，避免复用旧幂等键。
- 收紧分析适配器错误映射，异常中的内部文件路径或自由文本不再进入 API 响应。
- iOS 音频提交改为分块构建临时 multipart 文件并通过 URLSession 文件上传，避免把完整哼唱一次性载入内存，并补充临时文件清理测试。
- 将 Basic Pitch 转录与 FluidSynth/SoundFont 渲染解耦：缺少渲染环境时仍交付真实音符与 MIDI，并返回明确警告。
- iOS Create 流程新增 Quick Adjust 与 Analysis Result，支持编辑派生音高/音量并把乐器轨和独立 Vocal 加入 Edit 多轨草稿。
- 启动阶段 A 开发：新增可编译运行的 iPhone SwiftUI 工程与 Create / Edit / Me 主导航。
- 新增真实 FastAPI 分析服务，支持幂等音频上传、原始 Vocal 独立保存、Basic Pitch 转 MIDI 及 FluidSynth/SoundFont 渲染边界。
- 新增 ADR-001、ADR-002、ADR-006，记录 iPhone 原生客户端、BLE 方向和 MVP 分析 API 决策及仍开放的协议/部署事项。
- 新增服务端契约测试、iOS 领域测试和统一质量门禁脚本。
- 将用户修订后的 `AGENTS.pages` 转换为 Markdown，并完整替换根目录 `AGENTS.md`。
- 将用户修订后的 `design.pages` 转换为 Markdown，并完整替换 `truth/design.md`；保留现有设计图片及相对链接。
- 将用户最终修订的 Level 1-3 合并图设为唯一现行架构图，定稿前一版归档至 `reference/superseded-diagrams/2026-10-16-revision-2/`。
- 固定 Level 3 的 6 + 6 组件归属：`Instrument Recognition` 属于绿色 Music Processing，`Result Integration` 属于蓝色 App。
- 把图中为排版省略的蓝绿跨容器连线写为正式数据流，不再列作待确认关系。
- 同步更新架构文档、工程模块映射、根协作契约和任务自验记录。

## 2026-10-15

- 用修订后的 Level 1-3 合并图替换现行架构图；上一版合并图转入 `reference/superseded-diagrams/2026-10-15-revision-1/`。
- 确认 Level 3 通过蓝色和绿色分别展开 Level 2 的 App 与 Music Processing，Users、Music Glove、Output 以编号简化。
- 移除已修正的标题、Save/Load、截图控件和容器命名问题；保留 4 项仍影响实现的数据流关系。
- 将新的 Level 1-3 合并图设为唯一现行架构图；旧版三张分级图移入 `reference/superseded-diagrams/2026-10-09/`。
- 将架构文档升级到 1.1，并按最终图修订系统边界、容器、组件和数据流说明。
- 同步工程文档的组件映射，并登记最终图中的标题、职责归属和缺失连线问题。
- 建立 `charter/`、`eval/`、`gate/`、`object/`、`queue/`、`reference/`、`tool/`、`truth/` 开发目录体系。
- 将设计、架构和工程文档迁移为 `truth/` 下的三份权威正本，并保留设计页面与架构图附件。
- 新增项目专用根协作契约 `AGENTS.md`。
- 新增项目入口 `README.md` 与许可证状态说明。
