# T-20261016 Stage A upload memory

- 状态：`review`
- 授权依据：用户要求继续开发。
- 目标：避免客户端提交哼唱时把完整音频载入内存，并保证含敏感音频的临时请求体可靠清理。

## 范围

- `object/ios/MusicGlove/Infrastructure/HTTPAnalysisService.swift`
- `object/ios/MusicGloveTests/HTTPAnalysisServiceTests.swift`
- `object/ios/README.md`
- `CHANGELOG.md`

## 验收方法

1. 原始音频以固定大小块复制到临时 multipart 文件，不调用完整文件 `Data(contentsOf:)`。
2. multipart 文件名不使用外部文件名，避免 header 注入。
3. 临时请求体采用 iOS 文件保护，并在成功、失败或任务取消后清理。
4. URLSession 通过文件上传 API 发送请求，服务响应仍按现有契约解码。

## 自验结果

- iPhone 18 Pro / iOS 27 模拟器 XCTest：12 项通过，其中 3 项覆盖 multipart 文件内容、成功清理和网络失败清理。
- 完整 `gate/check.sh`：Python 10 项、当时 iOS 11 项、Markdown 链接、代码围栏与 Info.plist 检查均通过；新增网络失败清理测试后再次执行 iOS 全部 12 项并通过。
- 尚未实现生产级后台上传与断点续传；它们依赖持久队列和存储 ADR。

以上为执行者自验，尚未构成用户验收。
