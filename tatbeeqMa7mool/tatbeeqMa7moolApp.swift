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

        let client: ChatbaseClient
        if let baseURL = Bundle.main.infoDictionary?["API_BASE_URL"] as? String {
            client = ChatbaseClient(agentId: agentId, baseURL: baseURL)
        } else {
            client = ChatbaseClient(agentId: agentId)
        }
        registerSharedTools(on: client)
        return client
    }

    // Example of top-level tool calls that require no UI interaction
    private func registerSharedTools(on client: ChatbaseClient) {
        client.tool("package_status") { input in
            guard let email = input["email"]?.stringValue else {
                return .object(["error": .string("Missing email")])
            }
            let trackingNumber = Int.random(in: 1_000_000_000...9_999_999_999)
            let status = ["delivered", "in transit", "out for delivery", "cancelled"].randomElement()!
            return .object([
                "tracking_number": .int(trackingNumber),
                "status": .string(status),
                "email": .string(email)
            ])
        }
    }
}
