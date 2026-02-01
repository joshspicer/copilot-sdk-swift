// swift-tools-version: 5.9
/*---------------------------------------------------------------------------------------------
 *  Copyright (c) Microsoft Corporation. All rights reserved.
 *--------------------------------------------------------------------------------------------*/

import PackageDescription

let package = Package(
    name: "github-copilot-sdk",
    platforms: [
        .iOS(.v15),
        .macOS(.v12),
        .tvOS(.v15),
        .watchOS(.v8)
    ],
    products: [
        .library(
            name: "GitHubCopilotSDK",
            targets: ["GitHubCopilotSDK"]
        ),
    ],
    targets: [
        .target(
            name: "GitHubCopilotSDK",
            path: "Sources/GitHubCopilotSDK"
        ),
        .testTarget(
            name: "GitHubCopilotSDKTests",
            dependencies: ["GitHubCopilotSDK"],
            path: "Tests/GitHubCopilotSDKTests"
        ),
    ]
)
