// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "AppStoreIAPClient",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "AppStoreIAPClient", targets: ["AppStoreIAPClient"])
    ],
    targets: [
        .target(name: "AppStoreIAPClientCore"),
        .executableTarget(
            name: "AppStoreIAPClient",
            dependencies: ["AppStoreIAPClientCore"],
            resources: [
                .copy("Resources")
            ]
        ),
        .executableTarget(
            name: "AppStoreIAPClientSmoke",
            dependencies: ["AppStoreIAPClientCore"]
        ),
        .executableTarget(
            name: "AppStoreIAPClientUnitTests",
            dependencies: ["AppStoreIAPClientCore"]
        )
    ]
)
