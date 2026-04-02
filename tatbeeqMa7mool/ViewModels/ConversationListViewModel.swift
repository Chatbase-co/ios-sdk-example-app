//
//  ConversationListViewModel.swift
//  tatbeeqMa7mool
//
//  Created by Eesabase on 29/03/2026.
//

import Foundation
import os
import ChatbaseSDK

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "tatbeeqMa7mool", category: "ConversationListViewModel")

@MainActor @Observable
class ConversationListViewModel {
    let client: ChatbaseClient
    private(set) var conversations: [Conversation] = []
    private(set) var isLoading = false
    private(set) var errorMessage: String?
    private var nextCursor: String?
    private(set) var hasMore = true

    init(client: ChatbaseClient) {
        self.client = client
    }

    func loadConversations() async {
        isLoading = true
        errorMessage = nil

        do {
            let response = try await client.listConversations()
            conversations = response.data
            nextCursor = response.pagination.cursor
            hasMore = response.pagination.hasMore
        } catch {
            logger.error("Failed to load conversations: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func loadMore() async {
        guard hasMore, !isLoading, let cursor = nextCursor else { return }
        isLoading = true

        do {
            let response = try await client.listConversations(cursor: cursor)
            conversations.append(contentsOf: response.data)
            nextCursor = response.pagination.cursor
            hasMore = response.pagination.hasMore
        } catch {
            logger.error("Failed to load more conversations: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}
