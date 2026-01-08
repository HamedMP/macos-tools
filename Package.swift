// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "macos-tools",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "mac-calendar", targets: ["Calendar"]),
        .executable(name: "mac-notes", targets: ["Notes"]),
        .executable(name: "mac-messages", targets: ["Messages"]),
        .executable(name: "mac-mail", targets: ["Mail"]),
        .executable(name: "mac-contacts", targets: ["ContactsTool"]),
        .executable(name: "mac-focus", targets: ["Focus"]),
        .executable(name: "mac-music", targets: ["Music"]),
        .executable(name: "mac-canvas", targets: ["Canvas"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.3.0"),
        .package(url: "https://github.com/stephencelis/SQLite.swift", from: "0.15.0"),
        .package(url: "https://github.com/apple/swift-markdown", from: "0.3.0"),
    ],
    targets: [
        .executableTarget(name: "Calendar"),
        .executableTarget(
            name: "Notes",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "SQLite", package: "SQLite.swift"),
            ],
            swiftSettings: [.unsafeFlags(["-parse-as-library"])]
        ),
        .executableTarget(
            name: "Messages",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "SQLite", package: "SQLite.swift"),
            ],
            swiftSettings: [.unsafeFlags(["-parse-as-library"])]
        ),
        .executableTarget(
            name: "Mail",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "SQLite", package: "SQLite.swift"),
            ],
            swiftSettings: [.unsafeFlags(["-parse-as-library"])]
        ),
        .executableTarget(name: "ContactsTool"),
        .executableTarget(name: "Focus"),
        .executableTarget(name: "Music"),
        .executableTarget(
            name: "Canvas",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "Markdown", package: "swift-markdown"),
            ],
            swiftSettings: [.unsafeFlags(["-parse-as-library"])]
        ),
    ]
)
