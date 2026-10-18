import SwiftUI
import UniformTypeIdentifiers

struct EditorHomeView: View {
    @EnvironmentObject private var model: AppModel
    @State private var isPlaying = false

    var body: some View {
        ZStack {
            MGScreenBackground()

            VStack(spacing: 18) {
                HStack {
                    Text("Edit")
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                    Spacer()
                    Menu {
                        NavigationLink("Mixer") { MixerView(tracks: model.projectTracks) }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.title2.weight(.semibold))
                            .frame(width: 44, height: 44)
                    }
                    .accessibilityLabel("Project options")
                }

                Text("00:00 / 05:27")
                    .font(.title3)
                    .foregroundStyle(.secondary)

                timeline

                HStack(spacing: 34) {
                    NavigationLink {
                        MixerView(tracks: model.projectTracks)
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                    }
                    .accessibilityLabel("Mixer")

                    Button { } label: {
                        Image(systemName: "backward.end.fill")
                    }
                    .accessibilityLabel("Previous")

                    Button { isPlaying.toggle() } label: {
                        Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                            .font(.title)
                            .foregroundStyle(.white)
                            .frame(width: 66, height: 66)
                            .background(MGTheme.graphite, in: Circle())
                    }
                    .accessibilityLabel(isPlaying ? "Pause" : "Play")

                    Button { } label: {
                        Image(systemName: "forward.end.fill")
                    }
                    .accessibilityLabel("Next")
                }
                .font(.title2)
                .foregroundStyle(MGTheme.graphite)

                if model.projectTracks.isEmpty {
                    Text("Complete a real analysis to add an editable instrument track and the preserved Vocal.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 12)
            .padding(.bottom, 28)
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    private var visibleTracks: [ProjectTrack] {
        model.projectTracks
    }

    private var timeline: some View {
        GeometryReader { geometry in
            let labelWidth = min(132, geometry.size.width * 0.36)
            let clipWidth = max(120, geometry.size.width - labelWidth - 6)

            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.white.opacity(0.34))
                    .overlay { RoundedRectangle(cornerRadius: 18).stroke(Color.white, lineWidth: 1) }

                HStack(spacing: 0) {
                    VStack(spacing: 0) {
                        Text("Tracks")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(height: 32)
                        if visibleTracks.isEmpty {
                            emptyTrackLabel
                        } else {
                            ForEach(visibleTracks) { track in
                                NavigationLink {
                                    TrackDetailView(track: track)
                                } label: {
                                    trackLabel(track)
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        Button {
                            model.selectedTab = .create
                        } label: {
                            Label("Add Track", systemImage: "plus")
                                .font(.headline)
                                .frame(maxWidth: .infinity, minHeight: 62)
                        }
                        .buttonStyle(.plain)
                    }
                    .frame(width: labelWidth)

                    ZStack(alignment: .topLeading) {
                        TimelineGrid()

                        VStack(spacing: 0) {
                            HStack {
                                Text("0")
                                Spacer()
                                Text("5")
                                Spacer()
                                Text("10")
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 8)
                            .frame(height: 32)

                            if visibleTracks.isEmpty {
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.secondary.opacity(0.25), style: StrokeStyle(lineWidth: 1.5, dash: [6]))
                                    .frame(height: 86)
                                    .padding(.horizontal, 8)
                            } else {
                                ForEach(Array(visibleTracks.enumerated()), id: \.element.id) { index, track in
                                    TimelineClip(track: track, color: trackColor(index))
                                        .frame(width: clipWidth * clipFraction(for: track), height: 72)
                                        .padding(.horizontal, 8)
                                        .frame(maxWidth: .infinity, minHeight: 86, alignment: index.isMultiple(of: 2) ? .leading : .trailing)
                                }
                            }
                        }

                        Rectangle()
                            .fill(MGTheme.graphite)
                            .frame(width: 2)
                            .overlay(alignment: .top) {
                                Circle().fill(MGTheme.graphite).frame(width: 16, height: 16).offset(y: -6)
                            }
                            .padding(.top, 32)
                            .offset(x: clipWidth * 0.18)
                    }
                    .frame(width: clipWidth)
                }
            }
        }
        .frame(minHeight: 300, maxHeight: 470)
    }

    private var emptyTrackLabel: some View {
        VStack(spacing: 7) {
            Image(systemName: "waveform")
                .font(.title2)
            Text("No Tracks")
                .font(.headline)
        }
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity, minHeight: 86)
    }

    private func trackLabel(_ track: ProjectTrack) -> some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 10)
                .fill(MGTheme.cream.opacity(0.75))
                .frame(width: 46, height: 46)
                .overlay {
                    Image(systemName: trackSymbol(track))
                        .font(.title3)
                        .foregroundStyle(MGTheme.graphite)
                }
            Text(track.name)
                .font(.headline)
                .lineLimit(1)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 8)
        .frame(maxWidth: .infinity, minHeight: 86)
    }

    private func trackSymbol(_ track: ProjectTrack) -> String {
        switch track.kind {
        case .vocal: "mic.fill"
        case let .instrument(instrument): instrument.symbol
        }
    }

    private func trackColor(_ index: Int) -> Color {
        [Color.green, Color.cyan, MGTheme.lavender, Color.orange, MGTheme.cream][index % 5]
    }

    private func clipFraction(for track: ProjectTrack) -> CGFloat {
        switch track.kind {
        case .vocal: 0.96
        case .instrument: 0.74
        }
    }
}

private struct TimelineGrid: View {
    var body: some View {
        Canvas { context, size in
            var path = Path()
            stride(from: 0, through: size.width, by: 28).forEach { x in
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: size.height))
            }
            context.stroke(path, with: .color(Color.gray.opacity(0.16)), lineWidth: 1)
        }
    }
}

private struct TimelineClip: View {
    let track: ProjectTrack
    let color: Color

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(color.opacity(0.22))
            RoundedRectangle(cornerRadius: 10)
                .stroke(color.opacity(0.45), lineWidth: 1.4)
            MGWaveform(color: color.opacity(0.55), barCount: 19)
                .padding(10)
        }
        .accessibilityLabel("\(track.name) timeline clip")
    }
}

private struct TrackDetailView: View {
    @EnvironmentObject private var model: AppModel
    let track: ProjectTrack
    @State private var volume = 0.58
    @State private var pan = 0.50
    @State private var reverb = 0.75
    @State private var selectedSection = "Instrument"
    @State private var isPreparingExport = false
    @State private var exportDocument: MIDIFileDocument?
    @State private var showsExporter = false
    @State private var exportError: String?

    var body: some View {
        ZStack {
            MGScreenBackground()
            ScrollView {
                VStack(spacing: 22) {
                    Text(track.name + " Track")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                    Text("00:00 / 05:27")
                        .font(.title3)
                        .foregroundStyle(.secondary)

                    NavigationLink {
                        MelodyEditorView(track: track)
                    } label: {
                        TimelineClip(track: track, color: .green)
                            .frame(height: 150)
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint("Open melody editor")

                    Picker("Track section", selection: $selectedSection) {
                        Text("Instrument").tag("Instrument")
                        Text("Region").tag("Region")
                    }
                    .pickerStyle(.segmented)

                    NavigationLink {
                        InstrumentPickerView(selected: instrument)
                    } label: {
                        MGCard {
                            HStack {
                                MGInstrumentArtwork(instrument: instrument, size: 82)
                                VStack(alignment: .leading) {
                                    Text(instrument.title).font(.title3.bold())
                                    Text("Grand Piano").foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                            }
                        }
                    }
                    .buttonStyle(.plain)

                    control("Volume", value: $volume, display: "-3.0 dB")
                    control("Pan", value: $pan, display: "0")
                    control("Reverb", value: $reverb, display: "75%")

                    if track.midiURL != nil {
                        Button {
                            prepareMIDIExport()
                        } label: {
                            HStack {
                                if isPreparingExport { ProgressView().tint(.white) }
                                Label("Export MIDI", systemImage: "square.and.arrow.up")
                            }
                        }
                        .buttonStyle(MGPrimaryButtonStyle())
                        .disabled(isPreparingExport)
                    }

                    if let exportError {
                        Label(exportError, systemImage: "exclamationmark.triangle.fill")
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                }
                .padding(20)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .fileExporter(
            isPresented: $showsExporter,
            document: exportDocument,
            contentType: .midi,
            defaultFilename: "Music-Glove-\(track.name).mid"
        ) { result in
            if case let .failure(error) = result { exportError = error.localizedDescription }
            exportDocument = nil
        }
    }

    private var instrument: InstrumentType {
        switch track.kind {
        case .vocal: .piano
        case let .instrument(value): value
        }
    }

    private func control(_ name: String, value: Binding<Double>, display: String) -> some View {
        VStack(spacing: 6) {
            HStack {
                Text(name).font(.headline)
                Spacer()
                Text(display).foregroundStyle(.secondary)
            }
            Slider(value: value)
                .tint(MGTheme.graphite)
                .accessibilityLabel(name)
                .accessibilityValue(display)
        }
    }

    private func prepareMIDIExport() {
        isPreparingExport = true
        exportError = nil
        Task {
            do {
                let data = try await model.downloadMIDI(for: track)
                exportDocument = MIDIFileDocument(data: data)
                showsExporter = true
            } catch {
                exportError = error.localizedDescription
            }
            isPreparingExport = false
        }
    }
}

private struct MelodyEditorView: View {
    let track: ProjectTrack
    @State private var mode = "Piano Roll"

    var body: some View {
        ZStack {
            MGScreenBackground()
            VStack(spacing: 18) {
                Picker("Editor mode", selection: $mode) {
                    Text("Piano Roll").tag("Piano Roll")
                    Text("Score").tag("Score")
                }
                .pickerStyle(.segmented)

                ZStack(alignment: .leading) {
                    TimelineGrid()
                    VStack(spacing: 28) {
                        ForEach(Array(track.notes.prefix(6).enumerated()), id: \.element.id) { index, note in
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [MGTheme.lavender.opacity(0.72), MGTheme.cream.opacity(0.82)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .overlay { Capsule().stroke(MGTheme.accent.opacity(0.28)) }
                                .frame(width: 92 + CGFloat(index % 3) * 18, height: 24)
                                .offset(x: CGFloat((index * 39) % 180))
                                .accessibilityLabel("Note \(note.noteName)")
                        }
                    }
                    .padding(.leading, 70)
                }
                .frame(height: 350)

                HStack {
                    editorTool("pencil", "Draw")
                    editorTool("eraser.fill", "Erase")
                    editorTool("square.dashed", "Select")
                    editorTool("arrow.uturn.backward.circle", "Undo")
                    editorTool("arrow.uturn.forward.circle", "Redo")
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Velocity").font(.headline)
                    MGWaveform(barCount: 22).frame(height: 120)
                }
            }
            .padding(20)
        }
        .navigationTitle(track.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func editorTool(_ symbol: String, _ label: String) -> some View {
        Button { } label: {
            Image(systemName: symbol)
                .font(.title2)
                .frame(maxWidth: .infinity, minHeight: 44)
        }
        .accessibilityLabel(label)
    }
}

private struct InstrumentPickerView: View {
    let selected: InstrumentType
    @State private var category = "Piano"

    private let variants = ["Classic Grand Piano", "Vintage Upright Piano", "Studio Piano", "Digital Piano"]

    var body: some View {
        ZStack {
            MGScreenBackground()
            ScrollView {
                VStack(spacing: 20) {
                    MGInstrumentArtwork(instrument: selected, size: 250)
                    Text(selected.title).font(.title.bold())
                    Text("Grand Piano").foregroundStyle(.secondary)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(["Piano", "Keyboard", "Strings", "Wind"], id: \.self) { item in
                                Button(item) { category = item }
                                    .padding(.horizontal, 20)
                                    .frame(minHeight: 44)
                                    .background(category == item ? MGTheme.cream.opacity(0.8) : Color.white.opacity(0.4), in: RoundedRectangle(cornerRadius: 12))
                                    .overlay { RoundedRectangle(cornerRadius: 12).stroke(.white) }
                            }
                        }
                    }

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        ForEach(variants, id: \.self) { name in
                            VStack(spacing: 10) {
                                MGInstrumentArtwork(instrument: selected, size: 140)
                                Text(name)
                                    .font(.subheadline.weight(.medium))
                                    .multilineTextAlignment(.center)
                                    .frame(minHeight: 44)
                            }
                            .padding(8)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                        }
                    }
                }
                .padding(20)
            }
        }
        .navigationTitle("Instrument")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct MixerView: View {
    let tracks: [ProjectTrack]
    @State private var effects = true

    var body: some View {
        ZStack {
            MGScreenBackground()
            ScrollView(.horizontal) {
                HStack(alignment: .top, spacing: 20) {
                    ForEach(displayTracks) { track in
                        MixerChannel(track: track)
                    }
                }
                .padding(22)
            }
        }
        .navigationTitle("Mixer")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            Toggle("Track Effects", isOn: $effects)
                .padding()
                .background(.ultraThinMaterial)
        }
    }

    private var displayTracks: [ProjectTrack] { tracks }
}

private struct MixerChannel: View {
    let track: ProjectTrack
    @State private var level = 0.55

    var body: some View {
        VStack(spacing: 16) {
            Text(track.name).font(.headline)
            Circle()
                .fill(
                    LinearGradient(colors: [Color.white, Color.gray], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .frame(width: 62, height: 62)
                .overlay(alignment: .top) { Capsule().fill(.white).frame(width: 3, height: 28).padding(.top, 5) }
            Slider(value: $level)
                .rotationEffect(.degrees(-90))
                .frame(width: 220, height: 44)
                .padding(.vertical, 82)
                .accessibilityLabel("\(track.name) level")
            Text(String(format: "%.1f", (level - 1) * 12))
                .monospacedDigit()
        }
        .frame(width: 86)
    }
}

private struct MIDIFileDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.midi] }
    let data: Data

    init(data: Data) { self.data = data }

    init(configuration: ReadConfiguration) throws {
        data = configuration.file.regularFileContents ?? Data()
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}
