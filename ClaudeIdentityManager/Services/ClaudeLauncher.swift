import Foundation
import AppKit

// MARK: - Terminal App Enum

enum TerminalApp: String, CaseIterable, Identifiable {
    case terminal = "Terminal"
    case iterm = "iTerm"
    case warp = "Warp"
    case alacritty = "Alacritty"
    case kitty = "kitty"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .terminal: return "Terminal"
        case .iterm: return "iTerm2"
        case .warp: return "Warp"
        case .alacritty: return "Alacritty"
        case .kitty: return "Kitty"
        }
    }

    var bundleIdentifier: String {
        switch self {
        case .terminal: return "com.apple.Terminal"
        case .iterm: return "com.googlecode.iterm2"
        case .warp: return "dev.warp.Warp-Stable"
        case .alacritty: return "org.alacritty"
        case .kitty: return "net.kovidgoyal.kitty"
        }
    }

    var isInstalled: Bool {
        NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier) != nil
    }

    static var installedTerminals: [TerminalApp] {
        allCases.filter { $0.isInstalled }
    }
}

// MARK: - Claude Launcher

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

    /// Launches Claude with the specified identity in the preferred terminal
    func launch(identity: Identity, workingDirectory: URL? = nil, terminal: TerminalApp? = nil) throws {
        guard let claudePath = findClaudeExecutable() else {
            throw LaunchError.claudeNotFound
        }

        guard FileManager.default.fileExists(atPath: identity.directoryURL.path) else {
            throw LaunchError.identityDirectoryMissing(identity.name)
        }

        // Use provided terminal or get from UserDefaults
        let selectedTerminal = terminal ?? getPreferredTerminal()

        guard selectedTerminal.isInstalled else {
            throw LaunchError.terminalNotInstalled(selectedTerminal.displayName)
        }

        try launchInTerminal(
            terminal: selectedTerminal,
            claudePath: claudePath,
            identityPath: identity.directoryURL.path,
            workingDirectory: workingDirectory
        )
    }

    /// Gets the preferred terminal from UserDefaults
    func getPreferredTerminal() -> TerminalApp {
        let stored = UserDefaults.standard.string(forKey: "preferredTerminal") ?? ""
        return TerminalApp(rawValue: stored) ?? .terminal
    }

    /// Sets the preferred terminal in UserDefaults
    func setPreferredTerminal(_ terminal: TerminalApp) {
        UserDefaults.standard.set(terminal.rawValue, forKey: "preferredTerminal")
    }

    // MARK: - Private Methods

    private func launchInTerminal(terminal: TerminalApp, claudePath: URL, identityPath: String, workingDirectory: URL?) throws {
        switch terminal {
        case .terminal:
            try launchInAppleTerminal(claudePath: claudePath, identityPath: identityPath, workingDirectory: workingDirectory)
        case .iterm:
            try launchInITerm(claudePath: claudePath, identityPath: identityPath, workingDirectory: workingDirectory)
        case .warp:
            try launchInWarp(claudePath: claudePath, identityPath: identityPath, workingDirectory: workingDirectory)
        case .alacritty, .kitty:
            try launchInGenericTerminal(terminal: terminal, claudePath: claudePath, identityPath: identityPath, workingDirectory: workingDirectory)
        }
    }

    // MARK: - Terminal-Specific Launch Methods

    private func launchInAppleTerminal(claudePath: URL, identityPath: String, workingDirectory: URL?) throws {
        var commands: [String] = []

        if let workDir = workingDirectory {
            commands.append("cd '\(workDir.path)'")
        }

        // Set CLAUDE_CONFIG_DIR for config files
        // Note: Keychain credentials are stored separately and may not be fully isolated
        commands.append("env CLAUDE_CONFIG_DIR='\(identityPath)' '\(claudePath.path)'")
        let fullCommand = commands.joined(separator: "; ")

        let script = """
            tell application "Terminal"
                activate
                do script "\(fullCommand)"
            end tell
            """

        try executeAppleScript(script)
    }

    private func launchInITerm(claudePath: URL, identityPath: String, workingDirectory: URL?) throws {
        // Build command using env to ensure CLAUDE_CONFIG_DIR is set for the process
        var command = "env CLAUDE_CONFIG_DIR='\(identityPath)' '\(claudePath.path)'"

        if let workDir = workingDirectory {
            command = "cd '\(workDir.path)' && \(command)"
        }

        let script = """
            tell application "iTerm"
                activate
                if (count of windows) = 0 then
                    create window with default profile
                end if
                tell current window
                    create tab with default profile
                    tell current session
                        write text "\(command)"
                    end tell
                end tell
            end tell
            """

        try executeAppleScript(script)
    }

    private func launchInWarp(claudePath: URL, identityPath: String, workingDirectory: URL?) throws {
        // Warp supports AppleScript similar to Terminal
        var commands: [String] = []

        if let workDir = workingDirectory {
            commands.append("cd '\(workDir.path)'")
        }

        commands.append("env CLAUDE_CONFIG_DIR='\(identityPath)' '\(claudePath.path)'")
        let fullCommand = commands.joined(separator: "; ")

        let script = """
            tell application "Warp"
                activate
                do script "\(fullCommand)"
            end tell
            """

        try executeAppleScript(script)
    }

    private func launchInGenericTerminal(terminal: TerminalApp, claudePath: URL, identityPath: String, workingDirectory: URL?) throws {
        // For terminals like Alacritty and Kitty, launch via command line
        guard let terminalURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: terminal.bundleIdentifier) else {
            throw LaunchError.terminalNotInstalled(terminal.displayName)
        }

        var shellCommand = "env CLAUDE_CONFIG_DIR='\(identityPath)' '\(claudePath.path)'"

        if let workDir = workingDirectory {
            shellCommand = "cd '\(workDir.path)' && \(shellCommand)"
        }

        // Launch the terminal with the command
        let config = NSWorkspace.OpenConfiguration()
        config.arguments = ["-e", "/bin/zsh", "-c", shellCommand]

        // For these terminals, we use a different approach - launch a shell script
        let scriptContent = """
            #!/bin/zsh
            \(shellCommand)
            """

        let tempScript = FileManager.default.temporaryDirectory.appendingPathComponent("claude-launch-\(UUID().uuidString).sh")
        try scriptContent.write(to: tempScript, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: tempScript.path)

        // Open the terminal app
        NSWorkspace.shared.openApplication(at: terminalURL, configuration: config) { _, error in
            // Clean up temp script after a delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                try? FileManager.default.removeItem(at: tempScript)
            }
        }

        // Alternative: use open command with the terminal
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        process.arguments = ["-a", terminal.rawValue, "--args", "-e", "/bin/zsh", "-c", shellCommand]

        try process.run()
    }

    private func executeAppleScript(_ script: String) throws {
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
    case terminalNotInstalled(String)
    case scriptCreationFailed
    case launchFailed(String)

    var errorDescription: String? {
        switch self {
        case .claudeNotFound:
            return "Claude executable not found. Please ensure Claude Code is installed and available in your PATH."
        case .identityDirectoryMissing(let name):
            return "Identity directory for '\(name)' does not exist."
        case .terminalNotInstalled(let name):
            return "\(name) is not installed on this system."
        case .scriptCreationFailed:
            return "Failed to create AppleScript for Terminal launch."
        case .launchFailed(let message):
            return "Failed to launch Claude: \(message)"
        }
    }
}
