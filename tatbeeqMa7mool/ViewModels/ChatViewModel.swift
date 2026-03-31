//
//  ChatViewModel.swift
//  tatbeeqMa7mool
//
//  Created by Eesabase on 14/03/2026.
//

import Foundation
import SwiftUI
import os

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "tatbeeqMa7mool", category: "ChatViewModel")

@MainActor @Observable
class ChatViewModel {
    private let chatService: ChatService
    private(set) var conversationId: String?
    private(set) var messages: [Message] = []
    var inputText: String = ""
    private(set) var isLoading: Bool = false
    private(set) var isLoadingMore: Bool = false
    private(set) var errorMessage: String?
    private var messageCursor: String?
    private(set) var hasMoreMessages: Bool = false

    var background = Color.white

    init(chatService: ChatService, conversationId: String? = nil) {
        self.chatService = chatService
        self.conversationId = conversationId
    }

    func loadConversation() async {
        guard let conversationId else { return }
        isLoading = true
        do {
            let (_, msgs, pagination) = try await chatService.getConversation(conversationId)
            messages = msgs
            messageCursor = pagination.cursor
            hasMoreMessages = pagination.hasMore
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func loadMoreMessages() async {
        guard let conversationId, hasMoreMessages, !isLoadingMore,
              let cursor = messageCursor else { return }

        isLoadingMore = true
        do {
            let response = try await chatService.listMessages(conversationId: conversationId, cursor: cursor)
            messages.insert(contentsOf: response.data, at: 0)
            messageCursor = response.pagination.cursor
            hasMoreMessages = response.pagination.hasMore
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoadingMore = false
    }

    func retryMessage(_ messageId: String) async {
        guard let conversationId else { return }

        if let index = messages.lastIndex(where: { $0.id == messageId }) {
            messages.removeSubrange(index...)
        }

        isLoading = true
        errorMessage = nil
        await consumeStream(chatService.retryMessage(conversationId: conversationId, messageId: messageId))
        isLoading = false
    }

    func toggleFeedback(messageId: String, feedback: MessageFeedback) async {
        guard let conversationId else { return }
        guard let index = messages.firstIndex(where: { $0.id == messageId }) else { return }

        let current = messages[index].feedback
        let newFeedback: MessageFeedback? = current == feedback ? nil : feedback

        do {
            let updated = try await chatService.updateFeedback(
                conversationId: conversationId,
                messageId: messageId,
                feedback: newFeedback
            )
            messages[index].feedback = updated.feedback
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func newConversation() {
        messages = []
        inputText = ""
        errorMessage = nil
        conversationId = nil
    }

    func sendMessage() async {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        messages.append(Message(
            id: UUID().uuidString,
            text: text,
            sender: .user,
            date: .now
        ))
        inputText = ""
        isLoading = true
        errorMessage = nil

        await consumeStream(chatService.streamMessage(text, conversationId: conversationId))

        isLoading = false
    }

    private func consumeStream(_ stream: AsyncThrowingStream<StreamEvent, Error>) async {
        let placeholderId = UUID().uuidString
        var agentMessageId = placeholderId
        messages.append(Message(id: placeholderId, text: "", sender: .agent, date: .now))

        do {
            for try await event in stream {
                switch event {
                case .messageStarted(let id):
                    agentMessageId = id
                    if let index = messages.lastIndex(where: { $0.id == placeholderId }) {
                        messages[index].id = id
                    }
                case .textChunk(let chunk):
                    if let index = messages.lastIndex(where: { $0.id == agentMessageId }) {
                        messages[index].text += chunk
                    }
                case .finished(let info):
                    if let id = info.conversationId {
                        conversationId = id
                    }
                case .toolCall(let toolCall):
                    logger.info("Tool call received: \(toolCall.toolName) (id: \(toolCall.toolCallId))")

                    messages.removeAll(where: { $0.id == agentMessageId })

                    guard let conversationId else {
                        errorMessage = ChatError.noConversation.localizedDescription
                        return
                    }

                    let output = executeToolCall(toolCall)
                    logger.info("Tool executed, submitting result...")

                    do {
                        try await chatService.submitToolResult(
                            conversationId: conversationId,
                            toolCall: toolCall,
                            output: output
                        )
                        logger.info("Tool result submitted, continuing conversation...")
                        await consumeStream(chatService.continueConversation(conversationId))
                    } catch {
                        logger.error("Failed to submit tool result: \(error.localizedDescription)")
                        errorMessage = error.localizedDescription
                    }
                }
            }
        } catch {
            // Remove placeholder if stream failed before any content arrived
            if messages.last?.id == placeholderId || messages.last?.id == agentMessageId,
               messages.last?.text.isEmpty == true {
                messages.removeLast()
            }
            errorMessage = error.localizedDescription
        }
    }

    private func executeToolCall(_ toolCall: ToolCall) -> [String: String] {
        switch toolCall.toolName {
        case "change_background":
            background = background != Color.white ? Color.white : Color.cyan.opacity(0.2)
            return ["result": "Background changed"]
        default:
            return ["error": "Unknown tool: \(toolCall.toolName)"]
        }
    }
}
