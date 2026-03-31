//
//  ConversationListView.swift
//  tatbeeqMa7mool
//
//  Created by Eesabase on 29/03/2026.
//

import SwiftUI

struct ConversationListView: View {
    @State var viewModel: ConversationListViewModel

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.conversations.isEmpty && !viewModel.isLoading {
                    ContentUnavailableView(
                        "No Conversations",
                        systemImage: "bubble.left.and.bubble.right",
                        description: Text("Start a new chat to get going")
                    )
                } else {
                    List {
                        ForEach(viewModel.conversations) { conversation in
                            NavigationLink(value: conversation) {
                                ConversationRow(conversation: conversation)
                            }
                        }

                        if viewModel.hasMore {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .task { await viewModel.loadMore() }
                        }
                    }
                }
            }
            .navigationTitle("Conversations")
            .navigationDestination(for: Conversation.self) { conversation in
                ChatView(
                    viewModel: ChatViewModel(
                        chatService: viewModel.chatService,
                        conversationId: conversation.id
                    )
                )
            }
            .toolbar {
                NavigationLink {
                    ChatView(viewModel: ChatViewModel(chatService: viewModel.chatService))
                } label: {
                    Image(systemName: "square.and.pencil")
                }
            }
            .task { await viewModel.loadConversations() }
            .refreshable { await viewModel.loadConversations() }
            .overlay {
                if viewModel.isLoading && viewModel.conversations.isEmpty {
                    ProgressView()
                }
            }
        }
    }
}

struct ConversationRow: View {
    let conversation: Conversation

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(conversation.title ?? "New Chat")
                .font(.headline)
                .lineLimit(1)

            HStack {
                Text(conversation.status.rawValue.capitalized)
                    .font(.caption)
                    .foregroundStyle(conversation.status == .ongoing ? .green : .secondary)

                Spacer()

                Text(conversation.updatedAt, style: .relative)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}
