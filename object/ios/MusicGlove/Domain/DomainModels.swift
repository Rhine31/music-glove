import Foundation

enum InstrumentType: String, Codable, CaseIterable, Identifiable, Sendable {
    case piano
    case guitar
    case drums
    case bass
    case strings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .piano: "钢琴"
        case .guitar: "吉他"
        case .drums: "鼓"
        case .bass: "贝斯"
        case .strings: "弦乐"
        }
    }

    var symbol: String {
        switch self {
        case .piano: "pianokeys"
        case .guitar: "guitars"
        case .drums: "music.note"
        case .bass: "waveform"
        case .strings: "music.quarternote.3"
        }
    }
}

enum AnalysisJobStatus: String, Codable, Sendable {
    case queued
    case processing
    case completed
    case failed

    var title: String {
        switch self {
        case .queued: "等待分析"
        case .processing: "正在转换旋律"
        case .completed: "分析完成"
        case .failed: "分析失败"
        }
    }
}

struct AnalysisServiceHealth: Codable, Equatable, Sendable {
    let status: String
    let transcriptionAvailable: Bool
    let rendererAvailable: Bool

    enum CodingKeys: String, CodingKey {
        case status
        case transcriptionAvailable = "transcription_available"
        case rendererAvailable = "renderer_available"
    }
}

enum AnalysisServiceState: Equatable, Sendable {
    case checking
    case ready
    case transcriptionOnly
    case unavailable

    var title: String {
        switch self {
        case .checking: "正在检查分析服务"
        case .ready: "分析与试听服务可用"
        case .transcriptionOnly: "旋律分析可用，乐器试听未配置"
        case .unavailable: "分析服务不可用"
        }
    }
}

struct APIErrorDetail: Codable, Equatable, Sendable {
    let code: String
    let message: String
    let retryable: Bool
}

struct APIWarningDetail: Codable, Equatable, Sendable {
    let code: String
    let message: String
}

struct NoteEvent: Codable, Equatable, Sendable {
    let startSeconds: Double
    let endSeconds: Double
    let pitchMIDI: Int
    let amplitude: Double

    enum CodingKeys: String, CodingKey {
        case startSeconds = "start_seconds"
        case endSeconds = "end_seconds"
        case pitchMIDI = "pitch_midi"
        case amplitude
    }
}

struct AnalysisJob: Codable, Identifiable, Equatable, Sendable {
    let jobID: String
    let sessionID: String
    let status: AnalysisJobStatus
    let instrument: InstrumentType
    let createdAt: String
    let updatedAt: String
    let rawVocalAssetID: String
    let algorithmVersion: String?
    let midiURL: String?
    let previewAudioURL: String?
    let noteEvents: [NoteEvent]
    let warnings: [APIWarningDetail]
    let error: APIErrorDetail?

    var id: String { jobID }

    enum CodingKeys: String, CodingKey {
        case jobID = "job_id"
        case sessionID = "session_id"
        case status
        case instrument
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case rawVocalAssetID = "raw_vocal_asset_id"
        case algorithmVersion = "algorithm_version"
        case midiURL = "midi_url"
        case previewAudioURL = "preview_audio_url"
        case noteEvents = "note_events"
        case warnings
        case error
    }
}

struct EditableNote: Identifiable, Equatable, Sendable {
    let id: UUID
    let startSeconds: Double
    let endSeconds: Double
    var pitchMIDI: Int
    var amplitude: Double

    init(event: NoteEvent, id: UUID = UUID()) {
        self.id = id
        startSeconds = event.startSeconds
        endSeconds = event.endSeconds
        pitchMIDI = event.pitchMIDI
        amplitude = event.amplitude
    }

    var noteName: String {
        let names = ["C", "C♯", "D", "D♯", "E", "F", "F♯", "G", "G♯", "A", "A♯", "B"]
        let safePitch = min(127, max(0, pitchMIDI))
        return "\(names[safePitch % 12])\(safePitch / 12 - 1)"
    }
}

struct MelodyDraft: Equatable, Sendable {
    let sourceJobID: String
    let instrument: InstrumentType
    var notes: [EditableNote]

    init(job: AnalysisJob) {
        sourceJobID = job.jobID
        instrument = job.instrument
        notes = job.noteEvents.map { EditableNote(event: $0) }
    }
}

struct ProjectTrack: Identifiable, Equatable, Sendable {
    enum Kind: Equatable, Sendable {
        case vocal(assetID: String)
        case instrument(InstrumentType)
    }

    let id: String
    let name: String
    let kind: Kind
    let notes: [EditableNote]
    let midiURL: URL?

    init(
        id: String,
        name: String,
        kind: Kind,
        notes: [EditableNote],
        midiURL: URL? = nil
    ) {
        self.id = id
        self.name = name
        self.kind = kind
        self.notes = notes
        self.midiURL = midiURL
    }
}

enum AppTab: Hashable {
    case create
    case edit
    case me
}

struct RecordingSession: Identifiable, Equatable, Sendable {
    let id: UUID
    let startedAt: Date
    var selectedInstrument: InstrumentType
    var sourceAudioURL: URL?

    init(
        id: UUID = UUID(),
        startedAt: Date = Date(),
        selectedInstrument: InstrumentType = .piano,
        sourceAudioURL: URL? = nil
    ) {
        self.id = id
        self.startedAt = startedAt
        self.selectedInstrument = selectedInstrument
        self.sourceAudioURL = sourceAudioURL
    }
}

enum GloveConnectionState: Equatable, Sendable {
    case disconnected
    case simulated
    case connecting
    case connected(name: String)
    case failed(message: String)

    var title: String {
        switch self {
        case .disconnected: "未连接"
        case .simulated: "模拟手套已连接"
        case .connecting: "正在连接"
        case let .connected(name): "已连接 · \(name)"
        case .failed: "连接失败"
        }
    }
}
