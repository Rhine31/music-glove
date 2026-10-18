import SwiftUI
import UniformTypeIdentifiers

struct CreateHomeView: View {
    @EnvironmentObject private var model: AppModel
    @State private var showsRecording = false
    @State private var showsAudioImporter = false
    @State private var showsInstrumentChoice = false
    @State private var routesToQuickAdjust = false

    var body: some View {
        ZStack {
            MGScreenBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    Text("Create")
                        .font(.system(size: 40, weight: .bold, design: .rounded))

                    gloveCard
                    readyCard

                    Text("Continue Current Creation")
                        .font(.title2.weight(.medium))

                    currentProjectCard
                    serviceNotice

                    if let error = model.errorMessage {
                        errorCard(error)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 104)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .task { await model.refreshServiceHealth() }
        .navigationDestination(isPresented: $showsRecording) {
            RecordingImportView {
                showsAudioImporter = true
            }
        }
        .navigationDestination(isPresented: $routesToQuickAdjust) {
            if let job = model.analysisJob {
                QuickAdjustView(job: job)
            }
        }
        .confirmationDialog(
            "Development input: choose the instrument gesture",
            isPresented: $showsInstrumentChoice,
            titleVisibility: .visible
        ) {
            ForEach(InstrumentType.allCases) { instrument in
                Button(instrument.title) {
                    model.recording.selectedInstrument = instrument
                    showsRecording = true
                }
            }
        } message: {
            Text("The real glove protocol is not available yet. This selection replaces gesture recognition only during development.")
        }
        .fileImporter(
            isPresented: $showsAudioImporter,
            allowedContentTypes: [.audio],
            allowsMultipleSelection: false
        ) { result in
            guard case let .success(urls) = result, let url = urls.first else { return }
            model.selectAudio(url)
            Task {
                await model.submitAnalysis()
                if model.analysisJob?.status == .completed {
                    showsRecording = false
                    routesToQuickAdjust = true
                }
            }
        }
    }

    private var gloveCard: some View {
        Image("CreateGloveStatusCard")
            .resizable()
            .scaledToFit()
            .frame(maxWidth: .infinity)
            .accessibilityLabel("Music Glove 01, RSSIABCDE-0111, Connected, battery 50 percent")
            .accessibilityHint("Development preview device status")
    }

    private var readyCard: some View {
        Button {
            showsInstrumentChoice = true
        } label: {
            VStack(spacing: 16) {
                Text(model.isSubmitting ? "Analyzing your melody…" : "Ready to create?")
                    .font(.title.weight(.medium))

                if model.isSubmitting {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(1.5)
                        .frame(height: 190)
                } else {
                    MGOrb(size: 190)
                }

                Text(model.isSubmitting ? "Keep this screen open" : "Tap to start")
                    .font(.title2)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 28)
            .background(
                LinearGradient(
                    colors: [Color(red: 0.55, green: 0.54, blue: 0.54), Color(red: 0.31, green: 0.34, blue: 0.42)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 22)
            )
            .shadow(color: MGTheme.accent.opacity(0.18), radius: 18, y: 8)
        }
        .buttonStyle(.plain)
        .disabled(model.isSubmitting || model.serviceState == .checking || model.serviceState == .unavailable)
        .accessibilityHint("Choose a development instrument and import the original Vocal recording")
    }

    private var currentProjectCard: some View {
        MGCard {
            HStack(spacing: 14) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [MGTheme.cream, MGTheme.ice],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 68, height: 68)
                    .overlay {
                        Image(systemName: model.projectTracks.isEmpty ? "music.note" : "waveform")
                            .font(.title)
                            .foregroundStyle(MGTheme.graphite)
                    }

                VStack(alignment: .leading, spacing: 6) {
                    Text(model.projectTracks.isEmpty ? "No current creation" : "Current Creation")
                        .font(.title3.weight(.semibold))
                    Text(
                        model.projectTracks.isEmpty
                            ? "Your analyzed tracks will appear here"
                            : "\(model.projectTracks.count) tracks · editable project"
                    )
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
                Spacer()
                if !model.projectTracks.isEmpty {
                    Image(systemName: "ellipsis")
                        .font(.title3)
                }
            }
        }
    }

    private var serviceNotice: some View {
        HStack(spacing: 9) {
            Image(systemName: serviceStatusSymbol)
            Text(model.serviceState.title)
            Spacer()
            if model.serviceState == .unavailable {
                Button("Retry") { Task { await model.refreshServiceHealth() } }
            }
        }
        .font(.footnote.weight(.medium))
        .foregroundStyle(serviceStatusColor)
        .padding(.horizontal, 4)
        .accessibilityElement(children: .combine)
    }

    private var serviceStatusSymbol: String {
        switch model.serviceState {
        case .checking: "arrow.triangle.2.circlepath"
        case .ready: "checkmark.circle.fill"
        case .transcriptionOnly: "waveform.badge.checkmark"
        case .unavailable: "exclamationmark.triangle.fill"
        }
    }

    private var serviceStatusColor: Color {
        switch model.serviceState {
        case .checking: .secondary
        case .ready: MGTheme.success
        case .transcriptionOnly: .orange
        case .unavailable: .red
        }
    }

    private func errorCard(_ message: String) -> some View {
        MGCard {
            VStack(alignment: .leading, spacing: 10) {
                Label("Analysis not completed", systemImage: "exclamationmark.triangle.fill")
                    .font(.headline)
                    .foregroundStyle(.orange)
                Text(message)
                    .font(.subheadline)
                Button("Choose another recording") { showsAudioImporter = true }
                    .frame(minHeight: MGTheme.minimumTapTarget)
            }
        }
    }
}

private struct RecordingImportView: View {
    let selectRecording: () -> Void

    var body: some View {
        ZStack {
            MGScreenBackground()

            VStack(spacing: 26) {
                Text("Recording…")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                Label("Waiting for the original Vocal", systemImage: "circle.fill")
                    .font(.title3)
                    .foregroundStyle(.secondary)

                Spacer()

                Button(action: selectRecording) {
                    MGOrb(size: 235, isActive: true)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Select the Vocal recording captured by the product")

                MGWaveform(color: MGTheme.accent, barCount: 23)
                    .frame(height: 90)
                    .padding(.horizontal, 22)

                Spacer()

                Button("Select Recorded Vocal", action: selectRecording)
                    .buttonStyle(MGPrimaryButtonStyle())
                    .padding(.horizontal, 20)

                Text("The current development build imports the product recording. Live glove capture will replace this step after the hardware protocol is available.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 26)
            }
            .padding(.vertical, 22)
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}
