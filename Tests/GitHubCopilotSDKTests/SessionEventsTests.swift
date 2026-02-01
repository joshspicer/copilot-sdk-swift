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
        // Test new event types
        XCTAssertEqual(SessionEventType(rawValue: "session.info"), .sessionInfo)
        XCTAssertEqual(SessionEventType(rawValue: "session.model_change"), .sessionModelChange)
        XCTAssertEqual(SessionEventType(rawValue: "assistant.turn_start"), .assistantTurnStart)
        XCTAssertEqual(SessionEventType(rawValue: "assistant.usage"), .assistantUsage)
        XCTAssertEqual(SessionEventType(rawValue: "tool.user_requested"), .toolUserRequested)
        XCTAssertEqual(SessionEventType(rawValue: "subagent.started"), .subagentStarted)
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
            "selectedModel": "gpt-4",
            "version": 2,
            "producer": "copilot-sdk",
            "copilotVersion": "1.0.0",
            "startTime": "2024-01-01T00:00:00Z"
        }
        """
        
        let decoder = JSONDecoder()
        let event = try decoder.decode(SessionEvent.self, from: json.data(using: .utf8)!)
        
        XCTAssertEqual(event.type, .sessionStart)
        
        if case .sessionStart(let data) = event.data {
            XCTAssertEqual(data.sessionId, "test-session-123")
            XCTAssertEqual(data.selectedModel, "gpt-4")
            XCTAssertEqual(data.version, 2)
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
            "errorType": "internal_error",
            "message": "Something went wrong",
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
            XCTAssertEqual(data.message, "Something went wrong")
            XCTAssertEqual(data.errorType, "internal_error")
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
            "success": true,
            "result": {"content": "file contents here"},
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
            XCTAssertEqual(data.success, true)
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
            "success": true,
            "preCompactionTokens": 100000,
            "postCompactionTokens": 50000,
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
            XCTAssertEqual(data.preCompactionTokens, 100000)
            XCTAssertEqual(data.postCompactionTokens, 50000)
        } else {
            XCTFail("Expected compaction complete data")
        }
    }
    
    // MARK: - New Event Type Tests
    
    func testDecodeSessionInfoEvent() throws {
        let json = """
        {
            "type": "session.info",
            "infoType": "notification",
            "message": "Model updated"
        }
        """
        
        let decoder = JSONDecoder()
        let event = try decoder.decode(SessionEvent.self, from: json.data(using: .utf8)!)
        
        XCTAssertEqual(event.type, .sessionInfo)
        
        if case .sessionInfo(let data) = event.data {
            XCTAssertEqual(data.infoType, "notification")
            XCTAssertEqual(data.message, "Model updated")
        } else {
            XCTFail("Expected sessionInfo data")
        }
    }
    
    func testDecodeAssistantTurnStartEvent() throws {
        let json = """
        {
            "type": "assistant.turn_start",
            "turnId": "turn-123"
        }
        """
        
        let decoder = JSONDecoder()
        let event = try decoder.decode(SessionEvent.self, from: json.data(using: .utf8)!)
        
        XCTAssertEqual(event.type, .assistantTurnStart)
        
        if case .assistantTurnStart(let data) = event.data {
            XCTAssertEqual(data.turnId, "turn-123")
        } else {
            XCTFail("Expected assistantTurnStart data")
        }
    }
    
    func testDecodeAssistantUsageEvent() throws {
        let json = """
        {
            "type": "assistant.usage",
            "model": "gpt-4",
            "inputTokens": 100,
            "outputTokens": 50
        }
        """
        
        let decoder = JSONDecoder()
        let event = try decoder.decode(SessionEvent.self, from: json.data(using: .utf8)!)
        
        XCTAssertEqual(event.type, .assistantUsage)
        
        if case .assistantUsage(let data) = event.data {
            XCTAssertEqual(data.model, "gpt-4")
            XCTAssertEqual(data.inputTokens, 100)
            XCTAssertEqual(data.outputTokens, 50)
        } else {
            XCTFail("Expected assistantUsage data")
        }
    }
    
    func testDecodeSubagentStartedEvent() throws {
        let json = """
        {
            "type": "subagent.started",
            "toolCallId": "call-789",
            "agentName": "code-reviewer",
            "agentDisplayName": "Code Reviewer",
            "agentDescription": "Reviews code for issues"
        }
        """
        
        let decoder = JSONDecoder()
        let event = try decoder.decode(SessionEvent.self, from: json.data(using: .utf8)!)
        
        XCTAssertEqual(event.type, .subagentStarted)
        
        if case .subagentStarted(let data) = event.data {
            XCTAssertEqual(data.agentName, "code-reviewer")
            XCTAssertEqual(data.agentDisplayName, "Code Reviewer")
        } else {
            XCTFail("Expected subagentStarted data")
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
