//
//  tatbeeqMa7moolApp.swift
//  tatbeeqMa7mool
//
//  Created by Eesabase on 12/03/2026.
//

import SwiftUI
import UIKit
import ChatbaseSDK

@main
struct tatbeeqMa7moolApp: App {
    var body: some Scene {
        WindowGroup {
            if let client = makeChatbaseClient() {
                ConversationListView(viewModel: ConversationListViewModel(client: client))
            } else {
                Text("Missing API configuration")
                    .foregroundStyle(.red)
            }
        }
    }

    private func makeChatbaseClient() -> ChatbaseClient? {
        guard
            let agentId = Bundle.main.infoDictionary?["AGENT_ID"] as? String,
            let apiKey = Bundle.main.infoDictionary?["API_KEY"] as? String
        else { return nil }

        let baseURL = Bundle.main.infoDictionary?["API_BASE_URL"] as? String ?? "https://www.chatbase.co/api/v2"
        let userId = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString

        return ChatbaseClient(agentId: agentId, apiKey: apiKey, userId: userId, baseURL: baseURL)
    }
}
