import Foundation

final class FileSystemService {
    static let shared = FileSystemService()

    private let fileManager = FileManager.default

    private init() {}

    // MARK: - Directory Discovery

    /// Discovers all identities by scanning the identities directory
    func discoverIdentities() throws -> [Identity] {
        let identitiesDir = Constants.identitiesDirectory

        // Ensure base directory exists
        try ensureDirectoryExists(at: identitiesDir)

        let contents = try fileManager.contentsOfDirectory(
            at: identitiesDir,
            includingPropertiesForKeys: [.isDirectoryKey, .creationDateKey],
            options: [.skipsHiddenFiles]
        )

        return contents.compactMap { url -> Identity? in
            var isDirectory: ObjCBool = false
            guard fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory),
                  isDirectory.boolValue else {
                return nil
            }

            let attributes = try? fileManager.attributesOfItem(atPath: url.path)
            let createdAt = attributes?[.creationDate] as? Date ?? Date()

            return Identity(
                name: url.lastPathComponent,
                createdAt: createdAt
            )
        }.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    // MARK: - CRUD Operations

    /// Creates a new identity directory
    func createIdentityDirectory(name: String) throws {
        guard Constants.isValidIdentityName(name) else {
            throw FileSystemError.invalidIdentityName(name)
        }

        let identityDir = Constants.identitiesDirectory.appendingPathComponent(name)

        guard !fileManager.fileExists(atPath: identityDir.path) else {
            throw FileSystemError.identityAlreadyExists(name)
        }

        try fileManager.createDirectory(at: identityDir, withIntermediateDirectories: true)
    }

    /// Renames an identity directory
    func renameIdentityDirectory(from oldName: String, to newName: String) throws {
        guard Constants.isValidIdentityName(newName) else {
            throw FileSystemError.invalidIdentityName(newName)
        }

        let oldPath = Constants.identitiesDirectory.appendingPathComponent(oldName)
        let newPath = Constants.identitiesDirectory.appendingPathComponent(newName)

        guard fileManager.fileExists(atPath: oldPath.path) else {
            throw FileSystemError.identityNotFound(oldName)
        }

        guard !fileManager.fileExists(atPath: newPath.path) else {
            throw FileSystemError.identityAlreadyExists(newName)
        }

        try fileManager.moveItem(at: oldPath, to: newPath)
    }

    /// Deletes an identity directory and all its contents
    func deleteIdentityDirectory(name: String) throws {
        let identityDir = Constants.identitiesDirectory.appendingPathComponent(name)

        guard fileManager.fileExists(atPath: identityDir.path) else {
            throw FileSystemError.identityNotFound(name)
        }

        try fileManager.removeItem(at: identityDir)
    }

    // MARK: - Validation

    /// Checks if an identity directory exists
    func identityDirectoryExists(name: String) -> Bool {
        let identityDir = Constants.identitiesDirectory.appendingPathComponent(name)
        var isDirectory: ObjCBool = false
        return fileManager.fileExists(atPath: identityDir.path, isDirectory: &isDirectory) && isDirectory.boolValue
    }

    // MARK: - Private Helpers

    private func ensureDirectoryExists(at url: URL) throws {
        var isDirectory: ObjCBool = false
        if !fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory) {
            try fileManager.createDirectory(at: url, withIntermediateDirectories: true)
        } else if !isDirectory.boolValue {
            throw FileSystemError.pathExistsButNotDirectory(url.path)
        }
    }
}

// MARK: - Errors

enum FileSystemError: LocalizedError {
    case invalidIdentityName(String)
    case identityAlreadyExists(String)
    case identityNotFound(String)
    case pathExistsButNotDirectory(String)

    var errorDescription: String? {
        switch self {
        case .invalidIdentityName(let name):
            return "Invalid identity name: '\(name)'. Names must start with a letter or number and contain only letters, numbers, underscores, or hyphens."
        case .identityAlreadyExists(let name):
            return "An identity named '\(name)' already exists."
        case .identityNotFound(let name):
            return "Identity '\(name)' not found."
        case .pathExistsButNotDirectory(let path):
            return "Path exists but is not a directory: \(path)"
        }
    }
}
