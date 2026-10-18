import Combine
import Foundation

@MainActor
final class AppModel: ObservableObject {
    @Published var selectedTab: AppTab = .create
    @Published private(set) var gloveState: GloveConnectionState = .disconnected
    @Published var recording = RecordingSession()
    @Published private(set) var analysisJob: AnalysisJob?
    @Published private(set) var isSubmitting = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var projectTracks: [ProjectTrack] = []
    @Published private(set) var serviceState: AnalysisServiceState = .checking

    private let gloveGateway: any GloveGateway
    private let analysisService: any AnalysisServicing

    init(
        gloveGateway: any GloveGateway = SimulatedGloveGateway(),
        analysisService: (any AnalysisServicing)? = nil
    ) {
        self.gloveGateway = gloveGateway
        if let analysisService {
            self.analysisService = analysisService
        } else {
            let rawURL = ProcessInfo.processInfo.environment["MUSIC_GLOVE_API_URL"]
                ?? "http://127.0.0.1:8000"
            let baseURL = URL(string: rawURL) ?? URL(string: "http://127.0.0.1:8000")!
            self.analysisService = HTTPAnalysisService(baseURL: baseURL)
        }
    }

    func connectDevelopmentGlove() async {
        gloveState = .connecting
        do {
            gloveState = try await gloveGateway.connect()
        } catch {
            gloveState = .failed(message: error.localizedDescription)
        }
    }

    func refreshServiceHealth() async {
        serviceState = .checking
        do {
            let health = try await analysisService.health()
            if health.transcriptionAvailable {
                serviceState = health.rendererAvailable ? .ready : .transcriptionOnly
            } else {
                serviceState = .unavailable
            }
        } catch {
            serviceState = .unavailable
        }
    }

    func disconnectGlove() async {
        await gloveGateway.disconnect()
        gloveState = .disconnected
    }

    func selectAudio(_ url: URL) {
        if recording.sourceAudioURL != nil || analysisJob != nil {
            recording = RecordingSession(
                selectedInstrument: recording.selectedInstrument,
                sourceAudioURL: url
            )
        } else {
            recording.sourceAudioURL = url
        }
        analysisJob = nil
        errorMessage = nil
    }

    func submitAnalysis() async {
        guard let vocalURL = recording.sourceAudioURL else {
            errorMessage = MusicGloveError.missingAudio.localizedDescription
            return
        }

        isSubmitting = true
        defer { isSubmitting = false }
        errorMessage = nil
        let key = "\(recording.id.uuidString)-analysis-v1"

        do {
            var job = try await analysisService.submit(
                session: recording,
                vocalURL: vocalURL,
                idempotencyKey: key
            )
            analysisJob = job

            for _ in 0..<120 where job.status == .queued || job.status == .processing {
                try await Task.sleep(for: .seconds(1))
                job = try await analysisService.status(jobID: job.jobID)
                analysisJob = job
            }

            if job.status == .queued || job.status == .processing {
                throw MusicGloveError.analysisTimedOut
            }
            if job.status == .failed {
                errorMessage = job.error?.message ?? "分析失败，请重试。"
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func startNewSession() {
        recording = RecordingSession(selectedInstrument: recording.selectedInstrument)
        analysisJob = nil
        errorMessage = nil
    }

    func addToProject(_ draft: MelodyDraft) {
        guard let job = analysisJob, job.status == .completed else { return }

        let vocalID = "vocal-\(job.rawVocalAssetID)"
        if !projectTracks.contains(where: { $0.id == vocalID }) {
            projectTracks.append(
                ProjectTrack(
                    id: vocalID,
                    name: "Vocal",
                    kind: .vocal(assetID: job.rawVocalAssetID),
                    notes: [],
                    midiURL: nil
                )
            )
        }

        let instrumentID = "instrument-\(draft.sourceJobID)"
        let track = ProjectTrack(
            id: instrumentID,
            name: draft.instrument.title,
            kind: .instrument(draft.instrument),
            notes: draft.notes,
            midiURL: job.midiURL.flatMap(URL.init(string:))
        )
        if let index = projectTracks.firstIndex(where: { $0.id == instrumentID }) {
            projectTracks[index] = track
        } else {
            projectTracks.append(track)
        }
        selectedTab = .edit
    }

    func downloadMIDI(for track: ProjectTrack) async throws -> Data {
        guard let midiURL = track.midiURL else {
            throw MusicGloveError.assetUnavailable
        }
        return try await analysisService.downloadAsset(from: midiURL)
    }
}
