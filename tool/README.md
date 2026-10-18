# Music Glove 工具说明

本目录记录项目实际使用的开发工具、可重复命令与安全边界。第三方依赖、虚拟环境、缓存和个人配置不作为项目源码提交。

## 当前工具链

| 工具 | 当前用途 | 当前验证环境 |
| --- | --- | --- |
| Xcode | 打开、构建、测试和演示 iPhone App | Xcode 27.1 |
| Swift / SwiftUI | iOS 客户端、界面与应用状态 | Swift 6.4，最低目标暂定 iOS 17 |
| iOS Simulator | 无真机时运行高保真流程与 XCTest | iPhone 18 Pro / iOS 27.0 |
| Python | FastAPI 分析服务与测试 | Python 3.9.6 |
| FastAPI / Uvicorn | 哼唱分析 HTTP API 与本地服务 | 版本范围见 `object/service/pyproject.toml` |
| Spotify Basic Pitch | 将哼唱转换为音符事件和 MIDI | 固定为 0.4.0 |
| FluidSynth | 使用 SoundFont 把 MIDI 渲染为乐器试听 | 管线已接入；当前机器未安装 |
| SoundFont | 提供具体乐器采样音色 | 必须由使用者提供已授权的 `.sf2` 文件 |
| pytest | 服务端单元与 API 契约测试 | pytest 8.4.2 |
| Git / GitHub CLI | 版本管理、公开仓库推送与核验 | Git 2.56.0、GitHub CLI 2.102.0 |

## 仓库内工具入口

### 完整质量门禁

```bash
./gate/check.sh
```

输入是当前源码与本地 Python 虚拟环境；输出包括服务测试、Markdown 链接检查、`Info.plist` 校验和 iOS XCTest。任一检查失败时脚本以非零状态退出。

### Markdown 检查

```bash
object/service/.venv/bin/python gate/scripts/check_markdown_links.py
```

检查仓库内 Markdown 的本地链接和代码围栏，不修改文件。

### 打开 iOS 工程

```bash
open object/ios/MusicGlove.xcodeproj
```

在 Xcode 中选择共享的 `MusicGlove` scheme 和可用 iPhone Simulator 后运行。

### 启动分析服务

```bash
cd object/service
.venv/bin/python -m uvicorn app.main:app --host 127.0.0.1 --port 8000
```

需要完整乐器试听时，通过 `MUSIC_GLOVE_SOUNDFONT` 指向合法 SoundFont；没有渲染环境时仍可完成音符与 MIDI 转写，但不会伪造试听音频。

## 安全边界

- 不提交 `.venv/`、DerivedData、缓存、本地分析数据或来源不明的 SoundFont。
- 工具输出不得记录令牌、原始用户音频或可识别动作数据。
- 全局安装、付费服务、证书和账号操作需要用户明确授权。
- `tool/` 记录开发辅助能力；必须通过的检查仍统一放在 [`gate/`](../gate/)。
