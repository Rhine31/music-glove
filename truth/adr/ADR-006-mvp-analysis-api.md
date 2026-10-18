# ADR-006：MVP 分析 API 与哼唱转换管线

- 状态：`accepted-for-mvp`
- 日期：2026-10-16
- 审批：用户在当前会话确认 Python/FastAPI、Spotify Basic Pitch 与 SoundFont 路线

## 背景

项目必须调用真实 API，把原始哼唱转换成可编辑音乐信息，再结合手势识别出的乐器类型生成相应乐器音色的试听。原始 Vocal 不得被覆盖，重试不得产生重复任务。

## 选项

1. 自建 Python API，使用 Basic Pitch 转 MIDI，并用 SoundFont 渲染。
2. 直接依赖第三方托管音频转 MIDI API。
3. 仅在手机本地推理与渲染。

## 决定

MVP 使用 Python FastAPI 提供版本化 HTTP API：

1. App 以 multipart 上传原始 Vocal、稳定录制会话 ID 和本地手势识别得到的乐器类型，并携带幂等键。
2. 服务独立保存不可变原始 Vocal，并记录内容 SHA-256。
3. Spotify Basic Pitch 0.4.0 从哼唱生成可编辑 MIDI。
4. 服务返回 Basic Pitch 音符事件和 MIDI；音符事件在 MVP 传输层保留源音频秒数，进入正式项目存储前再转换为音乐时间。
5. 服务按乐器类型设置 General MIDI program，并在 FluidSynth 与项目外部合法 SoundFont 可用时生成 WAV 试听。
6. App 轮询任务状态并接收 MIDI、可选试听资产地址与非致命警告；缺少渲染器时转录仍完成，但明确标记试听不可用，不生成伪造音频。

此决定只覆盖 MVP API、模型与试听管线。云服务商、对象存储、持久任务队列、认证和生产部署仍待确认，因此 ADR-006 的生产门禁尚未完全关闭。

## 理由

- FastAPI 可生成可检查的 OpenAPI，并适合 Python 音乐分析生态。
- Basic Pitch 输出 MIDI 与音符事件，符合“哼唱决定音高和节奏”的领域规则。
- SoundFont 渲染把同一 MIDI 与手势识别乐器结合，切换乐器不会改写音符。
- 自有 API 保留幂等、原始资产与后续云端精修的控制权。

## 后果

- `object/service/` 是真实可运行 API，不是客户端 stub。
- Basic Pitch 模型质量、哼唱噪声容错和节奏精度必须在 `eval/` 单独评估。
- 项目不内置来源不明 SoundFont；部署必须配置授权资源并登记许可证。
- 当前进程内后台任务不具备生产级崩溃恢复，后续需持久队列和对象存储。
- 本地初步转写仍未实现；本 ADR 不能取消架构要求的“本地草稿 + 云端精修”。

## 兼容与迁移

API 路径固定在 `/v1/`。后续更换模型或任务系统时保持输入语义和稳定 `jobId`，派生结果记录算法版本；不覆盖旧结果或原始 Vocal。

## 验证证据

- FastAPI 契约、上传上限、幂等冲突、原始资产保存和派生资产下载测试通过。
- Basic Pitch 0.4.0 已在项目 Python 3.9 虚拟环境中，对 1 秒 440 Hz 合成音频生成 1 个音符和有效 MIDI。
- 本机尚无 FluidSynth 与授权 SoundFont，因此真实目标音色渲染未完成端到端验证。
