//
//  Conversation.swift
//  tatbeeqMa7mool
//
//  Created by Eesabase on 29/03/2026.
//

import Foundation

enum ConversationStatus: String, Decodable {
    case ongoing
    case ended
    case takenOver = "taken_over"
}

struct Conversation: Identifiable, Hashable {
    let id: String
    let title: String?
    let createdAt: Date
    let updatedAt: Date
    let userId: String?
    let status: ConversationStatus
}
