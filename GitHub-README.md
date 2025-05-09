# LibSignalClient

[![Swift Package Manager](https://img.shields.io/badge/SPM-compatible-brightgreen.svg)](https://swift.org/package-manager)
[![Platform](https://img.shields.io/badge/Platforms-iOS%20|%20macOS-blue)](https://developer.apple.com/documentation)
[![License](https://img.shields.io/badge/License-AGPL%203.0-lightgrey)](LICENSE)

A Swift package for the Signal protocol client library.

## Overview

LibSignalClient provides a Swift interface to the Signal protocol, allowing iOS and macOS applications to implement secure messaging using Signal's proven cryptographic protocols.

This package:
- Provides a Swift-friendly API over the Signal protocol Rust implementation
- Supports Swift Concurrency with async/await
- Includes binary distribution via XCFramework
- Fully supports Swift Package Manager for easy integration

## Requirements

- iOS 13.0+ / macOS 10.15+ / watchOS 6.0+ / tvOS 13.0+
- Swift 5.9+
- Xcode 15.0+

## Installation

### Option 1: Swift Package Manager (Recommended)

The Swift Package Manager is a tool for automating the distribution of Swift code and is integrated into the Swift compiler.

To add LibSignalClient to your Swift package, add it as a dependency in your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/yourusername/libsignal-swift.git", from: "1.0.0")
]
```

For app integration with Xcode:

1. Open your project in Xcode
2. Navigate to File > Add Packages
3. Enter the repository URL: `https://github.com/yourusername/libsignal-swift.git`
4. Select the version rule (recommended: "Up to Next Major Version")
5. Click "Add Package"

### Option 2: Manual XCFramework Integration

If you prefer to manually integrate the framework:

1. Download the latest `LibSignalClient.xcframework.zip` from the [Releases](https://github.com/yourusername/libsignal-swift/releases) page
2. Unzip the downloaded file
3. Drag the XCFramework into your Xcode project
4. When prompted, make sure "Copy items if needed" is selected
5. Select your target and go to "General" > "Frameworks, Libraries, and Embedded Content"
6. Make sure the framework is set to "Embed & Sign"

## Quick Start

```swift
import LibSignalClient

// Create an instance
let client = LibSignalClient.shared

// Generate a key pair
do {
    let keyPair = try IdentityKeyPair.generate()
    print("Generated key pair")
    print("Public key: \(keyPair.publicKey.serialize().map { String(format: "%02X", $0) }.joined())")
} catch {
    print("Error generating key pair: \(error)")
}
```

## Documentation

For more detailed information, check out these resources:

- [iOS Integration Guide](docs/ios-integration-guide.md) - Detailed instructions for iOS developers
- [API Documentation](#) - Full API documentation (coming soon)
- [Examples](Examples/) - Sample code showing how to use the library

## Building from Source

If you need to build the package from source, follow these steps:

1. Clone the repository
2. Run the distribution script to build for all platforms:
   ```
   ./package_for_distribution.sh
   ```
3. The distribution package will be created in the `dist` directory
4. You can:
   - Use the Package.swift in the dist directory for Swift Package Manager
   - Use the XCFramework in dist/Frameworks directly in your project

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the AGPL-3.0 License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Based on the [libsignal-client](https://github.com/signalapp/libsignal) Rust implementation
- Special thanks to the Signal team for their work on the protocol 