//
//  tatbeeqMa7moolApp.swift
//  tatbeeqMa7mool
//
//  Created by Eesabase on 12/03/2026.
//

import SwiftUI

@main
struct tatbeeqMa7moolApp: App {
    var body: some Scene {
        WindowGroup {
            if let chatService = ChatService(client: URLSessionClient()) {
                ConversationListView(viewModel: ConversationListViewModel(chatService: chatService))
            } else {
                Text("Missing API configuration")
                    .foregroundStyle(.red)
            }
        }
    }
}
