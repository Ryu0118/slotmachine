// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "slotmachine",
    platforms: [
        .macOS(.v15),
    ],
    products: [
        .executable(name: "slotmachine", targets: ["slotmachine"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.7.1"),
        .package(url: "https://github.com/Ryu0118/SlotKit", from: "0.4.0"),
    ],
    targets: [
        .executableTarget(
            name: "slotmachine",
            dependencies: [
                "SlotMachineCore",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "SlotKit", package: "SlotKit"),
            ],
        ),
        .target(
            name: "SlotMachineCore",
        ),
        .testTarget(
            name: "SlotMachineCoreTests",
            dependencies: [
                "SlotMachineCore",
            ],
        ),
    ],
)
