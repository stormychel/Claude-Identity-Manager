import Foundation

enum Constants {
    /// Base Claude configuration directory
    static let claudeBaseDirectory: URL = {
        let home = FileManager.default.homeDirectoryForCurrentUser
        return home.appendingPathComponent(".claude")
    }()

    /// Directory containing all identity folders
    static let identitiesDirectory: URL = {
        claudeBaseDirectory.appendingPathComponent("identities")
    }()

    /// Optional UI state persistence file
    static let stateFile: URL = {
        claudeBaseDirectory.appendingPathComponent("identity-manager-state.json")
    }()

    /// Valid identity name pattern: starts with alphanumeric, can contain alphanumeric, underscore, hyphen
    static let identityNamePattern = "^[a-zA-Z0-9][a-zA-Z0-9_-]*$"

    /// Maximum length for identity names
    static let maxIdentityNameLength = 64

    /// Reserved names that cannot be used for identities
    static let reservedNames: Set<String> = ["identities", "state", "config", "cache", "logs", "settings"]

    /// Validates an identity name
    static func isValidIdentityName(_ name: String) -> Bool {
        guard !name.isEmpty,
              name.count <= maxIdentityNameLength,
              !reservedNames.contains(name.lowercased()) else {
            return false
        }

        let regex = try? NSRegularExpression(pattern: identityNamePattern)
        let range = NSRange(name.startIndex..., in: name)
        return regex?.firstMatch(in: name, range: range) != nil
    }
}
