# T-20261016 Stage A iOS and analysis API foundation

- 状态：`review`
- 授权依据：用户要求开始开发，并确认首版采用 iPhone 原生 SwiftUI、Python/FastAPI、BLE、Spotify Basic Pitch 与 SoundFont 路线。
- 目标：建立可编译的 iOS 工程和真实分析 API，让开发阶段可导入哼唱音频、提交幂等分析任务、生成 MIDI，并为目标乐器试听建立真实渲染边界。

## 范围

- `object/ios/`
- `object/service/`
- `truth/adr/ADR-001-ios-swiftui-mvp.md`
- `truth/adr/ADR-002-ble-transport-direction.md`
- `truth/adr/ADR-006-mvp-analysis-api.md`
- `truth/architecture.md`
- `truth/engineering.md`
- `gate/`
- `README.md`
- `CHANGELOG.md`

## 验收方法

1. iOS App 在可用模拟器 SDK 下编译，Create/Edit/Me 导航存在。
2. 客户端能够导入哼唱文件并调用真实 `/v1/analysis/jobs` API。
3. API 对原始 Vocal、幂等键、上传上限、任务状态和派生资产进行测试。
4. Basic Pitch 对合成音频实际生成 MIDI，不以测试夹具替代模型验证。
5. 未取得的 BLE 协议、SoundFont 和生产部署能力被明确标记，不宣称完成。

## 自验结果

- `xcodebuild ... build`：通过。
- iPhone 18 Pro / iOS 27 模拟器 XCTest：2 项通过。
- Python `pytest`：6 项通过。
- Basic Pitch 0.4.0 合成音频烟雾测试：生成 1 个音符、315 字节 MIDI。
- Uvicorn 实际启动成功；`GET /health` 与 `/openapi.json` 均返回 200，转写可用、渲染因本机缺少 FluidSynth/SoundFont 明确报告为不可用。
- `Info.plist`：`plutil -lint` 通过。
- Markdown 相对链接与代码围栏检查：通过。
- iPhone 18 Pro / iOS 27 模拟器已安装并启动 App，Create 首屏视觉检查通过；开发模拟状态和真实 API 入口均清晰标注。
- FluidSynth 和授权 SoundFont：本机未提供，真实乐器音色端到端渲染尚未验证。
- 真机 BLE：缺少硬件协议与样机，尚未验证。

以上为执行者自验，尚未构成用户验收。
