#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$SCRIPT_DIR"
JNI_DIR="$PROJECT_DIR/jni"
OUTPUT_BINARY="a9_eink_server"

# --- Determine NDK path ---
if [ -n "$1" ]; then
    NDK_PATH="$1"
elif command -v ndk-build &>/dev/null; then
    # ndk-build is already in PATH; resolve its directory
    NDK_PATH="$(dirname "$(command -v ndk-build)")"
    echo "Found ndk-build in PATH: $NDK_PATH"
elif [ -n "$ANDROID_NDK_HOME" ]; then
    NDK_PATH="$ANDROID_NDK_HOME"
    echo "Using ANDROID_NDK_HOME: $NDK_PATH"
elif [ -n "$ANDROID_NDK_ROOT" ]; then
    NDK_PATH="$ANDROID_NDK_ROOT"
    echo "Using ANDROID_NDK_ROOT: $NDK_PATH"
elif [ -n "$NDK_HOME" ]; then
    NDK_PATH="$NDK_HOME"
    echo "Using NDK_HOME: $NDK_PATH"
else
    echo "Error: NDK path not provided and ndk-build not found in PATH."
    echo "Usage: $0 [/path/to/android-ndk]"
    exit 1
fi

# --- Validate NDK path ---
NDK_BUILD="$NDK_PATH/ndk-build"
if [ ! -x "$NDK_BUILD" ]; then
    echo "Error: ndk-build not found or not executable at: $NDK_BUILD"
    exit 1
fi

echo "Using NDK at: $NDK_PATH"

# --- Ensure jni/ directory structure exists ---
if [ ! -d "$JNI_DIR" ]; then
    echo "Error: jni/ directory not found at $JNI_DIR"
    echo "Please place Android.mk and eink_daemon.c inside jni/"
    exit 1
fi

if [ ! -f "$JNI_DIR/Android.mk" ]; then
    echo "Error: Android.mk not found in $JNI_DIR"
    exit 1
fi

if [ ! -f "$JNI_DIR/eink_daemon.c" ]; then
    echo "Error: eink_daemon.c not found in $JNI_DIR"
    exit 1
fi

# --- Clean previous build ---
echo "Cleaning previous build..."
"$NDK_BUILD" -C "$PROJECT_DIR" clean 2>/dev/null || true

# --- Build ---
echo "Building $OUTPUT_BINARY..."
"$NDK_BUILD" -C "$PROJECT_DIR"

# --- Move binary to script root directory ---
BUILT_BINARY="$PROJECT_DIR/libs/$TARGET_ABI/$OUTPUT_BINARY"
if [ -f "$BUILT_BINARY" ]; then
    cp "$BUILT_BINARY" "$SCRIPT_DIR/$OUTPUT_BINARY"
    echo ""
    echo "Build successful!"
    echo "Binary copied to: $SCRIPT_DIR/$OUTPUT_BINARY"
else
    echo "Error: Built binary not found at $BUILT_BINARY"
    exit 1
fi
