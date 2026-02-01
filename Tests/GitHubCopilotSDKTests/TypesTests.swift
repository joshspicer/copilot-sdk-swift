/*---------------------------------------------------------------------------------------------
 *  Copyright (c) Microsoft Corporation. All rights reserved.
 *--------------------------------------------------------------------------------------------*/

import XCTest
@testable import GitHubCopilotSDK

final class TypesTests: XCTestCase {
    
    // MARK: - AnyCodable Tests
    
    func testAnyCodableEncodesString() throws {
        let value = AnyCodable("hello")
        let encoder = JSONEncoder()
        let data = try encoder.encode(value)
        let json = String(data: data, encoding: .utf8)
        XCTAssertEqual(json, "\"hello\"")
    }
    
    func testAnyCodableEncodesNumber() throws {
        let value = AnyCodable(42)
        let encoder = JSONEncoder()
        let data = try encoder.encode(value)
        let json = String(data: data, encoding: .utf8)
        XCTAssertEqual(json, "42")
    }
    
    func testAnyCodableEncodesBoolean() throws {
        let value = AnyCodable(true)
        let encoder = JSONEncoder()
        let data = try encoder.encode(value)
        let json = String(data: data, encoding: .utf8)
        XCTAssertEqual(json, "true")
    }
    
    func testAnyCodableEncodesArray() throws {
        let value = AnyCodable([1, 2, 3])
        let encoder = JSONEncoder()
        let data = try encoder.encode(value)
        let json = String(data: data, encoding: .utf8)
        XCTAssertEqual(json, "[1,2,3]")
    }
    
    func testAnyCodableEncodesDictionary() throws {
        let value = AnyCodable(["key": "value"])
        let encoder = JSONEncoder()
        let data = try encoder.encode(value)
        let json = String(data: data, encoding: .utf8)
        XCTAssertEqual(json, "{\"key\":\"value\"}")
    }
    
    func testAnyCodableDecodesString() throws {
        let json = "\"hello\""
        let decoder = JSONDecoder()
        let value = try decoder.decode(AnyCodable.self, from: json.data(using: .utf8)!)
        XCTAssertEqual(value.value as? String, "hello")
    }
    
    func testAnyCodableDecodesNumber() throws {
        let json = "42"
        let decoder = JSONDecoder()
        let value = try decoder.decode(AnyCodable.self, from: json.data(using: .utf8)!)
        XCTAssertEqual(value.value as? Int, 42)
    }
    
    // MARK: - SystemMessageConfig Tests
    
    func testSystemMessageAppend() {
        let config = SystemMessageConfig.append(content: "Additional instructions")
        XCTAssertEqual(config.mode, .append)
        XCTAssertEqual(config.content, "Additional instructions")
    }
    
    func testSystemMessageReplace() {
        let config = SystemMessageConfig.replace(content: "Custom system message")
        XCTAssertEqual(config.mode, .replace)
        XCTAssertEqual(config.content, "Custom system message")
    }
    
    // MARK: - ProviderConfig Tests
    
    func testProviderConfigEncoding() throws {
        let provider = ProviderConfig(
            baseUrl: "https://api.openai.com/v1",
            type: "openai",
            apiKey: "sk-test"
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(provider)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        
        XCTAssertEqual(json?["baseUrl"] as? String, "https://api.openai.com/v1")
        XCTAssertEqual(json?["type"] as? String, "openai")
        XCTAssertEqual(json?["apiKey"] as? String, "sk-test")
    }
    
    // MARK: - Attachment Tests
    
    func testFileAttachment() {
        let attachment = Attachment.file("/path/to/file.swift")
        XCTAssertEqual(attachment.type, "file")
        XCTAssertEqual(attachment.path, "/path/to/file.swift")
    }
    
    func testDirectoryAttachment() {
        let attachment = Attachment.directory("/path/to/directory")
        XCTAssertEqual(attachment.type, "directory")
        XCTAssertEqual(attachment.path, "/path/to/directory")
    }
    
    // MARK: - SessionConfig Tests
    
    func testSessionConfigDefaults() {
        let config = SessionConfig()
        XCTAssertNil(config.sessionId)
        XCTAssertNil(config.model)
        XCTAssertTrue(config.tools.isEmpty)
        XCTAssertFalse(config.streaming)
    }
    
    func testSessionConfigCustomValues() {
        let config = SessionConfig(
            sessionId: "test-session",
            model: "gpt-4",
            streaming: true
        )
        XCTAssertEqual(config.sessionId, "test-session")
        XCTAssertEqual(config.model, "gpt-4")
        XCTAssertTrue(config.streaming)
    }
    
    // MARK: - InfiniteSessionConfig Tests
    
    func testInfiniteSessionConfigDefaults() {
        let config = InfiniteSessionConfig()
        XCTAssertNil(config.enabled)
        XCTAssertNil(config.backgroundCompactionThreshold)
        XCTAssertNil(config.bufferExhaustionThreshold)
    }
    
    func testInfiniteSessionConfigCustomValues() {
        let config = InfiniteSessionConfig(
            enabled: true,
            backgroundCompactionThreshold: 0.8,
            bufferExhaustionThreshold: 0.95
        )
        XCTAssertEqual(config.enabled, true)
        XCTAssertEqual(config.backgroundCompactionThreshold, 0.8)
        XCTAssertEqual(config.bufferExhaustionThreshold, 0.95)
    }
    
    // MARK: - McpServerConfig Tests
    
    func testMcpLocalServerConfig() throws {
        let config = McpLocalServerConfig(
            command: "npx",
            args: ["-y", "@modelcontextprotocol/server-filesystem"],
            tools: ["*"]
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(config)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        
        XCTAssertEqual(json?["command"] as? String, "npx")
        XCTAssertEqual(json?["args"] as? [String], ["-y", "@modelcontextprotocol/server-filesystem"])
        XCTAssertEqual(json?["tools"] as? [String], ["*"])
    }
    
    func testMcpRemoteServerConfig() throws {
        let config = McpRemoteServerConfig(
            url: "https://mcp.example.com",
            type: "http",
            tools: ["tool1", "tool2"]
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(config)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        
        XCTAssertEqual(json?["url"] as? String, "https://mcp.example.com")
        XCTAssertEqual(json?["type"] as? String, "http")
        XCTAssertEqual(json?["tools"] as? [String], ["tool1", "tool2"])
    }
    
    // MARK: - Response Types Tests
    
    func testPingResponseDecoding() throws {
        let json = """
        {"message":"pong","timestamp":1234567890,"protocolVersion":2}
        """
        
        let decoder = JSONDecoder()
        let response = try decoder.decode(PingResponse.self, from: json.data(using: .utf8)!)
        
        XCTAssertEqual(response.message, "pong")
        XCTAssertEqual(response.timestamp, 1234567890)
        XCTAssertEqual(response.protocolVersion, 2)
    }
    
    func testGetAuthStatusResponseDecoding() throws {
        let json = """
        {"isAuthenticated":true,"authType":"token","host":"github.com","login":"user123"}
        """
        
        let decoder = JSONDecoder()
        let response = try decoder.decode(GetAuthStatusResponse.self, from: json.data(using: .utf8)!)
        
        XCTAssertTrue(response.isAuthenticated)
        XCTAssertEqual(response.authType, "token")
        XCTAssertEqual(response.host, "github.com")
        XCTAssertEqual(response.login, "user123")
    }
    
    func testModelInfoDecoding() throws {
        let json = """
        {
            "id": "gpt-4",
            "name": "GPT-4",
            "capabilities": {
                "supports": {"vision": true, "reasoningEffort": false},
                "limits": {"max_context_window_tokens": 128000}
            }
        }
        """
        
        let decoder = JSONDecoder()
        let model = try decoder.decode(ModelInfo.self, from: json.data(using: .utf8)!)
        
        XCTAssertEqual(model.id, "gpt-4")
        XCTAssertEqual(model.name, "GPT-4")
        XCTAssertTrue(model.capabilities.supports.vision)
        XCTAssertFalse(model.capabilities.supports.reasoningEffort)
        XCTAssertEqual(model.capabilities.limits.maxContextWindowTokens, 128000)
    }
}
