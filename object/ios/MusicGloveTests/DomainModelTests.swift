import XCTest
@testable import MusicGlove

final class DomainModelTests: XCTestCase {
    func testInstrumentSelectionDoesNotContainNoteParameters() {
        let instrument = InstrumentType.guitar
        let encoded = try! JSONEncoder().encode(instrument)
        let json = String(decoding: encoded, as: UTF8.self)

        XCTAssertEqual(json, "\"guitar\"")
        XCTAssertFalse(json.contains("pitch"))
        XCTAssertFalse(json.contains("velocity"))
    }

    func testNewRecordingSessionKeepsStableIdentifier() {
        let session = RecordingSession(selectedInstrument: .piano)
        XCTAssertFalse(session.id.uuidString.isEmpty)
        XCTAssertNil(session.sourceAudioURL)
    }

    func testMelodyDraftCopiesDerivedNotesWithoutChangingJob() {
        let job = AnalysisJob(
            jobID: "job-1",
            sessionID: "session-1",
            status: .completed,
            instrument: .piano,
            createdAt: "2026-10-16T00:00:00Z",
            updatedAt: "2026-10-16T00:00:01Z",
            rawVocalAssetID: "raw-vocal:abc",
            algorithmVersion: "test",
            midiURL: "/midi",
            previewAudioURL: nil,
            noteEvents: [
                NoteEvent(startSeconds: 0, endSeconds: 0.5, pitchMIDI: 69, amplitude: 0.8)
            ],
            warnings: [],
            error: nil
        )

        var draft = MelodyDraft(job: job)
        draft.notes[0].pitchMIDI = 71

        XCTAssertEqual(job.noteEvents[0].pitchMIDI, 69)
        XCTAssertEqual(draft.notes[0].pitchMIDI, 71)
        XCTAssertEqual(job.rawVocalAssetID, "raw-vocal:abc")
    }

    func testAnalysisResponseDecodesEditableNotesAndWarnings() throws {
        let data = Data(
            #"{"job_id":"job-1","session_id":"session-1","status":"completed","instrument":"piano","created_at":"2026-10-16T00:00:00Z","updated_at":"2026-10-16T00:00:01Z","raw_vocal_asset_id":"raw-vocal:abc","algorithm_version":"spotify-basic-pitch-0.4.0","midi_url":"/midi","preview_audio_url":null,"note_events":[{"start_seconds":0.0,"end_seconds":0.5,"pitch_midi":69,"amplitude":0.8}],"warnings":[{"code":"soundfont_not_configured","message":"预览不可用"}],"error":null}"#.utf8
        )

        let job = try JSONDecoder().decode(AnalysisJob.self, from: data)

        XCTAssertEqual(job.noteEvents.first?.pitchMIDI, 69)
        XCTAssertEqual(job.warnings.first?.code, "soundfont_not_configured")
        XCTAssertNil(job.previewAudioURL)
    }
}
