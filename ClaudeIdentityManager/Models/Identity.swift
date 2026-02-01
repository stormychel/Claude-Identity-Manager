import Foundation

struct Identity: Identifiable, Hashable {
    let id: UUID
    var name: String
    let createdAt: Date
    var lastUsedAt: Date?

    /// The directory URL for this identity's Claude configuration
    var directoryURL: URL {
        Constants.identitiesDirectory.appendingPathComponent(name)
    }

    init(id: UUID = UUID(), name: String, createdAt: Date = Date(), lastUsedAt: Date? = nil) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
        self.lastUsedAt = lastUsedAt
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Identity, rhs: Identity) -> Bool {
        lhs.id == rhs.id
    }
}
