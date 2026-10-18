import Foundation
import XCTest
@testable import MusicGlove

@MainActor
final class AppModelTests: XCTestCase {
    func testHealthMapsTranscriptionOnlyState() async {
        let service = StubAnalysisService(
            healthValue: AnalysisServiceHealth(
                status: "ok",
                transcriptionAvailable: true,
                rendererAvailable: false
            )
        )
        let model = AppModel(analysisService: service)

        await model.refreshServiceHealth()

        XCTAssertEqual(model.serviceState, .transcriptionOnly)
    }

    func testAddingCompletedResultKeepsOneVocalAndOneInstrumentTrack() async throws {
        let completed = Self.completedJob
        let service = StubAnalysisService(
            healthValue: AnalysisServiceHealth(
                status: "ok",
                transcriptionAvailable: true,
                rendererAvailable: true
            ),
            submittedJob: completed
        )
        let model = AppModel(analysisService: service)
        let audioURL = FileManager.default.temporaryDirectory
            .appending(path: "music-glove-app-model-test.wav")
        try Data("synthetic-audio".utf8).write(to: audioURL, options: .atomic)
        defer { try? FileManager.default.removeItem(at: audioURL) }

        model.selectAudio(audioURL)
        await model.submitAnalysis()
        let draft = MelodyDraft(job: completed)
        model.addToProject(draft)
        model.addToProject(draft)

        XCTAssertEqual(model.projectTracks.count, 2)
        let vocalTrack = try XCTUnwrap(model.projectTracks.first { $0.name == "Vocal" })
        XCTAssertNil(vocalTrack.midiURL)
        XCTAssertEqual(model.selectedTab, .edit)
        let instrumentTrack = try XCTUnwrap(
            model.projectTracks.first { $0.name == InstrumentType.piano.title }
        )
        let midiData = try await model.downloadMIDI(for: instrumentTrack)
        XCTAssertEqual(midiData, Data("MThd".utf8))
    }

    func testReplacingSelectedAudioCreatesNewRecordingIdentity() {
        let service = StubAnalysisService(
            healthValue: AnalysisServiceHealth(
                status: "ok",
                transcriptionAvailable: true,
                rendererAvailable: false
            )
        )
        let model = AppModel(analysisService: service)
        let firstURL = URL(fileURLWithPath: "/tmp/first.wav")
        let secondURL = URL(fileURLWithPath: "/tmp/second.wav")

        model.selectAudio(firstURL)
        let firstSessionID = model.recording.id
        model.selectAudio(secondURL)

        XCTAssertNotEqual(model.recording.id, firstSessionID)
        XCTAssertEqual(model.recording.sourceAudioURL, secondURL)
    }

    private static let completedJob = AnalysisJob(
        jobID: "job-completed",
        sessionID: "session-completed",
        status: .completed,
        instrument: .piano,
        createdAt: "2026-10-16T00:00:00Z",
        updatedAt: "2026-10-16T00:00:01Z",
        rawVocalAssetID: "raw-vocal:test",
        algorithmVersion: "test",
        midiURL: "https://music-glove.test/result.mid",
        previewAudioURL: nil,
        noteEvents: [
            NoteEvent(startSeconds: 0, endSeconds: 0.5, pitchMIDI: 69, amplitude: 0.8)
        ],
        warnings: [],
        error: nil
    )
}

private struct StubAnalysisService: AnalysisServicing {
    let healthValue: AnalysisServiceHealth
    var submittedJob: AnalysisJob?

    func health() async throws -> AnalysisServiceHealth {
        healthValue
    }

    func submit(
        session: RecordingSession,
        vocalURL: URL,
        idempotencyKey: String
    ) async throws -> AnalysisJob {
        guard let submittedJob else { throw MusicGloveError.invalidResponse }
        return submittedJob
    }

    func status(jobID: String) async throws -> AnalysisJob {
        guard let submittedJob else { throw MusicGloveError.invalidResponse }
        return submittedJob
    }

    func downloadAsset(from url: URL) async throws -> Data {
        Data("MThd".utf8)
    }
}
