/*---------------------------------------------------------------------------------------------
 *  Copyright (c) Microsoft Corporation. All rights reserved.
 *--------------------------------------------------------------------------------------------*/

import Foundation

// MARK: - Tool Invocation

/// Context for a tool invocation
public struct ToolInvocation: Sendable {
    /// The session ID where the tool was invoked
    public let sessionId: String
    
    /// The unique ID for this tool call
    public let toolCallId: String
    
    /// The name of the tool being called
    public let toolName: String
    
    /// The arguments passed to the tool (decoded from JSON)
    public let arguments: Any?
    
    public init(sessionId: String, toolCallId: String, toolName: String, arguments: Any?) {
        self.sessionId = sessionId
        self.toolCallId = toolCallId
        self.toolName = toolName
        self.arguments = arguments
    }
    
    /// Decode the arguments as a specific type
    public func decodeArguments<T: Decodable>(_ type: T.Type) throws -> T {
        guard let args = arguments else {
            throw CopilotError.toolError(message: "No arguments provided")
        }
        
        let data = try JSONSerialization.data(withJSONObject: args)
        return try JSONDecoder().decode(type, from: data)
    }
    
    /// Get a string argument by key
    public func getString(_ key: String) -> String? {
        guard let dict = arguments as? [String: Any] else { return nil }
        return dict[key] as? String
    }
    
    /// Get an integer argument by key
    public func getInt(_ key: String) -> Int? {
        guard let dict = arguments as? [String: Any] else { return nil }
        return dict[key] as? Int
    }
    
    /// Get a double argument by key
    public func getDouble(_ key: String) -> Double? {
        guard let dict = arguments as? [String: Any] else { return nil }
        return dict[key] as? Double
    }
    
    /// Get a boolean argument by key
    public func getBool(_ key: String) -> Bool? {
        guard let dict = arguments as? [String: Any] else { return nil }
        return dict[key] as? Bool
    }
    
    /// Get an array argument by key
    public func getArray<T>(_ key: String) -> [T]? {
        guard let dict = arguments as? [String: Any] else { return nil }
        return dict[key] as? [T]
    }
}

// MARK: - Tool Result

/// Binary result returned by a tool
public struct ToolBinaryResult: Codable, Sendable {
    /// Base64-encoded binary data
    public var data: String
    
    /// MIME type of the data
    public var mimeType: String
    
    /// Type identifier
    public var type: String
    
    /// Optional description
    public var description: String?
    
    public init(data: String, mimeType: String, type: String = "binary", description: String? = nil) {
        self.data = data
        self.mimeType = mimeType
        self.type = type
        self.description = description
    }
    
    /// Create a binary result from raw data
    public static func from(data: Data, mimeType: String, description: String? = nil) -> ToolBinaryResult {
        ToolBinaryResult(
            data: data.base64EncodedString(),
            mimeType: mimeType,
            type: "binary",
            description: description
        )
    }
}

/// Result of a tool invocation
public struct ToolResult: Codable, Sendable {
    /// Text result sent to the LLM
    public var textResultForLlm: String
    
    /// Binary results (images, etc.) sent to the LLM
    public var binaryResultsForLlm: [ToolBinaryResult]?
    
    /// Result type: "success", "failure", "rejected", "denied"
    public var resultType: String
    
    /// Internal error message (not exposed to LLM)
    public var error: String?
    
    /// Logging output for the session
    public var sessionLog: String?
    
    /// Telemetry data
    public var toolTelemetry: [String: AnyCodable]?
    
    enum CodingKeys: String, CodingKey {
        case textResultForLlm = "textResultForLlm"
        case binaryResultsForLlm = "binaryResultsForLlm"
        case resultType = "resultType"
        case error = "error"
        case sessionLog = "sessionLog"
        case toolTelemetry = "toolTelemetry"
    }
    
    public init(
        textResultForLlm: String,
        binaryResultsForLlm: [ToolBinaryResult]? = nil,
        resultType: String = "success",
        error: String? = nil,
        sessionLog: String? = nil,
        toolTelemetry: [String: AnyCodable]? = nil
    ) {
        self.textResultForLlm = textResultForLlm
        self.binaryResultsForLlm = binaryResultsForLlm
        self.resultType = resultType
        self.error = error
        self.sessionLog = sessionLog
        self.toolTelemetry = toolTelemetry
    }
    
    /// Create a success result
    public static func success(_ text: String) -> ToolResult {
        ToolResult(textResultForLlm: text, resultType: "success")
    }
    
    /// Create a failure result
    public static func failure(_ text: String, error: String? = nil) -> ToolResult {
        ToolResult(textResultForLlm: text, resultType: "failure", error: error)
    }
    
    /// Create a rejected result (user rejected the operation)
    public static func rejected(_ text: String) -> ToolResult {
        ToolResult(textResultForLlm: text, resultType: "rejected")
    }
    
    /// Create a denied result (permission denied)
    public static func denied(_ text: String) -> ToolResult {
        ToolResult(textResultForLlm: text, resultType: "denied")
    }
}

// MARK: - Tool Definition

/// Handler type for tool invocations
public typealias ToolHandler = @Sendable (ToolInvocation) async throws -> ToolResult

/// Represents a tool that can be invoked by Copilot
public struct Tool: Sendable {
    /// The name of the tool
    public let name: String
    
    /// A description of what the tool does
    public let description: String?
    
    /// JSON Schema for the tool parameters
    public let parameters: [String: Any]
    
    /// The handler function
    public let handler: ToolHandler
    
    /// Create a tool with the given name, description, parameters, and handler
    public init(
        name: String,
        description: String? = nil,
        parameters: [String: Any] = [:],
        handler: @escaping ToolHandler
    ) {
        self.name = name
        self.description = description
        self.parameters = parameters
        self.handler = handler
    }
}

// MARK: - JSON Schema Builder

/// Builder for creating JSON Schema for tool parameters
public struct JSONSchema {
    /// Create an object schema
    public static func object(
        properties: [String: [String: Any]] = [:],
        required: [String] = [],
        additionalProperties: Bool = false
    ) -> [String: Any] {
        var schema: [String: Any] = [
            "type": "object",
            "properties": properties
        ]
        if !required.isEmpty {
            schema["required"] = required
        }
        schema["additionalProperties"] = additionalProperties
        return schema
    }
    
    /// Create a string property
    public static func string(description: String? = nil, enumValues: [String]? = nil) -> [String: Any] {
        var property: [String: Any] = ["type": "string"]
        if let desc = description {
            property["description"] = desc
        }
        if let values = enumValues {
            property["enum"] = values
        }
        return property
    }
    
    /// Create a number property
    public static func number(description: String? = nil, minimum: Double? = nil, maximum: Double? = nil) -> [String: Any] {
        var property: [String: Any] = ["type": "number"]
        if let desc = description {
            property["description"] = desc
        }
        if let min = minimum {
            property["minimum"] = min
        }
        if let max = maximum {
            property["maximum"] = max
        }
        return property
    }
    
    /// Create an integer property
    public static func integer(description: String? = nil, minimum: Int? = nil, maximum: Int? = nil) -> [String: Any] {
        var property: [String: Any] = ["type": "integer"]
        if let desc = description {
            property["description"] = desc
        }
        if let min = minimum {
            property["minimum"] = min
        }
        if let max = maximum {
            property["maximum"] = max
        }
        return property
    }
    
    /// Create a boolean property
    public static func boolean(description: String? = nil) -> [String: Any] {
        var property: [String: Any] = ["type": "boolean"]
        if let desc = description {
            property["description"] = desc
        }
        return property
    }
    
    /// Create an array property
    public static func array(items: [String: Any], description: String? = nil) -> [String: Any] {
        var property: [String: Any] = [
            "type": "array",
            "items": items
        ]
        if let desc = description {
            property["description"] = desc
        }
        return property
    }
}

// MARK: - Tool Builder (Result Builder)

/// Result builder for creating tools with a fluent syntax
@resultBuilder
public struct ToolBuilder {
    public static func buildBlock(_ components: ToolProperty...) -> [String: [String: Any]] {
        var properties: [String: [String: Any]] = [:]
        for component in components {
            properties[component.name] = component.schema
        }
        return properties
    }
}

/// A property in a tool's parameter schema
public struct ToolProperty {
    let name: String
    let schema: [String: Any]
    let isRequired: Bool
    
    public init(name: String, schema: [String: Any], required: Bool = false) {
        self.name = name
        self.schema = schema
        self.isRequired = required
    }
}

// MARK: - Convenience Extensions

extension Tool {
    /// Create a simple tool that takes no parameters
    public static func simple(
        name: String,
        description: String? = nil,
        handler: @escaping @Sendable () async throws -> String
    ) -> Tool {
        Tool(
            name: name,
            description: description,
            parameters: JSONSchema.object()
        ) { _ in
            let result = try await handler()
            return .success(result)
        }
    }
    
    /// Create a tool with typed arguments
    public static func typed<Args: Decodable>(
        name: String,
        description: String? = nil,
        parameters: [String: Any],
        handler: @escaping @Sendable (Args, ToolInvocation) async throws -> ToolResult
    ) -> Tool {
        Tool(
            name: name,
            description: description,
            parameters: parameters
        ) { invocation in
            let args: Args = try invocation.decodeArguments(Args.self)
            return try await handler(args, invocation)
        }
    }
}

// MARK: - Tool Serialization

extension Tool {
    /// Convert the tool to a dictionary for JSON-RPC serialization
    func toRPCParams() -> [String: Any] {
        var params: [String: Any] = ["name": name]
        if let description = description {
            params["description"] = description
        }
        if !parameters.isEmpty {
            params["parameters"] = parameters
        }
        return params
    }
}

extension Array where Element == Tool {
    /// Convert tools to RPC params format
    func toRPCParams() -> [[String: Any]] {
        map { $0.toRPCParams() }
    }
}
