import SwiftUI

@main
struct ClaudeIdentityManagerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var viewModel = IdentityManagerViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
                .onAppear {
                    appDelegate.setViewModel(viewModel)
                }
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentMinSize)
        .defaultSize(width: 700, height: 500)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Identity...") {
                    NotificationCenter.default.post(name: .showCreateIdentity, object: nil)
                }
                .keyboardShortcut("n", modifiers: .command)
            }

            CommandGroup(after: .appInfo) {
                Button("Refresh Identities") {
                    Task {
                        await viewModel.loadIdentities()
                    }
                }
                .keyboardShortcut("r", modifiers: .command)
            }
        }

        Settings {
            SettingsView()
        }
    }
}

// MARK: - Settings View

struct SettingsView: View {
    @State private var selectedTerminal: TerminalApp = ClaudeLauncher.shared.getPreferredTerminal()

    var body: some View {
        Form {
            Section("Terminal") {
                Picker("Terminal App", selection: $selectedTerminal) {
                    ForEach(TerminalApp.allCases) { terminal in
                        HStack {
                            Text(terminal.displayName)
                            if !terminal.isInstalled {
                                Text("(not installed)")
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .tag(terminal)
                    }
                }
                .onChange(of: selectedTerminal) { newValue in
                    ClaudeLauncher.shared.setPreferredTerminal(newValue)
                }

                if !selectedTerminal.isInstalled {
                    Label("\(selectedTerminal.displayName) is not installed. Terminal.app will be used as fallback.", systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }

            Section("Paths") {
                LabeledContent("Identities Location") {
                    Text(Constants.identitiesDirectory.path)
                        .textSelection(.enabled)
                        .foregroundStyle(.secondary)
                }

                LabeledContent("Claude Executable") {
                    if let path = ClaudeLauncher.shared.findClaudeExecutable()?.path {
                        Text(path)
                            .textSelection(.enabled)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Not found")
                            .foregroundStyle(.red)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 500, height: 250)
    }
}

// MARK: - Notifications

extension Notification.Name {
    static let showCreateIdentity = Notification.Name("showCreateIdentity")
}
