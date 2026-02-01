/*---------------------------------------------------------------------------------------------
 *  Copyright (c) Microsoft Corporation. All rights reserved.
 *--------------------------------------------------------------------------------------------*/

/// GitHub Copilot SDK for Swift
///
/// This SDK provides a Swift interface to the GitHub Copilot CLI, enabling you to
/// embed Copilot's agentic workflows in your iOS and macOS applications.
///
/// ## Quick Start
///
/// ```swift
/// import GitHubCopilotSDK
///
/// // Create a client
/// let client = CopilotClient()
///
/// // Create a session
/// let session = try await client.createSession()
///
/// // Send a message and get the response
/// try await session.send("Hello, Copilot!")
/// let response = try await session.getFinalMessage()
/// print(response)
///
/// // Clean up
/// await client.stop()
/// ```
///
/// ## Custom Tools
///
/// You can define custom tools that Copilot can invoke:
///
/// ```swift
/// let weatherTool = Tool(
///     name: "get_weather",
///     description: "Get the current weather for a location",
///     parameters: JSONSchema.object(
///         properties: [
///             "location": JSONSchema.string(description: "City name")
///         ],
///         required: ["location"]
///     )
/// ) { invocation in
///     let location = invocation.getString("location") ?? "unknown"
///     return .success("The weather in \(location) is sunny!")
/// }
///
/// let session = try await client.createSession(SessionConfig(tools: [weatherTool]))
/// ```
///
/// ## Platform Support
///
/// - iOS 15.0+
/// - macOS 12.0+
/// - tvOS 15.0+
/// - watchOS 8.0+

// Re-export all public types
@_exported import Foundation
