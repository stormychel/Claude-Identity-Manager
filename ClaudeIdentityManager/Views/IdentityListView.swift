import SwiftUI

struct IdentityListView: View {
    @EnvironmentObject var viewModel: IdentityManagerViewModel

    let onRename: (Identity) -> Void
    let onDelete: (Identity) -> Void

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.identities.isEmpty {
                emptyList
            } else {
                identityList
            }
        }
    }

    private var emptyList: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.crop.circle.badge.questionmark")
                .font(.system(size: 32))
                .foregroundStyle(.secondary)

            Text("No Identities")
                .font(.headline)
                .foregroundStyle(.secondary)

            Text("Create your first identity to get started")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    private var identityList: some View {
        List(selection: $viewModel.selectedIdentity) {
            ForEach(viewModel.identities) { identity in
                IdentityRowView(
                    identity: identity,
                    isSelected: viewModel.selectedIdentity?.id == identity.id,
                    onLaunch: {
                        Task {
                            do {
                                try await viewModel.launchClaude(with: identity)
                            } catch {
                                viewModel.errorMessage = error.localizedDescription
                                viewModel.showError = true
                            }
                        }
                    }
                )
                .tag(identity)
                .contextMenu {
                    Button {
                        Task {
                            do {
                                try await viewModel.launchClaude(with: identity)
                            } catch {
                                viewModel.errorMessage = error.localizedDescription
                                viewModel.showError = true
                            }
                        }
                    } label: {
                        Label("Launch Claude", systemImage: "play.fill")
                    }
                    .disabled(!viewModel.isClaudeAvailable)

                    Divider()

                    Button {
                        onRename(identity)
                    } label: {
                        Label("Rename...", systemImage: "pencil")
                    }

                    Button(role: .destructive) {
                        onDelete(identity)
                    } label: {
                        Label("Delete...", systemImage: "trash")
                    }
                }
            }
        }
        .listStyle(.sidebar)
    }
}
