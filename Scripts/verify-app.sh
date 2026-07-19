#!/bin/bash
set -euo pipefail

FAILURES=0

for app in .build/dist/*.app; do
    echo "─────────────────────────────────────────"
    echo "Verifying: $(basename "$app")"

    # Check directory structure
    for item in "Contents/MacOS" "Contents/Resources" "Contents/Info.plist"; do
        if [ -e "$app/$item" ]; then
            echo "  ✅ $item exists"
        else
            echo "  ❌ $item missing"
            FAILURES=$((FAILURES + 1))
        fi
    done

    # Check executable is a Mach-O file
    APP_NAME="$(basename "$app" .app)"
    EXEC_PATH="$app/Contents/MacOS/$APP_NAME"
    if [ -f "$EXEC_PATH" ]; then
        if file "$EXEC_PATH" | grep -q "Mach-O"; then
            echo "  ✅ Executable is a Mach-O file"
        else
            echo "  ❌ Executable is not a Mach-O file"
            FAILURES=$((FAILURES + 1))
        fi
    else
        echo "  ❌ Executable not found: $EXEC_PATH"
        FAILURES=$((FAILURES + 1))
    fi

    # Check Info.plist validity
    if plutil -lint "$app/Contents/Info.plist" > /dev/null 2>&1; then
        echo "  ✅ Info.plist is valid"
    else
        echo "  ❌ Info.plist is invalid"
        FAILURES=$((FAILURES + 1))
    fi

    # Check code signature
    if codesign --verify --deep "$app" > /dev/null 2>&1; then
        echo "  ✅ App has a valid signature"
    else
        echo "  ❌ App signature verification failed"
        FAILURES=$((FAILURES + 1))
    fi
done

echo "─────────────────────────────────────────"
if [ "$FAILURES" -eq 0 ]; then
    echo "✅ All checks passed."
else
    echo "❌ $FAILURES check(s) failed."
    exit 1
fi
