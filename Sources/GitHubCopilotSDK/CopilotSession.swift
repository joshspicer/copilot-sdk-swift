/*---------------------------------------------------------------------------------------------
 *  Copyright (c) Microsoft Corporation. All rights reserved.
 *--------------------------------------------------------------------------------------------*/

import Foundation

// MARK: - Copilot Session

/// Represents an active conversation session with Copilot
public actor CopilotSession {
    /// The unique session ID
    public let sessionId: String
    
    private weak var client: CopilotClient?
    private let rpcHandler: JSONRPCHandler
    private let tools: [Tool]
    private let onPermissionRequest: (@Sendable (PermissionRequest, PermissionInvocation) async throws -> PermissionRequestResult)?
    private let onUserInputRequest: (@Sendable (UserInputRequest, UserInputInvocation) async throws -> UserInputResponse)?
    private let hooks: SessionHooks?
    
    private var eventHandlers: [(SessionEvent) -> Void] = []
    private var eventContinuations: [AsyncStream<SessionEvent>.Continuation] = []
    
    init(
        sessionId: String,
        client: CopilotClient,
        rpcHandler: JSONRPCHandler,
        tools: [Tool],
        onPermissionRequest: (@Sendable (PermissionRequest, PermissionInvocation) async throws -> PermissionRequestResult)?,
        onUserInputRequest: (@Sendable (UserInputRequest, UserInputInvocation) async throws -> UserInputResponse)?,
        hooks: SessionHooks?
    ) {
        self.sessionId = sessionId
        self.client = client
        self.rpcHandler = rpcHandler
        self.tools = tools
        self.onPermissionRequest = onPermissionRequest
        self.onUserInputRequest = onUserInputRequest
        self.hooks = hooks
    }
    
    // MARK: - Event Handling
    
    /// Register an event handler that will be called for each session event
    public func on(_ handler: @escaping (SessionEvent) -> Void) {
        eventHandlers.append(handler)
    }
    
    /// Get an async stream of session events
    public var events: AsyncStream<SessionEvent> {
        AsyncStream { continuation in
            eventContinuations.append(continuation)
        }
    }
    
    /// Handle an incoming event from the server
    func handleEvent(_ event: SessionEvent) {
        // Notify all handlers
        for handler in eventHandlers {
            handler(event)
        }
        
        // Notify all stream continuations
        for continuation in eventContinuations {
            continuation.yield(event)
        }
    }
    
    // MARK: - Message Operations
    
    /// Send a message to the session
    /// - Parameter options: The message options including prompt and attachments
    /// - Returns: The message ID
    @discardableResult
    public func send(_ options: MessageOptions) async throws -> String {
        var params: [String: Any] = [
            "sessionId": sessionId,
            "prompt": options.prompt
        ]
        
        if !options.attachments.isEmpty {
            params["attachments"] = options.attachments.map { attachment in
                ["type": attachment.type, "path": attachment.path]
            }
        }
        
        if let mode = options.mode {
            params["mode"] = mode
        }
        
        let result = try await rpcHandler.sendRequest(method: "session.send", params: AnyCodable(params))
        
        guard let resultDict = result?.value as? [String: Any],
              let messageId = resultDict["messageId"] as? String else {
            throw CopilotError.invalidResponse
        }
        
        return messageId
    }
    
    /// Send a prompt string to the session
    /// - Parameter prompt: The prompt text
    /// - Returns: The message ID
    @discardableResult
    public func send(_ prompt: String) async throws -> String {
        try await send(MessageOptions(prompt: prompt))
    }
    
    /// Get all messages/events in the session
    /// - Returns: Array of session events
    public func getMessages() async throws -> [SessionEvent] {
        let params: [String: Any] = ["sessionId": sessionId]
        let result = try await rpcHandler.sendRequest(method: "session.getMessages", params: AnyCodable(params))
        
        guard let resultDict = result?.value as? [String: Any],
              let eventsArray = resultDict["events"] as? [[String: Any]] else {
            throw CopilotError.invalidResponse
        }
        
        // Decode events from JSON
        let decoder = JSONDecoder()
        var events: [SessionEvent] = []
        
        for eventDict in eventsArray {
            let data = try JSONSerialization.data(withJSONObject: eventDict)
            if let event = try? decoder.decode(SessionEvent.self, from: data) {
                events.append(event)
            }
        }
        
        return events
    }
    
    /// Abort the current session operation
    public func abort() async throws {
        let params: [String: Any] = ["sessionId": sessionId]
        _ = try await rpcHandler.sendRequest(method: "session.abort", params: AnyCodable(params))
    }
    
    /// Destroy the session
    public func destroy() async throws {
        let params: [String: Any] = ["sessionId": sessionId]
        _ = try await rpcHandler.sendRequest(method: "session.destroy", params: AnyCodable(params))
        
        // Close all event streams
        for continuation in eventContinuations {
            continuation.finish()
        }
        eventContinuations.removeAll()
        eventHandlers.removeAll()
    }
    
    // MARK: - Tool Handling
    
    /// Handle a tool call from the server
    func handleToolCall(toolCallId: String, toolName: String, arguments: Any?) async -> ToolResult {
        // Find the matching tool
        guard let tool = tools.first(where: { $0.name == toolName }) else {
            return .failure("Tool not found: \(toolName)")
        }
        
        let invocation = ToolInvocation(
            sessionId: sessionId,
            toolCallId: toolCallId,
            toolName: toolName,
            arguments: arguments
        )
        
        do {
            return try await tool.handler(invocation)
        } catch {
            return .failure("Tool execution failed: \(error.localizedDescription)", error: error.localizedDescription)
        }
    }
    
    // MARK: - Permission Handling
    
    /// Handle a permission request from the server
    func handlePermissionRequest(_ request: PermissionRequest) async throws -> PermissionRequestResult {
        guard let handler = onPermissionRequest else {
            // Default: allow
            return PermissionRequestResult(kind: "allow")
        }
        
        let invocation = PermissionInvocation(sessionId: sessionId)
        return try await handler(request, invocation)
    }
    
    // MARK: - User Input Handling
    
    /// Handle a user input request from the server
    func handleUserInputRequest(_ request: UserInputRequest) async throws -> UserInputResponse {
        guard let handler = onUserInputRequest else {
            throw CopilotError.toolError(message: "No user input handler configured")
        }
        
        let invocation = UserInputInvocation(sessionId: sessionId)
        return try await handler(request, invocation)
    }
    
    // MARK: - Hook Handling
    
    /// Handle a hook invocation from the server
    func handleHook(hookName: String, input: Any?) async throws -> Any? {
        let invocation = HookInvocation(sessionId: sessionId)
        let decoder = JSONDecoder()
        let encoder = JSONEncoder()
        
        switch hookName {
        case "onPreToolUse":
            guard let handler = hooks?.onPreToolUse else { return nil }
            let inputData = try JSONSerialization.data(withJSONObject: input ?? [:])
            let hookInput = try decoder.decode(PreToolUseHookInput.self, from: inputData)
            let result = try await handler(hookInput, invocation)
            if let result = result {
                let resultData = try encoder.encode(result)
                return try JSONSerialization.jsonObject(with: resultData)
            }
            return nil
            
        case "onPostToolUse":
            guard let handler = hooks?.onPostToolUse else { return nil }
            let inputData = try JSONSerialization.data(withJSONObject: input ?? [:])
            let hookInput = try decoder.decode(PostToolUseHookInput.self, from: inputData)
            let result = try await handler(hookInput, invocation)
            if let result = result {
                let resultData = try encoder.encode(result)
                return try JSONSerialization.jsonObject(with: resultData)
            }
            return nil
            
        case "onUserPromptSubmitted":
            guard let handler = hooks?.onUserPromptSubmitted else { return nil }
            let inputData = try JSONSerialization.data(withJSONObject: input ?? [:])
            let hookInput = try decoder.decode(UserPromptSubmittedHookInput.self, from: inputData)
            let result = try await handler(hookInput, invocation)
            if let result = result {
                let resultData = try encoder.encode(result)
                return try JSONSerialization.jsonObject(with: resultData)
            }
            return nil
            
        case "onSessionStart":
            guard let handler = hooks?.onSessionStart else { return nil }
            let inputData = try JSONSerialization.data(withJSONObject: input ?? [:])
            let hookInput = try decoder.decode(SessionStartHookInput.self, from: inputData)
            let result = try await handler(hookInput, invocation)
            if let result = result {
                let resultData = try encoder.encode(result)
                return try JSONSerialization.jsonObject(with: resultData)
            }
            return nil
            
        case "onSessionEnd":
            guard let handler = hooks?.onSessionEnd else { return nil }
            let inputData = try JSONSerialization.data(withJSONObject: input ?? [:])
            let hookInput = try decoder.decode(SessionEndHookInput.self, from: inputData)
            let result = try await handler(hookInput, invocation)
            if let result = result {
                let resultData = try encoder.encode(result)
                return try JSONSerialization.jsonObject(with: resultData)
            }
            return nil
            
        case "onErrorOccurred":
            guard let handler = hooks?.onErrorOccurred else { return nil }
            let inputData = try JSONSerialization.data(withJSONObject: input ?? [:])
            let hookInput = try decoder.decode(ErrorOccurredHookInput.self, from: inputData)
            let result = try await handler(hookInput, invocation)
            if let result = result {
                let resultData = try encoder.encode(result)
                return try JSONSerialization.jsonObject(with: resultData)
            }
            return nil
            
        default:
            return nil
        }
    }
}

// MARK: - Convenience Methods

extension CopilotSession {
    /// Wait for the session to become idle (no more events pending)
    /// - Parameter timeout: Maximum time to wait
    /// - Returns: The final events received
    public func waitForIdle(timeout: TimeInterval = 60) async throws -> [SessionEvent] {
        let startTime = Date()
        var collectedEvents: [SessionEvent] = []
        
        for await event in events {
            collectedEvents.append(event)
            
            if event.type == .sessionIdle {
                return collectedEvents
            }
            
            if event.type == .sessionError {
                if case .sessionError(let errorData) = event.data {
                    throw CopilotError.toolError(message: errorData.message)
                }
                throw CopilotError.toolError(message: "Session error occurred")
            }
            
            if Date().timeIntervalSince(startTime) > timeout {
                throw CopilotError.timeout
            }
        }
        
        return collectedEvents
    }
    
    /// Get the final assistant message after sending a prompt
    /// - Parameter timeout: Maximum time to wait
    /// - Returns: The assistant's response text
    public func getFinalMessage(timeout: TimeInterval = 60) async throws -> String {
        let events = try await waitForIdle(timeout: timeout)
        
        // Find the last assistant message
        for event in events.reversed() {
            if event.type == .assistantMessage,
               case .assistantMessage(let messageData) = event.data {
                return messageData.content
            }
        }
        
        throw CopilotError.invalidResponse
    }
}
