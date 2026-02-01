import SwiftUI

struct RenameIdentityView: View {
    @EnvironmentObject var viewModel: IdentityManagerViewModel
    @Environment(\.dismiss) private var dismiss

    let identity: Identity

    @State private var newName: String
    @State private var isRenaming = false
    @State private var errorMessage: String?

    init(identity: Identity) {
        self.identity = identity
        self._newName = State(initialValue: identity.name)
    }

    private var isValidName: Bool {
        viewModel.isValidRename(from: identity.name, to: newName)
    }

    private var hasChanges: Bool {
        newName.trimmingCharacters(in: .whitespacesAndNewlines) != identity.name
    }

    private var nameValidationMessage: String? {
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed != identity.name else { return nil }

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
                Text("Rename Identity")
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
                Text("Enter a new name for \"\(identity.name)\".")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                TextField("Identity name", text: $newName)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit {
                        if isValidName && hasChanges && !isRenaming {
                            renameIdentity()
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

                Button("Rename") {
                    renameIdentity()
                }
                .buttonStyle(.borderedProminent)
                .disabled(!isValidName || !hasChanges || isRenaming)
                .keyboardShortcut(.defaultAction)
            }
            .padding()
        }
        .frame(width: 400)
    }

    private func renameIdentity() {
        isRenaming = true
        errorMessage = nil

        Task {
            do {
                try await viewModel.renameIdentity(identity, to: newName)
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
                isRenaming = false
            }
        }
    }
}
