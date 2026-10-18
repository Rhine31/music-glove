import Foundation

/// Development-only adapter. It never claims to represent the final BLE packet protocol.
struct SimulatedGloveGateway: GloveGateway {
    func connect() async throws -> GloveConnectionState {
        try await Task.sleep(for: .milliseconds(350))
        return .simulated
    }

    func disconnect() async {}
}
