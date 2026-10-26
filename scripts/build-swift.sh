#!/usr/bin/env bash
# Builds the Swift bridge (Apple Silicon, macOS 26+, Xcode 26+) and copies it to ./bin/fm-bridge
set -euo pipefail
cd "$(dirname "$0")/../swift"
BUILD_ARGS=(-c release --arch arm64)
# Runtime availability checks cannot hide declarations missing from the selected SDK.
if swiftc -typecheck -target arm64-apple-macos26.0 - >/dev/null 2>&1 <<'SWIFT'
import FoundationModels
func check() async throws {
    _ = SystemLanguageModel.default.contextSize
    if #available(macOS 26.4, *) {
        _ = try await SystemLanguageModel.default.tokenCount(for: "test")
        _ = try await SystemLanguageModel.default.tokenCount(for: Instructions("test"))
    }
}
SWIFT
then
    BUILD_ARGS+=(-Xswiftc -DFM_TOKEN_APIS)
    echo "Using the model's context-size and token-count APIs."
else
    echo "Token APIs unavailable in the selected SDK; using a 4096-token window and estimated counts."
fi
swift build "${BUILD_ARGS[@]}"
BIN_DIR="$(swift build "${BUILD_ARGS[@]}" --show-bin-path)"
mkdir -p ../bin
cp "$BIN_DIR/fm-bridge" ../bin/fm-bridge
chmod +x ../bin/fm-bridge
echo "Built ../bin/fm-bridge"
"../bin/fm-bridge" --check || true
