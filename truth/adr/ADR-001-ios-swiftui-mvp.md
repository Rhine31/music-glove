# ADR-001：首版客户端采用 iPhone 原生 SwiftUI

- 状态：`accepted`
- 日期：2026-10-16
- 审批：用户在当前会话明确确认“iPhone 原生 SwiftUI + Python/FastAPI + BLE + Basic Pitch + SoundFont”首版方向

## 背景

首版需要同时处理手机 UI、文件导入、低延迟音频、后续 Core Bluetooth 手套接入和 iOS 无障碍能力。继续保持平台未决会阻塞阶段 A 工程骨架。

## 选项

1. iPhone 原生 SwiftUI。
2. Flutter 双平台。
3. React Native 双平台。

## 决定

首版先实现 iPhone 原生 SwiftUI App，使用 Swift 6 语言模式。当前工程的最低部署目标暂设为 iOS 17，以使用稳定的 SwiftUI 导航、文件导入和现代并发能力。

Android 不在首版实现范围内，但领域模型、API 和硬件协议边界不得依赖 SwiftUI 类型，为后续平台客户端保留复用空间。

## 理由

- Core Bluetooth、AVFAudio、后台行为和系统权限可直接使用平台 API。
- 当前设计是手机 App，原生实现便于校验 Dynamic Type、VoiceOver、安全区域和标准导航行为。
- 首版优先验证音乐创作闭环，不同时承担两个客户端平台的适配成本。

## 后果

- `object/ios/` 成为首版客户端正式开发区。
- Android 延后，不代表产品永远只支持 iOS。
- iOS 17 最低版本仍需在实机覆盖和用户设备目标明确后通过 ADR-010 最终确认。
- App 必须经端口协议访问设备、分析和存储，页面不能直接耦合后端或厂商 BLE 类型。

## 兼容与迁移

共享 API 使用普通 HTTP/JSON 与 multipart，标识和状态值不采用 Apple 专有类型。若后续增加 Android，复用服务契约和领域语义，单独实现 UI 与平台适配器。

## 验证证据

- Xcode 27 / Swift 6.4 下，iOS 17+ 模拟器构建通过。
- iPhone 18 Pro / iOS 27 模拟器领域单元测试通过。
