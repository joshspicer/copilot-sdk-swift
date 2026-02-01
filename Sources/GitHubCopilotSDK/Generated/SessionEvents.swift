/*---------------------------------------------------------------------------------------------
 *  Copyright (c) Microsoft Corporation. All rights reserved.
 *--------------------------------------------------------------------------------------------*/

// AUTO-GENERATED FILE - DO NOT EDIT
//
// This file should be regenerated using the generate-session-types script.
// For now, this is a minimal implementation to enable compilation.
//
// To update these types:
// 1. Update the schema in copilot-agent-runtime
// 2. Run: npm run generate:session-types

import Foundation

// MARK: - Session Event

/// Represents a session event from the Copilot CLI
public struct SessionEvent: Codable, Sendable {
    /// The type of event
    public let type: SessionEventType
    
    /// The data associated with this event
    public let data: SessionEventData?
    
    /// Raw JSON data for forward compatibility
    private let rawData: AnyCodable?
    
    enum CodingKeys: String, CodingKey {
        case type
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Decode the type, mapping unknown types to .unknown
        let typeString = try container.decode(String.self, forKey: .type)
        self.type = SessionEventType(rawValue: typeString) ?? .unknown
        
        // Try to decode the full event data based on type
        let singleContainer = try decoder.singleValueContainer()
        self.rawData = try? singleContainer.decode(AnyCodable.self)
        self.data = try? SessionEventData(from: decoder, type: type)
    }
    
    public func encode(to encoder: Encoder) throws {
        if let rawData = rawData {
            var container = encoder.singleValueContainer()
            try container.encode(rawData)
        } else {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(type.rawValue, forKey: .type)
        }
    }
    
    public init(type: SessionEventType, data: SessionEventData? = nil) {
        self.type = type
        self.data = data
        self.rawData = nil
    }
}

// MARK: - Session Event Type

/// The type of session event
public enum SessionEventType: String, Codable, Sendable {
    // Session lifecycle
    case sessionStart = "session.start"
    case sessionIdle = "session.idle"
    case sessionError = "session.error"
    case sessionResume = "session.resume"
    case sessionResourceUpdate = "session.resource_update"
    
    // Compaction
    case sessionCompactionStart = "session.compaction_start"
    case sessionCompactionComplete = "session.compaction_complete"
    
    // Assistant messages
    case assistantMessage = "assistant.message"
    case assistantMessageDelta = "assistant.message_delta"
    case assistantReasoning = "assistant.reasoning"
    case assistantReasoningDelta = "assistant.reasoning_delta"
    
    // User messages
    case userMessage = "user.message"
    
    // Tool execution
    case toolExecutionStart = "tool.execution_start"
    case toolExecutionComplete = "tool.execution_complete"
    case toolExecutionProgress = "tool.execution_progress"
    
    // Agent
    case agentSwitchStart = "agent.switch_start"
    case agentSwitchComplete = "agent.switch_complete"
    
    // Hook events
    case hookStart = "hook.start"
    case hookEnd = "hook.end"
    
    // Unknown for forward compatibility
    case unknown = "unknown"
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        self = SessionEventType(rawValue: rawValue) ?? .unknown
    }
}

// MARK: - Session Event Data

/// Data associated with a session event
public enum SessionEventData: Sendable {
    case sessionStart(SessionStartData)
    case sessionIdle(SessionIdleData)
    case sessionError(SessionErrorData)
    case sessionResume(SessionResumeData)
    case sessionResourceUpdate(SessionResourceUpdateData)
    case sessionCompactionStart(SessionCompactionStartData)
    case sessionCompactionComplete(SessionCompactionCompleteData)
    case assistantMessage(AssistantMessageData)
    case assistantMessageDelta(AssistantMessageDeltaData)
    case assistantReasoning(AssistantReasoningData)
    case assistantReasoningDelta(AssistantReasoningDeltaData)
    case userMessage(UserMessageData)
    case toolExecutionStart(ToolExecutionStartData)
    case toolExecutionComplete(ToolExecutionCompleteData)
    case toolExecutionProgress(ToolExecutionProgressData)
    case agentSwitchStart(AgentSwitchStartData)
    case agentSwitchComplete(AgentSwitchCompleteData)
    case hookStart(HookStartData)
    case hookEnd(HookEndData)
    case unknown
    
    init?(from decoder: Decoder, type: SessionEventType) throws {
        switch type {
        case .sessionStart:
            self = .sessionStart(try SessionStartData(from: decoder))
        case .sessionIdle:
            self = .sessionIdle(try SessionIdleData(from: decoder))
        case .sessionError:
            self = .sessionError(try SessionErrorData(from: decoder))
        case .sessionResume:
            self = .sessionResume(try SessionResumeData(from: decoder))
        case .sessionResourceUpdate:
            self = .sessionResourceUpdate(try SessionResourceUpdateData(from: decoder))
        case .sessionCompactionStart:
            self = .sessionCompactionStart(try SessionCompactionStartData(from: decoder))
        case .sessionCompactionComplete:
            self = .sessionCompactionComplete(try SessionCompactionCompleteData(from: decoder))
        case .assistantMessage:
            self = .assistantMessage(try AssistantMessageData(from: decoder))
        case .assistantMessageDelta:
            self = .assistantMessageDelta(try AssistantMessageDeltaData(from: decoder))
        case .assistantReasoning:
            self = .assistantReasoning(try AssistantReasoningData(from: decoder))
        case .assistantReasoningDelta:
            self = .assistantReasoningDelta(try AssistantReasoningDeltaData(from: decoder))
        case .userMessage:
            self = .userMessage(try UserMessageData(from: decoder))
        case .toolExecutionStart:
            self = .toolExecutionStart(try ToolExecutionStartData(from: decoder))
        case .toolExecutionComplete:
            self = .toolExecutionComplete(try ToolExecutionCompleteData(from: decoder))
        case .toolExecutionProgress:
            self = .toolExecutionProgress(try ToolExecutionProgressData(from: decoder))
        case .agentSwitchStart:
            self = .agentSwitchStart(try AgentSwitchStartData(from: decoder))
        case .agentSwitchComplete:
            self = .agentSwitchComplete(try AgentSwitchCompleteData(from: decoder))
        case .hookStart:
            self = .hookStart(try HookStartData(from: decoder))
        case .hookEnd:
            self = .hookEnd(try HookEndData(from: decoder))
        case .unknown:
            self = .unknown
        }
    }
}

// MARK: - Event Data Types

public struct SessionStartData: Codable, Sendable {
    public let type: String
    public let sessionId: String?
    public let model: String?
    public let timestamp: Int64?
}

public struct SessionIdleData: Codable, Sendable {
    public let type: String
    public let sessionId: String?
    public let timestamp: Int64?
}

public struct SessionErrorData: Codable, Sendable {
    public let type: String
    public let error: String?
    public let code: String?
    public let sessionId: String?
    public let timestamp: Int64?
}

public struct SessionResumeData: Codable, Sendable {
    public let type: String
    public let sessionId: String?
    public let timestamp: Int64?
}

public struct SessionResourceUpdateData: Codable, Sendable {
    public let type: String
    public let contextUtilization: Double?
    public let totalTokens: Int?
    public let maxTokens: Int?
    public let sessionId: String?
    public let timestamp: Int64?
}

public struct SessionCompactionStartData: Codable, Sendable {
    public let type: String
    public let sessionId: String?
    public let timestamp: Int64?
}

public struct SessionCompactionCompleteData: Codable, Sendable {
    public let type: String
    public let sessionId: String?
    public let tokensBefore: Int?
    public let tokensAfter: Int?
    public let timestamp: Int64?
}

public struct AssistantMessageData: Codable, Sendable {
    public let type: String
    public let content: String?
    public let messageId: String?
    public let sessionId: String?
    public let timestamp: Int64?
}

public struct AssistantMessageDeltaData: Codable, Sendable {
    public let type: String
    public let deltaContent: String?
    public let messageId: String?
    public let sessionId: String?
    public let timestamp: Int64?
}

public struct AssistantReasoningData: Codable, Sendable {
    public let type: String
    public let content: String?
    public let messageId: String?
    public let sessionId: String?
    public let timestamp: Int64?
}

public struct AssistantReasoningDeltaData: Codable, Sendable {
    public let type: String
    public let deltaContent: String?
    public let messageId: String?
    public let sessionId: String?
    public let timestamp: Int64?
}

public struct UserMessageData: Codable, Sendable {
    public let type: String
    public let content: String?
    public let messageId: String?
    public let sessionId: String?
    public let timestamp: Int64?
}

public struct ToolExecutionStartData: Codable, Sendable {
    public let type: String
    public let toolName: String?
    public let toolCallId: String?
    public let arguments: AnyCodable?
    public let sessionId: String?
    public let timestamp: Int64?
}

public struct ToolExecutionCompleteData: Codable, Sendable {
    public let type: String
    public let toolName: String?
    public let toolCallId: String?
    public let result: AnyCodable?
    public let resultType: String?
    public let sessionId: String?
    public let timestamp: Int64?
}

public struct ToolExecutionProgressData: Codable, Sendable {
    public let type: String
    public let toolName: String?
    public let toolCallId: String?
    public let progress: String?
    public let sessionId: String?
    public let timestamp: Int64?
}

public struct AgentSwitchStartData: Codable, Sendable {
    public let type: String
    public let agentName: String?
    public let sessionId: String?
    public let timestamp: Int64?
}

public struct AgentSwitchCompleteData: Codable, Sendable {
    public let type: String
    public let agentName: String?
    public let sessionId: String?
    public let timestamp: Int64?
}

public struct HookStartData: Codable, Sendable {
    public let type: String
    public let hookName: String?
    public let sessionId: String?
    public let timestamp: Int64?
}

public struct HookEndData: Codable, Sendable {
    public let type: String
    public let hookName: String?
    public let sessionId: String?
    public let timestamp: Int64?
}
