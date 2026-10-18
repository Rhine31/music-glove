# Music Glove

Music Glove 是一个结合可穿戴手套与手机 App 的交互音乐创作系统。用户通过双手模拟乐器动作并同时哼唱，系统识别乐器类型、分析旋律，并把灵感转换成可编辑、可试听、可保存与可导出的音乐项目。

## 项目入口

- [设计文档](truth/design.md)
- [架构文档](truth/architecture.md)
- [工程文档](truth/engineering.md)
- [Agent 协作规则](AGENTS.md)
- [变更记录](CHANGELOG.md)

## 当前可运行内容

- [iPhone SwiftUI App](object/ios/README.md)：Create / Edit / Me、开发模拟手套状态、真实分析 API、Quick Adjust、内存多轨草稿与 MIDI 文件导出。
- [Python 分析服务](object/service/README.md)：FastAPI 幂等任务、原始 Vocal 独立保存、Basic Pitch 音符/MIDI，以及可选的 FluidSynth + SoundFont 乐器试听。
- [质量门禁](gate/check.sh)：服务契约测试、iOS 单元测试、编译与配置检查。

## 克隆并使用 Xcode 运行

运行 iPhone App 需要 macOS、Xcode 以及 iOS 17 或更新版本的模拟器。界面演示不要求先启动 Python 服务；涉及真实哼唱分析、MIDI 或试听时，再按 [分析服务说明](object/service/README.md) 启动本地 API。

```bash
git clone https://github.com/Rhine31/music-glove.git
cd music-glove/object/ios
open MusicGlove.xcodeproj
```

在 Xcode 顶部选择 `MusicGlove` scheme 和一台可用的 iPhone Simulator，然后点击 Run。工程使用共享 scheme，不需要提交者本机的 Xcode 用户状态或 DerivedData。

也可以在终端仅验证 iOS 工程；把 destination 改成自己已安装的模拟器：

```bash
xcodebuild \
  -project object/ios/MusicGlove.xcodeproj \
  -scheme MusicGlove \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  CODE_SIGNING_ALLOWED=NO \
  test
```

完整质量门禁还需要先创建 `object/service/.venv`，具体依赖安装见服务说明。虚拟环境、测试缓存、本地分析数据、Xcode 用户状态和构建产物均由 `.gitignore` 排除，不随仓库分发。

## 目录

| 目录 | 用途 |
| --- | --- |
| `charter/` | 项目章程、范围和里程碑 |
| `truth/` | 经确认的设计、架构和工程正本 |
| `object/` | App、固件、云服务及共享代码等实际产物 |
| `queue/` | 任务、计划、交接和验收记录 |
| `gate/` | 必须通过的测试与发布门禁 |
| `eval/` | 体验与模型效果评价 |
| `tool/` | 项目脚本与开发工具 |
| `reference/` | 有来源的外部参考资料 |

项目已进入阶段 A 工程骨架开发。首版采用 iPhone 原生 SwiftUI、Bluetooth Low Energy 方向，以及 Python/FastAPI + Spotify Basic Pitch + FluidSynth/SoundFont 分析管线；手套具体协议、数据库、生产云部署、授权 SoundFont、同步和正式文件格式仍待后续 ADR 确认。

## 许可证

项目目前尚未授予开源许可证。其他人可以克隆并在本地查看、构建和运行，但复制、修改或再分发权限仍以 [LICENSE](LICENSE) 中的声明为准。
