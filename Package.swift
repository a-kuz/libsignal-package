// swift-tools-version:5.9

//
// Copyright 2020-2021 Signal Messenger, LLC.
// SPDX-License-Identifier: AGPL-3.0-only
//

import PackageDescription
import Foundation

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
    dependencies: [
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.4.3"),
    ],
    targets: [
        // Local development targets
        .systemLibrary(
            name: "SignalFfi",
            pkgConfig: "libsignal_ffi",
            providers: [
                .brew(["libsignal-client"]),
            ]
        ),
        .target(
            name: "LibSignalClient",
            dependencies: ["SignalFfi"],
            swiftSettings: [.enableExperimentalFeature("StrictConcurrency")]
        ),
        .executableTarget(
            name: "SignalDemo",
            dependencies: ["LibSignalClient"]
        ),
        .testTarget(
            name: "LibSignalClientTests",
            dependencies: ["LibSignalClient"],
            resources: [.process("Resources")],
            swiftSettings: [.enableExperimentalFeature("StrictConcurrency")]
        ),
    ]
)
