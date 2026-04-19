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
        && !viewModel.state.isSending
        && !viewModel.state.isLoadingHistory
    }

    private var scrollKey: String {
        let last = viewModel.state.messages.last
        let len: Int
        switch last?.kind {
        case .text(let t): len = t.count
        case .toolCall(let card): len = card.status == .executing ? 1 : 2
        case nil: len = 0
        }
        return "\(viewModel.state.messages.count)-\(len)"
    }

    var body: some View {
        VStack(spacing: 0) {
            if viewModel.state.isLoadingHistory && viewModel.state.messages.isEmpty {
                Spacer()
                ProgressView("Loading conversation...")
                Spacer()
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 20) {
                            if viewModel.state.hasMoreHistory {
                                Button {
                                    viewModel.loadMoreHistory()
                                } label: {
                                    if viewModel.state.isLoadingHistory {
                                        ProgressView()
                                    } else {
                                        Text("Load earlier messages")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .disabled(viewModel.state.isLoadingHistory)
                            }
                            ForEach(viewModel.state.messages) { message in
                                MessageBubble(
                                    message: message,
                                    onRetry: message.messageId.map { id in
                                        { viewModel.retryMessage(id) }
                                    }
                                )
                            }
                            if let error = viewModel.state.error {
                                Text(error.localizedDescription)
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
                    .onChange(of: scrollKey) {
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
                        .onSubmit { if canSend { viewModel.sendMessage() } }

                    Button {
                        viewModel.sendMessage()
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title2)
                            .foregroundStyle(canSend ? .blue : .gray)
                    }
                    .disabled(!canSend || viewModel.state.isSending)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
        }
        .navigationTitle("AI Chat")
        .background(viewModel.background)
        .onDisappear {
            viewModel.cancelColorPick()
        }
        .toolbar {
            Button {
                viewModel.newConversation()
            } label: {
                Image(systemName: "square.and.pencil")
            }
            .disabled(viewModel.state.isSending || viewModel.state.isLoadingHistory)
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
                        Button("Cancel") { viewModel.cancelColorPick() }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Apply") { viewModel.resolveColorPick(selectedColor) }
                    }
                }
            }
            .presentationDetents([.medium])
        }
    }
}
