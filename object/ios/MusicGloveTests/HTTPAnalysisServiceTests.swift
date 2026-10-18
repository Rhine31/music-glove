import Foundation
import XCTest
@testable import MusicGlove

final class HTTPAnalysisServiceTests: XCTestCase {
    override func tearDown() {
        URLProtocolStub.handler = nil
        super.tearDown()
    }

    func testHealthDecodesIndependentTranscriptionAndRendererCapabilities() async throws {
        URLProtocolStub.handler = { request in
            XCTAssertEqual(request.url?.path, "/health")
            return Self.response(
                request: request,
                status: 200,
                body: #"{"status":"ok","transcription_available":true,"renderer_available":false}"#
            )
        }

        let health = try await makeService().health()

        XCTAssertTrue(health.transcriptionAvailable)
        XCTAssertFalse(health.rendererAvailable)
    }

    func testServiceErrorPreservesHTTPStatusAndSafeDetail() async {
        URLProtocolStub.handler = { request in
            Self.response(
                request: request,
                status: 409,
                body: #"{"detail":"idempotency_conflict"}"#
            )
        }

        do {
            _ = try await makeService().status(jobID: "job-1")
            XCTFail("Expected service error")
        } catch let error as MusicGloveError {
            XCTAssertEqual(
                error,
                .service(statusCode: 409, message: "idempotency_conflict")
            )
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testSubmitUsesFileUploadAndRemovesStagedMultipartBody() async throws {
        let root = FileManager.default.temporaryDirectory
            .appending(path: "music-glove-upload-test-\(UUID().uuidString)")
        let staging = root.appending(path: "staging", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: staging, withIntermediateDirectories: true)
        let vocal = root.appending(path: "input.wav")
        try Data("synthetic-vocal".utf8).write(to: vocal)
        defer { try? FileManager.default.removeItem(at: root) }

        URLProtocolStub.handler = { request in
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertTrue(
                request.value(forHTTPHeaderField: "Content-Type")?
                    .hasPrefix("multipart/form-data; boundary=MusicGlove-") == true
            )
            XCTAssertNotNil(request.value(forHTTPHeaderField: "X-Idempotency-Key"))
            return Self.response(request: request, status: 202, body: Self.jobResponseBody)
        }

        let job = try await makeService(stagingDirectory: staging).submit(
            session: RecordingSession(selectedInstrument: .piano),
            vocalURL: vocal,
            idempotencyKey: "stable-key-00000001"
        )

        XCTAssertEqual(job.status, .completed)
        XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath: staging.path), [])
    }

    func testSubmitRemovesStagedMultipartBodyAfterNetworkFailure() async throws {
        let root = FileManager.default.temporaryDirectory
            .appending(path: "music-glove-upload-failure-test-\(UUID().uuidString)")
        let staging = root.appending(path: "staging", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: staging, withIntermediateDirectories: true)
        let vocal = root.appending(path: "input.wav")
        try Data("synthetic-vocal".utf8).write(to: vocal)
        defer { try? FileManager.default.removeItem(at: root) }
        URLProtocolStub.handler = { _ in throw URLError(.notConnectedToInternet) }

        do {
            _ = try await makeService(stagingDirectory: staging).submit(
                session: RecordingSession(selectedInstrument: .piano),
                vocalURL: vocal,
                idempotencyKey: "stable-key-00000002"
            )
            XCTFail("Expected upload failure")
        } catch {
            XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath: staging.path), [])
        }
    }

    func testMultipartFileContainsFieldsAndUnmodifiedAudioBytes() throws {
        let root = FileManager.default.temporaryDirectory
            .appending(path: "music-glove-multipart-test-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let source = root.appending(path: "unsafe\"name.WAV")
        let audio = Data([0x00, 0x01, 0x0A, 0xFF, 0x42])
        try audio.write(to: source)
        let destination = root.appending(path: "body.multipart")

        try MultipartFileBuilder.write(
            destination: destination,
            boundary: "test-boundary",
            fields: [("session_id", "session-1"), ("instrument", "piano")],
            fileField: "vocal",
            sourceURL: source,
            contentType: "audio/wav"
        )
        let body = try Data(contentsOf: destination)
        let text = String(decoding: body, as: UTF8.self)

        XCTAssertTrue(text.contains("name=\"session_id\""))
        XCTAssertTrue(text.contains("name=\"instrument\""))
        XCTAssertTrue(text.contains("filename=\"vocal.wav\""))
        XCTAssertFalse(text.contains("unsafe\"name"))
        XCTAssertNotNil(body.range(of: audio))
        let ending = Data("--test-boundary--\r\n".utf8)
        XCTAssertTrue(body.suffix(ending.count).elementsEqual(ending))
    }

    func testDownloadAssetReturnsMIDIBytes() async throws {
        URLProtocolStub.handler = { request in
            Self.response(request: request, status: 200, body: "MThd-test")
        }

        let data = try await makeService().downloadAsset(
            from: URL(string: "https://music-glove.test/result.mid")!
        )

        XCTAssertTrue(data.starts(with: Data("MThd".utf8)))
    }

    func testDownloadAssetRejectsOversizedResponse() async {
        URLProtocolStub.handler = { request in
            Self.response(request: request, status: 200, body: "12345")
        }

        do {
            _ = try await makeService(maxDownloadedAssetBytes: 4).downloadAsset(
                from: URL(string: "https://music-glove.test/result.mid")!
            )
            XCTFail("Expected asset size error")
        } catch let error as MusicGloveError {
            XCTAssertEqual(error, .assetTooLarge)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    private func makeService(
        stagingDirectory: URL = FileManager.default.temporaryDirectory,
        maxDownloadedAssetBytes: Int = 10 * 1024 * 1024
    ) -> HTTPAnalysisService {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [URLProtocolStub.self]
        return HTTPAnalysisService(
            baseURL: URL(string: "https://music-glove.test")!,
            session: URLSession(configuration: configuration),
            uploadStagingDirectory: stagingDirectory,
            maxDownloadedAssetBytes: maxDownloadedAssetBytes
        )
    }

    private static func response(
        request: URLRequest,
        status: Int,
        body: String
    ) -> (HTTPURLResponse, Data) {
        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: status,
            httpVersion: nil,
            headerFields: ["Content-Type": "application/json"]
        )!
        return (response, Data(body.utf8))
    }

    private static let jobResponseBody = #"{"job_id":"job-1","session_id":"session-1","status":"completed","instrument":"piano","created_at":"2026-10-16T00:00:00Z","updated_at":"2026-10-16T00:00:01Z","raw_vocal_asset_id":"raw-vocal:abc","algorithm_version":"test","midi_url":"https://music-glove.test/result.mid","preview_audio_url":null,"note_events":[{"start_seconds":0.0,"end_seconds":0.5,"pitch_midi":69,"amplitude":0.8}],"warnings":[],"error":null}"#
}

private final class URLProtocolStub: URLProtocol, @unchecked Sendable {
    nonisolated(unsafe) static var handler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool { true }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let handler = Self.handler else {
            client?.urlProtocol(self, didFailWithError: MusicGloveError.invalidResponse)
            return
        }
        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}
