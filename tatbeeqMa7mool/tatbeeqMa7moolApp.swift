//
//  tatbeeqMa7moolApp.swift
//  tatbeeqMa7mool
//
//  Created by Eesabase on 12/03/2026.
//

import SwiftUI
import ChatbaseSDK

@main
struct tatbeeqMa7moolApp: App {
    var body: some Scene {
        WindowGroup {
            if let client = makeChatbaseClient() {
                ConversationListView(
                    viewModel: ConversationListViewModel(client: client),
                    authViewModel: AuthViewModel(client: client)
                )
            } else {
                Text("Missing API configuration")
                    .foregroundStyle(.red)
            }
        }
    }

    private func makeChatbaseClient() -> ChatbaseClient? {
        guard let agentId = Bundle.main.infoDictionary?["AGENT_ID"] as? String else {
            return nil
        }

        if let baseURL = Bundle.main.infoDictionary?["API_BASE_URL"] as? String {
            return ChatbaseClient(agentId: agentId, baseURL: baseURL)
        }
        return ChatbaseClient(agentId: agentId)
    }
}
