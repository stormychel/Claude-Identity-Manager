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
    var body: some View {
        Form {
            Section {
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
        .frame(width: 450, height: 150)
    }
}

// MARK: - Notifications

extension Notification.Name {
    static let showCreateIdentity = Notification.Name("showCreateIdentity")
}
