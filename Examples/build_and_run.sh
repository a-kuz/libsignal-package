#!/bin/bash
set -e

# Go to the root directory of the project
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR/.."

echo "Building and running the Signal Protocol example..."

# Create a basic Swift Package for our example
cat > Examples/Package.swift << EOF
// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "SignalExample",
    platforms: [.macOS(.v10_15)],
    dependencies: [
        .package(path: "..")
    ],
    targets: [
        .executableTarget(
            name: "SignalExample",
            dependencies: [
                .product(name: "LibSignalClient", package: "libsignal-swift")
            ],
            path: "."
        )
    ]
)
EOF

# Check if pre-built libsignal_ffi.a exists or if we need to build it
if [ ! -f "target/debug/libsignal_ffi.a" ]; then
    echo "Building libsignal_ffi.a using the real build script..."
    cd libsignal
    ./swift/build_ffi.sh
    cd -
    
    # The file will be in libsignal/target/debug, let's symlink it to our target dir
    mkdir -p target/debug
    ln -sf "$PWD/libsignal/target/debug/libsignal_ffi.a" "$PWD/target/debug/libsignal_ffi.a"
    echo "Library built and linked to target/debug/libsignal_ffi.a"
fi

# Make directory for the build if it doesn't exist
mkdir -p .build

# Build the example
cd Examples
swift build || {
    echo "Build failed. There might be issues with the FFI library or Swift code."
    echo "Check the error messages above for more details."
    exit 1
}

# Run the example
swift run || {
    echo "Run failed. There might be issues with the built executable."
    echo "Check the error messages above for more details."
    exit 1
}

echo "Example completed!" 