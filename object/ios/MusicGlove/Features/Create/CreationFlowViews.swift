import AVFoundation
import SwiftUI

struct QuickAdjustView: View {
    let job: AnalysisJob
    @State private var draft: MelodyDraft
    @State private var selectedNoteID: UUID?

    init(job: AnalysisJob) {
        self.job = job
        let initialDraft = MelodyDraft(job: job)
        _draft = State(initialValue: initialDraft)
        _selectedNoteID = State(initialValue: initialDraft.notes.first?.id)
    }

    var body: some View {
        ZStack {
            MGScreenBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    VStack(spacing: 10) {
                        Text("Quick Adjust")
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                        Text("Adjust the melody and volume for a better result.\nTap a note to edit.")
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)

                    if draft.notes.isEmpty {
                        ContentUnavailableView {
                            Label("No notes detected", systemImage: "waveform.slash")
                        } description: {
                            Text("The original Vocal is preserved. Return and try a clearer recording.")
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("High")
                                .foregroundStyle(.secondary)
                            NoteTimeline(notes: draft.notes, selectedNoteID: $selectedNoteID)
                            HStack {
                                Text("Low")
                                Spacer()
                                Text("00:30")
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }

                        if let selectedIndex {
                            noteEditor(index: selectedIndex)
                        }

                        HStack(spacing: 14) {
                            Button("Play All") { }
                                .buttonStyle(MGPrimaryButtonStyle())

                            NavigationLink {
                                AnalysisResultView(job: job, draft: draft)
                            } label: {
                                Text("Apply")
                            }
                            .buttonStyle(MGSecondaryButtonStyle())
                        }
                    }
                }
                .padding(20)
                .padding(.bottom, 24)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    private var selectedIndex: Int? {
        guard let selectedNoteID else { return nil }
        return draft.notes.firstIndex(where: { $0.id == selectedNoteID })
    }

    private func noteEditor(index: Int) -> some View {
        MGCard {
            VStack(alignment: .leading, spacing: 18) {
                Text("Selected Note")
                    .font(.title3.weight(.semibold))

                HStack {
                    Text("Pitch")
                    Spacer()
                    Stepper(
                        draft.notes[index].noteName,
                        value: $draft.notes[index].pitchMIDI,
                        in: 0...127
                    )
                    .labelsHidden()
                    Text(draft.notes[index].noteName)
                        .monospacedDigit()
                        .frame(minWidth: 42)
                }

                VStack(alignment: .leading) {
                    HStack {
                        Text("Volume")
                        Spacer()
                        Text("\(Int(draft.notes[index].amplitude * 100))%")
                            .monospacedDigit()
                    }
                    Slider(value: $draft.notes[index].amplitude, in: 0...1)
                }
            }
        }
    }
}

struct AnalysisResultView: View {
    @EnvironmentObject private var model: AppModel

    let job: AnalysisJob
    let draft: MelodyDraft

    var body: some View {
        ZStack {
            MGScreenBackground()

            ScrollView {
                VStack(spacing: 22) {
                    Text("Instrument Detected")
                        .font(.system(size: 34, weight: .bold, design: .rounded))

                    MGInstrumentArtwork(instrument: job.instrument, size: 250)

                    Text(job.instrument.title)
                        .font(.title.bold())
                    Text("当前由开发替代输入指定；真实置信度需等待手套识别协议。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                    MGCard {
                        HStack(spacing: 14) {
                            Image(systemName: "play.fill")
                                .font(.title2)
                                .foregroundStyle(.white)
                                .frame(width: 52, height: 52)
                                .background(MGTheme.graphite, in: Circle())
                            MGWaveform()
                                .frame(height: 58)
                        }
                    }

                    if let value = job.previewAudioURL, let previewURL = URL(string: value) {
                        PreviewPlayer(url: previewURL)
                    } else {
                        Text("MIDI is ready. Instrument preview needs an authorized SoundFont.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }

                    Button {
                        model.addToProject(draft)
                    } label: {
                        Text("Add to Track")
                    }
                    .buttonStyle(MGPrimaryButtonStyle())

                    Button("Re-record") {
                        model.startNewSession()
                    }
                    .buttonStyle(MGSecondaryButtonStyle())
                }
                .padding(20)
                .padding(.bottom, 24)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct PreviewPlayer: View {
    let url: URL
    @State private var player: AVPlayer?
    @State private var isPlaying = false

    var body: some View {
        Button {
            if isPlaying {
                player?.pause()
                isPlaying = false
            } else {
                let activePlayer = player ?? AVPlayer(url: url)
                player = activePlayer
                activePlayer.seek(to: .zero)
                activePlayer.play()
                isPlaying = true
            }
        } label: {
            Label(isPlaying ? "Pause Preview" : "Play Instrument Preview", systemImage: isPlaying ? "pause.fill" : "play.fill")
                .frame(maxWidth: .infinity, minHeight: MGTheme.minimumTapTarget)
        }
        .buttonStyle(.bordered)
        .onDisappear {
            player?.pause()
            isPlaying = false
        }
    }
}

struct NoteTimeline: View {
    let notes: [EditableNote]
    @Binding var selectedNoteID: UUID?

    var body: some View {
        GeometryReader { geometry in
            let displayed = Array(notes.prefix(48))
            let minPitch = displayed.map(\.pitchMIDI).min() ?? 0
            let maxPitch = max(minPitch + 1, displayed.map(\.pitchMIDI).max() ?? 1)
            let endTime = max(0.1, displayed.map(\.endSeconds).max() ?? 0.1)

            ZStack {
                RoundedRectangle(cornerRadius: MGTheme.cardRadius)
                    .fill(Color.white.opacity(0.35))
                    .overlay {
                        Canvas { context, size in
                            let step: CGFloat = 28
                            var path = Path()
                            stride(from: 0, through: size.width, by: step).forEach { x in
                                path.move(to: CGPoint(x: x, y: 0))
                                path.addLine(to: CGPoint(x: x, y: size.height))
                            }
                            stride(from: 0, through: size.height, by: step).forEach { y in
                                path.move(to: CGPoint(x: 0, y: y))
                                path.addLine(to: CGPoint(x: size.width, y: y))
                            }
                            context.stroke(path, with: .color(Color.gray.opacity(0.16)), lineWidth: 1)
                        }
                    }
                ForEach(displayed) { note in
                    let x = CGFloat(note.startSeconds / endTime) * (geometry.size.width - 32) + 16
                    let width = max(
                        8,
                        CGFloat((note.endSeconds - note.startSeconds) / endTime)
                            * (geometry.size.width - 32)
                    )
                    let normalizedPitch = CGFloat(note.pitchMIDI - minPitch) / CGFloat(maxPitch - minPitch)
                    let y = geometry.size.height - 24 - normalizedPitch * (geometry.size.height - 48)

                    Button {
                        selectedNoteID = note.id
                    } label: {
                        Circle()
                            .fill(note.id == selectedNoteID ? MGTheme.accent : MGTheme.lavender.opacity(0.75))
                            .overlay { Circle().stroke(.white, lineWidth: 4) }
                            .shadow(color: MGTheme.accent.opacity(0.3), radius: 7)
                            .frame(width: note.id == selectedNoteID ? 23 : 18, height: note.id == selectedNoteID ? 23 : 18)
                    }
                    .buttonStyle(.plain)
                    .position(x: x + min(width / 2, 10), y: y)
                    .accessibilityLabel("音符 \(note.noteName)")
                    .accessibilityHint("选择后可调整音高和音量")
                }
            }
        }
        .frame(height: 230)
        .accessibilityElement(children: .contain)
    }
}
