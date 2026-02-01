# Claude Identity Manager (macOS)

A lightweight macOS SwiftUI app that manages multiple Claude Code identities and launches Claude with an explicitly chosen profile—eliminating accidental account mixing between personal and client work.

**Claude authentication is handled entirely by Claude itself.** This app only orchestrates identity isolation and launch context.

---

> ## Known Limitation: Credential Isolation Issue
>
> **Status:** Reported to Anthropic ([see bug report](ClaudeIdentityManager/Docs/ANTHROPIC_BUG_REPORT.md))
>
> Claude Code stores OAuth credentials in the macOS Keychain rather than in the config directory. While `CLAUDE_CONFIG_DIR` correctly isolates settings and user metadata, the Keychain credential lookup does not properly respect this variable.
>
> **Impact:** After authenticating an identity, subsequent launches may show "Missing API key · Run /login" even though you've already logged in.
>
> **Workaround:** Run `/login` for each identity when prompted. We are working with Anthropic to resolve this.

---

## Goals

* Explicit identity selection every time Claude is launched
* Zero stored API keys or secrets
* One Claude login per identity
* Native macOS UI (SwiftUI)
* CLI-friendly and GUI-safe
* Hard to misuse, easy to understand

## Non-Goals

* Managing Claude accounts or credentials
* Interfacing with Anthropic APIs
* Syncing or cloud features
* Replacing Claude Code itself

**This is not an AI client. It is a local identity and session manager.**

---

## Core Idea

Claude stores its login state under its config directory. By launching Claude with a different config directory per identity, we get clean isolation:

```bash
CLAUDE_CONFIG_DIR=~/.claude/identities/<identity-name> claude
```

* Each identity logs in independently
* Claude handles authentication prompts
* No tokens are stored by this app

The app manages only:

* Identity folders
* Identity selection
* Safe Claude launching

---

## File Layout

```
~/.claude/
├── identities/
│   ├── personal/
│   ├── client-acme/
│   └── client-foo/
└── state.json        (optional UI state)
```

Each folder represents a fully isolated Claude profile.

---

## Features (Initial Scope)

* Create, rename, and delete identities
* Launch Claude with a selected identity
* Optional menu bar integration
* Visual indicator of the active identity
* No default identity (explicit choice required)

## Planned Enhancements

* Per-repository default identity
* Finder and workspace detection
* Identity color tags
* "Client mode" warnings
* CLI bridge (a `claude` wrapper that opens the picker)
* Optional local-only audit log

---

## Requirements

* macOS 13 or later
* Claude Code installed (`claude` available in PATH)
* Xcode 15 or later

## Development Setup

1. Clone the repository
2. Open the project in Xcode
3. Build and run the app
4. Verify Claude is available in your shell:

```bash
which claude
```

No additional dependencies are required.

---

## Security and Privacy

* No API keys stored
* No network requests
* No telemetry
* All data remains local
* Claude authentication remains Claude's responsibility

---

## Philosophy

This tool exists because:

* Humans make mistakes
* Muscle memory is dangerous
* Client boundaries matter

**If you did not explicitly choose an identity, Claude should not run.**

---

## License

TBD

## Status

Early development and internal use. Interfaces and structure may evolve before the first stable release.
