//
//  Message.swift
//  tatbeeqMa7mool
//
//  Created by Eesabase on 13/03/2026.
//

import Foundation

enum MessageSender: Sendable { case user, agent }

enum MessageFeedback: String, Codable, Sendable {
    case positive
    case negative
}

enum FinishReason: String, Sendable {
    case stop
    case error
    case toolCalls = "tool-calls"
}

struct Usage: Sendable {
    let credits: Double
}

struct MessagePart: Sendable {
    enum Kind: Sendable {
        case text(String)
        case toolCall(toolCallId: String, toolName: String, input: JSONValue)
        case toolResult(toolCallId: String, toolName: String, output: JSONValue)
    }

    let kind: Kind
}

struct Message: Identifiable, Sendable {
    var id: String
    var text: String
    var sender: MessageSender
    var date: Date
    var feedback: MessageFeedback? = nil
    var score: Double? = nil
    var parts: [MessagePart] = []
}
