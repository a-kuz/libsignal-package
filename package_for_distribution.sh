#!/bin/bash

set -e

# Build the Rust FFI library for all supported platforms
echo "Building Rust FFI library for all platforms..."
mkdir -p build

# Build for iOS
echo "Building for iOS..."
RUSTUP_TOOLCHAIN=nightly CARGO_BUILD_TARGET=aarch64-apple-ios ./libsignal/swift/build_ffi.sh --release
mkdir -p build/ios
cp libsignal/target/aarch64-apple-ios/release/libsignal_ffi.a build/ios/

# Build for iOS Simulator
echo "Building for iOS Simulator..."
RUSTUP_TOOLCHAIN=nightly CARGO_BUILD_TARGET=aarch64-apple-ios-sim ./libsignal/swift/build_ffi.sh --release
mkdir -p build/ios-simulator
cp libsignal/target/aarch64-apple-ios-sim/release/libsignal_ffi.a build/ios-simulator/

# Build for macOS
echo "Building for macOS..."
RUSTUP_TOOLCHAIN=nightly CARGO_BUILD_TARGET=x86_64-apple-darwin ./libsignal/swift/build_ffi.sh --release
mkdir -p build/macos
cp libsignal/target/x86_64-apple-darwin/release/libsignal_ffi.a build/macos/

# Create temporary frameworks for each platform
echo "Creating frameworks for each platform..."

# Helper function to create a framework for a platform
create_framework() {
    PLATFORM=$1
    IDENTIFIER=$2
    MIN_VERSION=$3
    FRAMEWORK_PATH="build/LibSignalClient-$PLATFORM.framework"
    
    mkdir -p "$FRAMEWORK_PATH/Modules"
    mkdir -p "$FRAMEWORK_PATH/Headers"
    
    # Copy headers
    cp -r Sources/LibSignalClient/include/* "$FRAMEWORK_PATH/Headers/"
    
    # Create module map
    cat > "$FRAMEWORK_PATH/Modules/module.modulemap" << EOF
framework module LibSignalClient {
    umbrella header "LibSignalClient.h"
    export *
    module * { export * }
}
EOF
    
    # Copy library
    cp "build/$PLATFORM/libsignal_ffi.a" "$FRAMEWORK_PATH/LibSignalClient"
    
    # Create Info.plist
    cat > "$FRAMEWORK_PATH/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>LibSignalClient</string>
    <key>CFBundleIdentifier</key>
    <string>org.signal.libsignal.$IDENTIFIER</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>LibSignalClient</string>
    <key>CFBundlePackageType</key>
    <string>FMWK</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>MinimumOSVersion</key>
    <string>$MIN_VERSION</string>
</dict>
</plist>
EOF
}

# Create framework for each platform
create_framework "ios" "ios" "13.0"
create_framework "ios-simulator" "ios-simulator" "13.0"
create_framework "macos" "macos" "10.15"

# Create XCFramework
echo "Creating XCFramework..."
rm -rf LibSignalClient.xcframework

xcodebuild -create-xcframework \
    -framework "build/LibSignalClient-ios.framework" \
    -framework "build/LibSignalClient-ios-simulator.framework" \
    -framework "build/LibSignalClient-macos.framework" \
    -output "LibSignalClient.xcframework"

# Prepare Swift Package for distribution
echo "Preparing Swift Package for distribution..."
DIST_DIR="dist"
rm -rf $DIST_DIR
mkdir -p $DIST_DIR

# Copy XCFramework to Package structure
mkdir -p $DIST_DIR/Frameworks
cp -r LibSignalClient.xcframework $DIST_DIR/Frameworks/

# Create binary target Package.swift
cat > $DIST_DIR/Package.swift << EOF
// swift-tools-version:5.9

import PackageDescription

let package = Package(
    name: "LibSignalClient",
    platforms: [
        .macOS(.v10_15), 
        .iOS(.v13),
        .watchOS(.v6),
        .tvOS(.v13),
    ],
    products: [
        .library(
            name: "LibSignalClient",
            targets: ["LibSignalClient"]
        ),
    ],
    targets: [
        .binaryTarget(
            name: "LibSignalClient",
            path: "Frameworks/LibSignalClient.xcframework"
        )
    ]
)
EOF

# Copy README
cp README.md $DIST_DIR/
cp LICENSE $DIST_DIR/ 2>/dev/null || echo "No LICENSE file found, please add one"

echo "Distribution package created in $DIST_DIR directory"
echo "Done!" 