import Foundation
import AppKit

final class ClaudeLauncher {
    static let shared = ClaudeLauncher()

    private init() {}

    // MARK: - Public Methods

    /// Finds the claude executable in common locations or PATH
    func findClaudeExecutable() -> URL? {
        let possiblePaths = [
            "/usr/local/bin/claude",
            "/opt/homebrew/bin/claude",
            "\(NSHomeDirectory())/.local/bin/claude",
            "\(NSHomeDirectory())/.claude/local/claude"
        ]

        for path in possiblePaths {
            if FileManager.default.isExecutableFile(atPath: path) {
                return URL(fileURLWithPath: path)
            }
        }

        // Fall back to which command
        return findExecutableViaWhich("claude")
    }

    /// Checks if Claude is available
    var isClaudeAvailable: Bool {
        findClaudeExecutable() != nil
    }

    /// Launches Claude with the specified identity in Terminal.app
    func launch(identity: Identity, workingDirectory: URL? = nil) throws {
        guard let claudePath = findClaudeExecutable() else {
            throw LaunchError.claudeNotFound
        }

        guard FileManager.default.fileExists(atPath: identity.directoryURL.path) else {
            throw LaunchError.identityDirectoryMissing(identity.name)
        }

        try launchInTerminal(
            claudePath: claudePath,
            identityPath: identity.directoryURL.path,
            workingDirectory: workingDirectory
        )
    }

    // MARK: - Private Methods

    private func launchInTerminal(claudePath: URL, identityPath: String, workingDirectory: URL?) throws {
        var commands: [String] = []

        // Change to working directory if specified
        if let workDir = workingDirectory {
            commands.append("cd '\(workDir.path)'")
        }

        // Use CLAUDE_CONFIG_DIR to specify the config directory for this identity
        // This is the officially supported environment variable for Claude Code
        commands.append("env CLAUDE_CONFIG_DIR='\(identityPath)' '\(claudePath.path)'")

        let fullCommand = commands.joined(separator: "; ")

        let script = """
            tell application "Terminal"
                activate
                do script "\(fullCommand)"
            end tell
            """

        var error: NSDictionary?
        guard let scriptObject = NSAppleScript(source: script) else {
            throw LaunchError.scriptCreationFailed
        }

        scriptObject.executeAndReturnError(&error)

        if let error = error {
            let message = error[NSAppleScript.errorMessage] as? String ?? "Unknown AppleScript error"
            throw LaunchError.launchFailed(message)
        }
    }

    private func findExecutableViaWhich(_ name: String) -> URL? {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        task.arguments = [name]

        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = FileHandle.nullDevice

        do {
            try task.run()
            task.waitUntilExit()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            guard let path = String(data: data, encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines),
                  !path.isEmpty,
                  FileManager.default.isExecutableFile(atPath: path) else {
                return nil
            }

            return URL(fileURLWithPath: path)
        } catch {
            return nil
        }
    }
}

// MARK: - Errors

enum LaunchError: LocalizedError {
    case claudeNotFound
    case identityDirectoryMissing(String)
    case scriptCreationFailed
    case launchFailed(String)

    var errorDescription: String? {
        switch self {
        case .claudeNotFound:
            return "Claude executable not found. Please ensure Claude Code is installed and available in your PATH."
        case .identityDirectoryMissing(let name):
            return "Identity directory for '\(name)' does not exist."
        case .scriptCreationFailed:
            return "Failed to create AppleScript for Terminal launch."
        case .launchFailed(let message):
            return "Failed to launch Claude: \(message)"
        }
    }
}
