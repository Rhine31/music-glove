import SwiftUI

struct ProfileHomeView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        ZStack {
            MGScreenBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("My Profile")
                        .font(.system(size: 40, weight: .bold, design: .rounded))

                    HStack(spacing: 18) {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [MGTheme.ice, MGTheme.lavender.opacity(0.75)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 92, height: 92)
                            .overlay {
                                Image(systemName: "person")
                                    .font(.system(size: 46, weight: .light))
                                    .foregroundStyle(.white)
                            }
                            .overlay { Circle().stroke(.white, lineWidth: 2) }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Music Creator")
                                .font(.title2.weight(.semibold))
                            Text("Local development profile")
                                .foregroundStyle(.secondary)
                        }
                    }

                    HStack {
                        metric("1", "Projects")
                        metric("\(model.projectTracks.count)", "Tracks")
                        metric("—", "Plays")
                    }

                    MGCard {
                        VStack(spacing: 0) {
                            NavigationLink {
                                ProjectsView()
                            } label: {
                                menuRow("doc.text", "My Projects", "View and manage your music")
                            }

                            Divider().padding(.leading, 58)

                            NavigationLink {
                                GloveSettingsView()
                            } label: {
                                menuRow("hand.raised", "My Music Glove", "Device status, gesture guide and more")
                            }

                            Divider().padding(.leading, 58)

                            NavigationLink {
                                CommunityView()
                            } label: {
                                menuRow("person.3", "Community", "Share your music and discover others")
                            }

                            Divider().padding(.leading, 58)

                            NavigationLink {
                                AccountPrivacyView()
                            } label: {
                                menuRow("gearshape", "Account & Privacy", "Manage your account, security and data")
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 38)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    private func metric(_ value: String, _ label: String) -> some View {
        VStack(spacing: 5) {
            Text(value).font(.title.bold())
            Text(label).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }

    private func menuRow(_ symbol: String, _ title: String, _ subtitle: String) -> some View {
        HStack(spacing: 15) {
            Image(systemName: symbol)
                .font(.title2)
                .foregroundStyle(MGTheme.graphite)
                .frame(width: 42)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.title3.weight(.semibold))
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundStyle(.black)
        }
        .foregroundStyle(.primary)
        .padding(.vertical, 14)
        .contentShape(Rectangle())
    }
}

private struct ProjectsView: View {
    @EnvironmentObject private var model: AppModel
    @State private var filter = "Recent"

    var body: some View {
        ZStack {
            MGScreenBackground()

            VStack(spacing: 20) {
                Picker("Project filter", selection: $filter) {
                    Text("Recent").tag("Recent")
                    Text("Favourite").tag("Favourite")
                    Text("All").tag("All")
                }
                .pickerStyle(.segmented)

                if model.projectTracks.isEmpty {
                    ContentUnavailableView {
                        Label("No projects yet", systemImage: "music.note.house")
                    } description: {
                        Text("Create and analyze a melody to build your first local project.")
                    }
                    Spacer()
                } else {
                    NavigationLink {
                        ProjectDetailView()
                    } label: {
                        MGCard {
                            HStack(spacing: 14) {
                                projectCover
                                    .frame(width: 92, height: 92)
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Current Creation").font(.title2.bold())
                                    Text("\(model.projectTracks.count) tracks · local draft")
                                    Text("Today").foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    Spacer()
                }
            }
            .padding(20)
        }
        .navigationTitle("Projects")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var projectCover: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(
                LinearGradient(colors: [MGTheme.ice, MGTheme.cream], startPoint: .topLeading, endPoint: .bottomTrailing)
            )
            .overlay { Image(systemName: "sun.max.fill").font(.largeTitle).foregroundStyle(.orange) }
    }
}

private struct ProjectDetailView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        ZStack {
            MGScreenBackground()
            ScrollView {
                VStack(spacing: 20) {
                    Text("Current Creation")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                    RoundedRectangle(cornerRadius: 24)
                        .fill(
                            LinearGradient(colors: [MGTheme.ice, MGTheme.cream], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .frame(height: 260)
                        .overlay {
                            Image(systemName: "music.note.house.fill")
                                .font(.system(size: 72))
                                .foregroundStyle(MGTheme.graphite)
                        }
                        .overlay(alignment: .bottom) {
                            Image(systemName: "play.fill")
                                .font(.title)
                                .foregroundStyle(.white)
                                .frame(width: 72, height: 72)
                                .background(MGTheme.graphite, in: Circle())
                                .offset(y: 32)
                        }

                    Text("\(model.projectTracks.count) tracks · editable local draft")
                        .font(.title3)
                        .padding(.top, 24)

                    MGWaveform()
                        .frame(height: 100)

                    NavigationLink {
                        ShareMusicView()
                    } label: {
                        Label("Share Your Music", systemImage: "square.and.arrow.up")
                    }
                    .buttonStyle(MGPrimaryButtonStyle())

                    MGCard {
                        LabeledContent("Created", value: "Today")
                        Divider()
                        LabeledContent("Last edited", value: "Today")
                        Divider()
                        LabeledContent("Storage", value: "Local memory")
                    }
                }
                .padding(20)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct ShareMusicView: View {
    @State private var title = "Current Creation"
    @State private var description = "Created with Music Glove."

    var body: some View {
        ZStack {
            MGScreenBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Choose a project and share it with the community.")
                        .font(.title3)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)

                    HStack(spacing: 14) {
                        RoundedRectangle(cornerRadius: 18)
                            .fill(LinearGradient(colors: [MGTheme.ice, MGTheme.cream], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 130, height: 130)
                            .overlay { Image(systemName: "music.note.house.fill").font(.largeTitle) }
                        VStack(spacing: 12) {
                            TextField("Project", text: .constant("Current Creation"))
                                .disabled(true)
                            TextField("Title", text: $title)
                        }
                        .textFieldStyle(.roundedBorder)
                    }

                    Text("Description").font(.headline)
                    TextEditor(text: $description)
                        .frame(height: 110)
                        .padding(8)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))

                    HStack(spacing: 12) {
                        tag("#Piano")
                        tag("#Chill")
                        tag("+")
                    }

                    LabeledContent("Visibility") {
                        Label("Global", systemImage: "globe")
                    }
                    .font(.title3)

                    Button("Publish") { }
                        .buttonStyle(MGPrimaryButtonStyle())
                        .disabled(true)

                    Text("Publishing is disabled until account, cloud and community services are approved and implemented.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(20)
            }
        }
        .navigationTitle("Share Your Music")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func tag(_ value: String) -> some View {
        Text(value)
            .padding(.horizontal, 16)
            .frame(minHeight: 44)
            .background(.ultraThinMaterial, in: Capsule())
            .overlay { Capsule().stroke(.white) }
    }
}

private struct GloveSettingsView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        ZStack {
            MGScreenBackground()
            ScrollView {
                VStack(spacing: 18) {
                    Image("OnboardingGlove")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 336)
                        .frame(height: 238)
                        .accessibilityLabel("Music Glove illustration")

                    HStack {
                        Label(
                            model.gloveState == .simulated ? "Development demo" : "Not connected",
                            systemImage: "circle.fill"
                        )
                        .foregroundStyle(model.gloveState == .simulated ? MGTheme.success : .secondary)
                        Spacer()
                        Label("Battery —", systemImage: "battery.50percent")
                    }
                    .font(.title3)

                    MGCard {
                        Text("Music Glove 01").font(.title3.bold())
                        HStack {
                            Text("Protocol")
                            Spacer()
                            Text("Awaiting hardware specification").foregroundStyle(.secondary)
                        }
                    }

                    HStack(spacing: 14) {
                        Button("Reconnect") {
                            Task { await model.connectDevelopmentGlove() }
                        }
                        .buttonStyle(MGPrimaryButtonStyle())

                        Button("Disconnect") {
                            Task { await model.disconnectGlove() }
                        }
                        .buttonStyle(MGSecondaryButtonStyle())
                    }

                    NavigationLink {
                        GestureTestView()
                    } label: {
                        MGCard { Label("Gesture Guide & Test", systemImage: "book") }
                    }
                    .buttonStyle(.plain)

                    MGCard { Label("Customize", systemImage: "gearshape") }
                    MGCard { Label("Help & Troubleshooting", systemImage: "questionmark.circle") }
                }
                .padding(20)
            }
        }
        .navigationTitle("My Music Glove")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct GestureTestView: View {
    var body: some View {
        ZStack {
            MGScreenBackground()
            ScrollView {
                VStack(spacing: 20) {
                    Text("Wear your Music Glove and try the gesture.\nThe system will recognize it in real time.")
                        .multilineTextAlignment(.center)
                    MGGloveArtwork()
                    MGWaveform().frame(height: 100).padding(.horizontal, 30)
                    Text("Waiting for real glove protocol…")
                        .font(.title3)
                    MGCard {
                        HStack {
                            Image(systemName: "hand.raised.fill").font(.largeTitle)
                            VStack(alignment: .leading) {
                                Text("No live result").font(.headline)
                                Text("Development UI only").foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "ellipsis.circle").font(.title)
                        }
                    }
                    HStack(spacing: 14) {
                        Button("Try Again") { }.buttonStyle(MGPrimaryButtonStyle())
                        Button("Done") { }.buttonStyle(MGSecondaryButtonStyle())
                    }
                }
                .padding(20)
            }
        }
        .navigationTitle("Gesture Test")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct CommunityView: View {
    @State private var selection = "Discover"

    var body: some View {
        ZStack {
            MGScreenBackground()
            VStack(spacing: 20) {
                Picker("Community section", selection: $selection) {
                    Text("Discover").tag("Discover")
                    Text("My Uploads").tag("My Uploads")
                }
                .pickerStyle(.segmented)

                ContentUnavailableView {
                    Label("Community is not connected", systemImage: "person.3")
                } description: {
                    Text("This screen follows the approved layout. Publishing and live community data require the account and cloud ADRs.")
                }
                Spacer()
            }
            .padding(20)
        }
        .navigationTitle("Community")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct AccountPrivacyView: View {
    var body: some View {
        ZStack {
            MGScreenBackground()
            List {
                Section("Account") {
                    Label("Authentication not configured", systemImage: "person.crop.circle.badge.exclamationmark")
                }
                Section("Privacy") {
                    Label("Original Vocal stays separate", systemImage: "waveform")
                    Label("Motion data is treated as sensitive", systemImage: "hand.raised")
                    Label("Tokens and content are excluded from logs", systemImage: "lock.shield")
                }
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Account & Privacy")
        .navigationBarTitleDisplayMode(.inline)
    }
}
