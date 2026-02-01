// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ClaudeIdentityManager",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "ClaudeIdentityManager",
            targets: ["ClaudeIdentityManager"]
        )
    ],
    targets: [
        .executableTarget(
            name: "ClaudeIdentityManager",
            path: ".",
            exclude: ["Resources/Assets.xcassets", "Package.swift"],
            sources: [
                "App/ClaudeIdentityManagerApp.swift",
                "App/AppDelegate.swift",
                "Models/Identity.swift",
                "ViewModels/IdentityManagerViewModel.swift",
                "Views/ContentView.swift",
                "Views/IdentityListView.swift",
                "Views/IdentityRowView.swift",
                "Views/EmptyStateView.swift",
                "Views/CreateIdentityView.swift",
                "Views/RenameIdentityView.swift",
                "Views/MenuBarView.swift",
                "Services/FileSystemService.swift",
                "Services/ClaudeLauncher.swift",
                "Utilities/Constants.swift"
            ],
            resources: [
                .process("Resources/ClaudeIdentityManager.entitlements")
            ]
        )
    ]
)
