/*---------------------------------------------------------------------------------------------
 *  Copyright (c) Microsoft Corporation. All rights reserved.
 *--------------------------------------------------------------------------------------------*/

import Foundation

// MARK: - Connection State

/// Represents the client connection state
public enum ConnectionState: String, Codable, Sendable {
    case disconnected
    case connecting
    case connected
    case error
}

// MARK: - Client Options

/// Configuration options for the CopilotClient
public struct CopilotClientOptions: Sendable {
    /// Path to the Copilot CLI executable (default: "copilot")
    public var cliPath: String
    
    /// Working directory for the CLI process (default: current directory)
    public var cwd: String?
    
    /// Port for TCP transport (default: 0 = random port)
    public var port: Int
    
    /// Whether to use stdio transport instead of TCP (default: true)
    public var useStdio: Bool
    
    /// URL of an existing Copilot CLI server to connect to over TCP.
    /// Format: "host:port", "http://host:port", or just "port" (defaults to localhost)
    /// Mutually exclusive with cliPath, useStdio
    public var cliUrl: String?
    
    /// Log level for the CLI server
    public var logLevel: String
    
    /// Automatically start the CLI server on first use (default: true)
    public var autoStart: Bool
    
    /// Automatically restart the CLI server if it crashes (default: true)
    public var autoRestart: Bool
    
    /// Environment variables for the CLI process
    public var environment: [String: String]?
    
    /// GitHub token to use for authentication.
    /// When provided, the token is passed to the CLI server via environment variable.
    /// This takes priority over other authentication methods.
    public var githubToken: String?
    
    /// Whether to use the logged-in user for authentication.
    /// When true, the CLI server will attempt to use stored OAuth tokens or gh CLI auth.
    /// When false, only explicit tokens (githubToken or environment variables) are used.
    /// Default: true (but defaults to false when githubToken is provided)
    public var useLoggedInUser: Bool?
    
    public init(
        cliPath: String = "copilot",
        cwd: String? = nil,
        port: Int = 0,
        useStdio: Bool = true,
        cliUrl: String? = nil,
        logLevel: String = "info",
        autoStart: Bool = true,
        autoRestart: Bool = true,
        environment: [String: String]? = nil,
        githubToken: String? = nil,
        useLoggedInUser: Bool? = nil
    ) {
        self.cliPath = cliPath
        self.cwd = cwd
        self.port = port
        self.useStdio = useStdio
        self.cliUrl = cliUrl
        self.logLevel = logLevel
        self.autoStart = autoStart
        self.autoRestart = autoRestart
        self.environment = environment
        self.githubToken = githubToken
        self.useLoggedInUser = useLoggedInUser
    }
}

// MARK: - System Message Configuration

/// Mode for system message configuration
public enum SystemMessageMode: String, Codable, Sendable {
    /// Append mode: use CLI foundation with optional appended content
    case append
    /// Replace mode: use caller-provided system message entirely
    case replace
}

/// System message configuration for session creation
public struct SystemMessageConfig: Codable, Sendable {
    /// The mode for system message handling
    public var mode: SystemMessageMode?
    
    /// Content for the system message
    public var content: String?
    
    public init(mode: SystemMessageMode? = nil, content: String? = nil) {
        self.mode = mode
        self.content = content
    }
    
    /// Creates an append configuration with optional additional content
    public static func append(content: String? = nil) -> SystemMessageConfig {
        SystemMessageConfig(mode: .append, content: content)
    }
    
    /// Creates a replace configuration with the complete system message
    public static func replace(content: String) -> SystemMessageConfig {
        SystemMessageConfig(mode: .replace, content: content)
    }
}

// MARK: - Provider Configuration

/// Azure-specific provider options
public struct AzureProviderOptions: Codable, Sendable {
    /// Azure API version (default: "2024-10-21")
    public var apiVersion: String?
    
    public init(apiVersion: String? = nil) {
        self.apiVersion = apiVersion
    }
}

/// Configuration for a custom model provider (BYOK)
public struct ProviderConfig: Codable, Sendable {
    /// Provider type: "openai", "azure", or "anthropic" (default: "openai")
    public var type: String?
    
    /// API format (openai/azure only): "completions" or "responses" (default: "completions")
    public var wireApi: String?
    
    /// API endpoint URL
    public var baseUrl: String
    
    /// API key (optional for local providers like Ollama)
    public var apiKey: String?
    
    /// Bearer token for authentication.
    /// Use this for services requiring bearer token auth instead of API key.
    /// Takes precedence over apiKey when both are set.
    public var bearerToken: String?
    
    /// Azure-specific options
    public var azure: AzureProviderOptions?
    
    public init(
        baseUrl: String,
        type: String? = nil,
        wireApi: String? = nil,
        apiKey: String? = nil,
        bearerToken: String? = nil,
        azure: AzureProviderOptions? = nil
    ) {
        self.baseUrl = baseUrl
        self.type = type
        self.wireApi = wireApi
        self.apiKey = apiKey
        self.bearerToken = bearerToken
        self.azure = azure
    }
}

// MARK: - MCP Server Configuration

/// Configuration for a local/stdio MCP server
public struct McpLocalServerConfig: Codable, Sendable {
    /// List of tools to include from this server. Empty means none. Use ["*"] for all.
    public var tools: [String]
    
    /// Server type. Defaults to "local".
    public var type: String?
    
    /// Optional timeout in milliseconds for tool calls to this server
    public var timeout: Int?
    
    /// Command to run the MCP server
    public var command: String
    
    /// Arguments to pass to the command
    public var args: [String]
    
    /// Environment variables to pass to the server
    public var env: [String: String]?
    
    /// Working directory for the server process
    public var cwd: String?
    
    public init(
        command: String,
        args: [String] = [],
        tools: [String] = ["*"],
        type: String? = nil,
        timeout: Int? = nil,
        env: [String: String]? = nil,
        cwd: String? = nil
    ) {
        self.command = command
        self.args = args
        self.tools = tools
        self.type = type
        self.timeout = timeout
        self.env = env
        self.cwd = cwd
    }
}

/// Configuration for a remote MCP server (HTTP or SSE)
public struct McpRemoteServerConfig: Codable, Sendable {
    /// List of tools to include from this server. Empty means none. Use ["*"] for all.
    public var tools: [String]
    
    /// Server type. Must be "http" or "sse".
    public var type: String
    
    /// Optional timeout in milliseconds for tool calls to this server
    public var timeout: Int?
    
    /// URL of the remote server
    public var url: String
    
    /// Optional HTTP headers to include in requests
    public var headers: [String: String]?
    
    public init(
        url: String,
        type: String = "http",
        tools: [String] = ["*"],
        timeout: Int? = nil,
        headers: [String: String]? = nil
    ) {
        self.url = url
        self.type = type
        self.tools = tools
        self.timeout = timeout
        self.headers = headers
    }
}

/// Type-erased MCP server configuration
public enum McpServerConfig: Codable, Sendable {
    case local(McpLocalServerConfig)
    case remote(McpRemoteServerConfig)
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let local = try? container.decode(McpLocalServerConfig.self), local.command.isEmpty == false {
            self = .local(local)
        } else if let remote = try? container.decode(McpRemoteServerConfig.self) {
            self = .remote(remote)
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid MCP server config")
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .local(let config):
            try container.encode(config)
        case .remote(let config):
            try container.encode(config)
        }
    }
}

// MARK: - Custom Agent Configuration

/// Configuration for a custom agent
public struct CustomAgentConfig: Codable, Sendable {
    /// Unique name of the custom agent
    public var name: String
    
    /// Display name for UI purposes
    public var displayName: String?
    
    /// Description of what the agent does
    public var description: String?
    
    /// List of tool names the agent can use. nil for all tools.
    public var tools: [String]?
    
    /// The prompt content for the agent
    public var prompt: String
    
    /// MCP servers specific to this agent
    public var mcpServers: [String: AnyCodable]?
    
    /// Whether the agent should be available for model inference
    public var infer: Bool?
    
    public init(
        name: String,
        prompt: String,
        displayName: String? = nil,
        description: String? = nil,
        tools: [String]? = nil,
        mcpServers: [String: AnyCodable]? = nil,
        infer: Bool? = nil
    ) {
        self.name = name
        self.prompt = prompt
        self.displayName = displayName
        self.description = description
        self.tools = tools
        self.mcpServers = mcpServers
        self.infer = infer
    }
}

// MARK: - Infinite Session Configuration

/// Configuration for infinite sessions with automatic context compaction and workspace persistence
public struct InfiniteSessionConfig: Codable, Sendable {
    /// Whether infinite sessions are enabled (default: true)
    public var enabled: Bool?
    
    /// Context utilization (0.0-1.0) at which background compaction starts (default: 0.80)
    public var backgroundCompactionThreshold: Double?
    
    /// Context utilization (0.0-1.0) at which the session blocks until compaction completes (default: 0.95)
    public var bufferExhaustionThreshold: Double?
    
    public init(
        enabled: Bool? = nil,
        backgroundCompactionThreshold: Double? = nil,
        bufferExhaustionThreshold: Double? = nil
    ) {
        self.enabled = enabled
        self.backgroundCompactionThreshold = backgroundCompactionThreshold
        self.bufferExhaustionThreshold = bufferExhaustionThreshold
    }
}

// MARK: - Session Hooks

/// Context for a hook invocation
public struct HookInvocation: Sendable {
    public let sessionId: String
    
    public init(sessionId: String) {
        self.sessionId = sessionId
    }
}

/// Input for a pre-tool-use hook
public struct PreToolUseHookInput: Codable, Sendable {
    public var timestamp: Int64
    public var cwd: String
    public var toolName: String
    public var toolArgs: AnyCodable?
    
    public init(timestamp: Int64, cwd: String, toolName: String, toolArgs: AnyCodable? = nil) {
        self.timestamp = timestamp
        self.cwd = cwd
        self.toolName = toolName
        self.toolArgs = toolArgs
    }
}

/// Output for a pre-tool-use hook
public struct PreToolUseHookOutput: Codable, Sendable {
    /// Permission decision: "allow", "deny", or "ask"
    public var permissionDecision: String?
    public var permissionDecisionReason: String?
    public var modifiedArgs: AnyCodable?
    public var additionalContext: String?
    public var suppressOutput: Bool?
    
    public init(
        permissionDecision: String? = nil,
        permissionDecisionReason: String? = nil,
        modifiedArgs: AnyCodable? = nil,
        additionalContext: String? = nil,
        suppressOutput: Bool? = nil
    ) {
        self.permissionDecision = permissionDecision
        self.permissionDecisionReason = permissionDecisionReason
        self.modifiedArgs = modifiedArgs
        self.additionalContext = additionalContext
        self.suppressOutput = suppressOutput
    }
}

/// Input for a post-tool-use hook
public struct PostToolUseHookInput: Codable, Sendable {
    public var timestamp: Int64
    public var cwd: String
    public var toolName: String
    public var toolArgs: AnyCodable?
    public var toolResult: AnyCodable?
    
    public init(timestamp: Int64, cwd: String, toolName: String, toolArgs: AnyCodable? = nil, toolResult: AnyCodable? = nil) {
        self.timestamp = timestamp
        self.cwd = cwd
        self.toolName = toolName
        self.toolArgs = toolArgs
        self.toolResult = toolResult
    }
}

/// Output for a post-tool-use hook
public struct PostToolUseHookOutput: Codable, Sendable {
    public var modifiedResult: AnyCodable?
    public var additionalContext: String?
    public var suppressOutput: Bool?
    
    public init(
        modifiedResult: AnyCodable? = nil,
        additionalContext: String? = nil,
        suppressOutput: Bool? = nil
    ) {
        self.modifiedResult = modifiedResult
        self.additionalContext = additionalContext
        self.suppressOutput = suppressOutput
    }
}

/// Input for a user-prompt-submitted hook
public struct UserPromptSubmittedHookInput: Codable, Sendable {
    public var timestamp: Int64
    public var cwd: String
    public var prompt: String
    
    public init(timestamp: Int64, cwd: String, prompt: String) {
        self.timestamp = timestamp
        self.cwd = cwd
        self.prompt = prompt
    }
}

/// Output for a user-prompt-submitted hook
public struct UserPromptSubmittedHookOutput: Codable, Sendable {
    public var modifiedPrompt: String?
    public var additionalContext: String?
    public var suppressOutput: Bool?
    
    public init(
        modifiedPrompt: String? = nil,
        additionalContext: String? = nil,
        suppressOutput: Bool? = nil
    ) {
        self.modifiedPrompt = modifiedPrompt
        self.additionalContext = additionalContext
        self.suppressOutput = suppressOutput
    }
}

/// Input for a session-start hook
public struct SessionStartHookInput: Codable, Sendable {
    public var timestamp: Int64
    public var cwd: String
    /// Source of the session start: "startup", "resume", or "new"
    public var source: String
    public var initialPrompt: String?
    
    public init(timestamp: Int64, cwd: String, source: String, initialPrompt: String? = nil) {
        self.timestamp = timestamp
        self.cwd = cwd
        self.source = source
        self.initialPrompt = initialPrompt
    }
}

/// Output for a session-start hook
public struct SessionStartHookOutput: Codable, Sendable {
    public var additionalContext: String?
    public var modifiedConfig: [String: AnyCodable]?
    
    public init(
        additionalContext: String? = nil,
        modifiedConfig: [String: AnyCodable]? = nil
    ) {
        self.additionalContext = additionalContext
        self.modifiedConfig = modifiedConfig
    }
}

/// Input for a session-end hook
public struct SessionEndHookInput: Codable, Sendable {
    public var timestamp: Int64
    public var cwd: String
    /// Reason for session end: "complete", "error", "abort", "timeout", or "user_exit"
    public var reason: String
    public var finalMessage: String?
    public var error: String?
    
    public init(timestamp: Int64, cwd: String, reason: String, finalMessage: String? = nil, error: String? = nil) {
        self.timestamp = timestamp
        self.cwd = cwd
        self.reason = reason
        self.finalMessage = finalMessage
        self.error = error
    }
}

/// Output for a session-end hook
public struct SessionEndHookOutput: Codable, Sendable {
    public var suppressOutput: Bool?
    public var cleanupActions: [String]?
    public var sessionSummary: String?
    
    public init(
        suppressOutput: Bool? = nil,
        cleanupActions: [String]? = nil,
        sessionSummary: String? = nil
    ) {
        self.suppressOutput = suppressOutput
        self.cleanupActions = cleanupActions
        self.sessionSummary = sessionSummary
    }
}

/// Input for an error-occurred hook
public struct ErrorOccurredHookInput: Codable, Sendable {
    public var timestamp: Int64
    public var cwd: String
    public var error: String
    /// Context of the error: "model_call", "tool_execution", "system", or "user_input"
    public var errorContext: String
    public var recoverable: Bool
    
    public init(timestamp: Int64, cwd: String, error: String, errorContext: String, recoverable: Bool) {
        self.timestamp = timestamp
        self.cwd = cwd
        self.error = error
        self.errorContext = errorContext
        self.recoverable = recoverable
    }
}

/// Output for an error-occurred hook
public struct ErrorOccurredHookOutput: Codable, Sendable {
    public var suppressOutput: Bool?
    /// Error handling strategy: "retry", "skip", or "abort"
    public var errorHandling: String?
    public var retryCount: Int?
    public var userNotification: String?
    
    public init(
        suppressOutput: Bool? = nil,
        errorHandling: String? = nil,
        retryCount: Int? = nil,
        userNotification: String? = nil
    ) {
        self.suppressOutput = suppressOutput
        self.errorHandling = errorHandling
        self.retryCount = retryCount
        self.userNotification = userNotification
    }
}

/// Hook handlers for a session
public struct SessionHooks: Sendable {
    /// Handler called before a tool is executed
    public var onPreToolUse: (@Sendable (PreToolUseHookInput, HookInvocation) async throws -> PreToolUseHookOutput?)?
    
    /// Handler called after a tool has been executed
    public var onPostToolUse: (@Sendable (PostToolUseHookInput, HookInvocation) async throws -> PostToolUseHookOutput?)?
    
    /// Handler called when the user submits a prompt
    public var onUserPromptSubmitted: (@Sendable (UserPromptSubmittedHookInput, HookInvocation) async throws -> UserPromptSubmittedHookOutput?)?
    
    /// Handler called when a session starts
    public var onSessionStart: (@Sendable (SessionStartHookInput, HookInvocation) async throws -> SessionStartHookOutput?)?
    
    /// Handler called when a session ends
    public var onSessionEnd: (@Sendable (SessionEndHookInput, HookInvocation) async throws -> SessionEndHookOutput?)?
    
    /// Handler called when an error occurs
    public var onErrorOccurred: (@Sendable (ErrorOccurredHookInput, HookInvocation) async throws -> ErrorOccurredHookOutput?)?
    
    public init(
        onPreToolUse: (@Sendable (PreToolUseHookInput, HookInvocation) async throws -> PreToolUseHookOutput?)? = nil,
        onPostToolUse: (@Sendable (PostToolUseHookInput, HookInvocation) async throws -> PostToolUseHookOutput?)? = nil,
        onUserPromptSubmitted: (@Sendable (UserPromptSubmittedHookInput, HookInvocation) async throws -> UserPromptSubmittedHookOutput?)? = nil,
        onSessionStart: (@Sendable (SessionStartHookInput, HookInvocation) async throws -> SessionStartHookOutput?)? = nil,
        onSessionEnd: (@Sendable (SessionEndHookInput, HookInvocation) async throws -> SessionEndHookOutput?)? = nil,
        onErrorOccurred: (@Sendable (ErrorOccurredHookInput, HookInvocation) async throws -> ErrorOccurredHookOutput?)? = nil
    ) {
        self.onPreToolUse = onPreToolUse
        self.onPostToolUse = onPostToolUse
        self.onUserPromptSubmitted = onUserPromptSubmitted
        self.onSessionStart = onSessionStart
        self.onSessionEnd = onSessionEnd
        self.onErrorOccurred = onErrorOccurred
    }
}

// MARK: - Permission Handling

/// Context for a permission request invocation
public struct PermissionInvocation: Sendable {
    public let sessionId: String
    
    public init(sessionId: String) {
        self.sessionId = sessionId
    }
}

/// Represents a permission request from the server
public struct PermissionRequest: Codable, Sendable {
    public var kind: String
    public var toolCallId: String?
    
    /// Additional fields that vary by kind
    public var extra: [String: AnyCodable]?
    
    enum CodingKeys: String, CodingKey {
        case kind
        case toolCallId
    }
    
    public init(kind: String, toolCallId: String? = nil, extra: [String: AnyCodable]? = nil) {
        self.kind = kind
        self.toolCallId = toolCallId
        self.extra = extra
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        kind = try container.decode(String.self, forKey: .kind)
        toolCallId = try container.decodeIfPresent(String.self, forKey: .toolCallId)
        
        // Decode any extra fields
        let dynamicContainer = try decoder.container(keyedBy: DynamicCodingKey.self)
        var extras: [String: AnyCodable] = [:]
        for key in dynamicContainer.allKeys {
            if key.stringValue != "kind" && key.stringValue != "toolCallId" {
                if let value = try? dynamicContainer.decode(AnyCodable.self, forKey: key) {
                    extras[key.stringValue] = value
                }
            }
        }
        extra = extras.isEmpty ? nil : extras
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(kind, forKey: .kind)
        try container.encodeIfPresent(toolCallId, forKey: .toolCallId)
        
        if let extra = extra {
            var dynamicContainer = encoder.container(keyedBy: DynamicCodingKey.self)
            for (key, value) in extra {
                try dynamicContainer.encode(value, forKey: DynamicCodingKey(stringValue: key))
            }
        }
    }
}

/// Result of a permission request
public struct PermissionRequestResult: Codable, Sendable {
    public var kind: String
    public var rules: [AnyCodable]?
    
    public init(kind: String, rules: [AnyCodable]? = nil) {
        self.kind = kind
        self.rules = rules
    }
}

// MARK: - User Input Handling

/// Context for a user input request invocation
public struct UserInputInvocation: Sendable {
    public let sessionId: String
    
    public init(sessionId: String) {
        self.sessionId = sessionId
    }
}

/// Request for user input from the agent
public struct UserInputRequest: Codable, Sendable {
    /// The question to ask the user
    public var question: String
    
    /// Optional choices for multiple choice questions
    public var choices: [String]?
    
    /// Whether freeform text input is allowed
    public var allowFreeform: Bool?
    
    public init(question: String, choices: [String]? = nil, allowFreeform: Bool? = nil) {
        self.question = question
        self.choices = choices
        self.allowFreeform = allowFreeform
    }
}

/// Response to a user input request
public struct UserInputResponse: Codable, Sendable {
    /// The user's answer
    public var answer: String
    
    /// Whether the answer was freeform (not from the provided choices)
    public var wasFreeform: Bool
    
    public init(answer: String, wasFreeform: Bool = false) {
        self.answer = answer
        self.wasFreeform = wasFreeform
    }
}

// MARK: - Attachment

/// Represents an attachment in a message
public struct Attachment: Codable, Sendable {
    /// The type of attachment ("file" or "directory")
    public var type: String
    
    /// The path to the file or directory
    public var path: String
    
    public init(type: String, path: String) {
        self.type = type
        self.path = path
    }
    
    /// Creates a file attachment
    public static func file(_ path: String) -> Attachment {
        Attachment(type: "file", path: path)
    }
    
    /// Creates a directory attachment
    public static func directory(_ path: String) -> Attachment {
        Attachment(type: "directory", path: path)
    }
}

// MARK: - Session Configuration

/// Configuration for creating a new session
public struct SessionConfig: Sendable {
    /// Optional custom session ID
    public var sessionId: String?
    
    /// Model to use for this session
    public var model: String?
    
    /// Reasoning effort level for models that support it.
    /// Valid values: "low", "medium", "high", "xhigh"
    public var reasoningEffort: String?
    
    /// Override the default configuration directory location
    public var configDir: String?
    
    /// Tools to expose to the CLI
    public var tools: [Tool]
    
    /// System message configuration
    public var systemMessage: SystemMessageConfig?
    
    /// List of tool names to allow. When specified, only these tools will be available.
    /// Takes precedence over excludedTools.
    public var availableTools: [String]?
    
    /// List of tool names to disable. All other tools remain available.
    /// Ignored if availableTools is specified.
    public var excludedTools: [String]?
    
    /// Handler for permission requests from the server
    public var onPermissionRequest: (@Sendable (PermissionRequest, PermissionInvocation) async throws -> PermissionRequestResult)?
    
    /// Handler for user input requests from the agent (enables ask_user tool)
    public var onUserInputRequest: (@Sendable (UserInputRequest, UserInputInvocation) async throws -> UserInputResponse)?
    
    /// Hook handlers for session lifecycle events
    public var hooks: SessionHooks?
    
    /// Working directory for the session
    public var workingDirectory: String?
    
    /// Enable streaming of assistant message and reasoning chunks
    public var streaming: Bool
    
    /// Custom model provider (BYOK)
    public var provider: ProviderConfig?
    
    /// MCP server configurations
    public var mcpServers: [String: AnyCodable]?
    
    /// Custom agent configurations
    public var customAgents: [CustomAgentConfig]?
    
    /// Directories to load skills from
    public var skillDirectories: [String]?
    
    /// List of skill names to disable
    public var disabledSkills: [String]?
    
    /// Infinite session configuration
    public var infiniteSessions: InfiniteSessionConfig?
    
    public init(
        sessionId: String? = nil,
        model: String? = nil,
        reasoningEffort: String? = nil,
        configDir: String? = nil,
        tools: [Tool] = [],
        systemMessage: SystemMessageConfig? = nil,
        availableTools: [String]? = nil,
        excludedTools: [String]? = nil,
        onPermissionRequest: (@Sendable (PermissionRequest, PermissionInvocation) async throws -> PermissionRequestResult)? = nil,
        onUserInputRequest: (@Sendable (UserInputRequest, UserInputInvocation) async throws -> UserInputResponse)? = nil,
        hooks: SessionHooks? = nil,
        workingDirectory: String? = nil,
        streaming: Bool = false,
        provider: ProviderConfig? = nil,
        mcpServers: [String: AnyCodable]? = nil,
        customAgents: [CustomAgentConfig]? = nil,
        skillDirectories: [String]? = nil,
        disabledSkills: [String]? = nil,
        infiniteSessions: InfiniteSessionConfig? = nil
    ) {
        self.sessionId = sessionId
        self.model = model
        self.reasoningEffort = reasoningEffort
        self.configDir = configDir
        self.tools = tools
        self.systemMessage = systemMessage
        self.availableTools = availableTools
        self.excludedTools = excludedTools
        self.onPermissionRequest = onPermissionRequest
        self.onUserInputRequest = onUserInputRequest
        self.hooks = hooks
        self.workingDirectory = workingDirectory
        self.streaming = streaming
        self.provider = provider
        self.mcpServers = mcpServers
        self.customAgents = customAgents
        self.skillDirectories = skillDirectories
        self.disabledSkills = disabledSkills
        self.infiniteSessions = infiniteSessions
    }
}

/// Configuration for resuming an existing session
public struct ResumeSessionConfig: Sendable {
    /// Tools to expose to the CLI
    public var tools: [Tool]
    
    /// Custom model provider
    public var provider: ProviderConfig?
    
    /// Reasoning effort level
    public var reasoningEffort: String?
    
    /// Handler for permission requests from the server
    public var onPermissionRequest: (@Sendable (PermissionRequest, PermissionInvocation) async throws -> PermissionRequestResult)?
    
    /// Handler for user input requests from the agent
    public var onUserInputRequest: (@Sendable (UserInputRequest, UserInputInvocation) async throws -> UserInputResponse)?
    
    /// Hook handlers for session lifecycle events
    public var hooks: SessionHooks?
    
    /// Working directory for the session
    public var workingDirectory: String?
    
    /// Enable streaming of assistant message and reasoning chunks
    public var streaming: Bool
    
    /// MCP server configurations
    public var mcpServers: [String: AnyCodable]?
    
    /// Custom agent configurations
    public var customAgents: [CustomAgentConfig]?
    
    /// Directories to load skills from
    public var skillDirectories: [String]?
    
    /// List of skill names to disable
    public var disabledSkills: [String]?
    
    /// When true, skips emitting the session.resume event
    public var disableResume: Bool
    
    public init(
        tools: [Tool] = [],
        provider: ProviderConfig? = nil,
        reasoningEffort: String? = nil,
        onPermissionRequest: (@Sendable (PermissionRequest, PermissionInvocation) async throws -> PermissionRequestResult)? = nil,
        onUserInputRequest: (@Sendable (UserInputRequest, UserInputInvocation) async throws -> UserInputResponse)? = nil,
        hooks: SessionHooks? = nil,
        workingDirectory: String? = nil,
        streaming: Bool = false,
        mcpServers: [String: AnyCodable]? = nil,
        customAgents: [CustomAgentConfig]? = nil,
        skillDirectories: [String]? = nil,
        disabledSkills: [String]? = nil,
        disableResume: Bool = false
    ) {
        self.tools = tools
        self.provider = provider
        self.reasoningEffort = reasoningEffort
        self.onPermissionRequest = onPermissionRequest
        self.onUserInputRequest = onUserInputRequest
        self.hooks = hooks
        self.workingDirectory = workingDirectory
        self.streaming = streaming
        self.mcpServers = mcpServers
        self.customAgents = customAgents
        self.skillDirectories = skillDirectories
        self.disabledSkills = disabledSkills
        self.disableResume = disableResume
    }
}

// MARK: - Message Options

/// Options for sending a message
public struct MessageOptions: Sendable {
    /// The message to send
    public var prompt: String
    
    /// File or directory attachments
    public var attachments: [Attachment]
    
    /// Message delivery mode (default: "enqueue")
    public var mode: String?
    
    public init(prompt: String, attachments: [Attachment] = [], mode: String? = nil) {
        self.prompt = prompt
        self.attachments = attachments
        self.mode = mode
    }
}

// MARK: - Response Types

/// Response from a ping request
public struct PingResponse: Codable, Sendable {
    public var message: String
    public var timestamp: Int64
    public var protocolVersion: Int?
    
    public init(message: String, timestamp: Int64, protocolVersion: Int? = nil) {
        self.message = message
        self.timestamp = timestamp
        self.protocolVersion = protocolVersion
    }
}

/// Response from status.get
public struct GetStatusResponse: Codable, Sendable {
    /// Package version (e.g., "1.0.0")
    public var version: String
    
    /// Protocol version for SDK compatibility
    public var protocolVersion: Int
    
    public init(version: String, protocolVersion: Int) {
        self.version = version
        self.protocolVersion = protocolVersion
    }
}

/// Response from auth.getStatus
public struct GetAuthStatusResponse: Codable, Sendable {
    /// Whether the user is authenticated
    public var isAuthenticated: Bool
    
    /// Authentication type (user, env, gh-cli, hmac, api-key, token)
    public var authType: String?
    
    /// GitHub host URL
    public var host: String?
    
    /// User login name
    public var login: String?
    
    /// Human-readable status message
    public var statusMessage: String?
    
    public init(
        isAuthenticated: Bool,
        authType: String? = nil,
        host: String? = nil,
        login: String? = nil,
        statusMessage: String? = nil
    ) {
        self.isAuthenticated = isAuthenticated
        self.authType = authType
        self.host = host
        self.login = login
        self.statusMessage = statusMessage
    }
}

/// Model vision-specific limits
public struct ModelVisionLimits: Codable, Sendable {
    public var supportedMediaTypes: [String]
    public var maxPromptImages: Int
    public var maxPromptImageSize: Int
    
    enum CodingKeys: String, CodingKey {
        case supportedMediaTypes = "supported_media_types"
        case maxPromptImages = "max_prompt_images"
        case maxPromptImageSize = "max_prompt_image_size"
    }
    
    public init(supportedMediaTypes: [String], maxPromptImages: Int, maxPromptImageSize: Int) {
        self.supportedMediaTypes = supportedMediaTypes
        self.maxPromptImages = maxPromptImages
        self.maxPromptImageSize = maxPromptImageSize
    }
}

/// Model limits
public struct ModelLimits: Codable, Sendable {
    public var maxPromptTokens: Int?
    public var maxContextWindowTokens: Int
    public var vision: ModelVisionLimits?
    
    enum CodingKeys: String, CodingKey {
        case maxPromptTokens = "max_prompt_tokens"
        case maxContextWindowTokens = "max_context_window_tokens"
        case vision
    }
    
    public init(maxContextWindowTokens: Int, maxPromptTokens: Int? = nil, vision: ModelVisionLimits? = nil) {
        self.maxContextWindowTokens = maxContextWindowTokens
        self.maxPromptTokens = maxPromptTokens
        self.vision = vision
    }
}

/// Model support flags
public struct ModelSupports: Codable, Sendable {
    public var vision: Bool
    public var reasoningEffort: Bool
    
    public init(vision: Bool, reasoningEffort: Bool) {
        self.vision = vision
        self.reasoningEffort = reasoningEffort
    }
}

/// Model capabilities and limits
public struct ModelCapabilities: Codable, Sendable {
    public var supports: ModelSupports
    public var limits: ModelLimits
    
    public init(supports: ModelSupports, limits: ModelLimits) {
        self.supports = supports
        self.limits = limits
    }
}

/// Model policy state
public struct ModelPolicy: Codable, Sendable {
    public var state: String
    public var terms: String
    
    public init(state: String, terms: String) {
        self.state = state
        self.terms = terms
    }
}

/// Model billing information
public struct ModelBilling: Codable, Sendable {
    public var multiplier: Double
    
    public init(multiplier: Double) {
        self.multiplier = multiplier
    }
}

/// Information about an available model
public struct ModelInfo: Codable, Sendable {
    /// Model identifier (e.g., "claude-sonnet-4.5")
    public var id: String
    
    /// Display name
    public var name: String
    
    /// Model capabilities and limits
    public var capabilities: ModelCapabilities
    
    /// Policy state
    public var policy: ModelPolicy?
    
    /// Billing information
    public var billing: ModelBilling?
    
    /// Supported reasoning effort levels
    public var supportedReasoningEfforts: [String]?
    
    /// Default reasoning effort level
    public var defaultReasoningEffort: String?
    
    public init(
        id: String,
        name: String,
        capabilities: ModelCapabilities,
        policy: ModelPolicy? = nil,
        billing: ModelBilling? = nil,
        supportedReasoningEfforts: [String]? = nil,
        defaultReasoningEffort: String? = nil
    ) {
        self.id = id
        self.name = name
        self.capabilities = capabilities
        self.policy = policy
        self.billing = billing
        self.supportedReasoningEfforts = supportedReasoningEfforts
        self.defaultReasoningEffort = defaultReasoningEffort
    }
}

/// Response from models.list
public struct GetModelsResponse: Codable, Sendable {
    public var models: [ModelInfo]
    
    public init(models: [ModelInfo]) {
        self.models = models
    }
}

/// Metadata about a session
public struct SessionMetadata: Codable, Sendable {
    public var sessionId: String
    public var startTime: String
    public var modifiedTime: String
    public var summary: String?
    public var isRemote: Bool
    
    public init(sessionId: String, startTime: String, modifiedTime: String, summary: String? = nil, isRemote: Bool = false) {
        self.sessionId = sessionId
        self.startTime = startTime
        self.modifiedTime = modifiedTime
        self.summary = summary
        self.isRemote = isRemote
    }
}

/// Response from session.list
public struct ListSessionsResponse: Codable, Sendable {
    public var sessions: [SessionMetadata]
    
    public init(sessions: [SessionMetadata]) {
        self.sessions = sessions
    }
}

/// Response from session.create
public struct SessionCreateResponse: Codable, Sendable {
    public var sessionId: String
    
    public init(sessionId: String) {
        self.sessionId = sessionId
    }
}

/// Response from session.send
public struct SessionSendResponse: Codable, Sendable {
    public var messageId: String
    
    public init(messageId: String) {
        self.messageId = messageId
    }
}

/// Response from session.getMessages
public struct SessionGetMessagesResponse: Codable, Sendable {
    public var events: [SessionEvent]
    
    public init(events: [SessionEvent]) {
        self.events = events
    }
}

/// Response from session.delete
public struct DeleteSessionResponse: Codable, Sendable {
    public var success: Bool
    public var error: String?
    
    public init(success: Bool, error: String? = nil) {
        self.success = success
        self.error = error
    }
}

// MARK: - Helper Types

/// A type-erased Codable value for handling dynamic JSON
public struct AnyCodable: Codable, Sendable, Equatable, Hashable {
    public let value: Any
    
    public init(_ value: Any) {
        self.value = value
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if container.decodeNil() {
            self.value = NSNull()
        } else if let bool = try? container.decode(Bool.self) {
            self.value = bool
        } else if let int = try? container.decode(Int.self) {
            self.value = int
        } else if let double = try? container.decode(Double.self) {
            self.value = double
        } else if let string = try? container.decode(String.self) {
            self.value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            self.value = array.map { $0.value }
        } else if let dictionary = try? container.decode([String: AnyCodable].self) {
            self.value = dictionary.mapValues { $0.value }
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unable to decode value")
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch value {
        case is NSNull:
            try container.encodeNil()
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        case let array as [Any]:
            try container.encode(array.map { AnyCodable($0) })
        case let dictionary as [String: Any]:
            try container.encode(dictionary.mapValues { AnyCodable($0) })
        default:
            throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: encoder.codingPath, debugDescription: "Unable to encode value"))
        }
    }
    
    public static func == (lhs: AnyCodable, rhs: AnyCodable) -> Bool {
        switch (lhs.value, rhs.value) {
        case is (NSNull, NSNull):
            return true
        case let (lhs as Bool, rhs as Bool):
            return lhs == rhs
        case let (lhs as Int, rhs as Int):
            return lhs == rhs
        case let (lhs as Double, rhs as Double):
            return lhs == rhs
        case let (lhs as String, rhs as String):
            return lhs == rhs
        default:
            return false
        }
    }
    
    public func hash(into hasher: inout Hasher) {
        switch value {
        case is NSNull:
            hasher.combine(0)
        case let bool as Bool:
            hasher.combine(bool)
        case let int as Int:
            hasher.combine(int)
        case let double as Double:
            hasher.combine(double)
        case let string as String:
            hasher.combine(string)
        default:
            hasher.combine(1)
        }
    }
}

/// Dynamic coding key for handling unknown JSON keys
struct DynamicCodingKey: CodingKey {
    var stringValue: String
    var intValue: Int?
    
    init(stringValue: String) {
        self.stringValue = stringValue
        self.intValue = nil
    }
    
    init?(intValue: Int) {
        self.stringValue = String(intValue)
        self.intValue = intValue
    }
}
