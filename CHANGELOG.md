# Changelog

## Unreleased

- Fix Swift builds with SDKs that do not declare `SystemLanguageModel.contextSize` or `tokenCount`. The build script probes SDK support before enabling these APIs; other builds use the 4096-token on-device limit and estimated token counts.
- Security: `appleFm.bridgePath` is now machine-scoped and read only from user settings, so a workspace's `.vscode/settings.json` can no longer choose the executable that is spawned. The path must be absolute, and only the bundled binary is `chmod`-ed.

## 1.0.0

First public release.

- Adds Apple's on-device Foundation Model (Apple Intelligence) to the Copilot Chat model picker. It runs locally, works offline and is free.
- Prompts are measured with the model's own tokenizer and fit to the 4096-token context window. History is dropped oldest-first, and `appleFm.maxOutputTokens` is kept free for the reply.
- Works in Ask and Agent modes. The model answers in plain text only; it does not call tools.
- Settings: `appleFm.systemPrompt`, `appleFm.temperature`, `appleFm.maxInputTokens`, `appleFm.maxOutputTokens`, `appleFm.bridgePath`.
- Commands: Check Model Availability, Restart Bridge, Show Logs, Open Settings.
