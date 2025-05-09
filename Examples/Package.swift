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
