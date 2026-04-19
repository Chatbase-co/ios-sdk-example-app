//
//  ConversationListViewModel.swift
//  tatbeeqMa7mool
//
//  Created by Eesabase on 29/03/2026.
//

import Foundation
import ChatbaseSDK

/// Thin wrapper around `ConversationListState`.
@MainActor @Observable
class ConversationListViewModel {
    let client: ChatbaseClient
    let state: ConversationListState

    init(client: ChatbaseClient) {
        self.client = client
        self.state = ConversationListState(client: client)
    }

    func load() {
        Task { [state] in await state.load() }
    }

    func loadMore() {
        Task { [state] in await state.loadMore() }
    }
}
