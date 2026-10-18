import SwiftUI
import UIKit

struct RootView: View {
    @EnvironmentObject private var model: AppModel
    @State private var entryStage: EntryStage = .welcome

    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.white.withAlphaComponent(0.94)
        appearance.shadowColor = UIColor.clear
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
        UITabBar.appearance().unselectedItemTintColor = UIColor.systemGray2
    }

    var body: some View {
        Group {
            if entryStage == .app {
                mainTabs
            } else {
                EntryFlowView(stage: $entryStage)
            }
        }
    }

    private var mainTabs: some View {
        TabView(selection: $model.selectedTab) {
            NavigationStack {
                CreateHomeView()
            }
            .id(model.recording.id)
            .tabItem {
                Label("Create", systemImage: "waveform.badge.plus")
            }
            .tag(AppTab.create)

            NavigationStack {
                EditorHomeView()
            }
            .tabItem {
                Label("Edit", systemImage: "slider.horizontal.3")
            }
            .tag(AppTab.edit)

            NavigationStack {
                ProfileHomeView()
            }
            .tabItem {
                Label("Me", systemImage: "person.crop.circle")
            }
            .tag(AppTab.me)
        }
        .tint(.black)
    }
}

private enum EntryStage: Equatable {
    case welcome
    case login
    case signUp
    case onboarding(Int)
    case searchGlove
    case selectGlove
    case paired
    case app
}

private struct EntryFlowView: View {
    @EnvironmentObject private var model: AppModel
    @Binding var stage: EntryStage
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""

    var body: some View {
        ZStack {
            MGScreenBackground()

            switch stage {
            case .welcome:
                welcome
            case .login:
                authForm(isSignUp: false)
            case .signUp:
                authForm(isSignUp: true)
            case let .onboarding(page):
                onboarding(page)
            case .searchGlove:
                searchGlove
            case .selectGlove:
                selectGlove
            case .paired:
                paired
            case .app:
                EmptyView()
            }
        }
        .animation(.easeInOut(duration: 0.24), value: stage)
    }

    private var welcome: some View {
        VStack(spacing: 24) {
            Spacer()
            Image("WelcomeWaveform")
                .resizable()
                .scaledToFit()
                .frame(width: 190, height: 170)
                .accessibilityLabel("Audio waveform")

            VStack(spacing: 8) {
                Text("Welcome to")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                Text("Music Glove")
                    .font(.system(size: 50, weight: .black, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.black, Color(red: 0.24, green: 0.03, blue: 0.34), Color.black],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                Text("Capture your ideas.\nCreate your music. Anywhere.")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            Button("Log In") { stage = .login }
                .buttonStyle(MGPrimaryButtonStyle())
            Button("Sign Up") { stage = .signUp }
                .buttonStyle(MGSecondaryButtonStyle())
        }
        .padding(24)
        .padding(.bottom, 28)
    }

    private func authForm(isSignUp: Bool) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Button { stage = .welcome } label: {
                    Image(systemName: "chevron.left")
                        .font(.title2.weight(.semibold))
                        .frame(width: 44, height: 44)
                }
                .accessibilityLabel("Back")

                Spacer(minLength: 48)

                Text(isSignUp ? "Create Account" : "Music Glove")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                Text(isSignUp ? "Join Music Glove and start creating music." : "Turn your inspiration into music.")
                    .font(.title3)

                authField("Email", placeholder: "you@example.com", text: $email, secure: false)
                authField("Password", placeholder: "••••••••", text: $password, secure: true)
                if isSignUp {
                    authField("Confirm Password", placeholder: "••••••••", text: $confirmPassword, secure: true)
                }

                Button(isSignUp ? "Sign up" : "Log In") {
                    stage = .onboarding(0)
                }
                .buttonStyle(MGPrimaryButtonStyle())

                Text("Front-end preview only — no account is created and no credentials are transmitted.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)

                HStack {
                    Text(isSignUp ? "Already have an account?" : "Don’t have an account?")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button(isSignUp ? "Log In" : "Sign Up") {
                        stage = isSignUp ? .login : .signUp
                    }
                    .fontWeight(.semibold)
                }
                .padding(.top, 40)
            }
            .padding(24)
        }
    }

    private func authField(
        _ label: String,
        placeholder: String,
        text: Binding<String>,
        secure: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label).font(.headline)
            Group {
                if secure {
                    SecureField(placeholder, text: text)
                } else {
                    TextField(placeholder, text: text)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                }
            }
            .padding(.horizontal, 16)
            .frame(minHeight: 58)
            .background(Color.white.opacity(0.28), in: RoundedRectangle(cornerRadius: 12))
            .overlay { RoundedRectangle(cornerRadius: 12).stroke(MGTheme.graphite, lineWidth: 1.2) }
        }
    }

    private func onboarding(_ page: Int) -> some View {
        VStack(spacing: 22) {
            Spacer(minLength: 34)

            Group {
                if page == 2 {
                    VStack(spacing: 0) {
                        Text("From Inspiration")
                        Text("to a Complete Song")
                    }
                } else {
                    Text(onboardingTitle(page))
                }
            }
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, alignment: .center)
                .fixedSize(horizontal: false, vertical: true)
                .layoutPriority(1)

            if page == 0 {
                Text("Turn your inspiration into music\nwith voice and gesture.")
                    .font(.title3)
                    .multilineTextAlignment(.center)
                Image("OnboardingGlove")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 336)
                    .frame(height: 238)
                    .accessibilityLabel("Music Glove illustration")
            } else if page == 1 {
                onboardingFeature("OnboardingVoiceCircle", "Sing a melody\nwith your voice")
                onboardingFeature("OnboardingGestureCircle", "Make instrument gestures\nwith your glove")
            } else {
                VStack(alignment: .leading, spacing: 16) {
                    onboardingStep(1, "Record", "Sing and gesture", "OnboardingStepRecord")
                    onboardingStep(2, "AI Analysis", "Detect melody & instrument", "OnboardingStepAnalysis")
                    onboardingStep(3, "Edit", "Refine and arrange", "OnboardingStepEdit")
                    onboardingStep(4, "Build", "Add more tracks", "OnboardingStepBuild")
                    onboardingStep(5, "Save & Share", "Keep your music", "OnboardingStepShare")
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 10)
            }

            Spacer()

            HStack(spacing: 10) {
                ForEach(0..<3) { index in
                    Capsule()
                        .fill(index == page ? MGTheme.graphite : Color.gray.opacity(0.2))
                        .frame(width: index == page ? 28 : 10, height: 10)
                }
            }

            Button(page == 2 ? "Get Started" : "Next") {
                stage = page == 2 ? .searchGlove : .onboarding(page + 1)
            }
            .buttonStyle(MGPrimaryButtonStyle())

            if page < 2 {
                Button("Skip") { stage = .searchGlove }
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .frame(minHeight: 44)
            }
        }
        .padding(24)
        .padding(.bottom, 20)
    }

    private func onboardingTitle(_ page: Int) -> String {
        switch page {
        case 0: "Welcome to\nMusic Glove"
        default: "Create Music\nin a Natural Way"
        }
    }

    private func onboardingFeature(_ imageName: String, _ title: String) -> some View {
        HStack(spacing: 28) {
            Image(imageName)
                .resizable()
                .scaledToFit()
                .frame(width: 116, height: 116)
                .accessibilityHidden(true)
            Text(title).font(.title2)
            Spacer()
        }
        .accessibilityElement(children: .combine)
    }

    private func onboardingStep(_ index: Int, _ title: String, _ subtitle: String, _ imageName: String) -> some View {
        HStack(spacing: 18) {
            Image(imageName)
                .resizable()
                .scaledToFit()
                .frame(width: 72, height: 72)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                Text("\(index). \(title)").font(.title3.weight(.semibold))
                Text(subtitle).foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var searchGlove: some View {
        VStack(spacing: 18) {
            Spacer()
            Text("Searching for\nMusic Gloves…")
                .font(.system(size: 38, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, alignment: .center)
                .fixedSize(horizontal: false, vertical: true)
                .layoutPriority(1)
            Text("Make sure your glove is turned on\nand near your device.")
                .font(.title3)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, alignment: .center)
                .fixedSize(horizontal: false, vertical: true)
                .layoutPriority(1)
            Image("OnboardingGlove")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 336)
                .frame(height: 238)
                .accessibilityLabel("Music Glove illustration")
            Spacer()
            VStack(alignment: .leading, spacing: 10) {
                Text("Development device discovery")
                    .font(.title3)
                    .frame(maxWidth: .infinity, alignment: .leading)
                MGCard {
                    VStack(spacing: 12) {
                        ProgressView()
                            .scaleEffect(1.25)
                        Button("Show simulated devices") { stage = .selectGlove }
                            .frame(maxWidth: .infinity, minHeight: 44, alignment: .center)
                    }
                    .frame(maxWidth: .infinity, minHeight: 116, alignment: .center)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Text("Real scanning starts after the BLE packet protocol is supplied.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, alignment: .center)
                .fixedSize(horizontal: false, vertical: true)
                .layoutPriority(1)
        }
        .padding(24)
    }

    private var selectGlove: some View {
        VStack(alignment: .leading, spacing: 26) {
            Spacer()
                .frame(height: 56)
            Text("Select Your Glove")
                .font(.system(size: 38, weight: .bold, design: .rounded))

            ForEach(1...3, id: \.self) { index in
                Button {
                    Task {
                        await model.connectDevelopmentGlove()
                        stage = .paired
                    }
                } label: {
                    Image("SelectGlove0\(index)Card")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Music Glove 0\(index), RSSIABCDE-011\(index)")
                .accessibilityHint("Uses the development simulated glove gateway")
            }

            Spacer(minLength: 16)

            VStack(spacing: 2) {
                Button("Rescan") { stage = .searchGlove }
                    .font(.title3)
                    .frame(maxWidth: .infinity, minHeight: 44)
                Text("can't find your device?")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(24)
    }

    private var paired: some View {
        VStack(spacing: 24) {
            Spacer()
            Image("OnboardingGlove")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 336)
                .frame(height: 238)
                .accessibilityLabel("Music Glove illustration")
            Text("Glove Connected")
                .font(.system(size: 38, weight: .bold, design: .rounded))
            VStack(alignment: .leading, spacing: 10) {
                Text("Device Name")
                    .font(.headline)
                Text("Music Glove 01")

                HStack(spacing: 10) {
                    Image(systemName: "circle.fill")
                        .font(.caption)
                        .foregroundStyle(MGTheme.success)
                    Text("Connected")
                }
                .accessibilityElement(children: .combine)

                Label("Battery 82%", systemImage: "battery.75percent")
            }
            .font(.title3)
            .accessibilityHint("Development preview device status")
            Spacer()
            Button("Start Creating") { stage = .app }
                .buttonStyle(MGPrimaryButtonStyle())
            Button("Device Settings") { stage = .app }
                .buttonStyle(MGSecondaryButtonStyle())
        }
        .padding(24)
        .padding(.bottom, 22)
    }
}
