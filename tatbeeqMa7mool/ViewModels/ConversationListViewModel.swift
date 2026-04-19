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
    private var page: PaginatedResponse<Conversation>?
    var hasMore: Bool { page?.hasMore ?? true }

    init(client: ChatbaseClient) {
        self.client = client
    }

    func loadConversations() async {
        isLoading = true
        errorMessage = nil

        do {
            let response = try await client.listConversations()
            conversations = response.data
            page = response
        } catch {
            logger.error("Failed to load conversations: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func loadMore() async {
        guard !isLoading, let page else { return }
        isLoading = true

        do {
            if let next = try await page.loadMore() {
                conversations.append(contentsOf: next.data)
                self.page = next
            }
        } catch {
            logger.error("Failed to load more conversations: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}
