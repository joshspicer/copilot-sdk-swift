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
    case sessionResume = "session.resume"
    case sessionError = "session.error"
    case sessionIdle = "session.idle"
    case sessionInfo = "session.info"
    case sessionModelChange = "session.model_change"
    case sessionHandoff = "session.handoff"
    case sessionTruncation = "session.truncation"
    case sessionSnapshotRewind = "session.snapshot_rewind"
    case sessionUsageInfo = "session.usage_info"
    
    // Compaction
    case sessionCompactionStart = "session.compaction_start"
    case sessionCompactionComplete = "session.compaction_complete"
    
    // User messages
    case userMessage = "user.message"
    case pendingMessagesModified = "pending_messages.modified"
    
    // Assistant events
    case assistantTurnStart = "assistant.turn_start"
    case assistantIntent = "assistant.intent"
    case assistantReasoning = "assistant.reasoning"
    case assistantReasoningDelta = "assistant.reasoning_delta"
    case assistantMessage = "assistant.message"
    case assistantMessageDelta = "assistant.message_delta"
    case assistantTurnEnd = "assistant.turn_end"
    case assistantUsage = "assistant.usage"
    
    // Abort
    case abort = "abort"
    
    // Tool execution
    case toolUserRequested = "tool.user_requested"
    case toolExecutionStart = "tool.execution_start"
    case toolExecutionPartialResult = "tool.execution_partial_result"
    case toolExecutionProgress = "tool.execution_progress"
    case toolExecutionComplete = "tool.execution_complete"
    
    // Subagent events
    case subagentStarted = "subagent.started"
    case subagentCompleted = "subagent.completed"
    case subagentFailed = "subagent.failed"
    case subagentSelected = "subagent.selected"
    
    // Hook events
    case hookStart = "hook.start"
    case hookEnd = "hook.end"
    
    // Legacy event types (for backwards compatibility)
    case sessionResourceUpdate = "session.resource_update"
    case agentSwitchStart = "agent.switch_start"
    case agentSwitchComplete = "agent.switch_complete"
    
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
    case sessionResume(SessionResumeData)
    case sessionError(SessionErrorData)
    case sessionIdle(SessionIdleData)
    case sessionInfo(SessionInfoData)
    case sessionModelChange(SessionModelChangeData)
    case sessionHandoff(SessionHandoffData)
    case sessionTruncation(SessionTruncationData)
    case sessionSnapshotRewind(SessionSnapshotRewindData)
    case sessionUsageInfo(SessionUsageInfoData)
    case sessionCompactionStart(SessionCompactionStartData)
    case sessionCompactionComplete(SessionCompactionCompleteData)
    case userMessage(UserMessageData)
    case pendingMessagesModified(PendingMessagesModifiedData)
    case assistantTurnStart(AssistantTurnStartData)
    case assistantIntent(AssistantIntentData)
    case assistantReasoning(AssistantReasoningData)
    case assistantReasoningDelta(AssistantReasoningDeltaData)
    case assistantMessage(AssistantMessageData)
    case assistantMessageDelta(AssistantMessageDeltaData)
    case assistantTurnEnd(AssistantTurnEndData)
    case assistantUsage(AssistantUsageData)
    case abort(AbortData)
    case toolUserRequested(ToolUserRequestedData)
    case toolExecutionStart(ToolExecutionStartData)
    case toolExecutionPartialResult(ToolExecutionPartialResultData)
    case toolExecutionProgress(ToolExecutionProgressData)
    case toolExecutionComplete(ToolExecutionCompleteData)
    case subagentStarted(SubagentStartedData)
    case subagentCompleted(SubagentCompletedData)
    case subagentFailed(SubagentFailedData)
    case subagentSelected(SubagentSelectedData)
    case hookStart(HookStartData)
    case hookEnd(HookEndData)
    // Legacy types
    case sessionResourceUpdate(SessionResourceUpdateData)
    case agentSwitchStart(AgentSwitchStartData)
    case agentSwitchComplete(AgentSwitchCompleteData)
    case unknown
    
    init?(from decoder: Decoder, type: SessionEventType) throws {
        switch type {
        case .sessionStart:
            self = .sessionStart(try SessionStartData(from: decoder))
        case .sessionResume:
            self = .sessionResume(try SessionResumeData(from: decoder))
        case .sessionError:
            self = .sessionError(try SessionErrorData(from: decoder))
        case .sessionIdle:
            self = .sessionIdle(try SessionIdleData(from: decoder))
        case .sessionInfo:
            self = .sessionInfo(try SessionInfoData(from: decoder))
        case .sessionModelChange:
            self = .sessionModelChange(try SessionModelChangeData(from: decoder))
        case .sessionHandoff:
            self = .sessionHandoff(try SessionHandoffData(from: decoder))
        case .sessionTruncation:
            self = .sessionTruncation(try SessionTruncationData(from: decoder))
        case .sessionSnapshotRewind:
            self = .sessionSnapshotRewind(try SessionSnapshotRewindData(from: decoder))
        case .sessionUsageInfo:
            self = .sessionUsageInfo(try SessionUsageInfoData(from: decoder))
        case .sessionCompactionStart:
            self = .sessionCompactionStart(try SessionCompactionStartData(from: decoder))
        case .sessionCompactionComplete:
            self = .sessionCompactionComplete(try SessionCompactionCompleteData(from: decoder))
        case .userMessage:
            self = .userMessage(try UserMessageData(from: decoder))
        case .pendingMessagesModified:
            self = .pendingMessagesModified(try PendingMessagesModifiedData(from: decoder))
        case .assistantTurnStart:
            self = .assistantTurnStart(try AssistantTurnStartData(from: decoder))
        case .assistantIntent:
            self = .assistantIntent(try AssistantIntentData(from: decoder))
        case .assistantReasoning:
            self = .assistantReasoning(try AssistantReasoningData(from: decoder))
        case .assistantReasoningDelta:
            self = .assistantReasoningDelta(try AssistantReasoningDeltaData(from: decoder))
        case .assistantMessage:
            self = .assistantMessage(try AssistantMessageData(from: decoder))
        case .assistantMessageDelta:
            self = .assistantMessageDelta(try AssistantMessageDeltaData(from: decoder))
        case .assistantTurnEnd:
            self = .assistantTurnEnd(try AssistantTurnEndData(from: decoder))
        case .assistantUsage:
            self = .assistantUsage(try AssistantUsageData(from: decoder))
        case .abort:
            self = .abort(try AbortData(from: decoder))
        case .toolUserRequested:
            self = .toolUserRequested(try ToolUserRequestedData(from: decoder))
        case .toolExecutionStart:
            self = .toolExecutionStart(try ToolExecutionStartData(from: decoder))
        case .toolExecutionPartialResult:
            self = .toolExecutionPartialResult(try ToolExecutionPartialResultData(from: decoder))
        case .toolExecutionProgress:
            self = .toolExecutionProgress(try ToolExecutionProgressData(from: decoder))
        case .toolExecutionComplete:
            self = .toolExecutionComplete(try ToolExecutionCompleteData(from: decoder))
        case .subagentStarted:
            self = .subagentStarted(try SubagentStartedData(from: decoder))
        case .subagentCompleted:
            self = .subagentCompleted(try SubagentCompletedData(from: decoder))
        case .subagentFailed:
            self = .subagentFailed(try SubagentFailedData(from: decoder))
        case .subagentSelected:
            self = .subagentSelected(try SubagentSelectedData(from: decoder))
        case .hookStart:
            self = .hookStart(try HookStartData(from: decoder))
        case .hookEnd:
            self = .hookEnd(try HookEndData(from: decoder))
        case .sessionResourceUpdate:
            self = .sessionResourceUpdate(try SessionResourceUpdateData(from: decoder))
        case .agentSwitchStart:
            self = .agentSwitchStart(try AgentSwitchStartData(from: decoder))
        case .agentSwitchComplete:
            self = .agentSwitchComplete(try AgentSwitchCompleteData(from: decoder))
        case .unknown:
            self = .unknown
        }
    }
}

// MARK: - Event Data Types

public struct SessionStartData: Codable, Sendable {
    public let type: String
    public let sessionId: String?
    public let version: Int?
    public let producer: String?
    public let copilotVersion: String?
    public let startTime: String?
    public let selectedModel: String?
    public let context: SessionContextData?
}

public struct SessionContextData: Codable, Sendable {
    public let cwd: String?
    public let gitRoot: String?
    public let repository: String?
    public let branch: String?
}

public struct SessionResumeData: Codable, Sendable {
    public let type: String
    public let resumeTime: String?
    public let eventCount: Int?
    public let context: SessionContextData?
}

public struct SessionErrorData: Codable, Sendable {
    public let type: String
    public let errorType: String?
    public let message: String?
    public let stack: String?
    // Legacy fields
    public let error: String?
    public let code: String?
    public let sessionId: String?
    public let timestamp: Int64?
}

public struct SessionIdleData: Codable, Sendable {
    public let type: String
    public let sessionId: String?
    public let timestamp: Int64?
}

public struct SessionInfoData: Codable, Sendable {
    public let type: String
    public let infoType: String?
    public let message: String?
}

public struct SessionModelChangeData: Codable, Sendable {
    public let type: String
    public let previousModel: String?
    public let newModel: String?
}

public struct SessionHandoffData: Codable, Sendable {
    public let type: String
    public let handoffTime: String?
    public let sourceType: String?
    public let repository: SessionRepositoryData?
    public let context: String?
    public let summary: String?
    public let remoteSessionId: String?
}

public struct SessionRepositoryData: Codable, Sendable {
    public let owner: String?
    public let name: String?
    public let branch: String?
}

public struct SessionTruncationData: Codable, Sendable {
    public let type: String
    public let tokenLimit: Int?
    public let preTruncationTokensInMessages: Int?
    public let preTruncationMessagesLength: Int?
    public let postTruncationTokensInMessages: Int?
    public let postTruncationMessagesLength: Int?
    public let tokensRemovedDuringTruncation: Int?
    public let messagesRemovedDuringTruncation: Int?
    public let performedBy: String?
}

public struct SessionSnapshotRewindData: Codable, Sendable {
    public let type: String
    public let upToEventId: String?
    public let eventsRemoved: Int?
}

public struct SessionUsageInfoData: Codable, Sendable {
    public let type: String
    public let tokenLimit: Int?
    public let currentTokens: Int?
    public let messagesLength: Int?
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
    public let success: Bool?
    public let error: String?
    public let preCompactionTokens: Int?
    public let postCompactionTokens: Int?
    public let preCompactionMessagesLength: Int?
    public let messagesRemoved: Int?
    public let tokensRemoved: Int?
    public let summaryContent: String?
    public let compactionTokensUsed: CompactionTokensUsedData?
    // Legacy fields
    public let sessionId: String?
    public let tokensBefore: Int?
    public let tokensAfter: Int?
    public let timestamp: Int64?
}

public struct CompactionTokensUsedData: Codable, Sendable {
    public let input: Int?
    public let output: Int?
    public let cachedInput: Int?
}

public struct UserMessageData: Codable, Sendable {
    public let type: String
    public let content: String?
    public let transformedContent: String?
    public let attachments: [AttachmentData]?
    public let source: String?
    // Legacy fields
    public let messageId: String?
    public let sessionId: String?
    public let timestamp: Int64?
}

public struct AttachmentData: Codable, Sendable {
    public let type: String?
    public let path: String?
    public let displayName: String?
    public let filePath: String?
    public let text: String?
    public let selection: SelectionData?
}

public struct SelectionData: Codable, Sendable {
    public let start: PositionData?
    public let end: PositionData?
}

public struct PositionData: Codable, Sendable {
    public let line: Int?
    public let character: Int?
}

public struct PendingMessagesModifiedData: Codable, Sendable {
    public let type: String
}

public struct AssistantTurnStartData: Codable, Sendable {
    public let type: String
    public let turnId: String?
}

public struct AssistantIntentData: Codable, Sendable {
    public let type: String
    public let intent: String?
}

public struct AssistantReasoningData: Codable, Sendable {
    public let type: String
    public let reasoningId: String?
    public let content: String?
    // Legacy fields
    public let messageId: String?
    public let sessionId: String?
    public let timestamp: Int64?
}

public struct AssistantReasoningDeltaData: Codable, Sendable {
    public let type: String
    public let reasoningId: String?
    public let deltaContent: String?
    // Legacy fields
    public let messageId: String?
    public let sessionId: String?
    public let timestamp: Int64?
}

public struct AssistantMessageData: Codable, Sendable {
    public let type: String
    public let messageId: String?
    public let content: String?
    public let toolRequests: [ToolRequestData]?
    public let parentToolCallId: String?
    // Legacy fields
    public let sessionId: String?
    public let timestamp: Int64?
}

public struct ToolRequestData: Codable, Sendable {
    public let toolCallId: String?
    public let name: String?
    public let arguments: AnyCodable?
    public let type: String?
}

public struct AssistantMessageDeltaData: Codable, Sendable {
    public let type: String
    public let messageId: String?
    public let deltaContent: String?
    public let totalResponseSizeBytes: Int?
    public let parentToolCallId: String?
    // Legacy fields
    public let sessionId: String?
    public let timestamp: Int64?
}

public struct AssistantTurnEndData: Codable, Sendable {
    public let type: String
    public let turnId: String?
}

public struct AssistantUsageData: Codable, Sendable {
    public let type: String
    public let model: String?
    public let inputTokens: Int?
    public let outputTokens: Int?
    public let cacheReadTokens: Int?
    public let cacheWriteTokens: Int?
    public let cost: Double?
    public let duration: Int?
    public let initiator: String?
    public let apiCallId: String?
    public let providerCallId: String?
    public let quotaSnapshots: [String: QuotaSnapshotData]?
}

public struct QuotaSnapshotData: Codable, Sendable {
    public let isUnlimitedEntitlement: Bool?
    public let entitlementRequests: Int?
    public let usedRequests: Int?
    public let usageAllowedWithExhaustedQuota: Bool?
    public let overage: Int?
    public let overageAllowedWithExhaustedQuota: Bool?
    public let remainingPercentage: Double?
    public let resetDate: String?
}

public struct AbortData: Codable, Sendable {
    public let type: String
    public let reason: String?
}

public struct ToolUserRequestedData: Codable, Sendable {
    public let type: String
    public let toolCallId: String?
    public let toolName: String?
    public let arguments: AnyCodable?
}

public struct ToolExecutionStartData: Codable, Sendable {
    public let type: String
    public let toolCallId: String?
    public let toolName: String?
    public let arguments: AnyCodable?
    public let mcpServerName: String?
    public let mcpToolName: String?
    public let parentToolCallId: String?
    // Legacy fields
    public let sessionId: String?
    public let timestamp: Int64?
}

public struct ToolExecutionPartialResultData: Codable, Sendable {
    public let type: String
    public let toolCallId: String?
    public let partialOutput: String?
}

public struct ToolExecutionProgressData: Codable, Sendable {
    public let type: String
    public let toolCallId: String?
    public let progressMessage: String?
    // Legacy fields
    public let toolName: String?
    public let progress: String?
    public let sessionId: String?
    public let timestamp: Int64?
}

public struct ToolExecutionCompleteData: Codable, Sendable {
    public let type: String
    public let toolCallId: String?
    public let success: Bool?
    public let isUserRequested: Bool?
    public let result: ToolResultData?
    public let error: ToolErrorData?
    public let toolTelemetry: AnyCodable?
    public let parentToolCallId: String?
    // Legacy fields
    public let toolName: String?
    public let resultType: String?
    public let sessionId: String?
    public let timestamp: Int64?
}

public struct ToolResultData: Codable, Sendable {
    public let content: String?
    public let detailedContent: String?
}

public struct ToolErrorData: Codable, Sendable {
    public let message: String?
    public let code: String?
}

public struct SubagentStartedData: Codable, Sendable {
    public let type: String
    public let toolCallId: String?
    public let agentName: String?
    public let agentDisplayName: String?
    public let agentDescription: String?
}

public struct SubagentCompletedData: Codable, Sendable {
    public let type: String
    public let toolCallId: String?
    public let agentName: String?
}

public struct SubagentFailedData: Codable, Sendable {
    public let type: String
    public let toolCallId: String?
    public let agentName: String?
    public let error: String?
}

public struct SubagentSelectedData: Codable, Sendable {
    public let type: String
    public let agentName: String?
    public let agentDisplayName: String?
    public let tools: [String]?
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
    public let hookInvocationId: String?
    public let hookType: String?
    public let input: AnyCodable?
    // Legacy fields
    public let hookName: String?
    public let sessionId: String?
    public let timestamp: Int64?
}

public struct HookEndData: Codable, Sendable {
    public let type: String
    public let hookInvocationId: String?
    public let hookType: String?
    public let output: AnyCodable?
    public let success: Bool?
    public let error: HookErrorData?
    // Legacy fields
    public let hookName: String?
    public let sessionId: String?
    public let timestamp: Int64?
}

public struct HookErrorData: Codable, Sendable {
    public let message: String?
}
