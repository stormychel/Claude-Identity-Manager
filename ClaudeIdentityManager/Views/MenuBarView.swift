import SwiftUI

struct MenuBarView: View {
    @ObservedObject var viewModel: IdentityManagerViewModel
    let onOpenMainWindow: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Claude Identities")
                    .font(.headline)
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)

            Divider()

            // Identity list
            if viewModel.identities.isEmpty {
                emptyState
            } else {
                identityList
            }

            Divider()

            // Footer
            HStack {
                Button(action: onOpenMainWindow) {
                    Label("Open Manager...", systemImage: "rectangle.on.rectangle")
                }
                .buttonStyle(.plain)

                Spacer()

                if !viewModel.isClaudeAvailable {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.yellow)
                        .help("Claude not found")
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .frame(width: 260)
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Text("No identities")
                .foregroundStyle(.secondary)

            Button("Create Identity...") {
                onOpenMainWindow()
            }
            .buttonStyle(.link)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }

    private var identityList: some View {
        ScrollView {
            LazyVStack(spacing: 2) {
                ForEach(viewModel.identities) { identity in
                    MenuBarIdentityRow(
                        identity: identity,
                        isClaudeAvailable: viewModel.isClaudeAvailable,
                        onLaunch: {
                            Task {
                                try? await viewModel.launchClaude(with: identity)
                            }
                        }
                    )
                }
            }
            .padding(.vertical, 4)
        }
        .frame(maxHeight: 300)
    }
}

struct MenuBarIdentityRow: View {
    let identity: Identity
    let isClaudeAvailable: Bool
    let onLaunch: () -> Void

    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 10) {
            // Icon
            ZStack {
                Circle()
                    .fill(colorForIdentity.gradient)
                    .frame(width: 24, height: 24)

                Text(identity.name.prefix(1).uppercased())
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
            }

            // Name
            Text(identity.name)
                .font(.body)
                .lineLimit(1)

            Spacer()

            // Launch button
            if isHovering && isClaudeAvailable {
                Button(action: onLaunch) {
                    Image(systemName: "play.fill")
                        .font(.caption)
                        .foregroundStyle(.green)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(isHovering ? Color.primary.opacity(0.1) : Color.clear)
        .contentShape(Rectangle())
        .onHover { isHovering = $0 }
        .onTapGesture {
            if isClaudeAvailable {
                onLaunch()
            }
        }
    }

    private var colorForIdentity: Color {
        let colors: [Color] = [.blue, .purple, .pink, .orange, .green, .teal, .indigo, .cyan]
        let hash = abs(identity.name.hashValue)
        return colors[hash % colors.count]
    }
}
