import Foundation

struct HTTPAnalysisService: AnalysisServicing {
    let baseURL: URL
    var session: URLSession = .shared
    var uploadStagingDirectory: URL = FileManager.default.temporaryDirectory
    var maxDownloadedAssetBytes = 10 * 1024 * 1024

    func health() async throws -> AnalysisServiceHealth {
        let endpoint = baseURL.appending(path: "health")
        let (data, response) = try await session.data(from: endpoint)
        try validate(response: response, data: data)
        do {
            return try JSONDecoder().decode(AnalysisServiceHealth.self, from: data)
        } catch {
            throw MusicGloveError.invalidResponse
        }
    }

    func submit(
        session recording: RecordingSession,
        vocalURL: URL,
        idempotencyKey: String
    ) async throws -> AnalysisJob {
        let endpoint = baseURL.appending(path: "v1/analysis/jobs")
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue(idempotencyKey, forHTTPHeaderField: "X-Idempotency-Key")

        let boundary = "MusicGlove-\(UUID().uuidString)"
        request.setValue(
            "multipart/form-data; boundary=\(boundary)",
            forHTTPHeaderField: "Content-Type"
        )

        let hasAccess = vocalURL.startAccessingSecurityScopedResource()
        defer {
            if hasAccess { vocalURL.stopAccessingSecurityScopedResource() }
        }
        let stagedBodyURL = uploadStagingDirectory
            .appending(path: "music-glove-upload-\(UUID().uuidString).multipart")
        try MultipartFileBuilder.write(
            destination: stagedBodyURL,
            boundary: boundary,
            fields: [
                ("session_id", recording.id.uuidString),
                ("instrument", recording.selectedInstrument.rawValue),
            ],
            fileField: "vocal",
            sourceURL: vocalURL,
            contentType: Self.contentType(for: vocalURL)
        )
        defer { try? FileManager.default.removeItem(at: stagedBodyURL) }

        let (data, response) = try await session.upload(for: request, fromFile: stagedBodyURL)
        return try decodeJob(data: data, response: response)
    }

    func status(jobID: String) async throws -> AnalysisJob {
        let endpoint = baseURL.appending(path: "v1/analysis/jobs/\(jobID)")
        return try await send(URLRequest(url: endpoint))
    }

    func downloadAsset(from url: URL) async throws -> Data {
        let (temporaryURL, response) = try await session.download(from: url)
        let values = try temporaryURL.resourceValues(forKeys: [.fileSizeKey])
        let size = values.fileSize ?? 0
        let responseBody = size <= 64 * 1024
            ? try Data(contentsOf: temporaryURL)
            : Data()
        try validate(response: response, data: responseBody)
        guard size <= maxDownloadedAssetBytes else {
            throw MusicGloveError.assetTooLarge
        }
        return try Data(contentsOf: temporaryURL, options: .mappedIfSafe)
    }

    private func send(_ request: URLRequest) async throws -> AnalysisJob {
        let (data, response) = try await session.data(for: request)
        return try decodeJob(data: data, response: response)
    }

    private func decodeJob(data: Data, response: URLResponse) throws -> AnalysisJob {
        try validate(response: response, data: data)
        do {
            return try JSONDecoder().decode(AnalysisJob.self, from: data)
        } catch {
            throw MusicGloveError.invalidResponse
        }
    }

    private static func contentType(for url: URL) -> String {
        switch url.pathExtension.lowercased() {
        case "wav", "wave": "audio/wav"
        case "m4a", "mp4": "audio/mp4"
        case "mp3": "audio/mpeg"
        case "aac": "audio/aac"
        case "caf": "audio/x-caf"
        default: "application/octet-stream"
        }
    }

    private func validate(response: URLResponse, data: Data) throws {
        guard let http = response as? HTTPURLResponse else {
            throw MusicGloveError.invalidResponse
        }
        guard 200..<300 ~= http.statusCode else {
            let message = (try? JSONDecoder().decode(ServiceError.self, from: data).detail)
                ?? HTTPURLResponse.localizedString(forStatusCode: http.statusCode)
            throw MusicGloveError.service(statusCode: http.statusCode, message: message)
        }
    }
}

private struct ServiceError: Decodable {
    let detail: String
}

struct MultipartFileBuilder {
    static func write(
        destination: URL,
        boundary: String,
        fields: [(String, String)],
        fileField: String,
        sourceURL: URL,
        contentType: String
    ) throws {
        let manager = FileManager.default
        guard manager.createFile(atPath: destination.path, contents: nil) else {
            throw CocoaError(.fileWriteUnknown)
        }
        do {
            try manager.setAttributes(
                [.protectionKey: FileProtectionType.completeUnlessOpen],
                ofItemAtPath: destination.path
            )
            let output = try FileHandle(forWritingTo: destination)
            defer { try? output.close() }

            for (name, value) in fields {
                try output.write(contentsOf: Data(
                    "--\(boundary)\r\nContent-Disposition: form-data; name=\"\(name)\"\r\n\r\n\(value)\r\n".utf8
                ))
            }

            let safeExtension = sourceURL.pathExtension.lowercased()
                .filter { $0.isLetter || $0.isNumber }
            let filename = safeExtension.isEmpty ? "vocal.bin" : "vocal.\(safeExtension)"
            try output.write(contentsOf: Data(
                "--\(boundary)\r\nContent-Disposition: form-data; name=\"\(fileField)\"; filename=\"\(filename)\"\r\nContent-Type: \(contentType)\r\n\r\n".utf8
            ))

            let input = try FileHandle(forReadingFrom: sourceURL)
            defer { try? input.close() }
            while let chunk = try input.read(upToCount: 1024 * 1024), !chunk.isEmpty {
                try output.write(contentsOf: chunk)
            }
            try output.write(contentsOf: Data("\r\n--\(boundary)--\r\n".utf8))
        } catch {
            try? manager.removeItem(at: destination)
            throw error
        }
    }
}
