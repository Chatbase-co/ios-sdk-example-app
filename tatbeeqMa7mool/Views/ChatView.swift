//
//  ChatView.swift
//  tatbeeqMa7mool
//
//  Created by Eesabase on 12/03/2026.
//

import SwiftUI


struct ChatView: View {
    @State var viewModel: ChatViewModel

    var body: some View {
        VStack(spacing: 0) {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 20) {
                            if viewModel.hasMoreMessages && !viewModel.isLoading {
                                Button {
                                    Task { await viewModel.loadMoreMessages() }
                                } label: {
                                    if viewModel.isLoadingMore {
                                        ProgressView()
                                    } else {
                                        Text("Load earlier messages")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .disabled(viewModel.isLoadingMore)
                            }
                            ForEach(viewModel.messages) { message in
                                MessageBubble(
                                    message: message,
                                    onFeedback: { feedback in
                                        Task { await viewModel.toggleFeedback(messageId: message.id, feedback: feedback) }
                                    },
                                    onRetry: {
                                        Task { await viewModel.retryMessage(message.id) }
                                    }
                                )
                        }
                        if let error = viewModel.errorMessage {
                            Text(error)
                                .foregroundStyle(.red)
                                .font(.caption)
                        }
                        Color.clear
                            .frame(height: 1)
                            .id("bottom")
                    }
                    .padding()
                }
                .frame(maxWidth: .infinity)
                .onChange(of: viewModel.messages.last?.text) {
                    proxy.scrollTo("bottom", anchor: .bottom)
                }
            }

            HStack {
                TextField("Enter your message", text: $viewModel.inputText)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit {
                        Task { await viewModel.sendMessage() }
                    }

                Button("Send") {
                    Task {
                        await viewModel.sendMessage()
                    }
                }
                .disabled(viewModel.isLoading)
            }
            .padding()
            }
        .navigationTitle("AI Chat")
        .background(viewModel.background)
        .task { await viewModel.loadConversation() }
        .toolbar {
            Button {
                viewModel.newConversation()
            } label: {
                Image(systemName: "square.and.pencil")
            }
            .disabled(viewModel.isLoading)
        }
    }
}
