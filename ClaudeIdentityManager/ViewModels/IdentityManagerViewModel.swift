import Foundation
import SwiftUI

@MainActor
final class IdentityManagerViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published private(set) var identities: [Identity] = []
    @Published private(set) var isLoading = false
    @Published var selectedIdentity: Identity?
    @Published var errorMessage: String?
    @Published var showError = false

    // MARK: - Services

    private let fileSystemService: FileSystemService
    private let claudeLauncher: ClaudeLauncher

    // MARK: - Computed Properties

    var isClaudeAvailable: Bool {
        claudeLauncher.isClaudeAvailable
    }

    // MARK: - Initialization

    init(
        fileSystemService: FileSystemService = .shared,
        claudeLauncher: ClaudeLauncher = .shared
    ) {
        self.fileSystemService = fileSystemService
        self.claudeLauncher = claudeLauncher
    }

    // MARK: - Identity Management

    /// Loads all identities from the file system
    func loadIdentities() async {
        isLoading = true
        defer { isLoading = false }

        do {
            identities = try fileSystemService.discoverIdentities()

            // Clear selection if selected identity no longer exists
            if let selected = selectedIdentity,
               !identities.contains(where: { $0.name == selected.name }) {
                selectedIdentity = nil
            }
        } catch {
            showError(error)
        }
    }

    /// Creates a new identity with the given name
    func createIdentity(name: String) async throws {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)

        guard Constants.isValidIdentityName(trimmedName) else {
            throw FileSystemError.invalidIdentityName(trimmedName)
        }

        try fileSystemService.createIdentityDirectory(name: trimmedName)
        await loadIdentities()

        // Select the newly created identity
        selectedIdentity = identities.first { $0.name == trimmedName }
    }

    /// Renames an identity
    func renameIdentity(_ identity: Identity, to newName: String) async throws {
        let trimmedName = newName.trimmingCharacters(in: .whitespacesAndNewlines)

        guard Constants.isValidIdentityName(trimmedName) else {
            throw FileSystemError.invalidIdentityName(trimmedName)
        }

        try fileSystemService.renameIdentityDirectory(from: identity.name, to: trimmedName)
        await loadIdentities()

        // Update selection to the renamed identity
        selectedIdentity = identities.first { $0.name == trimmedName }
    }

    /// Deletes an identity
    func deleteIdentity(_ identity: Identity) async throws {
        try fileSystemService.deleteIdentityDirectory(name: identity.name)

        // Clear selection if we deleted the selected identity
        if selectedIdentity?.id == identity.id {
            selectedIdentity = nil
        }

        await loadIdentities()
    }

    // MARK: - Launch

    /// Launches Claude with the specified identity
    func launchClaude(with identity: Identity, in directory: URL? = nil) async throws {
        try claudeLauncher.launch(identity: identity, workingDirectory: directory)
    }

    // MARK: - Validation

    /// Checks if an identity name is valid and available
    func isValidNewIdentityName(_ name: String) -> Bool {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return Constants.isValidIdentityName(trimmedName) &&
               !fileSystemService.identityDirectoryExists(name: trimmedName)
    }

    /// Checks if a rename is valid
    func isValidRename(from oldName: String, to newName: String) -> Bool {
        let trimmedName = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedName == oldName { return true }
        return Constants.isValidIdentityName(trimmedName) &&
               !fileSystemService.identityDirectoryExists(name: trimmedName)
    }

    // MARK: - Error Handling

    private func showError(_ error: Error) {
        errorMessage = error.localizedDescription
        showError = true
    }

    func dismissError() {
        errorMessage = nil
        showError = false
    }
}
