import SwiftUI

enum MGTheme {
    static let ink = Color(red: 0.10, green: 0.11, blue: 0.13)
    static let graphite = Color(red: 0.25, green: 0.27, blue: 0.30)
    static let accent = Color(red: 0.48, green: 0.40, blue: 0.75)
    static let lavender = Color(red: 0.83, green: 0.79, blue: 0.96)
    static let blush = Color(red: 0.96, green: 0.87, blue: 0.88)
    static let cream = Color(red: 1.00, green: 0.96, blue: 0.88)
    static let ice = Color(red: 0.89, green: 0.94, blue: 1.00)
    static let success = Color(red: 0.25, green: 0.88, blue: 0.42)
    static let surface = Color.white.opacity(0.58)

    static let cardRadius: CGFloat = 18
    static let minimumTapTarget: CGFloat = 44
}

struct MGScreenBackground: View {
    var body: some View {
        ZStack {
            Color(red: 0.985, green: 0.975, blue: 0.955)
            RadialGradient(
                colors: [MGTheme.cream.opacity(0.72), .clear],
                center: .topTrailing,
                startRadius: 15,
                endRadius: 330
            )
            RadialGradient(
                colors: [MGTheme.ice.opacity(0.72), .clear],
                center: .bottomLeading,
                startRadius: 10,
                endRadius: 340
            )
            RadialGradient(
                colors: [MGTheme.blush.opacity(0.42), .clear],
                center: UnitPoint(x: 0.68, y: 0.57),
                startRadius: 20,
                endRadius: 300
            )
        }
        .ignoresSafeArea()
    }
}

struct MGCard<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: MGTheme.cardRadius))
            .overlay {
                RoundedRectangle(cornerRadius: MGTheme.cardRadius)
                    .stroke(Color.white.opacity(0.92), lineWidth: 1.4)
            }
            .shadow(color: Color.black.opacity(0.08), radius: 14, y: 8)
    }
}

struct MGPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.title3.weight(.semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, minHeight: 58)
            .background(
                LinearGradient(
                    colors: [Color(red: 0.08, green: 0.10, blue: 0.12), Color(red: 0.26, green: 0.26, blue: 0.27)],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                in: Capsule()
            )
            .opacity(configuration.isPressed ? 0.76 : 1)
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
    }
}

struct MGSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.title3.weight(.semibold))
            .foregroundStyle(MGTheme.ink)
            .frame(maxWidth: .infinity, minHeight: 58)
            .background(.ultraThinMaterial, in: Capsule())
            .overlay { Capsule().stroke(Color.white, lineWidth: 1.5) }
            .shadow(color: Color.black.opacity(0.07), radius: 10, y: 5)
            .opacity(configuration.isPressed ? 0.72 : 1)
    }
}

struct MGOrb: View {
    var size: CGFloat = 190
    var isActive = false

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    AngularGradient(
                        colors: [MGTheme.cream, MGTheme.lavender, MGTheme.ice, MGTheme.blush, MGTheme.cream],
                        center: .center
                    )
                )
                .overlay { Circle().stroke(Color.white.opacity(0.9), lineWidth: 2) }
                .shadow(color: MGTheme.accent.opacity(0.27), radius: 24)

            ForEach([0.78, 0.58, 0.38], id: \.self) { scale in
                Circle()
                    .fill(Color.white.opacity(scale == 0.38 ? 0.82 : 0.10))
                    .overlay { Circle().stroke(Color.white.opacity(0.72), lineWidth: 1.4) }
                    .scaleEffect(scale)
            }

            if isActive {
                RoundedRectangle(cornerRadius: 5)
                    .fill(.white)
                    .frame(width: 30, height: 30)
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

struct MGWaveform: View {
    var color: Color = MGTheme.graphite
    var barCount = 31

    var body: some View {
        GeometryReader { geometry in
            HStack(alignment: .center, spacing: max(2, geometry.size.width / CGFloat(barCount * 4))) {
                ForEach(0..<barCount, id: \.self) { index in
                    Capsule()
                        .fill(color.opacity(0.92))
                        .frame(
                            width: max(2, geometry.size.width / (CGFloat(barCount) * 2.25)),
                            height: height(for: index, available: geometry.size.height)
                        )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .accessibilityLabel("Audio waveform")
    }

    private func height(for index: Int, available: CGFloat) -> CGFloat {
        let pattern: [CGFloat] = [0.28, 0.48, 0.72, 0.42, 0.61, 0.36, 0.78, 0.52, 0.66, 0.34, 0.57]
        return max(6, available * pattern[index % pattern.count])
    }
}

struct MGGloveArtwork: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [MGTheme.lavender.opacity(0.72), MGTheme.blush.opacity(0.16), .clear],
                        center: .center,
                        startRadius: 5,
                        endRadius: 130
                    )
                )
            Image(systemName: "hand.raised.fill")
                .font(.system(size: 110, weight: .thin))
                .symbolRenderingMode(.palette)
                .foregroundStyle(Color.white, Color.gray.opacity(0.62))
                .shadow(color: .black.opacity(0.18), radius: 9, y: 7)
                .rotationEffect(.degrees(-13))
            Circle()
                .fill(Color(red: 0.56, green: 0.94, blue: 0.21))
                .frame(width: 18, height: 18)
                .offset(x: 18, y: 34)
        }
        .frame(height: 230)
        .accessibilityLabel("Music Glove illustration")
    }
}

struct MGInstrumentArtwork: View {
    let instrument: InstrumentType
    var size: CGFloat = 150

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 22)
                .fill(
                    LinearGradient(
                        colors: [MGTheme.blush.opacity(0.45), MGTheme.cream.opacity(0.7), MGTheme.ice.opacity(0.5)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            Image(systemName: instrument.symbol)
                .font(.system(size: size * 0.42, weight: .regular))
                .foregroundStyle(MGTheme.graphite)
        }
        .frame(width: size, height: size)
        .overlay { RoundedRectangle(cornerRadius: 22).stroke(.white, lineWidth: 1.5) }
        .accessibilityLabel(instrument.title)
    }
}

struct StatusLabel: View {
    let symbol: String
    let title: String
    let color: Color

    var body: some View {
        Label(title, systemImage: symbol)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(color)
            .accessibilityElement(children: .combine)
    }
}
