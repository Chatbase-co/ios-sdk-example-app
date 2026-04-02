//
//  ChatView.swift
//  tatbeeqMa7mool
//
//  Created by Eesabase on 12/03/2026.
//

import SwiftUI
import ChatbaseSDK

struct ChatView: View {
    @State var viewModel: ChatViewModel
    @State private var selectedColor: Color = .blue

    private var canSend: Bool {
        !viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        && !viewModel.isLoading
        && !viewModel.isLoadingConversation
    }

    var body: some View {
        VStack(spacing: 0) {
            if viewModel.isLoadingConversation {
                Spacer()
                ProgressView("Loading conversation...")
                Spacer()
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 20) {
                            if viewModel.hasMoreMessages {
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

                Divider()

                HStack(alignment: .bottom, spacing: 8) {
                    TextField("Message", text: $viewModel.inputText, axis: .vertical)
                        .lineLimit(1...5)
                        .textFieldStyle(.plain)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color(.systemGray6))
                        .cornerRadius(20)
                        .onSubmit {
                            if canSend {
                                Task { await viewModel.sendMessage() }
                            }
                        }

                    Button {
                        Task { await viewModel.sendMessage() }
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title2)
                            .foregroundStyle(canSend ? .blue : .gray)
                    }
                    .disabled(!canSend)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
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
            .disabled(viewModel.isLoading || viewModel.isLoadingConversation)
        }
        .sheet(isPresented: $viewModel.showColorPicker) {
            viewModel.cancelColorPick()
        } content: {
            NavigationStack {
                VStack(spacing: 24) {
                    ColorPicker("Pick a background color", selection: $selectedColor, supportsOpacity: false)
                        .font(.headline)

                    RoundedRectangle(cornerRadius: 12)
                        .fill(selectedColor)
                        .frame(height: 120)
                        .overlay(
                            Text("Preview")
                                .foregroundStyle(.white)
                                .font(.title3)
                        )
                }
                .padding()
                .navigationTitle("Background Color")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            viewModel.cancelColorPick()
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Apply") {
                            viewModel.resolveColorPick(selectedColor)
                        }
                    }
                }
            }
            .presentationDetents([.medium])
        }
    }
}
