//
//  ChatViewModel.swift
//  tatbeeqMa7mool
//
//  Created by Eesabase on 14/03/2026.
//

import Foundation
import SwiftUI
import ChatbaseSDK
import os

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "tatbeeqMa7mool", category: "ChatViewModel")

@MainActor @Observable
class ChatViewModel {
    private let client: ChatbaseClient
    private(set) var conversationId: String?
    private(set) var messages: [Message] = []
    var inputText: String = ""
    private(set) var isLoading: Bool = false
    private(set) var isLoadingConversation: Bool = false
    private(set) var isLoadingMore: Bool = false
    private(set) var errorMessage: String?
    private var messagesPage: PaginatedResponse<Message>?
    var hasMoreMessages: Bool { messagesPage?.hasMore ?? false }
    private var currentStream: ChatStream?

    // UI state for color picker tool
    var background = Color.white
    var showColorPicker = false
    private var colorPickContinuation: CheckedContinuation<Color?, Never>?

    init(client: ChatbaseClient, conversationId: String? = nil) {
        self.client = client
        self.conversationId = conversationId
    }

    // MARK: - Conversation Loading

    func loadConversation() async {
        guard let conversationId else { return }
        isLoadingConversation = true
        do {
            let response = try await client.listMessages(conversationId: conversationId)
            messages = response.data
            messagesPage = response
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoadingConversation = false
    }

    func loadMoreMessages() async {
        guard !isLoadingMore, let page = messagesPage else { return }

        isLoadingMore = true
        do {
            if let next = try await page.loadMore() {
                messages.insert(contentsOf: next.data, at: 0)
                messagesPage = next
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoadingMore = false
    }

    // MARK: - Messaging

    func sendMessage() async {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        messages.append(Message(id: UUID().uuidString, text: text, sender: .user, date: .now))
        inputText = ""
        isLoading = true
        errorMessage = nil

        await consumeStream(client.stream(text, conversationId: conversationId))

        isLoading = false
    }

    func retryMessage(_ messageId: String) async {
        guard let conversationId else { return }

        if let index = messages.lastIndex(where: { $0.id == messageId }) {
            messages.removeSubrange(index...)
        }

        isLoading = true
        errorMessage = nil
        await consumeStream(client.retry(conversationId: conversationId, messageId: messageId))
        isLoading = false
    }

    func newConversation() {
        currentStream?.cancel()
        messages = []
        messagesPage = nil
        inputText = ""
        errorMessage = nil
        conversationId = nil
    }

    func stopStreaming() {
        currentStream?.cancel()
        isLoading = false
    }

    // MARK: - Color Picker (deferred tool call example)

    func resolveColorPick(_ color: Color) {
        showColorPicker = false
        colorPickContinuation?.resume(returning: color)
        colorPickContinuation = nil
    }

    func cancelColorPick() {
        showColorPicker = false
        colorPickContinuation?.resume(returning: nil)
        colorPickContinuation = nil
    }

    private func awaitColorPick() async -> Color? {
        await withCheckedContinuation { continuation in
            colorPickContinuation = continuation
            showColorPicker = true
        }
    }

    // MARK: - Stream Consumer

    private func consumeStream(_ chatStream: ChatStream) async {
        currentStream = chatStream

        let placeholderId = UUID().uuidString
        var messageId = placeholderId
        messages.append(Message(id: placeholderId, text: "", sender: .agent, date: .now))

        var shouldContinue = false

        do {
            for try await event in chatStream {
                switch event {
                case .messageStarted(let id):
                    if let i = messages.lastIndex(where: { $0.id == messageId }) {
                        messages[i].id = id
                        messageId = id
                    }
                case .text(let chunk):
                    if let i = messages.lastIndex(where: { $0.id == messageId }) {
                        messages[i].text += chunk
                    }
                case .finished(let info):
                    if let id = info.conversationId {
                        conversationId = id
                    }
                case .toolCall(let call):
                    shouldContinue = await handleToolCall(call)
                }
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        // Clean up empty placeholder
        if let i = messages.lastIndex(where: { $0.id == messageId }), messages[i].text.isEmpty {
            messages.remove(at: i)
        }

        currentStream = nil

        // Continue the conversation if a tool call was resolved with continue: true
        if shouldContinue, let conversationId {
            await consumeStream(client.continue(conversationId: conversationId))
        }
    }

    // MARK: - Tool Call Handlers

    /// Handles a tool call. Returns true if the conversation should continue.
    private func handleToolCall(_ call: ToolCallHandle) async -> Bool {
        switch call.toolName {

        // Example: resolve + continue (deferred UI interaction)
        // Opens a color picker, waits for user, submits result, agent responds
        case "change_background":
            if let color = await awaitColorPick() {
                background = color
                await call.resolve(["color": .string(color.description)])
                return true
            } else {
                await call.ignore()
                return false
            }

        // Example: resolve + continue (instant, no UI)
        // Executes immediately, submits result, agent responds with the data
        case "package_status":
            guard let email = call.input["email"]?.stringValue else {
                await call.fail("Missing email")
                return true
            }
            let trackingNumber = Int.random(in: 1000000000...9999999999)
            let status = ["delivered", "in transit", "out for delivery", "cancelled"].randomElement()!
            await call.resolve([
                "tracking_number": .int(trackingNumber),
                "status": .string(status),
                "email": .string(email)
            ])
            return true

        // Example: resolve + no continue
        // Submits result but conversation pauses — consumer resumes later
        case "start_checkout":
            let amount = call.input["amount"]?.numberValue ?? 0
            logger.info("Starting checkout for amount: \(amount)")
            await call.resolve(["status": .string("checkout_started")])
            return false

        // Example: fail + continue
        // Tool execution fails, agent sees the error and responds
        case "fetch_order":
            guard let orderId = call.input["order_id"]?.stringValue else {
                await call.fail("Missing order_id")
                return true
            }
            // Simulate a failed lookup
            await call.fail("Order \(orderId) not found")
            return true

        // Example: ignore (fire-and-forget)
        // Don't submit anything, don't continue
        case "log_analytics":
            logger.info("Analytics: \(call.toolName)")
            await call.ignore()
            return false

        default:
            logger.warning("Unhandled tool call: \(call.toolName)")
            await call.ignore()
            return false
        }
    }
}
