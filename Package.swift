// swift-tools-version:5.9

//
// Copyright 2020-2023 Signal Messenger, LLC.
// SPDX-License-Identifier: AGPL-3.0-only
//

import PackageDescription

let package = Package(
    name: "LibSignalClient",
    platforms: [
        .macOS(.v10_15), .iOS(.v13),
    ],
    products: [
        .library(
            name: "LibSignalClient",
            targets: ["LibSignalClient"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "LibSignalClient"
        )
    ]
) 