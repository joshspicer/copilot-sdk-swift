/*---------------------------------------------------------------------------------------------
 *  Copyright (c) Microsoft Corporation. All rights reserved.
 *--------------------------------------------------------------------------------------------*/

import Foundation

// MARK: - JSON-RPC Types

/// JSON-RPC 2.0 request message
public struct JSONRPCRequest: Codable, Sendable {
    public let jsonrpc: String
    public let id: String?
    public let method: String
    public let params: AnyCodable?
    
    public init(id: String?, method: String, params: AnyCodable? = nil) {
        self.jsonrpc = "2.0"
        self.id = id
        self.method = method
        self.params = params
    }
}

/// JSON-RPC 2.0 response message
public struct JSONRPCResponse: Codable, Sendable {
    public let jsonrpc: String
    public let id: String?
    public let result: AnyCodable?
    public let error: JSONRPCError?
    
    public init(id: String?, result: AnyCodable? = nil, error: JSONRPCError? = nil) {
        self.jsonrpc = "2.0"
        self.id = id
        self.result = result
        self.error = error
    }
}

/// JSON-RPC 2.0 error object
public struct JSONRPCError: Codable, Sendable, Error {
    public let code: Int
    public let message: String
    public let data: AnyCodable?
    
    public init(code: Int, message: String, data: AnyCodable? = nil) {
        self.code = code
        self.message = message
        self.data = data
    }
    
    // Standard JSON-RPC error codes
    public static let parseError = -32700
    public static let invalidRequest = -32600
    public static let methodNotFound = -32601
    public static let invalidParams = -32602
    public static let internalError = -32603
}

/// JSON-RPC 2.0 notification message (no id)
public struct JSONRPCNotification: Codable, Sendable {
    public let jsonrpc: String
    public let method: String
    public let params: AnyCodable?
    
    public init(method: String, params: AnyCodable? = nil) {
        self.jsonrpc = "2.0"
        self.method = method
        self.params = params
    }
}

// MARK: - Message Envelope

/// A union type that can represent any JSON-RPC message
public enum JSONRPCMessage: Sendable {
    case request(JSONRPCRequest)
    case response(JSONRPCResponse)
    case notification(JSONRPCNotification)
    
    public init(from data: Data) throws {
        let decoder = JSONDecoder()
        
        // First try to decode as a generic dictionary to inspect the structure
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw JSONRPCError(code: JSONRPCError.parseError, message: "Failed to parse JSON")
        }
        
        // Check for required JSON-RPC version
        guard let jsonrpc = json["jsonrpc"] as? String, jsonrpc == "2.0" else {
            throw JSONRPCError(code: JSONRPCError.invalidRequest, message: "Invalid or missing jsonrpc version")
        }
        
        let hasId = json["id"] != nil
        let hasMethod = json["method"] != nil
        let hasResult = json["result"] != nil
        let hasError = json["error"] != nil
        
        if hasMethod && hasId {
            // Request
            self = .request(try decoder.decode(JSONRPCRequest.self, from: data))
        } else if hasMethod && !hasId {
            // Notification
            self = .notification(try decoder.decode(JSONRPCNotification.self, from: data))
        } else if (hasResult || hasError) && hasId {
            // Response
            self = .response(try decoder.decode(JSONRPCResponse.self, from: data))
        } else {
            throw JSONRPCError(code: JSONRPCError.invalidRequest, message: "Invalid JSON-RPC message structure")
        }
    }
    
    public func encode() throws -> Data {
        let encoder = JSONEncoder()
        switch self {
        case .request(let request):
            return try encoder.encode(request)
        case .response(let response):
            return try encoder.encode(response)
        case .notification(let notification):
            return try encoder.encode(notification)
        }
    }
}

// MARK: - Pending Request

/// Represents a pending JSON-RPC request awaiting a response
actor PendingRequest {
    private var continuation: CheckedContinuation<JSONRPCResponse, Error>?
    private var completed = false
    
    func wait() async throws -> JSONRPCResponse {
        try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
        }
    }
    
    func complete(with response: JSONRPCResponse) {
        guard !completed else { return }
        completed = true
        continuation?.resume(returning: response)
    }
    
    func fail(with error: Error) {
        guard !completed else { return }
        completed = true
        continuation?.resume(throwing: error)
    }
}

// MARK: - JSONRPC Handler

/// Handles JSON-RPC communication with the Copilot CLI server
public actor JSONRPCHandler {
    private let transport: Transport
    private var pendingRequests: [String: PendingRequest] = [:]
    private var requestIdCounter: Int = 0
    private var isRunning = false
    
    /// Handler for incoming notifications
    public var onNotification: (@Sendable (String, AnyCodable?) async -> Void)?
    
    /// Handler for incoming requests (server calling client)
    public var onRequest: (@Sendable (String, String, AnyCodable?) async -> AnyCodable?)?
    
    public init(transport: Transport) {
        self.transport = transport
    }
    
    /// Generate a unique request ID
    private func nextRequestId() -> String {
        requestIdCounter += 1
        return "\(requestIdCounter)"
    }
    
    /// Start the message receive loop
    public func start() async {
        guard !isRunning else { return }
        isRunning = true
        
        await receiveLoop()
    }
    
    /// Stop the message receive loop
    public func stop() {
        isRunning = false
        // Cancel all pending requests
        for (_, pending) in pendingRequests {
            Task {
                await pending.fail(with: CopilotError.connectionClosed)
            }
        }
        pendingRequests.removeAll()
    }
    
    /// Send a request and wait for a response
    public func sendRequest(method: String, params: AnyCodable? = nil) async throws -> AnyCodable? {
        let id = nextRequestId()
        let request = JSONRPCRequest(id: id, method: method, params: params)
        
        let pending = PendingRequest()
        pendingRequests[id] = pending
        
        do {
            try await transport.send(request)
            let response = try await pending.wait()
            pendingRequests.removeValue(forKey: id)
            
            if let error = response.error {
                throw error
            }
            
            return response.result
        } catch {
            pendingRequests.removeValue(forKey: id)
            throw error
        }
    }
    
    /// Send a notification (no response expected)
    public func sendNotification(method: String, params: AnyCodable? = nil) async throws {
        let notification = JSONRPCNotification(method: method, params: params)
        try await transport.sendNotification(notification)
    }
    
    /// Send a response to an incoming request
    public func sendResponse(id: String, result: AnyCodable? = nil, error: JSONRPCError? = nil) async throws {
        let response = JSONRPCResponse(id: id, result: result, error: error)
        try await transport.sendResponse(response)
    }
    
    /// Receive loop that processes incoming messages
    private func receiveLoop() async {
        while isRunning {
            do {
                let message = try await transport.receive()
                await handleMessage(message)
            } catch {
                if isRunning {
                    // Log error but continue if still running
                    // In production, consider adding error callback
                    continue
                }
                break
            }
        }
    }
    
    /// Handle an incoming message
    private func handleMessage(_ message: JSONRPCMessage) async {
        switch message {
        case .response(let response):
            if let id = response.id, let pending = pendingRequests[id] {
                await pending.complete(with: response)
            }
            
        case .notification(let notification):
            await onNotification?(notification.method, notification.params)
            
        case .request(let request):
            // Server is calling us (e.g., tool invocation)
            if let id = request.id, let handler = onRequest {
                let result = await handler(id, request.method, request.params)
                try? await sendResponse(id: id, result: result)
            }
        }
    }
}

// MARK: - Transport Protocol

/// Protocol for JSON-RPC transport implementations
public protocol Transport: Sendable {
    func send(_ request: JSONRPCRequest) async throws
    func sendNotification(_ notification: JSONRPCNotification) async throws
    func sendResponse(_ response: JSONRPCResponse) async throws
    func receive() async throws -> JSONRPCMessage
    func close() async
}

// MARK: - Errors

/// Errors that can occur during Copilot SDK operations
public enum CopilotError: Error, LocalizedError {
    case connectionClosed
    case connectionFailed(underlying: Error?)
    case invalidResponse
    case processStartFailed(message: String)
    case protocolVersionMismatch(expected: Int, actual: Int)
    case timeout
    case notConnected
    case sessionNotFound(sessionId: String)
    case toolError(message: String)
    case permissionDenied(message: String)
    
    public var errorDescription: String? {
        switch self {
        case .connectionClosed:
            return "Connection to Copilot CLI was closed"
        case .connectionFailed(let underlying):
            if let underlying = underlying {
                return "Failed to connect to Copilot CLI: \(underlying.localizedDescription)"
            }
            return "Failed to connect to Copilot CLI"
        case .invalidResponse:
            return "Received invalid response from Copilot CLI"
        case .processStartFailed(let message):
            return "Failed to start Copilot CLI process: \(message)"
        case .protocolVersionMismatch(let expected, let actual):
            return "Protocol version mismatch: SDK expects \(expected), CLI reports \(actual)"
        case .timeout:
            return "Operation timed out"
        case .notConnected:
            return "Not connected to Copilot CLI"
        case .sessionNotFound(let sessionId):
            return "Session not found: \(sessionId)"
        case .toolError(let message):
            return "Tool error: \(message)"
        case .permissionDenied(let message):
            return "Permission denied: \(message)"
        }
    }
}
