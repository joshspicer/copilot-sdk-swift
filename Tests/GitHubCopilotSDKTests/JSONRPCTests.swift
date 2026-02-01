/*---------------------------------------------------------------------------------------------
 *  Copyright (c) Microsoft Corporation. All rights reserved.
 *--------------------------------------------------------------------------------------------*/

import XCTest
@testable import GitHubCopilotSDK

final class JSONRPCTests: XCTestCase {
    
    // MARK: - Request Tests
    
    func testJSONRPCRequestEncoding() throws {
        let request = JSONRPCRequest(
            id: "123",
            method: "test.method",
            params: AnyCodable(["key": "value"])
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(request)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        
        XCTAssertEqual(json?["jsonrpc"] as? String, "2.0")
        XCTAssertEqual(json?["id"] as? String, "123")
        XCTAssertEqual(json?["method"] as? String, "test.method")
        
        let params = json?["params"] as? [String: Any]
        XCTAssertEqual(params?["key"] as? String, "value")
    }
    
    func testJSONRPCRequestDecoding() throws {
        let json = """
        {"jsonrpc":"2.0","id":"456","method":"another.method","params":{"count":42}}
        """
        
        let decoder = JSONDecoder()
        let request = try decoder.decode(JSONRPCRequest.self, from: json.data(using: .utf8)!)
        
        XCTAssertEqual(request.jsonrpc, "2.0")
        XCTAssertEqual(request.id, "456")
        XCTAssertEqual(request.method, "another.method")
        
        let params = request.params?.value as? [String: Any]
        XCTAssertEqual(params?["count"] as? Int, 42)
    }
    
    // MARK: - Response Tests
    
    func testJSONRPCResponseWithResult() throws {
        let response = JSONRPCResponse(
            id: "789",
            result: AnyCodable(["success": true]),
            error: nil
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(response)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        
        XCTAssertEqual(json?["jsonrpc"] as? String, "2.0")
        XCTAssertEqual(json?["id"] as? String, "789")
        
        let result = json?["result"] as? [String: Any]
        XCTAssertEqual(result?["success"] as? Bool, true)
    }
    
    func testJSONRPCResponseWithError() throws {
        let error = JSONRPCError(
            code: -32600,
            message: "Invalid Request",
            data: nil
        )
        
        let response = JSONRPCResponse(
            id: "error-test",
            result: nil,
            error: error
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(response)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        
        let errorJson = json?["error"] as? [String: Any]
        XCTAssertEqual(errorJson?["code"] as? Int, -32600)
        XCTAssertEqual(errorJson?["message"] as? String, "Invalid Request")
    }
    
    // MARK: - Notification Tests
    
    func testJSONRPCNotificationEncoding() throws {
        let notification = JSONRPCNotification(
            method: "session.event",
            params: AnyCodable(["type": "session.idle"])
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(notification)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        
        XCTAssertEqual(json?["jsonrpc"] as? String, "2.0")
        XCTAssertEqual(json?["method"] as? String, "session.event")
        XCTAssertNil(json?["id"])
        
        let params = json?["params"] as? [String: Any]
        XCTAssertEqual(params?["type"] as? String, "session.idle")
    }
    
    // MARK: - Message Parsing Tests
    
    func testParseRequest() throws {
        let json = """
        {"jsonrpc":"2.0","id":"req-1","method":"ping","params":{}}
        """
        
        let message = try JSONRPCMessage(from: json.data(using: .utf8)!)
        
        if case .request(let request) = message {
            XCTAssertEqual(request.id, "req-1")
            XCTAssertEqual(request.method, "ping")
        } else {
            XCTFail("Expected request message")
        }
    }
    
    func testParseResponse() throws {
        let json = """
        {"jsonrpc":"2.0","id":"resp-1","result":{"message":"pong"}}
        """
        
        let message = try JSONRPCMessage(from: json.data(using: .utf8)!)
        
        if case .response(let response) = message {
            XCTAssertEqual(response.id, "resp-1")
            XCTAssertNotNil(response.result)
        } else {
            XCTFail("Expected response message")
        }
    }
    
    func testParseNotification() throws {
        let json = """
        {"jsonrpc":"2.0","method":"session.event","params":{"type":"session.start"}}
        """
        
        let message = try JSONRPCMessage(from: json.data(using: .utf8)!)
        
        if case .notification(let notification) = message {
            XCTAssertEqual(notification.method, "session.event")
            XCTAssertNil(notification.jsonrpc == "2.0" ? nil : "wrong version")
        } else {
            XCTFail("Expected notification message")
        }
    }
    
    func testParseInvalidMessage() {
        let json = """
        {"jsonrpc":"1.0","method":"old"}
        """
        
        XCTAssertThrowsError(try JSONRPCMessage(from: json.data(using: .utf8)!)) { error in
            XCTAssertTrue(error is JSONRPCError)
        }
    }
    
    // MARK: - Error Constants Tests
    
    func testJSONRPCErrorCodes() {
        XCTAssertEqual(JSONRPCError.parseError, -32700)
        XCTAssertEqual(JSONRPCError.invalidRequest, -32600)
        XCTAssertEqual(JSONRPCError.methodNotFound, -32601)
        XCTAssertEqual(JSONRPCError.invalidParams, -32602)
        XCTAssertEqual(JSONRPCError.internalError, -32603)
    }
}
