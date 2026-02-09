// swift-tools-version:5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AICLIDashboard",
    platforms: [
        .macOS(.v13) // Ventura, supports M3+
    ],
    products: [
        .executable(name: "AICLIDashboard", targets: ["AICLIDashboard"])
    ],
    targets: [
        .executableTarget(
            name: "AICLIDashboard",
            path: "AICLIDashboard"
        ),
        .testTarget(
            name: "AICLIDashboardTests",
            dependencies: ["AICLIDashboard"],
            path: "AICLIDashboardTests"
        )
    ]
)
