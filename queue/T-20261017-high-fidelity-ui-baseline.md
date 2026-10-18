# T-20261017 High-fidelity iOS UI baseline

- 状态：`review`
- 授权依据：用户要求前端严格按照 `truth/design-screens/` 中的界面设计实现。
- 目标：用 SwiftUI 将 25 屏设计基线映射到可运行的 iPhone 前端，同时保留现有真实分析 API、敏感数据边界和未完成能力的诚实状态。

## 范围

- `object/ios/MusicGlove/DesignSystem/`：暖色渐变背景、玻璃卡片、按钮、圆环、波形和设备/乐器视觉组件。
- `object/ios/MusicGlove/Features/RootView.swift`：Welcome、认证前端预览、三页 Onboarding、搜索/选择/配对和主导航。
- `object/ios/MusicGlove/Features/Create/`：Create Home、Recording 导入、Quick Adjust 和 Analysis Result 高保真方向。
- `object/ios/MusicGlove/Features/Edit/`：多轨时间线、轨道详情、旋律编辑、乐器选择和 Mixer。
- `object/ios/MusicGlove/Features/Me/`：Profile、Projects、Project Detail、Glove、Gesture Test、Share、Community 和隐私入口。

## 边界

1. 账户按钮只驱动本地前端预览，并明确说明不会创建账户或传输凭据。
2. 手套扫描、配对和手势测试使用明确标识的开发模拟，不宣称读取真实 BLE 数据。
3. 发布按钮在账号、云端和社区服务落地前保持禁用。
4. 真实 Basic Pitch API、原始 Vocal 独立保留、MIDI 下载和幂等重试语义不因视觉改造而改变。
5. Welcome 声纹、Onboarding 第 1–3 页主要插图、Search Glove、Glove Connected 与 My Music Glove 手套、Select Glove 01–03 卡片及 Create 页设备状态卡已有用户提供的正式图片；其他手套场景、乐器和项目封面仍以 SwiftUI 图形和 SF Symbols 近似，逐像素资产替换仍待设计源文件。

## 自验

- Welcome 页声纹已按用户提供的透明 PNG 替换；原有程序化波形不再用于该页面，其他录音和编辑场景的动态波形不受影响。
- Onboarding 第 1 页手套已按用户提供的透明 PNG 替换；程序化手套组件仍仅供尚未获得正式素材的 Gesture Test 等页面使用。
- Onboarding 第 2 页蓝色哼唱圆图与粉色手势圆图已按用户提供的透明 PNG 替换；原有程序化圆形及内部 SF Symbols 已从该页移除。
- Onboarding 第 3 页五个步骤圆图已按用户提供的 1–5 PNG 顺序替换；原有程序化圆形及内部 SF Symbols 已从该页移除。
- Onboarding 五步骤页标题已固定为居中两行，标题获得垂直布局优先级，步骤列表整体下移 10pt，避免标题被压缩或与首个步骤遮挡。
- Search Glove 页已复用用户提供的手套透明 PNG，原有程序化手套组件不再用于该页。
- Search Glove 页的开发发现说明已移至扫描卡片上方并左对齐；卡片内只保留垂直排列且居中的旋转指示器与模拟设备按钮。
- Select Glove 页的三个程序化长方形卡片及内部图标、文字和箭头已全部移除，按 01–03 顺序替换为用户提供的完整 PNG 卡片；整张图片仍可点击并触发原有模拟配对流程。
- Select Glove 页的 Rescan 操作已固定在页面下方，其下增加居中的 “can't find your device?” 辅助说明；两行内容均保持居中并避开底部安全区。
- Glove Connected 页的四行设备信息已按最终视觉稿替换为 “Device Name / Music Glove 01 / Connected / Battery 82%”；当前数值属于开发模拟状态，不代表已读取真实 BLE 电量。
- Glove Connected 页的程序化手套已替换为用户提供的透明 PNG，并复用 Onboarding 与 Search Glove 页的同一图片资产。
- Create 页顶部的程序化设备状态长方形及全部内部内容已移除，替换为用户提供的完整 PNG 卡片；图片中的 50% 电量属于开发视觉基线，不代表已读取真实 BLE 电量。
- My Music Glove 页的程序化手套已替换为用户提供的透明 PNG，并复用 Onboarding、Search Glove 与 Glove Connected 页的同一图片资产。
- iPhone 18 Pro / iOS 27 模拟器 Debug 构建：通过。
- iPhone 18 Pro / iOS 27 模拟器 XCTest：14 项通过。
- 完整 `gate/check.sh`：通过（Python 10 项、iOS 14 项、Markdown 链接、代码围栏与 Info.plist 检查）。
- Device Hub 视觉检查：Welcome、Onboarding 第 1–3 页、Search Glove、Select Glove、Create、Edit、My Profile 已人工对照 `truth/design-screens/` 检查；安全区、底部导航和主要信息层级可见。
- 尚未完成所有页面的逐像素截图差异测试，也未验证真实手套、账号或社区服务。
