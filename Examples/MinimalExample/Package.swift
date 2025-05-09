// swift-tools-version:5.9

import PackageDescription

let package = Package(
    name: "MinimalExample",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v13),
    ],
    products: [
        .executable(
            name: "MinimalExample",
            targets: ["MinimalExample"]
        ),
    ],
    dependencies: [
        // Use the local path to the LibSignalClient package
        .package(path: "../../"),
    ],
    targets: [
        .executableTarget(
            name: "MinimalExample",
            dependencies: [
                .product(name: "LibSignalClient", package: "SimplifiedLibSignalClient")
            ]
        ),
    ]
) 