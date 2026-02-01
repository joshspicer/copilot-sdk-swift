/*---------------------------------------------------------------------------------------------
 *  Copyright (c) Microsoft Corporation. All rights reserved.
 *--------------------------------------------------------------------------------------------*/

import XCTest
@testable import GitHubCopilotSDK

final class SessionEventsTests: XCTestCase {
    
    // MARK: - Event Type Tests
    
    func testSessionEventTypeFromRawValue() {
        XCTAssertEqual(SessionEventType(rawValue: "session.start"), .sessionStart)
        XCTAssertEqual(SessionEventType(rawValue: "session.idle"), .sessionIdle)
        XCTAssertEqual(SessionEventType(rawValue: "session.error"), .sessionError)
        XCTAssertEqual(SessionEventType(rawValue: "assistant.message"), .assistantMessage)
        XCTAssertEqual(SessionEventType(rawValue: "tool.execution_start"), .toolExecutionStart)
    }
    
    func testUnknownEventType() {
        // Unknown types should map to .unknown for forward compatibility
        let unknownType = SessionEventType(rawValue: "future.event_type")
        XCTAssertNil(unknownType)
    }
    
    // MARK: - Event Decoding Tests
    
    func testDecodeSessionStartEvent() throws {
        let json = """
        {
            "type": "session.start",
            "sessionId": "test-session-123",
            "model": "gpt-4",
            "timestamp": 1234567890
        }
        """
        
        let decoder = JSONDecoder()
        let event = try decoder.decode(SessionEvent.self, from: json.data(using: .utf8)!)
        
        XCTAssertEqual(event.type, .sessionStart)
        
        if case .sessionStart(let data) = event.data {
            XCTAssertEqual(data.sessionId, "test-session-123")
            XCTAssertEqual(data.model, "gpt-4")
            XCTAssertEqual(data.timestamp, 1234567890)
        } else {
            XCTFail("Expected sessionStart data")
        }
    }
    
    func testDecodeSessionIdleEvent() throws {
        let json = """
        {
            "type": "session.idle",
            "sessionId": "idle-session",
            "timestamp": 1234567891
        }
        """
        
        let decoder = JSONDecoder()
        let event = try decoder.decode(SessionEvent.self, from: json.data(using: .utf8)!)
        
        XCTAssertEqual(event.type, .sessionIdle)
    }
    
    func testDecodeSessionErrorEvent() throws {
        let json = """
        {
            "type": "session.error",
            "error": "Something went wrong",
            "code": "INTERNAL_ERROR",
            "sessionId": "error-session",
            "timestamp": 1234567892
        }
        """
        
        let decoder = JSONDecoder()
        let event = try decoder.decode(SessionEvent.self, from: json.data(using: .utf8)!)
        
        XCTAssertEqual(event.type, .sessionError)
        
        if case .sessionError(let data) = event.data {
            XCTAssertEqual(data.error, "Something went wrong")
            XCTAssertEqual(data.code, "INTERNAL_ERROR")
        } else {
            XCTFail("Expected sessionError data")
        }
    }
    
    func testDecodeAssistantMessageEvent() throws {
        let json = """
        {
            "type": "assistant.message",
            "content": "Hello! How can I help you?",
            "messageId": "msg-123",
            "sessionId": "chat-session",
            "timestamp": 1234567893
        }
        """
        
        let decoder = JSONDecoder()
        let event = try decoder.decode(SessionEvent.self, from: json.data(using: .utf8)!)
        
        XCTAssertEqual(event.type, .assistantMessage)
        
        if case .assistantMessage(let data) = event.data {
            XCTAssertEqual(data.content, "Hello! How can I help you?")
            XCTAssertEqual(data.messageId, "msg-123")
        } else {
            XCTFail("Expected assistantMessage data")
        }
    }
    
    func testDecodeAssistantMessageDeltaEvent() throws {
        let json = """
        {
            "type": "assistant.message_delta",
            "deltaContent": "Hello",
            "messageId": "msg-124",
            "sessionId": "streaming-session",
            "timestamp": 1234567894
        }
        """
        
        let decoder = JSONDecoder()
        let event = try decoder.decode(SessionEvent.self, from: json.data(using: .utf8)!)
        
        XCTAssertEqual(event.type, .assistantMessageDelta)
        
        if case .assistantMessageDelta(let data) = event.data {
            XCTAssertEqual(data.deltaContent, "Hello")
        } else {
            XCTFail("Expected assistantMessageDelta data")
        }
    }
    
    func testDecodeToolExecutionStartEvent() throws {
        let json = """
        {
            "type": "tool.execution_start",
            "toolName": "read_file",
            "toolCallId": "call-456",
            "arguments": {"path": "/test.txt"},
            "sessionId": "tool-session",
            "timestamp": 1234567895
        }
        """
        
        let decoder = JSONDecoder()
        let event = try decoder.decode(SessionEvent.self, from: json.data(using: .utf8)!)
        
        XCTAssertEqual(event.type, .toolExecutionStart)
        
        if case .toolExecutionStart(let data) = event.data {
            XCTAssertEqual(data.toolName, "read_file")
            XCTAssertEqual(data.toolCallId, "call-456")
        } else {
            XCTFail("Expected toolExecutionStart data")
        }
    }
    
    func testDecodeToolExecutionCompleteEvent() throws {
        let json = """
        {
            "type": "tool.execution_complete",
            "toolName": "read_file",
            "toolCallId": "call-456",
            "result": "file contents here",
            "resultType": "success",
            "sessionId": "tool-session",
            "timestamp": 1234567896
        }
        """
        
        let decoder = JSONDecoder()
        let event = try decoder.decode(SessionEvent.self, from: json.data(using: .utf8)!)
        
        XCTAssertEqual(event.type, .toolExecutionComplete)
        
        if case .toolExecutionComplete(let data) = event.data {
            XCTAssertEqual(data.toolName, "read_file")
            XCTAssertEqual(data.resultType, "success")
        } else {
            XCTFail("Expected toolExecutionComplete data")
        }
    }
    
    func testDecodeUserMessageEvent() throws {
        let json = """
        {
            "type": "user.message",
            "content": "What is Swift?",
            "messageId": "user-msg-1",
            "sessionId": "chat-session",
            "timestamp": 1234567897
        }
        """
        
        let decoder = JSONDecoder()
        let event = try decoder.decode(SessionEvent.self, from: json.data(using: .utf8)!)
        
        XCTAssertEqual(event.type, .userMessage)
        
        if case .userMessage(let data) = event.data {
            XCTAssertEqual(data.content, "What is Swift?")
        } else {
            XCTFail("Expected userMessage data")
        }
    }
    
    func testDecodeCompactionEvents() throws {
        let startJson = """
        {
            "type": "session.compaction_start",
            "sessionId": "compaction-session",
            "timestamp": 1234567898
        }
        """
        
        let completeJson = """
        {
            "type": "session.compaction_complete",
            "sessionId": "compaction-session",
            "tokensBefore": 100000,
            "tokensAfter": 50000,
            "timestamp": 1234567899
        }
        """
        
        let decoder = JSONDecoder()
        
        let startEvent = try decoder.decode(SessionEvent.self, from: startJson.data(using: .utf8)!)
        XCTAssertEqual(startEvent.type, .sessionCompactionStart)
        
        let completeEvent = try decoder.decode(SessionEvent.self, from: completeJson.data(using: .utf8)!)
        XCTAssertEqual(completeEvent.type, .sessionCompactionComplete)
        
        if case .sessionCompactionComplete(let data) = completeEvent.data {
            XCTAssertEqual(data.tokensBefore, 100000)
            XCTAssertEqual(data.tokensAfter, 50000)
        } else {
            XCTFail("Expected compaction complete data")
        }
    }
    
    // MARK: - Forward Compatibility Tests
    
    func testDecodeUnknownEventType() throws {
        let json = """
        {
            "type": "future.new_event",
            "someField": "someValue",
            "timestamp": 1234567900
        }
        """
        
        let decoder = JSONDecoder()
        let event = try decoder.decode(SessionEvent.self, from: json.data(using: .utf8)!)
        
        // Should decode as unknown type without throwing
        XCTAssertEqual(event.type, .unknown)
    }
    
    // MARK: - Event Creation Tests
    
    func testCreateSessionEvent() {
        let event = SessionEvent(type: .sessionIdle, data: nil)
        XCTAssertEqual(event.type, .sessionIdle)
    }
}
