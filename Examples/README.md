# LibSignalClient Examples

This directory contains example projects demonstrating how to use the LibSignalClient package in real-world scenarios.

## Examples List

1. **BasicExample** - A simple command-line application demonstrating the basic functionality of the library
2. **iOS Sample App** - A simple iOS application showcasing the integration of LibSignalClient (coming soon)

## Running the Examples

### BasicExample

To run the BasicExample:

1. Make sure you've built the Rust FFI library:
   ```
   RUSTUP_TOOLCHAIN=nightly ./libsignal/swift/build_ffi.sh --release
   ```

2. Run the example using the build_and_run.sh script:
   ```
   cd Examples
   ./build_and_run.sh
   ```

## Creating Your Own Projects

When creating your own project using LibSignalClient, you can use either Swift Package Manager or manually integrate the XCFramework:

### Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/yourusername/libsignal-swift.git", from: "1.0.0")
]
```

### Manual Integration

1. Download the LibSignalClient.xcframework from the [Releases](https://github.com/yourusername/libsignal-swift/releases) page
2. Add it to your Xcode project
3. Make sure it's set to "Embed & Sign" in your target's Build Settings

For more details, see the [iOS Integration Guide](../docs/ios-integration-guide.md). 