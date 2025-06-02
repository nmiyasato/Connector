// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Connector",
    platforms: [
        .iOS(.v16), .macOS(.v10_15)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "Connector",
            targets: ["Connector"]),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "Connector",
            plugins: [
                .plugin(name: "RunMockolo"),
            ]
        ),
        .testTarget(
            name: "ConnectorTests",
            dependencies: ["Connector"],
            resources: [
                .copy("../../.build/pluginWorkDirectory/GeneratedMocks.swift") // Include generated mocks
            ])
        ,
        .plugin(
            name: "RunMockolo",
            capability: .buildTool(),
            dependencies: [.target(name: "mockolo")]
        ),
        .binaryTarget(
            name: "mockolo",
            url: "https://github.com/uber/mockolo/releases/download/2.4.0/mockolo.artifactbundle.zip",
            checksum: "740787a5c532dc1a16e9b6940c7ef844caa1f7c02cb85b740e4f44f49a25dc68"
        )
    ]
)
