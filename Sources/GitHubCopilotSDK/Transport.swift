/*---------------------------------------------------------------------------------------------
 *  Copyright (c) Microsoft Corporation. All rights reserved.
 *--------------------------------------------------------------------------------------------*/

import Foundation

#if canImport(Network)
import Network
#endif

// MARK: - Stdio Transport

/// Transport implementation using stdio pipes to communicate with the Copilot CLI process
public actor StdioTransport: Transport {
    private let process: Process
    private let stdin: Pipe
    private let stdout: Pipe
    private let stderr: Pipe
    private var buffer = Data()
    private let encoder = JSONEncoder()
    private var isStarted = false
    
    /// Create a new Stdio transport with the given CLI path and options
    public init(options: CopilotClientOptions) throws {
        process = Process()
        stdin = Pipe()
        stdout = Pipe()
        stderr = Pipe()
        
        process.executableURL = URL(fileURLWithPath: options.cliPath)
        
        var arguments = ["server", "--transport", "stdio"]
        if !options.logLevel.isEmpty {
            arguments.append(contentsOf: ["--log-level", options.logLevel])
        }
        process.arguments = arguments
        
        if let cwd = options.cwd {
            process.currentDirectoryURL = URL(fileURLWithPath: cwd)
        }
        
        // Set up environment
        var environment = ProcessInfo.processInfo.environment
        if let customEnv = options.environment {
            for (key, value) in customEnv {
                environment[key] = value
            }
        }
        
        // Set GitHub token if provided
        if let token = options.githubToken {
            environment["GITHUB_TOKEN"] = token
        }
        
        // Set logged-in user preference
        if let useLoggedIn = options.useLoggedInUser {
            environment["COPILOT_USE_LOGGED_IN_USER"] = useLoggedIn ? "1" : "0"
        } else if options.githubToken != nil {
            // Default to false when token is provided
            environment["COPILOT_USE_LOGGED_IN_USER"] = "0"
        }
        
        process.environment = environment
        
        process.standardInput = stdin
        process.standardOutput = stdout
        process.standardError = stderr
    }
    
    /// Start the CLI process
    public func start() throws {
        guard !isStarted else { return }
        
        do {
            try process.run()
            isStarted = true
        } catch {
            throw CopilotError.processStartFailed(message: error.localizedDescription)
        }
    }
    
    /// Check if the process is running
    public var isRunning: Bool {
        process.isRunning
    }
    
    /// Send a JSON-RPC request
    public func send(_ request: JSONRPCRequest) async throws {
        let data = try encoder.encode(request)
        try await writeMessage(data)
    }
    
    /// Send a JSON-RPC notification
    public func sendNotification(_ notification: JSONRPCNotification) async throws {
        let data = try encoder.encode(notification)
        try await writeMessage(data)
    }
    
    /// Send a JSON-RPC response
    public func sendResponse(_ response: JSONRPCResponse) async throws {
        let data = try encoder.encode(response)
        try await writeMessage(data)
    }
    
    /// Write a message with Content-Length header
    private func writeMessage(_ data: Data) async throws {
        guard isStarted && process.isRunning else {
            throw CopilotError.notConnected
        }
        
        let header = "Content-Length: \(data.count)\r\n\r\n"
        guard let headerData = header.data(using: .utf8) else {
            throw CopilotError.invalidResponse
        }
        
        let message = headerData + data
        stdin.fileHandleForWriting.write(message)
    }
    
    /// Receive the next JSON-RPC message
    public func receive() async throws -> JSONRPCMessage {
        // Read until we have a complete message
        while true {
            // Try to parse a message from the buffer
            if let message = try parseMessage() {
                return message
            }
            
            // Read more data
            let handle = stdout.fileHandleForReading
            let newData = handle.availableData
            
            if newData.isEmpty {
                if !process.isRunning {
                    throw CopilotError.connectionClosed
                }
                // Small delay to prevent busy waiting
                try await Task.sleep(nanoseconds: 10_000_000) // 10ms
                continue
            }
            
            buffer.append(newData)
        }
    }
    
    /// Parse a message from the buffer if we have a complete one
    private func parseMessage() throws -> JSONRPCMessage? {
        guard let headerEnd = findHeaderEnd() else {
            return nil
        }
        
        let headerData = buffer.prefix(headerEnd)
        guard let headerString = String(data: headerData, encoding: .utf8) else {
            throw CopilotError.invalidResponse
        }
        
        // Parse Content-Length
        guard let contentLength = parseContentLength(headerString) else {
            throw CopilotError.invalidResponse
        }
        
        let messageStart = headerEnd + 4 // Skip \r\n\r\n
        let messageEnd = messageStart + contentLength
        
        guard buffer.count >= messageEnd else {
            return nil // Need more data
        }
        
        let messageData = buffer[messageStart..<messageEnd]
        buffer = Data(buffer.suffix(from: messageEnd))
        
        return try JSONRPCMessage(from: messageData)
    }
    
    /// Find the end of the header section (double CRLF)
    private func findHeaderEnd() -> Int? {
        let pattern = Data("\r\n\r\n".utf8)
        guard let range = buffer.range(of: pattern) else {
            return nil
        }
        return range.lowerBound
    }
    
    /// Parse the Content-Length from the header
    private func parseContentLength(_ header: String) -> Int? {
        for line in header.split(separator: "\r\n") {
            let parts = line.split(separator: ":", maxSplits: 1)
            if parts.count == 2 && parts[0].lowercased() == "content-length" {
                return Int(parts[1].trimmingCharacters(in: .whitespaces))
            }
        }
        return nil
    }
    
    /// Close the transport and terminate the process
    public func close() async {
        if process.isRunning {
            process.terminate()
            process.waitUntilExit()
        }
        isStarted = false
    }
}

// MARK: - TCP Transport

/// Transport implementation using TCP socket to communicate with a remote Copilot CLI server
public actor TCPTransport: Transport {
    private let host: String
    private let port: Int
    #if canImport(Network)
    private var connection: NWConnection?
    #else
    private var connection: Any?
    #endif
    private var buffer = Data()
    private let encoder = JSONEncoder()
    private var isConnected = false
    
    /// Parse a CLI URL into host and port
    public static func parseUrl(_ urlString: String) -> (host: String, port: Int)? {
        // Handle various formats:
        // - "8080" -> localhost:8080
        // - "host:8080" -> host:8080
        // - "http://host:8080" -> host:8080
        
        var cleanUrl = urlString
        
        // Remove http:// or https:// prefix
        if cleanUrl.hasPrefix("http://") {
            cleanUrl = String(cleanUrl.dropFirst(7))
        } else if cleanUrl.hasPrefix("https://") {
            cleanUrl = String(cleanUrl.dropFirst(8))
        }
        
        // Remove trailing path
        if let slashIndex = cleanUrl.firstIndex(of: "/") {
            cleanUrl = String(cleanUrl[..<slashIndex])
        }
        
        // Check if it's just a port number
        if let port = Int(cleanUrl) {
            return ("localhost", port)
        }
        
        // Parse host:port
        let parts = cleanUrl.split(separator: ":")
        if parts.count == 2, let port = Int(parts[1]) {
            return (String(parts[0]), port)
        }
        
        return nil
    }
    
    #if canImport(Network)
    /// Create a new TCP transport with the given host and port
    public init(host: String, port: Int) {
        self.host = host
        self.port = port
    }
    /// Connect to the server
    public func connect() async throws {
        let nwEndpoint = NWEndpoint.hostPort(
            host: NWEndpoint.Host(host),
            port: NWEndpoint.Port(integerLiteral: UInt16(port))
        )
        
        let connection = NWConnection(to: nwEndpoint, using: .tcp)
        self.connection = connection
        
        return try await withCheckedThrowingContinuation { continuation in
            connection.stateUpdateHandler = { [weak self] state in
                switch state {
                case .ready:
                    Task { [self] in
                        await self?.setConnected(true)
                    }
                    continuation.resume()
                case .failed(let error):
                    continuation.resume(throwing: CopilotError.connectionFailed(underlying: error))
                case .cancelled:
                    continuation.resume(throwing: CopilotError.connectionClosed)
                default:
                    break
                }
            }
            
            connection.start(queue: .global())
        }
    }
    
    private func setConnected(_ value: Bool) {
        isConnected = value
    }
    
    /// Send a JSON-RPC request
    public func send(_ request: JSONRPCRequest) async throws {
        let data = try encoder.encode(request)
        try await writeMessage(data)
    }
    
    /// Send a JSON-RPC notification
    public func sendNotification(_ notification: JSONRPCNotification) async throws {
        let data = try encoder.encode(notification)
        try await writeMessage(data)
    }
    
    /// Send a JSON-RPC response
    public func sendResponse(_ response: JSONRPCResponse) async throws {
        let data = try encoder.encode(response)
        try await writeMessage(data)
    }
    
    /// Write a message with Content-Length header
    private func writeMessage(_ data: Data) async throws {
        guard let connection = connection, isConnected else {
            throw CopilotError.notConnected
        }
        
        let header = "Content-Length: \(data.count)\r\n\r\n"
        guard let headerData = header.data(using: .utf8) else {
            throw CopilotError.invalidResponse
        }
        
        let message = headerData + data
        
        return try await withCheckedThrowingContinuation { continuation in
            connection.send(content: message, completion: .contentProcessed { error in
                if let error = error {
                    continuation.resume(throwing: CopilotError.connectionFailed(underlying: error))
                } else {
                    continuation.resume()
                }
            })
        }
    }
    
    /// Receive the next JSON-RPC message
    public func receive() async throws -> JSONRPCMessage {
        guard let connection = connection else {
            throw CopilotError.notConnected
        }
        
        // Read until we have a complete message
        while true {
            // Try to parse a message from the buffer
            if let message = try parseMessage() {
                return message
            }
            
            // Read more data
            let newData: Data = try await withCheckedThrowingContinuation { continuation in
                connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { content, _, isComplete, error in
                    if let error = error {
                        continuation.resume(throwing: CopilotError.connectionFailed(underlying: error))
                    } else if let data = content {
                        continuation.resume(returning: data)
                    } else if isComplete {
                        continuation.resume(throwing: CopilotError.connectionClosed)
                    } else {
                        continuation.resume(returning: Data())
                    }
                }
            }
            
            if newData.isEmpty {
                throw CopilotError.connectionClosed
            }
            
            buffer.append(newData)
        }
    }
    
    /// Parse a message from the buffer if we have a complete one
    private func parseMessage() throws -> JSONRPCMessage? {
        guard let headerEnd = findHeaderEnd() else {
            return nil
        }
        
        let headerData = buffer.prefix(headerEnd)
        guard let headerString = String(data: headerData, encoding: .utf8) else {
            throw CopilotError.invalidResponse
        }
        
        // Parse Content-Length
        guard let contentLength = parseContentLength(headerString) else {
            throw CopilotError.invalidResponse
        }
        
        let messageStart = headerEnd + 4 // Skip \r\n\r\n
        let messageEnd = messageStart + contentLength
        
        guard buffer.count >= messageEnd else {
            return nil // Need more data
        }
        
        let messageData = buffer[messageStart..<messageEnd]
        buffer = Data(buffer.suffix(from: messageEnd))
        
        return try JSONRPCMessage(from: messageData)
    }
    
    /// Find the end of the header section (double CRLF)
    private func findHeaderEnd() -> Int? {
        let pattern = Data("\r\n\r\n".utf8)
        guard let range = buffer.range(of: pattern) else {
            return nil
        }
        return range.lowerBound
    }
    
    /// Parse the Content-Length from the header
    private func parseContentLength(_ header: String) -> Int? {
        for line in header.split(separator: "\r\n") {
            let parts = line.split(separator: ":", maxSplits: 1)
            if parts.count == 2 && parts[0].lowercased() == "content-length" {
                return Int(parts[1].trimmingCharacters(in: .whitespaces))
            }
        }
        return nil
    }
    
    /// Close the transport
    public func close() async {
        connection?.cancel()
        connection = nil
        isConnected = false
    }
    
    #else
    // Stub for platforms without Network framework
    public init(host: String, port: Int) {
        self.host = host
        self.port = port
    }
    
    public func connect() async throws {
        throw CopilotError.connectionFailed(underlying: nil)
    }
    
    public func send(_ request: JSONRPCRequest) async throws {
        throw CopilotError.notConnected
    }
    
    public func sendNotification(_ notification: JSONRPCNotification) async throws {
        throw CopilotError.notConnected
    }
    
    public func sendResponse(_ response: JSONRPCResponse) async throws {
        throw CopilotError.notConnected
    }
    
    public func receive() async throws -> JSONRPCMessage {
        throw CopilotError.notConnected
    }
    
    public func close() async {}
    #endif
}
