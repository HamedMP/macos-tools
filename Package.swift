// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "macos-tools",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "mac-reminders", targets: ["Reminders"]),
        .executable(name: "mac-notes", targets: ["Notes"]),
        .executable(name: "mac-contacts", targets: ["ContactsTool"]),
        .executable(name: "mac-focus", targets: ["Focus"]),
        .executable(name: "mac-music", targets: ["Music"]),
    ],
    targets: [
        .executableTarget(name: "Reminders"),
        .executableTarget(name: "Notes"),
        .executableTarget(name: "ContactsTool"),
        .executableTarget(name: "Focus"),
        .executableTarget(name: "Music"),
    ]
)
