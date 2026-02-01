import SwiftUI
import AppKit

struct ContentView: View {
    @EnvironmentObject var viewModel: IdentityManagerViewModel

    @State private var showCreateSheet = false
    @State private var identityToRename: Identity?
    @State private var identityToDelete: Identity?

    var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            detailView
        }
        .navigationSplitViewStyle(.balanced)
        .frame(minWidth: 600, minHeight: 400)
        .sheet(isPresented: $showCreateSheet) {
            CreateIdentityView()
        }
        .sheet(item: $identityToRename) { identity in
            RenameIdentityView(identity: identity)
        }
        .confirmationDialog(
            "Delete Identity",
            isPresented: Binding(
                get: { identityToDelete != nil },
                set: { if !$0 { identityToDelete = nil } }
            ),
            presenting: identityToDelete
        ) { identity in
            Button("Delete \"\(identity.name)\"", role: .destructive) {
                Task {
                    do {
                        try await viewModel.deleteIdentity(identity)
                    } catch {
                        viewModel.errorMessage = error.localizedDescription
                        viewModel.showError = true
                    }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: { identity in
            Text("This will permanently delete the identity folder \"\(identity.name)\" and all Claude data stored within it. This action cannot be undone.")
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK") {
                viewModel.dismissError()
            }
        } message: {
            if let message = viewModel.errorMessage {
                Text(message)
            }
        }
        .task {
            await viewModel.loadIdentities()
        }
    }

    // MARK: - Sidebar

    private var sidebar: some View {
        VStack(spacing: 0) {
            IdentityListView(
                onRename: { identityToRename = $0 },
                onDelete: { identityToDelete = $0 }
            )

            Divider()

            bottomToolbar
        }
        .navigationSplitViewColumnWidth(min: 200, ideal: 250, max: 350)
    }

    private var bottomToolbar: some View {
        HStack {
            Button(action: { showCreateSheet = true }) {
                Image(systemName: "plus")
            }
            .buttonStyle(.plain)
            .help("Create new identity")

            Spacer()

            if !viewModel.isClaudeAvailable {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.yellow)
                    .help("Claude executable not found in PATH")
            }
        }
        .padding(8)
    }

    // MARK: - Detail View

    @ViewBuilder
    private var detailView: some View {
        if let selected = viewModel.selectedIdentity {
            IdentityDetailView(identity: selected)
        } else {
            EmptyStateView(onCreateTapped: { showCreateSheet = true })
        }
    }
}

// MARK: - Identity Detail View

struct IdentityDetailView: View {
    @EnvironmentObject var viewModel: IdentityManagerViewModel
    @AppStorage("lastLaunchFolder") private var lastLaunchFolderPath: String = ""
    let identity: Identity

    private var lastLaunchFolder: URL? {
        guard !lastLaunchFolderPath.isEmpty else { return nil }
        let url = URL(fileURLWithPath: lastLaunchFolderPath)
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory),
              isDirectory.boolValue else {
            return nil
        }
        return url
    }

    var body: some View {
        VStack(spacing: 24) {
            // Identity icon
            ZStack {
                Circle()
                    .fill(colorForIdentity(identity.name).gradient)
                    .frame(width: 80, height: 80)

                Text(identity.name.prefix(1).uppercased())
                    .font(.system(size: 36, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
            }

            // Identity name
            Text(identity.name)
                .font(.title)
                .fontWeight(.semibold)

            // Metadata
            VStack(spacing: 8) {
                Label("Created \(identity.createdAt.formatted(date: .abbreviated, time: .omitted))", systemImage: "calendar")
                    .foregroundStyle(.secondary)

                if let lastUsed = identity.lastUsedAt {
                    Label("Last used \(lastUsed.formatted(.relative(presentation: .named)))", systemImage: "clock")
                        .foregroundStyle(.secondary)
                }
            }
            .font(.subheadline)

            Spacer()

            // Launch buttons
            VStack(spacing: 12) {
                // Launch in home directory
                Button(action: {
                    launchClaude(in: nil)
                }) {
                    Label("Launch Claude", systemImage: "play.fill")
                        .frame(minWidth: 180)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(!viewModel.isClaudeAvailable)

                // Launch in folder
                Button(action: {
                    selectFolderAndLaunch()
                }) {
                    HStack {
                        Image(systemName: "folder.fill")
                        if let folder = lastLaunchFolder {
                            Text("Launch in \(folder.lastPathComponent)")
                        } else {
                            Text("Launch in Folder...")
                        }
                    }
                    .frame(minWidth: 180)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .disabled(!viewModel.isClaudeAvailable)

                // Show last folder path if set
                if let folder = lastLaunchFolder {
                    Text(folder.path)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }

            if !viewModel.isClaudeAvailable {
                Text("Claude executable not found. Ensure Claude Code is installed.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func launchClaude(in directory: URL?) {
        Task {
            do {
                try await viewModel.launchClaude(with: identity, in: directory)
            } catch {
                viewModel.errorMessage = error.localizedDescription
                viewModel.showError = true
            }
        }
    }

    private func selectFolderAndLaunch() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.message = "Select a folder to launch Claude in"
        panel.prompt = "Launch Here"

        // Set initial directory to last used folder if available
        if let lastFolder = lastLaunchFolder {
            panel.directoryURL = lastFolder
        }

        if panel.runModal() == .OK, let url = panel.url {
            lastLaunchFolderPath = url.path
            launchClaude(in: url)
        }
    }

    private func colorForIdentity(_ name: String) -> Color {
        let colors: [Color] = [.blue, .purple, .pink, .orange, .green, .teal, .indigo, .cyan]
        let hash = abs(name.hashValue)
        return colors[hash % colors.count]
    }
}

#Preview {
    ContentView()
        .environmentObject(IdentityManagerViewModel())
}
