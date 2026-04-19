//
//  ConversationListView.swift
//  tatbeeqMa7mool
//
//  Created by Eesabase on 29/03/2026.
//

import SwiftUI
import ChatbaseSDK

struct ConversationListView: View {
    @State var viewModel: ConversationListViewModel
    @State var authViewModel: AuthViewModel
    @State private var showingAuthSheet = false

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.state.conversations.isEmpty && !viewModel.state.isLoading {
                    ContentUnavailableView(
                        "No Conversations",
                        systemImage: "bubble.left.and.bubble.right",
                        description: Text("Start a new chat to get going")
                    )
                } else {
                    List {
                        ForEach(viewModel.state.conversations) { conversation in
                            NavigationLink(value: conversation) {
                                ConversationRow(conversation: conversation)
                            }
                        }

                        if viewModel.state.hasMore {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .task { viewModel.loadMore() }
                        }
                    }
                }
            }
            .navigationTitle("Conversations")
            .navigationDestination(for: Conversation.self) { conversation in
                ChatView(
                    viewModel: ChatViewModel(
                        client: viewModel.client,
                        conversationId: conversation.id
                    )
                )
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    AuthBadge(viewModel: authViewModel) {
                        showingAuthSheet = true
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        ChatView(viewModel: ChatViewModel(client: viewModel.client))
                    } label: {
                        Image(systemName: "square.and.pencil")
                    }
                }
            }
            .sheet(isPresented: $showingAuthSheet) {
                AuthSheet(viewModel: authViewModel)
            }
            .task(id: authViewModel.isIdentified) { viewModel.load() }
            .refreshable { viewModel.load() }
            .overlay {
                if viewModel.state.isLoading && viewModel.state.conversations.isEmpty {
                    ProgressView()
                }
            }
        }
    }
}

private struct AuthBadge: View {
    let viewModel: AuthViewModel
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: viewModel.isIdentified
                    ? "person.crop.circle.badge.checkmark"
                    : "person.crop.circle")
                    .foregroundStyle(viewModel.isIdentified ? .green : .secondary)
                Text(viewModel.isIdentified ? (viewModel.currentUserId ?? "Signed in") : "Guest")
                    .font(.footnote)
                    .lineLimit(1)
                    .foregroundStyle(.primary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(.thinMaterial)
            )
            .overlay(
                Capsule()
                    .stroke(viewModel.isIdentified ? Color.green.opacity(0.3) : Color.secondary.opacity(0.2), lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(viewModel.isIdentified
            ? "Signed in as \(viewModel.currentUserId ?? "user")"
            : "Guest — tap to sign in")
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
