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
    /// Unique event identifier
    public let id: String

    /// ISO 8601 timestamp
    public let timestamp: String

    /// Parent event ID for nested events
    public let parentId: String?

    /// Whether this event is ephemeral (not persisted in session history)
    public let ephemeral: Bool?

    /// The type of event
    public let type: SessionEventType

    /// The data associated with this event
    public let data: SessionEventData?

    /// Raw JSON data for forward compatibility
    private let rawData: AnyCodable?

    enum CodingKeys: String, CodingKey {
        case id, timestamp, parentId, ephemeral, type, data
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(String.self, forKey: .id)
        timestamp = try container.decode(String.self, forKey: .timestamp)
        parentId = try container.decodeIfPresent(String.self, forKey: .parentId)
        ephemeral = try container.decodeIfPresent(Bool.self, forKey: .ephemeral)

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
            try container.encode(id, forKey: .id)
            try container.encode(timestamp, forKey: .timestamp)
            try container.encodeIfPresent(parentId, forKey: .parentId)
            try container.encodeIfPresent(ephemeral, forKey: .ephemeral)
            try container.encode(type.rawValue, forKey: .type)
        }
    }

    public init(id: String, timestamp: String, parentId: String? = nil, ephemeral: Bool? = nil, type: SessionEventType, data: SessionEventData? = nil) {
        self.id = id
        self.timestamp = timestamp
        self.parentId = parentId
        self.ephemeral = ephemeral
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
    case sessionIdle = "session.idle"
    case sessionError = "session.error"
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

    // Assistant turns and messages
    case assistantTurnStart = "assistant.turn_start"
    case assistantTurnEnd = "assistant.turn_end"
    case assistantIntent = "assistant.intent"
    case assistantReasoning = "assistant.reasoning"
    case assistantReasoningDelta = "assistant.reasoning_delta"
    case assistantMessage = "assistant.message"
    case assistantMessageDelta = "assistant.message_delta"
    case assistantUsage = "assistant.usage"

    // Tool execution
    case toolUserRequested = "tool.user_requested"
    case toolExecutionStart = "tool.execution_start"
    case toolExecutionPartialResult = "tool.execution_partial_result"
    case toolExecutionProgress = "tool.execution_progress"
    case toolExecutionComplete = "tool.execution_complete"

    // Subagents
    case subagentStarted = "subagent.started"
    case subagentCompleted = "subagent.completed"
    case subagentFailed = "subagent.failed"
    case subagentSelected = "subagent.selected"

    // Agent (legacy)
    case agentSwitchStart = "agent.switch_start"
    case agentSwitchComplete = "agent.switch_complete"

    // Hooks
    case hookStart = "hook.start"
    case hookEnd = "hook.end"

    // System
    case systemMessage = "system.message"
    case abort = "abort"

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
    case sessionIdle(SessionIdleData)
    case sessionError(SessionErrorData)
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
    case assistantTurnEnd(AssistantTurnEndData)
    case assistantIntent(AssistantIntentData)
    case assistantReasoning(AssistantReasoningData)
    case assistantReasoningDelta(AssistantReasoningDeltaData)
    case assistantMessage(AssistantMessageData)
    case assistantMessageDelta(AssistantMessageDeltaData)
    case assistantUsage(AssistantUsageData)
    case toolUserRequested(ToolUserRequestedData)
    case toolExecutionStart(ToolExecutionStartData)
    case toolExecutionPartialResult(ToolExecutionPartialResultData)
    case toolExecutionProgress(ToolExecutionProgressData)
    case toolExecutionComplete(ToolExecutionCompleteData)
    case subagentStarted(SubagentStartedData)
    case subagentCompleted(SubagentCompletedData)
    case subagentFailed(SubagentFailedData)
    case subagentSelected(SubagentSelectedData)
    case agentSwitchStart(AgentSwitchStartData)
    case agentSwitchComplete(AgentSwitchCompleteData)
    case hookStart(HookStartData)
    case hookEnd(HookEndData)
    case systemMessage(SystemMessageData)
    case abort(AbortData)
    case unknown

    init?(from decoder: Decoder, type: SessionEventType) throws {
        switch type {
        case .sessionStart:
            self = .sessionStart(try SessionStartData(from: decoder))
        case .sessionResume:
            self = .sessionResume(try SessionResumeData(from: decoder))
        case .sessionIdle:
            self = .sessionIdle(try SessionIdleData(from: decoder))
        case .sessionError:
            self = .sessionError(try SessionErrorData(from: decoder))
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
        case .assistantTurnEnd:
            self = .assistantTurnEnd(try AssistantTurnEndData(from: decoder))
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
        case .assistantUsage:
            self = .assistantUsage(try AssistantUsageData(from: decoder))
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
        case .agentSwitchStart:
            self = .agentSwitchStart(try AgentSwitchStartData(from: decoder))
        case .agentSwitchComplete:
            self = .agentSwitchComplete(try AgentSwitchCompleteData(from: decoder))
        case .hookStart:
            self = .hookStart(try HookStartData(from: decoder))
        case .hookEnd:
            self = .hookEnd(try HookEndData(from: decoder))
        case .systemMessage:
            self = .systemMessage(try SystemMessageData(from: decoder))
        case .abort:
            self = .abort(try AbortData(from: decoder))
        case .unknown:
            self = .unknown
        }
    }
}

// MARK: - Event Data Types

// Session Events
public struct SessionStartData: Codable, Sendable {
    public struct Context: Codable, Sendable {
        public let cwd: String
        public let gitRoot: String?
        public let repository: String?
        public let branch: String?
    }

    public let sessionId: String
    public let version: Int
    public let producer: String
    public let copilotVersion: String
    public let startTime: String
    public let selectedModel: String?
    public let context: Context?
}

public struct SessionResumeData: Codable, Sendable {
    public struct Context: Codable, Sendable {
        public let cwd: String
        public let gitRoot: String?
        public let repository: String?
        public let branch: String?
    }

    public let resumeTime: String
    public let eventCount: Int
    public let context: Context?
}

public struct SessionIdleData: Codable, Sendable {
    // Empty data object
}

public struct SessionErrorData: Codable, Sendable {
    public let errorType: String
    public let message: String
    public let stack: String?
}

public struct SessionInfoData: Codable, Sendable {
    public let infoType: String
    public let message: String
}

public struct SessionModelChangeData: Codable, Sendable {
    public let previousModel: String?
    public let newModel: String
}

public struct SessionHandoffData: Codable, Sendable {
    public struct Repository: Codable, Sendable {
        public let owner: String
        public let name: String
        public let branch: String?
    }

    public let handoffTime: String
    public let sourceType: String // "remote" | "local"
    public let repository: Repository?
    public let context: String?
    public let summary: String?
    public let remoteSessionId: String?
}

public struct SessionTruncationData: Codable, Sendable {
    public let tokenLimit: Int
    public let preTruncationTokensInMessages: Int
    public let preTruncationMessagesLength: Int
    public let postTruncationTokensInMessages: Int
    public let postTruncationMessagesLength: Int
    public let tokensRemovedDuringTruncation: Int
    public let messagesRemovedDuringTruncation: Int
    public let performedBy: String
}

public struct SessionSnapshotRewindData: Codable, Sendable {
    public let upToEventId: String
    public let eventsRemoved: Int
}

public struct SessionUsageInfoData: Codable, Sendable {
    public let tokenLimit: Int
    public let currentTokens: Int
    public let messagesLength: Int
}

public struct SessionCompactionStartData: Codable, Sendable {
    // Empty data object
}

public struct SessionCompactionCompleteData: Codable, Sendable {
    public struct CompactionTokensUsed: Codable, Sendable {
        public let input: Int
        public let output: Int
        public let cachedInput: Int
    }

    public let success: Bool
    public let error: String?
    public let preCompactionTokens: Int?
    public let postCompactionTokens: Int?
    public let preCompactionMessagesLength: Int?
    public let messagesRemoved: Int?
    public let tokensRemoved: Int?
    public let summaryContent: String?
    public let compactionTokensUsed: CompactionTokensUsed?
}

// User Message Events
public struct UserMessageData: Codable, Sendable {
    public struct FileAttachment: Codable, Sendable {
        public let type: String // "file"
        public let path: String
        public let displayName: String
    }

    public struct DirectoryAttachment: Codable, Sendable {
        public let type: String // "directory"
        public let path: String
        public let displayName: String
    }

    public struct SelectionAttachment: Codable, Sendable {
        public struct Position: Codable, Sendable {
            public let line: Int
            public let character: Int
        }

        public struct Selection: Codable, Sendable {
            public let start: Position
            public let end: Position
        }

        public let type: String // "selection"
        public let filePath: String
        public let displayName: String
        public let text: String
        public let selection: Selection
    }

    public let content: String
    public let transformedContent: String?
    public let attachments: [AnyCodable]? // Mixed array of attachment types
    public let source: String?
}

public struct PendingMessagesModifiedData: Codable, Sendable {
    // Empty data object
}

// Assistant Events
public struct AssistantTurnStartData: Codable, Sendable {
    public let turnId: String
}

public struct AssistantTurnEndData: Codable, Sendable {
    public let turnId: String
}

public struct AssistantIntentData: Codable, Sendable {
    public let intent: String
}

public struct AssistantReasoningData: Codable, Sendable {
    public let reasoningId: String
    public let content: String
}

public struct AssistantReasoningDeltaData: Codable, Sendable {
    public let reasoningId: String
    public let deltaContent: String
}

public struct AssistantMessageData: Codable, Sendable {
    public struct ToolRequest: Codable, Sendable {
        public let toolCallId: String
        public let name: String
        public let arguments: AnyCodable?
        public let type: String? // "function" | "custom"
    }

    public let messageId: String
    public let content: String
    public let toolRequests: [ToolRequest]?
    public let parentToolCallId: String?
}

public struct AssistantMessageDeltaData: Codable, Sendable {
    public let messageId: String
    public let deltaContent: String
    public let totalResponseSizeBytes: Int?
    public let parentToolCallId: String?
}

public struct AssistantUsageData: Codable, Sendable {
    public struct QuotaSnapshot: Codable, Sendable {
        public let isUnlimitedEntitlement: Bool
        public let entitlementRequests: Int
        public let usedRequests: Int
        public let usageAllowedWithExhaustedQuota: Bool
        public let overage: Int
        public let overageAllowedWithExhaustedQuota: Bool
        public let remainingPercentage: Int
        public let resetDate: String?
    }

    public let model: String?
    public let inputTokens: Int?
    public let outputTokens: Int?
    public let cacheReadTokens: Int?
    public let cacheWriteTokens: Int?
    public let cost: Double?
    public let duration: Double?
    public let initiator: String?
    public let apiCallId: String?
    public let providerCallId: String?
    public let quotaSnapshots: [String: QuotaSnapshot]?
}

// Tool Events
public struct ToolUserRequestedData: Codable, Sendable {
    public let toolCallId: String
    public let toolName: String
    public let arguments: AnyCodable?
}

public struct ToolExecutionStartData: Codable, Sendable {
    public let toolCallId: String
    public let toolName: String
    public let arguments: AnyCodable?
    public let mcpServerName: String?
    public let mcpToolName: String?
    public let parentToolCallId: String?
}

public struct ToolExecutionPartialResultData: Codable, Sendable {
    public let toolCallId: String
    public let partialOutput: String
}

public struct ToolExecutionProgressData: Codable, Sendable {
    public let toolCallId: String
    public let progressMessage: String
}

public struct ToolExecutionCompleteData: Codable, Sendable {
    public struct Result: Codable, Sendable {
        public let content: String
        public let detailedContent: String?
    }

    public struct Error: Codable, Sendable {
        public let message: String
        public let code: String?
    }

    public let toolCallId: String
    public let success: Bool
    public let isUserRequested: Bool?
    public let result: Result?
    public let error: Error?
    public let toolTelemetry: [String: AnyCodable]?
    public let parentToolCallId: String?
}

// Subagent Events
public struct SubagentStartedData: Codable, Sendable {
    public let toolCallId: String
    public let agentName: String
    public let agentDisplayName: String
    public let agentDescription: String
}

public struct SubagentCompletedData: Codable, Sendable {
    public let toolCallId: String
    public let agentName: String
}

public struct SubagentFailedData: Codable, Sendable {
    public let toolCallId: String
    public let agentName: String
    public let error: String
}

public struct SubagentSelectedData: Codable, Sendable {
    public let agentName: String
    public let agentDisplayName: String
    public let tools: [String]? // null means all tools
}

// Hook Events
public struct HookStartData: Codable, Sendable {
    public let hookInvocationId: String
    public let hookType: String
    public let input: AnyCodable?
}

public struct HookEndData: Codable, Sendable {
    public struct HookError: Codable, Sendable {
        public let message: String
        public let stack: String?
    }

    public let hookInvocationId: String
    public let hookType: String
    public let output: AnyCodable?
    public let success: Bool
    public let error: HookError?
}

// System Events
public struct SystemMessageData: Codable, Sendable {
    public struct Metadata: Codable, Sendable {
        public let promptVersion: String?
        public let variables: [String: AnyCodable]?
    }

    public let content: String
    public let role: String // "system" | "developer"
    public let name: String?
    public let metadata: Metadata?
}

public struct AbortData: Codable, Sendable {
    public let reason: String
}

// Agent Events (legacy)
public struct AgentSwitchStartData: Codable, Sendable {
    public let agentName: String
}

public struct AgentSwitchCompleteData: Codable, Sendable {
    public let agentName: String
}
