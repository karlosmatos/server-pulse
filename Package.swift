// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ServerPulse",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "ServerPulse",
            path: "Sources/ServerPulse",
            linkerSettings: [
                .unsafeFlags([
                    "-Xlinker", "-sectcreate",
                    "-Xlinker", "__TEXT",
                    "-Xlinker", "__info_plist",
                    "-Xlinker", "Resources/Info.plist"
                ])
            ]
        )
    ]
)
