# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Known Limitation

**Credential isolation is currently broken in Claude Code.** While `CLAUDE_CONFIG_DIR` isolates config files, OAuth credentials are stored in macOS Keychain and the lookup doesn't properly respect this variable. See `Docs/ANTHROPIC_BUG_REPORT.md` for details. Users may need to run `/login` for each identity.

## Project Overview

Claude Identity Manager is a native macOS SwiftUI app that manages multiple Claude Code identities. It launches Claude with isolated config directories to prevent accidental account mixing between personal and client work.

**This is not an AI client.** It is a local identity/session manager. Claude handles its own authentication.

## Core Mechanism

Identity isolation works via environment variables:
```bash
CLAUDE_CONFIG_DIR=~/.claude/identities/<identity-name> claude
```

Each identity folder is a fully isolated Claude profile. The app stores NO credentials, makes NO network requests, and has NO telemetry.

## Code Architecture

```
ClaudeIdentityManager/
├── App/
│   ├── ClaudeIdentityManagerApp.swift   # @main entry, scenes, commands
│   └── AppDelegate.swift                 # Menu bar status item setup
├── Models/
│   └── Identity.swift                    # Identity data model
├── ViewModels/
│   └── IdentityManagerViewModel.swift    # @MainActor, CRUD operations
├── Views/
│   ├── ContentView.swift                 # NavigationSplitView layout
│   ├── IdentityListView.swift            # Sidebar list with context menus
│   ├── IdentityRowView.swift             # Row with hover launch button
│   ├── CreateIdentityView.swift          # Sheet for new identity
│   ├── RenameIdentityView.swift          # Sheet for rename
│   ├── EmptyStateView.swift              # No selection prompt
│   └── MenuBarView.swift                 # Menu bar popover content
├── Services/
│   ├── FileSystemService.swift           # Identity folder CRUD
│   └── ClaudeLauncher.swift              # Terminal launch with env vars
└── Utilities/
    └── Constants.swift                   # Paths, validation regex
```

**Key files:**
- `ClaudeLauncher.swift:78` - Launches Claude with `CLAUDE_CONFIG_DIR` via AppleScript
- `FileSystemService.swift:13` - Discovers identities by scanning `~/.claude/identities/`
- `Constants.swift:10` - Identity directory path: `~/.claude/identities/`

## Build & Run

**Xcode (recommended):**
```bash
open ClaudeIdentityManager.xcodeproj
# Then Cmd+R to build and run
```

**Command line:**
```bash
xcodebuild -project ClaudeIdentityManager.xcodeproj -scheme ClaudeIdentityManager -configuration Debug build
```

**Swift Package Manager (alternative):**
```bash
cd ClaudeIdentityManager
swift build && swift run
```

**Requirements:** macOS 13+, Xcode 15+, Claude Code installed (`claude` in PATH)
