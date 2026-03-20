// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "StayMemo",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "StayMemo",
            path: "Sources/StayMemo",
            exclude: ["Info.plist"]
        )
    ]
)
