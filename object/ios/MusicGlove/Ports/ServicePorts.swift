import Foundation

protocol AnalysisServicing: Sendable {
    func health() async throws -> AnalysisServiceHealth

    func submit(
        session: RecordingSession,
        vocalURL: URL,
        idempotencyKey: String
    ) async throws -> AnalysisJob

    func status(jobID: String) async throws -> AnalysisJob

    func downloadAsset(from url: URL) async throws -> Data
}

protocol GloveGateway: Sendable {
    func connect() async throws -> GloveConnectionState
    func disconnect() async
}

enum MusicGloveError: LocalizedError, Equatable {
    case invalidServerURL
    case invalidResponse
    case service(statusCode: Int, message: String)
    case missingAudio
    case analysisTimedOut
    case assetUnavailable
    case assetTooLarge

    var errorDescription: String? {
        switch self {
        case .invalidServerURL:
            "分析服务地址无效。"
        case .invalidResponse:
            "分析服务返回了无法读取的数据。"
        case let .service(statusCode, message):
            "分析服务错误（\(statusCode)）：\(message)"
        case .missingAudio:
            "请先选择一段哼唱音频。"
        case .analysisTimedOut:
            "分析仍在进行，请稍后重试。"
        case .assetUnavailable:
            "当前结果没有可导出的文件。"
        case .assetTooLarge:
            "下载的文件超过客户端允许的大小。"
        }
    }
}
