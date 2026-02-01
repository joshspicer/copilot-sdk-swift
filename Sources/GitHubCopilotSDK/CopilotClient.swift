/*---------------------------------------------------------------------------------------------
 *  Copyright (c) Microsoft Corporation. All rights reserved.
 *--------------------------------------------------------------------------------------------*/

import Foundation

// MARK: - Copilot Client

/// The main client for interacting with the Copilot CLI
public actor CopilotClient {
    /// Current connection state
    public private(set) var connectionState: ConnectionState = .disconnected
    
    private let options: CopilotClientOptions
    private var transport: (any Transport)?
    private var rpcHandler: JSONRPCHandler?
    private var sessions: [String: CopilotSession] = [:]
    private var receiveTask: Task<Void, Never>?
    
    /// Connection state change handler
    public var onConnectionStateChanged: ((ConnectionState) -> Void)?
    
    // MARK: - Initialization
    
    /// Create a new Copilot client
    /// - Parameter options: Configuration options for the client
    public init(options: CopilotClientOptions = CopilotClientOptions()) {
        self.options = options
    }
    
    // MARK: - Connection Management
    
    /// Connect to the Copilot CLI server
    public func connect() async throws {
        guard connectionState != .connected else { return }
        
        setConnectionState(.connecting)
        
        do {
            if let cliUrl = options.cliUrl {
                // Connect to external server via TCP
                guard let (host, port) = TCPTransport.parseUrl(cliUrl) else {
                    throw CopilotError.connectionFailed(underlying: nil)
                }
                
                let tcpTransport = TCPTransport(host: host, port: port)
                try await tcpTransport.connect()
                transport = tcpTransport
            } else if options.useStdio {
                // Start CLI process with stdio transport
                let stdioTransport = try StdioTransport(options: options)
                try await stdioTransport.start()
                transport = stdioTransport
            } else {
                // TCP transport to local CLI (need to start CLI in server mode)
                let stdioTransport = try StdioTransport(options: CopilotClientOptions(
                    cliPath: options.cliPath,
                    cwd: options.cwd,
                    port: options.port,
                    useStdio: true,
                    logLevel: options.logLevel,
                    environment: options.environment,
                    githubToken: options.githubToken,
                    useLoggedInUser: options.useLoggedInUser
                ))
                try await stdioTransport.start()
                transport = stdioTransport
            }
            
            guard let transport = transport else {
                throw CopilotError.connectionFailed(underlying: nil)
            }
            
            // Create RPC handler
            let handler = JSONRPCHandler(transport: transport)
            rpcHandler = handler
            
            // Set up message handlers
            await handler.setOnNotification { [weak self] method, params in
                await self?.handleNotification(method: method, params: params)
            }
            
            await handler.setOnRequest { [weak self] id, method, params in
                await self?.handleRequest(id: id, method: method, params: params)
            }
            
            // Start receive loop
            receiveTask = Task {
                await handler.start()
            }
            
            // Verify connection with ping (use internal version to avoid ensureConnected check)
            let pingResponse = try await pingInternal()
            
            // Check protocol version
            if let serverVersion = pingResponse.protocolVersion, serverVersion != sdkProtocolVersion {
                throw CopilotError.protocolVersionMismatch(expected: sdkProtocolVersion, actual: serverVersion)
            }
            
            setConnectionState(.connected)
            
        } catch {
            setConnectionState(.error)
            throw error
        }
    }
    
    private func setConnectionState(_ state: ConnectionState) {
        connectionState = state
        onConnectionStateChanged?(state)
    }
    
    /// Stop the client and close all connections
    public func stop() async {
        receiveTask?.cancel()
        receiveTask = nil
        
        // Destroy all sessions
        for session in sessions.values {
            try? await session.destroy()
        }
        sessions.removeAll()
        
        // Close transport
        if let transport = transport {
            await transport.close()
        }
        transport = nil
        rpcHandler = nil
        
        setConnectionState(.disconnected)
    }
    
    /// Force stop the client immediately
    public func forceStop() {
        receiveTask?.cancel()
        receiveTask = nil
        sessions.removeAll()
        
        // Close transport synchronously if possible
        if let transport = transport {
            Task {
                await transport.close()
            }
        }
        transport = nil
        rpcHandler = nil
        
        setConnectionState(.disconnected)
    }
    
    // MARK: - API Methods
    
    /// Ping the server to check connectivity
    /// - Returns: Ping response with server info
    public func ping() async throws -> PingResponse {
        try await ensureConnected()
        return try await pingInternal()
    }
    
    /// Internal ping without ensureConnected check (used during connection)
    private func pingInternal() async throws -> PingResponse {
        guard let handler = rpcHandler else {
            throw CopilotError.notConnected
        }
        
        let result = try await handler.sendRequest(method: "ping", params: AnyCodable(["message": "ping"]))
        
        guard let dict = result?.value as? [String: Any] else {
            throw CopilotError.invalidResponse
        }
        
        return PingResponse(
            message: dict["message"] as? String ?? "",
            timestamp: dict["timestamp"] as? Int64 ?? 0,
            protocolVersion: dict["protocolVersion"] as? Int
        )
    }

    /// Get server status
    /// - Returns: Server status including version info
    public func getStatus() async throws -> GetStatusResponse {
        try await ensureConnected()
        
        guard let handler = rpcHandler else {
            throw CopilotError.notConnected
        }
        
        let result = try await handler.sendRequest(method: "status.get")
        
        guard let dict = result?.value as? [String: Any],
              let version = dict["version"] as? String,
              let protocolVersion = dict["protocolVersion"] as? Int else {
            throw CopilotError.invalidResponse
        }
        
        return GetStatusResponse(version: version, protocolVersion: protocolVersion)
    }
    
    /// Get authentication status
    /// - Returns: Current authentication status
    public func getAuthStatus() async throws -> GetAuthStatusResponse {
        try await ensureConnected()
        
        guard let handler = rpcHandler else {
            throw CopilotError.notConnected
        }
        
        let result = try await handler.sendRequest(method: "auth.getStatus")
        
        guard let dict = result?.value as? [String: Any] else {
            throw CopilotError.invalidResponse
        }
        
        return GetAuthStatusResponse(
            isAuthenticated: dict["isAuthenticated"] as? Bool ?? false,
            authType: dict["authType"] as? String,
            host: dict["host"] as? String,
            login: dict["login"] as? String,
            statusMessage: dict["statusMessage"] as? String
        )
    }
    
    /// Get available models
    /// - Returns: List of available models
    public func getModels() async throws -> [ModelInfo] {
        try await ensureConnected()
        
        guard let handler = rpcHandler else {
            throw CopilotError.notConnected
        }
        
        let result = try await handler.sendRequest(method: "models.list")
        
        guard let dict = result?.value as? [String: Any],
              let modelsArray = dict["models"] as? [[String: Any]] else {
            throw CopilotError.invalidResponse
        }
        
        let decoder = JSONDecoder()
        var models: [ModelInfo] = []
        
        for modelDict in modelsArray {
            let data = try JSONSerialization.data(withJSONObject: modelDict)
            if let model = try? decoder.decode(ModelInfo.self, from: data) {
                models.append(model)
            }
        }
        
        return models
    }
    
    // MARK: - Session Management
    
    /// Create a new session
    /// - Parameter config: Session configuration
    /// - Returns: The created session
    public func createSession(_ config: SessionConfig = SessionConfig()) async throws -> CopilotSession {
        try await ensureConnected()
        
        guard let handler = rpcHandler else {
            throw CopilotError.notConnected
        }
        
        var params: [String: Any] = [:]
        
        if let sessionId = config.sessionId {
            params["sessionId"] = sessionId
        }
        if let model = config.model {
            params["model"] = model
        }
        if let reasoningEffort = config.reasoningEffort {
            params["reasoningEffort"] = reasoningEffort
        }
        if let configDir = config.configDir {
            params["configDir"] = configDir
        }
        if let systemMessage = config.systemMessage {
            var sysMsg: [String: Any] = [:]
            if let mode = systemMessage.mode {
                sysMsg["mode"] = mode.rawValue
            }
            if let content = systemMessage.content {
                sysMsg["content"] = content
            }
            params["systemMessage"] = sysMsg
        }
        if let availableTools = config.availableTools {
            params["availableTools"] = availableTools
        }
        if let excludedTools = config.excludedTools {
            params["excludedTools"] = excludedTools
        }
        if let workingDirectory = config.workingDirectory {
            params["workingDirectory"] = workingDirectory
        }
        if config.streaming {
            params["streaming"] = true
        }
        if let provider = config.provider {
            let encoder = JSONEncoder()
            let providerData = try encoder.encode(provider)
            params["provider"] = try JSONSerialization.jsonObject(with: providerData)
        }
        if let customAgents = config.customAgents {
            let encoder = JSONEncoder()
            let agentsData = try encoder.encode(customAgents)
            params["customAgents"] = try JSONSerialization.jsonObject(with: agentsData)
        }
        if let skillDirectories = config.skillDirectories {
            params["skillDirectories"] = skillDirectories
        }
        if let disabledSkills = config.disabledSkills {
            params["disabledSkills"] = disabledSkills
        }
        if let infiniteSessions = config.infiniteSessions {
            let encoder = JSONEncoder()
            let infiniteData = try encoder.encode(infiniteSessions)
            params["infiniteSessions"] = try JSONSerialization.jsonObject(with: infiniteData)
        }
        
        // Add tools
        if !config.tools.isEmpty {
            params["tools"] = config.tools.toRPCParams()
        }
        
        // Add flags for handlers
        if config.onPermissionRequest != nil {
            params["hasPermissionHandler"] = true
        }
        if config.onUserInputRequest != nil {
            params["hasUserInputHandler"] = true
        }
        if config.hooks != nil {
            var hookNames: [String] = []
            if config.hooks?.onPreToolUse != nil { hookNames.append("onPreToolUse") }
            if config.hooks?.onPostToolUse != nil { hookNames.append("onPostToolUse") }
            if config.hooks?.onUserPromptSubmitted != nil { hookNames.append("onUserPromptSubmitted") }
            if config.hooks?.onSessionStart != nil { hookNames.append("onSessionStart") }
            if config.hooks?.onSessionEnd != nil { hookNames.append("onSessionEnd") }
            if config.hooks?.onErrorOccurred != nil { hookNames.append("onErrorOccurred") }
            if !hookNames.isEmpty {
                params["hooks"] = hookNames
            }
        }
        
        let result = try await handler.sendRequest(method: "session.create", params: AnyCodable(params))
        
        guard let dict = result?.value as? [String: Any],
              let sessionId = dict["sessionId"] as? String else {
            throw CopilotError.invalidResponse
        }
        
        let session = CopilotSession(
            sessionId: sessionId,
            client: self,
            rpcHandler: handler,
            tools: config.tools,
            onPermissionRequest: config.onPermissionRequest,
            onUserInputRequest: config.onUserInputRequest,
            hooks: config.hooks
        )
        
        sessions[sessionId] = session
        
        return session
    }
    
    /// Resume an existing session
    /// - Parameters:
    ///   - sessionId: The session ID to resume
    ///   - config: Configuration for the resumed session
    /// - Returns: The resumed session
    public func resumeSession(sessionId: String, config: ResumeSessionConfig = ResumeSessionConfig()) async throws -> CopilotSession {
        try await ensureConnected()
        
        guard let handler = rpcHandler else {
            throw CopilotError.notConnected
        }
        
        var params: [String: Any] = ["sessionId": sessionId]
        
        if let reasoningEffort = config.reasoningEffort {
            params["reasoningEffort"] = reasoningEffort
        }
        if let workingDirectory = config.workingDirectory {
            params["workingDirectory"] = workingDirectory
        }
        if config.streaming {
            params["streaming"] = true
        }
        if let provider = config.provider {
            let encoder = JSONEncoder()
            let providerData = try encoder.encode(provider)
            params["provider"] = try JSONSerialization.jsonObject(with: providerData)
        }
        if let customAgents = config.customAgents {
            let encoder = JSONEncoder()
            let agentsData = try encoder.encode(customAgents)
            params["customAgents"] = try JSONSerialization.jsonObject(with: agentsData)
        }
        if let skillDirectories = config.skillDirectories {
            params["skillDirectories"] = skillDirectories
        }
        if let disabledSkills = config.disabledSkills {
            params["disabledSkills"] = disabledSkills
        }
        if config.disableResume {
            params["disableResume"] = true
        }
        
        // Add tools
        if !config.tools.isEmpty {
            params["tools"] = config.tools.toRPCParams()
        }
        
        // Add flags for handlers
        if config.onPermissionRequest != nil {
            params["hasPermissionHandler"] = true
        }
        if config.onUserInputRequest != nil {
            params["hasUserInputHandler"] = true
        }
        if config.hooks != nil {
            var hookNames: [String] = []
            if config.hooks?.onPreToolUse != nil { hookNames.append("onPreToolUse") }
            if config.hooks?.onPostToolUse != nil { hookNames.append("onPostToolUse") }
            if config.hooks?.onUserPromptSubmitted != nil { hookNames.append("onUserPromptSubmitted") }
            if config.hooks?.onSessionStart != nil { hookNames.append("onSessionStart") }
            if config.hooks?.onSessionEnd != nil { hookNames.append("onSessionEnd") }
            if config.hooks?.onErrorOccurred != nil { hookNames.append("onErrorOccurred") }
            if !hookNames.isEmpty {
                params["hooks"] = hookNames
            }
        }
        
        _ = try await handler.sendRequest(method: "session.resume", params: AnyCodable(params))
        
        let session = CopilotSession(
            sessionId: sessionId,
            client: self,
            rpcHandler: handler,
            tools: config.tools,
            onPermissionRequest: config.onPermissionRequest,
            onUserInputRequest: config.onUserInputRequest,
            hooks: config.hooks
        )
        
        sessions[sessionId] = session
        
        return session
    }
    
    /// List all persisted sessions
    /// - Returns: Array of session metadata
    public func listSessions() async throws -> [SessionMetadata] {
        try await ensureConnected()
        
        guard let handler = rpcHandler else {
            throw CopilotError.notConnected
        }
        
        let result = try await handler.sendRequest(method: "session.list")
        
        guard let dict = result?.value as? [String: Any],
              let sessionsArray = dict["sessions"] as? [[String: Any]] else {
            throw CopilotError.invalidResponse
        }
        
        let decoder = JSONDecoder()
        var metadata: [SessionMetadata] = []
        
        for sessionDict in sessionsArray {
            let data = try JSONSerialization.data(withJSONObject: sessionDict)
            if let session = try? decoder.decode(SessionMetadata.self, from: data) {
                metadata.append(session)
            }
        }
        
        return metadata
    }
    
    /// Delete a persisted session
    /// - Parameter sessionId: The session ID to delete
    /// - Returns: Whether the deletion was successful
    @discardableResult
    public func deleteSession(sessionId: String) async throws -> Bool {
        try await ensureConnected()
        
        guard let handler = rpcHandler else {
            throw CopilotError.notConnected
        }
        
        let params: [String: Any] = ["sessionId": sessionId]
        let result = try await handler.sendRequest(method: "session.delete", params: AnyCodable(params))
        
        guard let dict = result?.value as? [String: Any],
              let success = dict["success"] as? Bool else {
            throw CopilotError.invalidResponse
        }
        
        // Remove from local cache if present
        sessions.removeValue(forKey: sessionId)
        
        return success
    }
    
    /// Get the last session ID
    /// - Returns: The last session ID or nil
    public func getLastSessionId() async throws -> String? {
        try await ensureConnected()
        
        guard let handler = rpcHandler else {
            throw CopilotError.notConnected
        }
        
        let result = try await handler.sendRequest(method: "session.getLastId")
        
        guard let dict = result?.value as? [String: Any] else {
            throw CopilotError.invalidResponse
        }
        
        return dict["sessionId"] as? String
    }
    
    // MARK: - Private Helpers
    
    private func ensureConnected() async throws {
        if connectionState == .disconnected && options.autoStart {
            try await connect()
        }
        
        guard connectionState == .connected else {
            throw CopilotError.notConnected
        }
    }
    
    // MARK: - Message Handlers
    
    private func handleNotification(method: String, params: AnyCodable?) async {
        switch method {
        case "session.event":
            // Decode the event and dispatch to the appropriate session
            guard let paramsDict = params?.value as? [String: Any],
                  let sessionId = paramsDict["sessionId"] as? String,
                  let session = sessions[sessionId] else {
                return
            }
            
            do {
                let data = try JSONSerialization.data(withJSONObject: paramsDict)
                let event = try JSONDecoder().decode(SessionEvent.self, from: data)
                await session.handleEvent(event)
            } catch {
                // Log error but don't crash
                print("Failed to decode session event: \(error)")
            }
            
        default:
            break
        }
    }
    
    private func handleRequest(id: String, method: String, params: AnyCodable?) async -> AnyCodable? {
        switch method {
        case "tool.call":
            // Handle tool invocation
            guard let paramsDict = params?.value as? [String: Any],
                  let sessionId = paramsDict["sessionId"] as? String,
                  let toolCallId = paramsDict["toolCallId"] as? String,
                  let toolName = paramsDict["toolName"] as? String,
                  let session = sessions[sessionId] else {
                return AnyCodable(["error": "Session or tool not found"])
            }
            
            let arguments = paramsDict["arguments"]
            let result = await session.handleToolCall(toolCallId: toolCallId, toolName: toolName, arguments: arguments)
            
            do {
                let encoder = JSONEncoder()
                let resultData = try encoder.encode(result)
                let resultDict = try JSONSerialization.jsonObject(with: resultData)
                return AnyCodable(resultDict)
            } catch {
                return AnyCodable(["textResultForLlm": "Error encoding result", "resultType": "failure"])
            }
            
        case "permission.request":
            // Handle permission request
            guard let paramsDict = params?.value as? [String: Any],
                  let sessionId = paramsDict["sessionId"] as? String,
                  let session = sessions[sessionId] else {
                return AnyCodable(["kind": "deny"])
            }
            
            do {
                let data = try JSONSerialization.data(withJSONObject: paramsDict)
                let request = try JSONDecoder().decode(PermissionRequest.self, from: data)
                let response = try await session.handlePermissionRequest(request)
                
                let encoder = JSONEncoder()
                let responseData = try encoder.encode(response)
                let responseDict = try JSONSerialization.jsonObject(with: responseData)
                return AnyCodable(responseDict)
            } catch {
                return AnyCodable(["kind": "deny"])
            }
            
        case "userInput.request":
            // Handle user input request
            guard let paramsDict = params?.value as? [String: Any],
                  let sessionId = paramsDict["sessionId"] as? String,
                  let session = sessions[sessionId] else {
                return AnyCodable(["error": "Session not found"])
            }
            
            do {
                let data = try JSONSerialization.data(withJSONObject: paramsDict)
                let request = try JSONDecoder().decode(UserInputRequest.self, from: data)
                let response = try await session.handleUserInputRequest(request)
                
                let encoder = JSONEncoder()
                let responseData = try encoder.encode(response)
                let responseDict = try JSONSerialization.jsonObject(with: responseData)
                return AnyCodable(responseDict)
            } catch {
                return AnyCodable(["error": error.localizedDescription])
            }
            
        case "hooks.invoke":
            // Handle hook invocation
            guard let paramsDict = params?.value as? [String: Any],
                  let sessionId = paramsDict["sessionId"] as? String,
                  let hookName = paramsDict["hookName"] as? String,
                  let session = sessions[sessionId] else {
                return nil
            }
            
            let input = paramsDict["input"]
            
            do {
                if let result = try await session.handleHook(hookName: hookName, input: input) {
                    return AnyCodable(result)
                }
                return nil
            } catch {
                return nil
            }
            
        default:
            return nil
        }
    }
}

// MARK: - JSONRPCHandler Extensions

extension JSONRPCHandler {
    func setOnNotification(_ handler: @escaping @Sendable (String, AnyCodable?) async -> Void) {
        onNotification = handler
    }
    
    func setOnRequest(_ handler: @escaping @Sendable (String, String, AnyCodable?) async -> AnyCodable?) {
        onRequest = handler
    }
}
