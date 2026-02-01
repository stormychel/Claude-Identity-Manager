import SwiftUI

struct IdentityRowView: View {
    let identity: Identity
    let isSelected: Bool
    let onLaunch: () -> Void

    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 12) {
            // Identity icon
            identityIcon

            // Identity name and metadata
            VStack(alignment: .leading, spacing: 2) {
                Text(identity.name)
                    .font(.body)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .lineLimit(1)

                if let lastUsed = identity.lastUsedAt {
                    Text("Last used \(lastUsed.formatted(.relative(presentation: .named)))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            // Launch button (visible on hover)
            if isHovering {
                Button(action: onLaunch) {
                    Image(systemName: "play.fill")
                        .foregroundStyle(.green)
                }
                .buttonStyle(.plain)
                .help("Launch Claude with this identity")
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onHover { isHovering = $0 }
    }

    private var identityIcon: some View {
        ZStack {
            Circle()
                .fill(colorForIdentity.gradient)
                .frame(width: 32, height: 32)

            Text(identity.name.prefix(1).uppercased())
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
        }
    }

    private var colorForIdentity: Color {
        let colors: [Color] = [.blue, .purple, .pink, .orange, .green, .teal, .indigo, .cyan]
        let hash = abs(identity.name.hashValue)
        return colors[hash % colors.count]
    }
}
