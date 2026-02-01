# Claude Code: CLAUDE_CONFIG_DIR Does Not Isolate Keychain Credentials

## Existing GitHub Issues

**This issue has already been reported. Please upvote/comment on these instead of creating a new issue:**

- **[#20553](https://github.com/anthropics/claude-code/issues/20553)** - OAuth credentials shared across CLAUDE_CONFIG_DIR profiles causing data isolation failure (compliance risk) - *Exact match*
- **[#15670](https://github.com/anthropics/claude-code/issues/15670)** - CLAUDE_CONFIG_DIR doesn't completely isolate installations - *Same use case*
- [#16103](https://github.com/anthropics/claude-code/issues/16103) - Cannot resume sessions when using CLAUDE_CONFIG_DIR
- [#16899](https://github.com/anthropics/claude-code/issues/16899) - statusline-setup agent ignores CLAUDE_CONFIG_DIR

---

## Our Use Case

I have my own Claude Code account and one from a client's Team, and I want to use them on the same Mac. I created a small identity switcher app ([Claude Identity Manager](https://github.com/stormychel/Claude-Identity-Manager)) to launch Claude with different `CLAUDE_CONFIG_DIR` values, but hit this roadblock: credentials stored in macOS Keychain are not isolated per config directory.

## Environment

- macOS 26 (Tahoe)
- Claude Code v2.1.29
- Multiple Claude accounts (personal + client Team)

## The Problem

When launching Claude Code with:
```bash
env CLAUDE_CONFIG_DIR="$HOME/.claude/identities/client-acme" claude
```

- Config files are correctly isolated ✅
- OAuth credentials are NOT isolated ❌ (stored in shared Keychain entry)

Claude stores OAuth credentials in macOS Keychain with service names like:
- `Claude Code-credentials` (default)
- `Claude Code-credentials-{hash}` (created but not found on subsequent launches)

The Keychain lookup doesn't properly use the hash that corresponds to `CLAUDE_CONFIG_DIR`, so credentials from one profile overwrite another, or simply aren't found.

## Suggested Fix (from #20553)

Keychain entries should be namespaced by config directory:
```
Claude Code-credentials-{md5(CLAUDE_CONFIG_DIR)[:8]}
```

Or store OAuth tokens in the config directory itself (encrypted).

## Workaround

Run `/login` each time you switch identities (not ideal for frequent switching).

---

*This document is part of the Claude Identity Manager project - a SwiftUI app attempting to solve multi-account usage on macOS.*
