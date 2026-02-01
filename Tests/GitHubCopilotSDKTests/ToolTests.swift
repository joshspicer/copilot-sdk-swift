/*---------------------------------------------------------------------------------------------
 *  Copyright (c) Microsoft Corporation. All rights reserved.
 *--------------------------------------------------------------------------------------------*/

import XCTest
@testable import GitHubCopilotSDK

final class ToolTests: XCTestCase {
    
    // MARK: - Tool Creation Tests
    
    func testToolCreation() {
        let tool = Tool(
            name: "test_tool",
            description: "A test tool",
            parameters: JSONSchema.object(
                properties: [
                    "input": JSONSchema.string(description: "Input value")
                ],
                required: ["input"]
            )
        ) { _ in
            .success("result")
        }
        
        XCTAssertEqual(tool.name, "test_tool")
        XCTAssertEqual(tool.description, "A test tool")
        XCTAssertNotNil(tool.parameters["properties"])
    }
    
    func testSimpleTool() async throws {
        let tool = Tool.simple(
            name: "simple_tool",
            description: "A simple tool"
        ) {
            return "Hello, World!"
        }
        
        XCTAssertEqual(tool.name, "simple_tool")
        XCTAssertEqual(tool.description, "A simple tool")
        
        // Test handler
        let invocation = ToolInvocation(
            sessionId: "test",
            toolCallId: "call-1",
            toolName: "simple_tool",
            arguments: nil
        )
        
        let result = try await tool.handler(invocation)
        XCTAssertEqual(result.textResultForLlm, "Hello, World!")
        XCTAssertEqual(result.resultType, "success")
    }
    
    // MARK: - ToolResult Tests
    
    func testToolResultSuccess() {
        let result = ToolResult.success("Operation completed")
        XCTAssertEqual(result.textResultForLlm, "Operation completed")
        XCTAssertEqual(result.resultType, "success")
        XCTAssertNil(result.error)
    }
    
    func testToolResultFailure() {
        let result = ToolResult.failure("Operation failed", error: "Internal error")
        XCTAssertEqual(result.textResultForLlm, "Operation failed")
        XCTAssertEqual(result.resultType, "failure")
        XCTAssertEqual(result.error, "Internal error")
    }
    
    func testToolResultRejected() {
        let result = ToolResult.rejected("User rejected the operation")
        XCTAssertEqual(result.textResultForLlm, "User rejected the operation")
        XCTAssertEqual(result.resultType, "rejected")
    }
    
    func testToolResultDenied() {
        let result = ToolResult.denied("Permission denied")
        XCTAssertEqual(result.textResultForLlm, "Permission denied")
        XCTAssertEqual(result.resultType, "denied")
    }
    
    // MARK: - ToolInvocation Tests
    
    func testToolInvocationGetString() {
        let invocation = ToolInvocation(
            sessionId: "test",
            toolCallId: "call-1",
            toolName: "test_tool",
            arguments: ["name": "John", "age": 30]
        )
        
        XCTAssertEqual(invocation.getString("name"), "John")
        XCTAssertNil(invocation.getString("missing"))
    }
    
    func testToolInvocationGetInt() {
        let invocation = ToolInvocation(
            sessionId: "test",
            toolCallId: "call-1",
            toolName: "test_tool",
            arguments: ["count": 42]
        )
        
        XCTAssertEqual(invocation.getInt("count"), 42)
        XCTAssertNil(invocation.getInt("missing"))
    }
    
    func testToolInvocationGetBool() {
        let invocation = ToolInvocation(
            sessionId: "test",
            toolCallId: "call-1",
            toolName: "test_tool",
            arguments: ["enabled": true]
        )
        
        XCTAssertEqual(invocation.getBool("enabled"), true)
        XCTAssertNil(invocation.getBool("missing"))
    }
    
    func testToolInvocationDecodeArguments() throws {
        struct TestArgs: Decodable {
            let name: String
            let count: Int
        }
        
        let invocation = ToolInvocation(
            sessionId: "test",
            toolCallId: "call-1",
            toolName: "test_tool",
            arguments: ["name": "Test", "count": 5]
        )
        
        let args: TestArgs = try invocation.decodeArguments(TestArgs.self)
        XCTAssertEqual(args.name, "Test")
        XCTAssertEqual(args.count, 5)
    }
    
    // MARK: - ToolBinaryResult Tests
    
    func testToolBinaryResultFromData() {
        let data = "Hello".data(using: .utf8)!
        let result = ToolBinaryResult.from(data: data, mimeType: "text/plain", description: "Test data")
        
        XCTAssertEqual(result.mimeType, "text/plain")
        XCTAssertEqual(result.type, "binary")
        XCTAssertEqual(result.description, "Test data")
        XCTAssertEqual(result.data, data.base64EncodedString())
    }
    
    // MARK: - JSONSchema Tests
    
    func testJSONSchemaObject() {
        let schema = JSONSchema.object(
            properties: [
                "name": JSONSchema.string(description: "Name field"),
                "age": JSONSchema.integer(description: "Age field")
            ],
            required: ["name"]
        )
        
        XCTAssertEqual(schema["type"] as? String, "object")
        XCTAssertNotNil(schema["properties"])
        XCTAssertEqual(schema["required"] as? [String], ["name"])
    }
    
    func testJSONSchemaString() {
        let schema = JSONSchema.string(description: "A string field", enumValues: ["a", "b", "c"])
        
        XCTAssertEqual(schema["type"] as? String, "string")
        XCTAssertEqual(schema["description"] as? String, "A string field")
        XCTAssertEqual(schema["enum"] as? [String], ["a", "b", "c"])
    }
    
    func testJSONSchemaNumber() {
        let schema = JSONSchema.number(description: "A number field", minimum: 0, maximum: 100)
        
        XCTAssertEqual(schema["type"] as? String, "number")
        XCTAssertEqual(schema["description"] as? String, "A number field")
        XCTAssertEqual(schema["minimum"] as? Double, 0)
        XCTAssertEqual(schema["maximum"] as? Double, 100)
    }
    
    func testJSONSchemaInteger() {
        let schema = JSONSchema.integer(description: "An integer field", minimum: 1, maximum: 10)
        
        XCTAssertEqual(schema["type"] as? String, "integer")
        XCTAssertEqual(schema["minimum"] as? Int, 1)
        XCTAssertEqual(schema["maximum"] as? Int, 10)
    }
    
    func testJSONSchemaBoolean() {
        let schema = JSONSchema.boolean(description: "A boolean field")
        
        XCTAssertEqual(schema["type"] as? String, "boolean")
        XCTAssertEqual(schema["description"] as? String, "A boolean field")
    }
    
    func testJSONSchemaArray() {
        let schema = JSONSchema.array(
            items: JSONSchema.string(),
            description: "An array of strings"
        )
        
        XCTAssertEqual(schema["type"] as? String, "array")
        XCTAssertEqual(schema["description"] as? String, "An array of strings")
        XCTAssertNotNil(schema["items"])
    }
    
    // MARK: - Tool RPC Params Tests
    
    func testToolToRPCParams() {
        let tool = Tool(
            name: "my_tool",
            description: "My tool description",
            parameters: JSONSchema.object(
                properties: ["input": JSONSchema.string()]
            )
        ) { _ in
            .success("done")
        }
        
        let params = tool.toRPCParams()
        
        XCTAssertEqual(params["name"] as? String, "my_tool")
        XCTAssertEqual(params["description"] as? String, "My tool description")
        XCTAssertNotNil(params["parameters"])
    }
    
    func testToolArrayToRPCParams() {
        let tools = [
            Tool(name: "tool1", description: "First tool") { _ in .success("1") },
            Tool(name: "tool2", description: "Second tool") { _ in .success("2") }
        ]
        
        let params = tools.toRPCParams()
        
        XCTAssertEqual(params.count, 2)
        XCTAssertEqual(params[0]["name"] as? String, "tool1")
        XCTAssertEqual(params[1]["name"] as? String, "tool2")
    }
}
