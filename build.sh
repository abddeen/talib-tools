#!/usr/bin/env bash
set -e

APP_NAME="TalibTools"
BUILD_DIR="build"
APP_BUNDLE="${BUILD_DIR}/${APP_NAME}.app"
CONTENTS_DIR="${APP_BUNDLE}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
RESOURCES_DIR="${CONTENTS_DIR}/Resources"
MODULE_CACHE="/tmp/ModuleCache"

mkdir -p "${MODULE_CACHE}"

build_app() {
    echo "🔨 Building ${APP_NAME}..."
    
    mkdir -p "${MACOS_DIR}"
    mkdir -p "${RESOURCES_DIR}"
    
    # Copy Info.plist
    cp "Sources/TalibTools/Resources/Info.plist" "${CONTENTS_DIR}/Info.plist"
    
    # Copy app icon
    cp "Sources/TalibTools/Resources/AppIcon.icns" "${RESOURCES_DIR}/AppIcon.icns"
    
    # Find all Swift files
    SWIFT_FILES=$(find Sources/TalibTools -name "*.swift")
    
    # Compile with swiftc
    CLANG_MODULE_CACHE_PATH="${MODULE_CACHE}" swiftc \
        -parse-as-library \
        -module-cache-path "${MODULE_CACHE}" \
        -target arm64-apple-macosx14.0 \
        -O \
        -framework Cocoa \
        -framework SwiftUI \
        -framework Carbon \
        -framework Vision \
        -framework NaturalLanguage \
        -framework AVFoundation \
        ${SWIFT_FILES} \
        -o "${MACOS_DIR}/${APP_NAME}"
    
    # Ad-hoc code sign for macOS local execution
    codesign --force --deep --sign - "${APP_BUNDLE}" 2>/dev/null || true
    
    echo "✅ Successfully built: ${APP_BUNDLE}"
}

run_app() {
    build_app
    echo "🚀 Launching ${APP_NAME}..."
    open "${APP_BUNDLE}"
}

install_app() {
    build_app
    echo "📦 Installing ${APP_NAME} to /Applications..."
    cp -R "${APP_BUNDLE}" "/Applications/"
    echo "✅ Installed to /Applications/${APP_NAME}.app"
}

clean_app() {
    echo "🧹 Cleaning ${BUILD_DIR}..."
    rm -rf "${BUILD_DIR}"
    echo "✅ Cleaned"
}

case "$1" in
    run)
        run_app
        ;;
    install)
        install_app
        ;;
    clean)
        clean_app
        ;;
    *)
        build_app
        ;;
esac
