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
    let state: ConversationState
    var inputText: String = ""

    // UI state for the color-picker tool example.
    var background = Color.white
    var showColorPicker = false
    private var colorPickContinuation: CheckedContinuation<Color?, Never>?

    init(client: ChatbaseClient, conversationId: String? = nil) {
        self.state = ConversationState(client: client, conversationId: conversationId)
        registerTools(on: client)
        if let conversationId {
            Task { [state] in await state.loadHistory(conversationId: conversationId) }
        }
    }

    // MARK: - Actions (forwarded to ConversationState)

    func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        inputText = ""
        Task { [state] in await state.sendMessage(text) }
    }

    func retryMessage(_ messageId: String) {
        Task { [state] in await state.retry(messageId: messageId) }
    }

    func loadMoreHistory() {
        Task { [state] in await state.loadMoreHistory() }
    }

    func newConversation() {
        state.clear()
    }

    // MARK: - Tool handlers
    //
    // Registered once on the client. The SDK auto-runs them during send/retry
    // and continues the conversation. Return a JSONValue to resolve; return
    // an `{"error": ...}` payload (or throw) to surface an error.

    private func registerTools(on client: ChatbaseClient) {
        // Async UI interaction: open a picker, wait for user, submit result.
        // Returning an `{"error": ...}` payload surfaces the failure to the
        // agent without throwing.
        client.tool("change_background") { [weak self] _ in
            guard let self else {
                return .object(["error": .string("View model released")])
            }
            guard let color = await self.awaitColorPick() else {
                return .object(["error": .string("User dismissed the color picker")])
            }
            await self.apply(background: color)
            return .object(["color": .string(color.description)])
        }
    }

    @MainActor private func apply(background color: Color) {
        self.background = color
    }

    // MARK: - Color picker

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
}
