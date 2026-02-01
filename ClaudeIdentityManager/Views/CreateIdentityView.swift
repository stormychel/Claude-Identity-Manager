import SwiftUI

struct CreateIdentityView: View {
    @EnvironmentObject var viewModel: IdentityManagerViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var isCreating = false
    @State private var errorMessage: String?

    private var isValidName: Bool {
        viewModel.isValidNewIdentityName(name)
    }

    private var nameValidationMessage: String? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        if !Constants.isValidIdentityName(trimmed) {
            return "Names must start with a letter or number and contain only letters, numbers, underscores, or hyphens."
        }

        if viewModel.identities.contains(where: { $0.name == trimmed }) {
            return "An identity with this name already exists."
        }

        return nil
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Create Identity")
                    .font(.headline)
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()

            Divider()

            // Content
            VStack(alignment: .leading, spacing: 16) {
                Text("Enter a name for your new identity. This will create a new isolated Claude configuration.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                TextField("Identity name", text: $name)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit {
                        if isValidName && !isCreating {
                            createIdentity()
                        }
                    }

                if let message = nameValidationMessage {
                    Label(message, systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }

                if let error = errorMessage {
                    Label(error, systemImage: "xmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.red)
                }

                Text("Examples: personal, work, client-acme, project-alpha")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding()

            Divider()

            // Footer
            HStack {
                Spacer()

                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Button("Create") {
                    createIdentity()
                }
                .buttonStyle(.borderedProminent)
                .disabled(!isValidName || isCreating)
                .keyboardShortcut(.defaultAction)
            }
            .padding()
        }
        .frame(width: 400)
    }

    private func createIdentity() {
        isCreating = true
        errorMessage = nil

        Task {
            do {
                try await viewModel.createIdentity(name: name)
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
                isCreating = false
            }
        }
    }
}

#Preview {
    CreateIdentityView()
        .environmentObject(IdentityManagerViewModel())
}
