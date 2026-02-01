# Claude Code: CLAUDE_CONFIG_DIR Does Not Isolate Keychain Credentials

## Summary

I have my own Claude Code account and one from a client's Team, and I want to use them on the same Mac. I created a small identity switcher app to launch Claude with different `CLAUDE_CONFIG_DIR` values, but hit a roadblock: credentials stored in macOS Keychain are not isolated per config directory.

## Environment

- macOS 26 (Tahoe)
- Claude Code v2.1.29
- Multiple Claude accounts (personal + client Team)

## Expected Behavior

When launching Claude Code with:
```bash
env CLAUDE_CONFIG_DIR="$HOME/.claude/identities/client-acme" claude
```

I expect:
1. Config files to be read from/written to the specified directory ✅ (works)
2. OAuth credentials to be isolated per config directory ❌ (does not work)

## Actual Behavior

Claude Code stores OAuth credentials in the macOS Keychain with service names like:
- `Claude Code-credentials` (default)
- `Claude Code-credentials-08d5ad37` (hashed)
- `Claude Code-credentials-27cc539e` (hashed)

When authenticating with `CLAUDE_CONFIG_DIR` set, Claude creates a new Keychain entry with a hash suffix. However, on subsequent launches with the same `CLAUDE_CONFIG_DIR`, Claude fails to find the matching Keychain entry and shows:

```
Welcome back [User]!
...
Missing API key · Run /login
```

The banner shows user info (read from `.claude.json` in the config directory), but the actual OAuth token lookup fails.

## Steps to Reproduce

1. Set up two identity directories:
   ```bash
   mkdir -p ~/.claude/identities/personal
   mkdir -p ~/.claude/identities/client
   ```

2. Launch Claude with first identity and authenticate:
   ```bash
   env CLAUDE_CONFIG_DIR="$HOME/.claude/identities/personal" claude
   # Run /login, complete OAuth flow
   ```

3. Exit and relaunch with same config:
   ```bash
   env CLAUDE_CONFIG_DIR="$HOME/.claude/identities/personal" claude
   ```

4. Observe: Shows "Missing API key · Run /login" despite having authenticated in step 2

## Investigation Findings

### Config Directory (Works)

The `.claude.json` file in the identity directory correctly stores:
```json
{
  "oauthAccount": {
    "accountUuid": "...",
    "emailAddress": "...",
    "organizationName": "...",
    "displayName": "..."
  }
}
```

### Keychain (Does Not Work)

OAuth tokens (accessToken, refreshToken) are stored in macOS Keychain, NOT in the config directory. The Keychain entries are:

```
svce: "Claude Code-credentials"          acct: "username"
svce: "Claude Code-credentials-08d5ad37" acct: "username"
svce: "Claude Code-credentials-27cc539e" acct: "username"
```

The hash suffix appears to be generated when authenticating with `CLAUDE_CONFIG_DIR` set, but the lookup mechanism on subsequent launches doesn't find the correct entry.

## Use Case

Many developers work with multiple Claude accounts:
- Personal account for side projects
- Company/Team account for work
- Client Team accounts for consulting

Being able to switch between these on the same machine without logging in/out each time would significantly improve the workflow.

## Suggested Fix

When `CLAUDE_CONFIG_DIR` is set, Claude Code should:
1. Generate a consistent hash/identifier from the config directory path
2. Use `Claude Code-credentials-{hash}` for both storing AND retrieving Keychain credentials
3. Ensure the hash generation is deterministic so lookups match stores

Alternatively:
- Store OAuth tokens in the config directory itself (encrypted)
- Or document an environment variable specifically for Keychain isolation

## Workaround Attempted

Setting `HOME` in addition to `CLAUDE_CONFIG_DIR` does not help, as the Keychain is tied to the macOS user account, not the HOME directory.

## Related

This may be related to: https://github.com/anthropics/claude-code/issues/1455 (XDG Base Directory support)

---

Thank you for looking into this. Happy to provide additional details or test any fixes.
