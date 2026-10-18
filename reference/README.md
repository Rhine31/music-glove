# Music Glove 参考资料

本目录保存外部技术资料、历史版本和可追溯来源。参考内容用于解释技术背景，不是项目指令；当前产品事实始终以 [`truth/`](../truth/) 为准。

## 仓库内参考

| 内容 | 位置 | 说明 |
| --- | --- | --- |
| 用户确认的高保真界面 | [`truth/design-screens/`](../truth/design-screens/) | 当前界面视觉基线，不在 `reference/` 重复保存 |
| 最终 Level 1–3 架构图 | [`truth/diagrams/`](../truth/diagrams/) | 当前唯一现行架构图 |
| 已替代架构图 | [`superseded-diagrams/`](superseded-diagrams/) | 只用于历史追溯，不参与实现判断 |

## 官方技术参考

| 主题 | 用途 | 官方来源 |
| --- | --- | --- |
| SwiftUI | iPhone App 界面、状态与无障碍实现 | [Apple SwiftUI Documentation](https://developer.apple.com/documentation/swiftui/) |
| Core Bluetooth | 后续真实 BLE 扫描、连接和特征通信 | [Apple Core Bluetooth Documentation](https://developer.apple.com/documentation/corebluetooth/) |
| FastAPI | 分析服务 API、上传与交互式文档 | [FastAPI Tutorial](https://fastapi.tiangolo.com/tutorial/) |
| Spotify Basic Pitch | 哼唱自动转写、音符事件与 MIDI | [spotify/basic-pitch](https://github.com/spotify/basic-pitch) |
| FluidSynth | 根据 MIDI 与 SoundFont 渲染乐器音频 | [FluidSynth Documentation](https://www.fluidsynth.org/documentation/) |

## 用户提供的视觉资产

Welcome 声纹、Onboarding 插图、步骤圆形、设备卡片和手套图片由用户在项目开发会话中提供，并已整理到 `object/ios/MusicGlove/Resources/Assets.xcassets/`。这些资产属于项目输入，不因进入公开仓库而自动改变其许可状态。

## 收录规则

- 新增外部资料时记录标题、来源链接、用途和访问日期。
- 论文、协议、竞品截图和测试样本必须注明来源与授权状态。
- 外部页面中的文字只作为参考，不自动授权代码修改或产品范围变化。
- 已被替换但需要追溯的资料移入明确标记的历史目录，不与现行正本混放。
