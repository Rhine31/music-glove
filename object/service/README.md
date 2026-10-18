# Music Glove Analysis Service

这是首版真实 HTTP 分析服务。客户端上传一份不可变的原始哼唱音频和手势识别得到的乐器类型，服务使用 Spotify Basic Pitch 生成可编辑 MIDI，再使用 FluidSynth 与指定 SoundFont 生成该乐器音色的 WAV 试听。

## 本地启动

```bash
cd object/service
python3 -m venv .venv
.venv/bin/python -m pip install -e '.[analysis,dev]'
export MUSIC_GLOVE_SOUNDFONT=/absolute/path/to/authorized-soundfont.sf2
.venv/bin/python -m uvicorn app.main:app --host 127.0.0.1 --port 8000
```

打开 `http://127.0.0.1:8000/docs` 可查看交互式 API 文档。`GET /health` 会分别报告 Basic Pitch 和渲染器是否就绪。未配置 SoundFont 或系统没有 `fluidsynth` 时，服务仍会用 Basic Pitch 完成音符与 MIDI，并通过 `warnings` 明确说明乐器预览音频不可用，不返回伪造试听。

## API

- `POST /v1/analysis/jobs`：以 multipart 上传 `vocal`、`session_id`、`instrument`，并提供 `X-Idempotency-Key`。
- `GET /v1/analysis/jobs/{job_id}`：查询任务状态。
- `GET /v1/analysis/jobs/{job_id}/assets/midi`：下载 MIDI。
- `GET /v1/analysis/jobs/{job_id}/assets/preview`：下载目标乐器音色的 WAV 试听。

任务响应同时包含 Basic Pitch 产生的 `note_events`，供客户端建立可编辑旋律草稿；资产字段为当前请求来源下的绝对 URL。原始 Vocal 保存为单独资产；派生音符、MIDI 和试听文件不会覆盖它。`.local-data/` 只用于本机开发，不应提交。

使用相同幂等键重试可重试失败时，服务会复用原 `job_id` 并重新执行分析；相同键配不同输入仍返回 `409 idempotency_conflict`。

若 Basic Pitch 没有识别到音符，任务返回不可重试的 `no_melody_detected` 验证错误；原始 Vocal 仍保留，客户端应让用户以新录制会话选择更清晰的输入。

## 当前限制

- 后台任务目前运行在单个 API 进程内；进程中断后的持久化队列恢复留待 ADR-006 的部署部分完成。
- 当前文件存储是首版适配器，不代表 ADR-004 已决定数据库。
- Basic Pitch 对单一旋律输入效果最佳；模型质量需要在 `eval/` 使用获授权样本单独评估。
- 项目不分发 SoundFont。使用者必须提供授权允许的 `.sf2` 文件。

## 依赖与许可证影响

| 依赖 | 用途 | 许可证/注意事项 |
| --- | --- | --- |
| FastAPI / Uvicorn | HTTP API 与本地开发服务器 | MIT / BSD-3-Clause |
| python-multipart | multipart 音频上传 | Apache-2.0 |
| Spotify Basic Pitch 0.4.0 | 音频转 MIDI | 仓库声明 Apache-2.0 或 GPL-3.0 双许可；正式发行前由项目选择并记录采用的许可路径 |
| FluidSynth | SoundFont MIDI 渲染 | LGPL-2.1-or-later；当前通过独立命令调用，不随项目打包 |
| SoundFont | 乐器音色资源 | 许可证由具体文件决定，必须单独核验，不得提交来源不明资源 |

项目自身的正式许可证仍未决定，本表不构成法律意见。
