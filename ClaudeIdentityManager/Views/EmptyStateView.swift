import SwiftUI

struct EmptyStateView: View {
    let onCreateTapped: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.crop.circle.badge.plus")
                .font(.system(size: 56))
                .foregroundStyle(.secondary)

            VStack(spacing: 8) {
                Text("No Identity Selected")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Select an identity from the sidebar to view details,\nor create a new one to get started.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button("Create Identity") {
                onCreateTapped()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
    }
}

#Preview {
    EmptyStateView(onCreateTapped: {})
}
