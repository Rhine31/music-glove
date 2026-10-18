# Music Glove iOS

原生 SwiftUI 首版客户端，最低部署目标暂设为 iOS 17。打开 `MusicGlove.xcodeproj` 后运行 `MusicGlove` scheme。

## 当前已实现

- 按 `truth/design-screens/` 重建的暖色渐变、玻璃卡片、深色主按钮、录制圆环、波形和三栏底部导航视觉系统。
- Welcome 页使用用户提供的透明声纹图片资源；图片按原比例适配并保留无障碍说明。
- Welcome、Log In、Sign Up、三页 Onboarding、手套搜索/选择/配对成功的前端流程；未接入的账户与 BLE 能力均明确标为前端预览或开发模拟。
- Create / Edit / Me 三个固定主入口。
- 明确标识的模拟手套连接，用于在未知 BLE 数据协议时验证 App 状态流转。
- 从 Files 选择哼唱音频，手动选择开发替代乐器类型。
- 调用真实 `POST /v1/analysis/jobs` 接口并轮询任务状态。
- 启动时检查分析与试听能力，分别显示完全可用、仅转录可用或服务不可用，并支持重新检查。
- 展示原始 Vocal 独立保留、目标乐器、任务状态、算法版本与渲染能力警告。
- 使用真实 API 音符结果进入 Quick Adjust，编辑派生音高和音量草稿。
- 在服务已生成试听资产时播放真实乐器预览，不使用占位音频。
- 将确认后的乐器轨与独立 Vocal 加入内存中的 Edit 多轨草稿。
- 从 Edit 乐器轨下载真实 API 生成的 MIDI，并通过系统文件导出器保存；下载大小限制为 10 MB。
- 对可重试失败使用原幂等键重试，服务端复用同一任务标识而不创建重复项目。
- 将原任务重试与更换音频分开：更换输入会创建新的录制会话和幂等身份。
- 基础 Dynamic Type、VoiceOver 文案、44 pt 触控尺寸和非纯颜色状态表达。
- 与设计页对应的多轨时间线、轨道详情、旋律编辑、乐器选择、Mixer、Profile、Projects、Project Detail、Glove、Gesture Test、Share 和 Community 页面结构；未完成的持久化、发布和硬件动作不会伪造成功。

## 启动分析服务

先按 `../service/README.md` 启动服务。模拟器默认访问 `http://127.0.0.1:8000`；可在 scheme 环境变量 `MUSIC_GLOVE_API_URL` 中覆盖。

当前导入音频会按块写入受文件保护的临时 multipart 请求体，再由 URLSession 以文件方式上传；成功、失败或取消后都会清理临时请求体。生产级断点续传与后台传输仍需结合持久队列 ADR 实现。

## 尚未声称完成

- 真实 Core Bluetooth 扫描、双手身份、数据包解析和时间同步。
- 本地持久化、断点续传、云同步与冲突处理。
- 多轨持久化、正式乐谱编辑、完整 Piano Roll 操作、真实混音、完整导出、账户和社区服务。
- Welcome 声纹、Onboarding 第 1–3 页主要插图、Search Glove、Glove Connected 与 My Music Glove 手套、Select Glove 01–03 卡片及 Create 页设备状态卡已替换为用户提供的正式图片；其他手套场景、乐器和封面独立资产尚未提供，仍使用 SwiftUI 图形和 SF Symbols 保持相同的信息层级与视觉方向。

这些能力必须按 `truth/engineering.md` 的 ADR 与阶段门禁继续实现。
