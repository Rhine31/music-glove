# T-20261017 GitHub 发布准备

- 状态：`in-progress`
- 授权：用户明确要求上传到 GitHub，使其他人可下载并用 Xcode 运行。

## 范围

- 将当前项目初始化为 Git 仓库并提交可复现源码与文档。
- 排除本地虚拟环境、缓存、生成数据、Xcode 用户状态和构建产物。
- 提供克隆后用 Xcode 打开共享 scheme 的步骤。
- 创建公开 GitHub 仓库并推送默认分支。

## 边界

- 项目许可证尚未决定，不添加或替换开源许可证。
- 不提交令牌、密码、原始用户音频、可识别动作数据、来源不明 SoundFont 或本地服务数据。
- 不提交 `object/service/.venv`；使用者根据 `pyproject.toml` 自行建立环境。

## 自验

- [x] `.gitignore` 命中本地生成内容。
- [x] Markdown 链接与 Xcode 工程配置通过检查。
- [x] 服务测试与 iOS XCTest 通过。
- [ ] GitHub 默认分支可见且可克隆。
- [x] 从已跟踪文件中未检出明显凭据。
