#!/bin/bash
set -euo pipefail

# Default to release; override with BUILD_CONFIG=debug for development.
BUILD_DIR=".build/${BUILD_CONFIG:-release}"

# ── AudiobookStudio ───────────────────────────────────────────

mkdir -p .build/dist/AudiobookStudio.app/Contents/MacOS
mkdir -p .build/dist/AudiobookStudio.app/Contents/Resources

cp "$BUILD_DIR/AudiobookStudio" \
   .build/dist/AudiobookStudio.app/Contents/MacOS/AudiobookStudio

cp Resources/StudioInfo.plist \
   .build/dist/AudiobookStudio.app/Contents/Info.plist

codesign --force --deep --sign - .build/dist/AudiobookStudio.app

# ── AudiobookModelLab ─────────────────────────────────────────

mkdir -p .build/dist/AudiobookModelLab.app/Contents/MacOS
mkdir -p .build/dist/AudiobookModelLab.app/Contents/Resources
mkdir -p .build/dist/AudiobookModelLab.app/Contents/Frameworks

# Copy MLX Metal shader library.
METALLIB=$(find .build -name "default.metallib" -path "*/${BUILD_CONFIG:-release}/*" -type f 2>/dev/null | head -1)
if [ -n "$METALLIB" ] && [ -f "$METALLIB" ]; then
    cp "$METALLIB" .build/dist/AudiobookModelLab.app/Contents/MacOS/mlx.metallib
fi

cp "$BUILD_DIR/AudiobookModelLab" \
   .build/dist/AudiobookModelLab.app/Contents/MacOS/AudiobookModelLab

cp Resources/ModelLabInfo.plist \
   .build/dist/AudiobookModelLab.app/Contents/Info.plist

# Bundle llama.framework from LocalLLMClient
LLAMA_XCFRAMEWORK=".build/artifacts/localllmclient/LocalLLMClientLlamaFramework/llama.xcframework"
if [ -d "$LLAMA_XCFRAMEWORK/macos-arm64_x86_64/llama.framework" ]; then
    cp -R "$LLAMA_XCFRAMEWORK/macos-arm64_x86_64/llama.framework" \
       .build/dist/AudiobookModelLab.app/Contents/Frameworks/
    install_name_tool -add_rpath @executable_path/../Frameworks \
       .build/dist/AudiobookModelLab.app/Contents/MacOS/AudiobookModelLab 2>/dev/null || true
fi

codesign --force --deep --sign - .build/dist/AudiobookModelLab.app

echo "✅ Built AudiobookStudio.app and AudiobookModelLab.app"
