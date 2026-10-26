# Apple Foundation Models for Copilot Chat

A VS Code extension that adds Apple's **on-device Foundation Model** (Apple Intelligence) to the Copilot Chat model picker. Private, offline, free.

## How it works

```
Copilot Chat ──► VS Code LM Chat Provider API ──► extension (TypeScript)
                                                     │  JSON Lines over stdin/stdout
                                                     ▼
                                          fm-bridge (Swift, FoundationModels)
```

Apple's FoundationModels framework is Swift-only, so a small CLI (`swift/`) wraps it. No network port is opened.

## Requirements

- Apple Silicon Mac, **macOS 26+**, Apple Intelligence enabled
- Xcode 26+ with Swift 6.2+ (to build the bridge), Node 20+
- VS Code 1.104+ with GitHub Copilot Chat

## Build and run

```bash
npm install
npm run build:swift        # builds swift/ and copies to bin/fm-bridge
bin/fm-bridge --check      # is the model available?
bin/fm-bridge --prompt "Say hi in five words"
npm run compile
```

The build script checks whether the selected SDK declares the model's context-size and token-count APIs. When available (for example, with the macOS 27 SDK), it enables them; exact counting also requires macOS 26.4+ at runtime. Otherwise, it uses a 4096-token context window and estimates token counts. Runtime availability checks alone do not make missing APIs compile with older SDKs. A direct `swift build` without the script also uses estimates.

Press **F5** in VS Code to launch an Extension Development Host. In Copilot Chat open the model picker → **Manage Models** → **Apple Foundation Models**, then pick *Apple Foundation Model*.

## Install

```bash
npm run package            # → apple-fm-copilot-provider.vsix (darwin-arm64)
npm run install:vscode     # package + `code --install-extension` (needs `code` on PATH)
```

Or in VS Code: Extensions view → `…` → **Install from VSIX…**. Then reload the window, open Copilot Chat, and pick **Apple Foundation Model** from the model picker (if it isn't listed: **Manage Models** → **Apple Foundation Models** → enable it). It works in the Ask and Agent modes of a **local** Copilot Chat session, but not in Copilot CLI sessions (see below).

If macOS quarantines the binary: `xattr -dr com.apple.quarantine bin/`.

## Use a local Copilot Chat session, not Copilot CLI

The model also shows up in the picker for **Copilot CLI** sessions, but it doesn't work there. Copilot CLI sends a large built-in system prompt and tool definitions with every request. Those alone are bigger than the on-device model's context window, so the CLI refuses the request before it reaches this extension. The chat shows no reply, and the agent host log (**Developer: Show Logs…** → **Agent Host**) shows:

```text
Static system messages and tool definitions exceed the model's usable context budget.
Session error: query - No response was returned.
```

Local Copilot Chat sessions go through this extension, which keeps only your messages and attachments so the request fits. To use the Apple model:

1. Open the Chat view (**⌃⌘I**, or **View** → **Chat**).
2. Start a new chat with **+** (**New Chat**).
3. In the session type picker, choose **Local** rather than **Copilot CLI**.
4. Pick **Ask** or **Agent** mode, then choose **Apple Foundation Model** from the model picker.
5. Send a short test message, such as `Say hello in three words`.

Each session type remembers its own model choice. Picking the Apple model in a local chat doesn't change the model used by Copilot CLI sessions, and the other way round. If a local chat still doesn't reply, run **Apple FM: Check Model Availability** and then check **Apple FM: Show Logs**.

## Using a custom bridge binary (`appleFm.bridgePath`)

By default the extension runs the bundled `bin/fm-bridge` (or `swift/.build/release/fm-bridge` in a dev checkout). To use a bridge you built yourself, point `appleFm.bridgePath` at it in your **user** settings:

1. Build the bridge (`npm run build:swift`) and make sure it is executable (`chmod +x /path/to/fm-bridge`).
2. Open the Command Palette (**⇧⌘P**) → **Preferences: Open User Settings (JSON)**. You can also run **Apple FM: Open Settings** and edit it in the **User** tab.
3. Add an **absolute** path:

   ```jsonc
   {
     "appleFm.bridgePath": "/Users/you/code/Apple-FM-Copilot-Chat/bin/fm-bridge"
   }
   ```

4. Save the file. The bridge restarts automatically when this setting changes. Run **Apple FM: Check Model Availability** to confirm it works, or **Apple FM: Show Logs** if it doesn't.

Notes:

- For security, this setting is **only read from user settings**. A value in a workspace or folder `.vscode/settings.json` is ignored, so an untrusted repository can't make the extension run a different program.
- The path must be absolute. `~`, `${workspaceFolder}`, other variables and relative paths are not expanded and will be rejected.
- The extension doesn't change the file's permissions, so the binary must already be executable.
- Leave the setting empty to go back to the bundled binary.

## Limits (v1)

- **4096-token context, input + output combined** for the on-device model. Newer SDK builds read the limit from the OS; Xcode 26 builds use 4096. Prompts are measured with the model's tokenizer when supported by both the build SDK and macOS, or estimated from UTF-8 length otherwise. History is dropped oldest-first, then the prompt is trimmed to leave `appleFm.maxOutputTokens` for the reply, and the reply may use all remaining room. Estimates are not exact and can still result in context-window errors.
- **No real tool calling.** Recent Copilot builds only list tool-capable models (the classic Ask mode is gone), so the model advertises tool calling but always answers in plain text. For agent requests, Copilot's large system prompt and workspace context are dropped; only your messages, attachments and prior replies are sent.
- **Local Copilot Chat sessions only.** Copilot CLI sessions fail with no reply because their fixed system prompt and tool definitions don't fit the context window. See [Use a local Copilot Chat session, not Copilot CLI](#use-a-local-copilot-chat-session-not-copilot-cli).
- Stateless: each request builds a fresh session from the trimmed history.
- macOS 27 adds a 32K-token Private Cloud Compute model, but it rejects requests from an unsigned CLI like `fm-bridge` (it appears to require an Apple entitlement), so it isn't used.

## Commands

Apple FM: Check Model Availability · Restart Bridge · Show Logs · Open Settings
